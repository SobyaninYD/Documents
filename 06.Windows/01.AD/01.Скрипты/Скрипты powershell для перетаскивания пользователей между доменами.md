
1.  Сбор информации о пользователях для экспорта на другой домен
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

2. Экспорт групп
```powershell
# Задайте путь, куда сохранить CSV-файл с данными о группах
$exportFilePath = "\\AD1\share\ADGroups.csv"
# Получаем информацию о всех группах в домене с сервера service.corp
$groups = Get-ADGroup -Filter * -Server "service.corp" -Properties Name, SamAccountName, Description, GroupScope, GroupCategory, DistinguishedName
# Экспортируем информацию о группах в CSV-файл с кодировкой UTF-8
$groups | Export-Csv -Path $exportFilePath -NoTypeInformation -Encoding UTF8
Write-Host "Список групп экспортирован в $exportFilePath"
```

3. Импорт выгруженного файла  на новый ад
```powershell
 # Задайте путь к CSV-файлу с данными пользователей, созданным на сервере service.corp
$importFilePath = "C:\share\ADUsersUTF8.csv"
# Задайте имя домена corp.service, куда нужно импортировать информацию
$targetDomain = "corp.service"
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
        $newUserParams = @{
            'Name'                = $user.Name
            'SamAccountName'      = $user.SamAccountName
            'UserPrincipalName'   = $user.UserPrincipalName
            'Enabled'             = $enabled
            'PasswordNeverExpires'= $passwordNeverExpires
            'EmailAddress'        = $user.EmailAddress
            'AccountPassword'     = $password  # Устанавливаем заранее заданный пароль
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
        # Создаем нового пользователя на сервере corp.service
        New-ADUser @newUserParams -Server $targetDomain -ErrorAction Stop
        Write-Host "Пользователь $($user.SamAccountName) успешно создан в домене $targetDomain"
    }
    catch {
        Write-Host "Ошибка при создании пользователя $($user.SamAccountName): $_"
    }
}
Write-Host "Информация о пользователях импортирована в домен $targetDomain"
```


5. Импорт групп в новый домен:
```powershell
 # Задайте путь к CSV-файлу с данными о группах из домена service.corp
$importFilePath = "\\AD1\share\ADGroups.csv"
# Задайте имя домена, в который вы хотите импортировать группы (test.corp)
$targetDomain = "test.corp"
# Загрузка CSV-файла с данными о группах
$groupsToImport = Import-Csv -Path $importFilePath
# Импорт групп в домен test.corp
$groupsToImport | ForEach-Object {
    $groupInfo = $_
    $groupName = $groupInfo.Name
    if (-not (Get-ADGroup -Filter { Name -eq $groupName } -Server "test.corp")) {
        $groupProperties = @{
            'Name'        = $groupInfo.Name
            'Description' = $groupInfo.Description
            'GroupScope'  = 'Global'
            'GroupCategory' = 'Security'
        }
        New-ADGroup @groupProperties -Server "test.corp" -ErrorAction SilentlyContinue
        Write-Host "Группа $groupName успешно импортирована в домен test.corp"
    } else {
        Write-Host "Группа $groupName уже существует в домене test.corp. Пропускаем импорт."
    }
}
```

4. Конвертирует файл в UTF8
```powershell
 # Задайте путь к исходному CSV-файлу с данными пользователей
$sourceFilePath = "C:\share\ADUsers2.csv"
# Задайте путь для сохранения нового CSV-файла с кодировкой UTF-8 без BOM
$targetFilePath = "C:\share\ADUsersUTF8.csv"
# Конвертируем кодировку исходного файла в UTF-8 без BOM
Get-Content -Path $sourceFilePath | Out-File -Encoding UTF8 $targetFilePath
Write-Host "Файл успешно пересохранен в кодировке UTF-8 без BOM: $targetFilePath"
```
6. Удаление всех пользователей AD

```powershell
# Задайте путь к CSV-файлу с данными пользователей, созданным на сервере service.corp
$importFilePath = "C:\share\ADUsersUTF8.csv"
# Задайте имя домена corp.service, где нужно удалить пользователей
$targetDomain = "corp.service"
# Импортируем данные из CSV-файла
$users = Import-Csv -Path $importFilePath
# Удаляем каждого пользователя из домена corp.service
foreach ($user in $users) {
    $samAccountName = $user.SamAccountName
    # Проверяем, существует ли пользователь в домене corp.service
    if (Get-ADUser -Filter { SamAccountName -eq $samAccountName } -Server $targetDomain) {
        Remove-ADUser -Identity $samAccountName -Server $targetDomain -Confirm:$false
        Write-Host "Пользователь $samAccountName удален из домена $targetDomain"
    } else {
        Write-Host "Пользователь $samAccountName не найден в домене $targetDomain"
    }
}
```