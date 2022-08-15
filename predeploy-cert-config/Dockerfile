FROM registry.access.redhat.com/ubi9/ubi-minimal
LABEL maintainer="Mikhail Nikitin <mikhail.nikitin1@ibm.com>"
LABEL description="UBI9-minimal image with latest OpenShift and kubectl binaries"
WORKDIR ~
RUN microdnf update && microdnf install -y tar gzip wget && \
    wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux-4.11.0.tar.gz && \
    tar xzvf openshift-client-linux-4.11.0.tar.gz -C /usr/bin && rm openshift-client-linux-4.11.0.tar.gz && rm /usr/bin/README.md && \
    chmod +x /usr/bin/oc && chmod +x /usr/bin/kubectl && \
    microdnf remove -y wget && microdnf clean all
# RUN chmod a+x init_db.sh
RUN ["/usr/bin/oc", "version"]