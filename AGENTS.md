# 📋 Directives de Développement & Règles d'Architecture — STEvE_OS NAS

> **CONSIGNE IMPÉRATIVE POUR L'AGENT IA ET TOUT DÉVELOPPEUR :**
> À chaque ajout ou modification dans le projet `steveos-nas`, respecter scrupuleusement les règles fondamentales suivantes.

---

## 🚫 Règle n°1 : Pas de build lourd sur la machine locale
- **Ne jamais lancer de compilation complète ou lourde (`nix build`, recompilation d'ISO, cargo build release) sur la machine locale.**
- La machine locale de travail ne doit exécuter que des vérifications syntaxiques et d'évaluation ultra-rapides :
  ```bash
  nix eval .#nixosConfigurations.steveos-nas.config.system.build.toplevel.drvPath
  ```
- Les compilations binaires lourdes et la mise en cache Nix sont obligatoirement déléguées aux workflows distants via **GitHub Actions** et **Cachix** (`chomiamos`).

---

## 🧬 Règle n°2 : Vérification ciblée `nix-ld` pour chaque paquet ajouté
- **Pour chaque paquet système, utilitaire CLI, codec, pilote ou bibliothèque ajouté à la configuration NixOS (`environment.systemPackages` ou dans un module de service/matériel) :**
  > ⚠️ **SE POSER SYSTÉMATIQUEMENT LA QUESTION DE DISCERNEMENT :**  
  > *« Est-ce que je vais vraiment avoir des problèmes si je ne le mets PAS dans `nix-ld` ? »*
  
- **Critères de décision :**
  - **OUI, l'ajouter** : si le paquet fournit des bibliothèques dynamiques (`.so`) indispensables à des binaires tiers non-Nix précompilés, des scripts externes (Python, Node.js natif, VS Code Server), des pilotes GPU ou des middlewares réseau/crypto dont l'absence provoquerait un crash `No such file or directory` ou `error while loading shared libraries`.
  - **NON, ne pas surcharger** : s'il s'agit d'un utilitaire purement autonome, d'un outil CLI sans bibliothèques partagées exportées, ou d'une dépendance strictement interne et hermétique à NixOS.
  - En cas d'ajout justifié, inscrire la bibliothèque dans `programs.nix-ld.libraries` du module [`modules/services/nix-ld.nix`](file:///home/chomiam/Projects/steveos-nas/modules/services/nix-ld.nix).

---

## 🏛️ Règle n°3 : Respect de l'architecture déclarative et de `vars.nix`
- **Séparation claire :**
  - Les modules dans `modules/` définissent les options déclaratives (`steveos.*`).
  - L'utilisateur configure son NAS uniquement via [`vars.nix`](file:///home/chomiam/Projects/steveos-nas/vars.nix).
  - [`vars-defaults.nix`](file:///home/chomiam/Projects/steveos-nas/vars-defaults.nix) doit toujours refléter les valeurs par défaut saines pour chaque nouvelle option.
- **Chemins FHS et Sockets :**
  - Si un outil externe cherche un socket ou un chemin FHS classique (`/var/run/...`, `/bin/...`), déclarer un lien symbolique propre via `systemd.tmpfiles.rules` au lieu de forcer des hacks impurs.

---

## ✍️ Règle n°4 : Commits explicatifs et détaillés en français
- Chaque commit doit comporter un message explicatif structuré en français :
  - **Contexte & Objectif** : Pourquoi la modification a été effectuée.
  - **Impact architectural** : Fichiers et modules Nix modifiés.
  - **Vérification** : Preuve d'évaluation valide sans warning de dépréciation.

---

## 🛑 Règle n°5 : Déploiement des mises à jour réservé exclusivement à l'utilisateur depuis le Dashboard
- **L'agent IA et les scripts de build ne doivent JAMAIS appliquer eux-mêmes les mises à jour directement sur le NAS distant** (interdiction formelle de lancer `nh os switch`, `nixos-rebuild switch` ou `git pull` sur `/etc/nixos` via SSH pour appliquer un changement).
- **Rôle strict de l'agent :**
  1. Développer, corriger et valider la syntaxe / l'évaluation sur la machine locale (`nix eval`).
  2. Mettre à jour `flake.lock` et pousser les commits / tags sur GitHub (`origin/main`).
  3. Informer l'utilisateur que la mise à jour est disponible et prête sur GitHub.
- **C'est EXCLUSIVEMENT l'utilisateur qui déclenche et applique la mise à jour sur son NAS en cliquant sur le bouton unique du Dashboard Web STEvE_OS.**

---

## 🏷️ Règle n°6 : Traçabilité des Anomalies & Identifiant Unique de Résolution (Bug Tracking)
- **Déclenchement systématique dès qu'un problème, dysfonctionnement ou bug est identifié** (que l'anomalie provienne de la configuration déclarative NixOS `steveos-nas` ou du moteur/UI `steveos-nas-dashboard`) :
  1. **Établissement préalable d'un Rapport d'Incident avec Identifiant Unique :**
     - Format standardisé de l'identifiant : `[BUG-YYYYMMDD-XX]` (ex: `[BUG-20260930-01]`).
     - Ce rapport récapitule synthétiquement :
       - **Symptôme & Contexte** : Message d'erreur exact, comportement inattendu, logs système ou capture d'écran.
       - **Composant(s) impacté(s)** : Configuration NixOS (`steve_os-nix`) et/ou Dashboard Web (`steveos-nas-dashboard`).
       - **Cause racine (RCA)** : Origine technique précise de la défaillance.
       - **Stratégie de résolution** : Correctifs appliqués et mesures de repli (fallbacks).
  2. **Traçabilité obligatoire dans tous les Commits associés :**
     - Chaque commit Git lié à la correction — qu'il se trouve dans `steveos-nas` ou dans `steveos-nas-dashboard` — doit **obligatoirement mentionner cet identifiant unique** :
       - Dans l'entête : `fix(scope)[BUG-YYYYMMDD-XX]: résumé court du correctif`
       - Dans le corps explicatif : mention claire de l'incident et lien avec le rapport.
  3. **Objectif architectural :**
     - Garantir une traçabilité totale entre les signalements et le code, faciliter l'audit de l'historique Git et éviter toute ambiguïté lors de la corrélation croisée entre le dépôt NixOS et le Dashboard.


