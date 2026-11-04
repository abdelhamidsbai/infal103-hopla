# TP 3 : configurer les serveurs avec Ansible

**Durée : 35 min. Incident :** Terraform a créé les machines, mais le site répond `502`. Qui installe nginx ?

Avant de commencer, gardez les conteneurs créés au TP 2 : ils doivent être allumés.

### 1. Regarder la liste des machines
```bash
cd labs/03-ansible
cat inventory.ini
```
**Vous devez voir :** `hopla-front-1` et `hopla-front-2`. Terraform a écrit ce fichier pour Ansible.

### 2. Lire le playbook
Ouvrez `labs/03-ansible/playbook.yml`.

**Question :** à quel endroit dit-on ce qu'on veut obtenir, sans dire comment le faire ?

### 3. Lancer le playbook
```bash
ansible-playbook playbook.yml
```
Comptez une à deux minutes.

**Vous devez voir :** à la fin, `failed=0` pour chaque serveur.

### 4. Ouvrir le site
```bash
for i in 1 2 3 4; do curl -s localhost:8080 | grep Servi; done
```
**Vous devez voir :** `hopla-front-1` et `hopla-front-2` à tour de rôle. Le `502` a disparu.

### 5. Relancer sans rien changer
```bash
ansible-playbook playbook.yml
```
**Vous devez voir :** `changed=0` pour chaque serveur.

### 6. Changer la page
Ouvrez `labs/03-ansible/templates/index.html.j2`, changez le titre, enregistrez, puis lancez :
```bash
ansible-playbook playbook.yml
curl -s localhost:8080
```
**Vous devez voir :** seules les tâches liées à la page changent, et votre nouveau titre s'affiche.

### 7. Casser un serveur
```bash
docker stop hopla-front-1
for i in 1 2 3 4; do curl -s localhost:8080 | grep Servi; done
```
L'arrêt prend une dizaine de secondes : c'est normal.

**Vous devez voir :** le site répond encore, avec `hopla-front-2` uniquement.

**Question :** comment auriez-vous su qu'un serveur était tombé, sans regarder ?

### 8. Remettre le serveur en route
```bash
docker start hopla-front-1
ansible-playbook playbook.yml
```
**Vous devez voir :** `failed=0`. Le playbook a relancé nginx sur `hopla-front-1`.

## Si ça bloque
| Problème | Solution |
|---|---|
| `Could not find or access 'inventory.ini'` | Le TP 2 n'est pas terminé : refaites `terraform apply` dans `labs/02-iac-terraform` |
| `command not found: ansible-playbook` | Fermez le terminal et ouvrez-en un nouveau |
| `Could not resolve` ou erreur sur `apt` | Attendez une minute, puis relancez : le playbook peut être relancé sans danger |
| Le serveur `hopla-front-3` est dans la liste | Remettez `front_count = 2` au TP 2, puis `terraform apply` |
