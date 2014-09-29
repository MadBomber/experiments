avahi-browse -r -t -f -a -p | fgrep -i 'printer' | grep ^= | gawk -F\; '{print $8 "\t" $7}' | sort -u
