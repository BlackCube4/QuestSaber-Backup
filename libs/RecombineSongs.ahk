recombineSongs(dir){
	Loop, Files, %dir%\ModData\com.beatgames.beatsaber\Mods\SongLoader\CustomLevels\*, D
	{
		Loop, Files, %A_LoopFileFullPath%\*, D 
		{
			FileCopyDir, %A_LoopFileFullPath%, %dir%\ModData\com.beatgames.beatsaber\Mods\SongLoader\CustomLevels\Combined\%A_LoopFileName%
		}
	}
}