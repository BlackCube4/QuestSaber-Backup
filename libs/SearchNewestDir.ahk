searchNewestDir(dir){
    ; Initialize the timestamp of the newest folder to 0
    newestTimestamp := 0
    folders := []

    ; Loop over all folders in the directory to find the newestTimestamp
    Loop, Files, %dir%\*, DR 
    {
        ; Get the timestamp of the current folder
        FileGetTime, timestamp, %A_LoopFileFullPath%, C

        ; If the current folder is newer than the newest folder found so far, update the timestamp
        if (timestamp > newestTimestamp) {
            newestTimestamp := timestamp
        }
    }

    ; Loop over all folders in the directory to build the Array
    Loop, Files, %dir%\*, DR 
    {
        ; Get the timestamp of the current folder
        FileGetTime, timestamp, %A_LoopFileFullPath%, C

        if (timestamp = newestTimestamp) {
            newestFolder := StrReplace(A_LoopFileFullPath, dir)
            folders.Push(newestFolder)
        }
    }

    ;for index, value in folders
    ;{
    ;    MsgBox % "folders[" index "] = " value
    ;}

    return folders
}