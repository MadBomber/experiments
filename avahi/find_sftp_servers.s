avahi-browse -r -t -f -a -p | fgrep -i SFTP | grep ^= | gawk -F\; '{print $8 "\t" $7}' | sort -u
