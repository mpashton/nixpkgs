
=================
RealVNC for NixOS
=================

Michael Ashton <data@gtf.org>
August 2013

*NOTICE: This expression is still in a basic, experimental form, and is fit only for bold adventurers.  See 'bugs' below for the list of issues.*

This expression installs RealVNC 5.0.5.  It runs on Intel 32-bit x86, and should run on x86-64 Linux (not yet tested).  Although RealVNC is, of course, not free software, at this writing it appears to be the best maintained and best performing VNC server available for Unix.

The expression uses the 'generic Linux' RealVNC package.  This is only obtainable after registering with RealVNC.  It cannot be downloaded automatically.  Therefore, to use this expression, you must download the package manually from http://www.realvnc.com/.  If you attempt to install the expression first, it will tell you which file to download, and it will suggest nix-prefetch-url to add the file to the store.

Once you have installed the package, you need to get a license from RealVNC to run it.  The result of this process will be a key string.  Activate it by running:

    vnclicense --add <key>

You should then be able to run the server from a user account:

    vncserver-virtual

Bugs
----

* Not yet tested on 64-bit systems
* OpenGL support not tested at all
* Probably conflicts with other VNC packages; need a priority setting
* Viewer and daemon not tested
* vncserver-virtual complains of not being able to find get_primary_ip4 script (seems to be harmless)
* Font linking throws errors (apparently harmless, but annoying)
* Probably loads more

Future
------

* Specify license key in configuration
* Run vncinstall as part of build process
* Implement as a systemd service

Theory of operation
-------------------

Many of the binaries in the RealVNC suite require files to be located at paths which cannot exist on a typical NixOS system.  This is dealt with using the LD_PRELOAD trick: certain library calls dealing with paths are intercepted and redirected using a shared library loaded through LD_PRELOAD.  The source for this library is preload.c.

Only vncserver-virtual is not wrapped.  This program calls xauth, which, for reasons unknown, crashes when wrapped with preload.c.  The main consequence of this is a warning from vncserver-virtual that it is not able to find the script "/etc/vnc/get_primary_ip4".  This appears to be harmless.

The redirected paths are:

- /usr/share/vnc becomes $out/share/realvnc
- /etc/vnc becomes $home/.vnc -- this causes vnclicense to write the license key to ~/.vnc/licensekey.
- /usr/X11R6/lib/X11 becomes $out/share/realvnc/X11 -- this contains several X11-related directories which Xvnc requires, particularly the fonts directory; Xvnc will not start if it cannot find the font 'fixed'.

Xvnc expects a traditional X11 fonts directory at startup.  As this is not readily available on NixOS, we construct one using the fontDirectories variable.

Thanks
------

I am especially grateful to Bjorn Forsman, who suggested the use of LD_PRELOAD and directed me to examples of its use in NixOS.
