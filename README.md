```markdown
# etcd-auto-deploy

Автоматизированный bash-скрипт для быстрого и безопасного развертывания узла etcd с конфигурацией через файл `/etc/etcd/etcd.conf.yml` и systemd.

## Возможности

- Скачивание и установка etcd (версия задаётся в скрипте)
- Создание пользователя, каталогов, установка прав
- Открытие необходимых портов через UFW
- Генерация корректного YAML-конфига `/etc/etcd/etcd.conf.yml` по вашим данным
- Создание systemd unit для etcd, использующего этот конфиг
- Автоматический запуск etcd
- Подсказка для проверки статуса кластера

---

## Быстрый старт

### 1. Клонируйте репозиторий или сохраните скрипт

```
git clone https://github.com/yourname/etcd-auto-deploy.git
cd etcd-auto-deploy
# или просто скачайте etcd_auto_deploy.sh
```

### 2. Сделайте скрипт исполняемым

```
chmod +x etcd_auto_deploy.sh
```

### 3. Запустите скрипт

```
./etcd_auto_deploy.sh
```

### 4. Следуйте инструкциям

- Скрипт попросит ввести:
  - Имя текущего узла (например, `matrix-db0`)
  - IP или hostname текущего узла
  - Список всех узлов через запятую (например, `matrix-db0,matrix-db1,matrix-db2`)
  - initial-cluster-state (`new` для первого запуска, `existing` для подключения к кластеру)

---

## Как добавить новый узел в кластер

1. Запустите скрипт на новом сервере, указав полный список всех узлов (включая новый) и `initial-cluster-state: existing`.
2. Обновите конфиг `/etc/etcd/etcd.conf.yml` на всех старых узлах, чтобы параметр `initial-cluster` содержал полный список участников.
3. Перезапустите etcd на всех узлах:
   ```
   sudo systemctl daemon-reload
   sudo systemctl restart etcd
   ```

---

## Проверка состояния кластера

После запуска скрипта используйте команду:

```
ETCDCTL_API=3 etcdctl --endpoints=host1:2379,host2:2379,host3:2379 endpoint status --cluster -w table
```
(где `host1,host2,host3` — ваши имена или IP всех узлов кластера)

---

## Требования

- Linux (Ubuntu/Debian, для CentOS используйте firewalld вместо ufw)
- bash
- curl
- sudo

---

## Безопасность

- Для production обязательно включайте TLS и аутентификацию в etcd!
- Скрипт по умолчанию открывает порты 2379 и 2380 через UFW.

---

## Лицензия

MIT

---
