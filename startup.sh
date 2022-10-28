#!/bin/bash

set -e

declare CERTIFICATE_SECRET_NAME=`curl --silent "http://metadata.google.internal/computeMetadata/v1/instance/attributes/CERTIFICATE_SECRET_NAME" -H "Metadata-Flavor: Google"`
declare CERTIFICATE_KEY_SECRET_NAME=`curl --silent "http://metadata.google.internal/computeMetadata/v1/instance/attributes/CERTIFICATE_KEY_SECRET_NAME" -H "Metadata-Flavor: Google"`
echo "Downloading certificate and keys"
chmod 705 /etc/ssl/private
gcloud secrets versions access "latest" --secret=$CERTIFICATE_KEY_SECRET_NAME > /etc/ssl/private/haproxy.pem.key
gcloud secrets versions access "latest" --secret=$CERTIFICATE_SECRET_NAME > /etc/ssl/private/haproxy.pem

echo "Installing Google Logging Agent"
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

echo "Check if haproxy is installed"

if ! apt list --installed | grep haproxy 2> /dev/null 1> /dev/null ; then
        echo "Installing haproxy"
        apt install haproxy -y
else
        echo "HA proxy s already installed"
fi

echo "Setting variables for haproxy"

sed -i '/CLEARBLADE_IP/d' /etc/default/haproxy
sed -i '/CERTIFICATE/d' /etc/default/haproxy
sed -i '/CLEARBLADE_MQTT_IP/d' /etc/default/haproxy

echo CLEARBLADE_IP=`curl --silent "http://metadata.google.internal/computeMetadata/v1/instance/attributes/CLEARBLADE_IP" -H "Metadata-Flavor: Google"` >>  /etc/default/haproxy
echo CLEARBLADE_MQTT_IP=`curl --silent "http://metadata.google.internal/computeMetadata/v1/instance/attributes/CLEARBLADE_MQTT_IP" -H "Metadata-Flavor: Google"` >>  /etc/default/haproxy
declare CERTIFICATE=/etc/ssl/private/haproxy.pem

echo "Applying haproxy configuration"

cat <<EOT > /etc/haproxy/haproxy.cfg
global
        log stdout    local0
        log stdout    local1 notice
        chroot /var/lib/haproxy
        stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
        stats timeout 30s
        user haproxy
        group haproxy
        daemon

        # Default SSL material locations
        ca-base /etc/ssl/certs
        crt-base /etc/ssl/private

        # See: https://ssl-config.mozilla.org/#server=haproxy&server-version=2.0.3&config=intermediate
        #ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
        #ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
        #ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
        log     global
        mode    http
        option  httplog
        option  dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000
        errorfile 400 /etc/haproxy/errors/400.http
        errorfile 403 /etc/haproxy/errors/403.http
        errorfile 408 /etc/haproxy/errors/408.http
        errorfile 500 /etc/haproxy/errors/500.http
        errorfile 502 /etc/haproxy/errors/502.http
        errorfile 503 /etc/haproxy/errors/503.http
        errorfile 504 /etc/haproxy/errors/504.http

frontend frontend_console
        mode http
        log global
        option httplog
        option http-server-close
        bind *:8080
        bind *:8443 ssl crt $CERTIFICATE
        timeout server 20m
        default_backend backend_console

backend backend_console
        mode http
        server console_call \$CLEARBLADE_IP:443 ssl verify none

listen mqtt_auth
      mode tcp
      option tcplog
      bind *:8905
      bind *:8906 ssl crt $CERTIFICATE
      server clearblade \$CLEARBLADE_IP:8905 check inter 10000

listen mqtt
     mode tcp
     option tcplog
     bind *:8883 ssl crt $CERTIFICATE
     bind *:443 ssl crt $CERTIFICATE
     server clearblade \$CLEARBLADE_MQTT_IP:443 check inter 10000 ssl verify none


listen mqtt_ws_auth
      mode tcp
      log global
      option tcplog
      bind *:8906
      bind *:8907 ssl crt $CERTIFICATE
      server clearblade \$CLEARBLADE_IP:8907 check inter 10000

listen mqtt_ws
      mode tcp
      log global
      option tcplog
      bind *:8903
      bind *:8904 ssl crt $CERTIFICATE
      server clearblade \$CLEARBLADE_IP:8904 check inter 10000 ssl verify none

EOT

echo "Setting up Cloud Agent"

cat <<EOT > /etc/google-cloud-ops-agent/config.yaml
logging:
  receivers:
    syslog:
      type: files
      include_paths:
      - /var/log/haproxy.log
  service:
    pipelines:
      default_pipeline:
        receivers: [syslog]
EOT

echo "Restarting Cloud Agent"
systemctl restart google-cloud-ops-agent
echo "Restarting haproxy"
systemctl restart haproxy