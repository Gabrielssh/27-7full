#!/usr/bin/env bash

set -e

# ==============================
# Detectar root/sudo
# ==============================
if [[ $EUID -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "❌ Execute como root ou instale sudo."
    exit 1
  fi
else
  SUDO=""
fi

# ==============================
# Detectar sistema operacional
# ==============================
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS=$ID
else
  echo "❌ Sistema não suportado."
  exit 1
fi

echo "📦 Detectado: $OS"

# ==============================
# Instalar dependências
# ==============================
install_deps() {
  case "$OS" in
    ubuntu|debian)
      $SUDO apt update -y
      $SUDO apt install -y curl wget git unzip
      ;;
    centos|rhel|fedora|almalinux|rocky)
      $SUDO dnf install -y curl wget git unzip || \
      $SUDO yum install -y curl wget git unzip
      ;;
    arch)
      $SUDO pacman -Sy --noconfirm curl wget git unzip
      ;;
    *)
      echo "⚠️ OS não testado. Tentando instalar dependências..."
      ;;
  esac
}

install_deps

# ==============================
# Baixar arquivos do projeto
# ==============================
WORKDIR="/opt/27-7full"

echo "📂 Instalando em $WORKDIR"

$SUDO rm -rf "$WORKDIR"
$SUDO git clone https://github.com/Gabrielssh/27-7full "$WORKDIR"

cd "$WORKDIR"

# ==============================
# Permissões
# ==============================
$SUDO chmod +x *.sh

# ==============================
# Rodar setup principal
# ==============================
if [[ -f setup.sh ]]; then
  echo "🚀 Executando setup..."
  $SUDO bash setup.sh
else
  echo "✅ Instalação concluída."
fi
