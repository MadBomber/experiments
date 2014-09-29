 avahi-browse -t -r -p _IsePrincess._tcp. | fgrep IseNetworkGateway | grep ^= | gawk -F\; '{print $7 "\t" $8 ":" $9}'
