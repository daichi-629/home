{
  curl,
  jq,
  nix,
  writeShellApplication,
}:

writeShellApplication {
  name = "update-antigravity-sources";
  runtimeInputs = [
    curl
    jq
    nix
  ];
  text = ''
    set -euo pipefail

    overlay_root="$(printenv ANTIGRAVITY_OVERLAY_ROOT || true)"
    if [ -z "$overlay_root" ]; then
      if [ -f "$PWD/overlays/antigravity/sources.json" ]; then
        overlay_root="$PWD/overlays/antigravity"
      else
        overlay_root="$PWD"
      fi
    fi

    sources_json="$overlay_root/sources.json"
    if [ ! -f "$sources_json" ]; then
      echo "Run from overlays/antigravity or set ANTIGRAVITY_OVERLAY_ROOT." >&2
      exit 1
    fi

    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT

    manifest_base="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests"

    jq -r 'to_entries[] | [.key, .value.manifestPlatform] | @tsv' "$sources_json" |
      while IFS="$(printf '\t')" read -r nix_system manifest_platform; do
        manifest="$(curl -fsSL "$manifest_base/$manifest_platform.json")"
        version="$(jq -r '.version' <<< "$manifest")"
        url="$(jq -r '.url' <<< "$manifest")"
        sha512="$(jq -r '.sha512' <<< "$manifest")"
        hash="$(nix hash to-sri --type sha512 "$sha512" 2>/dev/null)"

        jq \
          --arg nix_system "$nix_system" \
          --arg manifest_platform "$manifest_platform" \
          --arg version "$version" \
          --arg url "$url" \
          --arg sha512 "$sha512" \
          --arg hash "$hash" \
          '.[$nix_system] = {
            manifestPlatform: $manifest_platform,
            version: $version,
            url: $url,
            sha512: $sha512,
            hash: $hash
          }' \
          "$sources_json" > "$tmp"
        mv "$tmp" "$sources_json"
      done

    jq --sort-keys . "$sources_json" > "$tmp"
    mv "$tmp" "$sources_json"
  '';
}
