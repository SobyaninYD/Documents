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
