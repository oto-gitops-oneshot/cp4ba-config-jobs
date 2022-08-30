FROM quay.io/openshift/origin-cli:v3.11.0
WORKDIR .
COPY set_owner.sh set_owner.sh
COPY resources.txt resources.txt
RUN chmod a+x set_owner.sh && chmod a+r resources.txt
CMD [ "./set_owner.sh" ]

