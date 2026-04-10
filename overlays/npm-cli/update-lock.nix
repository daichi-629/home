{ writeShellApplication, nodejs_22 }:

{
  name,
  overlayName,
  overlayRootEnvVar,
  packageName,
}:

writeShellApplication {
  inherit name;
  runtimeInputs = [ nodejs_22 ];
  text = ''
    overlay_root="$(printenv ${overlayRootEnvVar} || true)"
    if [ -z "$overlay_root" ]; then
      if [ -f "$PWD/overlays/${overlayName}/package.json" ]; then
        overlay_root="$PWD/overlays/${overlayName}"
      else
        overlay_root="$PWD"
      fi
    fi
    cd "$overlay_root"
    if [ ! -f package.json ]; then
      echo "Run from overlays/${overlayName} or set ${overlayRootEnvVar}." >&2
      exit 1
    fi
    version="$(node -p 'require("./package.json").dependencies["${packageName}"]')"
    npm install --package-lock-only --lockfile-version=2 --ignore-scripts
    mkdir -p versions
    mv package-lock.json "versions/package-lock_''${version}.json"
  '';
}
