# Установка
## Подготовка

Первым делом отключаем selinux. Для этого открываем файл: `/etc/sysconfig/selinux` и устанавливаем значение **SELINUX=disabled**.

```bash
setenforce 0
```

Дальше обновляем систему и ставим пакеты Development Tools:
```bash
yum update
yum groupinstall core base "Development Tools"
```

## Установка БД

В своей работе FreePBX использует базу данных Mysql. В качестве mysql сервера будет mariadb. Подключаем репозиторий со свежей версией MariaDB. Для этого создаем файл `/etc/yum.repos.d/MariaDB.repo` и добавляем:
```bash
# MariaDB 10.3 CentOS repository list - created 2019-04-01 09:11 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
```
Далее ставим mariadb
```bash
yum install MariaDB-server MariaDB-client MariaDB-shared
```

Запускаем mariadb и добавляем в автозагрузку
```bash
systemctl enable mariadb --now
```

## Настройка Web сервера

Подключаем репозиторий epel
```bash
yum install epel-release
```

Подключаем remi репозиторий для centos 7

```bash
rpm -Uhv http://rpms.remirepo.net/enterprise/remi-release-7.rpm
```

Ставим пакет yum-utils
```bash
yum install yum-utils
```

Активируем remi-php74

```bash
yum-config-manager --enable remi-php74
```

Устанавливаем необходимые пакеты для работы сервера voip
```bash
yum install wget php php-pear php-cgi php-common php-curl php-mbstring php-gd php-mysql php-gettext php-bcmath php-zip php-xml php-imap php-json php-process php-snmp httpd
```

Теперь нам нужно изменить некоторые параметры httpd - запустить его от пользователя asterisk и включить опцию AllowOverride

```bash
sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/httpd/conf/httpd.conf
sed -i 's/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
```

httpd запускать пока не надо, так как пользователя asterisk мы еще не создали. Сделаем это после установки asterisk.

Поправим значение `upload_max_filesize` до 128М в `/etc/php.ini` 
```bash
upload_max_filesize = 120M
```

%%Или автоматом:
```bash
sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php.ini
```
%%

## Установка NodeJS

Для работы Freepbx требуется сервер NodeJS. Подключаем репозиторий NodeJS с помощью скрипта автоматизации от разработчика

```bash
curl -sL https://rpm.nodesource.com/setup_10.x | bash -
yum clean all && sudo yum makecache fast
yum install gcc-c++ make nodejs
node -v
```

Если видим номер версии, значит установка прошла успешно.

## Установка Asterisk

Качаем архив с оф сайта
```bash
cd ~ && wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20-current.tar.gz
```

Распаковываем и переходим в папку:
```bash
tar zxvf asterisk-*.tar.gz
cd asterisk*
```

Выполняем скрипт для установки пакетов с зависимостями для asterisk
```bash
contrib/scripts/install_prereq install
```

Запускаем скрипт для скачивания исходников для работы с mp3
```bash
contrib/scripts/get_mp3_source.sh
```

Настраиваем конфигурацию
```bash
./configure --with-pjproject-bundled --with-jansson-bundled --with-crypto --with-ssl=ssl --with-srtp
```

Запускаем выбор надстроек
 ```bash
 make menuselect
```

![[Pasted image 20230629100758.png]]

![[Pasted image 20230629100825.png]]

![[Pasted image 20230629100939.png]]

![[Pasted image 20230629101004.png]]

![[Pasted image 20230629101017.png]]

Запускаем установку asterisk
```bash
make && make install && make config && make samples && ldconfig
```

Настроим запуск астериск от системного пользователя asterisk
```bash
sed -i 's/ASTARGS=""/ASTARGS="-U asterisk"/g' /usr/sbin/safe_asterisk
```

Создадим этого пользователя и назначим нужные права на каталоги

```bash
useradd -m asterisk
# chown asterisk.asterisk /var/run/asterisk
# chown -R asterisk.asterisk /etc/asterisk
# chown -R asterisk.asterisk /var/{lib,log,spool}/asterisk
# chown -R asterisk.asterisk /usr/lib/asterisk
```

Запускаем
```bash
systemctl start asterisk && systemctl status asterisk
```

## Установка и настройка Freepbx

Скачиваем архив с оф сайта:
```bash
cd ~ && wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-16.0-latest.tgz
```

Распаковываем, переходим в распакованный каталог и выполняем скипт
```bash
tar xvfz freepbx-*.tgz && cd freepbx && ./start_asterisk start
```

Если результат выполнения:
```bash
STARTING ASTERISK
Asterisk is already running
```

То запускаем установку:
```bash
./install -n
```

> Если будет ошибка связанная с php, то запускаем установку еще раз. Должно пройти без ошибок. Но freepbx не будет работать должным образом. 
> Что бы все работало как надо необходимо в конце файла `/etc/asterisk/manager.conf`  заменить
```bash
#include manager_additional.conf
#include manager_custom.conf
```
>на:
```bash
;include manager_additional.conf
;include manager_custom.conf
```
Так же необходимо что бы параметр `secret` имел значение `amp111`
![[Pasted image 20230629102438.png]]


Отключаем firewall
```bash
systemctl stop firewalld && systemctl disable firewalld
```

Так же в iptables разрешаем порты: 80, 5060, 5061, 4569, 5038, 10000-20000.
```bash
iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT \
iptables -A INPUT -p udp -m udp --dport 5060 -j ACCEPT \
iptables -A INPUT -p udp -m udp --dport 5061 -j ACCEPT \
iptables -A INPUT -p tcp -m tcp --dport 5060 -j ACCEPT \
iptables -A INPUT -p tcp -m tcp --dport 5061 -j ACCEPT \
iptables -A INPUT -p udp -m udp --dport 4569 -j ACCEPT \
iptables -A INPUT -p tcp -m tcp --dport 5038 -j ACCEPT \
iptables -A INPUT -p udp -m udp --dport 5038 -j ACCEPT \
iptables -A INPUT -p udp -m udp --dport 10000:20000 -j ACCEPT
```

Запускаем httpd
```bash
systemctl enable httpd --now
```

Установка закончена Freepbx. Переходим в браузер по ip адресу сервера
![[Pasted image 20230629103024.png]]



# Настройка

## Подключение абонентов и проверка внутренних звонков










Когда выдавало сообщение что core поврежден помогла первая команда:
fwconsole ma refreshsignatures
fwconsole ma upgrade core