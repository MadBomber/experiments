avahi-browse -r -t -f -p _druby._tcp | grep ^= | gawk -F\; '{print $4 "\t" $8 "\t" $7}' | sort
