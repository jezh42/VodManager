#!/bin/bash
# VodManager
#
# Run: ./VodManager.sh
#
# Make sure to configure the global vars
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
first_run_vod_update_count=7
whilst_run_vod_update_count=7

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

vod_data=""
declare -a queue=()

# Update function
# Updates global queue with X vod IDs
# Only add to queue if _combined doesn't exist
#  & not live
# Sorted by oldest (smallest) ID first
# First run is global vod count, others are 5
update_queue () {

  #set -x TODO:

  oldQueueCount=${#queue[@]}

  vod_count=$1

  # Get latest x vod Ids (Twitch API)
  # https://dev.twitch.tv/docs/api/reference/#get-videos
  vod_data=$(twitch api get /videos \
    -q user_id=${channels[$current_streamer]} \
    -q sort=time \
    -q type=archive \
    -q first=${vod_count}
  )

  # Add the next vod ids
  for v in $(echo ${vod_data} | jq -r '.data[].id' | sort -u)
  do

    # Current stream info, empty if not live
    current_stream=$(twitch api get /streams \
    -q user_id=${channels[$current_streamer]} \
    -q type=live
    )
    current_stream_id=$(echo $current_stream | jq -r ".data[].id");

    # Stream ID of the current Vod
    vod_stream_id=$(echo ${vod_data} | jq -r ".data[] | select(.id == \"${v}\") | .stream_id");
    echo -e "${ORANGE}[VodManager] ${NC} ${PURPLE}vod_stream_id${NC} ${vod_stream_id}"
    published_at=$(echo ${vod_data} | jq -r ".data[] | select(.id == \"${v}\") | .published_at");
    echo -e "${ORANGE}[VodManager] ${NC} ${PURPLE}published_at${NC} ${published_at}"
    created_at=$(echo ${vod_data} | jq -r ".data[] | select(.id == \"${v}\") | .created_at");
    echo -e "${ORANGE}[VodManager] ${NC} ${PURPLE}created_at${NC} ${created_at}"
    duration=$(echo ${vod_data} | jq -r ".data[] | select(.id == \"${v}\") | .duration");
    echo -e "${ORANGE}[VodManager] ${NC} ${PURPLE}duration${NC} ${duration}"
    created_at_epoch_time=$(date +%s -ud"${created_at}")
    echo -e "${ORANGE}[VodManager] ${NC} ${PURPLE}created_at_epoch_time${NC} ${created_at_epoch_time}"
    duration_seconds=$(echo ${duration} | awk -F'[hms]' '{ print ($1 * 3600) + ($2 * 60) + $3 }')
    echo -e "${ORANGE}[VodManager] ${NC} ${PURPLE}duration_seconds${NC} ${duration_seconds}"
    created_plus_duration=$((created_at_epoch_time + duration_seconds))
    echo -e "${ORANGE}[VodManager] ${NC} ${PURPLE}created_plus_duration${NC} ${created_plus_duration}"
    current_time=$(date -u +'%Y-%m-%d'T'%H:%m:%S'Z'')
    echo -e "${ORANGE}[VodManager] ${NC} ${PURPLE}current_time${NC} ${current_time}"
    current_epoch_time=$(date +%s)
    echo -e "${ORANGE}[VodManager] ${NC} ${PURPLE}current_epoch_time${NC} ${current_epoch_time}"
    current_minus_sumation=$((current_epoch_time - created_plus_duration))
    echo -e "${ORANGE}[VodManager] ${NC} ${PURPLE}current_minus_sumation${NC} ${current_minus_sumation}"

    # LIVE CHECK
    # If vod is live then dont add to queue
    # if streamer is live (id is non-zero) AND if current stream id is the current vod id = live
    # OR if time between vod_created+duration and current epoch is < 60 = live
    if [[ -n "$current_stream_id" ]] && [[ "$current_stream_id" == "$vod_stream_id" ]]; then

      echo -e "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${RED}[0:1]${NC} Vod ${ORANGE}${v}${NC} still live!!! Skipping."
      # Add to queue if it doesn't exist
    elif [ "$current_minus_sumation" -lt 60 ]; then
      echo -e "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${RED}[0:2]${NC} Vod ${ORANGE}${v}${NC} still live!!! Skipping."
    elif [ ! -f "${vods_location}${v}_combined.mp4" ]; then
      echo -e "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${PURPLE}[U]${NC} Added ${v}..."
      queue+=($v)
      queue_count=${#queue[@]}
    fi

  done

  # Unique sort array (hack)
  queue=($(for i in "${queue[@]}"; do echo "${i}"; done | sort -u))

  # TODO: What if queue empty / no IDs returned from twitch
  # Fail early!!!

  newQueueCount=${#queue[@]}
  diff="$(($newQueueCount-$oldQueueCount))"

  echo -e "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${PURPLE}[U]${NC} Added ${diff} new vods to the queue"

  #set +x TODO:
}

# Get the queue for the first time
update_queue $first_run_vod_update_count

# Loop through the queue, indefinitely
while true
do

  #set -x

  # Get vod id from top of queue
  id=${queue[0]}
  queue=("${queue[@]:1}")
  queue_count=$((${#queue[@]}))

  if [ -f "${vods_location}${id}.mp4" ]; then
    echo -e "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${RED}[1]${NC} Vod ${ORANGE}${id}${NC} already downloaded, skipping."
  else
    echo -e "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${GREEN}[1]${NC} Downloading AlsoMij vod, id: ${ORANGE}${id}${NC}..."

    # TODO: Change the ffmpeg options to be less filesize?
    TwitchDownloaderCLI videodownload \
    --id ${id} \
    --quality Source \
    --log-level ${log_level} \
    --temp-path ${temp_location} \
    -o ${vods_location}${id}.mp4

  fi


  if [ -f "${vods_location}${id}_chat.json" ]; then
    echo -e "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${RED}[2]${NC} Chat ${ORANGE}${id}${NC} already downloaded, skipping."
  else
    echo -e "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${GREEN}[2]${NC} Downloading AlsoMij chat, id: ${ORANGE}${id}${NC}..."

    TwitchDownloaderCLI chatdownload -E \
      --id ${id} \
      --log-level ${log_level} \
      --temp-path ${temp_location} \
      -o ${vods_location}${id}_chat.json
  fi



  if [ -f "${vods_location}${id}_chat.mp4" ]; then
    echo -e "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${RED}[3]${NC} Chat ${ORANGE}${id}${NC} already rendered, skipping."
  else
    echo -e "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${GREEN}[3]${NC} Rendering AlsoMij chat, id: ${ORANGE}${id}${NC}..."

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

  # TODO: Only render and upload if its longer than 30 minutes
  # https://superuser.com/questions/361329/how-can-i-get-the-length-of-a-video-file-from-the-console
  #length=ffprobe -i ${vods_location}${id}.mp4 -show_entries format=duration -v quiet -of csv="p=0"

  # Bake chat onto VOD with transparency
  if [ -f "${vods_location}${id}_combined.mp4" ]; then
    echo -e "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${RED}[4]${NC} Combined Video ${ORANGE}${id}${NC} already rendered, skipping."
  #elif [ ]; then
  else
    echo -e "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${GREEN}[4]${NC} Baking chat overlay into AlsoMij vod, id: ${ORANGE}${id}${NC}..."

    # Baking time

    # -threads 4 \
    # -c:a copy \
    # -c:v libx264 \
    # -preset medium \


    ffmpeg \
     -i ${vods_location}${id}_chat.mp4 \
     -i ${vods_location}${id}_chat_mask.mp4 \
     -i ${vods_location}${id}.mp4 \
     -filter_complex "[0][1]alphamerge[ia];[2][ia]overlay=W-w:0" \
     -c:v h264_nvenc \
     -cq 23 \
     -c:a aac \
     -b:a 128k \
     -preset fast \
     -crf 23 \
     ${vods_location}${id}_combined.mp4

    # Upload to Youtube after rendering/baking
    echo -e "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${GREEN}[5]${NC} Uploading final AlsoMij vod, id: ${ORANGE}${id}${NC}..."

    # Variables from Vod
    # TODO: Confirm this isn't bugged
    title=$(echo ${vod_data} | jq -r ".data[] | select(.id == \"${id}\") | .title")
    #good_chars="A-Za-z0-9_.|-'\":()\[\]\\\/"
    #title_sanitised=$(echo "${title//[^${good_chars}]/_}")
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
        -metaJSON "${current_streamer}-yt-meta.json" \
        -sendFilename true \
        -description "" 2>> failedUploads.txt;
    then
      echo "[$(date +'%d-%m-%Y %T')] ${id}_combined.mp4 - ${combined_title:0:99}" >> uploadedVods.txt
      echo -e "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${GREEN}[6]${NC} ${ORANGE}${id}${NC} uploaded successfully! Yippers!"
    else
      echo "[$(date +'%d-%m-%Y %T')] ${id}_combined.mp4 - ${combined_title:0:99}" >> failedUploads.txt
      echo -e "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${RED}[6]${NC} ${ORANGE}${id}${NC} failed to upload. Logging..."
    fi

  fi

  echo -e "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${GREEN}[7]${NC} Finished processing video ${ORANGE}${id}${NC}"

  # Check for new video, once after every video, constantly if queue is empty
  echo -e "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${PURPLE}[8]${NC} Checking Twitch for new VODs..."
  checkTwitchOnce=true
  # oldQueueCount=${#queue[@]}
  while [ ${#queue[@]} -eq 0 -o $checkTwitchOnce = true ]
  do
    checkTwitchOnce=false

    # Fetch from Twitch again

    # If queue is empty (and looping), then check every 5 minutes
    if [ ${#queue[@]} -eq 0 ]; then
      # TODO: add a spinner
      # TODO: https://unix.stackexchange.com/questions/360198/can-i-overwrite-multiple-lines-of-stdout-at-the-command-line-without-losing-term
      #echo -ne "${ORANGE}[VodManager] [Q=$queue_count]${NC} ${PURPLE}[8]${NC} ZZZZ...\033[0K\r"

      sleep 5m | pv -t
      #temp dont sleep on 0, just shutdown
      #shutdown.exe /s /t 0

      #echo -ne "$(sleep 5 | pv -F $'%t')\033[0K\r" # -N "${ORANGE}[VodManager] [Q=${#queue[@]}]${NC} ${PURPLE}[8]${NC} ZZZZ...\033[0K\r";
      #echo -ne "\033[0K\r"
      #| tr $'\n' $'\033[0K\r' #
      #-c ?
    fi

    # Update the queue, use 5
    update_queue $whilst_run_vod_update_count

  done

  #set +x

done
