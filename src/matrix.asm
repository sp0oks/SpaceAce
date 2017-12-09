Include .\libs\Irvine32.inc

MCOLS = 20
LROWS = 10

GetMatrixData PROTO mAddr:DWORD, mCols: WORD, mRows: WORD, iCols: WORD, iRows:WORD

.data
	matrixT1 BYTE MCOLS*LROWS DUP ('a')

.code
main PROC
	Invoke GetMatrixData, ADDR matrixT1, MCOLS, LROWS, 0, 0
	call WriteChar
	
main ENDP

GetMatrixData PROC uses ebx ecx edx
	mAddr: DWORD, mCols:WORD, mRows:WORD, iCols:WORD, iRows:WORD
	
	mov eax, [mAddr]

	ret
GetMatrixData ENDP

END main