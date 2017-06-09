;
;
;
Material: MACRO ?color
	color:
		db ?color
	ENDM

; d = x
; b = z
; hl = span buffer
; ix = this
Material_RenderPoint:
	ld e,d
	inc e
	jr Material_RenderSpan

; d = x1
; e = x2
; b = z
; hl = span buffer
; ix = this
Material_RenderSpan:
	ld c,(ix + Material.color)
	call SpanBuffer_Insert
	ret

;
Material_blue:
	Material 55H

Material_red:
	Material 88H

Material_lightRed:
	Material 99H

Material_lightYellow:
	Material 0BBH

Material_green:
	Material 0CCH
