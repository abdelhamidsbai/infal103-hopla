#!/usr/bin/env bash
# Vérifie que le Codespace est prêt pour les TP.
manque=0
for outil in docker containerlab terraform ansible-playbook; do
  if command -v "$outil" >/dev/null 2>&1; then echo "OK      $outil"; else echo "MANQUE  $outil"; manque=1; fi
done
if docker ps >/dev/null 2>&1; then echo "OK      Docker répond"; else echo "MANQUE  Docker ne répond pas"; manque=1; fi
if [ "$manque" -eq 0 ]; then
  echo; echo "Environnement prêt."
else
  echo; echo "Attendez une minute, relancez ce script, puis appelez le formateur si le problème reste."
  exit 1
fi
