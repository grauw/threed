;
; 4x4 matrix
;
Matrix4x4: MACRO ?m00 = 0, ?m01 = 0, ?m02 = 0, ?m03 = 0,
                 ?m10 = 0, ?m11 = 0, ?m12 = 0, ?m13 = 0,
                 ?m20 = 0, ?m21 = 0, ?m22 = 0, ?m23 = 0,
                 ?m30 = 0, ?m31 = 0, ?m32 = 0, ?m33 = 0
	row0:
		Vector4 ?m00, ?m01, ?m02, ?m03
	row1:
		Vector4 ?m10, ?m11, ?m12, ?m13
	row2:
		Vector4 ?m20, ?m21, ?m22, ?m23
	row3:
		Vector4 ?m30, ?m31, ?m32, ?m33
	_size:
	ENDM

IdentityMatrix4x4: MACRO
	Matrix4x4 100H, 0, 0, 0, 0, 100H, 0, 0, 0, 0, 100H, 0, 0, 0, 0, 100H
	ENDM

TranslateMatrix4x4: MACRO ?x = 0, ?y = 0, ?z = 0
	Matrix4x4 100H, 0, 0, ?x, 0, 100H, 0, ?y, 0, 0, 100H, ?z, 0, 0, 0, 100H
	ENDM

ScaleMatrix4x4: MACRO ?x = 0, ?y = 0, ?z = 0
	Matrix4x4 ?x, 0, 0, 0, 0, ?y, 0, 0, 0, 0, ?z, 0, 0, 0, 0, 100H
	ENDM

OrthographicMatrix4x4: MACRO ?aspect = 100H, ?fovtan = 100H, ?near = 100H, ?far = 500H
	Matrix4x4 100H * ?aspect / ?fovtan, 0, 0, 0,
	          0, 10000H / ?fovtan, 0, 0,
	          0, 0, 10000H / (?far - ?near), -100H * ?near / (?far - ?near),
	          0, 0, 0, 100H
	ENDM

PerspectiveMatrix4x4: MACRO ?aspect = 100H, ?fovtan = 100H, ?near = 100H, ?far = 500H
	Matrix4x4 100H * ?aspect / ?fovtan, 0, 0, 0,
	          0, 10000H / ?fovtan, 0, 0,
	          0, 0, 100H * ?far / (?far - ?near), -?far * ?near / (?far - ?near),
	          0, 0, 100H, 0
	ENDM

; iy = matrix
; ix = this
Matrix4x4_Multiply:
	ld bc,Vector4.w
	add iy,bc
	ld bc,Matrix4x4.row3 - Matrix4x4.row0
	add ix,bc
	call Matrix4x4_MultiplyRowColumn
	push hl
	dec iy
	dec iy
	call Matrix4x4_MultiplyRowColumn
	push hl
	dec iy
	dec iy
	call Matrix4x4_MultiplyRowColumn
	push hl
	dec iy
	dec iy
	call Matrix4x4_MultiplyRowColumn
	push hl
	ld bc,Vector4.w
	add iy,bc
	ld bc,Matrix4x4.row2 - Matrix4x4.row3
	add ix,bc
	call Matrix4x4_MultiplyRowColumn
	push hl
	dec iy
	dec iy
	call Matrix4x4_MultiplyRowColumn
	push hl
	dec iy
	dec iy
	call Matrix4x4_MultiplyRowColumn
	push hl
	dec iy
	dec iy
	call Matrix4x4_MultiplyRowColumn
	push hl
	ld bc,Vector4.w
	add iy,bc
	ld bc,Matrix4x4.row1 - Matrix4x4.row2
	add ix,bc
	call Matrix4x4_MultiplyRowColumn
	push hl
	dec iy
	dec iy
	call Matrix4x4_MultiplyRowColumn
	push hl
	dec iy
	dec iy
	call Matrix4x4_MultiplyRowColumn
	push hl
	dec iy
	dec iy
	call Matrix4x4_MultiplyRowColumn
	push hl
	ld bc,Vector4.w
	add iy,bc
	ld bc,Matrix4x4.row0 - Matrix4x4.row1
	add ix,bc
	call Matrix4x4_MultiplyRowColumn
	push hl
	dec iy
	dec iy
	call Matrix4x4_MultiplyRowColumn
	push hl
	dec iy
	dec iy
	call Matrix4x4_MultiplyRowColumn
	push hl
	dec iy
	dec iy
	call Matrix4x4_MultiplyRowColumn
	push hl
	ld hl,0
	add hl,sp
	ld e,ixl
	ld d,ixh
	REPT 4 * 4 * 2  ; Matrix4x4._size
	ldi
	ENDM
	ld sp,hl
	ret

; iy = other matrix column
; ix = this matrix row
; hl <- dot product
Matrix4x4_MultiplyRowColumn:
	ld c,(ix + Vector4.x)
	ld b,(ix + Vector4.x + 1)
	ld l,(iy + Matrix4x4.row0)
	ld h,(iy + Matrix4x4.row0 + 1)
	call Math_MultiplySigned8_8x8_8
	push hl
	ld c,(ix + Vector4.y)
	ld b,(ix + Vector4.y + 1)
	ld l,(iy + Matrix4x4.row1)
	ld h,(iy + Matrix4x4.row1 + 1)
	call Math_MultiplySigned8_8x8_8
	push hl
	ld c,(ix + Vector4.z)
	ld b,(ix + Vector4.z + 1)
	ld l,(iy + Matrix4x4.row2)
	ld h,(iy + Matrix4x4.row2 + 1)
	call Math_MultiplySigned8_8x8_8
	push hl
	ld c,(ix + Vector4.w)
	ld b,(ix + Vector4.w + 1)
	ld l,(iy + Matrix4x4.row3)
	ld h,(iy + Matrix4x4.row3 + 1)
	call Math_MultiplySigned8_8x8_8
	pop de
	add hl,de
	pop de
	add hl,de
	pop de
	add hl,de
	ret

; iy = vector
; ix = this
Matrix4x4_MultiplyVector4:
	ld bc,Matrix4x4.row3 - Matrix4x4.row0
	add ix,bc
	call Vector4_Dot
	push hl
	ld bc,Matrix4x4.row2 - Matrix4x4.row3
	add ix,bc
	call Vector4_Dot
	push hl
	ld bc,Matrix4x4.row1 - Matrix4x4.row2
	add ix,bc
	call Vector4_Dot
	push hl
	ld bc,Matrix4x4.row0 - Matrix4x4.row1
	add ix,bc
	call Vector4_Dot
	ld (iy + Vector4.x),l
	ld (iy + Vector4.x + 1),h
	pop hl
	ld (iy + Vector4.y),l
	ld (iy + Vector4.y + 1),h
	pop hl
	ld (iy + Vector4.z),l
	ld (iy + Vector4.z + 1),h
	pop hl
	ld (iy + Vector4.w),l
	ld (iy + Vector4.w + 1),h
	ret

; iy = vector array
; ix = this
; bc = count
Matrix4x4_MultiplyVector4Array: PROC
Loop:
	push bc
	call Matrix4x4_MultiplyVector4
	ld bc,Vector4._size
	add iy,bc
	pop bc
	dec bc
	ld a,b
	or c
	jr nz,Loop
	ret
	ENDP

; hl = angle (binary radians)
Matrix4x4_SetRotationX:
	push hl
	call Math_Cosine
	ld (ix + Matrix4x4.row1 + Vector4.y),e
	ld (ix + Matrix4x4.row1 + Vector4.y + 1),d
	ld (ix + Matrix4x4.row2 + Vector4.z),e
	ld (ix + Matrix4x4.row2 + Vector4.z + 1),d
	pop hl
	call Math_Sine
	ld (ix + Matrix4x4.row2 + Vector4.y),e
	ld (ix + Matrix4x4.row2 + Vector4.y + 1),d
	xor a
	sub e  ; negate de
	ld e,a
	sbc a,a
	sub d
	ld d,a
	ld (ix + Matrix4x4.row1 + Vector4.z),e
	ld (ix + Matrix4x4.row1 + Vector4.z + 1),d
	ret

; hl = angle (binary radians)
Matrix4x4_SetRotationY:
	push hl
	call Math_Cosine
	ld (ix + Matrix4x4.row0 + Vector4.x),e
	ld (ix + Matrix4x4.row0 + Vector4.x + 1),d
	ld (ix + Matrix4x4.row2 + Vector4.z),e
	ld (ix + Matrix4x4.row2 + Vector4.z + 1),d
	pop hl
	call Math_Sine
	ld (ix + Matrix4x4.row0 + Vector4.z),e
	ld (ix + Matrix4x4.row0 + Vector4.z + 1),d
	xor a
	sub e  ; negate de
	ld e,a
	sbc a,a
	sub d
	ld d,a
	ld (ix + Matrix4x4.row2 + Vector4.x),e
	ld (ix + Matrix4x4.row2 + Vector4.x + 1),d
	ret

; hl = angle (binary radians)
Matrix4x4_SetRotationZ:
	push hl
	call Math_Cosine
	ld (ix + Matrix4x4.row0 + Vector4.x),e
	ld (ix + Matrix4x4.row0 + Vector4.x + 1),d
	ld (ix + Matrix4x4.row1 + Vector4.y),e
	ld (ix + Matrix4x4.row1 + Vector4.y + 1),d
	pop hl
	call Math_Sine
	ld (ix + Matrix4x4.row1 + Vector4.x),e
	ld (ix + Matrix4x4.row1 + Vector4.x + 1),d
	xor a
	sub e  ; negate de
	ld e,a
	sbc a,a
	sub d
	ld d,a
	ld (ix + Matrix4x4.row0 + Vector4.y),e
	ld (ix + Matrix4x4.row0 + Vector4.y + 1),d
	ret
