{
  description = "Home Manager configuration of dmtst";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs_unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    sops-nix={
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rustowl-flake = {
      url = "github:nix-community/rustowl-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-overlay = {
      url = "github:ryoppippi/nix-claude-code";
    };
    codex-overlay = {
      url = "path:./overlays/codex";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gemini-overlay = {
      url = "path:./overlays/gemini";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    playwright-overlay = {
      url = "path:./overlays/playwright";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    my_secrets = {
      url = "git+ssh://git@github.com/daichi-629/home-secrets";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      rustowl-flake,
      claude-overlay,
      codex-overlay,
      gemini-overlay,
      playwright-overlay,
      home-manager,
      nix-darwin,
      nixvim,
      nixpkgs_unstable,
      my_secrets,
      sops-nix,
      ...
    }:
    let
      lib = nixpkgs.lib;
      overlays = [
        rust-overlay.overlays.default
        rustowl-flake.overlays.default
        codex-overlay.overlays.default
        gemini-overlay.overlays.default
        playwright-overlay.overlays.default
        claude-overlay.overlays.default
      ];
      hostIdentities = my_secrets.lib.my.hosts;
      hostSettings = {
        "1" = {
          system = "x86_64-linux";
        };
        "2" = {
          system = "x86_64-linux";
        };
        "3" = {
          system = "x86_64-linux";
        };
        "4" = {
          system = "aarch64-darwin";
        };
      };
      mkCommonHomeModules =
        {
          hostId,
          username,
          homeDirectory,
          system,
        }:
        [
          sops-nix.homeManagerModules.sops
          my_secrets.homeManagerModules.my.emails
          nixvim.homeModules.nixvim
          ./home/common.nix
          {
            home.username = username;
            home.homeDirectory = homeDirectory;
            home.packages = [
              self.packages.${system}.update-all
              self.packages.${system}.update-pins
            ];
          }
        ];
      mkHomeModules =
        {
          hostId,
          username,
          homeDirectory,
          system,
        }:
        (mkCommonHomeModules {
          inherit hostId username homeDirectory system;
        })
        ++ [ (./home/hosts + "/${hostId}.nix") ];
      mkHome =
        {
          hostId,
          hostName,
          system,
          username,
        }:
        let
          homeDirectory =
            if lib.hasSuffix "darwin" system then "/Users/${username}" else "/home/${username}";
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system overlays;
            config = {
              allowUnfree = true;
            };
          };

          modules = mkHomeModules {
            inherit hostId username homeDirectory system;
          };
          extraSpecialArgs = {
            pkgs_unstable = import nixpkgs_unstable {
              inherit system;
              config = {
                allowUnfree = true;
              };
            };
            inherit sops-nix self hostId;
          };
        };
      mkDarwin =
        {
          hostId,
          hostName,
          system,
          username,
        }:
        let
          homeDirectory = "/Users/${username}";
        in
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit hostId username;
            hmCommonModules = mkCommonHomeModules {
              inherit hostId username homeDirectory system;
            };
          };
          modules = [
            home-manager.darwinModules.home-manager
            (./home/hosts + "/${hostId}.nix")
            {
              nixpkgs = {
                inherit overlays;
                config.allowUnfree = true;
                hostPlatform = system;
              };

              system.stateVersion = 6;
              system.primaryUser = username;
              users.users.${username}.home = homeDirectory;

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                pkgs_unstable = import nixpkgs_unstable {
                  inherit system;
                  config = {
                    allowUnfree = true;
                  };
                };
                inherit sops-nix self hostId;
              };
            }
          ];
        };
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      homeConfigurations = lib.mapAttrs' (
        hostId: hostSettingsForId:
        let
          identity =
            hostIdentities.${hostId}
              or (throw "Missing host identity for host id ${hostId} in secrets-home-manager");
        in
        lib.nameValuePair "${identity.username}@${identity.hostName}" (mkHome {
          inherit hostId;
          inherit (hostSettingsForId) system;
          inherit (identity) hostName username;
        })
      ) (lib.filterAttrs (_: hostSettingsForId: !(lib.hasSuffix "darwin" hostSettingsForId.system)) hostSettings);
      darwinConfigurations = lib.mapAttrs' (
        hostId: hostSettingsForId:
        let
          identity =
            hostIdentities.${hostId}
              or (throw "Missing host identity for host id ${hostId} in secrets-home-manager");
        in
        lib.nameValuePair identity.hostName (mkDarwin {
          inherit hostId;
          inherit (hostSettingsForId) system;
          inherit (identity) hostName username;
        })
      ) (lib.filterAttrs (_: hostSettingsForId: lib.hasSuffix "darwin" hostSettingsForId.system) hostSettings);
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          updatePins = (import ./scripts/update-pin.nix { inherit pkgs self; }).updatePins;
          bootstrapNewDevice =
            (import ./scripts/bootstrap-new-device.nix {
              inherit pkgs self;
            }).bootstrapNewDevice;
          updateAll =
            (import ./scripts/update-all.nix {
              inherit hostIdentities pkgs updatePins;
            }).updateAll;
        in
        {
          bootstrap-new-device = bootstrapNewDevice;
          update-all = updateAll;
          update-pins = updatePins;
        }
      );
      apps = forAllSystems (system: {
        bootstrap-new-device = {
          type = "app";
          program = "${self.packages.${system}.bootstrap-new-device}/bin/bootstrap-new-device";
        };
        update-all = {
          type = "app";
          program = "${self.packages.${system}.update-all}/bin/update-all";
        };
        update-pins = {
          type = "app";
          program = "${self.packages.${system}.update-pins}/bin/update-pins";
        };
      });
    };
}
