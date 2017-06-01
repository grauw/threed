;
; Renders renderables
;
Rasterizer_HEIGHT: equ 212

Rasterizer: MACRO
	super: Renderable Rasterizer_Render
	height:
		db Rasterizer_HEIGHT
	image:
		dw 0
	spanBuffer:
		dw SpanBuffer_instance
	buckets:
		ds 256 * 2
	ENDM

; de = image
; ix = this
Rasterizer_Construct:
	call Rasterizer_SetImage
	ret

; ix = this
; ix <- image
Rasterizer_GetImage:
	ld e,(ix + Rasterizer.image)
	ld d,(ix + Rasterizer.image + 1)
	ld ixl,e
	ld ixh,d
	ret

; de = image
; ix = this
Rasterizer_SetImage:
	ld (ix + Rasterizer.image),e
	ld (ix + Rasterizer.image + 1),d
	ret

; ix = this
Rasterizer_Clear:
	ld hl,Rasterizer.buckets
	ld e,ixl
	ld d,ixh
	add hl,de
	ld (hl),e
	inc hl
	ld (hl),d
	ld e,l
	ld d,h
	inc de
	dec hl
	ld bc,(Rasterizer_HEIGHT - 1) * 2
	ldir
	ld (ix + Renderable.y),0
	ld (ix + Rasterizer.height),Rasterizer_HEIGHT
	ret

; bc = renderable count
; de = renderable size
; iy = renderables
; ix = this
Rasterizer_AddArray: PROC
Loop:
	ex de,hl
	call Rasterizer_Add
	ex de,hl
	add iy,de
	dec bc
	ld a,b
	or c
	jr nz,Loop
	ret
	ENDP

; iy = renderable
; ix = this
; Modifies: de
Rasterizer_Add:
	ld e,(iy + Renderable.y)
	ld d,0
	push ix
	add ix,de
	add ix,de
	ld e,(ix + Rasterizer.buckets)
	ld d,(ix + Rasterizer.buckets + 1)
	ld (iy + Renderable.next),e
	ld (iy + Renderable.next + 1),d
	ld e,iyl
	ld d,iyh
	ld (ix + Rasterizer.buckets),e
	ld (ix + Rasterizer.buckets + 1),d
	pop ix
	ret

; ix = this
Rasterizer_StartRender:
	ld e,ixl
	ld d,ixh
	ld iyl,e
	ld iyh,d
	ld l,(ix + Rasterizer.spanBuffer)
	ld h,(ix + Rasterizer.spanBuffer + 1)
	jr Rasterizer_Render.Start

; hl = span buffer
; iy = last active
; ix = this
Rasterizer_Render: PROC
	push ix
	call Rasterizer_GetImage
	call RunLengthImage_PlotSpanBuffer
	pop ix
Start:
	dec (ix + Rasterizer.height)
	ret z
	call SpanBuffer_Init
	ld e,(ix + Renderable.y)
	inc (ix + Renderable.y)
	ld d,0
	push ix
	add ix,de
	add ix,de
	ld e,(ix + Rasterizer.buckets)
	ld d,(ix + Rasterizer.buckets + 1)
	pop ix
	ld (iy + Renderable.next),e
	ld (iy + Renderable.next + 1),d
	push ix
	pop iy
	ld e,(ix + Renderable.next)
	ld d,(ix + Renderable.next + 1)
	ld ixl,e
	ld ixh,d
	Renderable_RENDER
	ENDP
