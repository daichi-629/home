final: prev:

let
  version = "0.111.0";
  src = ../pkgs/codex;
in
{
  codex = final.buildNpmPackage {
    pname = "codex";
    inherit version src;

    nodejs = final.nodejs_22;
    npmDeps = final.importNpmLock { npmRoot = src; };
    npmConfigHook = final.importNpmLock.npmConfigHook;

    nativeBuildInputs = [ final.makeWrapper ];

    dontNpmBuild = true;
    dontNpmPrune = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/lib/node_modules" "$out/bin"
      cp -r node_modules "$out/lib/"

      makeWrapper "${final.nodejs_22}/bin/node" "$out/bin/codex" \
        --add-flags "$out/lib/node_modules/@openai/codex/bin/codex.js"

      runHook postInstall
    '';

    meta = with final.lib; {
      description = "OpenAI Codex CLI";
      homepage = "https://www.npmjs.com/package/@openai/codex";
      license = licenses.asl20;
      mainProgram = "codex";
      platforms = platforms.all;
      sourceProvenance = with sourceTypes; [ binaryBytecode ];
    };
  };
}
