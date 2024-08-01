#!/bin/sh
source ./.credentials
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>./status.log 2>&1

now=$(date)
echo "Script executing at $now"

# extract IP address. if first run will give error and then fail the compare, so will create file after.
dns_ip=$(jq -r '.records[].content' ./status.json)

# display ip for debug
echo "DNS points to IP $dns_ip"

# check current WAN IP:
wan_ip=$(curl -s -k http://canhazip.com)

#display output for debug purposes
echo "Current WAN IP is $wan_ip"

# compare both IP's and change porkbun setting if not the same.
if [ $dns_ip != $wan_ip ]; then
  echo "Porkbun DNS setting is not correct! Changing now!"
  # update DNS of wildcard record via API IF it has changed since the last time.
  change=$(curl -s -k --header "Content-type: application/json" --request POST --data '{"secretapikey":"'$secretapikey'","apikey":"'$apikey'","content":"'$wanip'"}' https://porkbun.com/api/json/v3/dns/editByNameType/$domain/A/*)
  sleep 10
  # now retrieve current IP set in porkbun dns
  status=$(curl -s -k --header "Content-type: application/json" --request POST --data '{"secretapikey":"'$secretapikey'","apikey":"'$apikey'"}' https://porkbun.com/api/json/v3/dns/retrieveByNameType/$domain/A/*)
  # save output to file so we don't have to connect to porkbun every 5 minutes but only if the ip has changed.
  echo "$status" > ./status.json
else
  echo "WAN IP matches DNS record. All good."
fi

