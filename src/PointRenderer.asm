;
; Renders a vector array as points
;
PointRenderer: MACRO
	ENDM

; ix = vertices
; bc = count
PointRenderer_Draw: PROC
	dec bc  ; 16-bit to 2x 8-bit loop
	inc b
	inc c
	ld a,b
	ld b,c
	ld c,a
Loop:
	ld a,(ix + Vector4.x + 1)
	or (ix + Vector4.y + 1)
	or (ix + Vector4.z + 1)
	jr nz,Cull
	ld d,(ix + Vector4.x)
	ld e,(ix + Vector4.y)
	push bc
	call PointRenderer_DrawPoint
	pop bc
Cull:
	ld de,Vector4._size
	add ix,de
	djnz Loop
	dec c
	jr nz,Loop
	ret
	ENDP

; d = x coordinate
; e = y coordinate
PointRenderer_DrawPoint:
	push de
	call VDPCommand_WaitReady
	pop de
	ld a,d
	ld b,36
	call VDP_SetRegister
	xor a
	ld b,37
	call VDP_SetRegister
	ld a,e
	ld b,38
	call VDP_SetRegister
	xor a
	ld b,39
	call VDP_SetRegister
	ld a,15
	ld b,44
	call VDP_SetRegister
	xor a
	ld b,45
	call VDP_SetRegister
	ld a,VDPCommand_PSET | VDPCommand_IMP
	ld b,46
	call VDP_SetRegister
	ret
