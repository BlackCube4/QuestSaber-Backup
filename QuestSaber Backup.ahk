#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Include libs\ADBcheck.ahk
#Include libs\UpdatePlaylists.ahk
#Include libs\SeperateSongsInPlaylistFolders.ahk
#Include libs\PackUnsortedSongsIntoFolder.ahk
#Include libs\CreatePlaylistString.ahk
#Include libs\RecombineSongs.ahk
#Include libs\SearchNewestDir.ahk

Gui, Add, Checkbox, vChooseLocation, choose Backup location
Gui, Add, Checkbox, vBackupModData Checked, Backup ModData
Gui, Add, Checkbox, vBackupBMBFData, Backup BMBFData
Gui, Add, Checkbox, vBackupAndroid, Backup Android
Gui, Add, Checkbox, vUpdatePlaylists Checked, update Playlists
Gui, Add, Checkbox, vSeperateSongs Checked, seperate Songs
Gui, Add, Checkbox, vCreateUnsorted Checked, create Unsorted Playlist
Gui, Add, Checkbox, vRecombineSongs Checked, recombine Songs
Gui, Add, Checkbox, vMoveToQuest Checked, move files back to Quest
Gui, Add, Button, Default gButtonFunction w200 h40, Press me
Gui, +Resize +MinSize280x228y
Gui, Show, , QuestSaber Backup
return

ButtonFunction:
Gui, Submit

FormatTime, timeNow, %A_Now%, dd.MM.yyyy_HH.mm
backupDir := A_ScriptDir . "\Backup_" . timeNow

if (ChooseLocation = 1) {
	FileSelectFolder, backupDir, *%A_ScriptDir%, , Choose a location for/of the Backup
	if (ErrorLevel != 0) {
		ExitApp
	}
}

if (BackupModData = 1 or BackupBMBFData = 1 or BackupAndroid = 1) {
	ADBcheck()
	ADBdeviceConnected()
	if (ChooseLocation = 0)
		FileCreateDir, %backupDir%
}

if (BackupModData = 1){
	RunWait, adb\adb.exe pull "sdcard/ModData" "%backupDir%", , UseErrorLevel Hide
	if (ErrorLevel != 0) 
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

if (BackupBMBFData = 1){
	RunWait, adb\adb.exe pull "sdcard/BMBFData" "%backupDir%", , Hide
}

if (BackupAndroid = 1){
	FileCreateDir, %backupDir%\Android\data
	RunWait, adb\adb.exe pull "sdcard/Android/data/com.beatgames.beatsaber" "%backupDir%\Android\data", , Hide

	FileCreateDir, %backupDir%\Android\obb
	RunWait, adb\adb.exe pull "sdcard/Android/obb/com.beatgames.beatsaber" "%backupDir%\Android\obb", , Hide
}

if (UpdatePlaylists = 1){
	updatePlaylists(backupDir)
}

if (SeperateSongs = 1){
	seperateSongsInPlaylistFolders(backupDir)
}

if (CreateUnsorted = 1){
	;packUnsortedSongsIntoFolder(backupDir)
	createPlaylistString(backupDir)
}

if (RecombineSongs = 1){
	recombineSongs(backupDir)
}

if (MoveToQuest = 1){
	ADBcheck()
	ADBdeviceConnected()
	RunWait, % "cmd /c " . "adb\adb.exe shell rm -r ""/sdcard/ModData/com.beatgames.beatsaber/Mods/SongLoader/CustomLevels""", , Hide
	RunWait, % "cmd /c " . "adb\adb.exe shell rm -r ""/sdcard/ModData/com.beatgames.beatsaber/Mods/PlaylistManager/Playlists""", , Hide
	RunWait, % "cmd /c " . "adb\adb.exe push """ . backupDir . "\ModData\com.beatgames.beatsaber\Mods\SongLoader\CustomLevels\Combined"" " . """/sdcard/ModData/com.beatgames.beatsaber/Mods/SongLoader/CustomLevels""", , ;Hide
	RunWait, % "cmd /c " . "adb\adb.exe push """ . backupDir . "\ModData\com.beatgames.beatsaber\Mods\PlaylistManager\Playlists"" " . """/sdcard/ModData/com.beatgames.beatsaber/Mods/PlaylistManager/Playlists""", , Hide
}

GuiClose:
ExitApp