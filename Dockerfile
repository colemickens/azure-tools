FROM mhart/alpine-node:6.4.0

RUN apk add --update bash
ADD ./docker-build.sh /tmp/
RUN /tmp/docker-build.sh

WORKDIR /opt/azure-tools
ADD ./context /opt/azure-tools
ADD ./trylogin.sh /tmp/

CMD /tmp/trylogin.sh && bash -l
