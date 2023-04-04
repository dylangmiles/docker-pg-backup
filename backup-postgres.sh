#!/bin/bash

PG_USER=
PG_PASSWORD=
PG_HOST=
PG_PORT=5432
COMPRESSION_METHOD=
RSH=

# The leading ":" suppresses error messages from
while getopts ":u:p:h:P:d:c:e:" opt; do
  case $opt in
    d)
      BACKUP_FILE=$OPTARG
      ;;
    u)
      PG_USER=$OPTARG
      ;;
    p)
      PG_PASSWORD=$OPTARG
      ;;
    P)
      PG_PORT=$OPTARG
      ;;
    h)
      PG_HOST=$OPTARG
      ;;
    c)
      COMPRESSION_METHOD=$OPTARG
      ;;
    e)
      RSH=$OPTARG
      ;;  
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [ -z "$BACKUP_FILE" ]; then
	BACKUP_FILE=/var/tmp/$(date +"%Y%m%d_%H%M%S")_${PG_HOST}_pgdump
fi

if [ -z "$PG_USER" ] || [ -z "$PG_PASSWORD" ]; then
	echo
	echo Usage: $0 -u pguser -p pgpassword -h pghost -c bzip2
	echo
	echo "  -u  Specifies the Postgres user (required)"
	echo "  -p  Specifies the Postgres password (required)"
	echo "  -h  Specifies the Postgres host (required)"
	echo "  -P  Specifies the Postgres port (optional)"
	echo "  -d  Specifies the backup file where to put the backup (default: /var/backups/CURRENT_DATETIME_PGHOST_pgdump)"
	echo "  -c  Specifies the compression method which should be used to compress the dump file (none | gzip) (optional)"
	echo
	exit 1
fi

echo Using the following configuration:
echo
echo "    backup_file:        ${BACKUP_FILE}"
echo "    pg_user:            ${PG_USER}"
echo "    pg_password:        ****** (not shown)"
echo "    pg_host:            ${PG_HOST}"
echo "    pg_port:            ${PG_PORT}"
echo "    compression_method: ${COMPRESSION_METHOD}"
echo "    rsh:                ${RSH}"
echo

PG_OPTS="-U ${PG_USER} -h ${PG_HOST} -p ${PG_PORT}"
PGDUMP_OPTS=""


# Create password file
echo ${PG_HOST}:${PG_PORT}:*:${PG_USER}:${PG_PASSWORD} > ~/.pgpass
chmod 0600 ~/.pgpass

for db in $(${RSH} psql ${PG_OPTS} -c 'SELECT datname FROM pg_catalog.pg_database WHERE datistemplate = false;' | grep -v datname | grep -v "^[-(#;]" | grep -v postgres); do
    echo "Dumping: ${db}"
    ${RSH} pg_dump ${PG_OPTS} ${PGDUMP_OPTS} ${db} >${BACKUP_FILE}_${db}.sql
    RETVAL=$?
    done

# compression step
if [ "$RETVAL" == 0 ]; then
	if [ "$COMPRESSION_METHOD" = "gzip" ]; then
		echo Compressing backup using gzip compression method.
		gzip --best ${BACKUP_FILE}*
		RETVAL=$?
	fi
fi

#Copy files to the destination
if [ "$RETVAL" == 0 ]; then
	echo Copy files to the destination
	cp -v ${BACKUP_FILE}* /var/destination

	RETVAL=$?
fi

#Remove the temporary backup
if [ "$RETVAL" == 0 ]; then
	echo Remove temporary files
	rm -v ${BACKUP_FILE}*

	RETVAL=$?
fi

if [ "$RETVAL" == 0 ]; then
	echo Backup finished successfully.
	exit 0
else
	echo Backup failed with errors!
	exit 1
fi