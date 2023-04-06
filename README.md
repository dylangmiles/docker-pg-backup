# Scheduled PostgreSQL Backup

Create schedule backups of databases in a PostgreSQL server to a destination directory.

## Build the contiainer
```
$ make
```

## Start a scheduled backup
```
docker run \
-v /var/destination:/var/destination \
-e TIMEZONE="Africa/Johannesburg" \
-e SCHEDULE="0 0 3 * *" \
-e BACKUP_OPTS="-u postgres -p test -h 172.17.0.68" \
dylangmiles/docker-pg-backup
```

## Run a backup once off

```
docker run \
--entrypoint="/usr/local/sbin/backup-run.sh" \
-v ~/dev/temp/backups:/var/destination \
-e BACKUP_OPTS="-u postgres -p abc123! -h host.docker.internal -c gzip" \
dylangmiles/docker-pg-backup

```



