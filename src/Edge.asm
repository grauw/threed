;
; An edge
;
; Using Bresenham’s Run-Slice algorithm
; See Michael Abrash’s Graphics Programming Black Book chapter 36
; http://downloads.gamedev.net/pdf/gpbb/gpbb36.pdf
;
Edge: MACRO ?vertex1, ?vertex2, ?material
	super: Renderable Edge_Render
	x:
		db 0
	z:
		db 0
	height:
		db 0
	dx:
		db 0
	dy:
		db 0
	stepx:
		db 0
	error:
		db 0
	material:
		dw ?material
	vertex1:
		dw ?vertex1 * Vector4._size
	vertex2:
		dw ?vertex2 * Vector4._size
	_size:
	ENDM

; iy = rasterizer
; ix = this
Edge_Prepare: PROC
	push iy
	ld c,(ix + Edge.vertex1)
	ld b,(ix + Edge.vertex1 + 1)
	ld iyl,c
	ld iyh,b
	ld l,(iy + Vector4.x)
	ld h,(iy + Vector4.y)
	ld a,(iy + Vector4.z)
	ld c,(ix + Edge.vertex2)
	ld b,(ix + Edge.vertex2 + 1)
	ld iyl,c
	ld iyh,b
	ld e,(iy + Vector4.x)
	ld d,(iy + Vector4.y)
	add a,(iy + Vector4.z)
	rr a
	ld (ix + Edge.z),a
	ld a,d
	sub h
	jr nc,NoSwap
	ex de,hl
	neg
NoSwap:
	ld (ix + Edge.x),l
	inc a
	ld (ix + Edge.height),a
	dec a
	ld (ix + Edge.dy),a
	ld c,a
	ld a,e
	sub l
	jr c,Left
Right:
	ld (ix + Edge.super.render),Edge_Render & 0FFH
	ld (ix + Edge.super.render + 1),Edge_Render >> 8
	jr Continue
Left:
	neg
	ld (ix + Edge.super.render),Edge_RenderLeft & 0FFH
	ld (ix + Edge.super.render + 1),Edge_RenderLeft >> 8
Continue:
	ld e,a
	call Math_Divide8x8
	ld (ix + Edge.stepx),a
	ld (ix + Edge.dx),b
	xor a
	srl c
	sbc a,c
	ld (ix + Edge.error),a
	pop iy
	ld e,h
	call Rasterizer_Add_IY
	ret
	ENDP

; bc = count
; iy = rasterizer
; ix = this
Edge_PrepareArray: PROC
Loop:
	push bc
	call Edge_Prepare
	pop bc
	ld de,Edge._size
	add ix,de
	dec bc
	ld a,b
	or c
	jr nz,Loop
	ret
	ENDP

; de = vertices
; ix = this
Edge_BakeVertices:
	ld l,(ix + Edge.vertex1)
	ld h,(ix + Edge.vertex1 + 1)
	add hl,de
	ld (ix + Edge.vertex1),l
	ld (ix + Edge.vertex1 + 1),h
	ld l,(ix + Edge.vertex2)
	ld h,(ix + Edge.vertex2 + 1)
	add hl,de
	ld (ix + Edge.vertex2),l
	ld (ix + Edge.vertex2 + 1),h
	ret

; bc = count
; de = vertices
; ix = this
Edge_BakeArrayVertices: PROC
Loop:
	call Edge_BakeVertices
	ex de,hl
	ld de,Edge._size
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
Edge_Render: PROC
	ld d,(ix + Edge.x)
	ld b,(ix + Edge.z)
	ld a,d
	add a,(ix + Edge.stepx)
	ld e,a
	ld a,(ix + Edge.error)
	add a,(ix + Edge.dx)
	jr nc,NoOverflow
	inc e
	sub (ix + Edge.dy)
NoOverflow:
	ld (ix + Edge.error),a
	ld (ix + Edge.x),e
	push ix
	ld a,(ix + Edge.material)
	ld c,(ix + Edge.material + 1)
	ld ixl,a
	ld ixh,c
	call Material_RenderPoint
	pop ix
	dec (ix + Edge.height)
	jp nz,Renderable_Advance
	jp Renderable_Next
	ENDP

; hl = span buffer (l is insignificant, assumed 0)
; iy = this
Edge_RenderLeft: PROC
	ld d,(ix + Edge.x)
	ld b,(ix + Edge.z)
	ld a,d
	sub (ix + Edge.stepx)
	ld e,a
	ld a,(ix + Edge.error)
	add a,(ix + Edge.dx)
	jr nc,NoOverflow
	dec e
	sub (ix + Edge.dy)
NoOverflow:
	ld (ix + Edge.error),a
	ld (ix + Edge.x),e
	push ix
	ld a,(ix + Edge.material)
	ld c,(ix + Edge.material + 1)
	ld ixl,a
	ld ixh,c
	call Material_RenderPoint
	pop ix
	dec (ix + Edge.height)
	jp nz,Renderable_Advance
	jp Renderable_Next
	ENDP
