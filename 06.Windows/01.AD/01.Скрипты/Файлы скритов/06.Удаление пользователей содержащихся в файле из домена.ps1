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
