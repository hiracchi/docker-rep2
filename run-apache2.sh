#!/bin/bash

. /etc/apache2/envvars

[ ! -d ${APACHE_RUN_DIR:-/var/run/apache2} ] && mkdir -p ${APACHE_RUN_DIR:-/var/run/apache2}
[ ! -d ${APACHE_LOCK_DIR:-/var/lock/apache2} ] && mkdir ${APACHE_RUN_USER:-www-data} ${APACHE_LOCK_DIR:-/var/lock/apache2}

# for rep2
yes no | cp -Ri /usr/local/p2-php/.default/* /ext/

/usr/local/bin/2chproxy.pl -c /usr/local/etc/2chproxy.conf & \
/usr/sbin/apache2 -D FOREGROUND
