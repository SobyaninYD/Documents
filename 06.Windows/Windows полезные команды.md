перейти на диск
```cmd
E:
```

Перейти в папку: 
```cmd
cd Documents
```

Посмотреть содержимое папки: 
```cmd
dir
```

Скопировать что то из в:
```cmd
robocopy "E:\proxyzabbix\dumpVM\dumpVM" "D:\VM" /E
```

Запрос информации о пользователе:
```powershell
Get-ADUser -identity <Username>
```

Запрос подробной информации о пользователе:

```powershell
Get-ADUser <Username> -Properties *
```

Вывод включенных учетных записей:
```powershell
Get-ADUser -filter {Enabled -eq "true"}
```

Удаленный перезапуск ПК
```cmd
shutdown -r -f -t 0 -m \\usercomp
```

Удаленный перезапуск ПК с авторизацией
```bash
net use \\192.168.1.10\admin$ password /USER:username & shutdown -r -f -t 0 -m \\192.168.1.10
```
