;
;
;
Edge: MACRO ?one, ?two, ?color
	one:
		dw ?one * Vector4._size
	two:
		dw ?two * Vector4._size
	color:
		db ?color
	_size:
	ENDM

; de = vertices
; ix = this
Edge_BakeVertices:
	ld l,(ix + Edge.one)
	ld h,(ix + Edge.one + 1)
	add hl,de
	ld (ix + Edge.one),l
	ld (ix + Edge.one + 1),h
	ld l,(ix + Edge.two)
	ld h,(ix + Edge.two + 1)
	add hl,de
	ld (ix + Edge.two),l
	ld (ix + Edge.two + 1),h
	ret

; bc = count
; de = vertices
; ix = this
Edge_BakeArrayVertices: PROC
	dec bc  ; 16-bit to 2x 8-bit loop
	inc b
	inc c
	ld a,b
	ld b,c
	ld c,a
Loop:
	call Edge_BakeVertices
	ex de,hl
	ld de,Edge._size
	add ix,de
	ex de,hl
	djnz Loop
	dec c
	jr nz,Loop
	ret
	ENDP
