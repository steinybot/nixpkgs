{ lib, stdenv, fetchurl, pkg-config, cmake
, zlib, bzip2, libiconv, libxml2, openssl, ncurses, curl, libmilter, pcre2
, libmspack, systemd, Foundation, json_c, check
, rustc, rust-bindgen, rustfmt, cargo, python3
}:

stdenv.mkDerivation rec {
  pname = "clamav";
  version = "0.105.0";

  src = fetchurl {
    url = "https://www.clamav.net/downloads/production/${pname}-${version}.tar.gz";
    sha256 = "sha256-JwIDpUxFgEnbVPzZNoP/Wy2xkVHzY8SOgs7O/d4rNdQ=";
  };

  # Flaky test, remove this when https://github.com/Cisco-Talos/clamav/issues/343 is fixed
  patches = [ ./remove-freshclam-test.patch ];

  enableParallelBuilding = true;
  nativeBuildInputs = [ cmake pkg-config rustc rust-bindgen rustfmt cargo python3 ];
  buildInputs = [
    zlib bzip2 libxml2 openssl ncurses curl libiconv libmilter pcre2 libmspack json_c check
  ] ++ lib.optional stdenv.isLinux systemd
    ++ lib.optional stdenv.isDarwin Foundation;

  cmakeFlags = [
    "-DSYSTEMD_UNIT_DIR=${placeholder "out"}/lib/systemd"
  ];

  doCheck = true;

  meta = with lib; {
    homepage = "https://www.clamav.net";
    description = "Antivirus engine designed for detecting Trojans, viruses, malware and other malicious threats";
    license = licenses.gpl2;
    maintainers = with maintainers; [ robberer qknight fpletz globin ];
    platforms = platforms.unix;
  };
}
