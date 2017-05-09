;
; 4-dimensional vector
;
Vector4: MACRO ?x = 0, ?y = 0, ?z = 0, ?w = 0
	super: Vector3 ?x, ?y, ?z
	x: equ super.x
	y: equ super.y
	z: equ super.z
	w:
		dw ?w
	_size:
	ENDM

; iy = other vector
; ix = this
Vector4_Multiply:
	call Vector3_Multiply
	ld c,(ix + Vector4.w)
	ld b,(ix + Vector4.w + 1)
	ld l,(iy + Vector4.w)
	ld h,(iy + Vector4.w + 1)
	call Math_MultiplySigned8_8x8_8
	ld (ix + Vector4.w),l
	ld (ix + Vector4.w + 1),h
	ret

; iy = other vector
; ix = this
; hl <- dot product
Vector4_Dot:
	call Vector3_Dot
	push hl
	ld c,(ix + Vector4.w)
	ld b,(ix + Vector4.w + 1)
	ld l,(iy + Vector4.w)
	ld h,(iy + Vector4.w + 1)
	call Math_MultiplySigned8_8x8_8
	pop de
	add hl,de
	ret
