# TP 1 : le réseau de Hopla Market

Ce TP se fait en trois actes, répartis dans la journée. Le réseau de Hopla reste allumé d'un acte à l'autre.

```
 poste      10.10.10.10 ─┐
 compta     10.10.10.20 ─┤
 dns        10.10.10.53 ─┼─ sw-bureau ── eth1 ┐
 nouveau-pc (sans IP)   ─┘                    │
                                     fw (routeur)  eth2 ── web    10.10.20.10
                                                   eth3 ── client 203.0.113.10
```

`sw-bureau` joue le rôle du switch du bureau. Le firewall et le site n'en ont pas besoin : ils ne sont que deux, reliés directement.

## Acte 1 : explorer le réseau
**Durée : 40 min. Incident :** à l'accueil, le site ne s'ouvre pas. Vous allez le reproduire, puis le réparer.

### 1. Démarrer le réseau
```bash
cd labs/01-reseau
sudo containerlab deploy -t hopla.clab.yml
```
**Vous devez voir :** un tableau de 8 machines, au bout d'une à deux minutes.

### 2. Entrer dans le poste d'accueil
```bash
docker exec -it clab-hopla-poste bash
```
**Vous devez voir :** une nouvelle invite de commande, à l'intérieur de `poste`.

### 3. Lire son adresse et ses routes
```bash
ip addr show eth1
ip route
```
**Vous devez voir :** `10.10.10.10/24`, puis une ligne `10.10.20.0/24 via 10.10.10.1`.

**Question :** par quelle passerelle le poste passe-t-il pour rejoindre le serveur web ?

Ignorez `eth0` : cette interface sert uniquement à faire fonctionner le laboratoire.

### 4. Tester la compta, puis le site
```bash
ping -c 2 10.10.10.20
curl -m 3 http://10.10.20.10
```
**Vous devez voir :** le ping répond, puis `Bienvenue chez Hopla Market`.

### 5. Lire le cache ARP du poste
```bash
ip neigh
```
**Vous devez voir :** une ligne pour `10.10.10.20` et une pour `10.10.10.1`, chacune avec une adresse MAC après `lladdr`. Ignorez les lignes `eth0`.

**Question :** le poste vient de joindre le site `10.10.20.10`. Pourquoi sa MAC n'apparaît-elle pas ?

### 6. Suivre le trajet vers le site
```bash
traceroute -n 10.10.20.10
```
**Vous devez voir :** d'abord `10.10.10.1`, puis `10.10.20.10`.

### 7. Reproduire l'incident
```bash
ip route del 10.10.20.0/24 via 10.10.10.1
ping -c 2 10.10.10.20
curl -m 3 http://10.10.20.10
```
**Vous devez voir :** la compta répond toujours, et le `curl` vers le site échoue avec une erreur de connexion. Le poste ne sait plus comment rejoindre cette rue.

**Question :** pourquoi la compta marche-t-elle encore ?

### 8. Réparer
```bash
ip route add 10.10.20.0/24 via 10.10.10.1
curl -m 3 http://10.10.20.10
exit
```
**Vous devez voir :** `Bienvenue chez Hopla Market`.

### Avant le retour collectif
Expliquez à votre voisin, sans regarder vos notes, le trajet d'un paquet entre le poste et le site.

## Acte 2 : protéger la compta
**Durée : 40 min. Incident :** depuis Internet, n'importe qui lit les salaires.

Vous allez traduire en règles la matrice remplie au tableau. Rappel des prises du firewall :

| Prise de `fw` | Elle mène vers |
|---|---|
| `eth1` | le bureau et la compta |
| `eth2` | le site web |
| `eth3` | Internet |

### 1. Constater le problème
```bash
cd labs/01-reseau
docker exec clab-hopla-client curl -s -m 4 http://10.10.10.20
```
**Vous devez voir :** `CONFIDENTIEL - salaires Hopla Market`.

### 2. Charger le fichier de règles tel quel
```bash
docker exec -i clab-hopla-fw nft -f - < firewall/regles.nft
bash firewall/tester.sh
```
**Vous devez voir :** Internet ne lit plus la compta, mais le site et le bureau sont coupés aussi. Tout est interdit par défaut : c'est le principe.

### 3. Compléter les règles
Ouvrez `labs/01-reseau/firewall/regles.nft`. Enlevez le `#` devant les deux règles, puis remplacez les `?` en vous aidant du tableau.

Ici, `fw` est un simple Linux, et le firewall, c'est `nftables` : pas besoin de boîtier. En entreprise, le même rôle est souvent tenu par un boîtier comme FortiGate ou par un logiciel comme pfSense.

Notre site de TP ne sert que le port 80 (HTTP) : c'est donc le seul à ouvrir. Un vrai site ouvrirait aussi le port 443 (HTTPS, le web chiffré), avec `tcp dport { 80, 443 } accept`.

### 4. Charger et tester
```bash
docker exec -i clab-hopla-fw nft -f - < firewall/regles.nft
bash firewall/tester.sh
```
**Vous devez voir :** `4 tests sur 4 sont bons`. Sinon, le script indique le flux à corriger : modifiez le fichier et relancez ces deux commandes.

**Question :** si le site est piraté, peut-il atteindre la compta ?

## Acte 3 : le premier jour de Karim
**Durée : 25 min. Incident :** Karim arrive, et son poste n'a ni adresse ni nom de serveur.

### 1. Entrer dans le poste de Karim
```bash
docker exec -it clab-hopla-nouveau-pc bash
ip addr show eth1
```
**Vous devez voir :** aucune ligne `inet` sur `eth1`. Ce poste n'a pas d'adresse.

### 2. Demander une adresse
```bash
udhcpc -i eth1 -n -q
ip addr show eth1
```
**Vous devez voir :** une adresse entre `10.10.10.100` et `10.10.10.150`.

Seul ce poste passe par le DHCP. Le site, la compta et le DNS ont une adresse fixe : ce sont des serveurs, leurs clients doivent toujours les retrouver.

### 3. Demander l'adresse du site à partir de son nom
```bash
dig +short @10.10.10.53 web.hopla.lan
exit
```
**Vous devez voir :** `10.10.20.10`.

### 4. Prendre un pari, puis casser le DNS
**Pariez :** si le DNS tombe, le poste d'accueil peut-il encore ouvrir le site ?
```bash
docker exec clab-hopla-dns pkill dnsmasq
docker exec clab-hopla-poste dig +short +time=2 +tries=1 @10.10.10.53 web.hopla.lan
docker exec clab-hopla-poste curl -s -m 3 http://10.10.20.10
```
**Vous devez voir :** le nom ne répond plus (`no servers could be reached`), alors que le site répond toujours par son adresse.

### 5. Réparer, puis éteindre
```bash
docker exec clab-hopla-dns dnsmasq --conf-file=/etc/dnsmasq.d/hopla.conf
docker exec clab-hopla-poste dig +short @10.10.10.53 web.hopla.lan
cd labs/01-reseau
sudo containerlab destroy -t hopla.clab.yml --cleanup
```
**Vous devez voir :** `10.10.20.10`, puis la suppression des machines.

## Si ça bloque
| Problème | Solution |
|---|---|
| `No such file or directory` sur `hopla.clab.yml` | Vous n'êtes pas dans le bon dossier : `cd /workspaces/*/labs/01-reseau` |
| Une commande `ip` ou `curl` n'existe pas | Vous n'êtes pas dans la bonne machine : tapez `exit`, puis entrez à nouveau |
| Le Codespace a été arrêté, ou tout est cassé | Repartir de zéro : `sudo containerlab deploy -t hopla.clab.yml --reconfigure`. Les règles du firewall sont alors à recharger |
| Une machine ne répond pas | Relancez la commande de démarrage ci-dessus |
