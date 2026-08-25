# Exercice 3 — Ajuster des paramètres noyau via sysctl de manière persistante

> Module : 2 — Modules de noyau, /proc, /sys et dépannage matériel
> Durée estimée : 25 minutes
> Difficulté : 2 / 5
> Type : Exercice d'application

## Objectifs pédagogiques

À la fin de cet exercice, vous serez capable de :

- Lire et modifier un paramètre du noyau au runtime
- Rendre un paramètre persistant à travers les redémarrages
- Vérifier qu'un paramètre est bien appliqué après reboot

## Prérequis

- Avoir suivi la partie "sysctl" du module 2
- Environnement : VM Linux avec accès sudo et possibilité de redémarrer
- Outils : `sysctl`, `cat`, `tee`, éditeur de fichiers

## Contexte

L'équipe réseau vous demande d'activer le routage IPv4 sur un serveur Linux pour qu'il joue le rôle de passerelle entre deux sous-réseaux. Vous devez aussi durcir un paramètre lié aux redirections ICMP et conserver le tout après reboot.

## Énoncé

### Partie 1 — Modification au runtime

1. Relevez la valeur courante de `net.ipv4.ip_forward` et de `net.ipv4.conf.all.accept_redirects`.
2. Activez le routage IPv4 et désactivez l'acceptation des redirections ICMP, sans toucher aux fichiers de configuration. Vérifiez que les deux valeurs sont bien à jour.
3. Listez tous les paramètres du noyau dont le nom contient `ip_forward`. Que signifie chaque paramètre ?

Résultat attendu : commandes utilisées et trace des valeurs avant/après.

```bash
sysctl net.ipv4.ip_forward
sysctl net.ipv4.conf.all.accept_redirects
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.all.accept_redirects=0

sysctl -a | grep ip_forward
```


### Partie 2 — Persistance et vérification

1. Créez un fichier dédié dans `/etc/sysctl.d/` pour rendre les deux modifications persistantes. Le fichier doit avoir un nom explicite et un commentaire d'en-tête indiquant la raison du changement et la date.
2. Rechargez la configuration sans redémarrer.
3. Redémarrez la VM puis vérifiez que les valeurs sont bien restées.
4. Imaginez qu'un autre administrateur ait laissé un fichier `99-zzz.conf` qui repasse `ip_forward` à 0. Expliquez (sans coder) comment vous repèreriez le conflit et quel ordre d'application sysctl utilise.

```bash
sudo tee /etc/sysctl.d/90-routing.conf > /dev/null <<'EOF'
# 2026-05-07 — Activation routage IPv4 et durcissement ICMP
# Demande : équipe réseau, ticket SR-1234
net.ipv4.ip_forward = 1
net.ipv4.conf.all.accept_redirects = 0
EOF

sudo sysctl --system | grep -E "ip_forward|accept_redirects"

sudo reboot

sysctl net.ipv4.ip_forward net.ipv4.conf.all.accept_redirects

grep -r ip_forward /etc/sysctl.d/ /usr/lib/sysctl.d/ /run/sysctl.d/
```