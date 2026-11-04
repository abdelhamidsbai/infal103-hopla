#!/usr/bin/env bash
# Installe Ansible et télécharge les images à l'avance pour ne pas perdre de temps en cours.
set -u
python3 -m pip install --user --break-system-packages --quiet ansible \
  || uv tool install --with-executables-from ansible-core ansible
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
done
for image in nicolaka/netshoot:latest nginx:alpine alpine:3.20 python:3.12-slim postgres:16-alpine louislam/uptime-kuma:1; do
  docker pull -q "$image" || echo "AVERTISSEMENT : image non téléchargée : $image"
done
echo "Installation terminée. Lancez : bash labs/00-verifier.sh"
