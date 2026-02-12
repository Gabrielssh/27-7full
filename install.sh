#!/usr/bin/env bash
set -e

PROJECT_DIR="$HOME/stream_manager"
SCRIPT_URL="https://github.com/Gabriessh/24-7iptv/raw/master/24/7.sh"
SCRIPT_NAME="stream-manager.sh"
BIN_NAME="stream24"

echo "======================================"
echo " STREAM MANAGER 24/7 - AUTO INSTALLER "
echo "======================================"
echo

# Não rodar como root
if [ "$EUID" -eq 0 ]; then
  echo "❌ Não execute como root."
  exit 1
fi

# Verificar Ubuntu
if ! grep -qi ubuntu /etc/os-release; then
  echo "❌ Apenas Ubuntu é suportado."
  exit 1
fi

echo "🔄 Atualizando sistema..."
sudo apt update -y
sudo apt upgrade -y

echo "📦 Instalando dependências..."
sudo apt install -y \
  ffmpeg \
  yt-dlp \
  tmux \
  coreutils \
  procps \
  curl

echo "📁 Criando diretório..."
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo "⬇️ Baixando script principal..."
curl -fsSL "$SCRIPT_URL" -o "$SCRIPT_NAME"

echo "🔐 Ajustando permissões..."
chmod +x "$SCRIPT_NAME"
chmod -R 700 "$PROJECT_DIR"

echo "🔗 Criando comando global..."
sudo ln -sf "$PROJECT_DIR/$SCRIPT_NAME" "/usr/local/bin/$BIN_NAME"

echo "🔄 Atualizando yt-dlp..."
yt-dlp -U || true

echo
echo "✅ INSTALAÇÃO FINALIZADA!"
echo
echo "▶️ Execute com:"
echo "   $BIN_NAME"
echo
echo "💡 Para rodar 24/7:"
echo "   tmux new -s stream24 $BIN_NAME"
echo
echo "Ctrl+B depois D para sair do tmux"