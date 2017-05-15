;
; Renders an edge array
;
EdgeRenderer: MACRO
	page:
		db 0
	drawCommand:
		VDPCommand 0, 0, 0, 0, 0, 0, 0, 1, VDPCommand_LINE | VDPCommand_IMP
	clearCommand:
		VDPCommand 0, 0, 0, 0, 256, 212, 0, 0, VDPCommand_HMMV | VDPCommand_IMP
	ENDM

; ix = this
; hl <- point command
EdgeRenderer_GetDrawCommand:
	ld e,ixl
	ld d,ixh
	ld hl,EdgeRenderer.drawCommand
	add hl,de
	ret

; ix = this
; hl <- clear command
EdgeRenderer_GetClearCommand:
	ld e,ixl
	ld d,ixh
	ld hl,EdgeRenderer.clearCommand
	add hl,de
	ret

; bc = count
; hl = edges
; iy = vertices
; ix = this
EdgeRenderer_Draw: PROC
	dec bc  ; 16-bit to 2x 8-bit loop
	inc b
	inc c
	ld a,b
	ld b,c
	ld c,a
Loop:
	push bc
	call EdgeRenderer_GetVertexXY
	ld c,e
	ld b,d
	call EdgeRenderer_GetVertexXY
	ld a,(hl)
	inc hl
	push hl
	call EdgeRenderer_DrawEdge
	pop hl
	pop bc
	djnz Loop
	dec c
	jr nz,Loop
	ret
	ENDP

; hl = vertex offset
; iy = vertices
; d <- x
; e <- y
; hl <- updated
EdgeRenderer_GetVertexXY:
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	push iy
	add iy,de
	ld d,(iy + Vector4.x)
	ld e,(iy + Vector4.y)
	pop iy
	ret

; a = color
; b = x coordinate 1
; c = y coordinate 1
; d = x coordinate 2
; e = y coordinate 2
; ix = this
EdgeRenderer_DrawEdge: PROC
	ld (ix + EdgeRenderer.drawCommand + VDPCommand.color),a
	ld (ix + EdgeRenderer.drawCommand + VDPCommand.dx),b
	ld (ix + EdgeRenderer.drawCommand + VDPCommand.dy),c
	ld a,c
	sub e
	jr c,CLessThanE
CGreaterThanE:
	set 3,(ix + EdgeRenderer.drawCommand + VDPCommand.argument)
	jr YContinue
CLessThanE:
	neg
	res 3,(ix + EdgeRenderer.drawCommand + VDPCommand.argument)
YContinue:
	ld (ix + EdgeRenderer.drawCommand + VDPCommand.ny),a
	ld a,b
	sub d
	jr c,BLessThanD
BGreaterThanD:
	set 2,(ix + EdgeRenderer.drawCommand + VDPCommand.argument)
	jr XContinue
BLessThanD:
	neg
	res 2,(ix + EdgeRenderer.drawCommand + VDPCommand.argument)
XContinue:
	ld (ix + EdgeRenderer.drawCommand + VDPCommand.nx),a
	ld a,(ix + EdgeRenderer.drawCommand + VDPCommand.nx)
	cp (ix + EdgeRenderer.drawCommand + VDPCommand.ny)
	jr nc,NXLessThanNY
NXGreaterThanNY:
	ld b,(ix + EdgeRenderer.drawCommand + VDPCommand.ny)
	ld c,(ix + EdgeRenderer.drawCommand + VDPCommand.nx)
	ld (ix + EdgeRenderer.drawCommand + VDPCommand.ny),c
	ld (ix + EdgeRenderer.drawCommand + VDPCommand.nx),b
	set 0,(ix + EdgeRenderer.drawCommand + VDPCommand.argument)
	jr NContinue
NXLessThanNY:
	res 0,(ix + EdgeRenderer.drawCommand + VDPCommand.argument)
NContinue:
	call EdgeRenderer_GetDrawCommand
	call VDPCommand_Execute_HL
	ret
	ENDP

; ix = this
EdgeRenderer_Swap:
	call VDPCommand_WaitReady
	ld a,(ix + EdgeRenderer.page)
	xor 1
	ld (ix + EdgeRenderer.page),a
	xor 1
	rrca
	rrca
	rrca
	or 31
	ld b,2
	call VDP_SetRegister
	ld a,(ix + EdgeRenderer.page)
	ld (ix + EdgeRenderer.drawCommand + VDPCommand.dy + 1),a
	ld (ix + EdgeRenderer.clearCommand + VDPCommand.dy + 1),a
	call EdgeRenderer_GetClearCommand
	call VDPCommand_Execute_HL
	ret
