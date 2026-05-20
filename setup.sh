#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="/opt/mywebapp"
DB_NAME="mywebapp_db"
DB_USER="mywebapp"
DB_PASSWORD="mypassword"
CONFIG_DIR="/etc/mywebapp"
N=25

echo "Starting installation ..."
echo "App directory: $APP_DIR"

echo "1 - Installing packages"
apt update
apt install -y git nginx postgresql nodejs npm

echo "2 - Creating users"
useradd -m -s /bin/bash student
echo "student:12345678" | chpasswd
usermod -aG sudo student
chage -d 0 student

useradd -m -s /bin/bash teacher
echo "teacher:12345678" | chpasswd
usermod -aG sudo teacher
chage -d 0 teacher

useradd -r -s /usr/sbin/nologin -M app

if getent group operator > /dev/null; then
    useradd -m -s /bin/bash -g operator operator
else
    useradd -m -s /bin/bash operator
fi
echo "operator:12345678" | chpasswd
chage -d 0 operator

cat > /etc/sudoers.d/operator << EOF
operator ALL=(ALL) NOPASSWD: \
  /bin/systemctl start mywebapp.service, \
  /bin/systemctl stop mywebapp.service, \
  /bin/systemctl restart mywebapp.service, \
  /bin/systemctl status mywebapp.service, \
  /bin/systemctl start mywebapp.socket, \
  /bin/systemctl stop mywebapp.socket, \
  /bin/systemctl restart mywebapp.socket, \
  /bin/systemctl status mywebapp.socket, \
  /bin/systemctl reload nginx
EOF

echo "3 - Setting up PostgreSQL"
sudo -u postgres psql << EOF
CREATE USER $DB_USER WITH PASSWORD '${DB_PASSWORD}';
CREATE DATABASE $DB_NAME OWNER $DB_USER;
EOF

echo "4 - Copying app and creating config file"
echo "Copying app to $APP_DIR"
mkdir -p $APP_DIR
cp -r "$SCRIPT_DIR/mywebapp/." $APP_DIR
cd $APP_DIR
echo "Installing project dependencies"
npm install

chown -R root:app $APP_DIR
chmod -R 750 $APP_DIR

echo "Creating config file"
mkdir -p $CONFIG_DIR
cat > $CONFIG_DIR/config.json << EOF
{
  "server": {
    "host": "127.0.0.1",
    "port": 8080
  },
  "database": {
    "host": "127.0.0.1",
    "port": 5432,
    "user": "$DB_USER",
    "password": "${DB_PASSWORD}",
    "database": "$DB_NAME"
  }
}
EOF

chown root:app $CONFIG_DIR/config.json
chmod 640 $CONFIG_DIR/config.json

echo "5 - Setting up systemd"
cp "$SCRIPT_DIR/deploy/mywebapp.service" /etc/systemd/system/mywebapp.service
cp "$SCRIPT_DIR/deploy/mywebapp.socket" /etc/systemd/system/mywebapp.socket
systemctl daemon-reload
systemctl enable mywebapp.socket

echo "6 - Starting service"
systemctl start mywebapp.socket

echo "7 - Configuring Nginx"
cp "$SCRIPT_DIR/deploy/nginx.conf" /etc/nginx/sites-available/mywebapp
ln -sf /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/mywebapp
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx

echo "8 - Creating gradebook"
echo "$N" > /home/student/gradebook
chown student:student /home/student/gradebook

echo "Blocking default user"
DEFAULT_USER=$(id -nu 1000)
if [[ -n "$DEFAULT_USER" && \
      "$DEFAULT_USER" != "student" && \
      "$DEFAULT_USER" != "teacher" && \
      "$DEFAULT_USER" != "operator" && \
      "$DEFAULT_USER" != "app" ]]; then
    usermod -L $DEFAULT_USER
    echo "User $DEFAULT_USER has been locked"
fi

echo "Installation completed"
echo "You may log in as 'student', 'teacher' or 'operator' with password '12345678'"