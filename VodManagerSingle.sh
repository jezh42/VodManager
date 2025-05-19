#!/bin/bash
# VodManager
#
# Run: ./VodManagerSingle.sh VodId timestamp_start timestamp_end
#
# Make sure to configure the global vars
#

# Global Vars
vods_location='/mnt/NAS_Drive/VODs/AlsoMij/'
temp_location="${vods_location}temp/"
log_level="Status,Info,Warning,Error" # Verbose
chat_height=176
chat_width=400

ORANGE='\033[0;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

current_streamer='AlsoMij'

# List of users https://dev.twitch.tv/docs/api/reference/#get-users
# $ twitch api get /users -q login=AlsoMij | jq -r '.data[].id'
declare -A channels=( ["AlsoMij"]="209005581" \
  ["Paislily"]="419476424" \
  ["PlayItShady"]="167753637" \
  ["ClintStevens"]="86268118"
)

PROGNAME=$0

usage() {
  cat << EOF >&2
Usage: $PROGNAME [-d --debug]

-d --debug: Debug
        -v: Verbose mode
EOF
  exit 1
}

verbose_level=0
while getopts dv o; do
  case $o in
    (d) debug=true;;
    (v) verbose_level=$((verbose_level + 1));;
    (*) usage
  esac
done
shift "$((OPTIND - 1))"


# Get Values
echo -ne "${ORANGE}[VodManager]${NC} ${GREEN}[1]${NC} Input VOD ID: "
read id

echo -ne "${ORANGE}[VodManager]${NC} ${GREEN}[2]${NC} Input timestamp to start at: "
read timestamp_start

echo -ne "${ORANGE}[VodManager]${NC} ${GREEN}[3]${NC} Input timestamp to end at: "
read timestamp_end

echo -ne "${ORANGE}[VodManager]${NC} ${GREEN}[4]${NC} Input game: "
read game
game_santised=$(echo "${game//[^A-Za-z0-9_-]/_}") # Remove bad chars from game name

echo -ne "${ORANGE}[VodManager]${NC} ${GREEN}[5]${NC} Input part (leave empty for no part): "
read part
title="| mij plays ${game} $( [ ! -z ${part} ] && echo "Part ${part}")"

# Assumes combined vod already

if [ "$debug" = true ]; then
   echo -e "${ORANGE}[VodManager]${NC} ${RED}[D]${NC} ${GREEN}id${NC} ${ORANGE}${id}${NC}"
   echo -e "${ORANGE}[VodManager]${NC} ${RED}[D]${NC} ${GREEN}timestamp_start${NC} ${ORANGE}${timestamp_start}${NC}"
   echo -e "${ORANGE}[VodManager]${NC} ${RED}[D]${NC} ${GREEN}timestamp_end${NC} ${ORANGE}${timestamp_end}${NC}"
   echo -e "${ORANGE}[VodManager]${NC} ${RED}[D]${NC} ${GREEN}title${NC} ${ORANGE}${title}${NC}"
   echo -e "${ORANGE}[VodManager]${NC} ${RED}[D]${NC} ${GREEN}game_santised${NC} ${ORANGE}${game_santised}${NC}"
fi


# Cut up the combined vod
echo -e "${ORANGE}[VodManager]${NC} ${GREEN}[6]${NC} Cutting the vod from ${ORANGE}${timestamp_start}${NC} to ${ORANGE}${timestamp_end}${NC}"



final_location=${vods_location}${id}_${game_santised}$( [ ! -z ${part} ] && echo "_${part}")

if [ "$debug" = true ]; then
   echo -e "${ORANGE}[VodManager]${NC} ${RED}[D]${NC} ${GREEN}final_location${NC} ${ORANGE}${final_location}${NC}";
   set -x
fi


ffmpeg \
   -ss ${timestamp_start} \
   -i ${vods_location}${id}_combined.mp4 \
   -to ${timestamp_end} \
   ${final_location}.mp4

if [ "$debug" = true ]; then
   set -x
fi

# Upload to Youtube after cuting
echo -e "${ORANGE}[VodManager]${NC} ${GREEN}[7]${NC} Uploading the trimmed vod, id: ${ORANGE}${id}${NC}..."



# if youtubeuploader \
#    -title "${title:0:99}" \
#    -filename ${vods_location}${id}_${game_santised}_${part}.mp4 \
#    -privacy 'private' \
#    -oAuthPort 4242 \
#    -cache ".request.token" \
#    -secrets ".client_secrets.json" \
#    -metaJSON "${current_streamer}-yt-meta.json" \
#    -sendFilename true \
#    -description "";
# then
# echo "[$(date +'%d-%m-%Y %T')] ${id}_combined.mp4 - ${combined_title:0:99}" >> uploadedVods.txt
# echo -e "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${GREEN}[6]${NC} ${ORANGE}${id}${NC} uploaded successfully! Yippers!"
# else
# echo "[$(date +'%d-%m-%Y %T')] ${id}_combined.mp4 - ${combined_title:0:99}" >> failedUploads.txt
# echo -e "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${RED}[6]${NC} ${ORANGE}${id}${NC} failed to upload. Logging..."
# fi

# echo -e "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${GREEN}[7]${NC} Finished processing video ${ORANGE}${id}${NC}"
