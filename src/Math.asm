; bc = multiplicand
; hl = multiplier
; dehl <- product
Math_MultiplySigned16x16: PROC
	bit 7,b
	jr nz,NegativeMultiplicand
	bit 7,h
	jr nz,NegativeMultiplier
	Math_MULTIPLY16X16
	ret
NegativeMultiplicand:
	bit 7,h
	jr nz,NegativeBoth
	push hl
	Math_MULTIPLY16X16
	ex de,hl
	pop bc
	sbc hl,bc
	ex de,hl
	ret
NegativeMultiplier:
	push bc
	Math_MULTIPLY16X16
	ex de,hl
	pop bc
	sbc hl,bc
	ex de,hl
	ret
NegativeBoth:
	push bc
	push hl
	Math_MULTIPLY16X16
	ex de,hl
	pop bc
	sbc hl,bc
	pop bc
	sbc hl,bc
	ex de,hl
	ret
	ENDP

; bc = multiplicand
; hl = multiplier
; hl <- product
Math_MultiplySigned8_8x8_8: PROC
	bit 7,b
	jr nz,NegativeMultiplicand
	bit 7,h
	jr nz,NegativeMultiplier
	Math_MULTIPLY16X16
	ld l,h
	ld h,e
	ret
NegativeMultiplicand:
	bit 7,h
	jr nz,NegativeBoth
	ld a,l
	Math_MULTIPLY16X16
	neg
	add a,e
	ld l,h
	ld h,a
	ret
NegativeMultiplier:
	ld a,c
	Math_MULTIPLY16X16
	neg
	add a,e
	ld l,h
	ld h,a
	ret
NegativeBoth:
	ld a,c
	add a,l
	Math_MULTIPLY16X16
	neg
	add a,e
	ld l,h
	ld h,a
	ret
	ENDP

; hl = multiplicand
; bc = multiplier
; dehl <- product
Math_MULTIPLY16X16: MACRO
	IF R800
	muluw hl,bc
	ELSE
	call Math_Multiply16x16_Z80
	ENDIF
	ENDM

; hl = multiplicand
; bc = multiplier
; dehl <- product
Math_Multiply16x16_Z80: PROC
	ex de,hl
	ld hl,0
	REPT 16
Loop:
	add hl,hl
	rl e
	rl d
	jr nc,NoAdd
	add hl,bc
	jp nc,NoAdd
	inc de
NoAdd:
	ENDM
	ret
	ENDP

; bc = dividend
; de = divisor
; bc <- quotient
; hl <- remainder
; Modifies: af
Math_Divide8_8x8_8: PROC
	ld h,0
	ld l,b  ; TODO: if b > d then overflow? or is h overflow and l remainder?
	ld a,c
	REPT 8
	rla
	adc hl,hl
	sbc hl,de
	jr nc,NoRestore
	add hl,de
NoRestore:
	ENDM
	rla
	cpl
	ld b,a
	REPT 8
	add hl,hl
	sbc hl,de
	jr nc,NoRestore
	add hl,de
NoRestore:
	rla
	ENDM
	cpl
	ld c,a
	ret
	ENDP

; bc = dividend
; de = negated divisor
; bc <- quotient
; hl <- remainder
; Modifies: af
Math_Divide8_8xNegated8_8: PROC
	ld h,0
	ld l,b  ; TODO: if b > d then overflow? or is h overflow and l remainder?
	ld a,c
	REPT 8
	rla
	adc hl,hl
	add hl,de
	jr c,NoRestore
	sbc hl,de
NoRestore:
	ENDM
	rla
	ld b,a
	REPT 8
	add hl,hl
	add hl,de
	jr c,NoRestore
	sbc hl,de
NoRestore:
	rla
	ENDM
	ld c,a
	ret
	ENDP

; bc = dividend
; de = divisor
; bc <- quotient
; Modifies: af, hl
Math_DivideSigned8_8x8_8: PROC
	bit 7,b
	jr nz,NegativeDividend
	bit 7,d
	jr nz,NegativeDivisor
	call Math_Divide8_8x8_8
	ret
NegativeDividend:
	bit 7,d
	jr nz,NegativeBoth
	xor a
	sub c  ; negate bc
	ld c,a
	sbc a,a
	sub b
	ld b,a
	call Math_Divide8_8x8_8
	xor a
	sub c  ; negate bc
	ld c,a
	sbc a,a
	sub b
	ld b,a
	ld a,h  ; fix rounding
	or l
	ret z
	dec bc
	ret
NegativeDivisor:
	call Math_Divide8_8xNegated8_8
	xor a
	sub c  ; negate bc
	ld c,a
	sbc a,a
	sub b
	ld b,a
	ld a,h  ; fix rounding
	or l
	ret z
	dec bc
	ret
NegativeBoth:
	xor a
	sub c  ; negate bc
	ld c,a
	sbc a,a
	sub b
	ld b,a
	call Math_Divide8_8xNegated8_8
	ret
	ENDP
