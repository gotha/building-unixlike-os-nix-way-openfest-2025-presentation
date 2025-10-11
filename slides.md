---
author: Hristo Georgiev
title: Building unix-like operating systems the nix way
date: October 19, 2025
---

## What are we going to talk about today 

- What is Nix?
- Sharing some personal stories 
- State of Nix
- Fun project/s to play with


<aside class="notes">
Overview of the Nix ecosystem
- why is it interesting?
</aside>

---

## $(whoami)

- [hgeorgiev.com](https://hgeorgiev.com)
- [github.com/gotha](https://github.com/gotha)
- why you should listen to me?
- disclaimer
- why am I here?

<aside class="notes">
Imagine everyone is naked!

Not literally everyone, obviously!

- I am not paid to do this!
- these are my personal views, nothing to do with my employer!
</aside>

---

## What is Nix 

- Pop Quiz: What is Nix?
    - a programming language 
    - a package manager 
    - a Linux distribution

<aside class="notes">
- It depends!
- any haskell fans? - both of them?
</aside>

---

## Etymology time

"nix" is Latin for "snow".

<aside class="notes">
Why is the logo made of lambdas?
</aside>

---

## The paper

- 2006 Eelco Dolstra - The Purely functional software deployment model
- each build is a function - in - out
- lets create a new lazy evaluated functional language for composition
- forget about FHS, we have /nix/store
- hash everything

<aside class="notes">
- FHS
   - /bin vs /usr/bin vs /opt
- sounds like supply chain attacks solution, but it it is much more
</aside>

---

## The result of the paper

- reproducible
- immutable
- atomic upgrades and instant rollbacks
- garbage collection
- source and binary deployment - the same thing

<aside class="notes">
- the theory is cool but ...
- today we are going to focus on the practical aspects
</aside>

---

## A bored hacker during the Christmas holidays 

![bored gnu](./img/bored-hacker.png)

<aside class="notes">
Note that back then I did NOT know anything about nix.

Warning: this presentation contains AI slop.
</aside>

---


## Lets play with containers

- reading [Building an Orchestrator in Go (from scratch) - Timothy Boring](https://www.oreilly.com/library/view/build-an-orchestrator/9781617299759/)
- [bicr](https://github.com/gotha/bicr/)
- Linux From Scratch - [bilfs](https://github.com/gotha/bilfs)
- building the toolchain is half the book! it is hard! Can we make it better?

<aside class="notes">
- pull docker api to schedule containers
- I like to document stuff - I needed a way to reproduce build env
</aside>

---

## first steps with nix


```nix
with (import <nixpkgs> {});
mkShell {
  buildInputs = [
    cacert coreutils bash binutils
    bison diffutils e2fsprogs findutils
    gawk gcc gzip m4 patch perl python3 sudo
    texinfo util-linux xz wget
  ];
```
nix-shell --pure [lfs.nix](https://github.com/gotha/bilfs/blob/main/lfs.nix)

<aside class="notes">
- what is "pure"?
- what is already installed?
- what version am I installing? 
- compare to other distros?
</aside>

---

## (slightly) Better flake with dev tools

```nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let supportedSystems =
        [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems
        (system: f { pkgs = import nixpkgs { inherit system; }; });
    in {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            coreutils
            bash binutils bison
            diffutils e2fsprogs
            findutils
            gawk gcc
```

nix develop

<aside class="notes">
Why is this better? 
- specify supported systems
- inputs
</aside>

---

## Don't let "unstable" fool you we have flake.lock

```nix
"nixpkgs": {
  "locked": {
    "lastModified": 1760038930,
    "narHash": "sha256-Oncbh0UmHjSlxO7ErQDM3KM0A5/Znfofj2BSzlHLeVw=",
    "owner": "NixOS",
    "repo": "nixpkgs",
    "rev": "0b4defa2584313f3b781240b29d61f6f9f7e0df3",
    "type": "github"
  }
```

- "unstable" is kind of like Debian "testing"


<aside class="notes">
- for nodejs - flake = nvm + npm
</aside>

---

## Building dev environments with nix flakes

- single flake.nix file + direnv = the first thing I do for every project
    - nvm, volta, venv, sdkman, etc.
    - I don't want to learn a new tool for every language
- no need for docker-compose (or devcontainers or god forbid - vagrant)
- alternatives - flox, devbox, devenv

<aside class="notes">
- containers are overhead for non-linux
- you can specify software AND env variables, configuration, etc.
- all alternatives mentioned here are based on nix - why? - it is great, but it is kind of complex.
- wrap up 
    - result for bicr + bilfs
    - since then flake.nix is the first thing I do for every project
    - compiler + dependencies + configuration
</aside>

---

## Ricing 

![gnu ricing](./img/gnu-race-car.png)

<aside class="notes">
- what is ricing?
- negative connotation, doesnt have to be!
- so far - packaging software and configs in flakes
- ahead - packaging software and configs in flakes
</aside>

---

## Dotfiles

- do I even need something to manage my dotfiles?
- GNU stow
- home-manager 
- why is it better?

<aside class="notes">
- my problems
    - forgot to install stuff - wob (volume/brightness overlay)
    - variations per machine
- marriage of installation and configuration
- you can template stuff 
- nix is a programming language - you can put as complex logic as you want 
- you can write your own complex modules
</aside>

--- 

## Some examples 

[github.com/gotha/dotfiles](https://github.com/gotha/dotfiles)

<aside class="notes">
- steal my dotfiles!
- dotfiles are like a poem - never finished, just abandoned
</aside>

---

## My tmux config

default.nix
```nix
{ pkgs, ... }: {
  home.packages = with pkgs; [ tmux ];

  home.file.".tmux.conf".source = ./tmux.conf;
}
```

tmux.conf
```tmux.conf
unbind C-b
set -g prefix C-Space
bind C-Space send-prefix
# BAU ... 
```

---

## My git config

```nix
{ pkgs, ... }: {

  home.packages = with pkgs; [ git git-lfs ];

  xdg.configFile."git/ignore".source = ./global_ignore;

  programs.git = {
    enable = true;

    userName = "gotha";
    userEmail = "h.georgiev@hotmail.com";

    signing = {
      key = "C3AB3AC0115DD07B5ACA476E8D8E74E4033D192C";
      signByDefault = true;
    };

    extraConfig = {
      init = { defaultBranch = "main"; };

      push = { autoSetupRemote = true; };

      core = {
        editor = "nvim";
        excludesfile = "~/.config/git/ignore";
      };

      diff = { tool = "vimdiff"; };

      filter."lfs" = {
        process = "git-lfs filter-process";
        required = true;
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
      };

      pull = { rebase = true; };
    };
  };
}
```

<aside class="notes">
- full nix module
- I always forget to install git-lfs
</aside>

--- 

## My Alacritty config 

```nix
{ config, lib, pkgs, ... }: {

  options.programs.alacritty.custom = {
    fontSize = lib.mkOption {
      type = lib.types.number;
      default = 10.0;
      description = "Font size for Alacritty terminal";
    };
  };

  config = {

    home.packages = with pkgs; [ alacritty ];

    xdg.configFile."alacritty/alacritty.toml".text = let
      baseConfig = builtins.readFile ./alacritty.toml;
      fontSize = toString config.programs.alacritty.custom.fontSize;
    in builtins.replaceStrings [ "{{FONT_SIZE}}" ] [ fontSize ] baseConfig;
  };
}
```

<aside class="notes">
- minimal change
- ideal for transition from old config to nix
</aside>


## Build it all together (flakify) your system

```nix
{
  description = "my minimal system flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
  };
  
  outputs = { nixpkgs, home-manager, ... }: {
    nixosConfigurations = {
      yourhostnamehere = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ 
          ./configuration.nix 
          home-manager.nixosModules.home-manager
          ./home-manager/git
          ./home-manager/tmux
        ];
      };
    };
  };
}

```

nixos-rebuild switch --flake .

<aside class="notes">
- not just for nixos - any unix
- nixos-install --flake .
</aside>

---

## Enter NIX Darwin


```nix
{ pkgs, systemPackages, ... }: {
  environment = {
    shells = with pkgs; [ zsh ];
    systemPackages = systemPackages;
    systemPath = [ "/opt/homebrew/bin" ];
    pathsToLink = [ "/Applications" ];
    variables = { EDITOR = "vi"; };
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  system.keyboard.nonUS.remapTilde = true;
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  system.defaults = {
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      _FXShowPosixPathInTitle = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      CreateDesktop = false;
    };
    dock = {
      autohide = true;
      orientation = "left";
    };
    trackpad = {
      Clicking = true; # tap to cick
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
    };
  };
}
```

<aside class="notes">
- osx breaking changes - abstraction
- not so many GUI apps for OSX, my package manager manages my other package manager.
</aside>

---

## Building distros?

- what do you call a collection of software and configs packaged in a flake? 

---

## Bored hacker needs to orchestrate servers

![gnu orchestrating](./img/gnu-orchestrating.png)

<aside class="notes">
- nix-install - why not install servers
- what is my project? - k3s IaC
</aside>

---

## Lets go to the cloud

- the hyperscalers dont offer nix?
    - all I could find is hacky guide for running on NixOS Hetzner
- you can install nix the package manager on any linux
- [system-manager](https://github.com/numtide/system-manager) - systemd, nix modules, configuration, etc.
- [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)? - ssh, kexec, disko, install
- [nixos-generators](https://github.com/nix-community/nixos-generators) - aws, azure, gcp, lxc, docker, vbox, vdmk, raw, qcow, iso, etc.


```sh
nixos-anywhere --flake '.#your-config' root@your-droplet-ip
nixos-generate -f do -c configuration.nix
```

<aside class="notes">
- system-manager turns any linux into a nixos machine
- nixos-anywhere - basically a nix virus
- nixos-generate:
    - live linux USB
    - custom linux installer
    - run inside qemu
</aside>

---


## Generations and rollbacks - NixOS' killer feature

```
> nixos-rebuild build
> nixos-rebuild switch
> nixos-rebuild list-generations
Generation  Build-date  NixOS version   Kernel   Current
38          2025-10-04  25.11.20251011  6.12.51  True
37          2025-10-03  25.11.20251011  6.12.51  False
36          2025-10-02  25.11.20251011  6.12.51  False
35          2025-10-01  25.11.20251011  6.12.51  False
```

---

## my minimal flake.nix for DO

```nix
  networking.useDHCP = true;

  services = {
    cloud-init = {
      enable = true;
      ext4.enable = true;
    };
    openssh.enable = true;
  };

  users.users.gotha = {
    openssh.authorizedKeys.keys = [ "..." ];
  };

  environment.systemPackages = with pkgs; [ curl wget git vim ];
```

<aside class="notes">
- cloud-init
- users.users.gotha ssh key 
- here are only base packages but you can have fully featured nixos
</aside>

---

## [deploy-rs](https://github.com/serokell/deploy-rs)

```nix
  inputs.deploy-rs.url = "github:serokell/deploy-rs";

  outputs = { self, nixpkgs, deploy-rs }: {
     nixosConfigurations = {
       bastion = nixpkgs.lib.nixosSystem {
         system = "x86_64-linux";
       };
     };

     deploy.nodes = {
        bastion = {
          hostname = config.bastion.publicIP;
          remoteBuild = false;
          sshUser = config.bastion.username;
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos
              self.nixosConfigurations.bastion;
          };
        };
```

<aside class="notes">
- you can have full image for every node or have one template image for bootstrapping 
- and then customize with deploy-rs
- my use case is for k3s cluster - 1 master and 3 workers - slightly different configs
- entire fleet with a single flake
- notice the remoteBuild = false; 
- nix copy --to ssh://root@host /nix/store/...-nix-serv
</aside>

---

## Deploying on not (so) powerful machines

- DO droplet with 1GB RAM
- [openfest/mixos](https://github.com/openfest/mixos)
- to remoteBuild or remoteBuild = false;


<aside class="notes">
- mixios is being used at the moment
- mixos has a version that works on raspberry pi
    - building on raspberry pi would take ages
- mention that mixos os public and people are encouraged to study and improve it
</aside>

---

## Push vs pull

[cachix.org](https://www.cachix.org/) - commercial service

```sh
services = {
    nix-serve = {
      enable = true;
      package = pkgs.nix-serve-ng;
      secretKeyFile = "/var/secrets/cache-private-key.pem";
      openFirewall = true;
    };
};
```


<aside class="notes">
- mixos custom overlays that need to be compiled - takes a long time 
- enable nix-serve and make your computer a nix registry
- nix copy --to ssh://root@your-droplet-ip /nix/store/...-nix-serve
- nix effectively reduces the install problem to copying files so direction is not important
</aside>

---

## Nix on exotic OSs and noteworthy projects 

- on MS Windows via WSL [nixos-wsl](https://github.com/nix-community/NixOS-WSL) - it is tollerable
- [nixos-bsd](https://github.com/nixos-bsd/nixbsd) - unofficial fork
- [guix](https://guix.gnu.org/) - shout out to our FSF friends
- [lix](https://lix.systems/) - why dont we gradually rewrite Nix in Rust
- [tvix](https://tvix.dev/) - why dont we make nix faster (by writing it in Rust)
- [determinite nix](https://docs.determinate.systems/determinate-nix/) - nix for the enterprise

<aside class="notes">
- guix uses guile (scheme) and is not compatible with nix anymore
- guix is more political more focused on software freedom 
- Eelco Dolstra works in Determinite Systems 
- Determinite Nix has some nice features like - not breaking on every osx install
</aside>

---

## How to start with nix?

Get your hands dirty:

- create a flake.nix with some tools - infect your friend's projects
- install home-manager on your current OS and steal somebody's [dotfiles](https://github.com/gotha/dotfiles)
- build full nixos system in VM 
- install nixos

Read some docs 
- [nix pills](https://nixos.org/guides/nix-pills/) - a series of blog posts

---


## How to get yourself really involved?

- [nixpkgs](https://github.com/NixOS/nixpkgs/)
- NixOS Foundation 
- NGI Zero

<aside class="notes">
- NGI Zero (New Generation Internet) is a European funding organization that supports NixOS
- NGI is publicly funded by the EU and tries to achieve digital sovereignty
- why taking money is necessary?
</aside>

---


## Thank you!

[github.com/gotha/building-unixlike-os-nix-way-openfest-2025-presentation](https://github.com/gotha/building-unixlike-os-nix-way-openfest-2025-presentation)

![QR](./img/qr_code.png)
