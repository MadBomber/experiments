 avahi-browse -r -t -f -a -p | fgrep 'SSH' | grep ^= | gawk -F\; '{print $8 "\t" $7}' | sort
