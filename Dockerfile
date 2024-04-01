# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM phusion/baseimage:jammy-1.0.2

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# install apache2 via apt
RUN apt-get -y update &&  \ 
    apt-get install --no-install-recommends -y \
    apache2 vim iproute2 iputils-ping tree libonig-dev

# enable apache2 status module
RUN a2enmod status

# create two new virtual hosts
RUN mkdir -p /var/www/example-domain1.org/html
RUN mkdir -p /var/www/example-domain2.org/html

COPY ./var/www/example-domain1.org/html /var/www/example-domain1.org/html 
COPY ./var/www/example-domain2.org/html /var/www/example-domain2.org/html 

COPY ./etc/apache2/sites-available /etc/apache2/sites-available

RUN a2ensite example-domain1.org
RUN a2ensite example-domain2.org

# disable default config
RUN a2dissite 000-default.conf

# create required log folder for apache2
RUN mkdir -p /var/log/apache2/latest
RUN chown www-data:www-data /var/log/apache2/latest

# create runit service for apache2
RUN mkdir /etc/service/apache2
COPY ./etc/service/run_apache2 /etc/service/apache2/run
RUN chmod +x /etc/service/apache2/run

# enable access to status from everywhere
RUN sed -i.ORIG 's/Require local/Require all granted/g' /etc/apache2/mods-available/status.conf 

# copy grok_exporter into place
COPY ./grok_exporter /usr/local/bin
RUN chmod +x /usr/local/bin/grok_exporter

# copy pre-defined grok patterns
COPY ./grok_patterns /root/patterns

# make grok_exporter run as runit service
RUN mkdir /etc/service/grok_exporter
COPY ./etc/service/run_grok_exporter /etc/service/grok_exporter/run
RUN chmod +x /etc/service/grok_exporter/run 

# copy grok_exporter config file into place
COPY ./grok_exporter_config.yml /root/./grok_exporter_config.yml

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
