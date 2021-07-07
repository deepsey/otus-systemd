# ДЗ по теме systemd

#### Дополняем файл юнита nginx возможностьтю запуска
#### нескольких инстансов сервера с разными конфигурационными файлами

Устанавливаем nginx, создаем несколько файлов конфигураций в /etc/nginx  

yum install epel-release nginx

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




Задание 1.

/etc/systemd/system/mymonitor.service

[Unit]
Description=Service for monitoring

[Service]
EnvironmentFile=/etc/sysconfig/mymonitor
ExecStart=/bin/bash /root/script.sh

[Install]
WantedBy=multi-user.target

vi /root/script.sh

#!/bin/bash

cat $LOGFILE | grep $KEYWORD > $FILE

vi /etc/sysconfig/mymonitor

LOGFILE=/var/log/messages
KEYWORD=mymonitor
FILE=/root/monitor_file










Скрипт script.sh осуществляет обработку файла access.log. Для создания
цикла обработки исходный из исходного файла последовательно выбираются
100 строк, информация из которых затем структурируется и отсылается на
почту пользователю root. Почтовым клиентом выступает mutt. К ДЗ приложен
Vagrantfile, который провижинионируется скриптом otus-bash.sh.
Файл otus-bash.sh снабжен необходимыми комментариями.

### Описание скрипта script.sh

#!/bin/bash

#### Пишем защиту от мультизапуска

lockfile=/root/lockfile

if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null;   
then  
  trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT  

#### Создаем файл счетчика строк исходного файла  

  if [[ ! -e /root/count.src ]]; then count=1>/root/count.src; fi  
  source /root/count.src  

#### Проверяем, не дошли ли мы до конца файла. Если да, возвращаем значение счетчика на начальную позицию

  if [ $count -gt 670 ]; then echo count=1 > /root/count.src; count=1;fi  

#### Увеличиваем конечное значение счетчика строк

  count2=$(expr $count + 100)

#### Выводим строки в файл access1.log 

  sed -n $count,${count2}p /root/access.log > /root/access1.log

#### Пишем новое значение счетчика строк

  echo count=$count2 > /root/count.src


#### Обрабатываем файл access1.log и отправляем результаты на почту root 
  {
  echo "Statistic for period from"  
  head -n 1 /root/access1.log | awk '{print $4 " " $5}'  
  echo "to"  
  tail -n 1 /root/access1.log | awk '{print $4 " " $5}'  

  echo ""  

  echo "10 IP addresses with maximal count of requests:"  

  cat /root/access1.log | awk '{print $1}' | sort | uniq -c | sort -bgr | head -n 10  

  echo "10 URI with maximal count of requests:"  

  cat /root/access1.log | awk '{print $7}' | sort | uniq -c | sort -bgr | head -n 10  

  echo "HTTP status codes and their count:"  

  cat /root/access1.log | awk '{print $9}' | sort | uniq -c | sort -bgr | grep -v "-"  
  
  echo "Failed requests:"  
  
  cat /root/access1.log | grep -v "HTTP"  

  } | mutt -s "Analize of access.log" -- root@${HOSTNAME}  


  rm -f "${lockfile}"  
  trap - INT TERM EXIT  
 EXIT  
else    
  echo "Failed to acquire lockfile: $lockfile."  
  echo "Held by $(cat $lockfile)"  
fi  

