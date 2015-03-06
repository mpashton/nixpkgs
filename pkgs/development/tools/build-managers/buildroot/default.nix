{ stdenv, fetchurl, graphviz, autogen, gettext, flex, bison, bc, pkgconfig, ncurses
}:

stdenv.mkDerivation rec {
  version = "2015.02";
  name = "buildroot-${version}";

  src = fetchurl {
    url = "http://www.buildroot.net/downloads/buildroot-${version}.tar.bz2";
    sha256 = "0pbn0whr61axrp9nkldqr7rvw29q90h505d8nyqlh2jf80pbpk8h";
  };

  buildroot-init-sh = ./buildroot-init.sh;
  
  builder = builtins.toFile "builder.sh" ''
    source $stdenv/setup

    mkdir -p $out/bin
    cp ${buildroot-init-sh} $out/bin/buildroot-init
    sed -i s/BUILDROOT-VERSION/${version}/g $out/bin/buildroot-init
    sed -i s#BUILDROOT-SOURCE#$src#g $out/bin/buildroot-init
    chmod +x $out/bin/buildroot-init
  '';
  
  meta = {
    homepage = "http://www.buildroot.net/";
    description = "Linux root filesystem builder";
    platforms = stdenv.lib.platforms.all;
  };
}

