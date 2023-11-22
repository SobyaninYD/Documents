# Задайте путь, куда сохранить CSV-файл с данными пользователей
$exportFilePath = "\\AD1\share\ADUsers2.csv"

# Получаем информацию о пользователях с сервера service.corp
$users = Get-ADUser -Filter * -Server "service.corp" -Properties Name, SamAccountName, UserPrincipalName, Enabled, PasswordNeverExpires, PasswordLastSet, LastLogonDate, EmailAddress, GivenName, Surname, DisplayName, OfficePhone

# Экспортируем информацию о пользователях в CSV-файл с кодировкой UTF-8
$users | Select-Object Name, SamAccountName, UserPrincipalName, Enabled, PasswordNeverExpires, PasswordLastSet, LastLogonDate, EmailAddress, GivenName, Surname, DisplayName, OfficePhone |
    Export-Csv -Path $exportFilePath -NoTypeInformation -Encoding UTF8

Write-Host "Информация о пользователях экспортирована в $exportFilePath"
