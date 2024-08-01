#!/bin/sh

# load secrets so they don't need to be hardcoded in the script. Replace with something more secure if needed.
source ./.credentials

# uncomment this line to make sur the log does not get too big, or use another method to manage logfiles
#tail -n 100 status.log > tmp.log && mv tmp.log status.log

# enable logging of all output streams. Use logrotate to manage your logs, by default will just always append.
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>./status.log 2>&1

# make sure required tools are installed. I used wget since it's the most default option.
command -v wget >/dev/null 2>&1 || { echo >&2 "I require wget but it's not installed.  Aborting."; exit 1; }

# echo the current time and date for the log.
now=$(date)
echo "Script executing at $now"

# check for the presense of status.json, will not exist during the first run, so will create it.
if [ ! -f ./status.json ]
then
    echo "status.json not found. Retrieving Porkbun DNS record now."
    status=$(wget --header="Content-type: application/json" \
  --post-data='{"secretapikey":"'$secretapikey'","apikey":"'$apikey'"}' \
  --no-check-certificate \
  --output-document - \
  --quiet \
  https://porkbun.com/api/json/v3/dns/retrieveByNameType/$domain'/A/*')
    # save output to file so we don't have to connect to porkbun every 5 minutes but only if the ip has changed.
    echo "$status" > ./status.json
fi

# extract IP address. if first run will give error and then fail the compare, so will create file after.
dns_ip=$(grep -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])' ./status.json)

# display ip for debug
echo "DNS points to IP $dns_ip"

# check current WAN IP:
wan_ip=$(wget --no-check-certificate --output-document - --quiet http://canhazip.com)

#display output for debug purposes
echo "Current WAN IP is $wan_ip"

# compare both IP's and change porkbun setting if not the same.
if [ "$dns_ip" != "$wan_ip" ]; then
  echo "Porkbun DNS setting is not correct! Changing now!"
  # update DNS of wildcard record via API IF it has changed since the last time.
  change=$(wget --header="Content-type: application/json" \
  --post-data='{"secretapikey":"'$secretapikey'","apikey":"'$apikey'","content":"'$wanip'"}' \
  --no-check-certificate \
  --output-document - \
  --quiet \
  https://porkbun.com/api/json/v3/dns/editByNameType/$domain'/A/*')

  sleep 10

  # now retrieve current IP set in porkbun dns
  status=$(wget --header="Content-type: application/json" \
  --post-data='{"secretapikey":"'$secretapikey'","apikey":"'$apikey'"}' \
  --no-check-certificate \
  --output-document - \
  --quiet \
  https://porkbun.com/api/json/v3/dns/retrieveByNameType/$domain'/A/*')
  # save output to file so we don't have to connect to porkbun every 5 minutes but only if the ip has changed.
  echo "$status" > ./status.json
else
  echo "WAN IP matches DNS record. All good."
fi
