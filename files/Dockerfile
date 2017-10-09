FROM mesoform/concierge-alpine-base-image:concierge-0.1.6

# Add some labels
LABEL maintainer="Gareth Brown <gareth@mesoform.com>"
LABEL description="Concierge maintained Consul Key Value Store Service Discovery and Dynamic Configuration for Mesoform"
LABEL com.mesoform.baseimage=False
LABEL com.joyent.autopilotpattern=True
LABEL com.mesoform.builddate="2017-10-09T13:46:21Z"
LABEL com.mesoform.baseimage.ver="mesoform/concierge-alpine-base-image:concierge-0.1.6"
LABEL com.docker.img.ver="mesoform/concierge-consul:0.1.6"

# Set some environment variables
ENV DOCKER_IMG_VER="mesoform/concierge-consul:0.1.6"
ENV DNS_DOMAIN=consul.dockerlx.oaas.mesoform.com
ENV CONSUL_AGENT=False
ENV CONSUL_VERSION=0.8.5
ENV CONSUL_CHECKSUM=35dc317c80862c306ea5b1d9bc93709483287f992fd0797d214d1cc1848e7b62

# Set some build arguments
ARG CONSUL_VERSION=0.8.5
ARG CONSUL_CHECKSUM=35dc317c80862c306ea5b1d9bc93709483287f992fd0797d214d1cc1848e7b62
ARG CONSUL_UI_CHECKSUM=4f7b90d8159480daeff6f3673f56fc75c00e4fd05de9c5c6d22a4af2fbc78368


# If we have an install script, run it.
RUN chmod -R +x /usr/local/bin/install.sh
RUN /usr/local/bin/install.sh

# Put Consul data on a separate volume to avoid filesystem performance issues
# with Docker image layers. Not necessary on Triton, but...
VOLUME [ "/data"  ]


# We don't need to expose these ports in order for other containers on Triton
# to reach this container in the default networking environment, but if we
# leave this here then we get the ports as well-known environment variables
# for purposes of linking.
EXPOSE 8300 8301 8301/udp 8302 8302/udp 8400 8500 53 53/udp 

# true should be lowercase http://jinja.pocoo.org/docs/2.9/templates/



