#include <AutoItConstants.au3>
#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <StringConstants.au3>

Opt('ExpandVarStrings', 1)  ; Allows me to put variables inside of strings

; Global Variables
Global Const $WIN_TITLE = 'AutoIt Multiprocessing'
Global Const $SUBPROCESS = 'Sub Process.exe'
Global $SubProcessPID = 0
Global $STD_Data = ''
Global $Paused = True

; GUI Variables
Global $MainGUI, $SubToMainTextBox, $ProgressBar, _
$StartButton, $StopButton, $PlayPauseButton, $ClearButton

Main()

Func Main()
	; Create the GUI
	$MainGUI = GUICreate($WIN_TITLE, 500, 300)
	$SubToMainTextBox = GUICtrlCreateEdit('', 20, 20, 460, 195)
	$ProgressBar = GUICtrlCreateProgress(20, 220, 460, 30)

	$StartButton = GUICtrlCreateButton("Start", 20, 255, 85, 25)
	$StopButton = GUICtrlCreateButton("Stop", 110, 255, 85, 25)
	$PlayPauseButton = GUICtrlCreateButton("Play/Pause", 200, 255, 85, 25)
	$ClearButton = GUICtrlCreateButton("Clear", 290, 255, 85, 25)
	$QuitButton = GUICtrlCreateButton("Quit", 380, 255, 100, 25)

	GUICtrlSetState($StartButton, $GUI_FOCUS)
	GUICtrlSetState($StopButton, $GUI_DISABLE)
	GUICtrlSetState($PlayPauseButton, $GUI_DISABLE)

	GUISetState(@SW_SHOW, $MainGUI)  ; Display the GUI

	While 1  ; Loop until the user exits
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $QuitButton
				ExitLoop

			Case $StartButton
				GUICtrlSetState($StartButton, $GUI_DISABLE)
				GUICtrlSetState($StopButton, $GUI_ENABLE)
				GUICtrlSetState($PlayPauseButton, $GUI_ENABLE)
				$Paused = False
				$SubProcessPID = Run($SUBPROCESS, '', Default, $STDOUT_CHILD + $STDIN_CHILD)
				AdlibRegister('CheckSubProcess', 250)

			Case $StopButton
				StopCheckingSubProcess(True)

			Case $PlayPauseButton
				StdinWrite($SubProcessPID, 'PLAYPAUSE;')
				$Paused = Not $Paused
				If $Paused Then
					AdlibUnRegister('CheckSubProcess')
				Else
					AdlibRegister('CheckSubProcess', 250)
				EndIf

			Case $ClearButton
				$STD_Data = ''
				GUICtrlSetData($SubToMainTextBox, $STD_Data)
				WinSetTitle($WIN_TITLE, '', $WIN_TITLE)
				GUICtrlSetData($ProgressBar, 0)
		EndSwitch
	WEnd

	GUIDelete($MainGUI)
	StopCheckingSubProcess(True)
EndFunc

Func CheckSubProcess()  ; Checks every 250ms once registered
	Local $LastReadData = StdoutRead($SubProcessPID)
	$STD_Data &= $LastReadData
	GUICtrlSetData($SubToMainTextBox, $STD_Data)

	; Update the Progress if it has been read in
	If StringRegExp($LastReadData, '(?m)\d+$') Then
		Local $LastPercent = Int(StringRegExp($LastReadData, '(?m)(\d+)$', $STR_REGEXPARRAYFULLMATCH)[0])
		WinSetTitle($WIN_TITLE, '', '$WIN_TITLE$ - $LastPercent$%')
		GUICtrlSetData($ProgressBar, $LastPercent)
	EndIf

	If StringInStr($LastReadData, 'Error') Then  ; Check for Error
		If MsgBox(BitOR($MB_ICONERROR, $MB_YESNO), $WIN_TITLE, 'A Phony Error has occured.@CRLF@Continue?', 0, $MainGUI) = $IDYES Then
			StdinWrite($SubProcessPID, 'CONTINUE;')
		Else
			StdinWrite($SubProcessPID, 'EXIT;')
			StopCheckingSubProcess()
		EndIf
	ElseIf StringInStr($LastReadData, 'DONE', $STR_CASESENSE) Then ; Check if Sub Process competed
		StopCheckingSubProcess()
		MsgBox($MB_ICONINFORMATION, $WIN_TITLE, 'Done', 0, $MainGUI)
	EndIf
EndFunc

Func StopCheckingSubProcess($KillSubProcess=False)
	AdlibUnRegister('CheckSubProcess')
	If $KillSubProcess And $SubProcessPID Then ProcessClose($SubProcessPID)
	$Paused = True
	GUICtrlSetState($StartButton, $GUI_ENABLE)
	GUICtrlSetState($StopButton, $GUI_DISABLE)
	GUICtrlSetState($PlayPauseButton, $GUI_DISABLE)
	GUICtrlSetState($StartButton, $GUI_FOCUS)
EndFunc
