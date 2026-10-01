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

10. **Persistance bidirectionnelle de l'état d'interface (Routage URL Hash & LocalStorage) :**
    - *Erreur passée* : Sauvegarder l'onglet actif uniquement en `sessionStorage` et conserver une URL statique `/`.
    - *Impact* : Tout rafraîchissement (F5, saisie barre d'adresse, navigation privée) ramenait systématiquement l'utilisateur sur la Vue d'ensemble (`tab-overview`), et la vue d'accueil clignotait brièvement à chaque rechargement avant que l'authentification asynchrone ne s'achève.
    - *Règle* :
      - Toujours synchroniser l'onglet et le sous-onglet actif avec `window.location.hash` (`#storage`, `#files`, `#containers/store`, `#network/samba`, etc.) et avec `localStorage`.
      - Supporter les boutons Précédent/Suivant de l'historique du navigateur via `window.addEventListener("hashchange", ...)`.
      - Appliquer un pré-rendu anti-flicker dès l'analyse DOM (`DOMContentLoaded` et attribut `data-initial-tab` dans l'en-tête HTML) pour masquer instantanément l'accueil et activer le bon onglet avant même l'appel réseau `/api/auth/me`.
      - Sauvegarder et restaurer le dossier courant de l'explorateur de fichiers (`steveos_files_path`) dans `localStorage`.

11. **Superposition et plan d'affichage des notifications Toast (`z-index` & `pointer-events`) :**
    - *Erreur passée* : Définir `#toast-container` avec `z-index: 999` tandis que les fenêtres modales et backdrops ont un `z-index: 2000`.
    - *Impact* : Lorsqu'une action déclenchait une alerte ou un toast depuis une fenêtre modale (ex: confirmation d'ouverture d'un port pare-feu en 1 clic ou notification de déploiement), le toast apparaissait masqué derrière l'overlay sombre de la modale.
    - *Règle* :
      - Élever impérativement `#toast-container` et tous les toasts flottants au premier plan absolu (`z-index: 100050 !important;`).
      - Définir `pointer-events: none;` sur `#toast-container` et `pointer-events: auto;` sur les cartes `.toast` individuelles afin d'éviter qu'une zone invisible vide ne bloque les clics sur l'interface sous-jacente.

### C. Gestion des Médias & Authentification
6. **Streaming média (Lecteurs Audio, Vidéo, Visionneuse) :**
   - *Erreur passée* : Les balises natives `<audio>`, `<video>` et `<img>` n'envoient pas les en-têtes HTTP `Authorization: Bearer ...`.
   - *Règle* :
     - Supporter l'authentification par paramètre d'URL `?token=...` et la synchronisation de cookie de session `steveos_token`.
     - Désactiver le `Cache-Control: no-store` pour les flux multimédias avec en-têtes `Accept-Ranges: bytes` afin de permettre le scrubbing (sauts de lecture dans la vidéo/audio).

12. **Lecteurs Média Flottants (Picture-in-Picture) et Fenêtres Déplaçables :**
    - *Erreur passée* : Appliquer `!important` sur les propriétés CSS `top`, `left`, `right`, `bottom` de la modale en mode vignette (`.mini-player-mode .file-modal-window`), et définir une transition sur `all`.
    - *Impact* : Les styles inline calculés dynamiquement en JavaScript lors du glisser-déposer (`win.style.left = ...`) étaient purement ignorés par le moteur CSS en raison du `!important` de la feuille de style. Le lecteur semblait figé et impossible à déplacer. De plus, `transition: all` entraînait une latence et des saccades lors du suivi du curseur.
    - *Règle* :
      1. Déclarer la position par défaut dans le CSS *sans* `!important` (`top: 122px; right: 24px; left: auto; bottom: auto;`) et injecter les coordonnées en JS avec `win.style.setProperty("left", ..., "important")` et `win.style.setProperty("right", "auto", "important")` lors du drag.
      2. Restreindre la transition CSS aux effets de halo et bordure (`transition: box-shadow 0.25s ease, border-color 0.25s ease !important;`) sans animer les positions `top`/`left`.
      3. Aligner par défaut la position verticale sur le conteneur principal adjacent (`top: 122px` pour coïncider avec `.files-main-pane`) pour une esthétique rigoureuse.
      4. Gérer simultanément les événements souris (`mousedown`, `mousemove`, `mouseup`) et tactiles (`touchstart`, `touchmove`, `touchend`) avec `document.body.style.userSelect = "none"` pendant la translation.

### D. Déploiement & Sécurité NixOS
7. **Pas de compilation lourde locale (Règle n°1 d'AGENTS.md) :**
   - La machine de dev et le NAS ne doivent jamais compiler Rust en local. Toujours attendre la fin du build Cachix sur GitHub Actions avant de bumper `flake.lock`.
8. **Déploiement réservé à l'utilisateur (Règle n°5 d'AGENTS.md) :**
   - L'agent ne doit jamais exécuter `nixos-rebuild switch` ou `git pull` directement sur le NAS distant via SSH. C'est l'utilisateur qui déclenche la mise à jour depuis le Dashboard.
9. **Paquets déclaratifs optionnels codés en dur dans des listes statiques :**
   - *Erreur passée* : Déclarer une option `cfg.services.<pkg>.enable` (ex: `goverlay`), mais laisser `<pkg>` en dur dans une liste statique `users.users.<user>.packages` ou `environment.systemPackages` d'un module connexe (ex: `modules/gaming/default.nix`). Résultat : même si l'utilisateur désactive l'option via `vars.nix` (`goverlay = false`), le paquet et toutes ses dépendances lourdes ou cassées (ex: `lazarus-qt6`) continuent d'être injectés dans la dérivation et compilés lors d'un `nh os switch` ou `nixos-rebuild`.
   - *Règle* : Tout paquet associé à une option configurable doit être conditionné systématiquement avec `lib.optional cfg.<option>.enable <paquet>` dans TOUS les modules sans exception.
10. **Nom d'utilisateur et chemins personnels codés en dur dans une distribution partagée :**
    - *Erreurs passées* :
      1. Hardcoder un utilisateur par défaut (`chomiam`) ou des chemins `/home/chomiam` dans le backend Rust ou les options de service sans transmettre dynamiquement `vars.user.username` au dashboard (`runuser -u chomiam` échoue).
      2. Omettre `homeDirectory` lors de la génération de `vars.nix` par l'installateur web ou coder en dur `homeDirectory = "/home/chomiam"` dans `vars-defaults.nix` / `options.nix`. Résultat : NixOS créait le répertoire `/home/chomiam` pour le compte d'un tiers, et le script d'activation scannant `/home/*` croyait détecter un compte orphelin `chomiam`, le recréant automatiquement dans `/etc/passwd` avec les privilèges `wheel` (admin).
    - *Règle* :
      1. Toujours propager `user = vars.user.username` depuis `hosts/nas/configuration.nix` vers les services applicatifs.
      2. Dans l'installateur web (`install.rs`), toujours injecter explicitement `fullName` et `homeDirectory = "/home/${username}"` dans `vars.nix`.
      3. Dans `options.nix` et `configuration.nix`, dériver dynamiquement `homeDirectory = "/home/${username}"` si non spécifié, sans jamais hardcoder de chemin personnel en fallback.
      4. Dans le script d'activation `steveosUsersSync` (`modules/core/users.nix`), exclure impérativement `[ "$h" != "${u.homeDirectory}" ]` lors du balayage de `/home/*` pour éviter toute création parasite.
11. **Isolation stricte de la page de connexion & Déconnexion atomique (Dashboard) :**
    - *Erreur passée* : Déclarer l'écran de connexion sous forme d'un simple overlay semi-transparent (`backdrop-filter: blur(...)`) au-dessus de la structure complète du dashboard (`<header>`, `<nav>`, `<main>`), tout en masquant le modal par défaut (`style="display:none;"`). Lors de la déconnexion (`logoutUser`), ne faire que supprimer les jetons et réafficher le modal sans vider le DOM, sans couper le polling et sans recharger la page.
    - *Conséquences* : Le dashboard complet, ses graphiques, ses disques et son arborescence restent visibles et chargés en arrière-plan sous le modal de connexion. L'utilisateur a l'impression que la déconnexion n'a pas eu lieu tant qu'il n'actualise pas manuellement la page (`F5`).
    - *Règle* :
      1. Encapsuler impérativement toute l'interface active du NAS dans un conteneur `#app-shell`.
      2. Conditionner l'affichage via des classes CSS strictes sur `<body>` : `body.not-authenticated .app-shell { display: none !important; }` et `body.authenticated .app-shell { display: block; }`.
      3. Rendre l'écran de connexion 100% opaque (`background: #11111b;` sans transparence ni dépendance au flou d'arrière-plan).
      4. Lors du `logoutUser()` : masquer instantanément `#app-shell`, révoquer la session sur l'API, purger cookies et stockage, nettoyer les paramètres d'URL (`?token=...`), et exécuter impérativement `window.location.replace("/")` pour purger la mémoire, les intervals et le DOM.
12. **Anti-pattern `iframe src=""` et roue de chargement permanente de l'onglet :**
    - *Erreur passée* : Déclarer un `<iframe src="">` ou des `<img src="">` vides dans le DOM initial pour un composant masqué (ex: visualiseur de document PDF ou miniature YouTube).
    - *Conséquence* : Selon la RFC 3986, un URI relatif vide sur un iframe pointe vers l'URI de base elle-même (`/`). Le navigateur tente donc de charger la page complète en boucle récursive à l'intérieur de l'iframe, ce qui maintient la roue de chargement de l'onglet du navigateur (`loading spinner`) en rotation continue sans jamais s'arrêter.
    - *Règle* :
      1. Utiliser impérativement `src="about:blank"` pour tout `<iframe>` non initialisé.
      2. Fournir un fichier natif `/favicon.ico` à la racine pour éviter que le navigateur ne tourne en boucle sur une erreur 404.
      3. Toujours déclarer `preload="none"` sur les balises `<video>` et `<audio>` tant qu'aucun média n'est chargé, et ne jamais y placer `autoplay` dans le HTML initial.
      4. Rendre le chargement des polices web CDN non-bloquant (`media="print" onload="this.media='all'"`) avec repli direct sur les polices système locales.

---

### E. Surveillance Matérielle, Ventilation & Sécurité Thermique
13. **Zéro composant matériel en dur (CPU / Carte Mère / GPU) :**
    - *Erreur passée* : Définir des valeurs de secours fixes (Dual Xeon E5-2650 v4, Huananzhi X99, Intel Arc A380) dans le backend Rust ou l'UI.
    - *Impact* : Tout utilisateur installant STEvE_OS sur une machine AMD Ryzen ou Intel Core voyait une fausse carte mère et un faux GPU affichés.
    - *Règle* : Détecter dynamiquement les composants via Linux sysfs (`/sys/class/dmi/id/`, `/sys/bus/pci/devices/*`, `/proc/cpuinfo`, `/sys/class/drm/`).
14. **Protection Failsafe Thermique Inviolable (80°C = 100% PWM) :**
    - *Règle fondamentale* : Dans tout démon d'asservissement des ventilateurs, forcer inconditionnellement la vitesse à 100% (255/255) si n'importe quelle sonde franchit 80°C, afin d'écarter tout risque de destruction matérielle par mauvaise courbe utilisateur.
15. **Persistance des Contrôleurs `hwmon` entre Redémarrages :**
    - *Règle* : Les index `/sys/class/hwmon/hwmonX` changent selon l'ordre d'initialisation des pilotes par le noyau Linux. Toujours associer les ventilateurs et sondes par `chip_name` (ex: `nct6775`, `k10temp`, `coretemp`) et index de canal (`fan1`, `temp1`) plutôt que par le numéro volatil de hwmon.
16. **Gestion des Ventilateurs GPU et Contrôleurs Autonomes (Intel Arc / i915 / VBIOS) :**
    - *Erreur passée* : Détecter un ventilateur GPU uniquement via la présence de `fanX_input` (tachymètre RPM) et supposer qu'il est réglable par PWM logiciel via `pwmX`.
    - *Impact* : Les ventilateurs des cartes graphiques dédiées Intel Arc (pilotes `i915` et `xe`) ne fournissent aucun fichier sysfs `pwmX` car leur régulation thermique est asservie directement en boucle fermée par le microcode matériel (VBIOS). Dans l'interface, les boutons de profils (Silencieux, Équilibré, Freeze) et le test de vitesse restaient cliquables mais n'avaient aucun effet mécanique.
    - *Règle & Pattern* :
      1. Tester systématiquement si `pwm_file.exists()` ET si le fichier est accessible en écriture (`fs::OpenOptions::new().write(true).open(&pwm_file).is_ok()`).
      2. Identifier les cartes GPU (`i915`, `xe`) et qualifier l'état `is_autonomous_firmware = true`.
      3. Dans l'UI, afficher un encart d'information Catppuccin explicatif (`🛡️ Régulation Autonome VBIOS`) et désactiver l'écrasement manuel ou le test PWM avec une mention pédagogique, tout en continuant à afficher le tachymètre RPM en temps réel.

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

### Régulation Thermique Linéaire par Morceaux (Courbes Ventilateurs) :
Pour convertir une température mesurée en consigne PWM fluide à partir d'une liste ordonnée de points d'inflexion `(temp_c, pwm_percent)` :
```rust
pub fn interpolate_pwm(temp: f32, curve: &[CurvePoint]) -> u8 {
    if temp >= 80.0 { return 100; } // Sécurité Failsafe inconditionnelle
    if curve.is_empty() { return 50; }
    if temp <= curve.first().unwrap().temp_c { return curve.first().unwrap().pwm_percent; }
    if temp >= curve.last().unwrap().temp_c { return curve.last().unwrap().pwm_percent; }

    for window in curve.windows(2) {
        let (p1, p2) = (&window[0], &window[1]);
        if temp >= p1.temp_c && temp <= p2.temp_c {
            let ratio = (temp - p1.temp_c) / (p2.temp_c - p1.temp_c).max(0.1);
            let pwm = p1.pwm_percent as f32 + ratio * (p2.pwm_percent as f32 - p1.pwm_percent as f32);
            return pwm.round().clamp(0.0, 100.0) as u8;
        }
    }
    100
}
```

---

### Affichage en ligne & inventaire matériel épuré (Dashboard) :
- Privilégier une disposition horizontale pleine largeur (`.hw-row-item` avec pastilles flex-wrap) plutôt qu'une grille de cartes imposantes qui fragmentent la lecture sur la page d'accueil.
- Décorer chaque ligne d'une bordure gauche thématique aux couleurs Catppuccin Mocha (CPU: mauve, Carte Mère: blue, RAM: yellow, GPU: peach, Réseau: teal, Stockage: sapphire).
- **Filtrage réseau strict** : Toujours filtrer les interfaces virtuelles bruyantes (`docker0`, `veth*`, `virbr*`, `br-*`, `wg*`, `tun*`, `tap*`) via la détection `/sys/class/net/<iface>/device` côté backend (`is_physical`) et un filtre de repli côté frontend, afin de ne valoriser sur la page d'accueil que les adaptateurs physiques réels (`eno1`, `enp*`, `eth*`) avec leur débit négocié, IPv4 locale et adresse MAC.

---

### Routage par Hash d'URL & Persistance Multi-Vues (Dashboard) :
- Ne jamais reposer uniquement sur `sessionStorage` pour l'état d'onglets : `sessionStorage` est volatile et se réinitialise lors des saisies d'URL dans la barre d'adresse, l'ouverture de nouvelles fenêtres ou les restrictions d'isolation de contexte.
- Utiliser un couplage dynamique entre `window.location.hash` (`#storage`, `#files`, `#containers`, `#network/samba`, etc.) et `localStorage.setItem("steveos_active_tab", tabId)`.
- Écouter l'événement `window.addEventListener("hashchange", ...)` pour garantir la cohérence des boutons Précédent / Suivant du navigateur.
- **Anti-flicker de la vue d'accueil** : Détecter et appliquer la vue cible dès le `DOMContentLoaded` (et via un attribut de pré-rendu `data-initial-tab` dans l'en-tête HTML) afin d'éviter tout clignotement ou affichage bref de la vue d'accueil (`tab-overview`) pendant l'attente de la vérification de session asynchrone (`/api/auth/me`).
- Conserver également le chemin actif de l'explorateur de fichiers (`steveos_files_path`) pour maintenir l'utilisateur dans son dossier courant après rafraîchissement.

---

### Transition visuelle & Rechargement fluide post-mise à jour (Dashboard) :
- Lors de la finalisation d'une mise à jour système (`stage === "completed"` ou 100%), déclencher un overlay plein écran avec floutage d'arrière-plan (`backdrop-filter: blur(20px)` et classe `body.app-updating-reload #app-shell` avec `filter: blur(14px) brightness(0.7)`).
- Présenter une carte centrée Catppuccin Mocha animée avec icône rayonnante ✨, halo radial et micro-jauge de progression de synchronisation (2.2s).
- **Persistance du contexte** : Mémoriser l'onglet actif dans `sessionStorage.setItem("steveos_active_tab", activeTab)` avant rechargement pour replacer automatiquement l'utilisateur sur son écran d'origine (qu'il soit resté sur l'onglet Mises à jour ou sur un autre onglet).
- Recharger la page via `window.location.replace()` avec un paramètre de timestamp pour purger le cache et appliquer immédiatement les nouveaux assets Web (HTML/JS/CSS) et le nouveau binaire.

---

### Architecture App Store STEvE_OS (`steveos_nas_store` & Docker Compose v2) :
- **Pourquoi Docker Compose asynchrone plutôt que la recompilation déclarative NixOS pour 600+ applications** :
  - Déployer des applications tierces via `virtualisation.oci-containers` forcerait un `nixos-rebuild switch` (plusieurs minutes d'évaluation, compilation et création de générations système) à chaque clic d'installation ou modification de variable.
  - L'orchestrateur Docker Compose v2 asynchrone permet un déploiement instantané (< 2 secondes) sous `/home/<user>/docker/<app_id>/compose.yaml` avec persistance unifiée dans `./data/...`.
- **Pipeline d'ingestion & Audit qualité rigoureux (`steveos_nas_store`)** :
  - Ingestion automatisée depuis les collections amont (Portainer types 1 et 3) avec résolution des stacks Git distantes.
  - Récriture impérative des chemins hôtes arbitraires (`/portainer/...`, `/srv/docker/...`) vers des chemins relatifs fiables et propres `./data/...`.
  - Élimination des applications obsolètes ou abandonnées :
    - Test de conformité Docker Compose Specification via `docker compose config -q`.
    - Détection des dépôts 404 et des images Docker Hub non maintenues (dernière mise à jour antérieure à 3 ans sans mise à jour).
    - Filtrage des projets dépréciés ou archivés (`deprecated`, `unmaintained`, `archived`, `discontinued`, `eol`).
- **Piège critique du typage des ports dans les schémas de données (Serde Rust)** :
  - *Erreur passée* : Typer `default_port` en `u16` dans les structures de catalogue Rust.
  - *Impact* : Des templates tiers amont contenaient des erreurs de saisie (ex: `98000`, `82303`). Serde échouait silencieusement à désérialiser tout le catalogue `store.json`, provoquant un repli sur un catalogue vide (0 applications).
  - *Règle* : Toujours utiliser `u32` pour les ports dans les structures Rust Serde afin de tolérer toute valeur brute, et normaliser impérativement les ports dans la plage TCP valide (1-65535) lors de l'ingestion et de l'audit.
- **Alerte Bouclier Pare-feu 1-Clic (`🛡️`) dans la modale d'installation** :
  - NixOS bloquant tout port non déclaré par défaut, l'installation d'une application Docker nécessite l'ouverture de son port hôte pour un accès LAN.
  - Intégrer une carte d'alerte pare-feu interactive dans la fenêtre d'installation :
    - Détection en direct via `/api/firewall`.
    - Si ouvert : pastille verte rassurante (`🛡️ Port X (TCP) Ouvert`).
    - Si fermé : avertissement pédagogique jaune avec bouton d'action immédiate `🔓 Ouvrir le port X en 1 clic`.
    - L'action appelle `POST /api/firewall/rules` (`category: "Conteneurs"`), actualise le pare-feu et bascule l'alerte au vert sans interrompre l'installation.
- **Fluidité de rendu du Store (Slicing 48 applications)** :
  - Ne jamais insérer plus de 50 à 100 cartes complexes simultanément dans le DOM.
  - Appliquer un découpage par tranches de 48 items avec un bouton dynamique "Afficher plus d'applications (+48)", tout en appliquant les recherches, tris et filtres par catégories sur l'intégralité du catalogue (640+ applications) en mémoire.

---

### Toast Flottant de Déploiement Docker en Arrière-Plan (Dashboard) :
- Ne jamais laisser l'utilisateur bloqué dans une modale figée pendant la création de volumes, le pulling d'images et le démarrage d'une stack Compose.
- **Cycle de vie du toast flottant** :
  1. Dès le clic sur "Déployer", fermer immédiatement la modale de configuration et faire glisser un toast élégant en bas à droite (`.docker-deploy-floating-toast`, `z-index: 100050`).
  2. Animer une micro-jauge de progression séquentielle (20% -> 45% -> 75% -> 100%) synchronisée avec les étapes d'orchestration (volumes, variables d'environnement, compose up, vérification de l'état).
  3. À la complétion réussie (code HTTP 200) :
     - Passer la pastille en vert (`status-success`) avec indicateur lumineux `✓ Déploiement terminé`.
     - Générer un bouton d'accès direct `🚀 Ouvrir l'application` pointant directement vers l'URL locale `http://<ip>:<port>`.
     - Ajouter un bouton d'action secondaire `📦 Voir les conteneurs` pour naviguer vers l'onglet conteneurs.
     - Programmer une fermeture automatique après 12 secondes avec repli manuel par bouton croix `✕`.
  4. En cas d'échec : passer la jauge en rouge (`status-error`), afficher le message d'erreur retourné par le daemon Docker et maintenir le toast ouvert pour consultation.

---

### Noyau Linux LTS & Stabilité Système pour NAS (NixOS) :
- **Suivi permanent du dernier noyau stable LTS NixOS (`pkgs.linuxPackages`)** :
  - Dans l'écosystème NixOS, `pkgs.linuxPackages` représente le noyau stable par défaut sélectionné et validé par les mainteneurs NixOS (actuellement la branche Linux 6.18.x) pour laquelle l'ensemble de la distribution (OpenZFS 2.4.x, pilotes Nvidia, virtualisation KVM/VFIO, Docker) est officiellement compilée et garantie dans le cache binaire.
  - Le noyau amont de pointe (`pkgs.linuxPackages_latest`) est quant à lui sur les versions 7.x expérimentales, non recommandées pour un serveur de stockage.
- **Architecture adoptée dans STEvE_OS** :
  - Déclaration de l'option `steveos.boot.kernel` dans `modules/options.nix` (valeur par défaut : `"lts"`).
  - Module dédié `modules/core/kernel.nix` assignant `boot.kernelPackages = pkgs.linuxPackages;` par défaut via `mkDefault` lorsque `kernel = "lts"`.
  - Cela garantit que le NAS bénéficie automatiquement du **dernier noyau stable LTS en permanence** au fil des mises à jour Nixpkgs sans intervention manuelle.
  - Possibilité d'épinglage fixe sur des versions antérieures (`"6_12"`, `"6_6"`) ou vers le noyau amont (`"latest"`).
  - Contrôle utilisateur centralisé via `vars.nix` (`kernel = "lts"`), documenté dans `vars-defaults.nix`.

---

### Easter Egg Rétro & Animation Pixel-Art (Dashboard) :
- **Déclenchement & Fenêtre glissante** :
  - Détection de 5 clics consécutifs sur le logo de marque (`#header-logo-wrap`) avec une temporisation glissante de 2.5 secondes (`clearTimeout`).
  - Animation de micro-rebond (`logoClickBounce`) sur le logo à chaque clic pour donner un retour tactile immédiat.
- **Rendu Pixel-Art Vectoriel Optimisé (SVG RLE)** :
  - Créer des sprites de 28x28 pixels nets via `shape-rendering="crispEdges"` et `image-rendering="pixelated"`.
  - Fusionner les pixels horizontaux contigus de même couleur (`width="N"`) en encodage RLE pour diviser le poids du DOM par 5 tout en garantissant un rendu 100% vectoriel sans artefacts de flou.
  - Cycle de course à 4 frames synchronisées (`[data-frame="0..3"]`) avec foulées alternées, canne levée, sac en balancier et nuage de poussière.
- **Synthèse Sonore Web Audio API (Zero-Dependency)** :
  - Utiliser l'API native `AudioContext` (activée automatiquement grâce au geste utilisateur des 5 clics) pour synthétiser en direct des pas de course légers.
  - Alterner la fréquence (245Hz / 290Hz) et le filtrage passe-bande entre le pied gauche et le pied droit pour un effet sonore authentique et rythmé.
  - Jouer un tintement d'arrivée doux à la fin du sprint (5.8s) avant de nettoyer le conteneur du DOM.
- **Positionnement de la Bulle de Dialogue (Anti-clipping)** :
  - Lorsque la piste est située sur la bordure inférieure du header (`bottom: -2px`), positionner la bulle de dialogue **en-dessous** du personnage (`top: 58px; transform: translateX(-50%)`) avec une flèche pointant vers le haut, afin qu'elle flotte harmonieusement au-dessus des onglets de navigation sans jamais être tronquée par le haut de la fenêtre du navigateur.

---

### Montage Durable Déclaratif `/mnt` (`mounts.json` + `mounts.nix`) & Gestion des Flags :
- **Architecture de double effet (Runtime immédiat & Déclaratif NixOS)** :
  - Pour concilier accès immédiat sans redémarrage et persistance durable après reboot, le Dashboard applique :
    1. Montage direct via `mount -o <runtime_flags> <device> <target>` avec attribution automatique des droits `chown -R <user>:storage <target>` et `chmod 2775 <target>` (setgid).
    2. Écriture atomique dans `mounts.json` synchronisée sur `/var/lib/steveos/mounts.json`, le répertoire de config (`$STEVEOS_CONFIG_DIR/mounts.json`) et le clone de développement.
    3. Lecture déclarative native par le module NixOS `modules/storage/mounts.nix` (`builtins.fromJSON (builtins.readFile ../../mounts.json)`) qui génère dynamiquement `fileSystems."<mountPoint>"` et les règles `systemd.tmpfiles.rules`.
- **Piège critique des Flags de montage (`nofail` vs Kernel runtime)** :
  - *Piège* : Passer aveuglément l'option `nofail` dans la commande runtime `mount -o defaults,noatime,nofail /dev/... /mnt/...` peut provoquer une erreur `mount: wrong fs type, bad option, bad superblock` selon le système de fichiers ou la version du noyau, car `nofail` est un drapeau géré exclusivement par `/etc/fstab` et `systemd`.
  - *Règle* : Toujours assainir les options envoyées à la commande `mount` runtime en filtrant les options spécifiques à fstab/systemd (`nofail`, `x-systemd.*`, `auto`, `noauto`), tout en conservant `nofail` dans `mounts.json` pour NixOS.
  - **Importance vitale de `nofail` sur un NAS** : Évite absolument tout basculement bloquant du NAS en mode rescue emergency au démarrage si un disque externe USB, un disque de données secondaire ou une baie est débranché ou temporairement indisponible.
  - **Drapeau `noatime`** : Recommandé par défaut sur tous les montages NAS pour éliminer les écritures inutiles d'horodatage de lecture, réduisant drastiquement l'usure mécanique/flash et augmentant les débits.
  - **Drapeau `compress=zstd`** : Activé automatiquement pour les volumes Btrfs pour économiser 20% à 35% d'espace disque.

---

### Refonte Ergonomique de l'Onglet Stockage (Dashboard) :
- **Affichage en Lignes pleine largeur (`.storage-disk-row`)** :
  - Remplacer les cartes verticales volumineuses par des lignes épurées et lisibles contenant l'identifiant physique (`Slot M.2 NVMe`, `Baie 1 (SATA)`), le modèle, le numéro de série, la capacité, la télémétrie S.M.A.R.T. et thermique, ainsi que l'état d'alimentation.
- **Cadre dédié pour les Grappes RAID (`.raid-cluster-frame`)** :
  - Encadrer visuellement chaque grappe RAID avec une bordure Catppuccin Mocha douce et une section dédiée aux **disques physiques membres de la grappe** (`.raid-members-section`), reliés par des connecteurs d'arbres hiérarchiques (`├──`, `└──`).
  - Séparer nettement les disques autonomes (non membres de grappes RAID) pour une lisibilité immédiate de l'infrastructure physique et logique.

---

## 🔄 4. Protocole d'Actualisation Continue de ce Fichier

À chaque fois qu'un bogue est résolu, qu'un écueil est identifié ou qu'une nouvelle architecture est introduite :
1. Ajouter l'anomalie et la solution dans la section **2. Pièges Critiques**.
2. Documenter la recette validée dans la section **3. Patterns Recommandés**.
3. Conserver un historique clair pour éviter toute régression sur les versions futures.
