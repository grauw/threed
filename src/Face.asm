;
;
;
Face: MACRO ?vertex1, ?vertex2, ?vertex3, ?material
	super: Renderable Face_Render
	material:
		dw ?material
	vertex1:
		dw ?vertex1 * Vector4._size
	vertex2:
		dw ?vertex2 * Vector4._size
	vertex3:
		dw ?vertex3 * Vector4._size
	_size:
	ENDM

; ix = this
Face_Prepare: PROC
	ret
	ENDP

; bc = count
; ix = this
Face_PrepareArray: PROC
Loop:
	call Face_Prepare
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
	ld l,(ix + Face.vertex1)
	ld h,(ix + Face.vertex1 + 1)
	add hl,de
	ld (ix + Face.vertex1),l
	ld (ix + Face.vertex1 + 1),h
	ld l,(ix + Face.vertex2)
	ld h,(ix + Face.vertex2 + 1)
	add hl,de
	ld (ix + Face.vertex2),l
	ld (ix + Face.vertex2 + 1),h
	ld l,(ix + Face.vertex3)
	ld h,(ix + Face.vertex3 + 1)
	add hl,de
	ld (ix + Face.vertex3),l
	ld (ix + Face.vertex3 + 1),h
	ret

; bc = count
; de = vertices
; ix = this
Face_BakeArrayVertices: PROC
Loop:
	call Face_BakeVertices
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

; hl = span buffer (l is insignificant, assumed 0)
; iy = this
Face_Render: PROC
	jp Renderable_Next
	ENDP
