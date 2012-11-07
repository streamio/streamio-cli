# Streamio CLI (Command Line Interface)

A gem for interacting with Streamio through the command line.

## Installation

    gem install streamio-exporter

## Usage

After installation you can use the streamio command from your
terminal. To get a list of available tasks run `streamio` without
any arguments.

To get help on a specific task run `streamio help name_of_task`.
For example run `streamio help export` to get usage scenario
and available options for the export task.

### Export

You can use the export task to download all videos and audios
from your Streamio account. First use your terminal to navigate
to a directory where you wish the export to be downloaded to.
Then use the command together with your api username and password
found under Account Settings > API when logged in to streamio.com.

    streamio export -u api_username -p api_password

By default only the original files will be downloaded. If you
wish to include transcodings you may add the `-i` parameter.

    streamio export -u api_username -p api_password -i

The export will use the following file structure for the downloads:

    streamio-export/videos/<video_id>/<video_filename>
    streamio-export/audios/<audio_id>/<audio_filename>

A json file containing the metadata of each resource will also
be availible:

    streamio-export/videos/<video_id>/<video_id>.json
    streamio-export/videos/<audio_id>/<audio_id>.json

Note that it is likely that you will need a developer to actually
make use of the exported material.
