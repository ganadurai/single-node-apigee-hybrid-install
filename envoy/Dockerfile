FROM envoyproxy/envoy:v1.24-latest

COPY envoy-config-proxy.yaml /tmpl/envoy.yaml.tmpl
COPY envoy-entrypoint.sh /

RUN chmod 500 /envoy-entrypoint.sh

RUN apt-get update && \
    apt-get install gettext -y

ENTRYPOINT ["/envoy-entrypoint.sh"]