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
#  Uploads to Youtube?
#
# Future Features:
#  Better logging
#  Command Line count vods
#  Supporting multiple streamers
#  Command line supply streamers
#  Chapter support?
#
# Configure the twitch CLI tool?

# Global Vars
vods_location='/mnt/NAS_Drive/VODs/AlsoMij/'
temp_location="${vods_location}temp/"
#log_level="Status,Info,Warning,Error,Verbose"
log_level="Status,Info,Warning,Error"
chat_height=176
chat_width=400
vodCount=5

# List of users
# https://dev.twitch.tv/docs/api/reference/#get-users
# twitch api get /users -q login=AlsoMij
# access them ${channels['AlsoMij']}
declare -A channels=(["AlsoMij"]="209005581")

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

  #set -x


  if [ -f "${vods_location}${id}.mp4" ]; then
    echo "[VodManager] [1] Vod ${id} already downloaded, skipping."
  else
    echo "[VodManager] [1] Downloading AlsoMij vod, id: ${id}..."
    
    # TODO: Change the ffmpeg options to be less filesize?
    TwitchDownloaderCLI videodownload \
    --id ${id} \
    --quality Source \
    --log-level ${log_level} \
    --temp-path ${temp_location} \
    -o ${vods_location}${id}.mp4


    #if [ $? -ne 0 ]; then
    #  echo "Error downloading video ${id}, skipping."
    #  continue
    #fi

  fi

 
  if [ -f "${vods_location}${id}_chat.json" ]; then
    echo "[VodManager] [2] Chat ${id} already downloaded, skipping."
  else
    echo "[VodManager] [2] Downloading AlsoMij chat, id: ${id}..."
    
    TwitchDownloaderCLI chatdownload -E \
      --id ${id} \
      --log-level ${log_level} \
      --temp-path ${temp_location} \
      -o ${vods_location}${id}_chat.json
  fi 


  
  if [ -f "${vods_location}${id}_chat.mp4" ]; then
    echo "[VodManager] [3] Chat ${id} already rendered, skipping."
  else
    echo "[VodManager] [3] Rendering AlsoMij chat, id: ${id}..."
    # Render chat
    # Change size
    # --background-color "#88111111" \
    # "#00000000"
    #  "alternate": "#222222" "regular": "#66191919"
    TwitchDownloaderCLI chatrender \
      -i ${vods_location}${id}_chat.json \
      -h ${chat_height} \
      -w ${chat_width} \
      --framerate 30 \
      --update-rate 0 \
      --font-size 18 \
      --background-color "#00000000" \
      --temp-path ${temp_location} \
      --generate-mask \
      -o ${vods_location}${id}_chat.mp4
  fi
  
  # ffmpeg combine chat ontop of vod -> new vid
  # https://stackoverflow.com/questions/52547971/overlay-transparency-video-on-top-of-other-video
  # https://github.com/lay295/TwitchDownloader/issues/79
  # https://stackoverflow.com/questions/23201134/transparent-argb-hex-value

  #"[1:v]format=rgb24,colorkey=black:0.3:0.2,colorchannelmixer=aa=0.3[1t]; \
  #[0:v][1t]overlay=W-w:0[outv]" \
  # -crf 23 \
  # -maxrate 5M -bufsize 10M \

  # ffmpeg -y \
  #  -i ${vods_location}${id}.mp4 \
  #  -i ${vods_location}${id}_chat.mp4 \
  #  -filter_complex \
  #  '[1:v]format=rgba,colorchannelmixer=aa=0.5[1t]; [0:v][1t]overlay=W-w:0[outv]' \
  #  -map [outv] -map 0:a \
  #  -c:a copy \
  #  -c:v libx264 \
  #  -preset slow \
  #  ${vods_location}${id}_combined.mp4

  

  # Continue if video is already downloaded
  if [ -f "${vods_location}${id}_combined.mp4" ]; then
    echo "[VodManager] [4] Combined Video ${id} already rendered, skipping."
  else
    echo "[VodManager] [4] Rendering chat overlay for AlsoMij vod, id: ${id}..."

    ffmpeg -y \
     -i ${vods_location}${id}_chat.mp4 \
     -i ${vods_location}${id}_chat_mask.mp4 \
     -i ${vods_location}${id}.mp4 \
     -filter_complex "[0][1]alphamerge[ia];[2][ia]overlay=W-w:0" \
     -c:a copy \
     -c:v libx264 \
     -preset slow \
     -crf 26 \
     ${vods_location}${id}_combined.mp4
  fi


  #echo "[VodManager] [5] Uploading final AlsoMij vod, id: ${id}..."

  echo "[VodManager] [6] Finished processing video ${id}"


  #set +x
done
