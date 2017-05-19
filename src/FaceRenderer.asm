;
; Renders a face array
;
FaceRenderer: MACRO
	page:
		db 0
	drawCommand:
		VDPCommand 0, 0, 0, 0, 0, 0, 0, 1, VDPCommand_LINE | VDPCommand_IMP
	clearCommand:
		VDPCommand 0, 0, 0, 0, 256, 212, 0, 0, VDPCommand_HMMV | VDPCommand_IMP
	ENDM

; ix = this
; hl <- point command
FaceRenderer_GetDrawCommand:
	ld e,ixl
	ld d,ixh
	ld hl,FaceRenderer.drawCommand
	add hl,de
	ret

; ix = this
; hl <- clear command
FaceRenderer_GetClearCommand:
	ld e,ixl
	ld d,ixh
	ld hl,FaceRenderer.clearCommand
	add hl,de
	ret

; bc = count
; iy = faces
; ix = this
FaceRenderer_Draw: PROC
	dec bc  ; 16-bit to 2x 8-bit loop
	inc b
	inc c
	ld a,b
	ld b,c
	ld c,a
Loop:
	push bc
	push ix
	ld e,(iy + Face.one)
	ld d,(iy + Face.one + 1)
	ld ixl,e
	ld ixh,d
	ld c,(ix + Vector4.x)
	ld b,(ix + Vector4.y)
	ld e,(iy + Face.two)
	ld d,(iy + Face.two + 1)
	ld ixl,e
	ld ixh,d
	ld l,(ix + Vector4.x)
	ld h,(ix + Vector4.y)
	ld e,(iy + Face.three)
	ld d,(iy + Face.three + 1)
	ld ixl,e
	ld ixh,d
	ld e,(ix + Vector4.x)
	ld d,(ix + Vector4.y)
	pop ix
	ld a,(iy + Face.color)
	call FaceRenderer_DrawFace
	ld bc,Face._size
	add iy,bc
	pop bc
	djnz Loop
	dec c
	jr nz,Loop
	ret
	ENDP

; a = color
; c = x coordinate 1
; b = y coordinate 1
; e = x coordinate 2
; d = y coordinate 2
; l = x coordinate 3
; h = y coordinate 3
; ix = this
FaceRenderer_DrawFace:
	push af
	push bc
	push de
	push hl
	call FaceRenderer_DrawEdge
	pop de
	pop bc
	pop hl
	pop af
	push af
	push bc
	push de
	push hl
	call FaceRenderer_DrawEdge
	pop de
	pop bc
	pop hl
	pop af
	call FaceRenderer_DrawEdge
	ret

; a = color
; c = x coordinate 1
; b = y coordinate 1
; e = x coordinate 2
; d = y coordinate 2
; ix = this
FaceRenderer_DrawEdge: PROC
	ld (ix + FaceRenderer.drawCommand + VDPCommand.color),a
	ld a,b
	sub d
	jr nc,YContinue
	neg
	ld l,e  ; ex bc,de
	ld e,c
	ld c,l
	ld l,d
	ld d,b
	ld b,l
YContinue:
	ld (ix + FaceRenderer.drawCommand + VDPCommand.ny),a
	ld (ix + FaceRenderer.drawCommand + VDPCommand.dx),e
	ld (ix + FaceRenderer.drawCommand + VDPCommand.dy),d
	ld a,e
	sub c
	jr c,BLessThanD
BGreaterThanD:
	set 2,(ix + FaceRenderer.drawCommand + VDPCommand.argument)
	jr XContinue
BLessThanD:
	neg
	res 2,(ix + FaceRenderer.drawCommand + VDPCommand.argument)
XContinue:
	ld (ix + FaceRenderer.drawCommand + VDPCommand.nx),a
	ld a,(ix + FaceRenderer.drawCommand + VDPCommand.nx)
	cp (ix + FaceRenderer.drawCommand + VDPCommand.ny)
	jr nc,NXLessThanNY
NXGreaterThanNY:
	ld b,(ix + FaceRenderer.drawCommand + VDPCommand.nx)
	ld c,(ix + FaceRenderer.drawCommand + VDPCommand.ny)
	ld (ix + FaceRenderer.drawCommand + VDPCommand.nx),c
	ld (ix + FaceRenderer.drawCommand + VDPCommand.ny),b
	set 0,(ix + FaceRenderer.drawCommand + VDPCommand.argument)
	jr NContinue
NXLessThanNY:
	res 0,(ix + FaceRenderer.drawCommand + VDPCommand.argument)
NContinue:
	call FaceRenderer_GetDrawCommand
	call VDPCommand_Execute_HL
	ret
	ENDP

; ix = this
FaceRenderer_Swap:
	call VDPCommand_WaitReady
	ld a,(ix + FaceRenderer.page)
	xor 1
	ld (ix + FaceRenderer.page),a
	xor 1
	rrca
	rrca
	rrca
	or 31
	ld b,2
	call VDP_SetRegister
	ld a,(ix + FaceRenderer.page)
	ld (ix + FaceRenderer.drawCommand + VDPCommand.dy + 1),a
	ld (ix + FaceRenderer.clearCommand + VDPCommand.dy + 1),a
	call FaceRenderer_GetClearCommand
	call VDPCommand_Execute_HL
	ret
