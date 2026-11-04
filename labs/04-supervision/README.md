# TP 4 : savoir avant les clients

**Durée : 30 min. Incident :** le site est tombé cette nuit, et Hopla l'a appris par un client.

Ce TP se fait en binôme. Gardez le site du TP 3 allumé.

### 1. Démarrer la supervision
```bash
cd labs/04-supervision
terraform init
terraform apply -auto-approve
```
**Vous devez voir :** `Apply complete! Resources: 2 added`.

### 2. Ouvrir l'interface
Dans VS Code, ouvrez l'onglet **Ports**, puis ouvrez la ligne `3001` dans le navigateur. Attendez 20 secondes si la page ne répond pas.

Créez un compte local. Il reste dans votre Codespace : inventez un mot de passe de test.

### 3. Ajouter trois sondes
Cliquez sur **Ajouter**, gardez le type **HTTP(s)**, et répétez pour chacune de ces adresses :

- `http://hopla-lb`
- `http://hopla-front-1`
- `http://hopla-front-2`

**Vous devez voir :** trois sondes vertes, au bout d'une minute.

### 4. Provoquer une panne en binôme
L'un de vous tourne le dos. L'autre choisit un serveur et l'arrête :
```bash
docker stop hopla-front-1
```
Votre binôme se retourne et cherche la panne, uniquement dans l'interface.

**Vous devez voir :** la sonde du serveur passe au rouge, alors que `hopla-lb` reste vert.

**Question :** le client voit-il cette panne ? Faut-il réveiller quelqu'un ?

### 5. Tout casser
```bash
docker stop hopla-front-2
```
**Vous devez voir :** cette fois, `hopla-lb` passe au rouge aussi.

**Question :** quelle différence avec la panne précédente ?

### 6. Remettre le site en route
```bash
docker start hopla-front-1 hopla-front-2
cd ../03-ansible
ansible-playbook playbook.yml
```
**Vous devez voir :** les trois sondes redevenir vertes au bout d'une minute.

## Si ça bloque
| Problème | Solution |
|---|---|
| `network hopla-front not found` | Le TP 2 n'est plus en place : relancez `terraform apply` dans `labs/02-iac-terraform` |
| La ligne `3001` n'apparaît pas | Ajoutez le port à la main dans l'onglet **Ports** |
| Une sonde reste rouge | Vérifiez l'adresse : elle doit commencer par `http://`, sans numéro de port |
