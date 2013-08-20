#!/bin/bash

if [ $# != 2 ] ; then
  echo "Usage: command ARCH "
  echo "Available commands: chroot unchroot mergeimg"
  echo "Supported ARCH types: x86 amd64"
  
  exit 1;

fi

_ARCH=$2
CHRDIR=/opt/deb_$_ARCH
TMPDIR=/tmp/deb_chroot.tmp/$_ARCH
FSIMG_LOCATION=debian_chroot
ROOTFS_IMG=${FSIMG_LOCATION}/sid_${_ARCH}.fs
SHM_MAXSIZE="2G"

_ROOTFS=$TMPDIR/squashfs
_AUFSSHM=$TMPDIR/shm


set -e

if [ $1 == "chroot" ] ; then
  sudo bash -c "
    set -e
    mkdir -v $CHRDIR
    mkdir -vp $_ROOTFS $_AUFSSHM
    mount -vt squashfs $ROOTFS_IMG $_ROOTFS -o loop
    mount -vt tmpfs tmpfs $_AUFSSHM -o rw,size=$SHM_MAXSIZE
    mount -vt aufs -o nowarn_perm,br:$_AUFSSHM=rw:$_ROOTFS=rr debchroot.$_ARCH $CHRDIR
    set +e
    mkdir -v $CHRDIR/{svr,proc,tmp}
    set -e
    mount -vt proc proc $CHRDIR/proc
    mount -vo bind $HOME $CHRDIR/svr
    chroot $CHRDIR /bin/login $USER"

elif [ $1 == "unchroot" ] ; then
  sudo bash -c "
    set -e
    umount -vl $CHRDIR/svr $CHRDIR/proc
    umount -vl $CHRDIR
    umount -vl $_ROOTFS
    umount -vl $_AUFSSHM
    rm -dv $_ROOTFS $_AUFSSHM $TMPDIR $CHRDIR"

elif [ $1 == "mergeimg" ] ; then
  sudo mksquashfs $CHRDIR ${ROOTFS_IMG}.new -comp xz -e svr proc tmp

else
  echo "Unknown command: $1"
  
  exit 1

fi

