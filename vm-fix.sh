#!/bin/sh

HOSTNAME=$1

[ -z $HOSTNAME ] && { echo "new hostname not found"; exit 128; }

# fix user cron
temp=/tmp/tempcron
crontab -l > $temp
sed -i 's/^/# /' $temp
crontab $temp
rm -rf $temp
echo "fix user cron - DONE!"

# fix root cron
temp=/tmp/tempcron
sudo crontab -l > $temp
sudo sed -i 's/^/# /' $temp
sudo crontab $temp
sudo rm -rf $temp
echo "fix root cron - DONE!"

# fix hostname
conf=/etc/hostname
echo $HOSTNAME | sudo tee $conf
echo "update hostname - DONE!"

echo "fix VM - DONE!"

