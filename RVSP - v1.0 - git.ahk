#Requires AutoHotkey v1.1+
#SingleInstance, force
#Persistent
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; https://github.com/CrisDxyz/RSVP-Speed-Reader/tree/main

; GUI
Gui, +Border  
Gui, Font, cffffff, s13, Arial Unicode MS ; White text
Gui, Add, Text, x10 y10 w100, Input Text:
Gui, Add, Edit, x10 y30 w300 h100 vInputText gTextChanged
Gui, Add, Button, x25 y140 w60 gPrevChunk, < Prev
Gui, Add, Button, x95 y140 w60 gStartRSVP, Start 
Gui, Add, Button, x165 y140 w60 gStopRSVP, Stop 
Gui, Add, Button, x235 y140 w60 gNextChunk, Next >
Gui, Add, Text, x10 y180 w300 h80 vDisplayWord Center
Gui, Add, Text, x75 y325 w100, Words per minute: ; Palabras por minuto
Gui, Add, Edit, x185 y325 w50 vWPM, 300 
Gui, Add, Text, x75 y360 w100, Chunk size: ; Tamaño del fragmento mostrado / Cuantas palabras se muestran al mismo tiempo
Gui, Add, Edit, x185 y360 w50 vChunkSize, 1 
Gui, Font, s24, Arial  ; display
Gui, Color, 101010, Black
GuiControl, Font, DisplayWord
Gui, Font

Gui, Show, w320 h400, RSVP Speed Reader

global isRunning := false
global words := []
global currentIndex := 1
global baseDelay := 0
global chunkSize := 1
global lastProcessedText := ""
global dynamicChunkSize
global word
return

TextChanged:
    Gui, Submit, NoHide
    if (InputText != lastProcessedText) {
        currentIndex := 1
    }
return

StartRSVP:
    Gui, Submit, NoHide
    
    if (InputText != lastProcessedText) {
        words := StrSplit(InputText, A_Space)
        currentIndex := 1
        lastProcessedText := InputText
    }
    
    baseDelay := 60000 / WPM
    chunkSize := ChunkSize
    isRunning := true
    DisplayWords()
return

StopRSVP:
    isRunning := false
return

PrevChunk:
    isRunning := false
    dynamicChunkSize := GetDynamicChunkSize()
    currentIndex := Max(1, currentIndex - dynamicChunkSize)
    DisplayChunk(dynamicChunkSize)
return

NextChunk:
    isRunning := false
    dynamicChunkSize := GetDynamicChunkSize()
    currentIndex := Min(words.Length(), currentIndex + dynamicChunkSize)
    DisplayChunk(dynamicChunkSize)
return

DisplayWords() {
    while (currentIndex <= words.Length() && isRunning)
    {
        dynamicChunkSize := GetDynamicChunkSize()
        DisplayChunk(dynamicChunkSize)
        currentIndex += dynamicChunkSize
    }
    if (currentIndex > words.Length()) {
        currentIndex := 1  ; Reset
    }
    isRunning := false
}

GetDynamicChunkSize() { ; Changes size to fit flow of reading
    local dynamicSize := chunkSize
    Loop, %chunkSize%
    {
        if (currentIndex + A_Index - 1 > words.Length()) {
            dynamicSize := A_Index - 1
            break
        }
        word := words[currentIndex + A_Index - 1]
        if (RegExMatch(word, "\.$|\!$|\?$|,$")) { ; . , ! ? 
            dynamicSize := A_Index
            break
        }
    }
    return dynamicSize
}

DisplayChunk(dynamicChunkSize) {
    chunk := ""
    endIndex := Min(words.Length(), currentIndex + dynamicChunkSize - 1)
    
    Loop, % (endIndex - currentIndex + 1)
    {
        word := words[currentIndex + A_Index - 1]
        chunk .= word . " "
    }
    
    GuiControl,, DisplayWord, %chunk%
    
    delay := baseDelay * dynamicChunkSize
    lastWord := words[endIndex]
    if (RegExMatch(lastWord, "\.$|\!$|\?$")) { ; manage reading flow here:
        delay *= 3  ; x3 the delay for sentence-ending punctuation
    } else if (RegExMatch(lastWord, ",$|;$|:$")) {
        delay *= 2  ; 2x delay for other punctuation
    }
    
    if (isRunning)
        Sleep, %delay%
}

GuiClose:
ExitApp

; reload rvsp
^r::Reload

; panic button
Esc::ExitApp


; https://github.com/CrisDxyz/RSVP-Speed-Reader/tree/main