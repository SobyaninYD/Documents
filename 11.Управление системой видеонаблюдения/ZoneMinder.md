## Требования к ПО

- Ubuntu 22.04/20.04/18.04  
- Веб-сервер Apache  
- PHP и MySQL  
- Пользователь с правами **sudo** 
- Подключение К Интернету

## Установка

Проверяем все ли обновления установлены
```bash
apt-get update && apt-get dist-upgrade -y
```

### Установка LAMP
```bash
apt-get install apache2 mysql-server php -y
systemctl enable --now apache2 mysql
systemctl status apache2 mysql --no-pager -l
```

### Добавление PPA

Проверяем доступные версии:
```bash
add-apt-repository ppa:iconnor/zoneminder-version
```
![[Pasted image 20230524141617.png|Проверка доступных версий ZoneMinder]]

 Видим, что последняя доступная версия 1.36. Ее и будем использовать
 ```bash
 sudo add-apt-repository ppa:iconnor/zoneminder-1.36
```

После добавления репозитория обновляем пакеты и ставим последние обновления
```bash
apt-get update && sudo apt-get dist-upgrade
```

### Установка ZoneMinder

```bash
apt-get install zoneminder
```

### MySQL

```bash
rm /etc/mysql/my.cnf
cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/my.cnf
nano /etc/mysql/my.cnf
```

Добавляем в конец файла **`/etc/mysql/my.cnf`** строчку `sql_mode = NO_ENGINE_SUBSTITUTION`
```mysql
sql_mode = NO_ENGINE_SUBSTITUTION
```

### Apache

Даем разрешение на доступ пользователю **`www-data`** к файлам ZoneMinder 
```bash
chmod 740 /etc/zm/zm.conf
chown root:www-data /etc/zm/zm.conf
chown -R www-data:www-data /usr/share/zoneminder/
```

Включаем модули Apache:
```bash
a2enmod cgi rewrite expires headers
```

Включаем конфигурацию виртуального хоста ZoneMinder
```bash
a2enconf zoneminder
```

В **`php.ini`** указываем правильную временную зону

```bash
nano /etc/php/*/apache2/php.ini
```
![[Pasted image 20230524142830.png|Часовой пояс +5 Екатеринбург]]


### Запуск

Включаем и запускам службы ZoneMinder
```bash
systemctl enable zoneminder
systemctl start zoneminder
```

Перезапускаем **Apache**
```bash
systemctl reload apache2
```

#### Доступ к вэб-интерфейсу

В браузере переходим по адресу **`http//:server-ip-address/zm`** , где `server-ip-address` - это адрес Вашего сервера ZoneMinder.

![[Pasted image 20230524143314.png|Соглашаемся]]

![[Pasted image 20230524143351.png|Вэб-интерфейс]]

## Работа с ZoneMinder
.......


## Удаление ZoneMinder

```bash
apt-get autoremove --purge zoneminder
add-apt-repository --remove ppa:iconnor/zoneminder-master
apt-apt autoremove --purge apache2 mysql-server php
```

#ZoneMinder #Видеонаблюдение 