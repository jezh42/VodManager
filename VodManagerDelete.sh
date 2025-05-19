#!/bin/bash
# VodManager Delete Old Combined
#
# Run: ./VodManagerDelete.sh
#
# Deletes old combined VODs, if the originals still exist
# Old >= 14 days


# Global Vars
shopt -s extglob
vods_location='/mnt/NAS_Drive/VODs/AlsoMij/'
deletion_days=14

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

size_before=$(du -hs ${vods_location} | cut -f1)
size_before_bytes=$(du -hbs ${vods_location} | cut -f1)
#echo -e "${ORANGE}[VodManager]${NC} File size before: ${size_before}"
#echo -e "${ORANGE}[VodManager]${NC} File size before: ${size_before_bytes}"

# First Delete the TwitchDownloaderCLI Cache (w/ prompt)
TwitchDownloaderCLI cache --force-clear --banner false

vod_delete=0
chat_delete=0
chat_mask_delete=0

# Loop through all mp4's that are numbers.mp4
for vod in "$vods_location"+([[:digit:]]).mp4
do

  id=$(basename ${vod} .mp4)

  # if same vod_id  _combined.mp4 exists
  if [ -f "${vods_location}${id}_combined.mp4" ]; then
    # date created vod
    date_created_vod_epoch=$(stat -c '%W' ${vods_location}${id}.mp4)
    three_months_ago_epoch=$(date -d "${deletion_days} days ago" +"%s")

    if [ ${three_months_ago_epoch} -gt ${date_created_vod_epoch} ]; then

      echo -e "${ORANGE}[VodManager]${NC} Deleting VOD ${RED}${id}${NC}"

      # +1 delete
      let vod_delete++
      rm ${vods_location}${id}_combined.mp4;
    fi
  fi

  # if same vod_id  _chat.mp4 exists
  if [ -f "${vods_location}${id}_chat.mp4" ]; then
    # date created vod
    date_created_vod_epoch=$(stat -c '%W' ${vods_location}${id}.mp4)
    three_months_ago_epoch=$(date -d "${deletion_days} days ago" +"%s")

    if [ ${three_months_ago_epoch} -gt ${date_created_vod_epoch} ]; then

      echo -e "${ORANGE}[VodManager]${NC} Deleting VOD Chat ${RED}${id}${NC}"

      # +1 delete
      let chat_delete++
      rm ${vods_location}${id}_chat.mp4;
    fi
  fi

  # if same vod_id  _chat_mask.mp4 exists
  if [ -f "${vods_location}${id}_chat_mask.mp4" ]; then
    # date created vod
    date_created_vod_epoch=$(stat -c '%W' ${vods_location}${id}.mp4)
    three_months_ago_epoch=$(date -d "${deletion_days} days ago" +"%s")

    if [ ${three_months_ago_epoch} -gt ${date_created_vod_epoch} ]; then

      echo -e "${ORANGE}[VodManager]${NC} Deleting VOD Chat Mask ${RED}${id}${NC}"

      # +1 delete
      let chat_mask_delete++
      rm ${vods_location}${id}_chat_mask.mp4;
    fi
  fi
done

echo -e "${ORANGE}[VodManager]${NC} VODs deleted ${RED}${vod_delete}${NC}"
echo -e "${ORANGE}[VodManager]${NC} VOD chat renders deleted ${RED}${chat_delete}${NC}"
echo -e "${ORANGE}[VodManager]${NC} VOD chat masks deleted ${RED}${chat_mask_delete}${NC}"

size_after=$(du -hs ${vods_location} | cut -f1)
size_after_bytes=$(du -hbs ${vods_location} | cut -f1)
echo -e "${ORANGE}[VodManager]${NC} File size before: ${PURPLE}${size_before}${NC}"
echo -e "${ORANGE}[VodManager]${NC} File size after: ${PURPLE}${size_after}${NC}"
size_diff=$((size_before_bytes-size_after_bytes))
size_diff_hr=$(echo ${size_diff} | numfmt --to=iec)
echo -e "${ORANGE}[VodManager]${NC} File size difference: ${PURPLE}${size_diff_hr}${NC}"