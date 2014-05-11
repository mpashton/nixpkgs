{ config, pkgs, stdenv, fetchurl, patchelf, avahi }:

assert stdenv.system == "x86_64-linux" || stdenv.system == "i686-linux";
with pkgs.lib;

stdenv.mkDerivation rec {
  version = "0.9.8.10.215-020456b";
  debversion = version;
  product = "plexms";
  name    = "${product}-${version}";

  src = if stdenv.system == "x86_64-linux"
    then fetchurl {
      url    = "http://downloads.plexapp.com/plex-media-server/${debversion}/plexmediaserver_${debversion}_amd64.deb";
      sha256 = "0m9spw74cy9cah9rad4xz4fwvqj1d7aws83dssd7mc87swkdlsji";
    }
    else fetchurl {
      url    = "http://downloads.plexapp.com/plex-media-server/${debversion}/plexmediaserver_${debversion}_i386.deb";
      sha256 = "180vkczb9jfbhflbvxsnsfwb1yfbvhpq4fh850mlqccb8269cnvd";
    };

  unpackPhase = ''
    ar vx ${src}
    tar xf data.tar.gz
  '';

  buildInputs = [ patchelf ];

  buildPhase = ''
    runpath="$out/usr/lib/plexmediaserver:${stdenv.gcc.libc}/lib:${stdenv.gcc.gcc}/lib"
    topatch=( "usr/lib/plexmediaserver/Plex Media Server" \
              "usr/lib/plexmediaserver/Plex DLNA Server" \
              "usr/lib/plexmediaserver/Plex Media Scanner" \
              "usr/lib/plexmediaserver/Resources/Plex Transcoder" \
              "usr/lib/plexmediaserver/Resources/rsync" \
              "usr/lib/plexmediaserver/Resources/Plex New Transcoder" \
              "usr/lib/plexmediaserver/Resources/Python/bin/python" )

    for i in "''${topatch[@]}" ; do
    ls -l "$i"
    patchelf \
      --set-interpreter "$(cat $NIX_GCC/nix-support/dynamic-linker)" \
      --set-rpath "$runpath" "$i"
    done
  '';

  dontPatchELF = true;
  dontStrip    = true;

  # Without this, patchShebangs is run on everything, and it barfs on 
  # the names with spaces in them.  Instead we turn it off here and 
  # run patchShebangs explicitly on usr/sbin in the preFixup hook.  
  # usr/sbin/start_pms is the only script which needs patching anyway;
  # usr/lib/plexmediaserver/start.sh is just for testing.
  dontPatchShebangs = true;
  preFixup = ''
    patchShebangs $out/usr/sbin
  '';

  startpms = ./start_pms.sh;

  installPhase = ''
    pwd
    mkdir -p "$out"
    cp -r usr "$out"
    cp "$startpms" "$out/usr/sbin/start_pms"
    chmod 0755 "$out/usr/sbin/start_pms"
  '';

  meta = with stdenv.lib; {
    description = "Plex Media Server";
    homepage    = "http://plexapp.com";
    license     = licenses.unfree;
    #maintainers = with maintainers; [ lovek323 ];
    platforms   = platforms.linux;
  };
}
