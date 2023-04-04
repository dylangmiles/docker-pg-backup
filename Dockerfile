FROM		postgres:14.2-bullseye
MAINTAINER	Dylan Miles <dylan.g.miles@gmail.com>

# install required packages
RUN		apt-get update -qq && \
		apt-get install -y --no-install-recommends ca-certificates curl && \
        apt-get clean autoclean && \
        apt-get autoremove --yes && \
        rm -rf /var/lib/{apt,dpkg,cache,log}/

ENV		GO_CRON_VERSION v0.0.7

RUN		curl -L https://github.com/odise/go-cron/releases/download/${GO_CRON_VERSION}/go-cron-linux.gz \
		| zcat > /usr/local/bin/go-cron \
		&& chmod u+x /usr/local/bin/go-cron

# install backup scripts
ADD		backup-postgres.sh /usr/local/sbin/backup-postgres.sh
ADD		backup-run.sh /usr/local/sbin/backup-run.sh

ADD		docker-entrypoint.sh /usr/local/sbin/docker-entrypoint.sh
ENTRYPOINT	["/usr/local/sbin/docker-entrypoint.sh"]

CMD		["go-cron"]