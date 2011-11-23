#singleinstance force
#include FcnLib.ahk
#include thirdParty/Notify.ahk
#singleinstance force

;GetClientInfo()
;debug(GetLynxVersion())
;CheckDatabaseFileSize()
;GetPerlVersion()
;GetApacheVersion()
;debug(IsApacheUpgradeNeeded(), IsPerlUpgradeNeeded())
;sleep, 1000
;ExitApp

;notify("message")
;notify("title", "text")
;sleepseconds(2)

;Beginning of the actual script
SendEmailNow("Starting an upgrade", A_ComputerName, "", "cameron@mitsi.com")
RunTaskManagerMinimized()
LynxOldVersion:=GetLynxVersion()

DownloadLynxFile("version.txt")
LynxDestinationVersion := FileRead("C:\temp\lynx_upgrade_files\version.txt")
msg("Attempting an upgrade from Lynx Version: " . LynxOldVersion . " to " . LynxDestinationVersion)

DownloadLynxFile("unzip.exe")
DownloadLynxFile("upgrade_pack.zip")
UnzipInstallPackage("upgrade_pack.zip")

;PerlOldVersion:=GetPerlVersion()
PerlUpgradeNeeded:=IsPerlUpgradeNeeded()
ApacheUpgradeNeeded:=IsApacheUpgradeNeeded()
;msg("Check the perl version to ensure that it is not older than 5.8.9")
;msg("If the perl version is older than 5.8.9, download the new perl")

msg("Ensure the SMS key is being created.")
CheckDatabaseFileSize()
GetServerSpecs()
GetClientInfo()
msg("Backup Lynx database")

msg("Turn off IIS, change port to 8081, turn off app pools")
msg("Turn off apache")
msg("Run perl start-msg-service.pl removeall")

if PerlUpgradeNeeded
{
   msg("Uninstall perl")
   ;TODO wait for the finished page of the installer
   ;UNCOMMENTME FileDeleteDir("C:\Perl")
   msg("Install new perl")
   ;TODO wait for the finished page of the installer
}

msg("Copy the contents of the zip files into C:\inetpub")
msg("If sql.txt or sql2.txt are not in the inetpub folder, then add them from \tools\")

if ApacheUpgradeNeeded
{
   msg("Uninstall apache")
   ;TODO wait for the finished page of the installer
   ;ensure the service is gone
   msg("Install apache")
   ;TODO wait for the finished page of the installer
}

msg("Run perl banner.plx")
msg("Run perl checkdb.plx")
msg("Restart apache services`n(wait until complete before performing the next step)")
msg("Run perl start-msg-service.pl installall")

msg("Send Test SMS message, popup (to server), and email (to lynx2).")

;admin login (web interface)
;TODO pull password out of DB and open lynx interface automatically
msg("Open the web interface, log in as admin, Install the new SMS key")
msg("under change system settings, then under file system locations and logging change logging to extensive, log age to yearly, message age to never, and log size to 500MB. Save your changes")
msg("Ask the customer if they have a public subscription page, and if not: Under Home Page and Subscriber Setup, change the home page to no_subscription.htm")
msg("Under back up system, set system backups monthly and database backups weekly")

;msg("Restart the services one at a time in the Apache control services manager")

;security login (web interface)
;TODO pull password out of DB and open lynx interface automatically
msg("Add the four LynxGuide supervision channels: 000 Normal, 006, 007, 008, 009")
msg("Add lynx2.mitsi.com to the LynxGuide channels 000 Normal, 000 Alarm, 001, 002, 003, 009")
msg("Add 000 Normal, supervision restored for all hardware alarm groups")
msg("Add lynx2@mitsi.com to 000 Alarm, 000 Normal and 990")

;TODO do all windows updates (if their server is acting funny)

;testing
msg("Note in sugar: Tested SMS and Email to lynx2@mitsi.com, failed/passed by [initials] mm-dd-yyyy")

msg("Note server version, last updated in sugar")
msg("Make case in sugar for 'Server Software Upgrade', note specific items/concerns addressed with customer in description")

LynxNewVersion := GetLynxVersion()
ShowUpgradeSummary()
SendLogsHome("upgrade")
ExitApp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; functions

;ghetto hotkey
Appskey & r::
SetTitleMatchMode, 2
WinActivate, Notepad
WinWaitActive, Notepad
Sleep, 200
Send, {ALT}fs
Sleep, 200
reload
return


GetClientInfo()
{
   ;TODO need to filecreate the perl code to client_info.plx

   ret := CmdRet_RunReturn("perl client_info.plx", "C:\inetpub\wwwroot\cgi\")
   ;ret := String
   msg("Enter client data from Lynx Database into Sugar`n`n" . ret)
   return ret
}

msg(message)
{
   MsgBox, , Lynx Upgrade Assistant, %message%
}

LynxError(message)
{
   msg("ERROR: " . message)
}

;Returns a true or false, confirming that they did or didn't complete this step
ConfirmMsgBox(message)
{
   title=Lynx Install

   MsgBox, 4, %title%, %message%
   IfMsgBox, Yes
      return true
   else
      return false
}

importantLogInfo(message)
{
}

logInfo()
{
}

UnzipInstallPackage(file)
{
   notify("unzipping install package")
   ;7z=C:\temp\lynx_upgrade_files\7z.exe
   unzip=C:\temp\lynx_upgrade_files\unzip.exe
   p=C:\temp\lynx_upgrade_files
   ;cmd=%7z% a -t7z %p%\archive.7z %p%\*.txt
   cmd=%unzip% %p%\%file%.zip -d %p%\%file%
   CmdRet_RunReturn(cmd, p)
   notify("finished unzipping install package")
}

;WRITEME
DownloadLynxFile(filename)
{
   global downloadPath

   TestDownloadProtocol("ftp")
   TestDownloadProtocol("http")

   destinationFolder=C:\temp\lynx_upgrade_files
   url=%downloadPath%/%filename%
   dest=%destinationFolder%\%filename%

   FileCreateDir, %destinationFolder%
   UrlDownloadToFile, %url%, %dest%

   ;TODO perhaps we want to unzip the file now (if it is a 7z)
}

TestDownloadProtocol(testProtocol)
{
   global connectionProtocol
   global downloadPath

   if connectionProtocol
      return ;we already found a protocol, so don't run the test again

   ;prepare for the test
   pass:=GetLynxPassword("generic")
   if (testProtocol == "ftp")
      downloadPath=ftp://update:%pass%@lynx.mitsi.com/upgrade_files
   else if (testProtocol == "http")
      downloadPath=http://update:%pass%@lynx.mitsi.com/Private/techsupport/upgrade_files

   ;test it
   url=%downloadPath%/test.txt
   joe:=UrlDownloadToVar(url)

   ;determine if the test was successful
   if (joe == "test message")
      connectionProtocol:=testProtocol
}

RunTaskManagerMinimized()
{
   Run, taskmgr
   WinWait, Windows Task Manager
   WinMinimize
}

GetServerSpecs()
{
   Loop 4
   {
      thisIP := A_IPaddress%A_Index%
      if (thisIP != "0.0.0.0")
         IPlist .= "`n" . thisIP
   }
   msg=The server's IP addresses are: %IPlist%`nPlease enter this info into Sugar
   msg(msg)

   Run, control /name Microsoft.System
   WinWait, System
   Sleep, 1000
   ;UNCOMMENTME SaveScreenShot("serverSpecs", "C:\inetpub\logs\lynxUpgrades\", "activeWindow")
   msg("Enter server Computer Name, RAM, Processor Speed and OS into Sugar")
   WinClose, System
}

GetPerlVersion()
{
   output:=CmdRet_RunReturn("perl -v")
   RegExMatch(output, "v([0-9.]+)", match)
   return match1
}

GetApacheVersion()
{
   output := CmdRet_RunReturn("C:\Program Files (x86)\Apache Software Foundation\Apache2.2\bin\httpd.exe -v")
   RegExMatch(output, "Apache.([0-9.]+)", match)
   return match1
}

IsPerlUpgradeNeeded()
{
   if (GetPerlVersion() != "5.8.9")
      return true
   else
      return false
}

IsApacheUpgradeNeeded()
{
   if (GetApacheVersion() != "2.2.21")
      return true
   else
      return false
}

GetLynxVersion()
{
   ;TODO need to filecreate the perl code to client_info.plx

   clientInfo := CmdRet_RunReturn("perl client_info.plx", "C:\inetpub\wwwroot\cgi\")
   ;return clientInfo
   RegExMatch(clientInfo, "LynxMessageServer3\t([0-9.]+)", match)
   returned := match1
   ;msg("Enter client data from Lynx Database into Sugar`n`n" . ret)
   return returned

   ;TODO might want to check both the DB and the version file
   ;versionFile=C:\inetpub\version.txt
   ;if NOT FileExist(versionFile)
      ;returned=lynx-old-build
   ;else
      ;FileRead, returned, %versionFile%

   return returned
}

ShowUpgradeSummary()
{
   global LynxOldVersion
   global LynxNewVersion
   msg=Upgraded server from %LynxOldVersion% to %LynxNewVersion%
   msg(msg)
}

CheckDatabaseFileSize()
{
   ;dbFile=C:\Program Files\Microsoft SQL Server\MSSQL10_50.SQLEXPRESS\MSSQL\DATA\lLynx.mdf
   ;dbFile=C:\Program Files\Microsoft SQL Server\MSSQL\MSSQL\DATA\lLynx.mdf
   dbSearchPath=C:\Program Files\Microsoft SQL Server\*
   Loop, %dbSearchPath%, 0, 1
   {
      if RegExMatch(A_LoopFileName, "Lynx\.mdf$")
         dbFile := A_LoopFileFullPath
   }
   dbSearchPath=C:\Program Files (x86)\Microsoft SQL Server\*
   Loop, %dbSearchPath%, 0, 1
   {
      if RegExMatch(A_LoopFileName, "Lynx\.mdf$")
         dbFile := A_LoopFileFullPath
   }

   if FileExist(dbFile)
   {
      dbSize:=FileGetSize(dbFile, "M")
      if (dbSize > 200)
      {
         msg=Inform level 2 support that the database file size is %size%MB
         msg(msg)
      }
   }
   else
   {
      importantLogInfo("Could not find database file")
      msg("Check database file size to ensure it is smaller than 200MB, if it is larger than 200MB, inform level 2 support")
   }
}

#include Lynx-FcnLib.ahk