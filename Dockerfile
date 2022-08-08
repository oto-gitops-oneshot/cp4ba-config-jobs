FROM quay.io/openshift/origin-cli:v3.11.0
WORKDIR ~

COPY configure_db2.sh configure_db2.sh
COPY db2-cmd.sh db2-cmd.sh
RUN chmod a+x db2-cmd.sh
RUN chmod a+x configure_db2.sh
CMD ["./configure_db2.sh"]
