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
- Les compilations binaires lourdes sont obligatoirement déléguées aux workflows distants via **GitHub Actions**.

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

## 🏷️ Règle n°6 : Traçabilité des Anomalies & Réservation des GitHub Issues aux Bugs
- **Déclenchement réservé exclusivement aux anomalies et dysfonctionnements (Bug Tracking)** :
  - **Ne PAS créer d'Issue pour les nouvelles fonctionnalités, améliorations UI ou ajouts standards** : un commit conventionnel clair (`feat(scope): ...`) suffit amplement.
  - **Création obligatoire préalable d'une GitHub Issue uniquement lorsqu'un problème ou bug est identifié** (que l'anomalie provienne de la configuration déclarative NixOS `steveos-nas` ou du moteur/UI `steveos-nas-dashboard`) :
    1. **Format du titre de l'Issue** : `[BUG-YYYYMMDD-XX]: Résumé synthétique de l'anomalie` (ex: `[BUG-20260930-01]`).
    2. **Corps de l'Issue** :
       - **Symptôme & Contexte** : Message d'erreur exact, comportement inattendu, logs système ou capture d'écran.
       - **Composant(s) impacté(s)** : Configuration NixOS (`steve_os-nix`) et/ou Dashboard Web (`steveos-nas-dashboard`).
       - **Cause racine (RCA)** : Origine technique précise de la défaillance après investigation.
       - **Stratégie de résolution** : Correctifs appliqués et mesures de repli (fallbacks).
    3. **Traçabilité obligatoire dans les Commits de correction de bugs** :
       - Dans l'entête : `fix(scope)[BUG-YYYYMMDD-XX]: résumé court du correctif (#num_issue)`
       - Dans le corps explicatif : mention claire de l'incident, de la RCA et clôture de l'issue (`Closes #num_issue`).

---

## ⚡ Règle n°7 : Alimentation obligatoire du cache binaire Cachix (steveos) à chaque mise à jour du Dashboard
- **À chaque nouvelle version, correctif ou mise à jour du Dashboard Web (`steveos-nas-dashboard`) :**
  1. **Publication distante et build Cachix** :
     - Pousser systématiquement les commits et tags sur GitHub (`main` et tags) pour que le workflow GitHub Actions compile le binaire du Dashboard et le pousse dans le cache binaire Cachix officiel `steveos` (`https://steveos.cachix.org`).
     - Vérifier impérativement la bonne complétion du workflow distant (`gh run list --repo Chomiam/steveos-nas-dashboard`) avant de déclarer la mise à jour prête.
  2. **Propagation du hash dans `steveos-nas`** :
     - Mettre à jour l'input `steveos-nas-dashboard` dans `flake.lock` (`nix flake lock --update-input steveos-nas-dashboard`).
     - Valider l'évaluation déclarative (`nix eval .#nixosConfigurations.steveos-nas.config.system.build.toplevel.drvPath`).
     - Committer et pousser la mise à jour de `flake.lock` sur `origin/main`.
  3. **Objectif fondamental** :
     - Garantir que le NAS de l'utilisateur télécharge instantanément le binaire précompilé depuis Cachix au lieu de compiler Rust localement sur son processeur lors du clic de mise à jour sur le Dashboard Web.

---

## 💡 Règle n°8 : Explication Pédagogique Systématique lors de la Résolution d'un Bug
- **À chaque résolution de bug, dysfonctionnement ou anomalie, prendre impérativement le temps d'expliquer à l'utilisateur :**
  1. **Le Problème constaté** : description concrète du comportement défaillant, messages d'erreurs et contexte déclencheur.
  2. **La Cause racine (RCA)** : explication technique détaillée de la faille (pourquoi le code, le service ou la configuration a dysfonctionné).
  3. **Le Correctif appliqué** : modifications précises apportées, rôle des changements et justification de la solution pérenne adoptée.

---

## 🔄 Règle n°9 : Actualisation Continue de la Base de Connaissances (`steveos-knowledge`)
- **À chaque bogue corrigé, retour d'expérience (REX) ou amélioration architecturale sur les projets de l'écosystème STEvE_OS :**
  - Mettre à jour systématiquement le skill [`steveos-knowledge`](file:///home/chomiam/Projects/steveos-nas/.agents/skills/steveos-knowledge/SKILL.md) (et sa copie globale).
  - Y consigner :
    - Les pièges techniques rencontrés et les erreurs à ne plus reproduire (anti-patterns).
    - Les recettes et patterns validés.
  - Objectif : capitaliser les acquis au fil des itérations pour éviter toute récidive.



