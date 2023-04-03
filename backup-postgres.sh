#!/bin/bash

PG_USER=
PG_PASSWORD=
PG_HOST=
PG_PORT=5432
COMPRESSION_METHOD=
RSH=
SPLIT_FILES=1

# The leading ":" suppresses error messages from
while getopts ":u:p:h:P:d:c:e:x" opt; do
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
    x)
      SPLIT_FILES=$OPTARG
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
	BACKUP_FILE=/var/tmp/$(date +"%Y-%m-%d-%H%M%S")_${PG_HOST}_pgdump
fi

if [ -z "$PG_USER" ] || [ -z "$PG_PASSWORD" ]; then
	echo
	echo Usage: $0 -u pguser -p pgpassword -h pghost -c bzip2
	echo
	echo "  -U  Specifies the Postgres user (required)"
	echo "  -p  Specifies the Postgres password (required)"
	echo "  -h  Specifies the Postgres host (required)"
	echo "  -p  Specifies the Postgres port (optional)"
	echo "  -d  Specifies the backup file where to put the backup (default: /var/backups/CURRENT_DATETIME_PGHOST_pgdump)"
	echo "  -c  Specifies the compression method which should be used to compress the dump file (bzip2 or gzip)"
	echo "  -e  Specified the remote shell which should be used (e.g. \"ssh -C user@remotehost\")"
	echo "  -x  If specified the backup will create a seperate file for each database/table (1 = file per database, 2 = file per table)"
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
echo "    split files:        ${SPLIT_FILES}"
echo

PG_OPTS="-U${PG_USER} -p${PG_PASSWORD} -h${PG_HOST} -p${PG_PORT}"
PGDUMP_OPTS=""


if [ "$SPLIT_FILES" == 1 ]; then
	for db in $(${RSH} psql ${PG_OPTS} -e \list | grep -v information_schema | grep -v performance_schema); do
		#for table in $(${RSH} mysql ${MYSQL_OPTS} $db -e show\ tables -s --skip-column-names); do
			echo "Dumping ${db}"

			echo "SET autocommit=0;SET unique_checks=0;SET foreign_key_checks=0;" >${BACKUP_FILE}_${db}.sql
			${RSH} pg_dump ${PG_OPTS} ${PGDUMP_OPTS} ${db} ${table} >>${BACKUP_FILE}_${db}.sql
			echo "SET autocommit=1;SET unique_checks=1;SET foreign_key_checks=1;commit;" >>${BACKUP_FILE}_${db}.sql

			RETVAL=$?
		#done
	done
else
	${RSH} pg_dump ${MYSQL_OPTS} ${MYSQLDUMP_OPTS} --all-databases >${BACKUP_FILE}.sql
	RETVAL=$?
fi

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