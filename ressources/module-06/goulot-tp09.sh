#!/usr/bin/env bash
# ============================================================
# TP 9 — Mise en place / retrait du goulot d'etranglement
# ------------------------------------------------------------
# Document FORMATEUR. A executer sur la VM stagiaire AVANT
# l'etape 6 du TP 9, sans que les stagiaires voient le scenario
# choisi : c'est a eux de l'identifier par la mesure.
#
#   sudo bash goulot-tp09.sh cpu       # bride le CPU a 25 %
#   sudo bash goulot-tp09.sh disque    # sature les I/O en continu
#   sudo bash goulot-tp09.sh memoire   # force la pression memoire
#   sudo bash goulot-tp09.sh stop      # retire TOUT goulot
#   sudo bash goulot-tp09.sh status    # etat courant
#
# Chaque scenario est reversible par `stop`. Rien n'est ecrit de
# facon persistante : un reboot suffit aussi a tout remettre.
# ============================================================
set -uo pipefail

SLICE=luxadma-goulot
UNIT_CPU=luxadma-cpu.service
UNIT_DISK=luxadma-disk.service
UNIT_MEM=luxadma-mem.service
WORKDIR=/var/tmp/luxadma-tp09

need_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Ce script doit etre lance avec sudo." >&2
        exit 1
    fi
}

need_stress() {
    if ! command -v stress-ng >/dev/null 2>&1; then
        echo "stress-ng absent, installation..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq stress-ng >/dev/null 2>&1 \
            || { echo "Echec de l'installation de stress-ng." >&2; exit 1; }
    fi
}

case "${1:-}" in

  cpu)
    need_root; need_stress
    # CPUQuota bride le slice : la charge tourne mais ne peut pas
    # depasser 25 % d'un coeur. Symptome attendu cote stagiaire :
    # %us eleve, load qui monte, MAIS %wa proche de zero.
    systemd-run --unit="$UNIT_CPU" \
        --slice="$SLICE" \
        -p CPUQuota=25% \
        -p Restart=always \
        stress-ng --cpu 4 --timeout 0 >/dev/null
    echo "Goulot CPU actif : slice $SLICE bride a 25 % (unite $UNIT_CPU)."
    echo "Indice attendu : %us eleve, %wa ~0, load > nproc."
    ;;

  disque)
    need_root; need_stress
    mkdir -p "$WORKDIR"
    # Ecritures aleatoires continues avec fsync : sature la file
    # d'attente du device. Symptome : %wa eleve, %util ~100,
    # await qui explose, colonne b de vmstat non nulle.
    systemd-run --unit="$UNIT_DISK" \
        --slice="$SLICE" \
        -p Restart=always \
        stress-ng --hdd 2 --hdd-bytes 512M --fsync 1 \
                  --temp-path "$WORKDIR" --timeout 0 >/dev/null
    echo "Goulot DISQUE actif (unite $UNIT_DISK, travail dans $WORKDIR)."
    echo "Indice attendu : %wa eleve, %util ~100 %, await x10, vmstat b > 0."
    ;;

  memoire)
    need_root; need_stress
    # Occupe la memoire et force le recours au swap.
    TOTAL_MB=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo)
    VM_BYTES=$(( TOTAL_MB * 80 / 100 ))
    systemd-run --unit="$UNIT_MEM" \
        --slice="$SLICE" \
        -p Restart=always \
        stress-ng --vm 2 --vm-bytes "${VM_BYTES}M" --vm-method flip \
                  --timeout 0 >/dev/null
    echo "Goulot MEMOIRE actif : ~${VM_BYTES} Mo occupes (unite $UNIT_MEM)."
    echo "Indice attendu : available qui s'effondre, si/so non nuls dans vmstat."
    ;;

  stop)
    need_root
    for u in "$UNIT_CPU" "$UNIT_DISK" "$UNIT_MEM"; do
        systemctl stop "$u" 2>/dev/null
        systemctl reset-failed "$u" 2>/dev/null
    done
    systemctl stop "${SLICE}.slice" 2>/dev/null
    rm -rf "$WORKDIR"
    echo "Tous les goulots ont ete retires."
    ;;

  status)
    echo "--- unites de goulot ---"
    for u in "$UNIT_CPU" "$UNIT_DISK" "$UNIT_MEM"; do
        printf "%-24s %s\n" "$u" "$(systemctl is-active "$u" 2>/dev/null)"
    done
    echo "--- charge actuelle ---"
    uptime
    ;;

  *)
    sed -n '2,20p' "$0"
    exit 1
    ;;
esac
