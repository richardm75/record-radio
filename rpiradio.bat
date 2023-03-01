@echo off
:: Copyright 2023 Richard Mott
::
:: This DOS batch script transfers new mp3 files from the Raspberry Pi
:: into a given folder on Windows.
:: After the transfer, it deletes those files from the Raspberry Pi.
::
:: This script uses PuTTY CLI utilities pscp and plink, with user name and password.
:: A destination directory must already exist to receive the transferred files.
:: Also a destination\temp\ directory is needed for to separate new transfers from past ones.
::
REM SETUP SECTION
REM =============
REM Note: paths should NOT have a trailing slash, not \ for windows paths, nor / for Linux paths.
REM First, we set information about the remote Raspberry Pi
REM IP address of Pi
set PiHostIP=Rasp-Pi-IPaddress
REM User name on PiHost
set PiUser=my username
REM Password for PiUser
set PiPassword=mypassword
REM Location of recordings on the Pi
set PiRecordings=/home/richard/Radio-Recordings
REM
REM Second, we set information about the local Windows system
REM Location to store files transferred from Pi.
set fileDestination=F:\rpiradio
REM Log File (optional)
REM LoggingRequired can be yes or no (without quotes). If yes, also set the file path for log file RecLog.txt.
REM Note: code below assumes that logfilePath contains the character : (e.g. drive:\some\path )
set LoggingRequired=yes
set logfilePath=C:\rhmc\tr
set /a maxLogLines=100
REM
REM Finally, information to locate PuTTY programs
REM PuTTY path
set puttyPath=C:\Users\richa\OneDrive\portableapps\PortableApps\PuTTYPortable\App\putty
REM END OF SETUP
REM ============

REM First time through, exit this script and restart it in a minimized window.
if not DEFINED IS_MINIMIZED set IS_MINIMIZED=1 && start "" /min "%~dpnx0" %* && exit

REM Second time through we transfer files from the Pi.
 
REM Wait to let the network get established
echo Safety delay, waiting for network to be established.
timeout /t 10

REM Check whether there are any .mp3 files to transfer. If not, we will exit.
%puttyPath%\pscp.exe -ls -pw %PiPassword% -noagent %PiUser%@%PiHostIP%:%PiRecordings% > %logfilePath%\tempMP3.txt
:: Note: the next "for" command is tricky. It assumes that logfilePath contains the character ":"
for /f "tokens=1-3 delims=:" %%j in ('find /c /i ".mp3" %logfilePath%\tempMP3.txt') do set /a numMP3=%%l
del %logfilePath%\tempMP3.txt
echo Number of MP3 files is %numMP3%
if %numMP3% EQU 0 (
    if %LoggingRequired%==yes echo %date%-%time: =0% No MP3 files this time >> %logfilePath%\RecLog.txt
    exit
)
echo New MP3 files found on Pi, beginning transfer.

REM Make sure a sleeping hard drive spins up before downloading by writing to it.
echo Checking that destination HD is ready for transfers.
type nul >> "%fileDestination%\spin-up-sleeping-HD"
timeout /t 1
REM Remove the HD spin-up file
del "%fileDestination%\spin-up-sleeping-HD"
echo HD OK. About to start transfers.

REM Trim log file if it is longer than maxLogLines.
if exist %logfilePath%\newfile.txt del %logfilePath%\newfile.txt
REM Get number of lines 
for /f %%i in ('findstr /r /n "^" %logfilePath%\RecLog.txt ^| find /c ":"') do set /a nol=%%i
echo number of log lines is %nol%

if %nol% LEQ %maxLogLines% goto logOK
REM We need to trim the log file. Leave the last 30 lines in it.

set /a removeUpTo=%nol% - 30
echo remove %removeUpTo% lines from log file

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

REM Transfer all available mp3 files from the Pi recording directory.
%puttyPath%\pscp.exe -pw %PiPassword% -noagent %PiUser%@%PiHostIP%:%PiRecordings%/*.mp3 %fileDestination%\temp\
if errorlevel 1 (
    echo %date%-%time: =0% There was a pscp transfer error >> %logfilePath%\RecLog.txt
	exit
)
echo Transfer(s) from Pi complete.

REM make list of transferred files in file "rpifiles"
REM We do this so that we can deal with each file individually.
if exist %logfilePath%\rpifiles del %logfilePath%\rpifiles
dir /b %fileDestination%\temp\*.mp3 > %logfilePath%\rpifiles

REM Calculate the length of the rpifiles file. We want to know that there are some files listed.
REM Sometimes no files are recorded, so no list. In that case the length of rpifiles will be 0.
for %%a in (c:\rhmc\tr\rpifiles) do set rpifilesize=%%~za

REM For each file transferred, delete it from Pi.
if %rpifilesize% EQU 0 (
    if %LoggingRequired%==yes echo %date%-%time: =0% No Files transferred or deleted from Pi >> %logfilePath%\RecLog.txt
    exit
) else (
    for /f "tokens=*" %%c in (%logfilePath%\rpifiles) do (
		%puttyPath%\plink.exe -ssh -pw %PiPassword% -noagent -no-antispoof %PiUser%@%PiHostIP% "rm %PiRecordings%/%%c"
		if errorlevel 1 (
			if %LoggingRequired%==yes echo %date%-%time: =0% There was a plink-delete error >> %logfilePath%\RecLog.txt
			exit
		)
		move %fileDestination%\temp\%%c %fileDestination%\%%c
		if %LoggingRequired%==yes echo %date%-%time: =0% Transferred file %%c and deleted it from Pi >> %logfilePath%\RecLog.txt
		echo Transferred file %%c and deleted it from Pi
    )
)
echo All done. Ready to exit.
exit

