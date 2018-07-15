FROM centos:7
USER root

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
      io.k8s.display-name="Nominatim 3.1.0" \
      io.openshift.expose-services="8080:apache" \
      io.openshift.tags="geocoding,nominatim" \
      name="centos/nominatim" \
      version="3.1.0" \
      usage="docker run -p 8080:8080 nominatim" \
      maintainer="Moritz Bunse <moritz.bunse@gmail.com>"

EXPOSE 8080

# from https://github.com/sclorg/postgresql-container/blob/generated/9.6/Dockerfile
COPY root/usr/libexec/fix-permissions /usr/libexec/fix-permissions
RUN chmod a+x /usr/libexec/fix-permissions

RUN yum install -y yum-utils && \
    yum install -y epel-release && \
    INSTALL_PKGS="cmake make gcc gcc-c++ libtool postgis postgis-utils postgresql-contrib postgresql-server proj-devel policycoreutils-python postgresql-devel php-pgsql php php-pear php-pear-DB php-intl libpqxx-devel php-pgsql php php-pear php-pear-DB php-intl libpqxx-devel proj-epsg bzip2-devel proj-devel libxml2-devel boost-devel expat-devel zlib-devel bzip2" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all && \
    localedef -f UTF-8 -i en_US en_US.UTF-8

#RUN useradd -u 30 -g root nominatim

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

RUN mkdir -p Nominatim-3.1.0/build && \
    /usr/libexec/fix-permissions ${HOME}

WORKDIR ${HOME}
RUN cmake .. && make

COPY root /
RUN chmod a+x /usr/libexec/* /usr/bin/run-nominatim

RUN /usr/libexec/httpd-prepare && /usr/libexec/nominatim-prepare

# Allow user to update /etc/passwd to insert himself
RUN chmod g=u /etc/passwd

# Nominatim user
USER 30

CMD ["/usr/bin/run-nominatim"]
