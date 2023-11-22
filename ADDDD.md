Задача состояла не просто миграция на Ад на новый сервер, а поднятие нового АД взаимодействие которого с старым доменом сводится только к доверительным отношениям между доменами что бы на новый ад не перетянулись ни какие хвосты со старого ад.

# Поднятие AD

После установки windows server ставим все обновления.  
Задаем статический ip адрес.  
Открываем диспетчер серверов. Выбираем **Управление -> Добавить роли и компоненты**.  
Роли выбираем как на скрине  
![pasted_image_20231019090348.png](https://wiki.ipsyd.ru/screen/windows/1-ad/pasted_image_20231019090348.png)

осле установки повышаем сервер до контроллера домена.

# Экспорт и импорт пользователей между AD

После экспорта и импорта необходимо руками сопоставить группы и пользователей. Скриптом у меня этого сделать не получилось.

## Выгружаем пользователей и группы из старого AD в .csv

Для данный целей подготовлены скрипты:

1. Для выгрузки пользователей и их данных

```powershell
# Задайте путь, куда сохранить CSV-файл с данными пользователей
$exportFilePath = "\\AD1\share\ADUsers2.csv"
# Получаем информацию о пользователях с сервера service.corp
$users = Get-ADUser -Filter * -Server "service.corp" -Properties Name, SamAccountName, UserPrincipalName, Enabled, PasswordNeverExpires, PasswordLastSet, LastLogonDate, EmailAddress, GivenName, Surname, DisplayName, OfficePhone
# Экспортируем информацию о пользователях в CSV-файл с кодировкой UTF-8
$users | Select-Object Name, SamAccountName, UserPrincipalName, Enabled, PasswordNeverExpires, PasswordLastSet, LastLogonDate, EmailAddress, GivenName, Surname, DisplayName, OfficePhone |
    Export-Csv -Path $exportFilePath -NoTypeInformation -Encoding UTF8

Write-Host "Информация о пользователях экспортирована в $exportFilePath"
```

2. Для выгрузки групп

```powershell
# Задайте путь, куда сохранить CSV-файл с данными о группах
$exportFilePath = "\\AD1\share\ADGroups.csv"
# Получаем информацию о всех группах в домене с сервера service.corp
$groups = Get-ADGroup -Filter * -Server "service.corp" -Properties Name, SamAccountName, Description, GroupScope, GroupCategory, DistinguishedName
# Экспортируем информацию о группах в CSV-файл с кодировкой UTF-8
$groups | Export-Csv -Path $exportFilePath -NoTypeInformation -Encoding UTF8
Write-Host "Список групп экспортирован в $exportFilePath"
```

## Импорт пользователей и групп на новый AD

Так же для этой задачи подготовлены скрипты:

1. Импорт пользователей

```powershell
# Задайте путь к CSV-файлу с данными пользователей, созданным на сервере service.corp
$importFilePath = "C:\share\ADUsers2.csv"
# Задайте имя домена corp.service, куда нужно импортировать информацию
$targetDomain = "ukstrana.corp"
# Импортируем данные из CSV-файла
$users = Import-Csv -Path $importFilePath
# Пароль, который будет установлен у каждого пользователя
$password = ConvertTo-SecureString "Planet2211@#" -AsPlainText -Force
# Создаем новых пользователей на сервере corp.service на основе данных из CSV-файла
foreach ($user in $users) {
    try {
        # Преобразуем строку в логическое значение для параметра Enabled
        $enabled = [bool]::Parse($user.Enabled)
        # Преобразуем строку в логическое значение для параметра PasswordNeverExpires
        $passwordNeverExpires = [bool]::Parse($user.PasswordNeverExpires)
        # Если параметр PasswordNeverExpires установлен в TRUE, установим его в FALSE
        if ($passwordNeverExpires) {
            $passwordNeverExpires = $false
        }
        $newUserParams = @{
            'Name'                = $user.Name
            'SamAccountName'      = $user.SamAccountName
            'UserPrincipalName'   = $user.UserPrincipalName
            'Enabled'             = $enabled
            'PasswordNeverExpires'= $passwordNeverExpires
            'EmailAddress'        = $user.EmailAddress
            'AccountPassword'     = $password  # Устанавливаем заранее заданный пароль
            'ChangePasswordAtLogon' = $true    # Требуется изменение пароля при первом входе
        }
        # Если значения для полей GivenName, Surname, DisplayName, OfficePhone
        # доступны в CSV, добавим их в параметры создания пользователя
        if ($user.GivenName) {
            $newUserParams['GivenName'] = $user.GivenName
        }
        if ($user.Surname) {
            $newUserParams['Surname'] = $user.Surname
        }
        if ($user.DisplayName) {
            $newUserParams['DisplayName'] = $user.DisplayName
        }
        if ($user.OfficePhone) {
            $newUserParams['OfficePhone'] = $user.OfficePhone
        }
        # Создаем нового пользователя на сервере ukstrana.corp
        New-ADUser @newUserParams -Server $targetDomain -ErrorAction Stop
        Write-Host "Пользователь $($user.SamAccountName) успешно создан в домене $targetDomain"
    }
    catch {
        Write-Host "Ошибка при создании пользователя $($user.SamAccountName): $_"
    }
}
Write-Host "Информация о пользователях импортирована в домен $targetDomain"
```

2. Импорт групп

```powershell
# Задайте путь к CSV-файлу с данными о группах из домена service.corp
$importFilePath = "C:\share\ADGroups.csv"
# Задайте имя домена, в который вы хотите импортировать группы (ukstrana.corp)
$targetDomain = "ukstrana.corp"
# Загрузка CSV-файла с данными о группах
$groupsToImport = Import-Csv -Path $importFilePath
# Импорт групп в домен ukstrana.corp
$groupsToImport | ForEach-Object {
    $groupInfo = $_
    $groupName = $groupInfo.Name
    if (-not (Get-ADGroup -Filter { Name -eq $groupName } -Server "ukstrana.corp")) {
        $groupProperties = @{
            'Name'        = $groupInfo.Name
            'Description' = $groupInfo.Description
            'GroupScope'  = 'Global'
            'GroupCategory' = 'Security'
        }
        New-ADGroup @groupProperties -Server "ukstrana.corp" -ErrorAction SilentlyContinue
        Write-Host "Группа $groupName успешно импортирована в домен ukstrana.corp"
    } else {
        Write-Host "Группа $groupName уже существует в домене ukstrana.corp. Пропускаем импорт."
    }
}
```

# Настройка

## Включение возможности вывода имени пользователя в формате Фамилия Имя

Суть проблемы: По умолчанию поиск пользователей происходит по имени, а не по фамилии, что. не удобно. т.к Александров в домене может быть с десяток, а по фамилии поиск будет более точный.  
Для того что бы решить данную проблему открываем **ADSIEdit**

![pasted_image_20231019100109.png](https://wiki.ipsyd.ru/screen/windows/1-ad/pasted_image_20231019100109.png)

Разворачиваем **Конфигурация**, **cn=DisplaySpecifiers** и выбираем **CN=419**  
419 - это код русского языка.  
409 - это код английского языка  
Ищем параметр **CN=user-Display**  
![pasted_image_20231019103826.png](https://wiki.ipsyd.ru/screen/windows/1-ad/pasted_image_20231019103826.png)

В нем ищем свойство **createDialog** и задаем в нем параметры: `%<sn> %<givenName>`  
![pasted_image_20231019104007.png](https://wiki.ipsyd.ru/screen/windows/1-ad/pasted_image_20231019104007.png)

После этого поиск будет работать как по имени так и по фамилии

## PPTP и L2TP

![pasted_image_20230928083617.png](https://wiki.ipsyd.ru/screen/windows/1-ad/pasted_image_20230928083617.png)

В окне настройки удаленного доступа необходимо выбрать «Развернуть только VPN»  
![pasted_image_20230928083825.png](https://wiki.ipsyd.ru/screen/windows/1-ad/pasted_image_20230928083825.png)  
Выбираем **Настроить и включить маршрутизацию и удаленный доступ**  
![pasted_image_20230928083921.png](https://wiki.ipsyd.ru/screen/windows/1-ad/pasted_image_20230928083921.png)

Выбираем «Особая конфигурация»  
![pasted_image_20230928084110.png](https://wiki.ipsyd.ru/screen/windows/1-ad/pasted_image_20230928084110.png)

Выбираем **Доступ к виртуальной частной сети (VPN)**  
![pasted_image_20230928084144.png](https://wiki.ipsyd.ru/screen/windows/1-ad/pasted_image_20230928084144.png)

Что бы изменить настройки VPN выбираем «Свойства»  
![pasted_image_20230928084254.png](https://wiki.ipsyd.ru/screen/windows/1-ad/pasted_image_20230928084254.png)

В «Общие» указываем все как на скрине  
![pasted_image_20230928084331.png](https://wiki.ipsyd.ru/screen/windows/1-ad/pasted_image_20230928084331.png)

В «Безопасность» все как на скрине + вставляем свой «Общий ключ»  
![pasted_image_20230928084455.png](https://wiki.ipsyd.ru/screen/windows/1-ad/pasted_image_20230928084455.png)

В вкладке «Безопасность» жмем на кнопку «Методы проверки подлиности» и выбираем все как на скрине:

![pasted_image_20230928084614.png](https://wiki.ipsyd.ru/screen/windows/1-ad/pasted_image_20230928084614.png)

В IPv4 Задаем необходимый диапазон адресов или выбираем DHCP  
![pasted_image_20230928084835.png](https://wiki.ipsyd.ru/screen/windows/1-ad/pasted_image_20230928084835.png)

В целом все готово. Осталось только в профиле пользователя разрешить «Входящие звонки» и проверить в брандмауэре, что правила **Маршрутизация и удаленный доступ GRE-входящий,** **PPTP-входящий** (для PPTP) и **L2TP-входящий** (для L2TP) включены

![pasted_image_20230928085122.png](https://wiki.ipsyd.ru/screen/windows/1-ad/pasted_image_20230928085122.png)

Для PPTP необходимо пробросить порт 1723

Для L2TP необходимо немного больше действий  
Необходимо в редакторе реестра перейти в:  
`HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\PolicyAgent`  
И создать параметр **DWORD** c именем **AssumeUDPEncapsulationContextOnSendRule** и значением **2**.

![pasted_image_20230928085454.png](https://wiki.ipsyd.ru/screen/windows/1-ad/pasted_image_20230928085454.png)

## Политики

### Политика паролей

![image.png](https://wiki.ipsyd.ru/screen/windows/1-ad/polotiki/image.png)

### Политика блокировки УЗ

![снимок_экрана_2023-11-03_в_13.58.19_1.png](https://wiki.ipsyd.ru/screen/windows/1-ad/polotiki/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-03_%D0%B2_13.58.19_1.png)

### Политика Kerberos

![снимок_экрана_2023-11-03_в_13.59.13.png](https://wiki.ipsyd.ru/screen/windows/1-ad/polotiki/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-03_%D0%B2_13.59.13.png)

### Политика входа в систему

Конфигурация компьютера -> Политики -> Конфигурация Windows -> Параметры безопасности -> Локальные политики -> Назначение прав пользователя  
![снимок_экрана_2023-11-03_в_14.04.04.png](https://wiki.ipsyd.ru/screen/windows/1-ad/polotiki/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-03_%D0%B2_14.04.04.png)

Конфигурация компьютера -> Политики -> Административные шаблоны -> Система -> Вход в систему

![снимок_экрана_2023-11-03_в_14.08.25.png](https://wiki.ipsyd.ru/screen/windows/1-ad/polotiki/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-03_%D0%B2_14.08.25.png)

Конфигурация пользователя -> Административные шаблоны -> Система -> Управление электропитанием  
![снимок_экрана_2023-11-03_в_14.16.02.png](https://wiki.ipsyd.ru/screen/windows/1-ad/polotiki/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-03_%D0%B2_14.16.02.png)

### Разрешаем длинные пути

Конфигурация компьютера -> Политики -> Административные шаблоны -> Система -> Файловая система  
![снимок_экрана_2023-11-03_в_14.11.53.png](https://wiki.ipsyd.ru/screen/windows/1-ad/polotiki/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-03_%D0%B2_14.11.53.png)

### Политика завершения работы ПО

Например необходимо в 19.00 завершать работу phonerlite

Для этого переходим в нужную политику -> Конфигурация пользователя -> Настройка -> Параметры панели управления -> Назначенные задания и там создаем задание  
![[Pasted image 20231122102314.png]]

И задаем необходимые параметры. В моем случае отрабатывает скрипт в powershell  
![снимок_экрана_2023-11-22_в_10.17.45.png](https://wiki.ipsyd.ru/screen/windows/1-ad/polotiki/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-22_%D0%B2_10.17.45.png)

/

## RADIUS

Необходимо установить роль: **Службы политики сети и доступа**  
![pasted_image_20231019104509.png](https://wiki.ipsyd.ru/screen/windows/1-ad/pasted_image_20231019104509.png)  
Перезагружаемся  
Далее необходимо пробросить udp порты 500, 4500 и 1701.

Далее в оснастке **Сервер политики сети**  
И регистрируем сервер в AD.  
![снимок_экрана_2023-11-07_в_13.16.30.png](https://wiki.ipsyd.ru/screen/windows/1-ad/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-07_%D0%B2_13.16.30.png)

Если кнопка не активна, то можно это сделать через powershell:

```poweshell
netsh ras add registeredserver
```

Результат:  
![снимок_экрана_2023-11-07_в_13.19.07.png](https://wiki.ipsyd.ru/screen/windows/1-ad/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-07_%D0%B2_13.19.07.png)

Возможно вылезет окно с подтверждением регистрации. Соглашаемся.  
Проверяем что бы сервер был в группе «**Серверы RAS и IAS**»  
![снимок_экрана_2023-11-07_в_13.23.38.png](https://wiki.ipsyd.ru/screen/windows/1-ad/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-07_%D0%B2_13.23.38.png)

Теперь создаем нового клиента  
![снимок_экрана_2023-11-07_в_13.25.44.png](https://wiki.ipsyd.ru/screen/windows/1-ad/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-07_%D0%B2_13.25.44.png)

![снимок_экрана_2023-11-07_в_13.28.02.png](https://wiki.ipsyd.ru/screen/windows/1-ad/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-07_%D0%B2_13.28.02.png)

Далее переходим в **Политики** -> **Сетевые политики**  
![снимок_экрана_2023-11-07_в_14.23.14.png](https://wiki.ipsyd.ru/screen/windows/1-ad/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-07_%D0%B2_14.23.14.png)

Задаем имя:  
![снимок_экрана_2023-11-07_в_14.24.32.png](https://wiki.ipsyd.ru/screen/windows/1-ad/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-07_%D0%B2_14.24.32.png)

Добавляем условия. Я добавил **Понятное имя клиента** и **группы**  
![снимок_экрана_2023-11-07_в_15.42.14.png](https://wiki.ipsyd.ru/screen/windows/1-ad/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-07_%D0%B2_15.42.14.png)

![снимок_экрана_2023-11-07_в_15.43.04.png](https://wiki.ipsyd.ru/screen/windows/1-ad/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-07_%D0%B2_15.43.04.png)  
![снимок_экрана_2023-11-07_в_15.44.03.png](https://wiki.ipsyd.ru/screen/windows/1-ad/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-07_%D0%B2_15.44.03.png)

В следующем окне я ни чего не менял  
![снимок_экрана_2023-11-07_в_15.44.45.png](https://wiki.ipsyd.ru/screen/windows/1-ad/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-07_%D0%B2_15.44.45.png)

Далее для **Service-Type** меняем значение на **Login**  
![снимок_экрана_2023-11-07_в_15.45.43.png](https://wiki.ipsyd.ru/screen/windows/1-ad/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-07_%D0%B2_15.45.43.png)

Результат  
![снимок_экрана_2023-11-07_в_15.49.27.png](https://wiki.ipsyd.ru/screen/windows/1-ad/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-07_%D0%B2_15.49.27.png)

Далее переходим в **Политики** -> **Политики запросов на подключение**

![снимок_экрана_2023-11-07_в_16.13.28.png](https://wiki.ipsyd.ru/screen/windows/1-ad/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-07_%D0%B2_16.13.28.png)

![снимок_экрана_2023-11-07_в_16.14.31.png](https://wiki.ipsyd.ru/screen/windows/1-ad/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-07_%D0%B2_16.14.31.png)

Далее так же выбираем **Понятное имя клиента**

![снимок_экрана_2023-11-07_в_16.16.37.png](https://wiki.ipsyd.ru/screen/windows/1-ad/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-07_%D0%B2_16.16.37.png)

![снимок_экрана_2023-11-07_в_16.17.47.png](https://wiki.ipsyd.ru/screen/windows/1-ad/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-07_%D0%B2_16.17.47.png)

![снимок_экрана_2023-11-07_в_16.18.30.png](https://wiki.ipsyd.ru/screen/windows/1-ad/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-07_%D0%B2_16.18.30.png)

![снимок_экрана_2023-11-07_в_16.19.40.png](https://wiki.ipsyd.ru/screen/windows/1-ad/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-07_%D0%B2_16.19.40.png)

Результат:  
![снимок_экрана_2023-11-07_в_16.20.17.png](https://wiki.ipsyd.ru/screen/windows/1-ad/%D1%81%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA_%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0_2023-11-07_%D0%B2_16.20.17.png)

[x]