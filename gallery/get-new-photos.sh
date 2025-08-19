#!/bin/bash

echo "Git revision is $CF_SHORT_REVISION"

mkdir -p ./assets-$CF_SHORT_REVISION/photos
cp Dockerfile ./assets-$CF_SHORT_REVISION/photos/
cd ./assets-$CF_SHORT_REVISION/photos/

for i in $(seq 1 10); do
	RESOLUTION="1920x1080"
	uuid=$(cat /proc/sys/kernel/random/uuid)
	wget -O "$uuid.jpg" "https://source.unsplash.com/random/$RESOLUTION/?wallpaper"
done
