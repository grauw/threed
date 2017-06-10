;
;
;
Face: MACRO ?vertex1, ?vertex2, ?vertex3, ?material
	this:
	material:
		dw ?material
	hasX:
		db 0
	x:
		db 0
	z:
		db 0
	edge1:
		FaceEdge ?vertex1, ?vertex2, this
	edge2:
		FaceEdge ?vertex2, ?vertex3, this
	edge3:
		FaceEdge ?vertex3, ?vertex1, this
	_size:
	ENDM

; ix = this
Face_Prepare: PROC
	ld bc,Face.edge1
	add ix,bc
	call FaceEdge_Prepare
	ld bc,Face.edge2 - Face.edge1
	add ix,bc
	call FaceEdge_Prepare
	ld bc,Face.edge3 - Face.edge2
	add ix,bc
	call FaceEdge_Prepare
	ld bc,-Face.edge3
	add ix,bc
	ret
	ENDP

; bc = count
; ix = this
Face_PrepareArray: PROC
Loop:
	push bc
	call Face_Prepare
	pop bc
	ld de,Face._size
	add ix,de
	dec bc
	ld a,b
	or c
	jr nz,Loop
	ret
	ENDP

; de = vertices
; ix = this
Face_BakeVertices:
	ld bc,Face.edge1
	add ix,bc
	call FaceEdge_BakeVertices
	ld bc,Face.edge2 - Face.edge1
	add ix,bc
	call FaceEdge_BakeVertices
	ld bc,Face.edge3 - Face.edge2
	add ix,bc
	call FaceEdge_BakeVertices
	ld bc,-Face.edge3
	add ix,bc
	ret

; bc = count
; de = vertices
; ix = this
Face_BakeArrayVertices: PROC
Loop:
	push bc
	call Face_BakeVertices
	pop bc
	ex de,hl
	ld de,Face._size
	add ix,de
	ex de,hl
	dec bc
	ld a,b
	or c
	jr nz,Loop
	ret
	ENDP

; d = x
; b = z
; hl = span buffer
; ix = this
; Modifies: ix
Face_Render: PROC
	bit 0,(ix + Face.hasX)
	jr nz,HasX
	set 0,(ix + Face.hasX)
	ld (ix + Face.x),e
	ld (ix + Face.z),b
	ret
HasX:
	res 0,(ix + Face.hasX)
	ld d,(ix + Face.x)
	ld a,(ix + Face.z)
	add a,b
	rr a
	ld b,a
	ld a,e
	cp d
	jr nc,NoSwap
	ld e,d
	ld d,a
NoSwap:
	ld a,(ix + Face.material)
	ld c,(ix + Face.material + 1)
	ld ixl,a
	ld ixh,c
	call Material_RenderSpan
	ret
	ENDP
