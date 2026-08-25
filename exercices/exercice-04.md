# Exercice 4 — Interpréter la sortie de pvs / vgs / lvs

> Module : 3 — Stockage avancé : LVM et BTRFS
> Durée estimée : 30 minutes
> Difficulté : 2 / 5
> Type : Exercice d'application

## Objectifs pédagogiques

À la fin de cet exercice, vous serez capable de :

- Lire la sortie des outils LVM et reconstituer la topologie d'un système de stockage
- Identifier les contraintes (espace libre, attributs des volumes)
- Diagnostiquer pourquoi une opération LVM peut échouer

## Prérequis

- Avoir suivi la partie "LVM et Device Mapper" du module 3
- Environnement : VM Linux avec deux disques additionnels (5 Go et 5 Go) et un VG préparé par le formateur
- Outils : `pvs`, `vgs`, `lvs`, `pvdisplay`, `vgdisplay`, `lvdisplay`, `lsblk`

## Contexte

Vous reprenez l'administration d'un serveur dont vous n'avez pas la documentation. Le système utilise LVM. Avant toute action (extension, snapshot, déplacement), il faut comprendre la topologie en place et l'état des volumes.

## Énoncé

### Partie 1 — Lecture de la topologie

À partir des commandes LVM uniquement (sans `cat /etc/lvm/`) :

1. Listez les Physical Volumes : pour chacun, le périphérique sous-jacent, sa taille totale, son espace libre, et le VG auquel il appartient.
2. Listez les Volume Groups : nom, taille totale, espace libre, nombre de PV et de LV, taille d'un PE.
3. Listez les Logical Volumes : nom, VG d'attache, taille, attributs (`lv_attr`), état activé/désactivé.
4. Reconstituez sur papier (ou en ASCII art) la topologie complète : disques → PV → VG → LV → FS si monté.

Résultat attendu : un schéma clair et un tableau récapitulatif.

```bash
sudo pvs -o pv_name,vg_name,pv_size,pv_free,pe_count,pe_alloc_count
sudo vgs -o vg_name,pv_count,lv_count,vg_size,vg_free,vg_extent_size
sudo lvs -o lv_name,vg_name,lv_size,lv_attr,seg_type,devices
```

### Partie 2 — Anticiper les contraintes

1. Pour le LV nommé `lv_app` (préparé par le formateur), peut-on l'étendre de 4 Go ? Justifiez à partir des chiffres relevés.
2. Si la réponse est non, quelles sont les deux options possibles pour libérer ou apporter de la capacité ? Donnez les commandes (sans les exécuter).
3. Le LV `lv_test` a l'attribut `lv_attr` qui commence par `s` (snapshot). À partir de quoi est-il une copie, et que se passe-t-il si la zone CoW est saturée ?

Résultat attendu : un compte rendu argumenté avec les chiffres extraits des sorties LVM.

