;
; Renders a vector array as points
;
PointRenderer: MACRO
	ENDM

; bc = count
; ix = vector array
PointRenderer_PerspectiveDivideArray: PROC
	dec bc  ; 16-bit to 2x 8-bit loop
	inc b
	inc c
	ld a,b
	ld b,c
	ld c,a
Loop:
	push bc
	ld e,(ix + Vector4.w)
	ld d,(ix + Vector4.w + 1)
	call Math_ReciprocalSigned8_8
	push bc
	ld l,(ix + Vector4.x)
	ld h,(ix + Vector4.x + 1)
	call Math_MultiplySigned8_8x8_8
	ld bc,100H
	add hl,bc
	sra h
	rr l
	ld (ix + Vector4.x),l
	ld (ix + Vector4.x + 1),h
	pop bc
	push bc
	ld l,(ix + Vector4.y)
	ld h,(ix + Vector4.y + 1)
	call Math_MultiplySigned8_8x8_8
	ld bc,0D4H
	add hl,bc
	sra h
	rr l
	ld (ix + Vector4.y),l
	ld (ix + Vector4.y + 1),h
	pop bc
	ld l,(ix + Vector4.z)
	ld h,(ix + Vector4.z + 1)
	call Math_MultiplySigned8_8x8_8
	ld (ix + Vector4.z),l
	ld (ix + Vector4.z + 1),h
	ld (ix + Vector4.w),0
	ld (ix + Vector4.w + 1),1
	ld bc,Vector4._size
	add ix,bc
	pop bc
	djnz Loop
	dec c
	jr nz,Loop
	ret
	ENDP

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
