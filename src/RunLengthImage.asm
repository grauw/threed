;
; Run-length encoded image
;
RunLengthImage_HEIGHT: equ 212

RunLengthImage: MACRO
	page:
		db 0
	spansEnd:
		dw spans + RunLengthImage_HEIGHT * RunLengthSpan._size
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
; hl <- spans
; de <- spans count
RunLengthImage_GetSpansAndCount:
	ld e,ixl
	ld d,ixh
	ld hl,RunLengthImage.spans
	add hl,de
	ex de,hl
	ld l,(ix + RunLengthImage.spansEnd)
	ld h,(ix + RunLengthImage.spansEnd + 1)
	sbc hl,de
	ex de,hl
	srl d
	rr e
	ret

; ix = this
RunLengthImage_Clear:
	call RunLengthImage_GetSpans
	ld (ix + RunLengthImage.spansEnd),l
	ld (ix + RunLengthImage.spansEnd + 1),h
	ret

; a = page
; ix = this
RunLengthImage_ClearBlack:
	call RunLengthImage_GetSpans
	ld e,l
	ld d,h
	inc de
	ld bc,RunLengthImage_HEIGHT * RunLengthSpan._size - 1
	ld (hl),0
	call System_FastLDIR
	ld (ix + RunLengthImage.spansEnd),e
	ld (ix + RunLengthImage.spansEnd + 1),d
	ret

; a = page
; ix = this
RunLengthImage_SetPage:
	ld (ix + RunLengthImage.page),a
	ret

; hl = span buffer
; ix = this
RunLengthImage_PlotSpanBuffer: PROC
	ld e,(ix + RunLengthImage.spansEnd)
	ld d,(ix + RunLengthImage.spansEnd + 1)
Loop:
	ld a,(hl)
	sub l
	ld (de),a
	inc de
	inc h
	ld c,h
	inc h
	add a,l
	ldi
	ld h,c
	ld l,a
	jr nz,Loop
	ld (ix + RunLengthImage.spansEnd),e
	ld (ix + RunLengthImage.spansEnd + 1),d
	ret
	ENDP

RunLengthImage_Draw: equ SCREENMODE = 5 || SCREENMODE = 6 ? RunLengthImage_Draw4Bpp : RunLengthImage_Draw8Bpp

; ix = this
RunLengthImage_Draw8Bpp: PROC
	ld hl,0
	ld a,(ix + RunLengthImage.page)
	call VDP_SetWriteAddress
	call RunLengthImage_GetSpansAndCount
	dec de  ; 16-bit to 2x 8-bit loop
	inc d
	inc e
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
	call RunLengthImage_GetSpansAndCount
	dec de  ; 16-bit to 2x 8-bit loop
	inc d
	inc e
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
	call RunLengthImage_GetSpansAndCount
	ld a,d
	or e
	ret z
	exx
	ld e,(ix + RunLengthImage.page)
	IF SCREENMODE = 5 || SCREENMODE = 6
	sla e
	ld hl,8000H
	ELSE
	sla e
	sla e
	ld hl,0C000H
	ENDIF
	exx
	ld bc,RunLengthImage.spans
	add ix,bc
	add iy,bc
	call RunLengthImage_DrawDeltaSpans
	ret

; de = span count
; ix = spans
; iy = other spans
; e' = screen page
; hl' = x/y position
RunLengthImage_DrawDeltaSpans: PROC
	dec de  ; 16-bit to 2x 8-bit loop
	inc d
	inc e
	ld a,d
	ld b,e
	ld l,(ix + RunLengthSpan.length)
	ld h,(ix + RunLengthSpan.color)
	ld e,(iy + RunLengthSpan.length)
	ld d,(iy + RunLengthSpan.color)
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
;      bit 6: address changed since last output (nonsequential output)
;      bit 5: address bits 14-17 changed (r#14)
; hl' = x/y position
RunLengthImage_DrawDeltaSpan8Bpp: PROC
	ex af,af'
	ld a,h
	cp d
	exx
	jr z,Advance
Output:
	ex af,af'
	ld b,a
	ex af,af'
	inc b
OutputLoop:
	call VDPWrite
	djnz OutputLoop
	jr AdvanceNoSetAddress
Advance:
	res 6,e
AdvanceNoSetAddress:
	ex af,af'
	ld c,a
	ld b,0
	inc bc
	add hl,bc
	exx
	ret nc
	exx
	set 6,h
	res 7,h
	inc e
	res 5,e
	exx
	ret
VDPWrite:
	bit 6,e
	call z,VDPWrite_SetAddress
	out (VDP_PORT_0),a
	ret
VDPWrite_SetAddress:
	push bc
	ld c,VDP_PORT_1
	bit 5,e
	jr nz,VDPWrite_SetAddressNoR14
	di
	out (c),e
	ld b,VDP_REGISTER | 14
	out (c),b
	set 5,e
VDPWrite_SetAddressNoR14:
	di
	out (c),l
	res 7,h
	set 6,e
	ei
	out (c),h
	set 7,h
	pop bc
	ret
	ENDP

; a = span length - 1
; h = span color
; d = other span color
; d' = previous span color
; e' = screen page
;      bit 7: force output
;      bit 6: address changed since last output (nonsequential output)
;      bit 5: address bits 14-17 changed (r#14)
; hl' = x/y position
RunLengthImage_DrawDeltaSpan4Bpp: PROC
	ex af,af'
	ld a,h
	cp d
	exx
	jr nz,Output
	bit 7,e
	jr z,Advance
	res 7,e
Output:
	ex af,af'
	ld b,a
	ex af,af'
	inc b
	bit 0,l
	jr z,OutputLoop
	and 0FH
	or d
	call VDPWrite
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
	call VDPWrite
	djnz OutputLoop
	jr AdvanceNoSetAddress
ForceNextAndAdvance:
	set 7,e
	jr AdvanceNoSetAddress
Advance:
	res 6,e
AdvanceNoSetAddress:
	and 0F0H
	ld d,a
	ex af,af'
	ld c,a
	ld b,0
	inc bc
	add hl,bc
	exx
	ret nc
	exx
	set 7,h
	inc e
	res 5,e
	exx
	ret
VDPWrite:
	bit 6,e
	call z,VDPWrite_SetAddress
	out (VDP_PORT_0),a
	ret
VDPWrite_SetAddress:
	push bc
	ld c,VDP_PORT_1
	bit 5,e
	jr nz,VDPWrite_SetAddressNoR14
	di
	out (c),e
	ld b,VDP_REGISTER | 14
	out (c),b
	set 5,e
VDPWrite_SetAddressNoR14:
	ld b,l
	rrc h
	rr b
	di
	out (c),b
	ld b,h
	rlc h
	res 7,b
	set 6,e
	ei
	out (c),b
	pop bc
	ret
	ENDP
