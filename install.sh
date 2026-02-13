#!/usr/bin/env bash

set -e

echo "🚀 Instalador 27-7full (modo usuário)"

# ==============================
# Bloquear execução como root
# ==============================
if [[ $EUID -eq 0 ]]; then
  echo "❌ Não execute como root!"
  echo "👉 Rode como usuário normal."
  exit 1
fi

# ==============================
# Verificar dependências
# ==============================
need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "❌ Dependência faltando: $1"
    echo "👉 Peça ao admin da VPS para instalar."
    exit 1
  }
}

need_cmd curl
need_cmd git
need_cmd unzip

# ==============================
# Diretório de instalação
# ==============================
WORKDIR="$HOME/27-7full"

echo "📂 Instalando em $WORKDIR"

rm -rf "$WORKDIR"
git clone https://github.com/Gabrielssh/27-7full "$WORKDIR"

cd "$WORKDIR"

chmod +x *.sh

# ==============================
# Setup opcional
# ==============================
if [[ -f setup.sh ]]; then
  echo "⚙️ Executando setup..."
  bash setup.sh
fi

echo "✅ Instalação concluída!"
echo "👉 Execute: cd $WORKDIR && ./start.sh"
