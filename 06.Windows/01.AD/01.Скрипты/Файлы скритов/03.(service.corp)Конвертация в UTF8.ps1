# Задайте путь к исходному CSV-файлу с данными пользователей
$sourceFilePath = "C:\share\ADUsers2.csv"

# Задайте путь для сохранения нового CSV-файла с кодировкой UTF-8 без BOM
$targetFilePath = "C:\share\ADUsersUTF8.csv"

# Конвертируем кодировку исходного файла в UTF-8 без BOM
Get-Content -Path $sourceFilePath | Out-File -Encoding UTF8 $targetFilePath

Write-Host "Файл успешно пересохранен в кодировке UTF-8 без BOM: $targetFilePath"
