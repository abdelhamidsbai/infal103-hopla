# Exercices bonus

Pour celles et ceux qui ont terminé en avance. Aucun n'est nécessaire pour suivre le cours.

## Voir passer les paquets (TP 1, acte 1)
Le réseau doit être allumé. Dans un second terminal :
```bash
docker exec clab-hopla-fw tcpdump -ni eth2 -c 4
```
Dans le premier, depuis `poste`, relancez `curl -m 3 http://10.10.20.10`. Repérez les adresses source et destination.

## Essayer IPv6 (TP 1, acte 1)
```bash
docker exec clab-hopla-poste ip addr add fd00:10::10/64 dev eth1
docker exec clab-hopla-compta ip addr add fd00:10::20/64 dev eth1
docker exec clab-hopla-poste ping -6 -c 2 fd00:10::20
```

## Simuler deux serveurs et un client à la main
```bash
docker network create tp-mini
for m in srv1 srv2 client; do docker run -d --name $m --network tp-mini alpine:3.20 sleep infinity; done
docker exec client ping -c 2 srv1
docker exec srv1 uname -r
uname -r
docker rm -f srv1 srv2 client
docker network rm tp-mini
```
Combien de commandes faudrait-il pour 50 machines ? Pourquoi `uname -r` affiche-t-il la même chose partout ?

## Afficher le graphe de Terraform (TP 2)
```bash
terraform graph
```

## Simuler sans rien modifier (TP 3)
```bash
ansible-playbook playbook.yml --check
```

## Voir la table MAC du switch

Le switch retient derrière quelle prise se trouve chaque adresse MAC :
```bash
docker exec clab-hopla-sw-bureau bridge fdb show br br0 | grep -v permanent
```
Comparez avec le résultat de `ip neigh` sur le poste : les mêmes adresses MAC y apparaissent, mais le poste les associe à une IP, et le switch à une prise.
