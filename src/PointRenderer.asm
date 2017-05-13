;
; Renders a vector array as points
;
PointRenderer: MACRO
	page:
		db 0
	drawCommand:
		VDPCommand 0, 0, 0, 0, 0, 0, 15, 0, VDPCommand_PSET | VDPCommand_IMP
	clearCommand:
		VDPCommand 0, 0, 0, 0, 256, 212, 0, 0, VDPCommand_HMMV | VDPCommand_IMP
	ENDM

; ix = this
; hl <- point command
PointRenderer_GetDrawCommand:
	ld e,ixl
	ld d,ixh
	ld hl,PointRenderer.drawCommand
	add hl,de
	ret

; ix = this
; hl <- clear command
PointRenderer_GetClearCommand:
	ld e,ixl
	ld d,ixh
	ld hl,PointRenderer.clearCommand
	add hl,de
	ret

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

; iy = vertices
; bc = count
; ix = this
PointRenderer_Draw: PROC
	dec bc  ; 16-bit to 2x 8-bit loop
	inc b
	inc c
	ld a,b
	ld b,c
	ld c,a
Loop:
	ld a,(iy + Vector4.x + 1)
	or (iy + Vector4.y + 1)
	or (iy + Vector4.z + 1)
	jr nz,Cull
	ld d,(iy + Vector4.x)
	ld e,(iy + Vector4.y)
	push bc
	call PointRenderer_DrawPoint
	pop bc
Cull:
	ld de,Vector4._size
	add iy,de
	djnz Loop
	dec c
	jr nz,Loop
	ret
	ENDP

; d = x coordinate
; e = y coordinate
; ix = this
PointRenderer_DrawPoint:
	ld (ix + PointRenderer.drawCommand + VDPCommand.dx),d
	ld (ix + PointRenderer.drawCommand + VDPCommand.dy),e
	call PointRenderer_GetDrawCommand
	call VDPCommand_Execute_HL
	ret

; ix = this
PointRenderer_Swap:
	call VDPCommand_WaitReady
	ld a,(ix + PointRenderer.page)
	xor 1
	ld (ix + PointRenderer.page),a
	xor 1
	rrca
	rrca
	rrca
	or 31
	ld b,2
	call VDP_SetRegister
	ld a,(ix + PointRenderer.page)
	ld (ix + PointRenderer.drawCommand + VDPCommand.dy + 1),a
	ld (ix + PointRenderer.clearCommand + VDPCommand.dy + 1),a
	call PointRenderer_GetClearCommand
	call VDPCommand_Execute_HL
	ret
