#!/bin/sh
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

vods_location = '/mnt/NAS_Drive/VODs/AlsoMij'
channels = ['AlsoMij']

# Get latest 5x vod Ids (Twitch API)


# Check if downloaded


# for all ids not downloaded
  # TwitchDownloadCLI vod
  # TwitchDownloadCLI chat
  # TwitchDownloadCLI render-chat
  # ffmpeg combine chat ontop of vod -> new vid

# get chapters
