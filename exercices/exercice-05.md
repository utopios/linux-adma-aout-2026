# Exercice 5 — Interpréter une sortie journalctl et identifier l'origine d'un échec

> Module : 4 — Séquence d'amorçage et gestion de l'activité
> Durée estimée : 30 minutes
> Difficulté : 2 / 5
> Type : Exercice d'application

## Objectifs pédagogiques

À la fin de cet exercice, vous serez capable de :

- Filtrer les journaux par service, par boot et par priorité
- Identifier la cause d'un échec à partir des journaux structurés
- Distinguer les messages noyau des messages applicatifs

## Prérequis

- Avoir suivi la partie "journald" et "systemctl" du module 4
- Environnement : VM Linux avec le service `myapp.service` en échec. Mise en
  place : exécuter `sudo bash ressources/module-04/prepare-exercice-05.sh`
  puis **redémarrer la VM** — sans lire le contenu du script, qui révèle la
  panne à diagnostiquer
- Outils : `journalctl`, `systemctl`, `grep`

## Contexte

Au matin, le formateur signale que sur la VM `srv-lab`, le service `myapp` ne démarre plus depuis hier après-midi. Vous devez localiser la cause exacte sans toucher à la configuration tant que le diagnostic n'est pas établi.

## Énoncé

### Partie 1 — Lecture orientée du journal

1. Donnez l'état actuel du service `myapp` : actif/inactif, code de sortie, dernière tentative.
2. Récupérez les 50 dernières lignes du journal de ce service uniquement.
3. Filtrez les messages de priorité `error` ou supérieure pour ce service depuis le boot courant.
4. Affichez les journaux du service depuis le boot précédent (`-b -1`). Comparez avec le boot courant.

Résultat attendu : commandes utilisées et extraits significatifs annotés (4-6 lignes max par extrait).

```bash
systemctl status myapp.service --no-pager
journalctl -u myapp.service -n 50 --no-pager
journalctl -u myapp.service -p err -b 0 --no-pager
journalctl -u myapp.service -b -1 --no-pager | tail -20
journalctl --list-boots
```

### Partie 2 — Diagnostic et cause racine

1. À partir des extraits, formulez une hypothèse sur la cause de l'échec (en une phrase).
2. Identifiez précisément :
   - le moment exact du premier échec
   - le code de retour rapporté par systemd
   - la ligne exacte dans le journal qui pointe vers la cause racine
3. Comment vérifieriez-vous l'hypothèse sans modifier le service ? Listez les commandes ou inspections que vous feriez.

Résultat attendu : une fiche de diagnostic en quatre champs : symptôme, première occurrence, cause probable, vérification proposée.


