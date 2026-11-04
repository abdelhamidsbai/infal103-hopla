#!/usr/bin/env bash
# Finale : tout a brûlé. Combien de temps pour tout reconstruire ?
set -euo pipefail
racine="$(cd "$(dirname "$0")" && pwd)"
debut=$SECONDS
# La supervision survit à la catastrophe : on la détache du réseau avant destruction.
docker network disconnect -f hopla-front hopla-supervision 2>/dev/null || true
terraform -chdir="$racine/02-iac-terraform" destroy -auto-approve
terraform -chdir="$racine/02-iac-terraform" apply -auto-approve
docker network connect hopla-front hopla-supervision 2>/dev/null || true
(cd "$racine/03-ansible" && ansible-playbook playbook.yml)
curl -fsS localhost:8080
echo
echo "Hopla Market reconstruit en $((SECONDS - debut)) secondes."
