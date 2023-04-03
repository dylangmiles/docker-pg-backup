#!/bin/sh

PIDFILE=/var/run/backup-run.pid

if [ -f $PIDFILE ]; then
	echo $0 is already running with pid $(cat $PIDFILE), aborting!
	exit 1
fi

echo $$ >$PIDFILE

/usr/local/sbin/backup-postgres.sh ${BACKUP_OPTS}

retval=$?

rm $PIDFILE

exit $retval