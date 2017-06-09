;
; A point
;
Point: MACRO ?vertex, ?material
	super: Renderable Point_Render
	x:
		db 0
	z:
		db 0
	material:
		dw ?material
	vertex:
		dw ?vertex * Vector4._size
	_size:
	ENDM

; iy = rasterizer
; ix = this
Point_Prepare: PROC
	push iy
	ld e,(ix + Point.vertex)
	ld d,(ix + Point.vertex + 1)
	ld iyl,e
	ld iyh,d
	ld e,(iy + Vector4.x)
	ld a,(iy + Vector4.z)
	ld (ix + Point.x),e
	ld (ix + Point.z),a
	ld e,(iy + Vector4.y)
	pop iy
	call Rasterizer_Add_IY
	ret
	ENDP

; bc = count
; iy = rasterizer
; ix = this
Point_PrepareArray: PROC
Loop:
	call Point_Prepare
	ld de,Point._size
	add ix,de
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
Point_Render:
	ld d,(ix + Point.x)
	ld b,(ix + Point.z)
	push ix
	ld a,(ix + Point.material)
	ld c,(ix + Point.material + 1)
	ld ixl,a
	ld ixh,c
	call Material_RenderPoint
	pop ix
	jp Renderable_Next
