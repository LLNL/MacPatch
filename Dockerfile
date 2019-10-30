FROM centos:7
LABEL maintainer="Jorge Escobar escobar6@llnl.gov"

ENV MPBASE "/opt/MacPatch"
ENV MPSERVERBASE "/opt/MacPatch/Server"
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

RUN pip install virtualenv

RUN useradd -r -M -s /dev/null -U www-data


# Setup directory structure
ADD Source/Server $MPSERVERBASE
RUN mkdir -p $MPBASE/Content/Web/clients \
    $MPBASE/Content/Web/patches \
    $MPBASE/Content/Web/sav \
    $MPBASE/Content/Web/sw \
    $MPBASE/Content/Web/tools \
    $MPSERVERBASE/InvData/files \
    $MPSERVERBASE/lib \
    $MPSERVERBASE/logs \
    $MPSERVERBASE/etc/ssl \
    $MPSERVERBASE/apps/log


# Create virtual environment
RUN virtualenv --no-site-packages $MPSERVERBASE/venv
RUN source $MPSERVERBASE/venv/bin/activate && \
    pip install pycrypto \
    argparse \
    biplist \
    python-dateutil \
    requests \
    six \
    wheel \
    mysql-connector-python-rf \
    python-crontab


# Run yarn
WORKDIR $MPSERVERBASE/apps/mpconsole
RUN yarn install --cwd $MPSERVERBASE/apps/mpconsole --modules-folder static/yarn_components --no-bin-links


# Create virtual environtment for flask apps
# ADD docker/pyRequired.txt $MPSERVERBASE/apps/pyRequired.txt
# RUN virtualenv --no-site-packages $MPSERVERBASE/apps/env
# RUN source $MPSERVERBASE/apps/env/bin/activate && \
#     pip install m2crypto --no-cache-dir --upgrade && \
#     pip install -r $MPSERVERBASE/apps/pyRequired.txt

# Create virtual environtments
ADD docker/requirement-server.txt $MPSERVERBASE/apps/requirements-server.txt
ADD docker/requirement-api.txt $MPSERVERBASE/apps/requirements-api.txt
ADD docker/requirement-console.txt $MPSERVERBASE/apps/requirements-console.txt
RUN python3 -m $MPSERVERBASE/env/server \
    python3 -m $MPSERVERBASE/env/api \
    python3 -m $MPSERVERBASE/env/console
RUN source $MPSERVERBASE/env/server/bin/activate && \
    pip install -r $MPSERVERBASE/apps/requirements-server.txt
RUN source $MPSERVERBASE/env/api/bin/activate && \
    pip install -r $MPSERVERBASE/apps/requirements-api.txt
RUN source $MPSERVERBASE/env/console/bin/activate && \
    pip install -r $MPSERVERBASE/apps/requirements-console.txt

# Copy in config files
ADD docker/config/config.cfg $MPSERVERBASE/apps/config.cfg
ADD docker/config/siteconfig.json $MPSERVERBASE/etc/siteconfig.json
ADD docker/supervisord.conf $MPSERVERBASE/supervisord/supervisord.conf
ADD docker/nginx/nginx.conf /etc/nginx/nginx.conf
ADD docker/nginx/sites /etc/nginx/sites/
ADD docker/run.sh /run.sh


# Apply permissions and ownership
RUN chmod -R 0775 "$MPBASE/Content" \
    "$MPSERVERBASE/logs" \
    "$MPSERVERBASE/etc" \
    "$MPSERVERBASE/InvData"
RUN chmod 2777 "$MPSERVERBASE/apps/log"
RUN chown -R $OWNERGRP $MPBASE


# Cleanup
RUN find $MPBASE -name ".mpRM" -print | xargs -I{} rm -rf {}


VOLUME $MPBASE/Content

EXPOSE 80 443 3600

ENTRYPOINT ["/bin/bash", "/run.sh"]
