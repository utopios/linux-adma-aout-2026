# Exercice 1 — Cartographier les composants d'un système Linux

> Module : 1 — Architecture système Linux et compilation du noyau
> Durée estimée : 30 minutes
> Difficulté : 2 / 5
> Type : Exercice d'application

## Objectifs pédagogiques

À la fin de cet exercice, vous serez capable de :

- Identifier la version du noyau, son origine et ses composants principaux
- Distinguer ce qui est compilé dans le noyau de ce qui est en module
- Lire la dépendance d'un binaire envers les bibliothèques partagées

## Prérequis

- Avoir suivi la partie "Vue d'ensemble" et "Composants du système" du module 1
- Environnement : machine virtuelle Linux (Debian 12, Ubuntu 22.04+ ou Rocky 9) avec accès sudo
- Outils : `uname`, `lsmod`, `modinfo`, `ldd`, `file`, `cat`, `lscpu`

## Contexte

Vous arrivez sur un serveur Linux dont vous ne connaissez rien. Avant toute intervention, il faut savoir précisément quel noyau tourne, quels modules sont chargés, et de quoi dépendent les services principaux.

## Énoncé

### Partie 1 — Identité du système

À partir d'un terminal sur la VM :

1. Relevez la version exacte du noyau, son architecture et la date de compilation.
   
```bash
uname -a
```

2. Identifiez la distribution et sa version.

```bash
cat /etc/os-release
```

3. Repérez le chemin du binaire `vmlinuz` correspondant au noyau actif et la taille du fichier.

```bash
ls -lh /boot/vmlinuz-$(uname -r)
```

4. Listez le nombre total de modules chargés et donnez le nom de cinq modules de votre choix.

```bash
   lsmod | wc -l
   lsmod | head -6
```


Résultat attendu : une fiche d'identité du système en 8 à 10 lignes.

### Partie 2 — Drivers et bibliothèques

1. Pour le module choisi à la question précédente, affichez ses métadonnées (auteur, licence, dépendances, paramètres acceptés).

```bash
   modinfo <module_name>
```

2. Choisissez la commande `/usr/sbin/sshd` (ou `/bin/bash` si sshd n'est pas installé) et listez :
   - les bibliothèques `.so` qu'elle charge dynamiquement
   - le format du binaire (architecture, statique/dynamique, stripped ou non)

```bash
   ldd /usr/sbin/sshd
   file /usr/sbin/sshd
```

3. Pour la bibliothèque `libc.so.6`, donnez son chemin réel sur le système et sa version.

```bash
realpath /lib/aarch64-linux-gnu/libc.so.6 
```


Résultat attendu : sortie commentée de chaque commande et un mini-tableau récapitulatif (binaire, format, bibliothèques principales).

