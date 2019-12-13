FROM python:3.7
LABEL maintainer="Jorge Escobar escobar6@llnl.gov"

ENV MPBASE "/opt/MacPatch"
ENV MPSERVERBASE "$MPBASE/Server"
ENV MPSERVERCONFIG "$MPBASE/ServerConfig"
ENV OWNERGRP "www-data:www-data"

WORKDIR $MPBASE

# Install dependencies
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" >> /etc/apt/sources.list.d/yarn.list && \
    apt update && \
    apt -y install yarn swig

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
        $MPSERVERBASE/env && \
    touch $MPSERVERCONFIG/flask/conf_api.cfg && \
    touch $MPSERVERCONFIG/flask/conf_console.cfg

# Install yarn components
RUN yarn install --cwd $MPSERVERBASE/apps/mpconsole --modules-folder $MPSERVERBASE/apps/mpconsole/static/yarn_components --no-bin-links

# Create virtual environtments
ADD docker/requirements-server.txt $MPSERVERBASE/apps/requirements-server.txt
ADD docker/requirements-api.txt $MPSERVERBASE/apps/requirements-api.txt
ADD docker/requirements-console.txt $MPSERVERBASE/apps/requirements-console.txt
RUN python -m venv $MPSERVERBASE/env/server && \
    $MPSERVERBASE/env/server/bin/pip install -r $MPSERVERBASE/apps/requirements-server.txt && \
    python -m venv $MPSERVERBASE/env/api && \
    $MPSERVERBASE/env/api/bin/pip install -r $MPSERVERBASE/apps/requirements-api.txt && \
    python -m venv $MPSERVERBASE/env/console && \
    $MPSERVERBASE/env/console/bin/pip install -r $MPSERVERBASE/apps/requirements-console.txt

# Copy in config files
ADD docker/config/config.cfg $MPSERVERCONFIG/flask/config.cfg
ADD docker/config/siteconfig.json $MPSERVERCONFIG/etc/siteconfig.json
ADD docker/run.sh /run.sh

# Apply correct permissions and ownership
RUN chmod -R 0775 "$MPBASE" && \
    chown -R $OWNERGRP "$MPBASE"

VOLUME $MPBASE/Content

EXPOSE 80 443 3600

ENTRYPOINT ["/bin/bash", "/run.sh"]
