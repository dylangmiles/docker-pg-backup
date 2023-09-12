#!/bin/bash

# Get last error even in piped commands
set -o pipefail

# Function to dump db
_dump_db() {
sh << EOF
${RSH} pg_dump ${PG_OPTS} ${PGDUMP_OPTS} $1 || exit \$?
EOF
}

if [ -z "$BACKUP_FILENAME_PREFIX" ]; then
	BACKUP_FILENAME_PREFIX=$(date +"%Y%m%d_%H%M%S")_${NAME}
fi


echo Using the following configuration:
echo
echo "    backup_file:        ${BACKUP_FILENAME_PREFIX}"
echo "    pg_user:            ${PG_USER}"
echo "    pg_password:        ****** (not shown)"
echo "    pg_host:            ${PG_HOST}"
echo "    pg_port:            ${PG_PORT}"
echo "    rsh:                ${RSH}"
echo

DESTINATION=$LOCAL_DESTINATION
if [ "$LOCATION" == "aws" ]; then
	DESTINATION=$AWS_DESTINATION
fi
if [ "$LOCATION" == "azure" ]; then
	DESTINATION="https://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZURE_STORAGE_BLOB_CONTAINER}/${AZURE_STORAGE_BLOB_PREFIX}"
fi

echo "Backup starting of ${BACKUP_FILENAME_PREFIX} on ${LOCATION} to ${DESTINATION}"
echo ""

PG_OPTS="-U ${PG_USER} -h ${PG_HOST} -p ${PG_PORT}"
PGDUMP_OPTS=""
LASTERRORRETVAL=0

# Create password file
echo ${PG_HOST}:${PG_PORT}:*:${PG_USER}:${PG_PASSWORD} > ~/.pgpass
chmod 0600 ~/.pgpass

# Enumerate dbs
dbs=$(${RSH} psql ${PG_OPTS} -c 'SELECT datname FROM pg_catalog.pg_database WHERE datistemplate = false;' | grep -v datname | grep -v "^[-(#;]" | grep -v postgres) && {

	if [ "$LOCATION" == "local" ]; then

		for db in $dbs; do

			# Ignore system databases
			if [ $db == "postgres" ]; then
				continue;
			fi

			echo "Dumping ${db}"

			_dump_db ${db} > gzip > "/var/destination/${BACKUP_FILENAME_PREFIX}_${db}.sql.gz" || {
				LASTERRORRETVAL=$?
			}

		done
	fi

	if [ "$LOCATION" == "aws" ]; then

		for db in $dbs; do

			# Ignore system databases
			if [ $db == "postgres" ]; then
				continue;
			fi

			echo "Dumping ${db}"

			_dump_db ${db} | gzip | aws s3 cp - "${AWS_DESTINATION}/${BACKUP_FILENAME_PREFIX}_${db}.sql.gz" || {
				LASTERRORRETVAL=$?
			}

		done
	fi

	if [ "$LOCATION" == "azure" ]; then
	
		for db in $dbs; do

			# Ignore system databases
			if [ $db == "postgres" ]; then
				continue;
			fi

			echo "Dumping ${db}"

		
		    _dump_db ${db} | gzip | azcopy copy "${DESTINATION}${BACKUP_FILENAME_PREFIX}_${db}.sql.gz" --from-to PipeBlob || {
				LASTERRORRETVAL=$?
			}
	
		done
	fi


} || {
	LASTERRORRETVAL=$?
}

echo ""

if [ "$LASTERRORRETVAL" == 0 ]; then
	echo "Backup completed successfully"
	exit 0
else
	echo "Backup failed with last error ${LASTERRORRETVAL}"
	exit 1
fi
