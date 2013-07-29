{ stdenv, requireFile, patchelf
, libX11, libXext, libICE, libXtst, libXi, libSM, xorgserver
, cups
, xkbcomp, xkeyboard_config
, fontDirectories, fontutil, libgcrypt, gnutls, pam
, fixesproto, damageproto, xcmiscproto, bigreqsproto, randrproto, renderproto
, fontsproto, videoproto, compositeproto, scrnsaverproto, resourceproto
, libxkbfile, libXfont, libXft, libXinerama
, xineramaproto, libXcursor
}:

let vncversion = "5.0.5";
    vncplatform = if stdenv.system == "i686-linux" then "x86" 
                else if stdenv.system == "x86_64-linux" then "x64"
                else throw "realvnc is available only for 32-bit or 64-bit Linux";
    interpreter = if stdenv.system == "i686-linux" then "ld-linux.so.2"
                else "ld-linux-x86-64.so.2";
    packagename = "VNC-${vncversion}-Linux-${vncplatform}-ANY.tar.gz";
in

stdenv.mkDerivation rec {
  version = vncversion;
  name = "realvnc-${vncversion}";
  src = requireFile {
    message = ''
      The installation package for RealVNC cannot be downloaded automatically.
      For this system, the name of the correct installation package file is:

          ${packagename}

      This file can be found in the download section at http://www.realvnc.com/.
      Once it is downloaded, execute

          nix-prefetch-url file:///\$PWD/${packagename}
    '';
    name = packagename;
    sha256 = if stdenv.system == "i686-linux"
             then "1cwgcl5w3c8anln8i47p7pacp8syrb28n1nryyf2m8q5nmxwcbi5"
             else "1272x2rpp6fpn7rzqdm6dqhhxasbaxnbpa2c4n7zmcc78anqf1y1";
  };

  phases = "unpackPhase installPhase";
  buildInputs = [ patchelf ];
  dontStrip = true;
  dontPatchElf = true;

  installPhase = ''
    binaries="vncaddrbook vncchat vnclicense vnclicensewiz vncpasswd vncpipehelper vncserverui vncserver-virtual vncserver-virtuald vncserver-x11 vncserver-x11-core vncserver-x11-serviced vncviewer Xvnc Xvnc-core"

    mkdir -p $out/bin
    for i in $binaries ; do
      cp $i $out/bin
      patchelf --set-interpreter ${stdenv.glibc}/lib/${interpreter} --set-rpath ${libX11}/lib:${libXext}/lib:${libSM}/lib:${stdenv.gcc.gcc}/lib64:${stdenv.gcc.gcc}/lib $out/bin/$i
    done

    mkdir -p $out/lib/vnc
    cp vncelevate get_primary_ip4 $out/lib/vnc

    manpath=$out/share/man/man1
    mkdir -p $manpath
    for i in *.man ; do
      cp $i $manpath/$(basename -s .man $i).1
    done

    mkdir -p $out/share/vnc
    cp rgb.txt $out/share/vnc

    mkdir -p $out/share/vnc/fonts
    cp fonts/* $out/share/vnc/fonts
  '';

  meta = {
    homepage = http://www.realvnc.com/;
    license = "unfree";
    description = "Commercial VNC server from the authors of the original VNC";
    #maintainers = with stdenv.lib.maintainers;
    platforms = with stdenv.lib.platforms; linux;
  };
}
