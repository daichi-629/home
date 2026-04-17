{ pkgs, ... }:
{
  updateNpmOverlays = pkgs.writeShellApplication {
    name = "update-npm-overlays";
    runtimeInputs = [
      pkgs.git
      pkgs.nodejs_22
    ];
    text = ''
      set -euo pipefail

      repo_root="$(${pkgs.git}/bin/git rev-parse --show-toplevel)"
      overlays_root="$repo_root/overlays"

      discover_overlays() {
        local dir

        for dir in "$overlays_root"/*; do
          [ -d "$dir" ] || continue
          [ -f "$dir/package.json" ] || continue
          [ -f "$dir/update-lock.nix" ] || continue
          basename "$dir"
        done
      }

      resolve_package_name() {
        local package_json="$1"

        node -e '
          const pkg = require(process.argv[1]);
          const deps = pkg.dependencies ?? {};
          const names = Object.keys(deps);

          if (names.length !== 1) {
            console.error(
              "Expected exactly one dependency in " + process.argv[1] + ", found " + names.length + "."
            );
            process.exit(1);
          }

          console.log(names[0]);
        ' "$package_json"
      }

      resolve_package_version() {
        local package_json="$1"
        local package_name="$2"

        node -p "require(process.argv[1]).dependencies[process.argv[2]]" "$package_json" "$package_name"
      }

      update_package_json_version() {
        local package_json="$1"
        local package_name="$2"
        local version="$3"

        node -e '
          const fs = require("fs");
          const [packageJsonPath, packageName, version] = process.argv.slice(1);
          const pkg = JSON.parse(fs.readFileSync(packageJsonPath, "utf8"));

          pkg.dependencies[packageName] = version;

          fs.writeFileSync(packageJsonPath, JSON.stringify(pkg, null, 2) + "\n");
        ' "$package_json" "$package_name" "$version"
      }

      if [ "$#" -gt 0 ]; then
        overlays=("$@")
      else
        mapfile -t overlays < <(discover_overlays)
      fi

      if [ "''${#overlays[@]}" -eq 0 ]; then
        echo "No npm overlays found." >&2
        exit 1
      fi

      for overlay in "''${overlays[@]}"; do
        overlay_root="$overlays_root/$overlay"
        package_json="$overlay_root/package.json"

        if [ ! -f "$package_json" ] || [ ! -f "$overlay_root/update-lock.nix" ]; then
          echo "Skipping $overlay: not an npm overlay under overlays/." >&2
          continue
        fi

        package_name="$(resolve_package_name "$package_json")"
        current_version="$(resolve_package_version "$package_json" "$package_name")"
        latest_version="$(npm view "$package_name" version)"

        if [ "$current_version" = "$latest_version" ]; then
          echo "$overlay: $package_name already at $latest_version"
          continue
        fi

        echo "$overlay: $package_name $current_version -> $latest_version"
        update_package_json_version "$package_json" "$package_name" "$latest_version"

        (
          cd "$overlay_root"
          npm install --package-lock-only --lockfile-version=2 --ignore-scripts
          mkdir -p versions
          mv -f package-lock.json "versions/package-lock_$latest_version.json"
        )
      done
    '';
  };
}
