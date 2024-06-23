#!/bin/bash
# VodManager
#  Run daily via cron?
#
#  Downloads VODs
#  Downloads Chat
#  Renders Chat
#  Combines Chat onto video
#   Old Vod is still kept
#  Gets Chapters
#  Uploads to Youtube?

vods_location='/mnt/NAS_Drive/VODs/AlsoMij/'
temp_location="${vods_location}temp/"
log_level="Status,Info,Warning,Error,Verbose"

# List of users
# https://dev.twitch.tv/docs/api/reference/#get-users
# twitch api get /users -q login=AlsoMij
# access them ${channels['AlsoMij']}
declare -A channels=(["AlsoMij"]="209005581")

# Configure the twitch CLI tool?

# Get latest 5x vod Ids (Twitch API)
# https://dev.twitch.tv/docs/api/reference/#get-videos
vod_data=$(twitch api get /videos \
  -q user_id=${channels['AlsoMij']} \
  -q sort=time \
  -q type=archive \
  -q first=5
)


# Loop through all 5 video ids
for id in $(echo ${vod_data} | jq -r '.data[].id') 
do

  # if video is alreayd downloaded
  	# continue
  
  set -x

  # TwitchDownloadCLI vod
  TwitchDownloaderCLI videodownload \
    --id ${id} \
    --log-level ${log_level} \
    --temp-path ${temp_location} \
    -o ${vods_location}${id}.mp4
  
  # TwitchDownloadCLI chat
  TwitchDownloaderCLI chatdownload -E \
    --id ${id} \
    --log-level ${log_level} \
    --temp-path ${temp_location} \
    -o ${vods_location}${id}_chat.json
     
  # TwitchDownloadCLI render-chat
  TwitchDownloaderCLI chatrender \
    -i ${vods_location}${id}_chat.json \
    -h 1080 \
    -w 422 \
    --framerate 30 \
    --update-rate 0 \
    --font-size 18 \
    --temp-path ${temp_location} \
    -o ${vods_location}${id}_chat.mp4
  
  # ffmpeg combine chat ontop of vod -> new vid
  set +x
done

# get chapters
