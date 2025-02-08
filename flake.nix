{
  description = "BEVFusion: Multi-Task Multi-Sensor Fusion with Unified Bird's-Eye View Representation";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";

    torchpack-src = {
      url = "github:zhijian-liu/torchpack/c066a1c50af17ca8611b4150c209876232ffe27b";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, torchpack-src }:
    flake-utils.lib.eachDefaultSystem(system: let 

    cuda-11-overlay = final: prev: {
      cudaPackages = prev.cudaPackages_11;
    };

    pkgs = import nixpkgs {
      inherit system;
      cudaSupport = true;
      config.allowUnfree = true;
      overlays = [ cuda-11-overlay ];
    };


    # torch-cuda-11 = with pkgs; python3Packages.torch.override {
    #   cudaPackages = pkgs.cudaPackages_11_3;
    # };
    # # bevfusion requires pytorch 1.9.0, which requires cuda 11.3 (fails on 11.4)
    # # all cuda dependent packages are overriden to use cuda 11.3
    # pytorch-cuda-11 = with pkgs; python38Packages.pytorch.override {
    #   cudaSupport = true;
    #   cudatoolkit = cudatoolkit_11_3;
    #   cudnn = cudnn_cudatoolkit_11_3;
    #   nccl = nccl.override { cudatoolkit = cudatoolkit_11_3; };
    #   magma = magma.override { cudatoolkit = cudatoolkit_11_3; };
    # };

    # torchvision-cuda-11 = with pkgs; python38Packages.torchvision.override {
    #   cudaSupport = true;
    #   pytorch = pytorch-cuda-11;
    #   cudatoolkit = cudatoolkit_11_3;
    #   cudnn = cudnn_cudatoolkit_11_3;
    # };

    torchpack = with pkgs.python3Packages; buildPythonPackage {
      pname = "torchpack";
      src = torchpack-src;
      version = "0.3.1.2"; # latest release on github is 0.3.1

      build-system = [ setuptools ];

      propagatedBuildInputs = [
        loguru
        multimethod
        numpy
        pyyaml
        pytorch-cuda-11
        torchvision-cuda-11
        tqdm
      ];
    };

    # mmengine = pkgs.python38Packages.callPackage ./mmengine-backport.nix (with newpkgs.python3Packages; {
    #   inherit bitsandbytes dvclive lion-pytorch;
    #   opencv4 = mkPythonMetaPackage {
    #     pname = "opencv-python-headless";
    #     inherit (opencv4) version;
    #     dependencies = [ opencv4 ];
    #     optional-dependencies = opencv4.optional-dependencies or { };
    #     meta = {
    #       inherit (opencv4.meta) description homepage;
    #     };
    #   };
    # });

    # mmcv = pkgs.python38Packages.callPackage ./mmcv-backport.nix {
    #   cudaArchList = pytorch-cuda-11.cudaArchList;
    #   cudatoolkit = pkgs.cudatoolkit_11_3;
    #   cudaSupport = true;
    #   pytorch = pytorch-cuda-11;
    #   torchvision = torchvision-cuda-11;
    #   # setuptools = pkgs.python38.pkgs.setuptools;
    #   # mmengine = (pkgs.python3Packages.mmengine.override {
    #     # buildPythonPackage = pkgs.python38Packages.buildPythonPackage;
    #   # });
    #   # inherit mmengine;
    #   # buildPythonPackage = pkgs.python38Packages.buildPythonPackage;
    # };

    bevfusion = with pkgs.python3Packages; buildPythonPackage {
      pname = "bevfusion";
      src = bevfusion-src;
      version = "1.0.0";

      build-system = [ setuptools ];

      # propagatedNativeBuildInputs = with pkgs; [ pytorch-cuda-11 cudatoolkit_11_3 python38Packages.pybind11 ];
      nativeBuildInputs = with pkgs; [ which cudaPackages.cudatoolkit python3Packages.pybind11 ];
      buildInputs = with pkgs; [
        torch

        cudaPackages.cudatoolkit
        cudaPackages.cudnn
        pybind11
        mmcv
        # torchpack
      ];

      # preConfigure = ''
      #   export TORCH_CUDA_ARCH_LIST="${nixpkgs.lib.concatStringsSep ";" pytorch-cuda-11.cudaArchList}"
      # '';
    };

    in 

  {
    packages.default = pkgs.python3Packages.torch;
    # packages.default = experimental-torch;

    # packages.default = self.packages.bevfusion;

  }
  );

  nixConfig = {
    extra-substituters = [ "https://nix-community.cachix.org" "https://cache.nixos.org/" ];
    extra-trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };

}
