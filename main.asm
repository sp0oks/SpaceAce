Include .\libs\Irvine32.inc
Include .\libs\win32.inc

COLS = 80
ROWS = 25

.data
	; Screen Buffer Data
	outHandle HANDLE 0
	scrBuffer CHAR_INFO COLS*ROWS DUP (<<0>, 0Fh>)
	scrSize COORD <COLS, ROWS>
	scrCoord COORD <0, 0>
	scrRect SMALL_RECT <0, 0, COLS-1, ROWS-1>
	
	; Ship Data
	shipY BYTE 1
	
	; Ship Literals
	shipThruster db '<|==]'
	shipMain db '<|===)'

.code
main PROC
	Invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov outHandle, eax
	
gameLoop:
	call Clrscr
	
	call ResetScreen
	
	call UpdateScreen
	
	Invoke WriteConsoleOutput, outHandle, ADDR scrBuffer, scrSize, scrCoord, ADDR scrRect
	
	call ReadInput
	
	mov eax, 150
	call Delay		; wait 150 ms

	jmp gameLoop
	
	ret
main ENDP


;======================================================
;
ResetScreen PROC 
;======================================================
	xor ecx, ecx
	
topMenu:												; top menu has black background and white chars
	mov scrBuffer[ecx * CHAR_INFO].Char, 0
	mov scrBuffer[ecx * CHAR_INFO].Attributes, 0Fh
	
	inc ecx

	cmp ecx, COLS										; for(ecx=0; ecx<COLS; ecx++) { set_screen_buffer(ecx, black, white) }
	jne topMenu
	
mainSpace:												; main space has white background and black chars
	mov scrBuffer[ecx * CHAR_INFO].Char, 0
	mov scrBuffer[ecx * CHAR_INFO].Attributes, 0F0h
	
	inc ecx
	
	cmp ecx, COLS*ROWS									; for(ecx=COLS; ecx<COLS*ROWS; ecx++) { set_screen_buffer(ecx, white, black) }
	jne mainSpace

	ret
ResetScreen ENDP


;======================================================
;
UpdateScreen PROC
;======================================================
	xor ebx, ebx
	xor ecx, ecx
	xor edx, edx

	mov eax, COLS
	mov bl, shipY
	mul ebx			; eax = COLS * shipY

	mov ebx, eax
topShip:
	mov dl, shipThruster[ecx]
	mov scrBuffer[ebx * CHAR_INFO].Char, dx
	
	inc ebx
	inc ecx
	cmp ecx, LENGTHOF shipThruster
	jne topShip
	
	add eax, COLS
	mov ebx, eax
	xor ecx, ecx
midShip:
	mov dl, shipMain[ecx]
	mov scrBuffer[ebx * CHAR_INFO].Char, dx

	inc ebx
	inc ecx
	cmp ecx, LENGTHOF shipMain
	jne midShip
	
	add eax, COLS
	mov ebx, eax
	xor ecx, ecx
botShip:
	mov dl, shipThruster[ecx]
	mov scrBuffer[ebx * CHAR_INFO].Char, dx
	
	inc ebx
	inc ecx
	cmp ecx, LENGTHOF shipThruster
	jne botShip
	
	ret
UpdateScreen ENDP


;======================================================
;
ReadInput PROC
;======================================================
	mov eax, 50
	call Delay		; wait 50ms
	
	call ReadKey
	
	cmp dx, VK_UP	; up arrow
	je shipUp
	cmp dx, VK_DOWN	; down arrow
	je shipDown
	jmp inputEnd
	
shipUp:
	mov al, [shipY]
	dec al
	
	cmp al, 1
	jb inputEnd		; if (shipY-1 < 1) { shipY-- }
	
	mov shipY, al
	
	jmp inputEnd
shipDown:
	mov al, [shipY]
	inc al
	
	cmp al, 22		; if (shipY+1 > 22) { shipY++ }
	ja inputEnd
	
	mov shipY, al
	
	jmp inputEnd
inputEnd:

	ret
ReadInput ENDP

END main