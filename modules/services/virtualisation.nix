{ config, lib, pkgs, ... }:

let
  cfg = config.steveos.services.virtualisation;
  u = config.steveos.user.username;
in
{
  options.steveos.services.virtualisation = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Hyperviseur KVM / QEMU / libvirt pour STEvE_OS NAS";
    };
    storagePool = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/storage/vms";
      description = "Dossier racine des disques virtuels QCOW2";
    };
    isoPool = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/storage/isos";
      description = "Dossier racine des images ISO d'installation";
    };
    enableIommu = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Activer IOMMU pour le GPU Passthrough (AMD / Intel)";
    };
  };

  config = lib.mkIf cfg.enable {
    # 1. Paramètres noyau pour AMD-V (svm) et Intel VT-x (vmx) + IOMMU pour le Passthrough (AMD / Intel / Nvidia)
    boot.kernelParams = lib.optionals cfg.enableIommu [
      "amd_iommu=on"
      "intel_iommu=on"
      "iommu=pt"                     # Mode passthrough matériel direct
      "kvm.ignore_msrs=1"            # Stabilité pour Windows 11 et pilotes graphiques
      "kvm.report_ignored_msrs=0"    # Évite le spam dans les logs lors des sondes de pilotes Nvidia
    ];

    # 2. Modules noyau VFIO et filtrage pont réseau
    boot.kernelModules = [
      "kvm-amd"
      "kvm-intel"
      "vfio"
      "vfio_iommu_type1"
      "vfio_pci"
      "br_netfilter"
    ];

    # 3. Paramètres sysctl pour le pont réseau :
    # Empêche iptables/nftables de filtrer le trafic de niveau 2 sur le pont LAN br0
    boot.kernel.sysctl = {
      "net.bridge.bridge-nf-call-iptables" = 0;
      "net.bridge.bridge-nf-call-ip6tables" = 0;
      "net.bridge.bridge-nf-call-arptables" = 0;
    };

    # 4. Service libvirtd & swtpm (TPM 2.0 pour Windows 11)
    # Note: En NixOS 26.05+, les images OVMF/UEFI de QEMU sont intégrées automatiquement par défaut
    virtualisation.libvirtd = {
      enable = true;
      allowedBridges = [ "br0" "virbr0" ];
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
      };
      onBoot = "ignore";
      onShutdown = "shutdown";
    };

    # 5. Paquets système requis pour l'administration et la console web
    environment.systemPackages = with pkgs; [
      qemu_kvm
      libvirt
      virt-manager
      bridge-utils
      swtpm
      novnc
      python3Packages.websockify
    ];

    # 6. Droits d'accès de l'utilisateur au groupe libvirtd et kvm
    users.users.${u}.extraGroups = [ "libvirtd" "kvm" ];

    # 7. Création déclarative des dossiers de stockage pour VMs et ISOs
    # + Liens symboliques de compatibilité pour les sockets client virtqemud -> libvirt-sock
    systemd.tmpfiles.rules = [
      "d ${cfg.storagePool} 2775 ${u} storage -"
      "z ${cfg.storagePool} 2775 ${u} storage -"
      "d ${cfg.isoPool} 2775 ${u} storage -"
      "z ${cfg.isoPool} 2775 ${u} storage -"
      "L+ /run/libvirt/virtqemud-sock - - - - /run/libvirt/libvirt-sock"
      "L+ /run/libvirt/virtqemud-sock-ro - - - - /run/libvirt/libvirt-sock-ro"
      "L+ /run/libvirt/virtqemud-admin-sock - - - - /run/libvirt/libvirt-admin-sock"
    ];
  };
}
