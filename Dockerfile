# EPICS SynApps Dockerfile
ARG REGISTRY=gcr.io/diamond-privreg/controls/prod
ARG ADCORE_VERSION=3.10b1.1

FROM ${REGISTRY}/epics/epics-adcore:${ADCORE_VERSION}

ARG ADPANDABLOCKS_VERSION=4-10

# install additional tools and libs
USER root

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    libboost-dev \
    libxml2-dev \
    libxslt1-dev

# get additional support modules
USER ${USERNAME}

# move etc out the way of the Makefile since we dont have iocbuilder
RUN ./add_module.sh PandABlocks ADPandABlocks ADPANDABLOCKS ${ADPANDABLOCKS_VERSION} && \
    mv ADPandABlocks-${ADPANDABLOCKS_VERSION}/etc ADPandABlocks-${ADPANDABLOCKS_VERSION}/_etc

# add CONFIG_SITE.linux and RELEASE.local
COPY --chown=${USER_UID}:${USER_GID} configure \
      ${SUPPORT}/ADPandABlocks-${ADPANDABLOCKS_VERSION}/configure

# update dependencies and build
RUN make release && \
    make -C ADPandABlocks-${ADPANDABLOCKS_VERSION} && \
    make -C ADPandABlocks-${ADPANDABLOCKS_VERSION} clean

# update the generic IOC Makefile
COPY --chown=${USER_UID}:${USER_GID} Makefile ${SUPPORT}/ioc/iocApp/src

# update dependencies and build (separate step for efficient image layers)
RUN make release && \
    make -C ioc && \
    make -C ioc clean
