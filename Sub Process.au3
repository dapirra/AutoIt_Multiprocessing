For $i = 0 To 100
	Local $response = ConsoleRead()
	If StringRight($response, 1) = ';' Then  ; Check for any commands during runtime
		If StringInStr($response, 'PLAYPAUSE', 1) Then
			$response = ''
			Do  ; Wait to be resumed
				$response &= ConsoleRead()
				Sleep(250)
			Until StringRight($response, 1) = ';'
		EndIf
	EndIf

	ConsoleWrite($i & @CRLF)  ; Send progress to Main Process

	If $i = 5 Or $i = 10 Then  ; Simulate an error
		ConsoleWrite('Phony Error at ' & $i & '. Waiting for user response...' & @CRLF)

		Do  ; Wait for a response from the main process for what to do
			$response &= ConsoleRead()
			Sleep(250)
		Until StringRight($response, 1) = ';'

		If StringInStr($response, 'EXIT') Then Exit
	EndIf
	Sleep(250)
Next

ConsoleWrite('DONE' & @CRLF)
Sleep(250)
Exit
