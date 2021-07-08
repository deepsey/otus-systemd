#!/bin/bash
 yum install -y epel-release

#Exercise #1

cp /vagrant/mymonitor.sh /root


cat <<'EOF1' | sudo tee /etc/sysconfig/mymonitor
LOGFILE=/var/log/messages
KEYWORD=monitoring
FILE=/root/monitor_file
EOF1


cat <<'EOF1' | sudo tee /etc/systemd/system/mymonitor.service
[Unit]
Description=Service for monitoring

[Service]
EnvironmentFile=/etc/sysconfig/mymonitor
ExecStart=/bin/bash /root/mymonitor.sh

[Install]
WantedBy=multi-user.target
EOF1


cat <<'EOF1' | sudo tee /etc/systemd/system/mymonitor.timer
[Unit]
Description=Timer For mymonitor service

[Timer]
OnUnitActiveSec=30s

[Install]
WantedBy=multi-user.target
EOF1

systemctl daemon-reload
systemctl enable mymonitor
systemctl enable mymonitor.timer
systemctl start mymonitor
systemctl start mymonitor.timer




#Exercise #2

yum install -y spawn-fcgi

cat <<'EOF1' | sudo tee /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=spawn-fcgi service

[Service]
ExecStart=/usr/bin/spawn-fcgi
EOF1




#Exercise #3
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
