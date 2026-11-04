# TP 2 : recréer Hopla avec Terraform

**Durée : 70 min. Incident :** l'admin est parti, le serveur a brûlé, et personne ne sait comment il était installé.

## De quoi s'agit-il ?
Jusqu'ici, tout dépendait de ce que l'admin avait en tête. Nous allons décrire l'infrastructure de Hopla dans des fichiers texte, et laisser Terraform la construire. C'est l'Infrastructure as Code (IaC) : si tout brûle, on relance.

**Ce que vous allez faire :**
1. **Créer Hopla** à partir du code, en lisant d'abord ce que Terraform annonce.
2. **Modifier Hopla** en changeant une valeur : plus de mémoire, un serveur de plus.
3. **Trouver les limites** : ce que Terraform ne sait pas faire, et ce qu'il faut protéger.

Prenez votre temps : le but est de **lire ce que Terraform annonce**, pas d'aller vite.

**Où :** toutes les commandes de ce TP se tapent dans le terminal du Codespace.

## Comment Terraform travaille
```mermaid
flowchart LR
  code["Vos fichiers<br/>main.tf<br/>terraform.tfvars"] --> init["terraform init<br/>prépare les outils"]
  init --> plan["terraform plan<br/>le devis"]
  plan --> apply["terraform apply<br/>le chantier"]
  apply --> infra["Réseaux et conteneurs<br/>dans Docker"]
  apply --> state["terraform.tfstate<br/>le carnet de chantier"]
  state -. "relu au plan suivant" .-> plan
```

| Fichier | Son rôle |
|---|---|
| `main.tf` | Décrit ce qui doit exister |
| `variables.tf` | Déclare les réglages possibles |
| `terraform.tfvars` | Donne la valeur de ces réglages |
| `outputs.tf` | Dit quoi afficher à la fin |
| `versions.tf` | Dit quels outils et quelles versions utiliser |
| `terraform.tfstate` | Mémorise ce que Terraform a créé. Il apparaît après le premier `apply` |

Ici, Terraform crée des conteneurs Docker, pour que le TP reste gratuit. Avec un autre fournisseur (*provider*), le même principe crée des VM chez AWS ou Azure.

## Partie 1 : créer Hopla

### 1. Lire le code
**Pourquoi :** avec Terraform, l'infrastructure se lit avant de se construire.

Ouvrez `labs/02-iac-terraform/main.tf`. Chaque bloc `resource` décrit une chose qui doit exister.

**Question :** combien de réseaux et de conteneurs ce fichier décrit-il ?

### 2. Préparer les outils
**Pourquoi :** Terraform doit télécharger les modules qui savent parler à Docker et écrire des fichiers.
```bash
cd /workspaces/*/labs/02-iac-terraform
terraform init
```
- `cd /workspaces/*/labs/02-iac-terraform` : se place dans le dossier du TP. Le `*` remplace le nom du dépôt.
- `terraform init` : télécharge ces modules dans le dossier `.terraform`. Il suffit de le faire une fois par dossier.

**Vous devez voir :** `Terraform has been successfully initialized!`

**Comment lire le résultat :**

```text
Initializing the backend...

Initializing provider plugins...
- Reusing version 4.6.0 of kreuzwerker/docker from the dependency lock file
...
Terraform has been successfully initialized!
```
- `Initializing provider plugins` : Terraform récupère les modules qui savent parler à Docker. La première fois, vous lirez `Installing` à la place de `Using` ou `Reusing`.
- `successfully initialized` : la seule ligne à vérifier. La suite du message n'est qu'un rappel.

### 3. Lire le devis
**Pourquoi :** on veut savoir ce qui va se passer avant que cela arrive.
```bash
terraform plan
```
- `terraform plan` : compare le code à ce qui existe, puis annonce les changements, sans rien toucher. `+` veut dire créer, `~` modifier, `-` détruire, et `-/+` détruire puis recréer.

**Vous devez voir :** `Plan: 10 to add, 0 to change, 0 to destroy.` Rien n'a encore été créé.

**Comment lire le résultat :**

Le résultat fait plusieurs centaines de lignes. Commencez par la fin, puis remontez. En voici un extrait :

```text
Terraform will perform the following actions:

  # docker_container.db will be created
  + resource "docker_container" "db" {
      + id                                          = (known after apply)
      + memory                                      = 256
      + name                                        = "hopla-db"
      ...
    }
...
Plan: 10 to add, 0 to change, 0 to destroy.
```
- `Plan: 10 to add, 0 to change, 0 to destroy.` : le résumé, à lire en premier. 10 créations, 0 modification, 0 destruction.
- `# docker_container.db will be created` : le titre de chaque ressource, et ce qui va lui arriver.
- `+` en début de ligne : cet élément sera créé.
- `(known after apply)` : Terraform ne connaîtra cette valeur qu'après la création.
- `Note: You didn't use the -out option...` : ignorez ce message dans ce TP.

### 4. Lancer le chantier
**Pourquoi :** le devis convient, on passe à la construction.
```bash
terraform apply
```
- `terraform apply` : refait le plan, demande votre accord, puis crée ce qui manque.

Relisez le plan, puis tapez `yes`.

**Vous devez voir :** `Apply complete! Resources: 10 added`.

**Comment lire le résultat :**

```text
Plan: 10 to add, 0 to change, 0 to destroy.
...
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

docker_network.front: Creating...
docker_network.front: Creation complete after 2s [id=a0216f7f1be7...]
...
Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:

serveurs_web = [
  "hopla-front-1",
  "hopla-front-2",
]
site = "http://localhost:8080"
```
- `Enter a value:` : Terraform attend votre réponse. Seul `yes` lance le chantier.
- `Creating...`, puis `Creation complete` : le suivi, ressource par ressource.
- `Apply complete! Resources: 10 added` : tout est créé. C'est la ligne à vérifier.
- `Outputs` : ce que `outputs.tf` demande d'afficher à la fin.

### 5. Regarder le résultat
**Pourquoi :** on vérifie par un autre moyen que Terraform, et on essaie le site.
```bash
docker ps
curl -i localhost:8080
```
- `docker ps` : liste les conteneurs en marche.
- `curl -i localhost:8080` : demande la page du site. `-i` affiche aussi le code de réponse, comme `200` ou `502`. Le port `8080` du Codespace mène au port 80 de `hopla-lb`.

**Vous devez voir :** 4 conteneurs, puis `502 Bad Gateway`.

**Comment lire le résultat :**

Résultat de `docker ps`. Le tableau est large, faites défiler si besoin :

```text
CONTAINER ID   IMAGE          COMMAND                  CREATED                  STATUS                  PORTS                  NAMES
a92bd9545157   785835ea65db   "/docker-entrypoint.…"   Less than a second ago   Up Less than a second   0.0.0.0:8080->80/tcp   hopla-lb
1b61d6112d9a   0cefaabd882e   "docker-entrypoint.s…"   Less than a second ago   Up Less than a second   5432/tcp               hopla-db
5f1b7dfa4a78   b18b261e1b49   "sleep infinity"         Less than a second ago   Up Less than a second                          hopla-front-1
f25c746a757a   b18b261e1b49   "sleep infinity"         Less than a second ago   Up Less than a second                          hopla-front-2
```
- `NAMES`, la dernière colonne : le nom du conteneur. C'est celle qu'on lit en premier.
- `STATUS` : `Up` veut dire allumé.
- `PORTS` : `0.0.0.0:8080->80/tcp` veut dire que le port 8080 du Codespace mène au port 80 de `hopla-lb`. `5432/tcp`, sans flèche : ce port n'est pas ouvert vers l'extérieur.
- `CONTAINER ID`, `IMAGE` et `COMMAND` : vous pouvez les ignorer ici.

Résultat de `curl -i`, avec le début de la réponse :

```text
HTTP/1.1 502 Bad Gateway
Server: nginx/1.31.8
...
<center><h1>502 Bad Gateway</h1></center>
```
- `HTTP/1.1 502 Bad Gateway` : le code de réponse, sur la première ligne. `200` veut dire que tout va bien. `502` veut dire que le serveur intermédiaire n'a pas obtenu de réponse des serveurs derrière lui.
- `Server: nginx` : c'est bien `hopla-lb` qui répond.
- La suite est la page d'erreur, en HTML.

Voici ce que vous venez de créer :

```mermaid
flowchart LR
  c["Vous<br/>localhost:8080"] --> lb["hopla-lb<br/>load balancer nginx"]
  lb -- "réseau hopla-front" --> f1["hopla-front-1<br/>serveur web, vide"]
  lb -- "réseau hopla-front" --> f2["hopla-front-2<br/>serveur web, vide"]
  f1 -- "réseau hopla-back" --> db[("hopla-db<br/>PostgreSQL")]
  f2 -- "réseau hopla-back" --> db
```

Dans ce TP, `hopla-lb` est un nginx en reverse proxy : il reçoit les clients à la place des serveurs web, et il les répartit entre eux.

Ce `502` est normal : les serveurs web existent, mais rien n'y est installé. Ce sera le TP 3.

### 6. Relancer sans rien changer
**Pourquoi :** Terraform compare ce qui existe à ce qui est demandé. Voyons ce qu'il fait quand tout est déjà là.
```bash
terraform apply
```
- `terraform apply` : la même commande qu'à l'étape 4. Elle ne demande rien s'il n'y a rien à faire.

**Vous devez voir :** `No changes.`

**Comment lire le résultat :**

```text
docker_network.front: Refreshing state... [id=a0216f7f1be7...]
docker_container.db: Refreshing state... [id=1b61d6112d9a...]
...
No changes. Your infrastructure matches the configuration.
...
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```
- `Refreshing state...` : Terraform vérifie où en est chaque ressource.
- `No changes` : ce qui existe correspond déjà au code.
- `0 added, 0 changed, 0 destroyed` : il n'a rien touché.

**Question :** que se serait-il passé avec un script lancé deux fois ?

## Partie 2 : modifier Hopla
**Le principe :** on ne touche plus aux conteneurs à la main. On change une valeur dans le code, et Terraform calcule la différence.

Ouvrez `labs/02-iac-terraform/terraform.tfvars`. C'est là que se trouvent les réglages.

### 7. Donner plus de mémoire à la base
**Pourquoi :** les ventes augmentent, et la base a besoin de plus de mémoire.

Remplacez `256` par `512` sur la ligne `db_memory_mb`, enregistrez, puis lancez :
```bash
terraform plan
terraform apply
docker inspect -f '{{.HostConfig.Memory}}' hopla-db
```
- `terraform plan` : annonce le changement. Regardez le symbole devant `hopla-db`.
- `terraform apply` : l'applique. Répondez `yes`.
- `docker inspect hopla-db` : affiche la fiche technique du conteneur. `-f '{{.HostConfig.Memory}}'` n'en garde que la limite de mémoire, en octets.

**Vous devez voir :** `536870912`, soit 512 Mo.

**Comment lire le résultat :**

Résultat de `terraform plan` :

```text
  ~ update in-place

Terraform will perform the following actions:

  # docker_container.db will be updated in-place
  ~ resource "docker_container" "db" {
      ~ memory                                      = 256 -> 512
        name                                        = "hopla-db"
        # (50 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```
- `~` : modifier. Le plan peut aussi afficher `+` (créer), `-` (détruire) ou `-/+` (détruire puis recréer).
- `~ memory = 256 -> 512` : l'ancienne valeur, puis la nouvelle.
- `(50 unchanged attributes hidden)` : le reste ne change pas, et Terraform ne l'affiche pas.

Résultat de `docker inspect` : le nombre est en octets. 512 × 1024 × 1024 = 536 870 912.

```text
536870912
```

**Question :** dans le plan, la base est-elle modifiée (`~`) ou détruite puis recréée (`-/+`) ?

### 8. Ajouter un serveur web
**Pourquoi :** le trafic monte, il faut un serveur de plus.

Remplacez `2` par `3` sur la ligne `front_count`, enregistrez, puis lancez :
```bash
terraform plan
terraform apply
docker ps
```
- `terraform plan` : annonce ce qui change. Lisez toutes les lignes.
- `terraform apply` : l'applique. Répondez `yes`.
- `docker ps` : vérifie la liste des conteneurs.

**Vous devez voir :** `hopla-front-3` dans la liste.

**Comment lire le résultat :**

Résultat de `terraform plan`, en ne gardant que les titres :

```text
  # docker_container.front[2] will be created
  # docker_container.lb must be replaced
      - upload { # forces replacement
      + upload { # forces replacement
  # local_file.inventaire must be replaced
Plan: 3 to add, 0 to change, 2 to destroy.
```
- `front[2]` : le troisième serveur, car la numérotation commence à 0. Il deviendra `hopla-front-3`.
- `must be replaced` : détruit, puis recréé.
- `# forces replacement` : le changement qui oblige à recréer la ressource.
- `3 to add, 2 to destroy` : 1 nouveau serveur, plus 2 ressources recréées.

Résultat de `docker ps` : la dernière colonne compte maintenant 5 conteneurs.

```text
CONTAINER ID   IMAGE          COMMAND                  CREATED                  STATUS                  PORTS                  NAMES
8cb7c22bac97   785835ea65db   "/docker-entrypoint.…"   Less than a second ago   Up Less than a second   0.0.0.0:8080->80/tcp   hopla-lb
cb757ae141ca   b18b261e1b49   "sleep infinity"         Less than a second ago   Up Less than a second                          hopla-front-3
1b61d6112d9a   0cefaabd882e   "docker-entrypoint.s…"   14 seconds ago           Up 14 seconds           5432/tcp               hopla-db
5f1b7dfa4a78   b18b261e1b49   "sleep infinity"         14 seconds ago           Up 14 seconds                                  hopla-front-1
f25c746a757a   b18b261e1b49   "sleep infinity"         14 seconds ago           Up 14 seconds                                  hopla-front-2
```

**Question :** pourquoi le load balancer change-t-il aussi ?

### 9. Revenir à deux serveurs
**Pourquoi :** le code décrit aussi ce qui ne doit plus exister. Retirer une ligne ou baisser un nombre fait détruire.

Remettez `front_count = 2`, enregistrez, puis lancez :
```bash
terraform apply
```
- `terraform apply` : détruit le serveur en trop. Répondez `yes`.

**Vous devez voir :** `hopla-front-3` détruit. Gardez bien 2 serveurs pour la suite.

**Comment lire le résultat :**

```text
  # docker_container.front[2] will be destroyed
  # (because index [2] is out of range for count)
  # docker_container.lb must be replaced
  # local_file.inventaire must be replaced
Plan: 2 to add, 0 to change, 3 to destroy.
...
Apply complete! Resources: 2 added, 0 changed, 3 destroyed.
```
- `will be destroyed` : le troisième serveur va disparaître.
- `out of range for count` : la raison. Il n'y a plus que 2 serveurs demandés, donc `front[2]` n'a plus de place.
- `3 destroyed, 2 added` : le serveur en trop, plus le load balancer et l'inventaire, recréés avec la nouvelle liste.

## Partie 3 : ce que Terraform ne fait pas

### 10. Supprimer la base à la main
**Pourquoi :** quelqu'un supprime la base sans passer par le code. Terraform s'en rend-il compte ?
```bash
docker rm -f hopla-db
terraform plan
```
- `docker rm -f hopla-db` : supprime le conteneur, même s'il tourne (`-f` pour *force*).
- `terraform plan` : compare de nouveau le code à ce qui existe vraiment.

**Vous devez voir :** Terraform propose de recréer `hopla-db`.

**Comment lire le résultat :**

`docker rm` affiche le nom du conteneur supprimé. Puis `terraform plan` :

```text
hopla-db
...
  # docker_container.db will be created
...
Plan: 1 to add, 0 to change, 0 to destroy.
```
Terraform a comparé son carnet à ce qui existe vraiment : la base manque, il propose de la créer. Une différence entre le code et la réalité s'appelle une dérive.

**Question :** il recréera le conteneur, mais que deviendront les données ?

Remettez la base en place :
```bash
terraform apply
```
- `terraform apply` : recrée le conteneur. Répondez `yes`.

### 11. Vérifier l'isolation
**Pourquoi :** le load balancer est exposé aux clients, et la base est sur un autre réseau. Vérifions que cette séparation fonctionne.
```bash
docker exec hopla-lb ping -c 1 hopla-db
```
- `docker exec hopla-lb ...` : lance la commande dans le load balancer.
- `ping -c 1 hopla-db` : tente de joindre la base par son nom, avec un seul message.

**Vous devez voir :** `bad address`. Le load balancer n'est pas sur le même réseau que la base.

**Comment lire le résultat :**

```text
ping: bad address 'hopla-db'
```
`bad address` : le nom `hopla-db` n'existe pas pour cette machine. `hopla-lb` n'est branché que sur le réseau `hopla-front`, et la base est sur `hopla-back`.

### 12. Ouvrir le carnet de chantier
**Pourquoi :** le fichier `terraform.tfstate` contient tout ce que Terraform sait. Tout, vraiment ?
```bash
grep -c demo-hopla terraform.tfstate
```
- `grep -c demo-hopla terraform.tfstate` : compte les lignes du fichier qui contiennent `demo-hopla`, le mot de passe de la base.

**Vous devez voir :** un nombre supérieur à 0. Le mot de passe est écrit en clair dans ce fichier.

**Comment lire le résultat :**

```text
1
```
`grep -c` affiche un nombre : les lignes du fichier qui contiennent `demo-hopla`. Ici 1 ligne, donc le mot de passe est bien dans le fichier. `0` voudrait dire qu'il n'y est pas.

**Question :** pourquoi ne faut-il pas envoyer ce fichier dans Git ?

## Si ça bloque
| Problème | Solution |
|---|---|
| `No configuration files` | Vous n'êtes pas dans le bon dossier : `cd /workspaces/*/labs/02-iac-terraform` |
| `Error: ... Cannot connect to the Docker daemon` | Attendez une minute, puis relancez `bash ../00-verifier.sh` |
| `name is already in use` | Reste d'un essai précédent : `docker rm -f hopla-front-1 hopla-front-2 hopla-lb hopla-db`, puis `terraform apply` |
| Tout est cassé | Repartir de zéro : `terraform destroy`, puis `terraform apply` |
