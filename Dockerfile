# Based on 
# centos/s2i-core-centos7 https://github.com/sclorg/s2i-base-container/blob/master/core/Dockerfile
# centos/httpd-24-centos7 https://github.com/sclorg/httpd-container/blob/master/2.4/Dockerfile
#     # DEPRECATED: Use above LABEL instead, because this will be removed in future versions.
# STI_SCRIPTS_URL=image:///usr/libexec/s2i \
# # Path to be used in other layers to place s2i scripts into
# STI_SCRIPTS_PATH=/usr/libexec/s2i \
# APP_ROOT=/opt/app-root \
# # The $HOME is not set by default, but some applications needs this variable
# HOME=/opt/app-root/src \
# PATH=/opt/app-root/src/bin:/opt/app-root/bin:$PATH
#FROM centos/s2i-core-centos7
#FROM centos/httpd-24-centos7
FROM centos:7
#
USER root
# oc new-build --strategy docker --binary --docker-image centos/s2i-core-centos7 --name nominatim
# oc start-build nominatim --from-dir . --follow
#TODO: postgis add to postgres image install postgis postgis-utils

ENV APP_ROOT=/opt/app-root \
    HOME=/opt/app-root/Nominatim-3.1.0/build \
    OSM_FLAT_FILE=/var/lib/nominatim/data

WORKDIR ${APP_ROOT}

ENV SUMMARY="Nominatm" \
    DESCRIPTION="Nominatim" \
    PBF_DATA=http://download.geofabrik.de/europe/monaco-latest.osm.pbf

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="Nominatim $NOMINATIM_VERSION" \
      io.openshift.expose-services="8080:apache" \
      io.openshift.tags="geocoding,nominatim" \
      name="centos/nominatim" \
      version="$NOMINATIM_VERSION" \
      usage="docker run -d --name nominatim -e POSTGRESQL_USER=user -e POSTGRESQL_PASSWORD=pass -e POSTGRESQL_DATABASE=db -p 5432:5432 centos/postgresql-96-centos7" \
      maintainer="Moritz Bunse <moritz.bunse@gmail.com"

EXPOSE 8080

# from https://github.com/sclorg/postgresql-container/blob/generated/9.6/Dockerfile
COPY root/usr/libexec/fix-permissions /usr/libexec/fix-permissions
RUN chmod a+x /usr/libexec/fix-permissions

#RUN yum remove -y httpd24-httpd-2.4.27-8.el7.1.x86_64 && \
RUN yum install -y yum-utils && \
    yum install -y epel-release && \
    INSTALL_PKGS="cmake make gcc gcc-c++ libtool postgis postgis-utils postgresql-contrib postgresql-server proj-devel policycoreutils-python postgresql-devel php-pgsql php php-pear php-pear-DB php-intl libpqxx-devel php-pgsql php php-pear php-pear-DB php-intl libpqxx-devel proj-epsg bzip2-devel proj-devel libxml2-devel boost-devel expat-devel zlib-devel bzip2" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all && \
    localedef -f UTF-8 -i en_US en_US.UTF-8


# from /usr/lib/systemd/system/postgresql.service
# User=postgres
# Group=postgres
# PGPORT=5432
# PGDATA=/var/lib/pgsql/data
# StartPre: /usr/bin/postgresql-check-db-dir ${PGDATA}
# ExecStart=/usr/bin/pg_ctl start -D ${PGDATA} -s -o "-p ${PGPORT}" -w -t 300

# Ausprobieren von /usr/bin/postgresql-check-db-dir $PGDATA
# Use "postgresql-setup initdb" to initialize the database cluster.
# See /usr/share/doc/postgresql-9.2.23/README.rpm-dist for more information.
# $ export PGDATA=/var/lib/pgsql/data
#  $ initdb
# The files belonging to this database system will be owned by user "user1".
# This user must also own the server process.

# The database cluster will be initialized with locale "C".
# The default database encoding has accordingly been set to "SQL_ASCII".
# The default text search configuration will be set to "english".

# initdb: could not access directory "/var/lib/pgsql/data": Permission denied
# Also müssen vorher die Rechte gesetzt werden
# chmod -R a+rwx /var/lib/pgsql


# from /usr/lib/systemd/system/httpd.service
# EnvironmentFile=/etc/sysconfig/httpd -> LANG=C
# ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
# ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
# ExecStop=/bin/kill -WINCH ${MAINPID}

RUN useradd -u 30 -g root nominatim

RUN mkdir -p /var/lib/pgsql/data && \
    mkdir -p /var/lib/nominatim/data && \
    mkdir -p /opt/app-root && \
    /usr/libexec/fix-permissions /var/lib/pgsql && \
    /usr/libexec/fix-permissions /var/lib/nominatim/data && \
    /usr/libexec/fix-permissions /var/run/postgresql && \
    /usr/libexec/fix-permissions /run/httpd && \
    /usr/libexec/fix-permissions ${APP_ROOT} && \
    usermod -a -G root postgres

# BUILD nominatim
RUN curl -L -f https://nominatim.org/release/Nominatim-3.1.0.tar.bz2 > Nominatim.tar.bz2 && \
    tar xvf Nominatim.tar.bz2

RUN mkdir -p Nominatim-3.1.0/build

WORKDIR ${HOME}
RUN cmake .. && make

COPY root /
RUN chmod a+x /usr/libexec/* /usr/bin/run-nominatim

RUN /usr/libexec/httpd-prepare && /usr/libexec/nominatim-prepare

# Nominatim user
USER 30

CMD ["/usr/bin/run-nominatim"]
