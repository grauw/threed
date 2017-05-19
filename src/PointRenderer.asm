;
; Renders a points array
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

; iy = points
; bc = count
; ix = this
PointRenderer_Draw: PROC
	call PointRenderer_Prepare
	dec bc  ; 16-bit to 2x 8-bit loop
	inc b
	inc c
	ld a,b
	ld b,c
	ld c,a
Loop:
	push bc
	call PointRenderer_DrawPoint
	pop bc
	ld de,Point._size
	add iy,de
	djnz Loop
	dec c
	jr nz,Loop
	ret
	ENDP

; bc = count
; iy = points
; ix = this
PointRenderer_Prepare:
	push bc
	push ix
	push iy
	push iy
	pop ix
	call Point_PrepareArray
	pop iy
	pop ix
	pop bc
	ret

; iy = point
; ix = this
PointRenderer_DrawPoint:
	ld e,(iy + Point.x)
	ld d,(iy + Point.y)
	ld a,(iy + Point.color)
	ld (ix + PointRenderer.drawCommand + VDPCommand.dx),e
	ld (ix + PointRenderer.drawCommand + VDPCommand.dy),d
	ld (ix + PointRenderer.drawCommand + VDPCommand.color),a
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
