#!/bin/sh

usage() {
echo "
buildroot-init [ --help ] <path>

Unpacks buildroot to <path>.  The result is ready for make menuconfig / make.  Extra dependencies may be required to build certain Buildroot packages.

Buildroot version is BUILDROOT-VERSION.
" |fmt
}

case "$1" in
  --help)
    usage
    exit 0
    ;;
esac

outpath=$1

if [[ x$outpath == x ]]
then
  usage
  exit 1
fi

mkdir $outpath
tar xjf "BUILDROOT-SOURCE" --strip-components=1 -C $outpath

shift

exit 0

