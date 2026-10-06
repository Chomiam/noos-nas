<div align="center">
  <img src="assets/logo.png" alt="Noos NAS Logo" width="500"/>
  <br/><br/>
  
  # 🌐 Noos NAS Edition
  ### *Le Système d'Exploitation NAS Souverain, Déclaratif et Éco-Énergétique*
  
  [![NixOS](https://img.shields.io/badge/Base-NixOS%2026.05%20(Yarara)-blue?style=for-the-badge&logo=nixos&logoColor=white)](https://nixos.org)
  [![Rust](https://img.shields.io/badge/Outillage-Rust%201.80+-orange?style=for-the-badge&logo=rust&logoColor=white)](https://www.rust-lang.org)
  [![Btrfs & ZFS](https://img.shields.io/badge/Stockage-Btrfs%20%7C%20ZFS%20%7C%20RAID-green?style=for-the-badge&logo=linux&logoColor=white)](https://btrfs.readthedocs.io)
  [![Transcoding](https://img.shields.io/badge/GPU-Intel%20QuickSync%20%7C%20AMD%20%7C%20Nvidia-purple?style=for-the-badge)](https://github.com/Chomiam/noos-nas)
  [![License](https://img.shields.io/badge/Licence-Open%20Source-teal?style=for-the-badge)](#)

  <p align="center">
    <strong>Reprenez le contrôle absolu de votre stockage privé. Sans abonnement récurrent. Sans télémétrie obscure. Sans risque de panne lors des mises à jour.</strong>
  </p>
</div>

---

## 💎 Pourquoi Choisir Noos NAS Edition ?

Les solutions de stockage grand public traditionnelles (Synology DSM, QNAP QTS) imposent un matériel propriétaire coûteux, des écosystèmes fermés et un risque permanent de verrouillage commercial. D'un autre côté, les solutions libres historiques (TrueNAS, Unraid) souffrent souvent d'une complexité décourageante ou de ruptures de compatibilité lors des montées de version.

**Noos NAS Edition réinvente le cloud personnel** en combinant la puissance industrielle et l'immutabilité de **NixOS** avec une ergonomie pensée pour les particuliers exigeants, les créateurs de contenu et les professionnels :

| Avantage Clé | Solutions NAS Propriétaires | Distributions Classiques | 🌟 **Noos NAS Edition** |
| :--- | :--- | :--- | :--- |
| **Souveraineté des Données** | Cloud tiers imposé, télémétrie | Dépend des paquets installés | 🔒 **100% Locale, Zéro télémétrie, Chiffrement natif** |
| **Fiabilité des Mises à Jour** | Risque de blocage ou d'obsolescence | Conflits de dépendances possibles | 🛡️ **Transactions atomiques & Rollback instantané au boot** |
| **Consommation & Bruit** | Gestion basique | Configuration manuelle complexe | ⚡ **Spindown HDD intelligent & Profils basse consommation** |
| **Transcodage Multimédia** | Licences limitées selon gamme | Installation manuelle de pilotes | 🎬 **Intel QuickSync, AMD VA-API & Nvidia prêts à l'emploi** |
| **Écosystème Applicatif** | Magasins bridés, Docker limité | Maintenance manuelle des conteneurs | 🛍️ **Store officiel de 640+ applications en 1-clic** |
| **Modèle Économique** | Matériel surévalué, abonnements | Gratuit mais chronophage | 💸 **Libre, Open Source, Zéro coût d'abonnement** |

---

## 🌟 Les 5 Piliers Fondateurs de Noos NAS

### 1. 🛡️ Résilience Absolue : L'Immutabilité NixOS
Grâce à l'architecture déclarative de NixOS, votre NAS ne craint plus aucune mise à jour. Chaque déploiement génère une nouvelle version autonome du système sans écraser la précédente. En cas d'erreur ou d'imprévu, **un simple redémarrage sur la génération précédente restaure votre NAS exactement dans son état fonctionnel antérieur en 3 secondes.**

### 2. ⚡ Éco-Responsable & Silencieux (Spindown Intelligent)
Votre NAS tourne 24 heures sur 24, mais vos disques mécaniques ne doivent pas s'user ni consommer pour rien :
- **Mise en veille automatique (`hdparm` / `spindown.nix`)** : Les disques durs rotatifs (HDD) se mettent en veille profonde dès qu'aucune activité n'est requise.
- **Préservation de la durée de vie** : Réduction drastique des vibrations, du bruit ambiant et de la facture énergétique.
- **Réveil instantané** : Dès qu'un accès réseau ou un flux multimédia est sollicité, le disque se réveille de façon transparente.

### 3. 🎬 Centre Multimédia Haute Performance (Transcodage 4K HDR)
Transformez votre matériel en un puissant serveur de streaming sans faire souffrir le processeur :
- **Intel QuickSync Video (QSV)** : Pilotes officiels `intel-media-driver` (iHD), runtime `vpl-gpu-rt`, OpenCL pour le tonemapping HDR en temps réel.
- **AMD VA-API** : Accélération matérielle complète Radeon avec `libva` et runtime ROCm.
- **Nvidia NVENC / NVDEC** : Prise en charge native avec `nvidia-container-toolkit` pour conteneurs Docker/Podman.
- **Permissions `/dev/dri` injectées automatiquement** pour Jellyfin, Plex et les applications du Store Noos.

### 4. 🗄️ Stockage Professionnel, RAID & Zéro Bitrot
- **Système de fichiers de nouvelle génération (Btrfs / ZFS)** : Protection active contre la corruption silencieuse des données (*bitrot*), snapshots instantanés *Copy-on-Write* et compression transparente `zstd`.
- **Surveillance continue de la santé physique (`smartd.nix`)** : Détection prédictive des défaillances de disques avant toute perte de données.
- **Scrubbing et maintenance programmés** : Tâches d'intégrité exécutées en arrière-plan pendant les heures creuses.

### 5. 🏰 Forteresse Numérique & Confidentialité Totale
- **Pare-Feu Modulaire Strict** : Chaque service actif (Samba, NFS, sFTP, WireGuard) n'ouvre ses ports que lorsqu'il est explicitement activé.
- **Protection Brute-Force avec Fail2ban** : Détection et bannissement instantané des tentatives d'intrusion sur SSH et les services exposés.
- **VPN WireGuard Intégré** : Accédez à vos partages de fichiers en toute sécurité depuis l'extérieur comme si vous étiez dans votre salon, sans ouvrir de ports non sécurisés sur votre box internet.

---

## 📁 Architecture du Dépôt

```text
noos-nas/
├── assets/
│   └── logo.png                     # Logo officiel Noos NAS
├── flake.nix                        # Déclaration de l'écosystème Flake & outil CLI
├── flake.lock                       # Verrouillage reproductible des versions logicielles
├── vars.nix                         # ⚙️ Vos réglages utilisateur (Nom du NAS, disques, services)
├── vars-defaults.nix                # Schéma officiel de référence
├── firewall-user.nix                # Surcharges personnalisées du pare-feu
│
├── hosts/
│   └── nas/                         # Définition du serveur NAS
│       ├── configuration.nix        # Orchestration des modules Noos
│       ├── hardware-configuration.nix # Spécifications matérielles du serveur
│       └── storage.nix              # Montages déclaratifs et pools de stockage
│
├── modules/
│   ├── options.nix                  # Options déclaratives de haut niveau (noos.*)
│   ├── core/                        # Noyau Linux, comptes utilisateurs, sécurité, pare-feu
│   ├── hardware/                    # Pilotes graphiques, codecs GPU, économie d'énergie
│   ├── storage/                     # SMART, spindown des disques, scrubbing Btrfs
│   └── services/                    # Samba (SMB), sFTP, NFS, Docker, VPN WireGuard
│
└── tools/
    └── noos-cli/                    # 🦀 Outil de gestion et diagnostic natif en Rust
        ├── Cargo.toml
        └── src/main.rs
```

---

## 🚀 Prise en Main avec l'Outil CLI Rust (`noos-cli`)

Noos NAS inclut un utilitaire natif en Rust permettant d'administrer, diagnostiquer et déployer votre configuration à distance en une commande :

```bash
# 1. Copier votre clé SSH vers le serveur NAS pour une connexion sans mot de passe
nix run .#noos-cli -- copy-id user@192.168.1.50

# 2. Diagnostiquer en direct le matériel distant (CPU, GPU, disques SATA/NVMe, mémoire)
nix run .#noos-cli -- probe user@192.168.1.50

# 3. Vérifier les ports réseau autorisés et le statut de la configuration déclarative
nix run .#noos-cli -- status

# 4. Compiler et déployer votre configuration Noos NAS sur le serveur distant
nix run .#noos-cli -- deploy user@192.168.1.50
```

---

## 🤝 L'Écosystème Noos NAS

Noos NAS Edition fait partie intégrante d'un écosystème modulaire et harmonieux :

- [**Noos NAS Dashboard**](https://github.com/Chomiam/noos-nas-dashboard) : L'interface web de contrôle ultra-réactive en Rust et Catppuccin Mocha.
- [**Noos NAS Store**](https://github.com/Chomiam/noos_nas_store) : La boutique de plus de 640 conteneurs Docker Compose déployables en 1-clic.
- [**Noos Game Eggs**](https://github.com/Chomiam/noos_nas_eggs) : Le hub de serveurs de jeux vidéo clé en main (Minecraft, Palworld, Valheim, etc.).
- [**Noos NAS ISO**](https://github.com/Chomiam/noos-nas_iso) : L'installateur réseau automatisé accessible directement depuis votre navigateur.

---

<div align="center">
  <sub>Propulsé par la communauté Noos • Conçu pour la souveraineté numérique et la durabilité matérielle.</sub>
</div>
