;
; A point
;
Point: MACRO ?vertex, ?color
	vertex:
		dw ?vertex * Vector4._size
	color:
		db ?color
	x:
		db 0
	y:
		db 0
	_size:
	ENDM

; ix = this
Point_Prepare: PROC
	ld c,(ix + Point.vertex)
	ld b,(ix + Point.vertex + 1)
	ld iyl,c
	ld iyh,b
	ld h,(iy + Vector4.x)
	ld l,(iy + Vector4.y)
	ld (ix + Point.x),h
	ld (ix + Point.y),l
	ret
	ENDP

; bc = count
; de = vertices
; ix = this
Point_PrepareArray: PROC
	dec bc  ; 16-bit to 2x 8-bit loop
	inc b
	inc c
	ld a,b
	ld b,c
	ld c,a
Loop:
	push bc
	call Point_Prepare
	pop bc
	ex de,hl
	ld de,Point._size
	add ix,de
	ex de,hl
	djnz Loop
	dec c
	jr nz,Loop
	ret
	ENDP

; de = vertices
; ix = this
Point_BakeVertices:
	ld l,(ix + Point.vertex)
	ld h,(ix + Point.vertex + 1)
	add hl,de
	ld (ix + Point.vertex),l
	ld (ix + Point.vertex + 1),h
	ret

; bc = count
; de = vertices
; ix = this
Point_BakeArrayVertices: PROC
	dec bc  ; 16-bit to 2x 8-bit loop
	inc b
	inc c
	ld a,b
	ld b,c
	ld c,a
Loop:
	call Point_BakeVertices
	ex de,hl
	ld de,Point._size
	add ix,de
	ex de,hl
	djnz Loop
	dec c
	jr nz,Loop
	ret
	ENDP
