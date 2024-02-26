#!/bin/bash
#########################
#  prerequisite-gfs2.sh #
#########################

echo
echo "This script will install prerequisite for GFS2 on cluster nodes"
echo
read -p "Continue? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi


nodes=$(pvecm status | grep 'A,V,NMW' | awk '{print $4}')

for item in ${nodes}; do
     ssh $item apt install dlm-controld gfs2-utils -y
     ssh $item  echo DLM_CONTROLD_OPTS="--enable_fencing 0" >> /etc/default/dlm
     ssh $item systemctl restart dlm
     ssh $item systemctl stop dlm; rmmod gfs2; rmmod dlm; sleep 3; systemctl restart udev; sleep 3; systemctl start dlm
done