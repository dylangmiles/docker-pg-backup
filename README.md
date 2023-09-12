# docker-pg-backup

This container can be used to periodically backup a Postgress database.

You can check the last run with the integrated HTTP server on port 18080.

The backup location is tar gziped to an Amazon S3 bucket and an email sent with the status of the backup.

# Setup

1. Clone this repository to your server with files that need to be backed up
```
git clone git@github.com:dylangmiles/docker-pg-backup.git
```

2. Create a `.env` file in the directory with the following settings:
```bash
# Cron schedule
SCHEDULE=* * * * *

# Label used for the backup filename. The result backup file name will use the format  YYMMDD_HH_mm_ss_NAME_tar.gz
NAME=test

# LOCATION local | aws
LOCATION=aws

# Database connection details
PG_USER=root
PG_PASSWORD=*********
PG_HOST=host.docker.internal
PG_PORT=5432

# The location where backups will be written to
LOCAL_DESTINATION=./data/destination

# AWS Storage
AWS_ACCESS_KEY=**************
AWS_SECRET_KEY=******************************
AWS_REGION=eu-west-1
AWS_DESTINATION=s3://bucketname/path

# Azure Storage
AZURE_APP_TENANT_ID=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee
AZURE_APP_ID=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeef
AZURE_APP_SECRET=*************
AZURE_STORAGE_ACCOUNT=mystorageaccount
AZURE_STORAGE_BLOB_CONTAINER=mycontainer
AZURE_STORAGE_BLOB_PREFIX=pathincontainer/

# Email address where notifications are sent
MAIL_TO=to@email.com

# Email sending options
SMTP_FROMNAME=FromName
SMTP_FROM=from@email.com
SMTP_HOST=mail.server.com
SMTP_PORT=587
SMTP_STARTTLS=on
SMTP_USERNAME=username@email.com
SMTP_PASSWORD=*******

```

3. Start the container
```
docker compose up -d db-backup
```

You can also manually run the backup from the command line
```
docker compose run --rm db-backup backup-run.sh
```

NB: The backup will ignore any directories with .file-backup-ignore in them.

