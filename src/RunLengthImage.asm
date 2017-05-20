;
; Run-length encoded image
;
RunLengthImage_HEIGHT: equ 212

RunLengthImage: MACRO
	page:
		db 0
	spanCount:
		dw RunLengthImage_HEIGHT
	spans:
		ds 1000H * RunLengthSpan._size
	ENDM

RunLengthSpan: MACRO
	length:
		db 0
	color:
		db 0
	_size:
	ENDM

; ix = this
; hl <- spans
RunLengthImage_GetSpans:
	ld e,ixl
	ld d,ixh
	ld hl,RunLengthImage.spans
	add hl,de
	ret

; ix = this
RunLengthImage_Clear:
	ld (ix + RunLengthImage.spanCount),0
	ld (ix + RunLengthImage.spanCount + 1),0
	ret

; a = page
; ix = this
RunLengthImage_ClearBlack:
	ld (ix + RunLengthImage.spanCount),RunLengthImage_HEIGHT
	ld (ix + RunLengthImage.spanCount + 1),0
	call RunLengthImage_GetSpans
	ld e,l
	ld d,h
	inc de
	ld bc,RunLengthImage_HEIGHT * RunLengthSpan._size - 1
	ld (hl),0
	call System_FastLDIR
	ret

; a = page
; ix = this
RunLengthImage_SetPage:
	ld (ix + RunLengthImage.page),a
	ret

; a = color
; e = x
; d = y
; ix = this
RunLengthImage_Pset: PROC
	push af
	call RunLengthImage_FindSpan
	and a
	jr nz,OffsetNonZero
	ld a,(hl)
	cp 1
	jr nz,InsertBefore
Replace:
	inc hl
	pop af
	ld (hl),a
	ret
InsertBefore:
	dec (hl)
	inc bc
	sla c  ; x RunLengthSpan._size
	rl b
	add hl,bc
	ld e,l
	ld d,h
	dec hl
	inc de
	lddr
	pop af
	inc hl
	ld (hl),1
	inc hl
	ld (hl),a
	inc (ix + RunLengthImage.spanCount)
	ret nz
	inc (ix + RunLengthImage.spanCount + 1)
	ret
OffsetNonZero:
	ld e,a
	inc a
	sub (hl)
	jr z,InsertAfter
	neg
Split:
	ld (hl),e
	inc bc
	sla c  ; x RunLengthSpan._size
	rl b
	add hl,bc
	ld e,l
	ld d,h
	dec hl
	inc de
	inc de
	inc de
	lddr
	ld b,a
	pop af
	inc hl
	inc hl
	inc hl
	ld (hl),1
	inc hl
	ld (hl),a
	inc hl
	ld (hl),b
	ld c,(ix + RunLengthImage.spanCount)
	ld b,(ix + RunLengthImage.spanCount + 1)
	inc bc
	inc bc
	ld (ix + RunLengthImage.spanCount),c
	ld (ix + RunLengthImage.spanCount + 1),b
	ret
InsertAfter:
	dec (hl)
	inc hl
	inc hl
	ld a,b
	or c
	jr z,InsertAfterNoneFollowing
	sla c  ; x RunLengthSpan._size
	rl b
	add hl,bc
	ld e,l
	ld d,h
	dec hl
	inc de
	lddr
	pop af
	inc hl
InsertAfterNoneFollowing:
	ld (hl),1
	inc hl
	ld (hl),a
	inc (ix + RunLengthImage.spanCount)
	ret nz
	inc (ix + RunLengthImage.spanCount + 1)
	ret
	ENDP

; e = x
; d = y
; ix = this
; hl <- span
; bc <- remaining spans after this one
; a <- span offset
RunLengthImage_FindSpan: PROC
	push de
	call RunLengthImage_GetSpans
	pop de
	ld c,(ix + RunLengthImage.spanCount)
	ld b,(ix + RunLengthImage.spanCount + 1)
	dec hl
	dec hl
Loop:
	dec bc
	inc hl
	inc hl
	ld a,(hl)
	neg
	add a,e
	ld e,a
	jr c,Loop
	dec d
	ld a,d
	inc a
	jr nz,Loop
Found:
	ld a,e
	add a,(hl)
	ret
	ENDP

RunLengthImage_Draw: equ SCREENMODE = 5 || SCREENMODE = 6 ? RunLengthImage_Draw4Bpp : RunLengthImage_Draw8Bpp

; ix = this
RunLengthImage_Draw8Bpp: PROC
	ld hl,0
	ld a,(ix + RunLengthImage.page)
	call VDP_SetWriteAddress
	call RunLengthImage_GetSpans
	ld c,(ix + RunLengthImage.spanCount)
	ld b,(ix + RunLengthImage.spanCount + 1)
	dec bc  ; 16-bit to 2x 8-bit loop
	inc b
	inc c
	ld e,c
	ld d,b
Loop:
	ld b,(hl)
	inc hl
	ld a,(hl)
	inc hl
OutLoop:
	out (VDP_PORT_0),a
	djnz OutLoop
	dec e
	jr nz,Loop
	dec d
	jr nz,Loop
	ret
	ENDP

; ix = this
RunLengthImage_Draw4Bpp: PROC
	ld hl,0
	ld a,(ix + RunLengthImage.page)
	srl a
	rr h
	call VDP_SetWriteAddress
	call RunLengthImage_GetSpans
	ld c,(ix + RunLengthImage.spanCount)
	ld b,(ix + RunLengthImage.spanCount + 1)
	dec bc  ; 16-bit to 2x 8-bit loop
	inc b
	inc c
	ld e,c
	ld d,b
EvenXLoop:
	ld b,(hl)
	inc hl
	ld a,(hl)
	inc hl
	srl b
	jr c,EvenXOddLength
EvenXEvenLength:
	jr nz,EvenXEvenLengthLoop
	ld b,80H
EvenXEvenLengthLoop:
	out (VDP_PORT_0),a
	djnz EvenXEvenLengthLoop
EvenXNext:
	dec e
	jr nz,EvenXLoop
	dec d
	jr nz,EvenXLoop
	ret
; a = previous colour
OddXLoop:
	and 0F0H
	ld c,a
	ld b,(hl)
	inc hl
	ld a,(hl)
	and 00FH
	or c
	out (VDP_PORT_0),a
	ld a,(hl)
	inc hl
	dec b
	jr z,EvenXNext
	srl b
	jr nc,EvenXEvenLength
EvenXOddLength:
	jr z,OddXNext
EvenXOddLengthLoop:
	out (VDP_PORT_0),a
	djnz EvenXOddLengthLoop
OddXNext:
	dec e
	jr nz,OddXLoop
	dec d
	jr nz,OddXLoop
	ret
	ENDP
