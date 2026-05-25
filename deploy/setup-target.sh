#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

if [ -z "$DB_PASSWORD" ]; then
  echo "Error: DB_PASSWORD environment variable is not set!"
  echo "Usage: sudo DB_PASSWORD='your_password' ./setup-target.sh"
  exit 1
fi

GITHUB_REPO="${1:?Usage: $0 <github-repo> (e.g., user/repo)}"
GITHUB_REPO="${GITHUB_REPO,,}"

read -p "Enter the PUBLIC KEY from the Runner node: " DEPLOY_PUBKEY

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_NAME="mywebapp_db"
DB_USER="mywebapp"
CONFIG_DIR="/etc/mywebapp"
N=25

echo "1 - Installing packages"
apt update -qq
apt install -y -qq nginx postgresql curl docker.io openssh-server
systemctl enable --now docker
systemctl enable --now ssh

echo "2 - Creating users"
useradd -m -s /bin/bash student
echo "student:12345678" | chpasswd
usermod -aG sudo student
chage -d 0 student

useradd -m -s /bin/bash teacher
echo "teacher:12345678" | chpasswd
usermod -aG sudo teacher
chage -d 0 teacher

if getent group operator > /dev/null; then
    useradd -m -s /bin/bash -g operator operator
else
    useradd -m -s /bin/bash operator
fi
echo "operator:12345678" | chpasswd
chage -M 99999 operator
usermod -aG docker operator

cat > /etc/sudoers.d/operator << 'EOF'
operator ALL=(ALL) NOPASSWD: \
  /usr/bin/systemctl daemon-reload, \
  /usr/bin/systemctl restart mywebapp-container.service, \
  /usr/bin/systemctl start mywebapp-container.service, \
  /usr/bin/systemctl stop mywebapp-container.service, \
  /usr/bin/systemctl status mywebapp-container.service --no-pager, \
  /usr/bin/systemctl reload nginx
EOF

chmod 0440 /etc/sudoers.d/operator

mkdir -p /home/operator/.ssh
echo "$DEPLOY_PUBKEY" >> /home/operator/.ssh/authorized_keys
chown -R operator:operator /home/operator/.ssh
chmod 700 /home/operator/.ssh
chmod 600 /home/operator/.ssh/authorized_keys

echo "3 - Setting up PostgreSQL"
sudo -u postgres psql << EOF
CREATE USER $DB_USER WITH PASSWORD '${DB_PASSWORD}';
CREATE DATABASE $DB_NAME OWNER $DB_USER;
EOF

echo "4 - Creating app config"
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/config.json" << EOF
{
  "server": {
    "host": "0.0.0.0",
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

cat > "$CONFIG_DIR/container.env" << EOF
MYWEBAPP_IMAGE=ghcr.io/${GITHUB_REPO}:stable
EOF

chmod 755 "$CONFIG_DIR"
chmod 644 "$CONFIG_DIR/config.json"
chmod 644 "$CONFIG_DIR/container.env"

echo "5 - Setting up systemd & Nginx"
cp "$SCRIPT_DIR/mywebapp-container.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable mywebapp-container.service

cp "$SCRIPT_DIR/nginx.conf" /etc/nginx/sites-available/mywebapp
ln -sf /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/mywebapp
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

echo "6 - Creating gradebook"
echo "$N" >>> /home/student/gradebook
chown student:student /home/student/gradebook

echo "Setup complete"