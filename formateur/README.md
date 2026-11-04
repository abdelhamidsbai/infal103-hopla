# Notes du formateur

Ce dossier n'est pas destiné aux étudiants. Il contient le corrigé du pare-feu et le script qui rejoue tous les TP.

Si le dépôt est public, les étudiants peuvent lire `fw-dmz.nft`. Pour éviter cela, retirez ce fichier du dépôt et gardez-le de votre côté.

## La veille du cours

1. Poussez le dépôt sur GitHub.
2. Ouvrez l'onglet **Actions**. Le workflow « Vérifier les TP » se lance à chaque push. Il rejoue tous les TP avec les vrais outils, et s'arrête au bout de 30 minutes au plus.
3. Cherchez la dernière ligne du journal : `RÉSULTAT : ... OK, 0 échec(s)`.
4. Si une ligne commence par `ECHEC`, ouvrez un Codespace et refaites cette étape à la main avec le fichier du TP.
5. Ouvrez un Codespace vous-même, et faites au moins le TP 1 et le TP 2 en entier. Vous saurez ce que les étudiants voient.

Pour lancer le même contrôle dans un Codespace :

```bash
bash formateur/verifier.sh 2>&1 | tee verification.log
```

Pour revoir les résultats réels de toutes les commandes :

```bash
bash formateur/captures.sh 2>&1 | tee captures.log
```

Les réponses aux questions des TP ne sont pas dans ce dépôt, car il est public.

## Le jour du cours

- Les Codespaces mettent environ 5 minutes à s'installer. Faites-les ouvrir dès la diapo 7.
- Un compte GitHub gratuit donne assez d'heures de Codespace pour les deux jours. Demandez aux étudiants d'arrêter leur Codespace le soir.
- Si un étudiant reste bloqué plus de 5 minutes, mettez-le en binôme.
- Le TP 2 et le TP 3 partagent la même infrastructure : personne ne fait `terraform destroy` avant la finale.

## Le corrigé du pare-feu

Les deux règles à compléter dans `labs/01-reseau/firewall/regles.nft` sont :

```
iifname "eth1" accept
iifname "eth3" oifname "eth2" tcp dport 80 accept
```

Le fichier complet est `fw-dmz.nft`. Pour le charger :

```bash
docker exec -i clab-hopla-fw nft -f - < formateur/fw-dmz.nft
```
