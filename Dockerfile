FROM ukhomeofficedigital/centos-base

# add our user and group first to make sure their IDs get assigned 
# consistently, regardless of whatever dependencies get added
RUN groupadd -r mysql && useradd -r -g mysql mysql

ENV PERCONA_XTRADB_VERSION 5.6
ENV MYSQL_VERSION 5.6
ENV INSTALL_PACKAGE_VERSION 56
ENV TERM linux
ENV DATADIR /var/lib/mysql
ENV CONF_FILE /etc/my.cnf
ENV CONF_D /etc/my.cnf.d

# the "/var/lib/mysql" stuff here is because the mysql-server
# postinst doesn't have an explicit way to disable the 
# mysql_install_db codepath besides having a database already
# "configured" (ie, stuff in /var/lib/mysql/mysql)
RUN yum install -y http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm \
    && yum install -y Percona-XtraDB-Cluster-${INSTALL_PACKAGE_VERSION} \
    && yum install -y iproute socat which nmap-ncat \
    && yum install -y ruby \
    && rm -rf ${DATADIR} \
    && mkdir -p ${DATADIR} && chown -R mysql:mysql ${DATADIR} \
    && mkdir -p /var/log/mysql && chown -R mysql:mysql /var/log/mysql \
    && mkdir -p /var/run/mysqld && chown -R mysql:mysql /var/run/mysqld

COPY my.cnf /etc/my.cnf
COPY cluster.cnf /etc/my.cnf.d/cluster.cnf
COPY /recover_service/* /opt/recover_service/

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 3306 4444 4567 4568
CMD ["mysqld"]
