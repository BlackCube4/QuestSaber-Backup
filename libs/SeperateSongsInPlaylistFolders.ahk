seperateSongsInPlaylistFolders(dir){
	SongList := {}

	Loop, Files, %dir%\ModData\com.beatgames.beatsaber\Mods\PlaylistManager\Playlists\*.*
	{
		;skip non json files
		if (A_LoopFileExt != "json")
			continue
		
		FileRead, Content, %A_LoopFileFullPath%
		RegExMatch(Content, """playlistTitle"":""(.*?)""", PlaylistTitle)
		pos := InStr(Content, "[")
		loop
		{
			matchPos := RegExMatch(Content, """hash"":""(.*?)""", match, pos)
			;stop when not finding any more songs
			if matchPos = 0 
				break
			;url := "https://api.beatsaver.com/maps/hash/" . match1
			;UrlDownloadToFile, %url%, map.json
			;FileReadLine, keyLine, map.json, 2
			;RegExMatch(keyLine, """id"": ""(.*)""", key)

			if (SongList[match1] = "")
				SongList[match1] := PlaylistTitle1
			else
				SongList[match1] := SongList[match1] . "," . PlaylistTitle1
			pos := matchPos + StrLen(match1)
			;msgbox, % matchPos . "`n" . PlaylistTitle1 . "`n" . SongList[match1]
		}
	}

	Loop, Files, %dir%\ModData\com.beatgames.beatsaber\Mods\SongLoader\CustomLevels\*.*, D
	{
		RegExMatch(A_LoopFileName, "(^\S*) ?", Hash)
		if (StrLen(Hash1) < 15) {
			url := "https://api.beatsaver.com/maps/id/" . Hash1
			UrlDownloadToFile, %url%, map.json
			FileRead, Content, map.json
			RegExMatch(Content, "m)""hash"": ""([A-Za-z0-9]{30,})""", Hash)
		}
		Playlists := StrSplit(SongList[Hash1], ",")

		FileMoveDir, %A_LoopFileFullPath%, %A_LoopFileDir%\%Hash1%, R

		;if (StrLen(A_LoopFileName) > 43 or StrLen(A_LoopFileName) < 35)
		;	msgbox, % "Filename: " A_LoopFileName "`n`n" "Hash: " Hash1 "`n`n" "Playlists: " SongList[Hash1] "`n`n" "FilenameCount: " Playlists.Length()
		if (Playlists.Length() = 0) {
			FileCopyDir, %A_LoopFileDir%\%Hash1%, %dir%\ModData\com.beatgames.beatsaber\Mods\SongLoader\Unsorted\%Hash1%
		} else {
			for index, entry in Playlists
			{
				FileCopyDir, %A_LoopFileDir%\%Hash1%, %dir%\ModData\com.beatgames.beatsaber\Mods\SongLoader\%entry%\%Hash1%
			}
		}
	}

	FileDelete, map.json
}