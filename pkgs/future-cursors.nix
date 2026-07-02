# Future cursors (yeyushengfan258) + Future-Cyan hyprcursor port (Pummelfisch).
# XCursor theme "Future-cursors" for GTK/XWayland, hyprcursor "Future-Cyan"
# for Hyprland's native SVG cursor rendering. Not in nixpkgs.
{ pkgs }:

let
  xcursorSrc = pkgs.fetchzip {
    url = "https://github.com/yeyushengfan258/Future-cursors/archive/587c14d2f5bd2dc34095a4efbb1a729eb72a1d36.tar.gz";
    sha256 = "09hpgc21v3c31fx65w74h5w42pnn9a18s4g5m7rifmhdmcqj08ff";
  };
  hyprcursorSrc = pkgs.fetchzip {
    url = "https://gitlab.com/Pummelfisch/future-cyan-hyprcursor/-/archive/cf4126d17f4520aceb688d8a60daca4a1f0b9e80/future-cyan-hyprcursor-cf4126d17f4520aceb688d8a60daca4a1f0b9e80.tar.gz";
    sha256 = "1237r7yjxjwpk1ln7lasq908zswld2qbvg857x64kla7clzxvckb";
  };
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "future-cursors";
  version = "unstable-2026-07-02";

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/icons/Future-cursors
    cp -r ${xcursorSrc}/dist/. $out/share/icons/Future-cursors/
    cp -r ${hyprcursorSrc}/Future-Cyan-Hyprcursor_Theme $out/share/icons/Future-Cyan
    runHook postInstall
  '';

  meta = {
    description = "Future cursor theme (xcursor) with Future-Cyan hyprcursor port";
    license = pkgs.lib.licenses.gpl3Only;
  };
}
