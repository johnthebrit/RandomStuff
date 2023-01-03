#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

^!g::Run, https://www.google.com/search?q=%Clipboard%   ; Ctrl Alt g

^!b::Run, https://www.bing.com/search?q=%Clipboard%

:*?:att::AT&T ;this will replace without having to press space after. The ? triggers within a word and * does not need ending character (space or enter)

::gj::
Send Great job {U+1F919} ; to send unicode shaka symbol
return