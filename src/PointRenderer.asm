;
; Renders a points array
;
PointRenderer: MACRO
	image:
		dw 0
	ENDM

; de = image
; ix = this
PointRenderer_Construct:
	ld (ix + PointRenderer.image),e
	ld (ix + PointRenderer.image + 1),d
	ret

; ix = this
; ix <- image
PointRenderer_GetImage:
	ld e,(ix + PointRenderer.image)
	ld d,(ix + PointRenderer.image + 1)
	ld ixl,e
	ld ixh,d
	ret

; iy = points
; bc = count
; ix = this
PointRenderer_Draw: PROC
	call PointRenderer_Prepare
	dec bc  ; 16-bit to 2x 8-bit loop
	inc b
	inc c
	ld a,b
	ld b,c
	ld c,a
Loop:
	push bc
	call PointRenderer_DrawPoint
	pop bc
	ld de,Point._size
	add iy,de
	djnz Loop
	dec c
	jr nz,Loop
	ret
	ENDP

; bc = count
; iy = points
; ix = this
PointRenderer_Prepare:
	push bc
	push ix
	push iy
	push iy
	pop ix
	call Point_PrepareArray
	pop iy
	pop ix
	pop bc
	ret

; iy = point
; ix = this
PointRenderer_DrawPoint:
	push ix
	call PointRenderer_GetImage
	ld e,(iy + Point.x)
	ld d,(iy + Point.y)
	ld a,(iy + Point.color)
	call RunLengthImage_Pset
	pop ix
	ret
