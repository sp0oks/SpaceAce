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
	
	; Enemies Data
	enemiesArr BYTE COLS DUP (-1)					; Enemies array - Index determines X position, and the value determines Y position; if Y is -1, enemy doesn't exist
	enemyUpCtr BYTE 0								; Enemy iteration counter
	enemyGenCtr BYTE 0								; Enemy generation counter
	
	; Bullets Data
	bulletsArr BYTE COLS DUP(-1)					; Bullets array - Index determines X position, and the value determines Y position; if Y is -1, bullet doesn't exist
	
	; Ship Literals
	shipThruster db '<|==]'
	shipMain db '<|===)'

.code
main PROC
	Invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov outHandle, eax
	
	call Randomize
	
gameLoop:
	call UpdateEnemies

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
ResetScreen PROC uses ecx
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
UpdateScreen PROC uses eax ebx ecx edx
;======================================================
	xor ebx, ebx
	xor ecx, ecx
	xor edx, edx

; Player ship
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
	
; Enemies
	xor ecx, ecx
enemiesLoop:
	movsx eax, enemiesArr[ecx]		; row
	
	cmp eax, -1						; check if there's a enemy ship
	je nextEnemy

	mov ebx, COLS
	mul ebx							; eax = COLS*y
	add eax, ecx					; eax = COLS*y + x
	
	mov scrBuffer[eax * CHAR_INFO].Char, '<'
	mov scrBuffer[eax * CHAR_INFO].Attributes, 0F4h

nextEnemy:
	inc ecx
	cmp ecx, LENGTHOF enemiesArr
	jne enemiesLoop
	
; Bullets
	xor ecx, ecx
bulletsLoop:
	movsx eax, bulletsArr[ecx]		; row
	
	cmp eax, -1						; check if there's a bullet
	je nextBullet
	
	mov ebx, COLS
	mul ebx
	add eax, ecx
	
	mov scrBuffer[eax * CHAR_INFO].Char, '-'
	mov scrBuffer[eax * CHAR_INFO].Attributes, 0F6h
	
nextBullet:
	inc ecx
	cmp ecx, LENGTHOF bulletsArr
	jne bulletsLoop
	
	ret
UpdateScreen ENDP

;======================================================
;
UpdateEnemies PROC uses eax ecx edx
;======================================================
	mov dl, enemyUpCtr
	cmp dl, 2					; After three main updates, update enemies position
	je trueUpdate

	inc dl
	mov enemyUpCtr, dl
	
	jmp endUpdate
trueUpdate:

	; Update all enemies position
	mov ecx, 1
enemyLoop:
	mov dl, enemiesArr[ecx]
	mov enemiesArr[ecx-1], dl
	
	inc ecx
	cmp ecx, LENGTHOF enemiesArr
	jne enemyLoop
	
	mov enemiesArr[ecx-1], -1
	
	; Check if should generate new enemy
	mov dl, enemyGenCtr
	cmp dl, 3				; After three updates, generate new enemy (total: 6 updates)
	je trueGen
	
	inc dl
	mov enemyGenCtr, dl
	
	jmp endGen
trueGen:
	mov eax, 21				; Range 0-21
	call RandomRange
	add eax, 2				; Range 2-23
	
	mov enemiesArr[LENGTHOF enemiesArr - 1], al

	mov enemyGenCtr, 0
endGen:
	
	mov enemyUpCtr, 0
endUpdate:
	
	ret
UpdateEnemies ENDP

;======================================================
;
ReadInput PROC uses eax edx
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