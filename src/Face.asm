;
;
;
Face: MACRO ?one, ?two, ?three, ?color
	one:
		dw ?one * Vector4._size
	two:
		dw ?two * Vector4._size
	three:
		dw ?three * Vector4._size
	color:
		db ?color
	_size:
	ENDM

; de = vertices
; ix = this
Face_BakeVertices:
	ld l,(ix + Face.one)
	ld h,(ix + Face.one + 1)
	add hl,de
	ld (ix + Face.one),l
	ld (ix + Face.one + 1),h
	ld l,(ix + Face.two)
	ld h,(ix + Face.two + 1)
	add hl,de
	ld (ix + Face.two),l
	ld (ix + Face.two + 1),h
	ld l,(ix + Face.three)
	ld h,(ix + Face.three + 1)
	add hl,de
	ld (ix + Face.three),l
	ld (ix + Face.three + 1),h
	ret

; bc = count
; de = vertices
; ix = this
Face_BakeArrayVertices: PROC
	dec bc  ; 16-bit to 2x 8-bit loop
	inc b
	inc c
	ld a,b
	ld b,c
	ld c,a
Loop:
	call Face_BakeVertices
	ex de,hl
	ld de,Face._size
	add ix,de
	ex de,hl
	djnz Loop
	dec c
	jr nz,Loop
	ret
	ENDP
