#!/usr/bin/env bash
# Rejoue tous les TP, tels que les étudiants les feront.
# Dans un Codespace : bash formateur/verifier.sh 2>&1 | tee verification.log
# Sur GitHub : ce script tourne automatiquement dans l'onglet Actions.
set -u
racine="$(cd "$(dirname "$0")/.." && pwd)"
ok=0; ko=0
test_ok() { echo "OK    $1"; ok=$((ok+1)); }
test_ko() { echo "ECHEC $1"; ko=$((ko+1)); }
attendu() { local nom="$1"; shift; if "$@" >/dev/null 2>&1; then test_ok "$nom"; else test_ko "$nom"; fi; }
refuse()  { local nom="$1"; shift; if "$@" >/dev/null 2>&1; then test_ko "$nom"; else test_ok "$nom"; fi; }
contient() { local nom="$1" motif="$2" sortie; shift 2; sortie="$("$@" 2>&1)"; if printf '%s\n' "$sortie" | grep -q -- "$motif"; then test_ok "$nom"; else test_ko "$nom (attendu : $motif)"; printf '%s\n' "$sortie" | tail -25 | sed 's/^/      /'; fi; }

echo "=== Environnement"
attendu "labs/00-verifier.sh" bash "$racine/labs/00-verifier.sh"

echo "=== TP 1, acte 1"
cd "$racine/labs/01-reseau"
sudo containerlab deploy -t hopla.clab.yml --reconfigure >/tmp/clab.log 2>&1 || { test_ko "démarrage du réseau"; tail -30 /tmp/clab.log; }
sleep 3
c() { docker exec "clab-hopla-$1" "${@:2}"; }
contient "le poste est en /24" "10.10.10.10/24" c poste ip addr show eth1
contient "le poste connaît sa route" "10.10.20.0/24 via 10.10.10.1" c poste ip route
attendu "le poste joint la compta" c poste ping -c 1 -W 2 10.10.10.20
contient "le poste ouvre le site" "Bienvenue" c poste curl -s -m 3 http://10.10.20.10
contient "le cache ARP connaît la compta" "10.10.10.20 dev eth1 lladdr" c poste ip neigh
contient "le cache ARP connaît la passerelle" "10.10.10.1 dev eth1 lladdr" c poste ip neigh
contient "le trajet passe par la passerelle" "10.10.10.1" c poste traceroute -n -w 2 -m 3 10.10.20.10
attendu "suppression de la route" c poste ip route del 10.10.20.0/24 via 10.10.10.1
attendu "incident : la compta répond toujours" c poste ping -c 1 -W 2 10.10.10.20
refuse  "incident : le site ne répond plus" c poste curl -s -m 3 http://10.10.20.10
attendu "réparation de la route" c poste ip route add 10.10.20.0/24 via 10.10.10.1
contient "le site répond à nouveau" "Bienvenue" c poste curl -s -m 3 http://10.10.20.10

echo "=== TP 1, acte 2"
contient "incident : Internet lit les salaires" "CONFIDENTIEL" c client curl -s -m 4 http://10.10.10.20
if docker exec -i clab-hopla-fw nft -f - < firewall/regles.nft; then test_ok "chargement du fichier étudiant"; else test_ko "chargement du fichier étudiant"; fi
refuse  "tout est interdit : le site est coupé" c client curl -s -m 3 http://10.10.20.10
refuse  "le testeur signale les flux à corriger" bash firewall/tester.sh
if docker exec -i clab-hopla-fw nft -f - < "$racine/formateur/fw-dmz.nft"; then test_ok "chargement du corrigé"; else test_ko "chargement du corrigé"; fi
contient "le testeur valide le corrigé" "4 tests sur 4" bash firewall/tester.sh

echo "=== TP 1, acte 3"
refuse  "Karim n'a pas d'adresse" sh -c "docker exec clab-hopla-nouveau-pc ip addr show eth1 | grep -q 'inet '"
attendu "Karim obtient une adresse" c nouveau-pc udhcpc -i eth1 -n -q -t 3
contient "l'adresse est dans la plage" "10.10.10.1[0-5][0-9]" c nouveau-pc ip addr show eth1
contient "le DNS répond à Karim" "10.10.20.10" c nouveau-pc dig +short +time=2 +tries=1 @10.10.10.53 web.hopla.lan
attendu "arrêt du DNS" c dns pkill dnsmasq
sleep 1
refuse  "le nom ne répond plus" c poste dig +short +time=2 +tries=1 @10.10.10.53 web.hopla.lan
contient "le site répond par son adresse" "Bienvenue" c poste curl -s -m 3 http://10.10.20.10
attendu "relance du DNS" c dns dnsmasq --conf-file=/etc/dnsmasq.d/hopla.conf
sleep 1
contient "le DNS répond à nouveau" "10.10.20.10" c poste dig +short +time=2 +tries=1 @10.10.10.53 web.hopla.lan
sudo containerlab destroy -t hopla.clab.yml --cleanup >/dev/null 2>&1

echo "=== TP 2"
cd "$racine/labs/02-iac-terraform"
reglages="$(cat terraform.tfvars)"
regler() { sed -i "s/^$1 .*/$1 = $2/" terraform.tfvars; }
attendu "terraform init" terraform init -input=false
contient "le plan annonce 10 créations" "10 to add" terraform plan -input=false
attendu "terraform apply" terraform apply -auto-approve -input=false
[ "$(docker ps --filter name=hopla- -q | wc -l)" -eq 4 ] && test_ok "4 conteneurs" || test_ko "4 conteneurs"
sleep 2
contient "le site répond 502" "502" curl -s -i -m 4 localhost:8080
contient "deuxième apply : aucun changement" "No changes" terraform apply -auto-approve -input=false
regler db_memory_mb 512
attendu "mémoire à 512 Mo" terraform apply -auto-approve -input=false
contient "la limite est appliquée" "536870912" docker inspect -f '{{.HostConfig.Memory}}' hopla-db
regler front_count 3
attendu "passage à 3 serveurs" terraform apply -auto-approve -input=false
contient "hopla-front-3 existe" "hopla-front-3" docker ps --format '{{.Names}}'
regler front_count 2
attendu "retour à 2 serveurs" terraform apply -auto-approve -input=false
refuse  "hopla-front-3 a disparu" docker inspect hopla-front-3
regler db_memory_mb 256
attendu "retour à 256 Mo" terraform apply -auto-approve -input=false
docker rm -f hopla-db >/dev/null
contient "dérive : le plan recrée la base" "hopla-db\|docker_container.db" terraform plan -input=false
attendu "la base est recréée" terraform apply -auto-approve -input=false
refuse  "isolation : le LB ne joint pas la base" docker exec hopla-lb ping -c 1 -W 2 hopla-db
contient "le mot de passe est dans le state" "demo-hopla" cat terraform.tfstate
printf '%s\n' "$reglages" > terraform.tfvars

echo "=== TP 3"
cd "$racine/labs/03-ansible"
contient "inventaire généré" "hopla-front-2" cat inventory.ini
contient "premier passage" "failed=0" ansible-playbook playbook.yml
sleep 1
reponses=$(for i in 1 2 3 4; do curl -s -m 4 localhost:8080 | grep -o 'hopla-front-[0-9]'; done | sort -u | wc -l)
[ "$reponses" -eq 2 ] && test_ok "répartition sur 2 serveurs" || test_ko "répartition : $reponses serveur(s)"
contient "relance : changed=0" "changed=0.*failed=0" ansible-playbook playbook.yml
contient "terraform ne voit toujours aucun changement" "No changes" sh -c "cd '$racine/labs/02-iac-terraform' && terraform plan -input=false"
page="$(cat templates/index.html.j2)"
sed -i 's/Hopla Market/Hopla Market Test/' templates/index.html.j2
ansible-playbook playbook.yml >/dev/null 2>&1
contient "la nouvelle page s'affiche" "Hopla Market Test" curl -s -m 4 localhost:8080
printf '%s\n' "$page" > templates/index.html.j2
ansible-playbook playbook.yml >/dev/null 2>&1
docker stop hopla-front-1 >/dev/null
contient "panne d'un serveur : le site répond" "hopla-front-2" curl -s -m 8 localhost:8080
docker start hopla-front-1 >/dev/null
contient "le playbook relance le serveur" "failed=0" ansible-playbook playbook.yml
sleep 11
reponses=$(for i in 1 2 3 4 5 6; do curl -s -m 4 localhost:8080 | grep -o 'hopla-front-[0-9]'; done | sort -u | wc -l)
[ "$reponses" -eq 2 ] && test_ok "les 2 serveurs répondent à nouveau" || test_ko "après relance : $reponses serveur(s)"

echo "=== TP 4"
cd "$racine/labs/04-supervision"
attendu "terraform init" terraform init -input=false
attendu "supervision déployée" terraform apply -auto-approve -input=false
sleep 20
attendu "l'interface répond" curl -fsS -m 5 -o /dev/null localhost:3001
docker stop hopla-front-1 >/dev/null
attendu "panne d'un serveur : le site répond encore" curl -fsS -m 8 -o /dev/null localhost:8080
docker stop hopla-front-2 >/dev/null
refuse  "panne totale : le site est en erreur" curl -fsS -m 8 -o /dev/null localhost:8080
docker start hopla-front-1 hopla-front-2 >/dev/null
contient "le playbook remet le site en route" "failed=0" sh -c "cd '$racine/labs/03-ansible' && ansible-playbook playbook.yml"

echo "=== Finale"
contient "reconstruction complète" "reconstruit en" bash "$racine/labs/finale.sh"
contient "la supervision survit" "hopla-supervision" docker ps --format '{{.Names}}'
cd "$racine/labs/04-supervision" && terraform destroy -auto-approve -input=false >/dev/null 2>&1
cd "$racine/labs/02-iac-terraform" && terraform destroy -auto-approve -input=false >/dev/null 2>&1

echo; echo "RÉSULTAT : $ok OK, $ko échec(s)"
[ "$ko" -eq 0 ]
