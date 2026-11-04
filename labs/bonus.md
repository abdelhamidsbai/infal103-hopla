# Exercices bonus

Pour celles et ceux qui ont terminé en avance. Aucun n'est nécessaire pour suivre le cours.

## Voir passer les paquets (TP 1, acte 1)
**Le but :** regarder les paquets traverser le firewall. Le réseau doit être allumé.

Dans un second terminal du Codespace :
```bash
docker exec clab-hopla-fw tcpdump -ni eth2 -c 4
```
- `tcpdump` : affiche les paquets qui passent.
- `-n` : affiche les adresses, sans chercher les noms.
- `-i eth2` : écoute la prise du site.
- `-c 4` : s'arrête après 4 paquets.

Dans le premier, depuis `poste`, relancez `curl -m 3 http://10.10.20.10`. Repérez les adresses source et destination.

## Essayer IPv6 (TP 1, acte 1)
**Le but :** faire communiquer deux machines avec des adresses IPv6, écrites en hexadécimal et sur 128 bits.
```bash
docker exec clab-hopla-poste ip addr add fd00:10::10/64 dev eth1
docker exec clab-hopla-compta ip addr add fd00:10::20/64 dev eth1
docker exec clab-hopla-poste ping -6 -c 2 fd00:10::20
```
- `ip addr add ... dev eth1` : ajoute une adresse à la prise `eth1`. Elle s'ajoute à l'adresse IPv4, les deux coexistent.
- `ping -6` : envoie le ping en IPv6.

## Simuler deux serveurs et un client à la main
**Le but :** créer un mini-réseau sans containerlab ni Terraform, pour voir ce que ces outils nous évitent.
```bash
docker network create tp-mini
for m in srv1 srv2 client; do docker run -d --name $m --network tp-mini alpine:3.20 sleep infinity; done
docker exec client ping -c 2 srv1
docker exec srv1 uname -r
uname -r
docker rm -f srv1 srv2 client
docker network rm tp-mini
```
- `docker network create tp-mini` : crée un réseau.
- `docker run -d --name $m --network tp-mini alpine:3.20 sleep infinity` : démarre un conteneur en arrière-plan (`-d`), avec ce nom, sur ce réseau. `sleep infinity` le garde allumé. La boucle `for` le fait pour chacune des 3 machines.
- `ping -c 2 srv1` : joint `srv1` par son nom, grâce au DNS intégré à Docker.
- `uname -r` : affiche la version du noyau, dans le conteneur, puis dans le Codespace.
- `docker rm -f` et `docker network rm` : font le ménage.

Combien de commandes faudrait-il pour 50 machines ? Pourquoi `uname -r` affiche-t-il la même chose partout ?

## Afficher le graphe de Terraform (TP 2)
**Le but :** voir dans quel ordre Terraform crée les ressources. Il le déduit de leurs dépendances.

Dans `labs/02-iac-terraform` :
```bash
terraform graph
```
- `terraform graph` : affiche les ressources et leurs liens, sous forme de texte. Chaque ligne `A -> B` se lit : A dépend de B.

## Simuler sans rien modifier (TP 3)
**Le but :** voir ce qu'Ansible changerait, sans rien changer.

Dans `labs/03-ansible` :
```bash
ansible-playbook playbook.yml --check
```
- `--check` : joue le playbook à blanc. Les tâches annoncent leur résultat, mais rien n'est modifié.

## Voir la table MAC du switch
**Le but :** vérifier que le switch retient derrière quelle prise se trouve chaque adresse MAC. Le réseau du TP 1 doit être allumé.
```bash
docker exec clab-hopla-sw-bureau bridge fdb show br br0 | grep -v permanent
```
- `bridge fdb show br br0` : affiche la table MAC du switch, appelé ici `br0` (`fdb` pour *forwarding database*).
- `| grep -v permanent` : retire les lignes `permanent`, pour ne garder que ce que le switch a appris.

Comparez avec le résultat de `ip neigh` sur le poste : les mêmes adresses MAC y apparaissent, mais le poste les associe à une IP, et le switch à une prise.
