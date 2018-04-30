FROM docker-registry.prod.internal.testing/lib/rhel7:7.1
MAINTAINER Sandeep Lamba <sandeep.lamba@cool.domain.com>

RUN yum -y update
RUN yum install -y epel-release
RUN yum -y update

RUN yum install -y wget bind-utils gcc tcl rubygem-redis make tar jq; yum clean all

WORKDIR /usr/src
RUN wget http://download.redis.io/releases/redis-4.0.9.tar.gz
RUN tar -xvf redis-4.0.9.tar.gz

WORKDIR /usr/src/redis-4.0.9/
RUN make
RUN make install
COPY redis-trib.rb /usr/src/redis-4.0.9/src/

ADD redis.conf /etc/

EXPOSE 6379 16379

ADD docker-entrypoint.sh /opt/

WORKDIR /opt/
RUN chmod +x docker-entrypoint.sh
CMD ["./docker-entrypoint.sh"]
