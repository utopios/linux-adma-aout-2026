#!/usr/bin/env bash
# ============================================================================
# Préparation EXERCICE 5 — service myapp en échec (module 4)
# ----------------------------------------------------------------------------
# ATTENTION STAGIAIRES : exécutez ce script SANS LE LIRE — son contenu
# révèle la panne que l'exercice vous demande de diagnostiquer.
# ----------------------------------------------------------------------------
# Ce script met en place le scénario de l'énoncé :
#   - un service `myapp.service` qui FONCTIONNE au boot courant
#   - au PROCHAIN redémarrage, le service se met à échouer
# Après reboot, le journal contient donc : boot -1 = succès, boot 0 = échecs.
# C'est exactement ce que les questions 1 à 4 de l'exercice exploitent.
#
# Usage (sur la VM de l'exercice, la veille ou juste avant la pause) :
#   sudo bash prepare-exercice-05.sh            # phase 1 : installe, puis REBOOTEZ
#   sudo bash prepare-exercice-05.sh status     # où en est le scénario ?
#   sudo bash prepare-exercice-05.sh remove     # tout retirer (après l'exercice)
# ============================================================================

set -uo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être lancé avec sudo." >&2
    exit 1
fi

BIN=/usr/local/bin/myapp.sh
UNIT=/etc/systemd/system/myapp.service
BREAKER=/etc/systemd/system/myapp-breaker.service

case "${1:-install}" in

install)
    # --- 0. journal persistant : indispensable pour que le boot précédent
    #        soit encore lisible après le reboot (journalctl -b -1)
    mkdir -p /var/log/journal
    systemd-tmpfiles --create --prefix /var/log/journal >/dev/null 2>&1
    systemctl restart systemd-journald

    # --- 1. le binaire : une application qui vit et journalise
    cat > "$BIN" <<'EOF'
#!/usr/bin/env bash
echo "myapp démarré (pid $$)"
while true; do
    echo "traitement du lot $(date +%H:%M:%S) : 42 enregistrements OK"
    sleep 30
done
EOF
    chmod +x "$BIN"

    # --- 2. l'unité : volontairement identique à celle du cours (module 4)
    cat > "$UNIT" <<'EOF'
[Unit]
Description=Application metier myapp (lab LUX-ADMA)
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/myapp.sh
Restart=on-failure
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF

    # --- 3. le "casseur" : au prochain boot, AVANT myapp, il fait
    #        disparaître le binaire puis s'efface. myapp échouera alors
    #        en 203/EXEC à chaque tentative, jusqu'au start-limit.
    cat > "$BREAKER" <<EOF
[Unit]
Description=Preparation exercice 5 (usage unique)
Before=myapp.service
DefaultDependencies=no
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'mv $BIN $BIN.disabled; systemctl disable myapp-breaker.service; rm -f $BREAKER'

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now myapp.service >/dev/null 2>&1
    systemctl enable myapp-breaker.service >/dev/null 2>&1

    sleep 2
    if systemctl is-active --quiet myapp.service; then
        echo "Phase 1 OK : myapp.service est ACTIF et journalise."
        echo ""
        echo "  Dernière étape : REDÉMARRER la machine (sudo reboot)."
        echo "  Après le reboot, le scénario de l'exercice est en place."
    else
        echo "ERREUR : myapp.service n'a pas démarré — vérifier systemctl status myapp" >&2
        exit 1
    fi
    ;;

status)
    echo "--- myapp.service : $(systemctl is-active myapp.service 2>/dev/null ; systemctl is-failed myapp.service >/dev/null 2>&1 && echo '(failed)')"
    if [ -f "$BREAKER" ]; then
        echo "--- casseur : ARMÉ (le scénario se déclenchera au prochain reboot)"
    elif [ -f "$BIN.disabled" ]; then
        echo "--- casseur : DÉCLENCHÉ — scénario en place, l'exercice peut commencer"
    else
        echo "--- casseur : absent (scénario non préparé ou retiré)"
    fi
    ;;

remove)
    systemctl disable --now myapp.service >/dev/null 2>&1
    systemctl disable --now myapp-breaker.service >/dev/null 2>&1
    systemctl reset-failed myapp.service >/dev/null 2>&1
    rm -f "$BIN" "$BIN.disabled" "$UNIT" "$BREAKER"
    systemctl daemon-reload
    echo "Scénario retiré : plus aucune trace de myapp."
    ;;

*)
    echo "Usage : sudo bash $0 [install|status|remove]" >&2
    exit 1
    ;;
esac
