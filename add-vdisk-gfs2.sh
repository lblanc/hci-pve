#!/bin/bash

nodes="10.12.109.101 10.12.109.102"

echo
echo "This script will add DataCore vDisk to a PVE Cluster as a GFS2"
echo
read -p "Continue? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi
