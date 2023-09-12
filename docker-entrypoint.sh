#!/bin/bash
set -e

echo "Authenticating with AWS"
aws configure set aws_access_key_id ${AWS_ACCESS_KEY}
aws configure set aws_secret_access_key ${AWS_SECRET_KEY}
aws configure set default.region ${AWS_REGION}

echo "Authenticating with Azure"
export AZCOPY_AUTO_LOGIN_TYPE=SPN
export AZCOPY_SPA_APPLICATION_ID=${AZURE_APP_ID}
export AZCOPY_SPA_CLIENT_SECRET=${AZURE_APP_SECRET}
export AZCOPY_TENANT_ID=${AZURE_APP_TENANT_ID}

echo "Setting up SMTP settings"
envsubst < /root/.muttrc.template > /root/.muttrc
envsubst < /root/.msmtprc.template > /root/.msmtprc

if [ -n "$TIMEZONE" ]; then
	echo ${TIMEZONE} > /etc/timezone && \
	dpkg-reconfigure -f noninteractive tzdata
fi

if [ $1 == "go-cron" ]; then

	if [ -z "$SCHEDULE" ]; then
		echo Missing SCHEDULE environment variable 2>&1
		echo Example -e SCHEDULE=\"\*/10 \* \* \* \* \*\" 2>&1
		exit 1
	fi

exec go-cron -s "${SCHEDULE}" -- /usr/local/sbin/backup-run.sh
fi

exec "$@"