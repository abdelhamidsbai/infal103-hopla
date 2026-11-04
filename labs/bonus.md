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

**Comment lire le résultat :**

```text
21:13:45.590195 IP 10.10.10.10.48910 > 10.10.20.10.80: Flags [S], seq 2707742607, ...
21:13:45.590220 IP 10.10.20.10.80 > 10.10.10.10.48910: Flags [S.], seq 2276700648, ack 2707742608, ...
21:13:45.590242 IP 10.10.10.10.48910 > 10.10.20.10.80: Flags [.], ack 1, ...
21:13:45.590290 IP 10.10.10.10.48910 > 10.10.20.10.80: Flags [P.], seq 1:76, ack 1, ...
```
- `10.10.10.10.48910 > 10.10.20.10.80` : le paquet part du poste (port 48910) vers le site (port 80).
- `Flags [S]`, `[S.]`, puis `[.]` : les trois échanges qui ouvrent une connexion TCP : SYN, SYN-ACK et ACK.
- `Flags [P.]` : la demande de la page.

## Essayer IPv6 (TP 1, acte 1)
**Le but :** faire communiquer deux machines avec des adresses IPv6, écrites en hexadécimal et sur 128 bits.
```bash
docker exec clab-hopla-poste ip addr add fd00:10::10/64 dev eth1
docker exec clab-hopla-compta ip addr add fd00:10::20/64 dev eth1
docker exec clab-hopla-poste ping -6 -c 2 fd00:10::20
```
- `ip addr add ... dev eth1` : ajoute une adresse à la prise `eth1`. Elle s'ajoute à l'adresse IPv4, les deux coexistent.
- `ping -6` : envoie le ping en IPv6.

**Comment lire le résultat :** `ip addr add` n'affiche rien. Le `ping` se lit comme en IPv4 :

```text
64 bytes from fd00:10::20: icmp_seq=1 ttl=64 time=0.100 ms
...
2 packets transmitted, 2 received, 0% packet loss, time 1045ms
```

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

**Comment lire le résultat :**

```text
digraph G {
  "docker_container.db" -> "docker_image.postgres";
  "docker_container.db" -> "docker_network.back";
  "docker_container.lb" -> "docker_container.front";
  ...
}
```
La flèche se lit « dépend de » : la base a besoin de son image et de son réseau, et le load balancer a besoin des serveurs web. Terraform crée donc d'abord ce qui est à droite de la flèche.

## Simuler sans rien modifier (TP 3)
**Le but :** voir ce qu'Ansible changerait, sans rien changer.

Dans `labs/03-ansible` :
```bash
ansible-playbook playbook.yml --check
```
- `--check` : joue le playbook à blanc. Les tâches annoncent leur résultat, mais rien n'est modifié.

**À lancer après l'étape 3 du TP 3.** Sur des serveurs encore vides, la simulation s'arrête dès la première tâche :

```text
fatal: [hopla-front-1]: FAILED! => {"changed": false, "msg": "python3-apt must be installed to use check mode. ..."}
```
Le module `apt` a besoin de `python3-apt`, qu'il installe lui-même seulement lors d'un vrai lancement.

Une fois le playbook passé, la simulation se lit comme un lancement normal. `changed` y veut dire « changerait ».

## Voir la table MAC du switch
**Le but :** vérifier que le switch retient derrière quelle prise se trouve chaque adresse MAC. Le réseau du TP 1 doit être allumé.
```bash
docker exec clab-hopla-sw-bureau bridge fdb show br br0 | grep -v permanent
```
- `bridge fdb show br br0` : affiche la table MAC du switch, appelé ici `br0` (`fdb` pour *forwarding database*).
- `| grep -v permanent` : retire les lignes `permanent`, pour ne garder que ce que le switch a appris.

Comparez avec le résultat de `ip neigh` sur le poste : les mêmes adresses MAC y apparaissent, mais le poste les associe à une IP, et le switch à une prise.

**Comment lire le résultat :**

```text
aa:c1:ab:79:6f:73 dev eth5 master br0
aa:c1:ab:23:91:00 dev eth1 master br0
aa:c1:ab:0a:b5:94 dev eth2 master br0
```
Chaque ligne associe une adresse MAC à une prise (`eth5`, `eth1`...) du switch `br0`. Ici, `eth1` mène à `poste` et `eth5` à `fw`.
