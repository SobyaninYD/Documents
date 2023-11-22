## Исходные данные
- Ubuntu 22.04
- Server, frontend agent
- Mysql
- Nginx

## Установка

### Добавление репозитория

```bash
wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu22.04_all.deb  
dpkg -i zabbix-release_6.0-4+ubuntu22.04_all.deb  
apt update
```

### Установка Zabbix сервера и агента
```bash
apt-get install zabbix-server-mysql zabbix-frontend-php zabbix-nginx-conf zabbix-sql-scripts zabbix-agent
```

### База данных
```bash
apt-get install mysql-server
```
```mysql
create database zabbix character set utf8mb4 collate utf8mb4_bin;
create user zabbix@localhost identified by 'zabbix';
grant all privileges on zabbix.* to zabbix@localhost;
set global log_bin_trust_function_creators = 1;
quit;
```

Импортируем начальную схему и данные:
```bash
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix
```
>Запросит пароль который указывали (zabbix)

Выключаем опцию log_bin_trust_function_creators после импорта схемы базы данных

```mysql
mysql -uroot -p  
password  
mysql> set global log_bin_trust_function_creators = 0;  
mysql> quit;
```

#### Настройка БД
В файле  `/etc/zabbix/zabbix_server.conf` в параметре *`DBPassword`* прописываем пароль:
```bash
DBPassword=password
```

#### Настройка PHP
Редактируем файл `/etc/zabbix/nginx.conf`
```php
listen 8080;  
server_name ip_adress_or_domain_name;
```

### Запуск
```bash
systemctl restart zabbix-server zabbix-agent nginx php8.1-fpm
systemctl enable zabbix-server zabbix-agent nginx php8.1-fpm
```

Далее переходим в вэб интерфейс и заканчиваем установку

![[Pasted image 20230607131329.png|Стандартный логин: Admin. Пароль: zabbix|350]]


## Zabbbix-Get

```bash
apt install zabbix-get
```

Проверить нагрузку на ЦП:
```bash
zabbix_get -s 192.168.1.147 -p 10050 -k system.cpu.load[all,avg1]
```
