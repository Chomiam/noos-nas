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
