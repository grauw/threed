;
; 2-dimensional vector
;
Vector2: MACRO ?x = 0, ?y = 0
	x:
		dw ?x
	y:
		dw ?y
	_size:
	ENDM

; iy = other vector
; ix = this
Vector2_Multiply:
	ld c,(ix + Vector2.x)
	ld b,(ix + Vector2.x + 1)
	ld l,(iy + Vector2.x)
	ld h,(iy + Vector2.x + 1)
	call Math_MultiplySigned8_8x8_8
	ld (ix + Vector2.x),l
	ld (ix + Vector2.x + 1),h
	ld c,(ix + Vector2.y)
	ld b,(ix + Vector2.y + 1)
	ld l,(iy + Vector2.y)
	ld h,(iy + Vector2.y + 1)
	call Math_MultiplySigned8_8x8_8
	ld (ix + Vector2.y),l
	ld (ix + Vector2.y + 1),h
	ret

; iy = other vector
; ix = this
; hl <- dot product
Vector2_Dot:
	ld c,(ix + Vector2.x)
	ld b,(ix + Vector2.x + 1)
	ld l,(iy + Vector2.x)
	ld h,(iy + Vector2.x + 1)
	call Math_MultiplySigned8_8x8_8
	push hl
	ld c,(ix + Vector2.y)
	ld b,(ix + Vector2.y + 1)
	ld l,(iy + Vector2.y)
	ld h,(iy + Vector2.y + 1)
	call Math_MultiplySigned8_8x8_8
	pop de
	add hl,de
	ret
