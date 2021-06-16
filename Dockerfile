# EPICS SynApps Dockerfile
ARG REGISTRY=ghcr.io/epics-containers
ARG ADCORE_VERSION=3.10r1.0

FROM ${REGISTRY}/epics-adcore:${ADCORE_VERSION}

ARG ADPANDABLOCKS_VERSION=4-12

# install additional tools and libs
USER root

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    libboost-dev \
    libxml2-dev \
    libxslt1-dev

USER ${USERNAME}

# get additional support modules
RUN python3 module.py add PandABlocks ADPandABlocks ADPANDABLOCKS ${ADPANDABLOCKS_VERSION}

# add CONFIG_SITE.linux and RELEASE.local
COPY --chown=${USER_UID}:${USER_GID} configure \
      ${SUPPORT}/ADPandABlocks-${ADPANDABLOCKS_VERSION}/configure
# move etc out the way of the Makefile since we dont have iocbuilder
RUN mv ADPandABlocks-${ADPANDABLOCKS_VERSION}/etc ADPandABlocks-${ADPANDABLOCKS_VERSION}/_etc

# update the generic IOC Makefile to include the new support
COPY --chown=${USER_UID}:${USER_GID} Makefile ${SUPPORT}/ioc/iocApp/src

# update dependencies and build
# update dependencies and build the support modules and the ioc
RUN python3 module.py dependencies && \
    make && \
    make  clean
