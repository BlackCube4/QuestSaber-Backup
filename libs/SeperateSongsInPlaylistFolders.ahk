seperateSongsInPlaylistFolders(dir){
	SongList := []

	Loop, Files, %dir%\ModData\com.beatgames.beatsaber\Mods\PlaylistManager\Playlists\*.*
	{
		;skip non json files
		if (A_LoopFileExt != "json")
			continue
		
		FileRead, Content, %A_LoopFileFullPath%
		
		RegExMatch(Content, """playlistTitle"":""(.*?)""", PlaylistTitle)

		pos := 1
		loop
		{
			matchPos := RegExMatch(Content, """hash"":""(.*?)"".*?""songName"":""(.*?)""", match, pos)
			
			;stop when not finding any more songs
			if matchPos = 0 
				break
		
			url := "https://api.beatsaver.com/maps/hash/" . match1
			UrlDownloadToFile, %url%, map.json
			FileReadLine, keyLine, map.json, 2
			RegExMatch(keyLine, """id"": ""(.*)""", bskey)

			SongList.Push({ "Playlist": PlaylistTitle1, "Key": bskey1,"Hash": match1, "SongName": match2})

			; Update the position to continue searching for the next match
			pos := matchPos + 62 + StrLen(match2)
		}
	}

	FileDelete, map.json

	; Create an object to store elements and their occurrences
	hashes := {}
	duplicates := {}

	; Loop through the array of objects
	for index, song in SongList
	{
		if hashes.HasKey(song.Hash)
		{
			; Duplicate Hash found
			duplicates[song.Hash] := true
			; msgbox, % "Multible Playlists contain the following `nSong: " . song.SongName . "`nHash: " . song.Hash . "`none of the Playlists: " . song.Playlist
			continue
		}
		else
		{
			; Store the Hash
			hashes[song.Hash] := true
		}
	}

	/*
	for index, song in SongList
	{
		if duplicates.HasKey(song.Hash)
		{
			FileAppend, SongName: %song.SongName%   Hash: %song.Hash%   Key: %song.Key%   Playlist: %song.Playlist%`n, duplicates.txt
		}
	}
	*/

	/*
	FileDelete, MySongs.ini
	for index, song in SongList
	{
		Value := song.Key . "; " . song.Hash
		Section := song.Playlist
		Key := song.SongName
		IniWrite, %Value%, MySongs.ini, %Section%, %Key%
	}
	*/

	deleteList := []
	for index, song in SongList
	{
		Playlist := song.Playlist
		foundMatch := 0
		basicPath := dir . "\ModData\com.beatgames.beatsaber\Mods\SongLoader\CustomLevels\"
		
		Needle := "^" . song.Hash
		Loop, Files, %basicPath%*.*, D
		{
			if RegExMatch(A_LoopFileName, Needle)
			{
				matchName := A_LoopFileName
				foundMatch ++
				if foundMatch=2
					msgbox, % "More than one Song found :/ `nNeedle" . Needle . "`nFolder: " . A_LoopFileFullPath
			}
		}
		if (foundMatch > 0) {
			if (duplicates.HasKey(song.Hash)) {
				FileCopyDir, %basicPath%%matchName%, % basicPath . Playlist . "\" . song.Hash . " (" . song.Key . ")"
				deleteList.Push(basicPath . matchName)
			}
			else
			{
				FileMoveDir, %basicPath%%matchName%, % basicPath . Playlist . "\" . song.Hash . " (" . song.Key . ")"
			}
		}
		else {
			Needle := "^" . song.Key
			Loop, Files, %basicPath%*.*, D
			{
				if RegExMatch(A_LoopFileName, Needle)
				{
					matchName := A_LoopFileName
					foundMatch ++
					if foundMatch=2
						msgbox, % "More than one Song found :/ `nNeedle" . Needle . "`nFolder: " . A_LoopFileFullPath
				}
			}
			if (foundMatch > 0) {
				if (duplicates.HasKey(song.Hash)) {
					FileCopyDir, %basicPath%%matchName%, % basicPath . Playlist . "\" . song.Hash . " (" . song.Key . ")"
					deleteList.Push(basicPath . matchName)
				}
				else
					FileMoveDir, %basicPath%%matchName%, % basicPath . Playlist . "\" . song.Hash . " (" . song.Key . ")"
			}
			else
			{
				;MsgBox, % "Song is missing `nPlaylist: " . Playlist . "`nSong Name: " . song.SongName
			}
		}
	}

	for index, folderPath in deleteList
	{
		FileRemoveDir, %folderPath%, 1 ; Use the "1" flag to delete non-empty folders
	}
}