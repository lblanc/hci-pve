#!/bin/bash
#########################
#  rescan-dc-service.sh #
#########################



cat > "/etc/systemd/system/rescan-dc.service" <<EOT
[Unit]
Description=Rescan iSCSI DataCore Target
Requires=network-online.target iscsid.service
After=network-online.target iscsid.service


[Service]
Type=simple
ExecStart=/root/rescan-dc.sh

[Install]
WantedBy=multi-user.target

EOT

cat > "/root/rescan-dc.sh" <<EOT
#!/bin/bash
iscsiadm -m discovery -t sendtargets -p 192.168.31.1
iscsiadm -m discovery -t sendtargets -p 192.168.32.1
iscsiadm -m discovery -t sendtargets -p 192.168.31.2
iscsiadm -m discovery -t sendtargets -p 192.168.32.2
iscsiadm --mode node --portal 192.168.31.1 --targetname iqn.2000-08.com.datacore:sds1-fe1 --login
iscsiadm --mode node --portal 192.168.32.1 --targetname iqn.2000-08.com.datacore:sds1-fe2 --login
iscsiadm --mode node --portal 192.168.31.2 --targetname iqn.2000-08.com.datacore:sds2-fe1 --login
iscsiadm --mode node --portal 192.168.32.2 --targetname iqn.2000-08.com.datacore:sds2-fe2 --login
iscsiadm -m session --rescan
EOT

chmod +x /root/rescan-dc.sh

systemctl daemon-reload

systemctl enable rescan-dc.service




