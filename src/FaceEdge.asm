;
; A face edge
;
; Using Bresenham’s Run-Slice algorithm
; See Michael Abrash’s Graphics Programming Black Book chapter 36
; http://downloads.gamedev.net/pdf/gpbb/gpbb36.pdf
;
FaceEdge: MACRO ?vertex1, ?vertex2, ?face
	super: Renderable FaceEdge_Render
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
	face:
		dw ?face
	vertex1:
		dw ?vertex1 * Vector4._size
	vertex2:
		dw ?vertex2 * Vector4._size
	_size:
	ENDM

; iy = rasterizer
; ix = this
FaceEdge_Prepare: PROC
	push iy
	ld c,(ix + FaceEdge.vertex1)
	ld b,(ix + FaceEdge.vertex1 + 1)
	ld iyl,c
	ld iyh,b
	ld l,(iy + Vector4.x)
	ld h,(iy + Vector4.y)
	ld a,(iy + Vector4.z)
	ld c,(ix + FaceEdge.vertex2)
	ld b,(ix + FaceEdge.vertex2 + 1)
	ld iyl,c
	ld iyh,b
	ld e,(iy + Vector4.x)
	ld d,(iy + Vector4.y)
	add a,(iy + Vector4.z)
	rr a
	ld (ix + FaceEdge.z),a
	ld a,d
	sub h
	jr nc,NoSwap
	ex de,hl
	neg
NoSwap:
	and a
	jr z,DontAdd
	ld (ix + FaceEdge.x),l
	ld (ix + FaceEdge.height),a
	ld (ix + FaceEdge.dy),a
	ld c,a
	ld a,e
	sub l
	jr c,Left
Right:
	ld (ix + FaceEdge.super.render),FaceEdge_Render & 0FFH
	ld (ix + FaceEdge.super.render + 1),FaceEdge_Render >> 8
	jr Continue
Left:
	neg
	ld (ix + FaceEdge.super.render),FaceEdge_RenderLeft & 0FFH
	ld (ix + FaceEdge.super.render + 1),FaceEdge_RenderLeft >> 8
Continue:
	ld e,a
	call Math_Divide8x8
	ld (ix + FaceEdge.stepx),a
	ld (ix + FaceEdge.dx),b
	xor a
	srl c
	sbc a,c
	ld (ix + FaceEdge.error),a
	pop iy
	ld e,h
	call Rasterizer_Add_IY
	ret
DontAdd:
	pop iy
	ret
	ENDP

; bc = count
; iy = rasterizer
; ix = this
FaceEdge_PrepareArray: PROC
Loop:
	push bc
	call FaceEdge_Prepare
	pop bc
	ld de,FaceEdge._size
	add ix,de
	dec bc
	ld a,b
	or c
	jr nz,Loop
	ret
	ENDP

; de = vertices
; ix = this
FaceEdge_BakeVertices:
	ld l,(ix + FaceEdge.vertex1)
	ld h,(ix + FaceEdge.vertex1 + 1)
	add hl,de
	ld (ix + FaceEdge.vertex1),l
	ld (ix + FaceEdge.vertex1 + 1),h
	ld l,(ix + FaceEdge.vertex2)
	ld h,(ix + FaceEdge.vertex2 + 1)
	add hl,de
	ld (ix + FaceEdge.vertex2),l
	ld (ix + FaceEdge.vertex2 + 1),h
	ret

; bc = count
; de = vertices
; ix = this
FaceEdge_BakeArrayVertices: PROC
Loop:
	call FaceEdge_BakeVertices
	ex de,hl
	ld de,FaceEdge._size
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
FaceEdge_Render: PROC
	ld d,(ix + FaceEdge.x)
	ld b,(ix + FaceEdge.z)
	ld a,d
	add a,(ix + FaceEdge.stepx)
	ld e,a
	ld a,(ix + FaceEdge.error)
	add a,(ix + FaceEdge.dx)
	jr nc,NoOverflow
	inc e
	sub (ix + FaceEdge.dy)
NoOverflow:
	ld (ix + FaceEdge.error),a
	ld (ix + FaceEdge.x),e
	push ix
	ld a,(ix + FaceEdge.face)
	ld c,(ix + FaceEdge.face + 1)
	ld ixl,a
	ld ixh,c
	call Face_Render
	pop ix
	dec (ix + FaceEdge.height)
	jp nz,Renderable_Advance
	jp Renderable_Next
	ENDP

; hl = span buffer (l is insignificant, assumed 0)
; iy = this
FaceEdge_RenderLeft: PROC
	ld e,(ix + FaceEdge.x)
	ld b,(ix + FaceEdge.z)
	ld a,e
	sub (ix + FaceEdge.stepx)
	ld d,a
	ld a,(ix + FaceEdge.error)
	add a,(ix + FaceEdge.dx)
	jr nc,NoOverflow
	dec d
	sub (ix + FaceEdge.dy)
NoOverflow:
	ld (ix + FaceEdge.error),a
	ld (ix + FaceEdge.x),d
	push ix
	ld a,(ix + FaceEdge.face)
	ld c,(ix + FaceEdge.face + 1)
	ld ixl,a
	ld ixh,c
	call Face_Render
	pop ix
	dec (ix + FaceEdge.height)
	jp nz,Renderable_Advance
	jp Renderable_Next
	ENDP
