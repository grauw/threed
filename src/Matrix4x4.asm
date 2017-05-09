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
	dec bc  ; 16-bit to 2x 8-bit loop
	inc b
	inc c
	ld a,b
	ld b,c
	ld c,a
Loop:
	push bc
	call Matrix4x4_MultiplyVector4
	ld bc,Vector4._size
	add iy,bc
	pop bc
	djnz Loop
	dec c
	jr nz,Loop
	ret
	ENDP
