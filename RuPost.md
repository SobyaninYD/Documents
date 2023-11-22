---
sticker: lucide//mail-check
---
После установки  ос требуется подключить расширенный репозиторий Astra Linux. Для этого необходимо в `/etc/apt/sources.list` добавить:
```shell file:/etc/apt/sources.list
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-extended/ 1.7_x86-64 main contrib non-free
```
Должно получиться:
![[Pasted image 20231122123919.png]]

Далее  если обновить пакеты, то получим ошибку:
![[Pasted image 20231122123958.png]]

Для устранения проверяем установлен ли `ca-certificates` командой:
```shell
apt policy apt-transport-https ca-certificates
```

![[Pasted image 20231122124134.png]]
Вывод говорит о том что `ca-certificates` отсутсвует. Ставим.
```bash
apt install ca-certificates
```

Далее обновляем пакеты


```bash
sudo apt install postgresql
```

