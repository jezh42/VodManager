# VodManager

Requires the following programs installed and configured (e.g. auth setup) and in your PATH:
 - youtubeuploader
 - ffmpeg
 - twitch
 - TwitchDownloaderCLI

## Features:
 - Downloads VODs
 - Downloads Chat
 - Renders Chat
 - Combines Chat onto video
 - Old Vod is still kept
 - Uploads to Youtube via [YoutubeUploader](https://github.com/porjo/youtubeuploader)


## Future Features:
 - Better and cleaner logging
 - Command Line count vods
 - Supporting multiple streamers
 - Chapter support?
 - Run Daily
   - OR
 - Always run as a service, checking for new vods
 - Zig Version
 - Quit Management
 - Configuration file
   - Vod Location
   - List of streamers
   - Start with newest or oldest
 - FFMpeg Status
 - General Declutter of Output
 - Verbose Support (-v)
 - Debugging Support (-d)
 - Logging/tee log natively
 - Log youtube completed video URL

## Bugs

TODO:
- ID and Title search (with jq) is a bit weird
   - Might convert to Zig to work better with objects and json
- Strip Invalid Chars for Youtube Title `>-<`

## Youtube API

 - Follow the configuration steps detailed in [YoutubeUploader](https://github.com/porjo/youtubeuploader).

 - Recommended to publish your GCP Project.

 - Keeping it in testing only gives refresh tokens that last 7 days.

 - Publishing it doesn't require verification for our uses and gives refresh tokens that last forever.