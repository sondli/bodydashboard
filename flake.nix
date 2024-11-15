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
			postgres = {
				container-name = "bodydashboard-dev";
				db-name = "bodydashboard-dev";
				user = "postgres";
				password = "postgres";
				port = "5432";
			};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          elixir
          docker
          postgresql
        ];
        shellHook = ''
          echo "BodyDashboard dev environment loaded!"
          
          # Check if Docker is running
          if ! docker info >/dev/null 2>&1; then
            echo "Error: Docker daemon is not running. Please start Docker first."
            exit 1
          fi

          echo "Checking PostgreSQL container..."
          
          # Check if container exists (running or stopped)
          if docker ps -a -q -f name=${postgres.container-name} | grep . >/dev/null; then
            # Container exists, check if it's running
            if docker ps -q -f name=${postgres.container-name} | grep . >/dev/null; then
              echo "PostgreSQL container is already running"
            else
              echo "Starting existing PostgreSQL container..."
              docker start ${postgres.container-name}
            fi
          else
            echo "Creating new PostgreSQL container..."
            docker run -d \
              --name ${postgres.container-name} \
              -e POSTGRES_USER=${postgres.user} \
              -e POSTGRES_PASSWORD=${postgres.password} \
              -e POSTGRES_DB=${postgres.db-name} \
              -p ${postgres.port}:5432 \
              postgres:15
          fi
        '';
      };
    };
}
