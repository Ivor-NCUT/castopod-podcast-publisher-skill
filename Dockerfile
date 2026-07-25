FROM castopod/castopod@sha256:4e4f0440520f45257bfeac7be4347defd20048b4efef8f53d73ec9ed3a4f7966

COPY docker/patch-rest-api.sh /tmp/patch-rest-api.sh
RUN sh /tmp/patch-rest-api.sh && rm /tmp/patch-rest-api.sh
