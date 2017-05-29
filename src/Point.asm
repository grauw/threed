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
	z:
		db 0
	next:
		dw 0
	_size:
	ENDM

; ix = this
Point_Prepare: PROC
	ld c,(ix + Point.vertex)
	ld b,(ix + Point.vertex + 1)
	ld iyl,c
	ld iyh,b
	ld l,(iy + Vector4.x)
	ld h,(iy + Vector4.y)
	ld c,(iy + Vector4.z)
	ld (ix + Point.x),l
	ld (ix + Point.y),h
	ld (ix + Point.z),c
	ret
	ENDP

; bc = count
; de = vertices
; ix = this
Point_PrepareArray: PROC
Loop:
	push bc
	call Point_Prepare
	pop bc
	ex de,hl
	ld de,Point._size
	add ix,de
	ex de,hl
	dec bc
	ld a,b
	or c
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
Loop:
	call Point_BakeVertices
	ex de,hl
	ld de,Point._size
	add ix,de
	ex de,hl
	dec bc
	ld a,b
	or c
	jr nz,Loop
	ret
	ENDP

; hl = span buffer (l is insignificant, assumed 0)
; iy = this
Point_Draw_IY:
	ld d,(iy + Point.x)
	ld e,d
	inc e
	ld b,(iy + Point.z)
	ld c,(iy + Point.color)
	call SpanBuffer_Insert
	ld e,(iy + Point.next)
	ld d,(iy + Point.next + 1)
	ld a,e
	or d
	ret z
	ld iyl,e
	ld iyh,d
	jr Point_Draw_IY
