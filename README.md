# 🚀 Noos NAS Edition

Système d'exploitation modulaire pour NAS & Serveur de Stockage personnel, propulsé par **NixOS** et outillé en **Rust**.
Directement inspiré de l'architecture déclarative de **ChomiamOS**, Noos NAS Edition est optimisé pour une disponibilité 24/7, une faible consommation électrique, un transcodage multimédia matériel performant et des partages réseau sécurisés.

---

## 🌟 Points Forts

- **Schéma Déclaratif Centralisé :** Tout se configure simplement dans `vars.nix` (héritant automatiquement de `vars-defaults.nix`).
- **Transcodage GPU & Codecs Modulaires :**
  - **Intel QuickSync :** Pilote `intel-media-driver` (iHD), runtime `vpl-gpu-rt`, `libva`, OpenCL `intel-compute-runtime`.
  - **AMD VA-API :** Décodage/encodage matériel Radeon avec `libva` et ROCm OpenCL.
  - **Nvidia NVENC/NVDEC :** Support officiel avec `nvidia-container-toolkit` pour conteneurs Docker/Podman.
  - Permissions `/dev/dri` injectées automatiquement pour Jellyfin et les conteneurs.
- **Pare-Feu Modulaire :**
  - Chaque module de service (Samba, NFS, SSH, WireGuard) déclare et ouvre ses propres ports uniquement lorsqu'il est activé.
  - Surcharges utilisateur préservées dans `firewall-user.nix`.
  - Protection active contre le bruteforce avec **Fail2ban**.
- **Gestion du Stockage & Disques :**
  - Mise en veille automatique des disques HDD rotatifs (`spindown.nix` via `hdparm`).
  - Surveillance continue de la santé des disques (`smartd.nix`).
  - Tâches de maintenance programmées (scrub Btrfs / trim ZFS).
- **Outillage CLI 100% Rust (`noos-cli`) :**
  - Outil natif en Rust pour diagnostiquer le NAS distant (`probe`), copier vos clés SSH (`copy-id`), inspecter l'évaluation NixOS (`status`) et déployer (`deploy`).

---

## 🛠️ Structure du Projet

```text
noos-nas/
├── flake.nix                       # Point d'entrée Flake (mkNasSystem + package noos-cli)
├── flake.lock                      # Verrouillage reproductible des dépendances
├── vars.nix                        # Configuration utilisateur personnalisée
├── vars-defaults.nix               # Schéma de référence et valeurs par défaut
├── firewall-user.nix               # Règles pare-feu manuelles
│
├── hosts/
│   └── nas/                        # Configuration système de la machine NAS
│       ├── configuration.nix       # Assemblage des modules et options
│       ├── hardware-configuration.nix # Configuration matérielle scannée
│       └── storage.nix             # Montages et pools de stockage
│
├── modules/
│   ├── options.nix                 # Définition des options déclaratives (noos.*)
│   ├── core/                       # Nix, utilisateurs, sécurité, pare-feu modulaire
│   ├── hardware/                   # Pilotes GPU, codecs VA-API/QSV, économie d'énergie
│   ├── storage/                    # SMART, spindown, maintenance disques
│   └── services/                   # Samba, NFS, sFTP, Docker, VPN (WireGuard), KVM, nix-ld
│
└── tools/
    └── noos-cli/                # 🦀 Outil d'administration natif en Rust
        ├── Cargo.toml
        └── src/main.rs
```

---

## 🚀 Utilisation avec l'Outil CLI en Rust (`noos-cli`)

Vous pouvez exécuter directement l'outil avec `nix run` :

```bash
# 1. Copier votre clé SSH vers le NAS
nix run .#noos-cli -- copy-id chomiam@192.168.1.139

# 2. Diagnostiquer le matériel distant (CPU, GPU, disques, OS actuel)
nix run .#noos-cli -- probe chomiam@192.168.1.139

# 3. Vérifier les ports du pare-feu modulaire et le statut de la configuration locale
nix run .#noos-cli -- status

# 4. Déployer la configuration Noos sur le NAS distant
nix run .#noos-cli -- deploy chomiam@192.168.1.139
```
