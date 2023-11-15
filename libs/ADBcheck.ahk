ADBcheck(){
    RunWait, cmd /c adb\adb.exe version,, Hide UseErrorLevel

    ; Check ErrorLevel value
    if (ErrorLevel != 0) {
        MsgBox, ADB is not installed.
        ExitApp
    }
}

ADBdeviceConnected(){
    FileDelete, output.txt

    ; Run the command and capture output
    RunWait, cmd /c adb\adb.exe devices > output.txt,, Hide UseErrorLevel

    ; Read output file and delete it
    FileRead, output, output.txt
    FileDelete, output.txt

    ; Split the output into lines
    lines := StrSplit(output, "`n", "`r")

    ; Initialize device count
    deviceCount := 0

    ; Loop through each line
    Loop, % lines.MaxIndex()
    {
        ; Skip first line
        if (A_Index = 1)
            continue
        ; If the line contains the word "device", increment the device count
        if (InStr(lines[A_Index], "device"))
            deviceCount++
    }

    ; Check if a device is listed in the output
    if (deviceCount = 0) {
        MsgBox, Quest is not connected.
        ExitApp
    } else if (deviceCount > 1){
        MsgBox, Multible Android devices are connected.
        ExitApp
    }
}