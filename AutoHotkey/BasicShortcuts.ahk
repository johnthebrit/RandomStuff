#SingleInstance, Force ;only allows once instance and with force replaces old instance
SendMode Input ;makes Send synonymous with SendInput which has better speed and reliability
SetWorkingDir, %A_ScriptDir%

;if a single line no need for a return at end
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

;:*?:att::AT&T ;this will replace without having to press space after.
;The ? triggers within a word and * does not need ending character (space or enter)
;;however that also stops me typing the word attention I quickly found out :D

::att::AT&T

;example on multiple lines so return required as not implicit
::gj::
Send Great job {U+1F919} ; to send unicode shaka symbol
return