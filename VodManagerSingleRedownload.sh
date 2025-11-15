#!/bin/bash
# VodManagerSingleRedownload
#
# Run: ./VodManagerSingleRedownload.sh
#
# no inputs yet
# VodId timestamp_start timestamp_end
#
# Make sure to configure the global vars
# Assumes you have the .mp4 and the chat.json
#


# Global Vars
vods_location='/mnt/zimablade/vods/AlsoMij/'
#vods_location='/mnt/NAS_Drive/VODs/AlsoMij/'
temp_location="${vods_location}temp/"
log_level="Status,Info,Warning,Error" # Verbose
chat_height=176
chat_width=400

# Assuming completed vods get deleted after 14 days (VodManagerDeleted)
# Lower number to account for lack of database implementation (filenames currently)
first_run_vod_update_count=23
whilst_run_vod_update_count=23

ORANGE='\033[0;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
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

echo -e "${PURPLE}[VodManager]${NC} ${GREEN}[0]${NC} Redonwloads all parts from twitch, supports timestamps"

echo -ne "${ORANGE}[VodManager]${NC} ${GREEN}[1]${NC} Input VOD ID: "
read id

echo -e "${ORANGE}[VodManager]${NC} ${GREEN}[1]${NC} Getting vod data quickly..."
vod_data=$(twitch api get /videos \
    -q id=${id}
)
duration=$(echo ${vod_data} | jq -r ".data[] | .duration");

echo -ne "${ORANGE}[VodManager]${NC} ${GREEN}[2]${NC} Input timestamp to start at (%H:%M:%S), or empty for start (setting this forces redownload): "
read start_input
timestamp_start=$(if [ -z ${start_input} ]; then echo "00:00:00"; else echo "${start_input}"; fi)

echo -ne "${ORANGE}[VodManager]${NC} ${GREEN}[3]${NC} Input timestamp to end at (%H:%M:%S), or empty for end (setting this forces redownload): "
read end_input
timestamp_end=$(if [ -z ${end_input} ]; then echo "${duration}" | sed -E 's/[hm]/:/g; s/s//g'; else echo "${end_input}"; fi)


echo -ne "${ORANGE}[VodManager]${NC} ${GREEN}[4]${NC} Input game title: "
read game
game_santised=$(echo "${game//[^A-Za-z0-9_-]/_}") # Remove bad chars from game name

echo -ne "${ORANGE}[VodManager]${NC} ${GREEN}[5]${NC} Input part number (leave empty for no part): "
read part
title="| mij plays ${game} $( [ ! -z ${part} ] && echo "Part ${part}")"

final_filename=${id}_${game_santised}$( [ ! -z ${part} ] && echo "_${part// /_}")
final_location=${vods_location}${final_filename}

if [ "$debug" = true ]; then
   echo -e "${ORANGE}[VodManager]${NC} ${BLUE}[D]${NC} ${GREEN}id${NC} ${ORANGE}${id}${NC}"
   echo -e "${ORANGE}[VodManager]${NC} ${BLUE}[D]${NC} ${GREEN}timestamp_start${NC} ${ORANGE}${timestamp_start}${NC}"
   echo -e "${ORANGE}[VodManager]${NC} ${BLUE}[D]${NC} ${GREEN}timestamp_end${NC} ${ORANGE}${timestamp_end}${NC}"
   echo -e "${ORANGE}[VodManager]${NC} ${BLUE}[D]${NC} ${GREEN}title${NC} ${ORANGE}${title}${NC}"
   echo -e "${ORANGE}[VodManager]${NC} ${BLUE}[D]${NC} ${GREEN}game_santised${NC} ${ORANGE}${game_santised}${NC}"
fi


if [[ -f "${vods_location}${id}.mp4" && -z ${end_input} && -z ${start_input} ]]; then
   echo -e "${ORANGE}[VodManager]${NC} ${RED}[3]${NC} Vod ${ORANGE}${id}${NC} already downloaded, skipping."
else
   echo -e "${ORANGE}[VodManager]${NC} ${GREEN}[3]${NC} Downloading AlsoMij vod, id: ${ORANGE}${id}${NC}..."

   # TODO: Change the ffmpeg options to be less filesize?
   TwitchDownloaderCLI videodownload \
   --id ${id} \
   --quality Source \
   --beginning ${timestamp_start} \
   --ending ${timestamp_end} \
   --log-level ${log_level} \
   --temp-path ${temp_location} \
   -o ${final_location}.mp4

fi


if [[ -f "${vods_location}${id}_chat.json" && -z ${end_input} && -z ${start_input} ]]; then
   echo -e "${ORANGE}[VodManager]${NC} ${RED}[4]${NC} Chat ${ORANGE}${id}${NC} already downloaded, skipping."
else
   echo -e "${ORANGE}[VodManager]${NC} ${GREEN}[4]${NC} Downloading AlsoMij chat, id: ${ORANGE}${id}${NC}..."

   TwitchDownloaderCLI chatdownload -E \
   --id ${id} \
   --log-level ${log_level} \
   --beginning ${timestamp_start} \
   --ending ${timestamp_end} \
   --temp-path ${temp_location} \
   -o ${final_location}_chat.json
fi



if [[ -f "${vods_location}${id}_chat.mp4" && -z ${end_input} && -z ${start_input} ]]; then
   echo -e "${ORANGE}[VodManager]${NC} ${RED}[5]${NC} Chat ${ORANGE}${id}${NC} already rendered, skipping."
else
   echo -e "${ORANGE}[VodManager]${NC} ${GREEN}[5]${NC} Rendering AlsoMij chat, id: ${ORANGE}${id}${NC}..."

   # Render chat
   TwitchDownloaderCLI chatrender \
   -i ${final_location}_chat.json \
   -h ${chat_height} \
   -w ${chat_width} \
   --framerate 30 \
   --update-rate 0 \
   --font-size 18 \
   --background-color "#00000000" \
   --temp-path ${temp_location} \
   --generate-mask \
   -o ${final_location}_chat.mp4

fi

# TODO: Only render and upload if its longer than 30 minutes
# https://superuser.com/questions/361329/how-can-i-get-the-length-of-a-video-file-from-the-console
#length=ffprobe -i ${vods_location}${id}.mp4 -show_entries format=duration -v quiet -of csv="p=0"

# Bake chat onto VOD with transparency
if [[ -f "${vods_location}${id}_combined.mp4" && -z ${end_input} && -z ${start_input} ]]; then
   echo -e "${ORANGE}[VodManager]${NC} ${RED}[6]${NC} Combined Video ${ORANGE}${id}${NC} already rendered, skipping."
#elif [ ]; then
else
   echo -e "${ORANGE}[VodManager]${NC} ${GREEN}[6]${NC} Baking chat overlay into AlsoMij vod, id: ${ORANGE}${id}${NC}..."

   # Baking time

   # -threads 4 \
   # -c:a copy \
   # -c:v libx264 \
   # -preset medium \


   ffmpeg \
   -i ${final_location}_chat.mp4 \
   -i ${final_location}_chat_mask.mp4 \
   -i ${final_location}.mp4 \
   -filter_complex "[0][1]alphamerge[ia];[2][ia]overlay=W-w:0" \
   -c:v h264_nvenc \
   -cq 23 \
   -c:a aac \
   -b:a 128k \
   -preset fast \
   -crf 23 \
   ${final_location}_combined.mp4

   # Upload to Youtube after rendering/baking
   echo -e "${ORANGE}[VodManager]${NC} ${GREEN}[7]${NC} Uploading final AlsoMij vod, id: ${ORANGE}${id}${NC}..."

   set -x

   if youtubeuploader \
      -title "${combined_title:0:99}" \
      -filename ${final_location}_combined.mp4 \
      -privacy 'private' \
      -oAuthPort 4242 \
      -cache ".request.token" \
      -secrets ".client_secrets.json" \
      -metaJSON "${current_streamer}-yt-meta.json" \
      -sendFilename true \
      -description "" 2>> failedUploads.txt;
   then
      echo "[$(date +'%d-%m-%Y %T')] ${final_filename}_combined.mp4.mp4 - ${combined_title:0:99}" >> uploadedVods.txt
      echo -e "${ORANGE}[VodManager]${NC} ${GREEN}[8]${NC} ${ORANGE}${id}${NC} uploaded successfully! Yippers!"
   else
      echo "[$(date +'%d-%m-%Y %T')] ${final_filename}_combined.mp4 - ${combined_title:0:99}" >> failedUploads.txt
      echo -e "${ORANGE}[VodManager]${NC} ${RED}[8]${NC} ${ORANGE}${id}${NC} failed to upload. Logging..."
   fi
   set +x
fi

echo -e "${ORANGE}[VodManager]${NC} ${GREEN}[9]${NC} Finished processing and uploading video ${ORANGE}${id}${NC}"
