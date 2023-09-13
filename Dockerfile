FROM		postgres:15.4-bookworm
MAINTAINER	Dylan Miles <dylan.g.miles@gmail.com>

ARG TARGETPLATFORM
ARG BUILDPLATFORM

# install required packages
RUN		apt-get update -qq && \
		apt-get install -y \
					curl \
					wget \
					unzip \
					msmtp \
					gettext \
					mutt \
		&& apt-get autoremove --yes \
		&& rm -rf /var/lib/{apt,dpkg,cache,log}/

ENV		GO_CRON_VERSION v0.0.10

# linux/arm64 packages
# GO CRON
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ] ; then \
	curl -L "https://github.com/prodrigestivill/go-cron/releases/download/v0.0.10/go-cron-linux-arm64.gz" \
	| zcat > /usr/local/bin/go-cron \
	&& chmod u+x /usr/local/bin/go-cron; \
	fi

# AWS CLI
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ] ; then \
	curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip" \
	&& unzip awscliv2.zip \
	&& ./aws/install \
	; \
	fi

# AzureCopy
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ] ; then \
	curl "https://aka.ms/downloadazcopy-v10-linux-arm64" -L -o "downloadazcopy-v10-linux-arm64.tar.gz" \
	&& tar -xzvf downloadazcopy-v10-linux-arm64.tar.gz \
	&& cp ./azcopy_linux_arm64_*/azcopy /usr/bin/ \
	; \
	fi

# linux/amd64 packages
# GO CRON
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ] ; then \
	curl -L "https://github.com/prodrigestivill/go-cron/releases/download/v0.0.10/go-cron-linux-amd64.gz" \
	| zcat > /usr/local/bin/go-cron \
	&& chmod u+x /usr/local/bin/go-cron; \
	fi

# AWS CLI
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ] ; then \
	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
	&& unzip awscliv2.zip \
	&& ./aws/install \
	; \
	fi

# AzureCopy
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ] ; then \
	curl "https://aka.ms/downloadazcopy-v10-linux" -L -o "downloadazcopy-v10-linux.tar.gz" \
	&& tar -xzvf downloadazcopy-v10-linux.tar.gz \
	&& cp ./azcopy_linux_amd64_*/azcopy /usr/bin/ \
	; \
	fi



# Configure mail notification sending
ADD conf/.muttrc /root/.muttrc.template
ADD conf/.msmtprc /root/.msmtprc.template

# Install backup scripts
ADD		backup-db.sh /usr/local/sbin/backup-db.sh
ADD		backup-run.sh /usr/local/sbin/backup-run.sh

#18080 http status port
EXPOSE		18080

ADD		docker-entrypoint.sh /usr/local/sbin/docker-entrypoint.sh
ENTRYPOINT	["/usr/local/sbin/docker-entrypoint.sh"]

CMD		["go-cron"]