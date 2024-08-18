#!/bin/bash
# VodManager
#
# Run: ./VodManager.sh
#
# Make sure to configure the global vars
#
# !NOTE!: Combined VOD/chat render is commented out atm
#
#  Run daily via cron?
#
# Goal:
#  Downloads VODs
#  Downloads Chat
#  Renders Chat
#  Combines Chat onto video
#   Old Vod is still kept
#  Gets Chapters
#  Uploads to Youtube?
#
# Future Features:
#  Better logging
#  Command Line count vods
#  Supporting multiple streamers
#  Command line supply streamers

# Global Vars
vods_location='/mnt/NAS_Drive/VODs/AlsoMij/'
temp_location="${vods_location}temp/"
log_level="Status,Info,Warning,Error,Verbose"
chat_height=176
chat_width=400
vodCount=1

# List of users
# https://dev.twitch.tv/docs/api/reference/#get-users
# twitch api get /users -q login=AlsoMij
# access them ${channels['AlsoMij']}
declare -A channels=(["AlsoMij"]="209005581")

# Configure the twitch CLI tool?

# Get latest x vod Ids (Twitch API)
# https://dev.twitch.tv/docs/api/reference/#get-videos
vod_data=$(twitch api get /videos \
  -q user_id=${channels['AlsoMij']} \
  -q sort=time \
  -q type=archive \
  -q first=${vodCount}
)


# Loop through all x video ids
for id in $(echo ${vod_data} | jq -r '.data[].id') 
do

  # if video is alreayd downloaded
  	# continue

  echo "[VodManager] Downloading AlsoMij vod, id: ${id}"
  
  set -x

  # TwitchDownloadCLI vod
  # TODO: Change the ffmpeg options to be less filesize
  TwitchDownloaderCLI videodownload \
    --id ${id} \
    --log-level ${log_level} \
    --temp-path ${temp_location} \
    --collision Exit \
    -o ${vods_location}${id}.mp4
  
  # TwitchDownloadCLI chat
  TwitchDownloaderCLI chatdownload -E \
    --id ${id} \
    --log-level ${log_level} \
    --temp-path ${temp_location} \
    --collision Exit \
    -o ${vods_location}${id}_chat.json

     
  # TwitchDownloadCLI render-chat
  # Change size
  TwitchDownloaderCLI chatrender \
    -i ${vods_location}${id}_chat.json \
    -h ${chat_height} \
    -w ${chat_width} \
    --framerate 30 \
    --update-rate 0 \
    --font-size 18 \
    --background-color "#CC111111" \
    --temp-path ${temp_location} \
    --collision Exit \
    -o ${vods_location}${id}_chat.mp4
  
  # ffmpeg combine chat ontop of vod -> new vid
  # https://stackoverflow.com/questions/52547971/overlay-transparency-video-on-top-of-other-video
  #ffmpeg -y \
  #  -i ${vods_location}${id}.mp4 \
  #  -i ${vods_location}${id}_chat.mp4 \
  #  -filter_complex \
  #  "[1:v]format=rgb24,colorkey=black:0.3:0.2,colorchannelmixer=aa=0.3[1t]; \
  #  [0:v][1t]overlay=W-w:0[outv]" \
  #  -map [outv] -map 0:a \
  #  -c:a copy \
  #  -c:v libx264 \
  #  -preset ultrafast \
  #  ${vods_location}${id}_combined.mp4
  
  set +x
done

# get chapters
