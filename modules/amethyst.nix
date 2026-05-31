{
  lib,
  appimageTools,
  fetchurl,
}:
let
  version = "1.3.6";
  pname = "amethyst";

  src = fetchurl {
    url = "https://github.com/ChrisDKN/Amethyst-Mod-Manager/releases/download/v${version}/AmethystModManager-${version}-x86_64.AppImage";
    hash = "sha256-0f3i0c8pkwq1xx6qpf183v0b5a0hjl32b860wf29lqf0jlimyjgh";
  };

  appimageContents = appimageTools.extractType1 { inherit name src; };
in
appimageTools.wrapType2 rec {
  inherit pname version src;

  extraInstallCommands = ''
    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=${meta.mainProgram}'
  '';

  meta = {
    description = "Amethyst - Linux Mod Manager";
    homepage = "https://github.com/ChrisDKN/Amethyst-Mod-Manager/";
    downloadPage = "https://github.com/ChrisDKN/Amethyst-Mod-Manager/releases";
    license = lib.licenses.asl20;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ onny ];
    platforms = [ "x86_64-linux" ];
  };
}
