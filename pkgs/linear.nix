# Linear App for Linux
# Electron wrapper for linear.app web application
# Can be submitted to nixpkgs as an unofficial Linux client
{ lib
, stdenv
, fetchFromGitHub
, makeWrapper
, makeDesktopItem
, electron
, nodejs
, copyDesktopItems
}:

let
  pname = "linear";
  version = "0.2.3";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "selimaj-dev";
    repo = "linear-linux";
    rev = "v${version}";
    sha256 = "sha256-kE2PNEh2a1dC6yXyXTbHaF5c++30j96RYpdVnKQJAoM=";
  };

  nativeBuildInputs = [
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    electron
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "linear";
      desktopName = "Linear";
      comment = "Issue tracking for modern software teams";
      exec = "linear %U";
      icon = "linear";
      categories = [ "Office" "ProjectManagement" ];
      startupWMClass = "Linear";
    })
  ];

  installPhase = ''
    runHook preInstall

    # Create app directory
    mkdir -p $out/lib/linear
    cp -r src/* $out/lib/linear/ 2>/dev/null || cp -r . $out/lib/linear/

    # Create wrapper script
    mkdir -p $out/bin
    makeWrapper ${electron}/bin/electron $out/bin/linear \
      --add-flags "$out/lib/linear" \
      --add-flags "--enable-features=UseOzonePlatform" \
      --add-flags "--ozone-platform=wayland"

    # Install icon (if available in source, otherwise create placeholder)
    mkdir -p $out/share/icons/hicolor/256x256/apps
    if [ -f assets/icon.png ]; then
      cp assets/icon.png $out/share/icons/hicolor/256x256/apps/linear.png
    elif [ -f icon.png ]; then
      cp icon.png $out/share/icons/hicolor/256x256/apps/linear.png
    fi

    runHook postInstall
  '';

  meta = with lib; {
    description = "Linear - Issue tracking for modern software teams (unofficial Linux client)";
    homepage = "https://linear.app";
    license = licenses.unfree;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "linear";
  };
}
