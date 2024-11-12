{
  description = "Development environment for BodyDashboard";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          (pkgs.dotnetCorePackages.sdk_9_0)
        ];

        shellHook = ''
					echo "BodyDashboard dev environment loaded!"
        '';
      };
    };
}
