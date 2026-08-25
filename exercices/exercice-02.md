# Exercice 2 — Interpréter le contenu de /proc et /sys

> Module : 2 — Modules de noyau, /proc, /sys et dépannage matériel
> Durée estimée : 30 minutes
> Difficulté : 2 / 5
> Type : Exercice d'application

## Objectifs pédagogiques

À la fin de cet exercice, vous serez capable de :

- Naviguer dans /proc et /sys pour récupérer une information précise
- Distinguer une donnée en lecture seule d'un paramètre modifiable
- Lire la documentation associée aux fichiers du pseudo-FS

## Prérequis

- Avoir suivi la partie "/proc et /sys" du module 2
- Environnement : VM Linux fonctionnelle avec accès sudo
- Outils : `cat`, `ls`, `find`, `sysctl`, `grep`, `awk`

## Contexte

Avant d'écrire un script de monitoring ou de configurer le tuning d'un serveur, il faut savoir où le noyau publie ce qu'il sait. /proc et /sys sont les deux étagères principales : encore faut-il y trouver la bonne information.

## Énoncé

### Partie 1 — Lecture dans /proc

Relevez les éléments suivants en utilisant uniquement /proc :

1. Modèle exact et nombre de cœurs logiques du CPU
2. Mémoire totale et mémoire disponible (pas la mémoire libre)
3. Liste des points de montage actuellement actifs
4. Ligne de commande qui a été passée au noyau au démarrage
5. PID du processus `systemd` (PID 1) et la liste de ses descripteurs de fichiers ouverts

```bash
lscpu | grep -E "Architecture|Model name|^CPU\(s\)"
grep -c "^processor" /proc/cpuinfo

grep "^MemTotal" /proc/meminfo
grep "^MemAvailable" /proc/meminfo

cat /proc/mounts | head -10
cat /proc/cmdline

sudo ls -l /proc/1/fd | head
```


Résultat attendu : un compte rendu indiquant pour chaque question le chemin lu et la valeur récupérée.

### Partie 2 — Exploration de /sys

1. Pour la première interface réseau active (autre que `lo`), donnez :
   - son adresse MAC
   - son état (`operstate`)
   - son débit négocié si disponible
   - le pilote utilisé (en suivant `device/driver`)
2. Pour le premier disque physique de la VM (sda, vda, nvme0n1...), donnez :
   - sa taille en blocs (et en Go)
   - le scheduler I/O actif
   - le rotational flag (HDD ou SSD ?)
3. Pour le module `loop` (s'il est chargé), listez ses paramètres exposés sous `/sys/module/`.

Résultat attendu : un tableau avec colonnes "Question / Chemin / Valeur".

```bash
IFACE=$(basename $(ls -d /sys/class/net/*/ | grep -v '/lo/' | head -1))
cat /sys/class/net/$IFACE/address
cat /sys/class/net/$IFACE/operstate
cat /sys/class/net/$IFACE/speed
readlink -f cat /sys/class/net/$IFACE/device/

DEV=$(lsblk -dn -o NAME,TYPE | awk '$2=="disk"{print $1; exit}')
cat /sys/block/$DEV/size
cat /sys/block/$DEV/queue/scheduler
cat /sys/block/$DEV/queue/rotational

ls /sys/module/loop/parameters/
```