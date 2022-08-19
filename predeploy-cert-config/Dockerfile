FROM registry.access.redhat.com/ubi9/ubi-minimal
LABEL maintainer="Mikhail Nikitin, Langley M"
LABEL description="UBI9-minimal image with latest OpenShift and kubectl binaries"
WORKDIR ~
COPY cert_gen.sh cert_gen.sh
RUN chmod a+x cert_gen.sh
# RUN mkdir certs
# RUN chmod 777 -R certs
RUN microdnf update && microdnf install -y tar gzip openssl wget && \
    # wget https://mirror.openshift.com/pub/openshift-v3/clients/3.11.0-0.10.0/linux/oc.tar.gz && \
    wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux-4.11.0.tar.gz && \
    # tar xzvf oc.tar.gz -C /usr/bin && rm oc.tar.gz &&  \
    tar xzvf openshift-client-linux-4.11.0.tar.gz -C /usr/bin && rm openshift-client-linux-4.11.0.tar.gz && rm /usr/bin/README.md && \
    chmod +x /usr/bin/oc && chmod +x /usr/bin/kubectl && \
    # chmod +x /usr/bin/oc && \
    microdnf remove -y wget && microdnf clean all
# RUN chmod a+x init_db.sh
CMD ["./cert_gen.sh"]