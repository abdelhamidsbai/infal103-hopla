#!/usr/bin/env bash
# Rejoue les commandes des TP et affiche leurs résultats réels.
# Ces résultats servent d'exemples dans les énoncés. Aucun contrôle ici : voir verifier.sh.
set -u
racine="$(cd "$(dirname "$0")/.." && pwd)"
export TF_CLI_ARGS="-no-color" ANSIBLE_NOCOLOR=1
titre() { echo; echo "@@@@@ $*"; }
run() { echo "@@ \$ $*"; eval "$@" 2>&1; echo "@@ code retour : $?"; }
dans() { local m="$1"; shift; echo "@@ $m:~# $*"; docker exec "clab-hopla-$m" sh -c "$*" 2>&1; echo "@@ code retour : $?"; }
regler() { sed -i "s/^$1 .*/$1 = $2/" terraform.tfvars; }

titre "Environnement"
cd "$racine"
run bash labs/00-verifier.sh

titre "TP 1, acte 1"
cd "$racine/labs/01-reseau"
run sudo containerlab deploy -t hopla.clab.yml
sleep 3
dans poste ip addr show eth1
dans poste ip route
dans poste ping -c 2 10.10.10.20
dans poste curl -m 3 http://10.10.20.10
dans poste ip neigh
dans poste traceroute -n 10.10.20.10
dans poste ip route del 10.10.20.0/24 via 10.10.10.1
dans poste ping -c 2 10.10.10.20
dans poste curl -m 3 http://10.10.20.10
dans poste ip route add 10.10.20.0/24 via 10.10.10.1
dans poste curl -m 3 http://10.10.20.10

titre "Bonus réseau"
(docker exec clab-hopla-fw tcpdump -ni eth2 -c 4 2>&1 | sed 's/^/@@ tcpdump : /') &
sleep 2
docker exec clab-hopla-poste curl -s -m 3 -o /dev/null http://10.10.20.10
wait
dans poste ip addr add fd00:10::10/64 dev eth1
dans compta ip addr add fd00:10::20/64 dev eth1
sleep 3
dans poste ping -6 -c 2 fd00:10::20
run "docker exec clab-hopla-sw-bureau bridge fdb show br br0 | grep -v permanent"

titre "TP 1, acte 2"
run docker exec clab-hopla-client curl -s -m 4 http://10.10.10.20
run "docker exec -i clab-hopla-fw nft -f - < firewall/regles.nft"
run bash firewall/tester.sh
run "docker exec -i clab-hopla-fw nft -f - < $racine/formateur/fw-dmz.nft"
run bash firewall/tester.sh

titre "TP 1, acte 3"
dans nouveau-pc ip addr show eth1
dans nouveau-pc udhcpc -i eth1 -n -q
dans nouveau-pc ip addr show eth1
dans nouveau-pc dig +short @10.10.10.53 web.hopla.lan
run docker exec clab-hopla-dns pkill dnsmasq
sleep 1
run docker exec clab-hopla-poste dig +short +time=2 +tries=1 @10.10.10.53 web.hopla.lan
run docker exec clab-hopla-poste curl -s -m 3 http://10.10.20.10
run docker exec clab-hopla-dns dnsmasq --conf-file=/etc/dnsmasq.d/hopla.conf
sleep 1
run docker exec clab-hopla-poste dig +short @10.10.10.53 web.hopla.lan
run sudo containerlab destroy -t hopla.clab.yml --cleanup

titre "TP 2"
cd "$racine/labs/02-iac-terraform"
reglages="$(cat terraform.tfvars)"
run terraform init
run terraform plan
echo '@@ $ terraform apply (réponse : yes)'
echo yes | terraform apply 2>&1 || terraform apply -auto-approve 2>&1
run docker ps
sleep 2
run curl -i localhost:8080
run terraform apply
regler db_memory_mb 512
run terraform plan
run terraform apply -auto-approve
run "docker inspect -f '{{.HostConfig.Memory}}' hopla-db"
regler front_count 3
run terraform plan
run terraform apply -auto-approve
run docker ps
regler front_count 2
run terraform plan
run terraform apply -auto-approve
run docker rm -f hopla-db
run terraform plan
run terraform apply -auto-approve
run docker exec hopla-lb ping -c 1 hopla-db
run grep -c demo-hopla terraform.tfstate
run terraform graph
printf '%s\n' "$reglages" > terraform.tfvars
run terraform apply -auto-approve

titre "TP 3"
cd "$racine/labs/03-ansible"
run cat inventory.ini
run ansible-playbook playbook.yml --check
run ansible-playbook playbook.yml
sleep 1
run 'for i in 1 2 3 4; do curl -s localhost:8080 | grep Servi; done'
run ansible-playbook playbook.yml
page="$(cat templates/index.html.j2)"
sed -i 's/Hopla Market/Hopla Market, le nouveau site/' templates/index.html.j2
run ansible-playbook playbook.yml
run curl -s localhost:8080
printf '%s\n' "$page" > templates/index.html.j2
ansible-playbook playbook.yml >/dev/null 2>&1
run docker stop hopla-front-1
run 'for i in 1 2 3 4; do curl -s localhost:8080 | grep Servi; done'
run docker start hopla-front-1
run ansible-playbook playbook.yml

titre "TP 4"
cd "$racine/labs/04-supervision"
run terraform init
run terraform apply -auto-approve
run docker stop hopla-front-1
run docker stop hopla-front-2
run docker start hopla-front-1 hopla-front-2
cd ../03-ansible
run ansible-playbook playbook.yml

titre "Finale"
cd "$racine"
run bash labs/finale.sh

titre "Ménage"
cd "$racine/labs/04-supervision" && terraform destroy -auto-approve >/dev/null 2>&1
cd "$racine/labs/02-iac-terraform" && terraform destroy -auto-approve >/dev/null 2>&1
echo "Captures terminées."
