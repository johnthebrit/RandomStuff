#SingleInstance, Force ;only allows once instance and with force replaces old instance
#Persistent ; Keep the script permanently running until terminated
SendMode Input ;makes Send synonymous with SendInput which has better speed and reliability
SetWorkingDir, %A_ScriptDir%

;All of mine are Ctrl Alt <letter>

;if a single line no need for a return at end
;Launch URL with the clipboard content
^!g::Run, https://www.google.com/search?q=%Clipboard%   ; Ctrl Alt g
^!b::Run, https://www.bing.com/search?q=%Clipboard%

;PowerPoint next and back
^!q::
oPowerPoint:=ComObjActive("PowerPoint.Application")
oPowerPoint.ActivePresentation.SlideShowWindow.View.Previous()
Return
^!w::
oPowerPoint:=ComObjActive("PowerPoint.Application")
oPowerPoint.ActivePresentation.SlideShowWindow.View.Next()
Return
^!e::
Send ^!w   ;send the next PowerPoint slide key press
Sleep 500
Send ^!s   ;send my OBS hotkey to add a new chapter
Return

;Toggle current Window to always on top
^!t:: Winset, Alwaysontop, , A

;Toggle transparent for current Window
^!f::
WinGet, TransLevel, Transparent, A
If (TransLevel = 50) {
    WinSet, Transparent, OFF, A
} Else {
    WinSet, Transparent, 50, A
}
return

;Sleep
^!0::
DllCall("PowrProf\SetSuspendState", "Int", 0, "Int", 0, "Int", 0)

;Toggle microphone mute found code on reddit, not mine!
^!m::
SoundSet, +1, MASTER, mute,3
SoundGet, master_mute, , mute, 3

ToolTip, Mute %master_mute% ;use a tool tip at mouse pointer to show what state mic is after toggle
SetTimer, RemoveToolTip, 1000
return

RemoveToolTip:
SetTimer, RemoveToolTip, Off
ToolTip
return

;list microphones
^!n::
SetBatchLines -1
SplashTextOn,,, Gathering Soundcard Info...

; Most of the pure numbers below probably don't exist in any mixer, but they're queried for completeness.
; The numbers correspond to the following items (in order): CUSTOM, BOOLEANMETER, SIGNEDMETER, PEAKMETER,
; UNSIGNEDMETER, BOOLEAN, BUTTON, DECIBELS, SIGNED, UNSIGNED, PERCENT, SLIDER, FADER, SINGLESELECT, MUX,
; MULTIPLESELECT, MIXER, MICROTIME, MILLITIME
ControlTypes = VOLUME,ONOFF,MUTE,MONO,LOUDNESS,STEREOENH,BASSBOOST,PAN,QSOUNDPAN,BASS,TREBLE,EQUALIZER,0x00000000, 0x10010000,0x10020000,0x10020001,0x10030000,0x20010000,0x21010000,0x30040000,0x30020000,0x30030000,0x30050000,0x40020000,0x50030000,0x70010000,0x70010001,0x71010000,0x71010001,0x60030000,0x61030000

ComponentTypes = MASTER,HEADPHONES,DIGITAL,LINE,MICROPHONE,SYNTH,CD,TELEPHONE,PCSPEAKER,WAVE,AUX,ANALOG,N/A

; Create a ListView and prepare for the main loop:
Gui, Add, Listview, w400 h400 vMyListView, Component Type|Control Type|Setting|Mixer
LV_ModifyCol(4, "Integer")
SetFormat, Float, 0.2  ; Limit number of decimal places in percentages to two.

Loop  ; For each mixer number that exists in the system, query its capabilities.
{
    CurrMixer := A_Index
    SoundGet, Setting,,, %CurrMixer%
    if ErrorLevel = Can't Open Specified Mixer  ; Any error other than this indicates that the mixer exists.
        break

    ; For each component type that exists in this mixer, query its instances and control types:
    Loop, parse, ComponentTypes, `,
    {
        CurrComponent := A_LoopField
        ; First check if this component type even exists in the mixer:
        SoundGet, Setting, %CurrComponent%,, %CurrMixer%
        if ErrorLevel = Mixer Doesn't Support This Component Type
            continue  ; Start a new iteration to move on to the next component type.
        Loop  ; For each instance of this component type, query its control types.
        {
            CurrInstance := A_Index
            ; First check if this instance of this instance even exists in the mixer:
            SoundGet, Setting, %CurrComponent%:%CurrInstance%,, %CurrMixer%
            ; Checking for both of the following errors allows this script to run on older versions:
            if ErrorLevel in Mixer Doesn't Have That Many of That Component Type,Invalid Control Type or Component Type
                break  ; No more instances of this component type.
            ; Get the current setting of each control type that exists in this instance of this component:
            Loop, parse, ControlTypes, `,
            {
                CurrControl := A_LoopField
                SoundGet, Setting, %CurrComponent%:%CurrInstance%, %CurrControl%, %CurrMixer%
                ; Checking for both of the following errors allows this script to run on older versions:
                if ErrorLevel in Component Doesn't Support This Control Type,Invalid Control Type or Component Type
                    continue
                if ErrorLevel  ; Some other error, which is unexpected so show it in the results.
                    Setting := ErrorLevel
                ComponentString := CurrComponent
                if CurrInstance > 1
                    ComponentString = %ComponentString%:%CurrInstance%
                LV_Add("", ComponentString, CurrControl, Setting, CurrMixer)
            }  ; For each control type.
        }  ; For each component instance.
    }  ; For each component type.
}  ; For each mixer.

Loop % LV_GetCount("Col")  ; Auto-size each column to fit its contents.
    LV_ModifyCol(A_Index, "AutoHdr")

SplashTextOff
Gui, Show
return

GuiClose:
return


;:*?:att::AT&T ;this will replace without having to press space after.
;The ? triggers within a word and * does not need ending character (space or enter)
;;however that also stops me typing the word attention I quickly found out :D
::att::AT&T

;example on multiple lines so return required as not implicit
::gj::
Send Great job {U+1F919} ; to send unicode shaka symbol
return