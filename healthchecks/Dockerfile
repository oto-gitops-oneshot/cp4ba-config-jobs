FROM quay.io/openshift/origin-cli:v3.11.0
WORKDIR .
COPY patterns.sh patterns.sh
COPY hc_functions.sh hc_functions.sh
COPY options_check.sh options_check.sh
COPY patterns_check.sh patterns_check.sh
COPY core_check.sh core_check.sh
RUN chmod a+x core_check.sh && chmod a+x patterns_check.sh && chmod a+x options_check.sh
CMD [ "/bin/bash" ]

