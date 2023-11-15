updatePlaylists(dir){
	hashes := {}
	
	Loop, Files, %dir%\ModData\com.beatgames.beatsaber\Mods\SongLoader\CustomLevels\*, D
	{
		RegExMatch(A_LoopFileName, "(^\S*) ?", Hash)
		if (StrLen(Hash1) < 15) {
			url := "https://api.beatsaver.com/maps/id/" . Hash1
			UrlDownloadToFile, %url%, map.json
			FileRead, Content, map.json
			RegExMatch(Content, "m)""hash"": ""(.*?)""", Hash)
		}
		hashes[Hash1] := true
	}

	FileDelete, map.json

	Loop, Files, %dir%\ModData\com.beatgames.beatsaber\Mods\PlaylistManager\Playlists\*.*
	{
		;skip non json files
		if (A_LoopFileExt != "json")
			continue
		
		FileRead, Content, %A_LoopFileFullPath%
		pos := InStr(Content, "[")
		loop
		{
			matchPos := RegExMatch(Content, """hash"":""(.*?)""", match, pos)
			;stop when not finding any more songs
			if matchPos = 0 
				break
			if !(hashes.HasKey(match1))
			{
				Content := RegExReplace(Content, "{.*?""hash"":.*?},?", "", , 1, pos)
			}
			else {
				; Update the position to continue searching for the next match
				pos := matchPos + StrLen(match1)
			}
		}
		;clean up the last comma that might be left when the last entry was deleted but the next-to-last wasn't
		Content := RegExReplace(Content, "},\]", "}]", , 1, pos)

		FileDelete, %A_LoopFileFullPath%
		FileAppend, %Content%, %A_LoopFileFullPath%
	}
}