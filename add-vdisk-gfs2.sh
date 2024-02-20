#!/bin/bash

######################
#  add-vdisk-gfs2.sh #
######################


echo
echo "This script will add DataCore vDisk to a PVE Cluster as a GFS2"
echo
read -p "Continue? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi


echo
read -p "Enter vDisk naa (ex. 60030d9041d01a05b2c89e35133dd631) " -r
echo

naa=$REPLY

echo
read -p "Number of nodes in cluster? " -r
echo

numnodes=$REPLY

echo
read -p "IP list of nodes in cluster? ex. '10.0.0.1 10.0.0.2' " -r
echo

nodes=$REPLY


echo
read -p "vDisk Name? (ex. DC_VOL5_GFS2) DO NOT USE '-' " -r
echo

vdiskname=$REPLY

storagename=$vdiskname

for item in ${nodes}; do
     ssh $item iscsiadm -m session --rescan
     ssh $item multipath -r
     ssh $item multipath -ll
done


vdiskid=$(multipath -ll |grep $naa | sed 's/^\([^ ]*\).*/\1/')

sgdisk -N 1 /dev/mapper/$vdiskid



mnt="/mnt/pve/$vdiskname"

clustername=$(pvecm status | grep 'Name:' | awk '{print $2}')

vdiskname="$clustername:$vdiskname"
vdiskpartpath="/dev/mapper/$vdiskid-part1"


# -K
# Keep, do not attempt to discard blocks at mkfs time (discarding blocks initially is useful on solid state devices and sparse / thin-provisioned storage).

mkfs.gfs2 -K -t $vdiskname -j $numnodes -J 64 $vdiskpartpath

label=$(blkid $vdiskpartpath | sed -n 's/.*LABEL=\"\([^\"]*\)\".*/\1/p' )
svcname=$(echo $mnt| sed 's/\//-/g' | sed 's/$/.mount/' |sed 's/^.//')


cat > "./$svcname" <<EOT
[Unit]
Description=Mount $svcname share over iSCSI LUN
Requires=network-online.target iscsid.service dlm.service
After=network-online.target iscsid.service dlm.service rescan-dc.service

[Mount]
What=/dev/disk/by-label/$label
Where=$mnt
Type=gfs2
Options=_netdev,acl

[Install]
WantedBy=multi-user.target

EOT


for item in ${nodes}; do
    scp ./$svcname  $item:/etc/systemd/system/$svcname 
    ssh $item iscsiadm -m session --rescan
    ssh $item multipath -r
    ssh $item multipath -ll
    ssh $item "mkdir -p $mnt; systemctl daemon-reload; systemctl enable \"/etc/systemd/system/$svcname\" ; systemctl start $svcname"
done

rm  ./$svcname

pvesh create /storage --storage $storagename --type dir --shared  --path $mnt --content images,iso,vztmpl,rootdir
