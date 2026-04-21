#!/bin/bash
Packages=(
      Base
	  BaseServer
      S7Plus
      codemeter
     )

help () {

	echo "usage: $(basename $0) srcdir builddir outdir [version]"
	echo "the builddir must not exist, it will be created during the process"
	echo "optional version parameter replaces the string <VERSION> in removeFileList.txt"
}

repackageDebianPackage () {
	local package="$1"
	local filepath="$2"
	local removeFileList="$3"
	local removeDepsList="$4"
	local builddir="$5"
	local outdir="$6"
	local filename=${filepath##*/}
    
	echo "repackage $filepath to $outdir/$filename"
	mkdir -p "$builddir/package/DEBIAN" && \
    cd "$builddir" && \
	dpkg-deb -x "$filepath" package/ && \
	dpkg-deb -e "$filepath" package/DEBIAN && \
	for f in $(cat "$removeFileList") ; do rm -rf $builddir/package/$f; done && \
	for f in $(cat "$removeDepsList") ; do sed -i "s/$f[^,]*, //" $builddir/package/DEBIAN/control; done && \
	cat $builddir/package/DEBIAN/control && \
	dpkg-deb -Z xz --nocheck -b package/ "$outdir/$filename"

	rm -rf "$builddir/package"
}


if [ $# -lt 3 ] ;
then
	help
	exit 1
fi

scriptdir="$(dirname "$(readlink -f "$0")")"
srcdir="$1"
builddir="$2"
outdir="$3"

echo Using $scriptdir as scriptdir
if [ -d "$srcdir" ] ; then
  echo Using $srcdir as sourcedir
else
  echo $srcdir does not exist
  exit 2
fi

if [ -d "$outdir" ] ; then
  echo Using $outdir as outputdir
else
  echo $outdir does not exist, creating it
  mkdir -p $outdir
fi

if [ -d "$builddir" ] ; then
  echo $builddir already exists, please remove it before starting the script
  exit 3
else
  echo Creating $builddir
  mkdir -p $builddir
fi

if [ $# -ge 4 ] ;
then
  sed "s/<VERSION>/$4/g" $scriptdir/removeFileList.txt > $builddir/removeFileList.txt
else
  cp $scriptdir/removeFileList.txt $builddir/removeFileList.txt
fi

for Package in ${Packages[*]}
do
	filenames=$srcdir/*$Package*.deb
	echo $filenames
	
	for filename in $filenames
    do
	  repackageDebianPackage $Package $filename $builddir/removeFileList.txt $scriptdir/removeDepsList.txt $builddir $outdir
    done

done

rm -rf $builddir
