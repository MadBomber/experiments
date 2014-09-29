avahi-browse -r -t -f -a -p | fgrep -i IseNetworkGateway | grep ^= | gawk -F\; '{print $8 ":" $9 "\t" $7 "\t" $10}' | sort
