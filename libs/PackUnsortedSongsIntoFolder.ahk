packUnsortedSongsIntoFolder(dir){
    Playlists := []

    Loop, Files, %dir%\ModData\com.beatgames.beatsaber\Mods\PlaylistManager\Playlists\*.*
	{
		;skip non json files
		if (A_LoopFileExt != "json")
			continue
		
		FileRead, Content, %A_LoopFileFullPath%
		RegExMatch(Content, """playlistTitle"":""(.*?)""", PlaylistTitle)

        Playlists.Push(PlaylistTitle1)
	}

    Loop, Files, %dir%\ModData\com.beatgames.beatsaber\Mods\SongLoader\CustomLevels\*.*, D
	{
        currentFolder := A_LoopFileName
        for index, Playlist in Playlists
        {
            if (currentFolder = Playlist)
            {
                continue 2
            }
        }
        FileMoveDir, %A_LoopFileFullPath%, %dir%\ModData\com.beatgames.beatsaber\Mods\SongLoader\CustomLevels\Unsorted\%A_LoopFileName%
    }
}
