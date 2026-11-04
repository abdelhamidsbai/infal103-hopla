# INFAL103 : construire l'infrastructure de Hopla Market

Hopla Market vend en ligne. Tout tourne sur un seul PC, sous le bureau du comptable. En deux jours, nous allons construire son infrastructure, un incident à la fois.

## Démarrer (10 minutes, à faire une seule fois)
1. Connectez-vous à GitHub.
2. Cliquez sur **Code > Codespaces > Create codespace on main**.
3. Attendez la fin de l'installation : comptez environ 5 minutes.
4. Ouvrez un terminal, puis lancez :

```bash
bash labs/00-verifier.sh
```

Vous devez lire : `Environnement prêt`.

**Arrêtez votre Codespace chaque soir** pour préserver votre quota gratuit.

Un sigle inconnu ? Regardez le [glossaire](labs/glossaire.md).

## Les TP
Commencez un TP seulement quand le formateur l'annonce. Une diapo jaune « On passe au TP » indique le moment.

| Quand | TP | Durée | Fichier |
|---|---|---|---|
| Jour 1 | TP 1, acte 1 : explorer le réseau | 40 min | [labs/01-reseau](labs/01-reseau/README.md#acte-1--explorer-le-réseau) |
| Jour 1 | TP 1, acte 2 : protéger la compta | 40 min | [labs/01-reseau](labs/01-reseau/README.md#acte-2--protéger-la-compta) |
| Jour 1 | TP 1, acte 3 : le premier jour de Karim | 25 min | [labs/01-reseau](labs/01-reseau/README.md#acte-3--le-premier-jour-de-karim) |
| Jour 2 | TP 2 : recréer Hopla avec Terraform | 70 min | [labs/02-iac-terraform](labs/02-iac-terraform/README.md) |
| Jour 2 | TP 3 : configurer les serveurs avec Ansible | 35 min | [labs/03-ansible](labs/03-ansible/README.md) |
| Jour 2 | TP 4 : savoir avant les clients | 30 min | [labs/04-supervision](labs/04-supervision/README.md) |
| Jour 2 | Finale : tout reconstruire | 15 min | `bash labs/finale.sh` |

Vous avez terminé en avance ? Regardez les [exercices bonus](labs/bonus.md).

## Si ça bloque
1. Relisez le message d'erreur à voix haute avec votre voisin.
2. Le TP donne une solution aux problèmes les plus courants.
3. Votre infrastructure est jetable : chaque TP explique comment repartir de zéro.
4. Appelez le formateur : c'est prévu.

Les conteneurs servent ici à simuler des machines sur tous les ordinateurs. Ce ne sont pas de vraies VM : un conteneur partage le noyau de l'hôte, alors qu'une VM a le sien.
