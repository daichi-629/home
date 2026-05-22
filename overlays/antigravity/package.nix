{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  sources = lib.importJSON ./sources.json;
  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported Antigravity CLI platform: ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "antigravity-cli";
  inherit (source) version;

  src = fetchurl {
    inherit (source) url hash;
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    install -m755 antigravity "$out/bin/agy"

    runHook postInstall
  '';

  meta = {
    description = "Google Antigravity CLI";
    homepage = "https://antigravity.google/product/antigravity-cli";
    mainProgram = "agy";
    platforms = builtins.attrNames sources;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
