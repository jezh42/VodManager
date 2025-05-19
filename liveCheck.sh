#!/bin/bash
# VodManager Live Check

#set -x

ORANGE='\033[0;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

current_streamer_id='634606699'
#209005581
#634606699

vod_data=$(twitch api get /videos \
    -q user_id=$current_streamer_id \
    -q sort=time \
    -q type=archive \
    -q first=1
)

v=$(echo ${vod_data} | jq -r '.data[].id')

 # Current stream info, empty if not live
current_stream=$(twitch api get /streams \
  -q user_id=$current_streamer_id \
  -q type=live
)
current_stream_id=$(echo $current_stream | jq -r ".data[].id");


echo -e "${ORANGE}[VodManager] ${NC} ${PURPLE}Vod Data${NC} ${vod_data}"

echo -e "${ORANGE}[VodManager] ${NC} ${PURPLE}Stream Data${NC} ${current_stream}"

echo -e "${ORANGE}[VodManager] ${NC} ${PURPLE}current_stream_id${NC} ${current_stream_id}"

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
# if streamer is live (id is non-zero) AND current stream id is the current vod id
if [[ -n "$current_stream_id" ]] || [[ "$current_stream_id" == "$vod_stream_id" ]]; then

   echo -e "${ORANGE}[VodManager] ${NC} [1] ${RED}Vod ${ORANGE}${v}${RED} still live!!! Skipping.${NC}"

fi

# Check stream data
   # check if duration changed
   #

#echo -e "${ORANGE}[VodManager] ${NC} [2] ${RED}Vod ${ORANGE}${v}${RED} still live!!! Skipping.${NC}"

#   echo -e "${ORANGE}[VodManager] ${NC} Vod ${ORANGE}${v}${NC} is ready to download 😎"
#fi


#set +x