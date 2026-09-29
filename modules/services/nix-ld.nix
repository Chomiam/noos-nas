{ config, lib, pkgs, ... }:

let
  cfg = config.steveos.services.nixLd;
in
{
  # =========================================================================
  # 🧪 COMPATIBILITÉ BINAIRES UNIVERSELLE (NIX-LD & APPIMAGE)
  # =========================================================================
  # Permet d'exécuter des binaires ELF non-Nix précompilés (VS Code Server,
  # scripts Python/Node.js natifs, agents de monitoring, outils tiers).
  # Intègre l'ensemble des bibliothèques fondamentales ainsi que les outils
  # déjà présents sur STEvE_OS (FFmpeg, ImageMagick, libheif, libraw, LVM2,
  # Btrfs, OpenSSL, Vulkan/Mesa, etc.).
  # =========================================================================

  options.steveos.services.nixLd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Active nix-ld et appimage pour exécuter des binaires Linux précompilés externes sans modification.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Intégration AppImage automatique via binfmt
    programs.appimage = {
      enable = true;
      binfmt = true;
      package = pkgs.appimage-run.override {
        extraPkgs = pkgs: [
          pkgs.icu
          pkgs.libxcrypt-legacy
        ];
      };
    };

    # Loader nix-ld pour exécuter les binaires ELF standard Linux
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # --- Runtimes C/C++ fondamentaux & Compression ---
        stdenv.cc.cc
        glibc
        libxcrypt-legacy
        zlib
        bzip2
        xz
        zstd
        icu

        # --- Système, Événements & IPC ---
        glib
        pcre2
        libevent
        libuv
        systemd
        dbus
        fuse3

        # --- Cryptographie, Sécurité & Réseau ---
        openssl
        curl
        nghttp2
        libssh2

        # --- Formats de données, XML & Base de données ---
        libxml2
        sqlite

        # --- Matériel & Supervision (issus des paquets NAS de STEvE_OS) ---
        pciutils
        libusb1
        lm_sensors
        lvm2
        btrfs-progs
        e2fsprogs
        parted

        # --- Traitement Multimédia & Images (issus des outils STEvE_OS) ---
        ffmpeg
        imagemagick
        libheif
        libraw
        fontconfig
        freetype

        # --- Accélération Graphique, GPU, Audio & Vidéo ---
        libdrm
        libgbm
        libglvnd
        mesa
        vulkan-loader
        alsa-lib
        pipewire
        wayland

        # --- Bibliothèques GUI / Headless / VS Code Remote / Electron / Playwright ---
        nss
        nspr
        atk
        at-spi2-atk
        at-spi2-core
        cups
        expat
        libxkbcommon
        cairo
        pango
        gdk-pixbuf
        gtk3
        libnotify
        libunwind
        libx11
        libxcomposite
        libxcursor
        libxdamage
        libxext
        libxfixes
        libxi
        libxrandr
        libxrender
        libxscrnsaver
        libxtst
        libxcb
        libxshmfence
      ];
    };
  };
}
