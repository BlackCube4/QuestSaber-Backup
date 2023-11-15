createPlaylistString(dir){

	unsortedDir := dir . "\ModData\com.beatgames.beatsaber\Mods\SongLoader\CustomLevels\Unsorted"
	if !(FileExist(unsortedDir))
	{
		;MsgBox % "The Unsorted directory doesn't exists.`n`n" . unsortedDir
		return 1
	}

	RegExMatch(unsortedDir, ".*\\(.*)", PlaylistName)
	playlistString := "{""playlistDescription"":null,""playlistAuthor"":null,""playlistTitle"":""" . PlaylistName1 . """,""songs"":["

	Loop, Files, %unsortedDir%\*, D
	{
		RegExMatch(A_LoopFileName, "(^\S*) ?", Hash)
		if (StrLen(Hash1) < 15) {
			url := "https://api.beatsaver.com/maps/id/" . Hash1
			UrlDownloadToFile, %url%, map.json
			FileRead, Content, map.json
			RegExMatch(Content, "m)""hash"": ""(.*?)""", Hash)
		}
		playlistString := playlistString . "{""hash"":""" . Hash1 . """},"
	}
	playlistString := SubStr(playlistString, 1, -1)
	playlistString := playlistString . "]}"
	PlaylistPath := dir . "\ModData\com.beatgames.beatsaber\Mods\PlaylistManager\Playlists\" . StrReplace(PlaylistName1, " ", "_") . ".bplist_BMBF.json"
	;if FileExist(PlaylistPath)
	;{
	;	MsgBox, Es gibt schon eine Playlist Datei für %PlaylistName1%
	;	ExitApp
	;}
	FileDelete, %PlaylistPath%
	msgbox, % PlaylistPath . "`n`n" . playlistString
	FileAppend, %playlistString%, %PlaylistPath%

	FileDelete, map.json

	;Clipboard := playlistString
	;MsgBox, String copied to clipboard: %playlistString%
}