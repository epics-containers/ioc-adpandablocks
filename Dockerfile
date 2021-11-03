# EPICS SynApps Dockerfile
ARG ADPANDABLOCKS_VERSION=4-14

##### build stage ##############################################################

FROM ghcr.io/epics-containers/epics-areadetector:3.10r3.0 AS developer

ARG ADPANDABLOCKS_VERSION

# install additional tools and libs
USER root

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
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
COPY --chown=${USER_UID}:${USER_GID} Makefile ${IOC}/iocApp/src

# update dependencies and build the support modules and the ioc
RUN python3 module.py dependencies && \
    make -C ${SUPPORT}/ADPandABlocks-${ADPANDABLOCKS_VERSION} && \
    make -C ${IOC} && \
    make  clean

##### runtime stage ############################################################

FROM ghcr.io/epics-containers/epics-areadetector:3.10r3.0.run AS runtime

ARG ADPANDABLOCKS_VERSION

# install runtime libraries from additional packages section above
USER root

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    libxml2 \
    libxslt1.1

USER ${USERNAME}

# get the products from the build stage
COPY --from=developer --chown=${USER_UID}:${USER_GID} ${SUPPORT}/ADPandABlocks-${ADPANDABLOCKS_VERSION} ${SUPPORT}/ADPandABlocks-${ADPANDABLOCKS_VERSION}
COPY --from=developer --chown=${USER_UID}:${USER_GID} ${IOC} ${IOC}
