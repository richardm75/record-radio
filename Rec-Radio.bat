@echo off
REM Copyright 2023 Richard Mott
REM
REM This DOS batch script records a live internet radio show tramsitted via HLS/DASH or Icecast/Shoutcast using ffmpeg.
REM (Optional) Log script run start/end times.
REM It requires ffmpeg installed. 

REM IMPORTANT: See SETUP SECTION below to set paths.

REM Three parameters are required
REM    Station         # The name of the station streaming the show
REM    NameOfShow      # Note: NO SPACES ARE ALLOWED, EVER
REM    nn              # Time in minutes of recording
REM e.g.
REM Rec-Radio.bat KPBS MyShow 30

REM The recorded filename will be "NameOfShow-date_time_rec.mp3"
REM The recorded file will be placed under a subfolder NameOfShow\ under the given recording path.
REM Metadata (ID3) will be added. For available tags see https://gist.github.com/eyecatchup/0757b3d8b989fe433979db2ea7d95a01
REM Use cron to schedule recordings. 

REM SETUP SECTION
REM ============= 
REM Change the next variables to set file paths. IMPORTANT: Do not include \ on the end of paths.
REM IMPORTANT: these paths must exist or the script will fail to store the recorded file, sometimes without flagging an error.
REM Location of ffmpeg.exe
set ffmpegpath=D:\rhmd\ffmpeg\bin
REM Location to store recordings.
REM Note: a subdirectory \NameOfShow will be added automatically.
set recordingpath=F:\winradio
REM Log File (optional)
REM LoggingRequired can be yes or no (without quotes). If yes, also set the file path for log file RecLog.txt.
set LoggingRequired=yes
set logfilePath=c:\rhmc\tr
set /a maxLogLines=100
REM
REM DOS batch doesn't have real arrays, only lists, so we use this awkward approach to
REM make a list of stations and their corresponding URLS.
REM Initially the lists contain 10 entries. Fill in what you need from the start. Leave the rest as unused.
REM It should be obvious how to extend it if required.
REM The `stName` list matches script parameter 1, the name of a station (no spaces, no quotes)
REM the `stURL` list is the stream URL for the station. Enclose in quotes. Not URL encoded.
set stName[0]=Your-station-name
set stURL[0]="http://station-stream-URL"
set stName[1]=unused
set stURL[1]="urlunused"
set stName[2]=unused
set stURL[2]="urlunused"
set stName[3]=unused
set stURL[3]="urlunused"
set stName[4]=unused
set stURL[4]="urlunused"
set stName[5]=unused
set stURL[5]="urlunused"
set stName[6]=unused
set stURL[6]="urlunused"
set stName[7]=unused
set stURL[7]="urlunused"
set stName[8]=unused
set stURL[8]="urlunused"
set stName[9]=unused
set stURL[9]="urlunused"
REM 
REM A few lines of code below will extract fields from date and time strings. The string contents returned 
REM by Windows vary by country/region. It may be necessary to adjust code below to match local results.
REM END OF SETUP
REM ============

REM First time through, exit this script and restart it in a minimized window.
if not DEFINED IS_MINIMIZED set IS_MINIMIZED=1 && start "" /min "%~dpnx0" %* && exit

REM Second time through (restarted script) continue with the recording.
echo DO NOT CLOSE THIS WINDOW, minimize it again - Recording in progress
echo Recording %* mins. Started on %date% at %time%. 

set NameOfStation=%1
set nameofshow=%2
set mins=%3

REM Trim log file if it is longer than maxLogLines.
if exist %logfilePath%\newfile.txt del %logfilePath%\newfile.txt
REM Get number of lines 
for /f %%i in ('findstr /r /n "^" %logfilePath%\RecLog.txt ^| find /c ":"') do set /a nol=%%i
echo number of log lines is %nol%


if %nol% LEQ %maxLogLines% goto logOK
REM We need to trim the log file. Leave the last 30 lines in it.
set /a removeUpTo=%nol% - 30

REM Read each line from the file and drop it until we reach the last 30 lines.
for /f "tokens=1-4 delims=:" %%b in ('findstr /n /r "^" %logfilePath%\RecLog.txt') do (
    if %%b GTR %removeUpTo% (
        echo %%c:%%d:%%e >> %logfilePath%\newfile.txt
    )
)
del %logfilePath%\RecLog.txt
move %logfilePath%\newfile.txt %logfilePath%\RecLog.txt
echo Log file trimmed
goto endLogTrim

:logOK
echo skipped log file trim
:endLogTrim

REM If logging is active, log start of task
if %LoggingRequired%==yes echo %date%-%time: =0% %~nx0 Recording start: %NameOfStation% - %nameofshow% for %mins% minutes to %recordingpath% >> %logfilePath%\RecLog.txt

REM Recording will be placed in %recordingpath%\%nameofshow%\
REM If the recordingpath subfolder does not exist yet, we create it because ffmpeg needs it to be there.
if not exist %recordingpath%\%nameofshow% mkdir %recordingpath%\%nameofshow%

REM Windows date and time formats vary per country/region. Adjust below as necessary.
REM Assumed local date format: Thu 01/12/2023
set dd=%date:~7,2%
set mn=%date:~4,2%
set yyyy=%date:~10,4%
REM Assumed local time format: 10:18:19.25  
REM Note: when hours are single digit, there is a leading space instead of 0. So change it to 0.
set HH=%time:~0,2%
set HH=%HH: =0%
set MM=%time:~3,2%

set timestamp=%yyyy%%mn%%dd%_%HH%-%MM%
set title=%dd%/%mn%/%yyyy%

IF "%mins%"=="" set mins=1
set /a secs="%mins% * 60" 

REM Make sure a sleeping hard drive spins up before downloading
type nul >> "%recordingpath%\%nameofshow%\spin-up-sleeping-HD"
REM Pause to let the network get established
timeout /t 10
REM Remove the HD spin-up file
del "%recordingpath%\%nameofshow%\spin-up-sleeping-HD"

REM Look at parameter 1 (the name of the station to be recorded) and grab the stream URL for it.
REM (Sorry about this `if` and `goto` nonsense, but batch doesn't have associative arrays)

if /i %stName[0]% EQU %NameOfStation% goto have0
if /i %stName[1]% EQU %NameOfStation% goto have1
if /i %stName[2]% EQU %NameOfStation% goto have2
if /i %stName[3]% EQU %NameOfStation% goto have3
if /i %stName[4]% EQU %NameOfStation% goto have4
if /i %stName[0]% EQU %NameOfStation% goto have5
if /i %stName[1]% EQU %NameOfStation% goto have6
if /i %stName[2]% EQU %NameOfStation% goto have7
if /i %stName[3]% EQU %NameOfStation% goto have8
if /i %stName[4]% EQU %NameOfStation% goto have9
REM Whoops! We couldn't match parameter one against any of our known radio stations.
REM So, log that and exit.
if %LoggingRequired%==yes echo %date%-%time: =0% %~nx0 Station name not found in list of stations >> %logfilePath%\RecLog.txt
echo ERROR: Station name %NameOfStation% not recognised. Pausing prior to exit.
pause
exit
:have0
set stream=%stURL[0]%
set StationName=%stName[0]%
goto haveURL
:have1
set StationName=%stName[1]%
set stream=%stURL[1]%
goto haveURL
:have2
set StationName=%stName[2]%
set stream=%stURL[2]%
goto haveURL
:have3
set StationName=%stName[3]%
set stream=%stURL[3]%
goto haveURL
:have4
set StationName=%stName[4]%
set stream=%stURL[4]%
goto haveURL
:have5
set stream=%stURL[5]%
set StationName=%stName[5]%
goto haveURL
:have6
set StationName=%stName[6]%
set stream=%stURL[6]%
goto haveURL
:have7
set StationName=%stName[7]%
set stream=%stURL[7]%
goto haveURL
:have8
set StationName=%stName[8]%
set stream=%stURL[8]%
goto haveURL
:have9
set StationName=%stName[9]%
set stream=%stURL[9]%
goto haveURL

:haveURL
echo Station is: %StationName%
echo URL is: %stream%
:: pause

REM Now download the stream for the show
echo Starting to record
"%ffmpegpath%\ffmpeg.exe" -i %stream% ^
-map 0:a:0 -t %secs% -filter:a "volume=3dB" -y -hide_banner -loglevel warning ^
-metadata album="%nameofshow%" -metadata title="%title%" -metadata date="%yyyy%" -metadata artist="%Stationname%" ^
"%recordingpath%\%nameofshow%\%nameofshow%-%timestamp%_rec.mp3"

if %errorlevel% neq 0 (
    if %LoggingRequired%==yes (
        echo Error after ffmpeg. ErrorLevel is %errorlevel% >> %logfilePath%\RecLog.txt
		echo Variables: Station=%StationName%, nameofshow=%nameofshow%, mins=%mins%, dd=%dd%, mn=%mn%, yyyy=%yyyy%, HH=%HH%, MM=%MM% >> %logfilePath%\RecLog.txt
		echo secs=%secs%, ffmpegpath=%ffmpegpath%, secs=%secs%, date=%yyyy%, title=%title% >> %logfilePath%\RecLog.txt
		echo recordingpath=%recordingpath%, timestamp=%timestamp%, stream=%stream% >> %logfilePath%\RecLog.txt
    )
    exit
)

REM We have a complete recording so log that and exit
REM If logging is active, log end of task
if %LoggingRequired%==yes (
    echo %date%-%time: =0% %~nx0 Recording end  : %nameofshow% for %mins% minutes to %recordingpath% >> %logfilePath%\RecLog.txt
)
pause
exit
