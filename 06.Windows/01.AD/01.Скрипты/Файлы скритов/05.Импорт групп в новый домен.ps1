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
