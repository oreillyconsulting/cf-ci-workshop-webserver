#!/bin/bash

echo "Git revision is $CF_SHORT_REVISION"

mkdir -p ./assets/$CF_SHORT_REVISION/photos
cp Dockerfile ./assets/$CF_SHORT_REVISION/photos/
cd ./assets/$CF_SHORT_REVISION/photos/

# procedure to get images from unsplash
#
#for i in $(seq 1 10); do
#	RESOLUTION="1920x1080"
#	uuid=$(cat /proc/sys/kernel/random/uuid)
#	wget -O "$uuid.jpg" "https://source.unsplash.com/random/$RESOLUTION/?wallpaper"
#done

# Cache file to save Reddit API response.
JSONCACHE="/tmp/reddit-wallpaper-cache.json"
# Custom user agent for Reddit
USERAGENT="Mozilla/5.0 (X11; Linux x86_64; rv:100.0) Gecko/20100101 Firefox/100.0"
APIURL="https://www.reddit.com/r/wallpapers.json?limit=100"
# Remove cached response if older than 2 hours.
find $(dirname $JSONCACHE) -name "$(basename $JSONCACHE)" -mmin +120 -exec rm {} \; 2>/dev/null
# Remove wallpapers older than 2 days
find . -type f -mtime +2 -exec rm {} \; 2>/dev/null

# Exit on error
set -e

# Download the JSON cache if not already available
if [ ! -f "$JSONCACHE" ]; then
  curl -H "User-Agent: $USERAGENT" "$APIURL" -s > "$JSONCACHE"
fi

# Extract all post JSON entries
POSTS=$(cat "$JSONCACHE" | jq -c '.data.children[].data')

# Get 10 unique image URLs
echo "$POSTS" | shuf | while read -r WJSON; do
  # Handle crossposts
  CROSSPOST=$(echo "$WJSON" | jq -c '.crosspost_parent_list[0]' --raw-output)
  if [ "$CROSSPOST" != "null" ]; then
    WJSON=$CROSSPOST
  fi

  WDOMAIN=$(echo "$WJSON" | jq '.domain' --raw-output)
  case "$WDOMAIN" in
    "i.redd.it"|"reddit.com"|"i.imgur.com")
      ;;
    *)
      continue
      ;;
  esac

  # Handle galleries
  WISGALLERY=$(echo "$WJSON" | jq '.is_gallery')
  if [ "$WISGALLERY" == "true" ]; then
    GITEM=$(echo "$WJSON" | jq -c '.media_metadata' --raw-output | jq -c 'to_entries[] | .value' | shuf -n 1)
    WMIME=$(echo "$GITEM" | jq '.m' --raw-output)
    WEXT=$(basename "$WMIME")
    WID=$(echo "$GITEM" | jq '.id' --raw-output)
    WURI="https://i.redd.it/$WID.$WEXT"
  else
    WURI=$(echo "$WJSON" | jq '.url' --raw-output)
  fi

  # Extract image name and path
  WNAME=$(basename "$WURI")
  FILEPATH="./$WNAME"

  # Download if not already present
  if [ ! -f "$FILEPATH" ]; then
    curl -s "$WURI" -o "$FILEPATH"
    if [ $? -eq 0 ]; then
      echo "Downloaded: $FILEPATH"
      ls -lah "$FILEPATH"
    else
      echo "Failed to download: $WURI"
      rm -f "$FILEPATH"
    fi
    COUNT=$((COUNT + 1))
  fi

  # Stop after downloading 10 unique images
  if [ "$COUNT" -ge 10 ]; then
    break
  fi

done
