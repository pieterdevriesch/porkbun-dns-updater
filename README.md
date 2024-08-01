# porkbun-dns-updater
### Porkbun DNS update script for when public IP changes

This is a quick shell script that you can add to a cron job to make sure your domain's DNS is still pointed to your public IP if you're running things from your home, or anywhere with a non fixed IP. Mine used to be very fixed but recently I've been getting a new IP after every router restart so I made this.

I use a wildcard DNS record and a reverse proxy server which is why I couldn't use ddclient or any of the other existing tools I tried.

I run it every 5 minutes but [icanhazip.com](https://major.io/p/a-new-future-for-icanhazip/) supposedly doesn't have a rate limit so you could theoretically do it every second if you wanted, not that I'm advocating that... 

Originally I used jq for json parsing and curl for the web request but I refactored it to remove dependencies on external tools, it should work on anything that can run at least busybox. I use wget to do the requests, grep with a regex to extract the ip and that's pretty much it.

### Installation
Just put the status.sh script anywhere you want (I put it in a subfolder under my home folder) and add a cron job to run it [every 5 minutes](https://crontab.guru/every-5-minutes) for example. 

### Logging
The script logs to status.log in it's own location, you can use something like logrotate to make sure the log doesn't get too big.
That's what I do, keeping 90 days of logs just in case. Alternatively you can uncomment this line at the beginning of the script that removes everything except the last 100 lines of the log (change to however long you want it to be):

```
#tail -n 100 status.log > tmp.log && mv tmp.log status.log
```

Or just remove the second > from the logging section on line 12 to overwrite the log every time it runs:

```
exec 1>./status.log 2>&1
```
