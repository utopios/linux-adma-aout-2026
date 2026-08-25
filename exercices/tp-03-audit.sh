#!/usr/bin/env bash
# ============================================================================

set -uo pipefail

AUDIT_DIR="$HOME/audit-$(hostname)"
RAW="$AUDIT_DIR/raw"
PAUSE="${PAUSE:-no}"

step() {
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  $1"
    echo "════════════════════════════════════════════════════════════════"
    if [ "$PAUSE" = "yes" ]; then read -rp "  [Entrée pour dérouler]"; fi
}

run() {
    # affiche la commande avant de l'exécuter, puis sa sortie indentée
    echo ""
    echo "  \$ $*"
    echo "  ----------------------------------------------------------------"
    "$@" 2>&1 | sed 's/^/  /'
}

# ============================================================================
# ÉTAPE 1 — Préparer l'arborescence
# ============================================================================

step "ÉTAPE 1 — Arborescence de travail"
mkdir -p "$RAW"
cd "$AUDIT_DIR"
run pwd
run ls -la raw/

# ============================================================================
# ÉTAPE 2 — Inventaire matériel
# ============================================================================

step "ÉTAPE 2 — Inventaire matériel"


run bash -c "lscpu | tee '$RAW/lscpu.txt' > /dev/null && head -8 '$RAW/lscpu.txt'"
head -30 /proc/cpuinfo >> "$RAW/lscpu.txt"


run bash -c "lsmem | tee '$RAW/lsmem.txt' > /dev/null && tail -4 '$RAW/lsmem.txt'"
sudo dmidecode -t memory > "$RAW/dmidecode-mem.txt" 2>&1 || true
free -h | tee -a "$RAW/lsmem.txt" | sed 's/^/  /'


run bash -c "lsblk -f -o NAME,FSTYPE,SIZE,MOUNTPOINT,LABEL,UUID | tee '$RAW/lsblk.txt'"
sudo smartctl --scan > "$RAW/smart-scan.txt" 2>&1 || true


sudo lspci -nnk > "$RAW/lspci.txt" 2>&1 || true
run bash -c "head -12 '$RAW/lspci.txt'"
sudo lsusb -t > "$RAW/lsusb.txt" 2>&1 || true


sudo lshw -short > "$RAW/lshw-short.txt" 2>&1 || true
sudo dmidecode -t system -t bios > "$RAW/dmidecode.txt" 2>&1 || true
run bash -c "grep -E 'Manufacturer|Product|Serial|Version' '$RAW/dmidecode.txt' | head -6"

echo ""
echo "  Point de contrôle : fichiers raw/ présents et non vides :"
run bash -c "wc -l '$RAW'/*.txt | sed 's|$RAW/||'"

# ============================================================================
# ÉTAPE 3 — Santé disque et thermique
# ============================================================================

step "ÉTAPE 3 — Santé disque et thermique"

DEV=$(lsblk -dn -o NAME,TYPE | awk '$2=="disk"{print $1; exit}')


sudo smartctl -i "/dev/$DEV" > "$RAW/smart-$DEV.txt" 2>&1 || true
sudo smartctl -H "/dev/$DEV" >> "$RAW/smart-$DEV.txt" 2>&1 || true
run bash -c "tail -5 '$RAW/smart-$DEV.txt'"

SMART_VM_VERDICT="SMART non applicable : disque virtualisé ($DEV), pas de passthrough — ce n'est PAS une panne."


SMART_REF=""
for c in "$(dirname "$0")/../../ressources/module-02/smart-physique.txt" \
         "./smart-physique.txt" "$HOME/smart-physique.txt" \
         "/vagrant/ressources/module-02/smart-physique.txt"; do
    [ -r "$c" ] && SMART_REF="$c" && break
done

if [ -n "$SMART_REF" ]; then
    cp "$SMART_REF" "$RAW/smart-physique.txt"
    echo ""
    echo "  Analyse du SMART physique fourni ($SMART_REF) :"
    run grep -E "overall-health|Reallocated_Sector_Ct|Current_Pending_Sector|Power_On_Hours|Reallocated_Event" "$RAW/smart-physique.txt"
    SMART_PHY_VERDICT="Disque physique de référence : verdict PASSED **mais** 112 secteurs réalloués (progressifs : 106 événements), **8 secteurs en attente** et 54 782 h (~6,3 ans) : planifier le remplacement. Un Current_Pending_Sector non nul est le signal le plus alarmant."
else
    echo "  (smart-physique.txt introuvable : copier ressources/module-02/smart-physique.txt"
    echo "   à côté de ce script ou dans ~ pour jouer l'analyse de référence)"
    SMART_PHY_VERDICT="(sortie SMART de référence non fournie lors de cette exécution)"
fi


run bash -c "ls /sys/class/hwmon/ 2>/dev/null | head -3; echo '(vide = aucun capteur en VM)'"
sensors > "$RAW/sensors.txt" 2>&1 || echo "sensors : aucun capteur détecté (VM)" > "$RAW/sensors.txt"

# ============================================================================
# ÉTAPE 4 — Journaux noyau et incidents
# ============================================================================

step "ÉTAPE 4 — Journaux noyau"

journalctl -p err -k -b 0 --no-pager > "$RAW/dmesg-errors.txt" 2>&1 || true
run bash -c "cat '$RAW/dmesg-errors.txt' | head -8; [ -s '$RAW/dmesg-errors.txt' ] || echo '-- No entries -- (bon signe : rien en err sur ce boot)'"


# NB : ne pas incrementer un compteur DANS un pipeline (| tee) — la boucle
# tournerait en sous-shell et le compteur serait perdu. On ecrit le fichier,
# puis on compte a partir du fichier.
for kw in "Hardware Error" "MCE" "I/O error" "thermal" "ata.*fail" "OOM"; do
    echo "=== $kw ==="
    dmesg -T 2>/dev/null | grep -iE "$kw" || echo "  (rien)"
done > "$RAW/dmesg-keywords.txt"
sed 's/^/  /' "$RAW/dmesg-keywords.txt"
# familles avec occurrences = 6 mots-cles moins les sections "(rien)"
KW_FOUND=$(( 6 - $(grep -c "(rien)" "$RAW/dmesg-keywords.txt") ))


journalctl --list-boots --no-pager > "$RAW/boots.txt" 2>&1 || true
journalctl -p err -k -b -1 --no-pager > "$RAW/dmesg-errors-prev.txt" 2>&1 || true

# ============================================================================
# ÉTAPE 5 — La fiche d'audit
# ============================================================================

step "ÉTAPE 5 — Génération du rapport inventaire.md"

CPU_MODEL=$(lscpu | awk -F': +' '/Model name|Nom de modèle/{print $2; exit}')
# certains hyperviseurs n'exposent pas le modele (lscpu affiche "-") :
# on note l'architecture et on renvoie vers la piece brute
if [ -z "${CPU_MODEL:-}" ] || [ "$CPU_MODEL" = "-" ]; then
    CPU_MODEL="modèle non exposé par l'hyperviseur — arch $(uname -m), voir raw/lscpu.txt"
fi
CPU_N=$(nproc)
MEM_TOT=$(free -h | awk '/^Mem/{print $2}')
OS=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
DISKS=$(lsblk -dn -o NAME,SIZE,TYPE | awk '$3=="disk"{printf "%s (%s) ", $1, $2}')
NICS=$(ip -br link | awk '$1!="lo"{printf "%s ", $1}')
SERIAL=$(sudo dmidecode -s system-serial-number 2>/dev/null | head -1)
PRODUCT=$(sudo dmidecode -s system-product-name 2>/dev/null | head -1)

# "-- No entries --" est un message de journalctl, pas une erreur : on ne
# compte que les lignes de VRAIS messages pour decider de la recommandation
# grep -c imprime "0" ET sort en code 1 quand rien ne matche : surtout pas
# de "|| echo 0" (double zero). On tolere l'echec et on borne a 0 si vide.
ERR_LINES=$(grep -vc "^-- No entries" "$RAW/dmesg-errors.txt" 2>/dev/null || true)
ERR_LINES=${ERR_LINES:-0}

if [ "$KW_FOUND" -eq 0 ] && [ "$ERR_LINES" -eq 0 ]; then
    RECO="**Aucune action requise.** Aucun signal d'incident matériel sur ce boot ; inventaire à archiver comme référence. Prochain audit : dans 6 mois ou au premier symptôme."
else
    RECO="**Surveillance accrue.** Des signaux ont été relevés dans les journaux noyau (voir section Incidents) : corréler avec les créneaux de ralentissement signalés, réauditer sous 7 jours."
fi

cat > "$AUDIT_DIR/inventaire.md" <<EOF
# Audit matériel — $(hostname) — $(date +%F)

## Identité
- Machine : ${PRODUCT:-n/a} — serial ${SERIAL:-n/a}
- OS : $OS — noyau $(uname -r) ($(uname -m))
- Audit du $(date '+%F %H:%M') par $USER — sorties brutes : \`raw/\`

## Composants
- CPU : ${CPU_MODEL:-voir raw/lscpu.txt} — $CPU_N coeurs logiques
- Mémoire : $MEM_TOT (détail firmware : raw/dmidecode-mem.txt)
- Stockage : $DISKS(détail : raw/lsblk.txt)
- Réseau : $NICS(drivers : raw/lspci.txt)
- Cartes PCI : voir raw/lspci.txt

## Santé
- SMART : $SMART_VM_VERDICT
- Référence physique analysée : $SMART_PHY_VERDICT
- Températures : aucun capteur exposé à l'invité (VM) — surveillance à
  faire côté hyperviseur / BMC sur le matériel réel

## Incidents détectés
- \`journalctl -p err -k -b 0\` : $( [ "$ERR_LINES" -gt 0 ] && echo "$ERR_LINES ligne(s) — voir raw/dmesg-errors.txt" || echo "aucune entrée (bon signe)" )
- Mots-clés (Hardware Error, MCE, I/O error, thermal, ata fail, OOM) :
  $KW_FOUND famille(s) avec occurrences — détail : raw/dmesg-keywords.txt

## Recommandation
$RECO
EOF

run bash -c "cat '$AUDIT_DIR/inventaire.md'"

# ============================================================================
# FIN
# ============================================================================

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Audit terminé."
echo "  Livrable : $AUDIT_DIR/inventaire.md"
echo "  Sorties brutes  : $RAW/"
echo "  Pour rejouer    : rm -rf $AUDIT_DIR"
echo "════════════════════════════════════════════════════════════════"
