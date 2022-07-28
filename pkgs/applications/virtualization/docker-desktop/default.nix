{ stdenv, fetchurl, lib,
  # Darwin dependencies
  stdenvNoCC, undmg,
  # Linux dependencies
  dpkg, autoPatchelfHook, wrapGAppsHook,
  gtk3, atk, at-spi2-atk, cairo, pango, gdk-pixbuf, glib, freetype, fontconfig,
  dbus, libX11, xorg, libXi, libXcursor, libXdamage, libXrandr, libXcomposite,
  libXext, libXfixes, libXrender, libXtst, libXScrnSaver, nss, nspr, alsa-lib,
  cups, expat, libuuid, at-spi2-core, libappindicator-gtk3, mesa, libcap_ng,
  libseccomp
}:

let
  # https://desktop.docker.com/linux/main/amd64/appcast.xml
  # https://desktop.docker.com/linux/main/arm64/appcast.xml
  # https://desktop.docker.com/mac/main/amd64/appcast.xml
  # https://desktop.docker.com/mac/main/arm64/appcast.xml
  version = "4.10.1";
  buildNumber = "82475";
  sources = {
    x86_64-linux = {
      url = "https://desktop.docker.com/linux/main/amd64/${buildNumber}/docker-desktop-${version}-amd64.deb";
      sha256 = "sha256-k2O8WER4xcdlQAS6y1FCnCdbWKho70PDvGJJ1YROxb4=";
    };
    aarch64-linux = {
      url = "https://desktop.docker.com/linux/main/arm64/${buildNumber}/docker-desktop-${version}-amd64.deb";
      sha256 = "sha256-KMs3uFfDt1Guj695aBGmi2fmK0m+Scwszja0FRQsYvA=";
    };
    x86_64-darwin = {
      url = "https://desktop.docker.com/mac/main/amd64/${buildNumber}/Docker.dmg";
      sha256 = "sha256-KMs3uFfDt1Guj6950BGmi2fmKfm+Scwszja8FRQsYvA=";
    };
    aarch64-darwin = {
      url = "https://desktop.docker.com/mac/main/arm64/${buildNumber}/Docker.dmg";
      sha256 = "sha256-q/gauZMB4a8Oa0lmveLLMPK7arU30VpCy9SrbmpaPZ0=";
    };
  };
in stdenvNoCC.mkDerivation {
  inherit version;

  pname = "docker-desktop";

  src = fetchurl sources.${stdenvNoCC.hostPlatform.system};

  sourceRoot = ".";

  nativeBuildInputs = if stdenv.isDarwin then [ undmg ] else
    [ autoPatchelfHook dpkg wrapGAppsHook ];

  buildInputs = lib.optionals stdenv.isLinux [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libX11
    libXScrnSaver
    libXcomposite
    libXcursor
    libXdamage
    libXext
    libXfixes
    libXi
    libXrandr
    libXrender
    libXtst
    libappindicator-gtk3
    libcap_ng
    libseccomp
    libuuid
    mesa # for libgbm
    nspr
    nss
    pango
    xorg.libxcb
    xorg.libxshmfence
  ];

  unpackPhase = lib.optional stdenv.isLinux "dpkg-deb -x $src .";

  installPhase = if stdenv.isDarwin then ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -r 'Docker.app' "$out/Applications"

    runHook postInstall
  ''
  else ''
    runHook preInstall

    mkdir -p $out/lib

    mv opt/docker-desktop $out/lib/docker-desktop

    mv usr/share $out/share
    mv usr/lib/docker $out/lib/docker
    mv usr/lib/systemd $out/lib/systemd
    substituteInPlace $out/lib/systemd/user/docker-desktop.service --replace /opt/docker-desktop/bin/com.docker.backend $out/lib/docker-desktop/bin/com.docker.backend

    mkdir -p $out/bin
    ln -s $out/lib/docker-desktop/bin/docker-desktop $out/bin/docker-desktop

    runHook postInstall
  '';

  meta = {
    description = "Docker Desktop – the fastest way to containerize applications.";
    homepage = "https://www.docker.com/products/docker-desktop/";
    license = {
      fullName = "Docker Subscription Service Agreement";
      url = "https://www.docker.com/legal/docker-software-end-user-license-agreement/";
      free = false;
    };
    maintainers = with lib.maintainers; [ steinybot teutat3s ];
    platforms = [ "x86_64-darwin" "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];
  };
}
