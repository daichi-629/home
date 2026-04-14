{
  lib,
  buildNpmPackage,
  importNpmLock,
  makeWrapper,
  nodejs_22,
}:

{
  pname,
  src,
  packageName,
  packageLockFile,
  binName ? pname,
  binPath,
  description,
  homepage,
  license ? lib.licenses.asl20,
  mainProgram ? binName,
  npmFlags ? [ ],
}:

let
  basePackageJson = lib.importJSON (src + "/package.json");
  packageLock = lib.importJSON packageLockFile;
  version = packageLock.packages.${"node_modules/${packageName}"}.version;
  packageJson = basePackageJson // {
    dependencies = basePackageJson.dependencies // {
      ${packageName} = version;
    };
  };
in
buildNpmPackage {
  inherit pname version src;
  inherit npmFlags;

  nodejs = nodejs_22;
  npmDeps = importNpmLock {
    npmRoot = src;
    package = packageJson;
    inherit packageLock;
  };
  npmConfigHook = importNpmLock.npmConfigHook;

  nativeBuildInputs = [ makeWrapper ];

  dontNpmBuild = true;
  dontNpmPrune = true;

  package = builtins.toJSON packageJson;
  packageLock = builtins.toJSON packageLock;
  passAsFile = [
    "package"
    "packageLock"
  ];

  postPatch = ''
    cp --no-preserve=mode "$packagePath" package.json
    cp --no-preserve=mode "$packageLockPath" package-lock.json
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/node_modules" "$out/bin"
    cp -r node_modules "$out/lib/"
    rm -f "$out/lib/node_modules/.package-lock.json"

    makeWrapper "${nodejs_22}/bin/node" "$out/bin/${binName}" \
      --add-flags "$out/lib/node_modules/${packageName}/${binPath}"

    runHook postInstall
  '';

  passthru = {
    inherit packageName packageJson packageLockFile;
  };

  meta = {
    inherit description homepage license mainProgram;
    platforms = lib.platforms.all;
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
  };
}
