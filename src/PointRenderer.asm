;
; Renders a points array
;
PointRenderer: MACRO
	image:
		dw 0
	buckets:
		ds 212 * 2
	ENDM

; de = image
; ix = this
PointRenderer_Construct:
	call PointRenderer_SetImage
	ret

; ix = this
; ix <- image
PointRenderer_GetImage:
	ld e,(ix + PointRenderer.image)
	ld d,(ix + PointRenderer.image + 1)
	ld ixl,e
	ld ixh,d
	ret

; de = image
; ix = this
PointRenderer_SetImage:
	ld (ix + PointRenderer.image),e
	ld (ix + PointRenderer.image + 1),d
	ret

; iy = points
; bc = count
; ix = this
PointRenderer_Draw:
	push bc
	push ix
	push iy
	push iy
	pop ix
	call Point_PrepareArray
	pop iy
	pop ix
	pop bc
	push bc
	push iy
	call PointRenderer_BucketSortPoints
	pop iy
	pop bc
	call PointRenderer_DrawScanlines
	ret

; bc = count
; iy = points
; ix = this
PointRenderer_BucketSortPoints: PROC
	ld hl,PointRenderer.buckets
	ld e,ixl
	ld d,ixh
	add hl,de
	push bc
	push hl
	ld e,l
	ld d,h
	inc de
	ld (hl),0
	ld bc,212 * 2 - 1
	ldir
	pop hl
	pop bc
Loop:
	ld a,(iy + Point.y)
	cp 212
	jr nc,Next
	add a,a
	ld e,a
	ld d,0
	rl d
	add hl,de
	ld a,(hl)
	ld (iy + Point.next),a
	inc hl
	ld a,(hl)
	ld (iy + Point.next + 1),a
	ld a,iyh
	ld (hl),a
	dec hl
	ld a,iyl
	ld (hl),a
	sbc hl,de
Next:
	ld de,Point._size
	add iy,de
	dec bc
	ld a,b
	or c
	jr nz,Loop
	ret
	ENDP

; ix = this
PointRenderer_DrawScanlines: PROC
	ld hl,PointRenderer.buckets
	ld e,ixl
	ld d,ixh
	add hl,de
	ld b,212
Loop:
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	inc d
	dec d
	jr z,Next
	push bc
	push hl
PointLoop:
	ld iyl,e
	ld iyh,d
	call PointRenderer_DrawPoint
	ld e,(iy + Point.next)
	ld d,(iy + Point.next + 1)
	ld a,e
	or d
	jr nz,PointLoop
	pop hl
	pop bc
Next:
	djnz Loop
	ret
	ENDP

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
