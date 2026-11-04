#!/usr/bin/env bash
# Teste les quatre flux de la matrice et dit lesquels sont à corriger.
bons=0
tester() { # description, attendu (oui/non), machine, commande
  local passe=non
  if docker exec "clab-hopla-$3" sh -c "$4" >/dev/null 2>&1; then passe=oui; fi
  if [ "$passe" = "$2" ]; then
    echo "BON        $1"; bons=$((bons+1))
  elif [ "$2" = oui ]; then
    echo "A CORRIGER $1 : ce flux doit passer, mais il est bloqué"
  else
    echo "A CORRIGER $1 : ce flux doit être bloqué, mais il passe"
  fi
}
tester "Internet vers le site"   oui client "curl -s -m 3 -o /dev/null http://10.10.20.10"
tester "Internet vers la compta" non client "curl -s -m 3 -o /dev/null http://10.10.10.20"
tester "Site vers la compta"     non web    "timeout 4 wget -q -O /dev/null http://10.10.10.20"
tester "Bureau vers le site"     oui poste  "curl -s -m 3 -o /dev/null http://10.10.20.10"
echo; echo "$bons tests sur 4 sont bons"
[ "$bons" -eq 4 ]
