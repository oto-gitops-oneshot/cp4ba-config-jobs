FROM quay.io/openshift/origin-cli:v3.11.0
WORKDIR ~
COPY dbs/create_db.sh create_db.sh
COPY dbs/init_db.sh init_db.sh
RUN chmod a+x create_db.sh
RUN chmod a+x init_db.sh
CMD ["./create_db.sh"]
