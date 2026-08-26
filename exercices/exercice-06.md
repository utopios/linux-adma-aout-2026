# Exercice 6 — Rédiger une procédure de recovery pour un serveur en panne

> Module : 5 — Maintenance système et configuration réseau
> Durée estimée : 30 minutes
> Difficulté : 3 / 5
> Type : Exercice d'application

## Objectifs pédagogiques

À la fin de cet exercice, vous serez capable de :

- Décrire la séquence de recovery d'un serveur Linux non bootable
- Identifier les pré-requis matériels et logiciels d'une intervention de secours
- Documenter une procédure exécutable par un autre administrateur

## Prérequis

- Avoir suivi la partie "Gestion d'urgence en cas de crash" du module 5
- Environnement : aucun, l'exercice est documentaire
- Outils : éditeur de texte ou Markdown

## Contexte

Votre équipe veut industrialiser les interventions de recovery. On vous demande d'écrire la procédure générique applicable à tous les serveurs Debian 12 du parc, qu'un junior puisse exécuter avec succès en astreinte à 3h du matin.

## Énoncé

### Partie 1 — Cadre et inventaire

Rédigez la première partie de la procédure :

1. Pré-requis matériels et logiciels (live USB, accès console, identifiants...)
2. Informations à recueillir avant d'intervenir (modèle de serveur, type de boot BIOS/UEFI, présence de LUKS ou LVM, partitionnement type)
3. Critères pour décider d'intervenir vs. escalader (par exemple : RAID matériel dégradé, disque physique HS)

Résultat attendu : section "Pré-requis et cadrage" en 20 à 30 lignes Markdown.

### Partie 2 — Séquence d'intervention

Rédigez la séquence d'actions, étape par étape, pour les deux scénarios suivants :

1. **Scénario A** : "Le serveur boucle au boot, le bootloader est sain mais initramfs ou rootfs est cassé." Couvrir : démarrage live USB, identification des partitions, montage, chroot, action corrective générique.
2. **Scénario B** : "Le serveur ne boote plus du tout, GRUB absent." Couvrir : récupération GRUB depuis le chroot.

Pour chaque étape, donnez la commande exacte et un point de contrôle (ce qu'on doit voir).

Résultat attendu : deux sections Markdown distinctes, lisibles par un junior sans paraphrase orale.

