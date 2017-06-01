;
; Shape renderable with the scanline renderer
;
Renderable: MACRO ?render, ?y = 0
	; hl = span buffer
	; iy = last active
	; ix = this
	Render:
		jp ?render
	render: equ $ - 2
	next:
		dw 0
	y:
		db ?y
	ENDM

; hl = span buffer
; iy = last active
; ix = this
Renderable_RENDER: MACRO
	jp ix
	ENDM

; hl = span buffer
; iy = last active
; ix = this
Renderable_Render:
	Renderable_RENDER

; hl = span buffer
; iy = last active
; ix = this
Renderable_Advance:
	ld e,ixl
	ld d,ixh
	ld iyl,e
	ld iyh,d
	ld e,(ix + Renderable.next)
	ld d,(ix + Renderable.next + 1)
	ld ixl,e
	ld ixh,d
	Renderable_RENDER

; hl = span buffer
; iy = last active
; ix = this
Renderable_Next:
	ld e,(ix + Renderable.next)
	ld d,(ix + Renderable.next + 1)
	ld (iy + Renderable.next),e
	ld (iy + Renderable.next + 1),d
	ld ixl,e
	ld ixh,d
	Renderable_RENDER
