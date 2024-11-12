#!/bin/bash
# VodManager
#
# Run: ./VodManager.sh
#
# Make sure to configure the global vars
#

# Global Vars
#vods_location='/mnt/zimablade/vods/AlsoMij/'
vods_location='/mnt/NAS_Drive/VODs/AlsoMij/'
temp_location="${vods_location}temp/"
#log_level="Status,Info,Warning,Error,Verbose"
log_level="Status,Info,Warning,Error"
chat_height=176
chat_width=400
vodCount=5

ORANGE='\033[0;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# List of users https://dev.twitch.tv/docs/api/reference/#get-users
# $ twitch api get /users -q login=AlsoMij
declare -A channels=(["AlsoMij"]="209005581")

# Get latest x vod Ids (Twitch API)
# https://dev.twitch.tv/docs/api/reference/#get-videos
vod_data=$(twitch api get /videos \
  -q user_id=${channels['AlsoMij']} \
  -q sort=time \
  -q type=archive \
  -q first=${vodCount}
)


# Loop through all x videos getting id, title and created_at
#for id in $(echo ${vod_data} | jq -r '.data[].id' | tac)
for id in $(echo ${vod_data} | jq -r '.data[].id')
do

  #set -x

  if [ -f "${vods_location}${id}.mp4" ]; then
    echo -e "${ORANGE}[VodManager]${NC} ${RED}[1]${NC} Vod ${ORANGE}${id}${NC} already downloaded, skipping."
  else
    echo -e "${ORANGE}[VodManager]${NC} ${GREEN}[1]${NC} Downloading AlsoMij vod, id: ${ORANGE}${id}${NC}..."
    
    # TODO: Change the ffmpeg options to be less filesize?
    TwitchDownloaderCLI videodownload \
    --id ${id} \
    --quality Source \
    --log-level ${log_level} \
    --temp-path ${temp_location} \
    -o ${vods_location}${id}.mp4

  fi

 
  if [ -f "${vods_location}${id}_chat.json" ]; then
    echo -e "${ORANGE}[VodManager]${NC} ${RED}[2]${NC} Chat ${ORANGE}${id}${NC} already downloaded, skipping."
  else
    echo -e "${ORANGE}[VodManager]${NC} ${GREEN}[2]${NC} Downloading AlsoMij chat, id: ${ORANGE}${id}${NC}..."
    
    TwitchDownloaderCLI chatdownload -E \
      --id ${id} \
      --log-level ${log_level} \
      --temp-path ${temp_location} \
      -o ${vods_location}${id}_chat.json
  fi 


  
  if [ -f "${vods_location}${id}_chat.mp4" ]; then
    echo -e "${ORANGE}[VodManager]${NC} ${RED}[3]${NC} Chat ${ORANGE}${id}${NC} already rendered, skipping."
  else
    echo -e "${ORANGE}[VodManager]${NC} ${GREEN}[3]${NC} Rendering AlsoMij chat, id: ${ORANGE}${id}${NC}..."

    # Render chat
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
  
  # Bake chat onto VOD with transparency
  if [ -f "${vods_location}${id}_combined.mp4" ]; then
    echo -e "${ORANGE}[VodManager]${NC} ${RED}[4]${NC} Combined Video ${ORANGE}${id}${NC} already rendered, skipping."
  else
    echo -e "${ORANGE}[VodManager]${NC} ${GREEN}[4]${NC} Baking chat overlay into AlsoMij vod, id: ${ORANGE}${id}${NC}..."

    # Baking time
    ffmpeg \
     -i ${vods_location}${id}_chat.mp4 \
     -i ${vods_location}${id}_chat_mask.mp4 \
     -i ${vods_location}${id}.mp4 \
     -filter_complex "[0][1]alphamerge[ia];[2][ia]overlay=W-w:0" \
     -c:a copy \
     -c:v libx264 \
     -preset medium \
     -crf 23 \
     ${vods_location}${id}_combined.mp4

    # Upload to Youtube after rendering/baking
    echo -e "${ORANGE}[VodManager]${NC} ${GREEN}[5]${NC} Uploading final AlsoMij vod, id: ${ORANGE}${id}${NC}..."

    # Variables from Vod
    title=$(echo ${vod_data} | jq -r ".data[] | select(.id == \"${id}\") | .title")
    created_at=$(echo ${vod_data} | jq -r ".data[] | select(.id == \"${id}\") | .created_at")
    created_at_date=$(echo ${created_at} | sed 's/T.*//g')
    combined_title="${id} - ${title:0:67} [${created_at_date}]"

    #set -x

    if youtubeuploader \
        -title "${combined_title:0:99}" \
        -filename ${vods_location}${id}_combined.mp4 \
        -privacy 'private' \
        -oAuthPort 4242 \
        -cache ".request.token" \
        -secrets ".client_secrets.json" \
        -sendFilename true \
        -description "";
    then
      echo "[$(date +'%d-%m-%Y %T')] ${id}_combined.mp4 - ${combined_title:0:99}" >> uploadedVods.txt
      echo -e "${ORANGE}[VodManager]${NC} ${GREEN}[6]${NC} ${ORANGE}${id}${NC} uploaded successfully! Yippers!"
    else
      echo "[$(date +'%d-%m-%Y %T')] ${id}_combined.mp4 - ${combined_title:0:99}" >> failedUploads.txt
      echo -e "${ORANGE}[VodManager]${NC} ${RED}[6]${NC} ${ORANGE}${id}${NC} failed to upload. Logging..."
    fi

  fi

  echo -e "${ORANGE}[VodManager]${NC} ${GREEN}[7]${NC} Finished processing video ${ORANGE}${id}${NC}"

  #set +x

done
