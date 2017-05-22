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

; bc = count
; ix = vector array
Vector4_PerspectiveDivide:
	ld e,(ix + Vector4.w)
	ld d,(ix + Vector4.w + 1)
	call Math_ReciprocalSigned8_8
	push bc
	ld l,(ix + Vector4.x)
	ld h,(ix + Vector4.x + 1)
	call Math_MultiplySigned8_8x8_8
	ld bc,100H
	add hl,bc
	sra h
	rr l
	ld (ix + Vector4.x),l
	ld (ix + Vector4.x + 1),h
	pop bc
	push bc
	ld l,(ix + Vector4.y)
	ld h,(ix + Vector4.y + 1)
	call Math_MultiplySigned8_8x8_8
	ld bc,0D4H
	add hl,bc
	sra h
	rr l
	ld (ix + Vector4.y),l
	ld (ix + Vector4.y + 1),h
	pop bc
	ld l,(ix + Vector4.z)
	ld h,(ix + Vector4.z + 1)
	call Math_MultiplySigned8_8x8_8
	ld (ix + Vector4.z),l
	ld (ix + Vector4.z + 1),h
	ld (ix + Vector4.w),0
	ld (ix + Vector4.w + 1),1
	ret

; bc = count
; ix = vector array
Vector4_PerspectiveDivideArray: PROC
Loop:
	push bc
	call Vector4_PerspectiveDivide
	ld bc,Vector4._size
	add ix,bc
	pop bc
	dec bc
	ld a,b
	or c
	jr nz,Loop
	ret
	ENDP
