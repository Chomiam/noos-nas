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

    # Démarrage automatique garanti du service et du socket libvirtd au boot
    systemd.services.libvirtd.wantedBy = [ "multi-user.target" ];
    systemd.sockets.libvirtd.wantedBy = [ "sockets.target" "multi-user.target" ];
    systemd.sockets.libvirtd-ro.wantedBy = [ "sockets.target" "multi-user.target" ];
    systemd.sockets.libvirtd-admin.wantedBy = [ "sockets.target" "multi-user.target" ];

    # Initialisation déclarative du réseau NAT virtuel par défaut (virbr0)
    systemd.services.libvirt-default-network = {
      description = "Initialisation du réseau NAT par défaut de libvirt (virbr0)";
      after = [ "libvirtd.service" ];
      wants = [ "libvirtd.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "libvirt-init-default-net" ''
          mkdir -p /run/libvirt
          cat << 'EOF' > /run/libvirt/default-net.xml
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <dns enable='no'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
EOF
          # Définition / mise à jour déclarative du réseau libvirt avec désactivation du port 53
          ${pkgs.libvirt}/bin/virsh -c qemu:///system net-define /run/libvirt/default-net.xml || true
          rm -f /run/libvirt/default-net.xml

          ${pkgs.libvirt}/bin/virsh -c qemu:///system net-autostart default || true
          if ! LC_ALL=C ${pkgs.libvirt}/bin/virsh -c qemu:///system net-info default 2>&1 | grep -q "Active:.*yes"; then
            ${pkgs.libvirt}/bin/virsh -c qemu:///system net-start default || true
          fi
        '';
      };
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
