# Задайте путь, куда сохранить CSV-файл с данными о группах
$exportFilePath = "\\AD1\share\ADGroups.csv"

# Получаем информацию о всех группах в домене с сервера service.corp
$groups = Get-ADGroup -Filter * -Server "service.corp" -Properties Name, SamAccountName, Description, GroupScope, GroupCategory, DistinguishedName

# Экспортируем информацию о группах в CSV-файл с кодировкой UTF-8
$groups | Export-Csv -Path $exportFilePath -NoTypeInformation -Encoding UTF8

Write-Host "Список групп экспортирован в $exportFilePath"
