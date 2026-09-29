{ config, lib, pkgs, ... }:

let
  isAmd = config.steveos.hardware.gpu == "amd";
  codecs = config.steveos.hardware.enableCodecs;
in
{
  config = lib.mkIf isAmd {
    boot.initrd.kernelModules = [ "amdgpu" ];
    boot.kernelModules = [ "kvm-amd" ];

    hardware.graphics = {
      enable = true;
      extraPackages = lib.mkIf codecs (with pkgs; [
        libva
        libva-utils
        rocmPackages.clr.icd # Runtime OpenCL ROCm pour transcodage et calcul
      ]);
    };

    hardware.amdgpu.opencl.enable = true;
  };
}
