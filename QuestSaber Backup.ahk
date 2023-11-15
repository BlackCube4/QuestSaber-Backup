#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
CoordMode, ToolTip, Screen
#Include libs\ADBcheck.ahk
#Include libs\UpdatePlaylists.ahk
#Include libs\SeperateSongsInPlaylistFolders.ahk
#Include libs\CreatePlaylistString.ahk
#Include libs\SearchNewestDir.ahk

; Calculate the position for the tooltip (bottom right corner)
ToolTipX := A_ScreenWidth - 20
ToolTipY := A_ScreenHeight - 70

; Create a initial state object
stateObject := {"ChooseLocation": 0, "BackupModData": 1, "BackupBMBFData": 0, "BackupAndroid": 0, "UpdatePlaylists": 1, "SeperateSongs": 1, "CreateUnsorted": 1, "RecombineSongs": 1, "MovePlaylistsToQuest": 1, "MoveSongsToQuest": 1}

; Write INI file data to stateObject
for name, value in stateObject
{
    IniRead, buffer, State.ini, States, %name%, %value%
	stateObject[name] := buffer
}

;Create Gui
Gui, Add, Checkbox, vChooseLocation gChooseLocation, choose Backup location

Gui, Add, Checkbox, y+15 vBackupModData gBackupModData Checked, Backup ModData
Gui, Add, Checkbox, vBackupBMBFData gBackupBMBFData, Backup BMBFData
Gui, Add, Checkbox, vBackupAndroid gBackupAndroid, Backup Android

Gui, Add, Checkbox, y+15 vUpdatePlaylists Checked, update Playlists
Gui, Add, Checkbox, vSeperateSongs Checked, seperate Songs
Gui, Add, Checkbox, vCreateUnsorted Checked, create Unsorted Playlist

Gui, Add, Checkbox, y+15 vMovePlaylistsToQuest Checked, move Playlists back to Quest
Gui, Add, Checkbox, vMoveSongsToQuest Checked, move Songs back to Quest

Gui, Add, Button, Default gExecuteEverything w200 h40, Execute Everything
Gui, Add, Button, gUpdatePlaylistsButton w200 h40, only Update Playlists
Gui, Add, Button, gCreatePlaylistFromFolder w200 h40, create Playlist from Folder
Gui, Add, Button, gForceQuestExplorer w200 h40, force Quest to show in File Explorer
Gui, +Resize +MinSize
Gui, Margin, 10, 10
Gui, Show, , QuestSaber Backup

; Set the state of the checkboxes
for name, value in stateObject
    GuiControl, , %name%, %value%
return

ChooseLocation:
	Gui, Submit, NoHide
	if (BackupModData=0 and BackupAndroid=0 and BackupBMBFData=0)
		GuiControl, , ChooseLocation, 1
return

BackupModData:
BackupAndroid:
BackupBMBFData:
	Gui, Submit, NoHide
	if (BackupModData=0 and BackupAndroid=0 and BackupBMBFData=0)
		GuiControl, , ChooseLocation, 1
return

UpdatePlaylistsButton:
	ADBcheck()
	ADBdeviceConnected()
	ToolTip, Download Playlists, %ToolTipX%, %ToolTipY%
	RunWait, adb\adb.exe pull "/sdcard/ModData/com.beatgames.beatsaber/Mods/PlaylistManager/Playlists" "tempPlaylists", , Hide
	ToolTip, Generating Song List, %ToolTipX%, %ToolTipY%
	songList := generateSongListQuest()
	ToolTip, Updating Playlists, %ToolTipX%, %ToolTipY%
	updatePlaylists(songList, tempPlaylists)
	ToolTip, Uploading Playlists, %ToolTipX%, %ToolTipY%
	RunWait, % "cmd /c " . "adb\adb.exe shell rm -r ""/sdcard/ModData/com.beatgames.beatsaber/Mods/PlaylistManager/Playlists""", , Hide
	RunWait, % "cmd /c " . "adb\adb.exe push ""tempPlaylists"" ""/sdcard/ModData/com.beatgames.beatsaber/Mods/PlaylistManager/Playlists""", , Hide
	FileRemoveDir, tempPlaylists, 1
return

CreatePlaylistFromFolder:
	FileSelectFolder, songDir, *%A_ScriptDir%, , Choose the folder with the songs you want to put into a playlist
	if (ErrorLevel != 0) {
		ExitApp
	}
	FileSelectFolder, playlistDir, *%A_ScriptDir%, , Choose where to put the Playlist file
	if (ErrorLevel != 0) {
		ExitApp
	}
	createPlaylistString(songDir, playlistDir)
return

ForceQuestExplorer:
	ADBcheck()
	ADBdeviceConnected()
	RunWait, adb\adb.exe shell svc usb setFunctions mtp true
return

ExecuteEverything:
saveState()

FormatTime, timeNow, %A_Now%, dd.MM.yyyy_HH.mm
backupDir := A_ScriptDir . "\Backup_" . timeNow

if (ChooseLocation) {
	FileSelectFolder, backupDir, *%A_ScriptDir%, , Choose a location for/of the Backup
	if (ErrorLevel != 0) {
		ExitApp
	}
}

if (BackupModData or BackupBMBFData or BackupAndroid) {
	ADBcheck()
	ADBdeviceConnected()
	if (ChooseLocation = 0)
		FileCreateDir, %backupDir%
}

if (BackupModData){
	ToolTip, Download ModData, %ToolTipX%, %ToolTipY%
	RunWait, adb\adb.exe pull "/sdcard/ModData" "%backupDir%", , UseErrorLevel Hide
	if (ErrorLevel) 
	{
		errorFolders := searchNewestDir(backupDir)
		for index, errorFolder in errorFolders
		{    
			errorFolder := StrReplace(errorFolder, "\", "/")
			RunWait, % "cmd /c " . "adb\adb.exe shell ls ""/sdcard" . errorFolder . """" . " > output.txt", , Hide

			longestLength := 0
			; Loop over all lines in output.txt
			Loop, Read, output.txt 
			{
				length := StrLen(A_LoopReadLine)

				; If the current line is longer than the longest line found so far, update the longest line and its length
				if (length > longestLength) 
				{
					longestLength := length
					longestLine := A_LoopReadLine
				}
			}
			FileDelete, output.txt
			if (longestLength > 30) 
			{
				RegExMatch(longestLine, ".*\.(.*)", match)
				if (match1 = "egg" or match1 = "png" or match1 = "jpg" or match1 = "jpeg")
				{
					break
				}
			}
		}

		if (longestLength > 30) 
		{
			RegExMatch(longestLine, ".*\.(.*)", match)
			if (match1 = "egg")
			{
				shortFileName := RegExReplace(longestLine, ".*(\..*)", "Song$1")
			}
			else if (match1 = "png" or match1 = "jpg" or match1 = "jpeg")
			{
				shortFileName := RegExReplace(longestLine, ".*(\..*)", "CoverImage$1")
			}
			else 
			{
				Msgbox, An unknown error occurred while copying the files.`n`n(unexpected extension %match1% %longestLine%)
				ExitApp
			}
			vSize := StrPut(longestLine, "CP0")
			VarSetCapacity(vUtf8, vSize)
			vSize := StrPut(longestLine, &vUtf8, vSize, "CP0")
			longestLineUTF := StrGet(&vUtf8, "UTF-8")
			Msgbox, 4, Error, % "An error occurred while copying the files.`nMaby the following filename was to long:`n`n" . errorFolder . "/" . longestLineUTF . "`n`nWould you like to change it to:`n`n" . errorFolder . "/" . shortFileName . "`n`n and try again?"
			IfMsgBox, Yes 
			{
				longestLineEscaped := StrReplace(longestLineUTF, " ", "\ ")
				Command := "cmd /c " . "adb\adb.exe shell mv ""/sdcard" . errorFolder . "/" . longestLineEscaped . """" . " ""/sdcard" . errorFolder . "/" . shortFileName . """"
				RunWait, %Command%, , Hide
				RunWait, % "cmd /c " . "adb\adb.exe pull ""/sdcard" . errorFolder . "/info.dat" . """" . " """ . A_WorkingDir . """", , Hide
				FileRead, infoContent, %A_WorkingDir%\info.dat
				infoContent := StrReplace(infoContent, longestLine, shortFileName)
				FileDelete, %A_WorkingDir%\info.dat
				FileAppend, %infoContent%, %A_WorkingDir%\info.dat
				RunWait, % "cmd /c " . "adb\adb.exe push """ . A_WorkingDir . "\info.dat"" " . """/sdcard" . errorFolder . "/info.dat""", , Hide
				FileDelete, %A_WorkingDir%\info.dat
				FileRemoveDir, %backupDir%, 1
				Run, % """" . A_ScriptFullPath . """"
				ExitApp
			}
			else 
			{
				ExitApp
			}
		}
		else
		{
			Msgbox, An unknown error occurred while copying the files.`n`n(longestLength %longestLength%<30 %longestLine%)
			ExitApp
		}
	}
}

if (BackupBMBFData){
	ToolTip, Download BMBFData, %ToolTipX%, %ToolTipY%
	RunWait, adb\adb.exe pull "sdcard/BMBFData" "%backupDir%", , Hide
}

if (BackupAndroid){
	ToolTip, Download Android, %ToolTipX%, %ToolTipY%
	FileCreateDir, %backupDir%\Android\data
	RunWait, adb\adb.exe pull "sdcard/Android/data/com.beatgames.beatsaber" "%backupDir%\Android\data", , Hide

	FileCreateDir, %backupDir%\Android\obb
	RunWait, adb\adb.exe pull "sdcard/Android/obb/com.beatgames.beatsaber" "%backupDir%\Android\obb", , Hide
}

if (UpdatePlaylists){
	ToolTip, Updating Playlists, %ToolTipX%, %ToolTipY%
	songList := foldersInDir(backupDir . "\ModData\com.beatgames.beatsaber\Mods\SongLoader\CustomLevels")
	updatePlaylists(songList, backupDir . "\ModData\com.beatgames.beatsaber\Mods\PlaylistManager\Playlists")
}

if (SeperateSongs){
	ToolTip, Seperating Songs into Folders, %ToolTipX%, %ToolTipY%
	seperateSongsInPlaylistFolders(backupDir)
}

if (CreateUnsorted){
	ToolTip, Creating Unsorted Playlist, %ToolTipX%, %ToolTipY%
	unsortedDir := backupDir . "\ModData\com.beatgames.beatsaber\Mods\SongLoader\Unsorted"
	playlistDir := backupDir . "\ModData\com.beatgames.beatsaber\Mods\PlaylistManager\Playlists"
	createPlaylistString(unsortedDir, playlistDir)
}

if (MovePlaylistsToQuest or MoveSongsToQuest){
	ADBcheck()
	ADBdeviceConnected()
	if (MovePlaylistsToQuest){
		ToolTip, Copying Playlists to Quest, %ToolTipX%, %ToolTipY%
		RunWait, % "cmd /c " . "adb\adb.exe shell rm -r ""/sdcard/ModData/com.beatgames.beatsaber/Mods/PlaylistManager/Playlists""", , Hide
		RunWait, % "cmd /c " . "adb\adb.exe push """ . backupDir . "\ModData\com.beatgames.beatsaber\Mods\PlaylistManager\Playlists"" " . """/sdcard/ModData/com.beatgames.beatsaber/Mods/PlaylistManager/Playlists""", , Hide
	}
	if (MoveSongsToQuest){
		ToolTip, Copying Songs to Quest, %ToolTipX%, %ToolTipY%
		RunWait, % "cmd /c " . "adb\adb.exe shell rm -r ""/sdcard/ModData/com.beatgames.beatsaber/Mods/SongLoader/CustomLevels""", , Hide
		RunWait, % "cmd /c " . "adb\adb.exe push """ . backupDir . "\ModData\com.beatgames.beatsaber\Mods\SongLoader\CustomLevels"" " . """/sdcard/ModData/com.beatgames.beatsaber/Mods/SongLoader/CustomLevels""", , Hide
	}
}

msgbox, Everything finished ^^

GuiClose:
saveState()
ExitApp

saveState(){
	global
	Gui, Submit
	; Write the state of the checkboxes to the INI file
	for name, value in stateObject
		IniWrite, % %name%, State.ini, States, %name%
}