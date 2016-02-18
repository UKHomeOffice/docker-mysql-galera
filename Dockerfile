FROM ukhomeofficedigital/centos-base

# add our user and group first to make sure their IDs get assigned 
# consistently, regardless of whatever dependencies get added
RUN groupadd -r mysql && useradd -r -g mysql mysql

ENV PERCONA_XTRADB_VERSION 5.6
ENV MYSQL_VERSION 5.6
ENV INSTALL_PACKAGE_VERSION 56
ENV TERM linux

# the "/var/lib/mysql" stuff here is because the mysql-server
# postinst doesn't have an explicit way to disable the 
# mysql_install_db codepath besides having a database already
# "configured" (ie, stuff in /var/lib/mysql/mysql)
# also, we set debconf keys to make APT a little quieter
RUN yum install -y http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm \
    && yum install -y Percona-Server-server-${INSTALL_PACKAGE_VERSION} \
    && rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql

VOLUME /var/lib/mysql

COPY my.cnf /etc/mysql/my.cnf
COPY cluster.cnf /etc/mysql/conf.d/cluster.cnf

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 3306 4444 4567 4568
CMD ["mysqld"]
