#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

oPowerPoint:=ComObjActive("PowerPoint.Application")
Return

^!q::
oPowerPoint.ActivePresentation.SlideShowWindow.View.Previous()
Return
^!w::
oPowerPoint.ActivePresentation.SlideShowWindow.View.Next()
Return
^!e::
oPowerPoint.ActivePresentation.SlideShowWindow.View.Next()
Send ^!s
Return
