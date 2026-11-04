# TP 2 : recréer Hopla avec Terraform

**Durée : 70 min. Incident :** l'admin est parti, le serveur a brûlé, et personne ne sait comment il était installé.

Prenez votre temps : le but est de **lire ce que Terraform annonce**, pas d'aller vite.

## Partie 1 : créer Hopla

### 1. Lire le code
Ouvrez `labs/02-iac-terraform/main.tf`.

**Question :** combien de réseaux et de conteneurs ce fichier décrit-il ?

### 2. Préparer les outils
```bash
cd labs/02-iac-terraform
terraform init
```
**Vous devez voir :** `Terraform has been successfully initialized!`

### 3. Lire le devis
```bash
terraform plan
```
**Vous devez voir :** `Plan: 10 to add, 0 to change, 0 to destroy.` Rien n'a encore été créé.

### 4. Lancer le chantier
```bash
terraform apply
```
Relisez le plan, puis tapez `yes`.

**Vous devez voir :** `Apply complete! Resources: 10 added`.

### 5. Regarder le résultat
```bash
docker ps
curl -i localhost:8080
```
**Vous devez voir :** 4 conteneurs, puis `502 Bad Gateway`.

Dans ce TP, `hopla-lb` est un nginx en reverse proxy : il reçoit les clients à la place des serveurs web, et il les répartit entre eux.

Ce `502` est normal : les serveurs web existent, mais rien n'y est installé. Ce sera le TP 3.

### 6. Relancer sans rien changer
```bash
terraform apply
```
**Vous devez voir :** `No changes.`

**Question :** que se serait-il passé avec un script lancé deux fois ?

## Partie 2 : modifier Hopla

Ouvrez `labs/02-iac-terraform/terraform.tfvars`. C'est là que se trouvent les réglages.

### 7. Donner plus de mémoire à la base
Remplacez `256` par `512` sur la ligne `db_memory_mb`, enregistrez, puis lancez :
```bash
terraform plan
terraform apply
docker inspect -f '{{.HostConfig.Memory}}' hopla-db
```
**Vous devez voir :** `536870912`, soit 512 Mo.

**Question :** dans le plan, la base est-elle modifiée (`~`) ou détruite puis recréée (`-/+`) ?

### 8. Ajouter un serveur web
Remplacez `2` par `3` sur la ligne `front_count`, enregistrez, puis lancez :
```bash
terraform plan
terraform apply
docker ps
```
**Vous devez voir :** `hopla-front-3` dans la liste.

**Question :** pourquoi le load balancer change-t-il aussi ?

### 9. Revenir à deux serveurs
Remettez `front_count = 2`, enregistrez, puis lancez :
```bash
terraform apply
```
**Vous devez voir :** `hopla-front-3` détruit. Gardez bien 2 serveurs pour la suite.

## Partie 3 : ce que Terraform ne fait pas

### 10. Supprimer la base à la main
```bash
docker rm -f hopla-db
terraform plan
```
**Vous devez voir :** Terraform propose de recréer `hopla-db`.

**Question :** il recréera le conteneur, mais que deviendront les données ?

Remettez la base en place :
```bash
terraform apply
```

### 11. Vérifier l'isolation
```bash
docker exec hopla-lb ping -c 1 hopla-db
```
**Vous devez voir :** `bad address`. Le load balancer n'est pas sur le même réseau que la base.

### 12. Ouvrir le carnet de chantier
```bash
grep -c demo-hopla terraform.tfstate
```
**Vous devez voir :** un nombre supérieur à 0. Le mot de passe est écrit en clair dans ce fichier.

**Question :** pourquoi ne faut-il pas envoyer ce fichier dans Git ?

## Si ça bloque
| Problème | Solution |
|---|---|
| `No configuration files` | Vous n'êtes pas dans le bon dossier : `cd /workspaces/*/labs/02-iac-terraform` |
| `Error: ... Cannot connect to the Docker daemon` | Attendez une minute, puis relancez `bash ../00-verifier.sh` |
| `name is already in use` | Reste d'un essai précédent : `docker rm -f hopla-front-1 hopla-front-2 hopla-lb hopla-db`, puis `terraform apply` |
| Tout est cassé | Repartir de zéro : `terraform destroy`, puis `terraform apply` |
