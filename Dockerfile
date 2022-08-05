FROM quay.io/openshift/origin-cli:v3.11.0
WORKDIR ~
COPY configure configure
RUN chmod +x configure
RUN chmod +x configure/configure_db2.sh
CMD ["./configure/configure_db2.sh"]
