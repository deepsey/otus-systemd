#!/bin/bash

yum install -y epel-release 
yum install -y nginx

cp /vagrant/nginx1.conf /vagrant/nginx2.conf /vagrant/nginx3.conf /etc/nginx

cat <<'EOF1' | sudo tee /etc/systemd/system/nginx@.service
[Unit]
Description=The nginx HTTP and reverse proxy server
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
# Nginx will fail to start if /run/nginx.pid already exists but has the wrong
# SELinux context. This might happen when running `nginx -t` from the cmdline.
# https://bugzilla.redhat.com/show_bug.cgi?id=1268621
ExecStartPre=/usr/bin/rm -f /run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx -c /etc/nginx/%i.conf
ExecReload=/usr/sbin/nginx -s reload
KillSignal=SIGQUIT
TimeoutStopSec=5
KillMode=process
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF1

setenforce 0

systemctl start nginx@nginx1.service
systemctl start nginx@nginx2.service
systemctl start nginx@nginx3.service
