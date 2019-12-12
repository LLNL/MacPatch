FROM centos:7
LABEL maintainer="Jorge Escobar escobar6@llnl.gov"

ENV MPBASE "/opt/MacPatch"
ENV MPSERVERBASE "$MPBASE/Server"
ENV MPSERVERCONFIG "$MPBASE/ServerConfig"
ENV OWNERGRP "www-data:www-data"


# Provision OS
RUN curl -sLk https://dl.yarnpkg.com/rpm/yarn.repo -o /etc/yum.repos.d/yarn.repo
RUN yum -y update && \
    yum -y groupinstall "Development tools" && \
    yum -y install epel-release && \
    yum -y install gcc \
        gcc-c++ \
        zlib-devel \
        pcre-devel \
        openssl \
        openssl-devel \
        python3-devel \
        python3-setuptools \
        python3 \
        python3-pip \
        swig \
        yarn \
        supervisor \
        nginx

RUN pip3 install --upgrade pip virtualenv

RUN useradd -r -M -s /dev/null -U www-data


# Setup MacPatch directory structure
ADD Source/Server $MPSERVERBASE
RUN mkdir -p $MPBASE/Content/Web/clients \
        $MPBASE/Content/Web/patches \
        $MPBASE/Content/Web/sav \
        $MPBASE/Content/Web/sw \
        $MPBASE/Content/Web/tools \
        $MPSERVERBASE/InvData/files \
        $MPSERVERBASE/lib \
        $MPSERVERBASE/etc/ssl \
        $MPSERVERBASE/logs \
        $MPSERVERCONFIG/etc \
        $MPSERVERCONFIG/flask \
        $MPSERVERCONFIG/jobs \
        $MPSERVERCONFIG/logs/apps \
    touch $MPSERVERCONFIG/flask/conf_api.cfg && \
    touch $MPSERVERCONFIG/flask/conf_console.cfg


# Run yarn
WORKDIR $MPSERVERBASE/apps/mpconsole
RUN yarn install --cwd $MPSERVERBASE/apps/mpconsole --modules-folder static/yarn_components --no-bin-links


# Create virtual environtments
ADD docker/requirements-server.txt $MPSERVERBASE/apps/requirements-server.txt
ADD docker/requirements-api.txt $MPSERVERBASE/apps/requirements-api.txt
ADD docker/requirements-console.txt $MPSERVERBASE/apps/requirements-console.txt
RUN mkdir -p $MPSERVERBASE/env && \
    python3 -m venv $MPSERVERBASE/env/server && \
    $MPSERVERBASE/env/server/bin/pip3 install -r $MPSERVERBASE/apps/requirements-server.txt && \
    python3 -m venv $MPSERVERBASE/env/api && \
    $MPSERVERBASE/env/api/bin/pip3 install -r $MPSERVERBASE/apps/requirements-api.txt && \
    python3 -m venv $MPSERVERBASE/env/console && \
    $MPSERVERBASE/env/console/bin/pip3 install -r $MPSERVERBASE/apps/requirements-console.txt

# Copy in config files
ADD docker/config/config.cfg $MPSERVERCONFIG/flask/config.cfg
ADD docker/config/siteconfig.json $MPSERVERCONFIG/etc/siteconfig.json
ADD docker/supervisord.conf $MPSERVERBASE/supervisord/supervisord.conf
ADD docker/nginx/nginx.conf /etc/nginx/nginx.conf
ADD docker/nginx/sites /etc/nginx/sites/
ADD docker/nginx/ssl/server.crt /etc/ssl/server.crt
ADD docker/nginx/ssl/server.key /etc/ssl/server.key
ADD docker/run.sh /run.sh


# Apply permissions and ownership
RUN chmod -R 0775 "$MPBASE/Content" \
    "$MPSERVERCONFIG" \
    "$MPSERVERBASE/InvData" \
    "$MPSERVERCONFIG/logs" \
    "$MPSERVERCONFIG/etc"
RUN chown -R $OWNERGRP "$MPBASE"


# Cleanup
RUN find $MPBASE -name ".mpRM" -print | xargs -I{} rm -rf {}


VOLUME $MPBASE/Content

EXPOSE 80 443 3600

ENTRYPOINT ["/bin/bash", "/run.sh"]
