# ДЗ по теме systemd

Стенд поднимается прилагаемым файлом Vagrantfile. Провижининг
организован через скрипт otus-systemd.sh.

## Описание скрипта otus-systemd.sh.

#!/bin/bash

#### Устанавливаем репозитрий epel

yum install -y epel-release  



### Задание № 1.Пишем сервис для мониторинга

#### Копируем файл со скриптом мониторинга лог-файла

cp /vagrant/mymonitor.sh /root

#### В этом файле:

cat $LOGFILE | grep $KEYWORD > $FILE

$LOGFILE - переменная имени лога  
$KEYWORD - переменная для ключевого слова  
$FILE - переменная имени файла, в который будут выводится строки с ключевым словом  

Значения переменных определяются в файле /etc/sysconfig/mymonitor (см. ниже)

#### Создаем файл с переменными для нашего юнита mymonitor.service:

cat <<'EOF1' | sudo tee /etc/sysconfig/mymonitor
LOGFILE=/var/log/messages
KEYWORD=monitoring
FILE=/root/monitor_file
EOF1


#### Создаем файл юнита и таймер для него:

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
  
  
#### Активируем и запускаем юниты

systemctl daemon-reload  
systemctl enable mymonitor  
systemctl enable mymonitor.timer  
systemctl start mymonitor  
systemctl start mymonitor.timer  
  

В результате с заданной периодичностью в файл /root/monitor_file будут записываться  
строки из /var/log/messages, содержащие ключевое слово "monitoring".  







### Задание № 2. Из репозитория epel устанавливаем spawn-fcgi и 
### переписываем init-скрипт на unit-файл

yum install -y spawn-fcgi

cat <<'EOF1' | sudo tee /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=spawn-fcgi service

[Service]
ExecStart=/usr/bin/spawn-fcgi
EOF1



### Задание №3. Дополняем файл юнита nginx возможностьтю запуска
### нескольких инстансов сервера с разными конфигурационными файлами

#### Устанавливаем nginx, создаем несколько файлов конфигураций в /etc/nginx, 
#### копируем конфигурации в /etc/nginx

yum install epel-release nginx  
  
cp /vagrant/nginx1.conf /vagrant/nginx2.conf /vagrant/nginx3.conf /etc/nginx  

#### Создаем сервис для запуска нескольких экземпляров nginx

cat <<'EOF1' | sudo tee /etc/systemd/system/nginx@.service  
[Unit]  
Description=The nginx HTTP and reverse proxy server  
After=network-online.target remote-fs.target nss-lookup.target  
Wants=network-online.target  
  
[Service]  
Type=forking  
PIDFile=/run/nginx.pid  
#Nginx will fail to start if /run/nginx.pid already exists but has the wrong  
#SELinux context. This might happen when running `nginx -t` from the cmdline.  
#https://bugzilla.redhat.com/show_bug.cgi?id=1268621  
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
  
#### Отключаем Selinux
  
setenforce 0  
  
  
#### Запускаем сервисы

systemctl start nginx@nginx1.service  
systemctl start nginx@nginx2.service  
systemctl start nginx@nginx3.service  


#### Заходим по адресам nginx, убеждаемся, что все работает

curl http://localhost:82  
curl http://localhost:83  
curl http://localhost:84  
