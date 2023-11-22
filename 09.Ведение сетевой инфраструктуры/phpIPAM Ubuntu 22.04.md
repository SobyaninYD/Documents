
### Установка обновлений и git 

```bash
apt-get update && apt-get dist-upgrade -y && apt-get install git
```

### Установка Apache и MariaDB
```bash

apt install apache2 apache2-utils && systemctl enable apache2 && systemctl start apache2

apt install software-properties-common mariadb-server mariadb-client && systemctl enable mariadb && systemctl start mariadb

mysql_secure_installation
```

Выбираем вот так: 
> Set root password? [Y/n] y
 Remove anonymous users? [Y/n] y
 Disallow root login remotely? [Y/n] y
 Remove test database and access to it? [Y/n] y
 Reload privilege tables

Далее нам нужно будет войти в консоль MariaDB и создать базу данных для phpIPAM. Выполните следующую команду:

```bash
mysql -u root -p
```


```mysql
create database phpipamdb;
grant all on phpipamdb.* to phpipam@localhost identified by 'Planet2211';
FLUSH PRIVILEGES;
EXIT;
```

### Установка phpIPAM

Теперь мы загружаем phpIPAM, используя следующую `git` команду: 

```bash
git clone --recursive https://github.com/phpipam/phpipam.git /var/www/html/phpipam
```

Затем перейдите в каталог клонов:
```bash
cd /var/www/html/phpipam
```

После этого скопируйте в , как показано ниже: `config.dist.php``config.php`
```bash
cp config.dist.php config.php
```

Затем откройте файл и определите настройки своей базы данных: `config.php`
```bash
nano config.php
```

Сделайте следующие изменения:

```php
/ ** 
* database connection details
******************************/
$db['host'] = 'localhost';
$db['user'] = 'phpipam';
$db['pass'] = 'Your-Strong-Password';
$db['name'] = 'phpipamdb';
$db['port'] = 3306;
```

### Настройте Apache

Теперь мы создаем файл виртуального хоста для phpIPAM в нашей системе:

```bash
nano /etc/apache2/sites-enabled/phpipam.conf
```

Добавьте следующие строки:

```bash

<VirtualHost *:80>
    ServerAdmin ya.sobyanin@uksnegiri.ru DocumentRoot "/var/www/html/phpipam"
    ServerNameipam.10.1.16.209 ServerAlias www.10.1.16.209 <Directory "/var/www/html/phpipam">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog "/var/log/apache2/phpipam-error_log"
    CustomLog "/var/log/apache2/phpipam-access_log" combined
</VirtualHost>
```

Сохраните и закройте файл, затем перезапустите веб-сервер Apache, чтобы изменения вступили в силу:

```bash
a2enmod rewrite
a2ensite phpipam.conf
systemctl restart apache2
```

После этого смените владельца каталога на пользователя и группу www-data: `/var/www/`

```bash
chown -R www-data:www-data /var/www/html/
```

### Доступ к веб-интерфейсу PhpIPAM

После успешной установки откройте свой веб-браузер и введите URL-адрес . Вы будете перенаправлены на следующую страницу: `http://ip.service.corp/`
![[Pasted image 20230506171135.png]]





#документация 