#!/bin/sh
set -e

echo "Generating envoy.yaml config file..."
envsubst < /tmpl/envoy.yaml.tmpl > /etc/envoy.yaml

#cat /tmpl/envoy.yaml.tmpl | envsubst \$APIGEE_NAMESPACE,\$SERVICE_NAME > /etc/envoy.yaml

echo "Starting Envoy..."
/usr/local/bin/envoy -c /etc/envoy.yaml