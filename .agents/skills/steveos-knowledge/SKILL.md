---
name: steveos-knowledge
description: >-
  Base de connaissances, retours d'expérience (REX), bonnes pratiques et pièges critiques
  à éviter sur l'écosystème STEvE_OS (steveos-nas, steveos-nas-dashboard, steve_nas_eggs).
  Activer ce skill pour toute tâche d'architecture, de débogage, de build, de mise à jour,
  de conteneurisation Docker/Eggs ou d'intégration NixOS.
---

# 🧠 Base de Connaissances & Retours d'Expérience (REX) — Écosystème STEvE_OS

Ce guide regroupe les apprentissages essentiels, l'architecture des dépôts, les bonnes pratiques de développement et la liste des erreurs critiques à ne jamais reproduire sur les projets liés à **STEvE_OS**.

---

## 🏛️ 1. Architecture des Composants STEvE_OS

| Dépôt / Projet | Rôle & Technologies | Emplacement local |
| :--- | :--- | :--- |
| **`steveos-nas`** (`steve_os-nix`) | Configuration déclarative NixOS du NAS (Modules, Flake, services système, virtualisation, réseau, stockage ZFS/Btrfs). | `/home/chomiam/Projects/steveos-nas` |
| **`steveos-nas-dashboard`** | Tableau de bord Web réactif & API haute performance (Backend Rust Axum, Frontend Vanilla JS/CSS Catppuccin Mocha). | `/home/chomiam/Projects/steveos-nas-dashboard` |
| **`steve_nas_eggs`** | Catalogue d'Eggs de serveurs de jeux conteneurisés Docker (Minecraft, Palworld, Valheim, Terraria, CS2, Enshrouded, etc.). | Dépôt GitHub officiel `Chomiam/steve_nas_eggs` |

### Principes d'intégration :
- `steveos-nas` intègre `steveos-nas-dashboard` via une entrée Flake (`flake.nix` / `flake.lock`).
- Les binaires du Dashboard sont construits par **GitHub Actions** et hébergés sur le cache binaire Cachix officiel `steveos` (`https://steveos.cachix.org`).
- Le Dashboard communique en local avec Docker, systemd, ZFS, WireGuard et NixOS via des commandes CLI isolées et des sockets IPC.

---

## ⚠️ 2. Pièges Critiques & Erreurs à Ne Jamais Reproduire (Anti-Patterns)

### A. Réseau & API
1. **Pas de `git ls-remote` synchrone sur de gros dépôts (`nixpkgs`) :**
   - *Erreur passée* : Exécuter `git ls-remote https://github.com/nixos/nixpkgs` lors de chaque vérification de mise à jour.
   - *Impact* : Blocage du thread HTTP serveur pendant 20 à 30 secondes, interface web figée sur `Vérification de l'état du système...` avec des tirets `--`.
   - *Règle* : `nixpkgs` est géré et verrouillé par `flake.lock` dans `steve_os-nix`. Ne jamais sonder `nixpkgs` à distance via `git ls-remote`.
2. **Double comptage des composants internes :**
   - *Erreur passée* : Détecter une mise à jour du Dashboard dans sa télémétrie dédiée ET le compter une seconde fois comme paquet système tiers dans `package_updates_count`.
   - *Règle* : Exclure systématiquement les composants internes suivis (`steveos-nas-dashboard`) du balayage générique des paquets.

### B. Frontend JavaScript & Résilience UI
3. **Préférer `Promise.allSettled` à `Promise.all` pour les rafraîchissements globaux :**
   - *Erreur passée* : Utiliser `Promise.all` dans `refreshAll()`.
   - *Impact* : Si une seule requête échouait (ex: réseau indisponible ou module tiers désactivé), l'ensemble du rafraîchissement du Dashboard était avorté.
   - *Règle* : Toujours utiliser `Promise.allSettled` pour les écrans d'accueil ou de synthèse.
4. **Vérification d'existence des sessions et objets dynamiques :**
   - *Erreur passée* : Accéder directement à `currentUser` ou à `data.containers.length` sans garde.
   - *Règle* :
     ```javascript
     const user = (currentUserSession && currentUserSession.username) || "chomiam";
     const containers = Array.isArray(data.containers) ? data.containers : [];
     ```
5. **Pré-remplissage des compteurs de sous-onglets :**
   - *Erreur passée* : Ne charger les données d'un sous-onglet (ex: `Générations Système ( -- )`) que lors du clic sur l'onglet, laissant `--` affiché par défaut.
   - *Règle* : Fournir les compteurs légers dès la réponse de synthèse globale du backend (`status.system_generations_count`) ou précharger les requêtes en tâche de fond.
6. **Mise en page des tableaux denses et badges d'origine :**
   - *Erreur passée* : Badges sans `white-space: nowrap` qui se coupent verticalement dans les cellules étroites (ex: `🔒 Système` sur une ligne et `[NixOS]` en dessous) et mélange désordonné des démons système et des règles personnalisées de l'utilisateur.
   - *Règle* :
     - Toujours verrouiller les badges compacts avec `white-space: nowrap; display: inline-flex; align-items: center; gap: 5px;`.
     - Dans les tableaux où cohabitent des dizaines d'entrées système immuables et des règles utilisateur, structurer l'affichage en groupes distincts avec accordéon réductible (`localStorage`) pour les éléments système.
7. **Cycle de vie et multi-états des conteneurs applicatifs / Serveurs de jeu :**
   - *Erreur passée* : Détection binaire simplifiée (`Running == true -> online`, sinon `offline`), masquant les crashs applicatifs et les phases critiques de boot.
   - *Règle* :
     - Différencier l'arrêt volontaire (`ExitCode == 0` -> `stopped`) du crash/erreur (`ExitCode != 0`, `OOMKilled`, ou `dead` -> `error`).
     - Détecter la phase de démarrage (`starting`) : transition via actions utilisateur (start/restart), probe TCP non bloquant sur le port de jeu, et délai de warm-up de boot.
     - Adapter les boutons d'actions selon l'état réel (bouton "Voir Crash Log" sur erreur, "Console Boot" pendant le démarrage).
8. **Performance de rendu & Pattern SWR (Stale-While-Revalidate) :**
   - *Erreur passée* : Attendre la réponse réseau d'une API lourde (ex: `list_game_servers` qui interroge Docker) avant de rendre l'UI, laissant l'utilisateur devant un écran vide pendant 2 à 3 secondes.
   - *Règle* :
     - Hydrater immédiatement l'UI (0ms) depuis `localStorage` au chargement de l'onglet ou de la page.
     - Déclencher la requête API en arrière-plan et rafraîchir le DOM de manière transparente à l'arrivée des données fraîches.
     - Côté Backend Rust : grouper les inspections Docker en une seule commande batch (`docker inspect c1 c2 ...`), court-circuiter dès le début si la liste est vide, et mettre en cache mémoire (TTL) les catalogues ou fichiers statiques souvent relus sur disque.
9. **Feedback visuel & progression des actions asynchrones (Boutons d'inspection / mise à jour) :**
   - *Erreur passée* : Boutons d'action réseau (ex: "Vérifier maintenant") plats et statiques qui se contentent d'un texte figé "Recherche...", ne donnant aucun sentiment de travail actif ni de progression.
   - *Règle* :
     - Intégrer un balayage lumineux shimmer et une icône rotative fluide (`@keyframes spinIconSmooth`).
     - Intégrer une jauge de progression micro-fine sur la bordure du bouton (incréments d'étapes : 30% -> 65% -> 85% -> 100%).
     - Afficher des libellés contextuels séquentiels ("Interrogation GitHub...", "Analyse des paquets...", "Finalisation...").
     - Offrir un état de succès transitoire bien visible (bordure verte, checkmark "✨ Système synchronisé !") avec impulsion lumineuse sur l'horodatage.

### C. Gestion des Médias & Authentification
6. **Streaming média (Lecteurs Audio, Vidéo, Visionneuse) :**
   - *Erreur passée* : Les balises natives `<audio>`, `<video>` et `<img>` n'envoient pas les en-têtes HTTP `Authorization: Bearer ...`.
   - *Règle* :
     - Supporter l'authentification par paramètre d'URL `?token=...` et la synchronisation de cookie de session `steveos_token`.
     - Désactiver le `Cache-Control: no-store` pour les flux multimédias avec en-têtes `Accept-Ranges: bytes` afin de permettre le scrubbing (sauts de lecture dans la vidéo/audio).

### D. Déploiement & Sécurité NixOS
7. **Pas de compilation lourde locale (Règle n°1 d'AGENTS.md) :**
   - La machine de dev et le NAS ne doivent jamais compiler Rust en local. Toujours attendre la fin du build Cachix sur GitHub Actions avant de bumper `flake.lock`.
8. **Déploiement réservé à l'utilisateur (Règle n°5 d'AGENTS.md) :**
   - L'agent ne doit jamais exécuter `nixos-rebuild switch` ou `git pull` directement sur le NAS distant via SSH. C'est l'utilisateur qui déclenche la mise à jour depuis le Dashboard.
9. **Paquets déclaratifs optionnels codés en dur dans des listes statiques :**
   - *Erreur passée* : Déclarer une option `cfg.services.<pkg>.enable` (ex: `goverlay`), mais laisser `<pkg>` en dur dans une liste statique `users.users.<user>.packages` ou `environment.systemPackages` d'un module connexe (ex: `modules/gaming/default.nix`). Résultat : même si l'utilisateur désactive l'option via `vars.nix` (`goverlay = false`), le paquet et toutes ses dépendances lourdes ou cassées (ex: `lazarus-qt6`) continuent d'être injectés dans la dérivation et compilés lors d'un `nh os switch` ou `nixos-rebuild`.
   - *Règle* : Tout paquet associé à une option configurable doit être conditionné systématiquement avec `lib.optional cfg.<option>.enable <paquet>` dans TOUS les modules sans exception.

---

## 🛠️ 3. Patterns Recommandés & Recettes Éprouvées

### Comptage ultra-rapide des générations NixOS (0ms) :
Pour connaître instantanément le nombre de générations système sans lancer de commande lourde `nixos-rebuild list-generations` :
```rust
pub fn get_system_generations_count() -> u32 {
    if let Ok(entries) = fs::read_dir("/nix/var/nix/profiles") {
        entries.flatten().filter(|e| {
            let fname = e.file_name().to_string_lossy().to_string();
            fname.starts_with("system-") && fname.ends_with("-link")
        }).count() as u32
    } else {
        0
    }
}
```

### Intégration des Eggs & Bannières de Jeux :
- Toujours associer les serveurs de jeux à leur Egg d'origine via `egg_id`.
- Réutiliser dynamiquement `banner_url` (dégradé panoramique) et `icon_url` (logo PNG transparent avec ombre portée) :
  ```javascript
  const bannerStyle = bannerUrl
    ? `background: linear-gradient(180deg, rgba(17, 17, 27, 0.40) 0%, rgba(17, 17, 27, 0.92) 100%), url('${bannerUrl}') center/cover no-repeat;`
    : ``;
  ```
- Toujours prévoir un fallback sécurisé vers l'emoji natif si l'image distante échoue à charger (`onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';"`).

---

## 🔄 4. Protocole d'Actualisation Continue de ce Fichier

À chaque fois qu'un bogue est résolu, qu'un écueil est identifié ou qu'une nouvelle architecture est introduite :
1. Ajouter l'anomalie et la solution dans la section **2. Pièges Critiques**.
2. Documenter la recette validée dans la section **3. Patterns Recommandés**.
3. Conserver un historique clair pour éviter toute régression sur les versions futures.
