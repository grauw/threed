;
; 3-dimensional vector
;
Vector3: MACRO ?x = 0, ?y = 0, ?z = 0
	super: Vector2 ?x, ?y
	x: equ super.x
	y: equ super.y
	z:
		dw ?z
	_size:
	ENDM

; iy = other vector
; ix = this
Vector3_Multiply:
	call Vector2_Multiply
	ld c,(ix + Vector3.z)
	ld b,(ix + Vector3.z + 1)
	ld l,(iy + Vector3.z)
	ld h,(iy + Vector3.z + 1)
	call Math_MultiplySigned8_8x8_8
	ld (ix + Vector3.z),l
	ld (ix + Vector3.z + 1),h
	ret

; iy = other vector
; ix = this
; hl <- dot product
Vector3_Dot:
	call Vector2_Dot
	push hl
	ld c,(ix + Vector3.z)
	ld b,(ix + Vector3.z + 1)
	ld l,(iy + Vector3.z)
	ld h,(iy + Vector3.z + 1)
	call Math_MultiplySigned8_8x8_8
	pop de
	add hl,de
	ret
