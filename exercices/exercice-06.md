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


```markdown
# Procédure de recovery — Debian 12 — Datacenter LUX

## Pré-requis matériels et logiciels
- Live USB SystemRescue ou Debian live (clé physique pour datacenter, ISO en console pour cloud)
- Accès console hors-bande : iLO/iDRAC/IPMI (datacenter) ou console hyperviseur (VM)
- Identifiants root du serveur, ou clé MOK si Secure Boot
- Mots de passe LUKS si chiffrement disque
- Sauvegarde récente (vérifiée) du serveur cible
- Bracelet antistatique si intervention sur le matériel

## Informations à recueillir avant l'intervention
- Modèle serveur (Dell, HP, Supermicro)
- Mode de boot : BIOS legacy ou UEFI (`efivars` côté OS)
- Présence de LUKS, LVM, RAID matériel
- Schéma de partition (à conserver dans le runbook)
- Date de dernière modification du serveur (apt history, etckeeper)

## Critères d'escalade
- RAID matériel dégradé (carte LSI/PERC) → équipe hardware
- Disque physique HS détecté SMART FAILED → demande de remplacement
- Erreur ECC mémoire récurrente → remplacement DIMM
- Suspicion de compromission → équipe sécurité, isolation réseau
- Données critiques non sauvegardées → ne pas écrire avant accord équipe métier
```

### Partie 2 — Séquence d'intervention

Rédigez la séquence d'actions, étape par étape, pour les deux scénarios suivants :

1. **Scénario A** : "Le serveur boucle au boot, le bootloader est sain mais initramfs ou rootfs est cassé." Couvrir : démarrage live USB, identification des partitions, montage, chroot, action corrective générique.


```markdown
## Scénario A — Serveur boucle, bootloader sain mais initramfs ou rootfs cassé

### Étape A.1 — Démarrer en live
1. Insérer la clé live ou monter l'ISO en console
2. Modifier l'ordre de boot pour démarrer dessus
3. Choisir "Live" (pas "Install")
   - Point de contrôle : invite shell sur live OK

### Étape A.2 — Identifier les partitions
```bash
sudo lsblk -f
sudo blkid
```
   - Point de contrôle : noter UUID de root, EFI, swap

### Étape A.3 — Préparer le chroot
```bash
sudo mkdir -p /mnt/sys
# si LUKS
sudo cryptsetup open /dev/sdaX root
# si LVM
sudo vgchange -ay
# monter root
sudo mount /dev/mapper/<root> /mnt/sys
# si UEFI
sudo mount /dev/sda1 /mnt/sys/boot/efi
# bind-mounts
for d in dev proc sys run; do sudo mount --bind /$d /mnt/sys/$d; done
```
   - Point de contrôle : `ls /mnt/sys/etc/debian_version` retourne la version

### Étape A.4 — Chroot et action corrective
```bash
sudo chroot /mnt/sys /bin/bash
# action générique : reconstruire initramfs et grub
update-initramfs -u -k all
update-grub
exit
```
   - Point de contrôle : `ls /boot/initrd*` montre des fichiers récents

### Étape A.5 — Sortie propre
```bash
for d in run sys proc dev; do sudo umount /mnt/sys/$d; done
sudo umount /mnt/sys/boot/efi 2>/dev/null
sudo umount /mnt/sys
```
   - Point de contrôle : aucune erreur de démontage

### Étape A.6 — Reboot et test
   - Détacher l'ISO, redémarrer sur disque
   - Point de contrôle : login normal accessible
   

2. **Scénario B** : "Le serveur ne boote plus du tout, GRUB absent." Couvrir : récupération GRUB depuis le chroot.

Pour chaque étape, donnez la commande exacte et un point de contrôle (ce qu'on doit voir).

Résultat attendu : deux sections Markdown distinctes, lisibles par un junior sans paraphrase orale.

## Scénario B — GRUB absent

### Étape B.1 à B.3 : identique au scénario A (chroot)

### Étape B.4 — Réinstaller GRUB
**UEFI** :
```bash
chroot /mnt/sys
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=debian
# sur la VM de demo du formateur (ARM64) : --target=arm64-efi
update-grub
efibootmgr -v
```

**BIOS legacy** :
```bash
chroot /mnt/sys
grub-install /dev/sda
update-grub
```
   - Point de contrôle : `efibootmgr` montre l'entrée debian (UEFI), ou `grub.cfg` est cohérent (BIOS)

### Étape B.5 et B.6 : identique scénario A
```

