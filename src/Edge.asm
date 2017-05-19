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
	x:
		db 0
	y:
		db 0
	dx:
		db 0
	dy:
		db 0
	_size:
	ENDM

; ix = this
Edge_Prepare: PROC
	ld c,(ix + Edge.one)
	ld b,(ix + Edge.one + 1)
	ld iyl,c
	ld iyh,b
	ld h,(iy + Vector4.x)
	ld l,(iy + Vector4.y)
	ld c,(ix + Edge.two)
	ld b,(ix + Edge.two + 1)
	ld iyl,c
	ld iyh,b
	ld d,(iy + Vector4.x)
	ld e,(iy + Vector4.y)
	ld a,e
	sub l
	jr nc,NoSwap
	ex de,hl
	neg
NoSwap:
	ld (ix + Edge.x),h
	ld (ix + Edge.y),l
	ld (ix + Edge.dy),a
	ld a,d
	sub h
	ld (ix + Edge.dx),a
	ret
	ENDP

; bc = count
; ix = this
Edge_PrepareArray: PROC
	dec bc  ; 16-bit to 2x 8-bit loop
	inc b
	inc c
	ld a,b
	ld b,c
	ld c,a
Loop:
	push bc
	call Edge_Prepare
	pop bc
	ex de,hl
	ld de,Edge._size
	add ix,de
	ex de,hl
	djnz Loop
	dec c
	jr nz,Loop
	ret
	ENDP

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
