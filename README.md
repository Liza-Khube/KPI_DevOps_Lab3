# Лабораторна робота №3. CI/CD. Setup Guide

### Для виконання роботи використовувалось:

- Runner VM - Ubuntu Server 24.04 ([https://ubuntu.com/download/server](https://ubuntu.com/download/server))
- Target Node VM - Ubuntu Server 24.04 ([https://ubuntu.com/download/server](https://ubuntu.com/download/server))

### Після форку репозиторія:

### На Runner VM:

1. Склонувати репозиторій:

   `git clone https://github.com/<OWNER>/<REPO>.git`

   (замість `<OWNER>` та `<REPO>` підставити username свого акаунта в GitHub та назву репозиторія)

2. Перейти у папку проекта:

   `cd <REPO>`

3. Запустити сетап файл з переданим значенням `<username>` користувача системи (наприклад `admin`):

   `sudo bash deploy/setup-runner.sh <username>`

   Скрипт виведе публічний SSH ключ - його треба скопіювати/зберегти. Цей ключ буде вставлятись при запиті `setup-target.s`

### На Target Node VM

4. Склонувати репозиторій:

   `git clone https://github.com/<OWNER>/<REPO>.git`

   (замість `<OWNER>` та `<REPO>` підставити username свого акаунта в GitHub та назву репозиторія)

5. Перейти у папку проекта:

   `cd <REPO>`

6. Запустити сетап файл з переданим значенням `<username>` користувача системи (наприклад `admin`):

   `sudo DB_PASSWORD='<yourpassword>' bash deploy/setup-target.sh "<owner>/<repo>"`

   Скрипт запитає публічний SSH ключ з Runner VM - вставити те, що вивів `setup-runner.sh` (п. 3)

### На Runner VM:

7. Перейти на профіль користувача `<username>`, що був переданий при запуску `setup-runner.sh` (п. 3):

   `su - <username>`

8. Перейти у папку ранера:

   `cd /home/<username>/actions-runner`

9. Зробити конфігурацію:

   `./config.sh --url https://github.com/<OWNER>/<REPO> --token <TOKEN>`

   (значення `<TOKEN>` береться з GitHub репозиторія: **Settings** ➔ **Actions** ➔ **Runners ➔** **New self-hosted runner (Linux)** ➔ **Розділ Configure ➔ набір символів після `--token`**)

10. Встановити сервіс:

    `sudo ./svc.sh install && sudo ./svc.sh start`

### GitHub Secrets

Для CI/CD pipline потрібна одна змінна, яку треба записати у GitHub Secrets:

**Settings ➔ Secrets and variables ➔ Actions:** **TARGET_NODE_IP** зі значенням ip адреси **Target Node VM**
