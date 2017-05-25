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
		ds 800H * 2  ; RunLengthSpan._size
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

; hl = span buffer
; ix = this
RunLengthImage_PlotSpanBuffer: PROC
	ex de,hl
	ld c,ixl
	ld b,ixh
	ld hl,RunLengthImage.spans
	add hl,bc
	ld c,(ix + RunLengthImage.spanCount)
	ld b,(ix + RunLengthImage.spanCount + 1)
	add hl,bc
	add hl,bc
	ex de,hl
Loop:
	ld a,(hl)
	sub l
	inc h
	inc h
	ld (de),a
	inc de
	ld a,(hl)
	dec h
	dec h
	ld (de),a
	inc de
	inc bc
	ld l,(hl)
	inc l
	dec l
	jr nz,Loop
	ld (ix + RunLengthImage.spanCount),c
	ld (ix + RunLengthImage.spanCount + 1),b
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

; iy = other image
; ix = this
RunLengthImage_DrawDelta:
	ld c,(ix + RunLengthImage.spanCount)
	ld b,(ix + RunLengthImage.spanCount + 1)
	ld a,b
	or c
	ret z
	exx
	ld hl,0
	ld e,(ix + RunLengthImage.page)
	exx
	ld de,RunLengthImage.spans
	add ix,de
	add iy,de
	call RunLengthImage_DrawDeltaSpans
	ret

; bc = span count
; ix = spans
; iy = other spans
; e' = screen page
; hl' = x/y position
RunLengthImage_DrawDeltaSpans: PROC
	ld l,(ix + RunLengthSpan.length)
	ld h,(ix + RunLengthSpan.color)
	ld e,(iy + RunLengthSpan.length)
	ld d,(iy + RunLengthSpan.color)
	dec bc  ; 16-bit to 2x 8-bit loop
	inc b
	inc c
	ld a,b
	ld b,c
OuterLoop:
	push af
Loop:
	dec l
	dec e
	ld a,l
	sub e
	jr c,SmallerL
	jr z,EqualL
LargerL:
	ld l,a
	ld a,e
	ld e,0
	call RunLengthImage_DrawDeltaSpan
	inc iy
	inc iy
	ld e,(iy + RunLengthSpan.length)
	ld d,(iy + RunLengthSpan.color)
	jr Loop
EqualL:
	ld l,a
	ld a,e
	ld e,l
	call RunLengthImage_DrawDeltaSpan
	inc iy
	inc iy
	ld e,(iy + RunLengthSpan.length)
	ld d,(iy + RunLengthSpan.color)
	inc ix
	inc ix
	ld l,(ix + RunLengthSpan.length)
	ld h,(ix + RunLengthSpan.color)
	djnz Loop
	pop af
	dec a
	jr nz,OuterLoop
	ret
SmallerL:
	neg
	ld e,a
	ld a,l
	ld l,0
	call RunLengthImage_DrawDeltaSpan
	inc ix
	inc ix
	ld l,(ix + RunLengthSpan.length)
	ld h,(ix + RunLengthSpan.color)
	djnz Loop
	pop af
	dec a
	jr nz,OuterLoop
	ret
	ENDP

RunLengthImage_DrawDeltaSpan: equ SCREENMODE = 5 || SCREENMODE = 6 ? RunLengthImage_DrawDeltaSpan4Bpp : RunLengthImage_DrawDeltaSpan8Bpp

; a = span length - 1
; h = span color
; d = other span color
; e' = screen page
; hl' = x/y position
RunLengthImage_DrawDeltaSpan8Bpp: PROC
	ex af,af'
	ld a,h
	cp d
	exx
	jr z,Advance
Output:
	rlc h
	rl e
	rlc h
	rl e
	ld c,VDP_PORT_1
	di
	out (c),e
	ld b,VDP_REGISTER | 14
	out (c),b
	srl e
	srl e
	rrc h
	rrc h
	out (c),l
	ld b,h
	set 6,b
	res 7,b
	ei
	out (c),b
	dec c
	ex af,af'
	ld b,a
	ex af,af'
	inc b
OutputLoop:
	out (c),a
	djnz OutputLoop
Advance:
	ex af,af'
	ld c,a
	ld b,0
	inc bc
	add hl,bc
	exx
	ret
	ENDP

; a = span length - 1
; h = span color
; d = other span color
; d' = previous span color
; e' = screen page, bit 7: force output
; hl' = x/y position
RunLengthImage_DrawDeltaSpan4Bpp: PROC
	ex af,af'
	ld a,h
	cp d
	exx
	jr nz,Output
	bit 7,e
	jr z,Advance
Output:
	rlc h
	rl e
	ld c,VDP_PORT_1
	di
	out (c),e
	ld b,VDP_REGISTER | 14
	out (c),b
	srl e
	rrc h
	ld b,l
	rrc h
	rr b
	out (c),b
	ld b,h
	rlc h
	set 6,b
	res 7,b
	res 7,e
	ei
	out (c),b
	dec c
	ex af,af'
	ld b,a
	ex af,af'
	inc b
	bit 0,l
	jr z,OutputLoop
	and 0FH
	or d
	out (c),a
	exx
	ld a,h
	exx
	dec b
	jr z,Advance
	exx
	cp d
	exx
	jr z,Advance
OutputLoop:
	dec b
	jr z,ForceNextAndAdvance
	out (c),a
	djnz OutputLoop
	jr Advance
ForceNextAndAdvance:
	set 7,e
Advance:
	and 0F0H
	ld d,a
	ex af,af'
	ld c,a
	ld b,0
	inc bc
	add hl,bc
	exx
	ret
	ENDP
