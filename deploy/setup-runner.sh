#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./setup-runner.sh <your_username>)"
  exit 1
fi

RUNNER_USER="${1:?Usage: $0 <username> (e.g., ubuntu or student)}"

if [ "$RUNNER_USER" = "root" ]; then
  echo "Error: GitHub Runner cannot be run as root. Please specify a regular user."
  exit 1
fi

if ! id -u "$RUNNER_USER" >/dev/null 2>&1; then
  echo "User '$RUNNER_USER' does not exist. Creating it now..."
  useradd -m -s /bin/bash "$RUNNER_USER"
fi

usermod -aG docker "$RUNNER_USER"

RUNNER_DIR="/home/${RUNNER_USER}/actions-runner"

echo "1 - Installing dependencies"
apt update -qq
apt install -y -qq curl docker.io jq git openssh-client

systemctl enable --now docker

echo "2 - Downloading GitHub Actions runner"
LATEST_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name | sed 's/v//')
ARCH="x64"
RUNNER_PACKAGE="actions-runner-linux-${ARCH}-${LATEST_VERSION}.tar.gz"

mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"
curl -fsSL "https://github.com/actions/runner/releases/download/v${LATEST_VERSION}/${RUNNER_PACKAGE}" -o "$RUNNER_PACKAGE"
tar xzf "$RUNNER_PACKAGE"
rm "$RUNNER_PACKAGE"
chown -R "${RUNNER_USER}:${RUNNER_USER}" "$RUNNER_DIR"

echo "3 - Generating SSH key for target node access"
SSH_KEY_PATH="/home/${RUNNER_USER}/.ssh/id_ed25519"

if [ ! -f "$SSH_KEY_PATH" ]; then
  sudo -u "$RUNNER_USER" ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -q
fi

echo "Setup complete"
echo "1. Your PUBLIC KEY for the target node:"
cat "${SSH_KEY_PATH}.pub"
echo "--------------------------------------"
echo "2. Next steps:"
echo "   - Switch to user: su - $RUNNER_USER"
echo "   - Go to runner dir: cd $RUNNER_DIR"
echo "   - Configure: ./config.sh --url https://github.com/Liza-Khube/KPI_DevOps_Lab3 --token <TOKEN>"
echo "   - Install service: sudo ./svc.sh install && sudo ./svc.sh start"