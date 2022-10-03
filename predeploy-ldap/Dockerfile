FROM quay.io/openshift/origin-cli:v3.11.0
WORKDIR ~
COPY cm.yaml /tmp/cm.yaml
COPY predeploy.sh predeploy.sh
RUN chmod a+x predeploy.sh
RUN chmod a+rw /tmp/cm.yaml
RUN chgrp -R 0 /tmp && \
    chmod -R g=u /tmp
CMD ["./predeploy.sh"]
