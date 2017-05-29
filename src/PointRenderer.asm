;
; Renders a points array
;
PointRenderer: MACRO
	image:
		dw 0
	spanBuffer:
		dw SpanBuffer_instance
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

; ix = this
PointRenderer_Clear:
	ld hl,PointRenderer.buckets
	ld e,ixl
	ld d,ixh
	add hl,de
	ld e,l
	ld d,h
	inc de
	ld (hl),0
	ld bc,212 * 2 - 1
	ldir
	ret

; iy = points
; bc = count
; ix = this
PointRenderer_AddPoints:
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
	ret

; bc = count
; iy = points
; ix = this
PointRenderer_BucketSortPoints: PROC
	ld hl,PointRenderer.buckets
	ld e,ixl
	ld d,ixh
	add hl,de
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
PointRenderer_Draw: PROC
	ld hl,PointRenderer.buckets
	ld e,ixl
	ld d,ixh
	add hl,de
	ld b,212
Loop:
	push bc
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	push hl
	call PointRenderer_DrawScanline
	pop hl
	pop bc
	djnz Loop
	ret
	ENDP

; de = points
; ix = this
PointRenderer_DrawScanline:
	ld l,(ix + PointRenderer.spanBuffer)
	ld h,(ix + PointRenderer.spanBuffer + 1)
	call SpanBuffer_Init
	push hl
	inc d
	dec d
	ld iyl,e
	ld iyh,d
	call nz,Point_Draw_IY
	pop hl
	push ix
	call PointRenderer_GetImage
	call RunLengthImage_PlotSpanBuffer
	pop ix
	ret
