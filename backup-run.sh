#!/bin/bash

# Get last error even in piped commands
set -o pipefail

PIDFILE=/var/run/backup-run.pid

if [ -f $PIDFILE ]; then
	echo $0 is already running with pid $(cat $PIDFILE), aborting!
	exit 1
fi

echo $$ >$PIDFILE

# Generate the file name
BACKUP_FILENAME_PREFIX=$(date +"%Y%m%d_%H%M%S")_${NAME}

# Call backup script and capture output
OUT_BUFF=$( /usr/local/sbin/backup-db.sh 2>&1 | tee /proc/1/fd/1 )

RETVAL=$?

# Calculate result in words
RESULT="unknown"
if [ "$RETVAL" == 0 ]; then
	RESULT="success"
else
	RESULT="failed"
fi

cat <<EOF | mutt -s "Postgress backup ${RESULT}: ${BACKUP_FILENAME_PREFIX}" -- $MAIL_TO
${OUT_BUFF}
EOF

rm $PIDFILE

exit $RETVAL


