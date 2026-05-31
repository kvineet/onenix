{
  pkgs,
  lib,
}:
let
  version = "1.3.6";
  pname = "amethyst";

  src = pkgs.fetchurl {
    url = "https://github.com/ChrisDKN/Amethyst-Mod-Manager/releases/download/v${version}/AmethystModManager-${version}-x86_64.AppImage";
    hash = "sha256-0f3i0c8pkwq1xx6qpf183v0b5a0hjl32b860wf29lqf0jlimyjgh";
  };

  appimageContents = pkgs.appimageTools.extractType1 { inherit pname version src; };
in
pkgs.appimageTools.wrapType2 rec {
  inherit pname version src;

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/amethyst-mod-manager.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/amethyst-mod-manager.desktop \
      --replace-fail "Exec=AppRun" "Exec=${pname}"
    cp -r ${appimageContents}/share/icons $out/share/2>/dev/null || true
  '';

  meta = with lib; {
    description = "Amethyst - Linux Mod Manager";
    homepage = "https://github.com/ChrisDKN/Amethyst-Mod-Manager/";
    downloadPage = "https://github.com/ChrisDKN/Amethyst-Mod-Manager/releases";
    license = lib.licenses.asl20;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ onny ];
    platforms = [ "x86_64-linux" ];
  };
}
