FROM castopod/castopod:4.3.2

COPY docker/patch-rest-api.sh /tmp/patch-rest-api.sh
RUN sh /tmp/patch-rest-api.sh && rm /tmp/patch-rest-api.sh
