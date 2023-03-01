# Record-Radio

The Rec-Radio scripts will record internet radio. There are two versions: Windows DOS (.bat), and Linux bash (.sh). Typically Rec-Radio is scheduled to run via Windows Task Scheduler, or Linux crontab. This makes Rec-Radio an equivalent of a DVR for internet radio shows.

I created Rec-Radio as a sample script to avoid missing live shows broadcast when I wasn't around. I live in the USA, on the west coast, and sometimes want to record UK shows that are on while I am asleep. Rec-Radio is my answer. I started with the DOS version, then added Linux in order to run it on a Raspberry Pi. In practice I run the bash script on a Raspberry Pi and schedule my recordings there with crontab. Since my day-to-day computer is Windows, I added another DOS script (rpiradio.bat) to transfer the recorded mp3 files over to Windows. I run rpiradio.bat automatically every time my PC  wakes up from sleep (See the Wiki for details).

Rec-Radio uses ffmpeg to do the recording. It is available in Linux package managers. For Windows, ffmpeg.exe can be downloaded as a pre-compiled binary from several sites. For example download [ffmpeg-git-essentials.7z](https://www.gyan.dev/ffmpeg/builds/)

The scripts here do not contain any specific radio stations. You will want to add your own. I provide my own examples below. The Wiki provides some information about Internet Radio Streaming and includes some tips on how to determine the URL required to stream from your favorite station.

## Usage

Three script parameters are required,

* **Station-Name**
  * the name of a station to be recorded. This name is matched against a table of stations and their stream URLs in the script.
  * NO SPACES ARE ALLOWED IN THE NAME, EVER
* **NameOfShow**
  * the name of the show to be recorded. This name is included in the filename of the recorded show along with the date and time of recording.
  * NO SPACES ARE ALLOWED IN THE NAME, EVER
* **nnn**  
  * the duration in minutes of the recording

Example: `rec-Radio.bat KPBS myshow 30`

## Setup

The **SETUP SECTION** near the start of the script contains all paths and variables necessary to customize Rec-Radio for a system.

Make sure to set the proper paths for the system in place of those already in the script. All paths must exist before the script is run. Don not add a trailing slash at the end of paths - the script does that.

* `ffmpegpath` - the location of ffmpeg.exe
* `recordingpath` - the location for recorded files. IN the Windows scripts a subfolder `NameOfShow` will be placed under this location and created automatically if it doesn't already exist.
* `logfilepath` - the location for the log file named `RecLog.txt`. This file will only be used if `LoggingRequired` is set to yes.

The Linux bash version keeps station names and their corresponding stream URLs in a `stations` array. Insert as many as you wish.

Windows DOS does not support associative arrays. Instead there are a pair of lists, `stName[]` and `stURL[]`. As written the lists support up to 10 stations, but that number is easily extended.

For Linux remember to make the script executable: `chmod +x Rec-Radio.sh`

## Usage Notes

### Note 1

* The recorded filename will be `NameOfShow-date_time_rec.mp3`
* For Windows scripts the recorded file will be placed under a subfolder `NameOfShow\` under the given recording path.
* FOr the bash version the recorded file will be recorded initially into /tmp/rpiradio. When the recording is completed, the file is moved directly into the given recording path.
* Metadata (ID3) tags are added.
  * If you want different tags, change the ffmpeg statement (carefully). For available tags see <https://gist.github.com/eyecatchup/0757b3d8b989fe433979db2ea7d95a01>
* Recording takes place in the background.
* Feel free to do anything while the script runs, e.g.watch videos, listen to internet radio, etc. Multiple copies of the script can run at the same time.
* Using Task Scheduler on Windows enables scheduled recordings, even when the system is in "sleep mode". See the Wiki for details. Linux has no easy way to do this. The assumption is that a Linux system is always on.

### Note 2

The script opens a minimized window which contains a couple of messages. There may also be some info messages from DOS and ffmpeg. If not errors, ignore them.

### Note 3

For the case when a recording goes onto a hard drive that may be sleeping, not spinning, the script issues a touch command before ffmpeg.exe to spin the disk up. A sleeping HD takes time to reach operating speed, so the start of recording will be delayed. If your HD does not spin down, or if using SSDs, feel free to remove or comment out the 'type nul' and 'del' lines prior to ffmpeg.exe

## Scheduling Recordings

To record show broadcast in a different country, the most frustrating problem is sorting out the switch from standard time to daylight savings time. The problem is that the switch may happen on different weekends in different countries. This is a pain in the neck and messes up scheduled timestamps. For example,

* DST in most of the United States begins each year on the second Sunday in March, when clocks are set forward by one hour. They are turned back again to standard time on the first Sunday in November as DST ends. But Hawaii and Arizona are different!
* In the UK, DST starts on the last Sunday in March, and ends on the last Sunday in October.

I have yet to find good tools to help with this annoyance.

### Using Windows Task Scheduler

These instructions ensure that recordings will happen when the system is active and also when it is in "sleep mode".

* Open the Task Scheduler
* (optional) Create a new folder called "RadioRecordings"
* Select folder, right click, Create New Task
* General tab: Type any name, usually the name of the show. leave "Run when user logged in"
* Triggers tab: New, and e.g. Weekly - select day(s), set start time (local time)
* Actions tab: "Start a Program", for example `Program=C:\rhmc\tr\Rec-Radio.bat`, and Arguments=`StationName NameOfShow 30`
  * Remember: NO SPACES IN StationName or NameOfShow, NONE, EVER
* Conditions tab: Check Power - Wake the computer to start this task (in case we are in "sleep mode")
* Settings tab: Stop the task if it runs longer than: 2 hours (or whatever time makes sense for your show)
* Press OK

When using the Windows Task Scheduler to wake the system from sleep mode, start a scheduled recording 2 minutes earlier than the actual start time. There are several reasons for doing this.

1) Task Scheduler can take more than a minute to wake up the system and run the script.
2) The script contains a 10 second pause before starting to record the show. Why? Safety. If the system is waking from sleep mode, it may take a few seconds before the network is re-established. BTW If your system is always powered up, never goes into sleep mode, feel free to remove or comment out the line 'timeout 10'.

In addition, if a Windows system is in sleep mode, the Windows DOS script can fool the task scheduler (TS). The DOS script immediately exits and restarts in order to run in a minimized window. As a result, TS believes the task has finished almost immediately and will assume the system is now idle. Therefore, when recording a show in Sleep mode, it is necessary to set a power-off after "idle time" period to be longer than any expected recorded show.

### Using Linux crontab

Everything is normal. If preferred, use systemd timers. One of my recordings looks like this in `crontab -l`

`6 17 * * SAT  /home/richard/Rec-Radio.sh World World-Science-Hour 54`

## Examples of station details

I commonly record from my local NPR station, KPBS. Also, from the BBC World Service and BBC Radio 4. Here is how these are specified in the two scripts

Windows DOS, Rec-Radio.bat

```dos
set stName[0]=KPBS
set stURL[0]="http://75.102.53.50:80/kpbs-mp3"
set stName[1]=World
set stURL[1]="http://as-hls-ww-live.akamaized.net/pool_904/live/ww/bbc_world_service/bbc_world_service.isml/bbc_world_service-audio=96000.norewind.m3u8"
set stName[2]=Radio4
set stURL[2]="http://as-hls-ww-live.akamaized.net/pool_904/live/ww/bbc_radio_fourfm/bbc_radio_fourfm.isml/bbc_radio_fourfm-audio=96000.norewind.m3u8"
set stName[3]=unused
set stURL[3]=urlunused
etc.
```

Linux bash, Rec-Radio.sh

```bash
declare -A stations
stations["KPBS"]="http://75.102.53.50:80/kpbs-mp3"
stations["World"]="http://as-hls-ww-live.akamaized.net/pool_904/live/ww/bbc_world_service/bbc_world_service.isml/bbc_world_service-audio=96000.norewind.m3u8"
stations["Radio4"]="http://as-hls-ww-live.akamaized.net/pool_904/live/ww/bbc_radio_fourfm/bbc_radio_fourfm.isml/bbc_radio_fourfm-audio=96000.norewind.m3u8"
```

## To test the DOS script manually and record live radio for 2 minutes

* Make sure all paths are correct for your system (see SETUP SECTION).
* Open a terminal window.
* cd to wherever you stored this script.
* Run the script with a command: `Rec-Radio.bat Station LiveRadio 2`
  * For Linux bash use `./Rec-Radio.sh Station LiveRadio 2`
* For DOS a minimized window will start. You can maximize/minimize it if you want.
  * For Linux, the starting terminal remains running.
* When the recording is finished, the window will close and the mp3 file will be completed with metadata.
* The recorded file will be found at `recordingpath\LiveRadio\LiveRadio-timestamp_rec.mp3`
  * For Linux, the recorded file will be found at `recordingPath\LiveRadio-timestamp_rec.mp3`

## Can I run the script on a hosting site?

Maybe. Most hosting sites run Linux bash. Two requirements must be met,

1. You need cron to make scheduled recordings. (Most hosters provide cron)
2. You must have ffmpeg available on the site.
    * A few hosters include ffmpeg. Check by running `ffmpeg -h` in a terminal.
    * If not, you can try installing a pre-built cross-platform binary from <https://ffbinaries.com/downloads>. Put it in a local directory. It should work fine for this purpose. 
      * To check which binary to download, examine the dashboard carefully to see what is used, or perhaps open a terminal and issue command `uname -a`


