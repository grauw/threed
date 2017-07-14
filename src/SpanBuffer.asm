;
; Span buffer
;
; See http://www.cs.bu.edu/groups/bugg/Quake/sbuf_faq.txt
;     http://tfpsly.free.fr/Docs/TomHammersley/sbuffer.htm
;
; It is using a linked list approach, however to avoid needing a span allocation
; mechanism, it puts spans in 256 buckets, one for each pixel. To speed up
; traversing the spans list, the span fields are placed in three aligned arrays
; rather than one array of span objects. Also the buckets are shifted left by 1,
; (so x 0 is in bucket 255) to avoid special-casing end x 0 (=100H).
;
SpanBuffer: MACRO
	IF ($ & 0FFH) != 0
		ERROR "Must be aligned to 100H."
	ENDIF
	next:
		ds 100H
	z:
		ds 100H
	color:
		ds 100H
	ENDM

; a = clear colour
; h = this
; h <- this
SpanBuffer_Clear:
	ld l,-1
	ld (hl),255
	inc h
	ld (hl),0FFH
	inc h
	ld (hl),a
	dec h
	dec h
	ret

; d = x
; e = end x
; b = z
; c = color
; h = this
; Modifies: af, d, e
SpanBuffer_Insert: PROC
	dec e
	ld a,e
	cp d
	call c,System_ThrowException
	dec d
	ld a,255
	cp d
	jr z,StartNoSplit

; a = x
; d = span x
; e = span end x
StartLoop:
	ld l,a
	ld a,(hl)
	cp d
	jr c,StartLoop
	jr z,StartNoSplit
StartSplit:
	inc h
	ld a,(hl)
	dec h
	cp b
	jr c,CullLoopFromFill
	push bc
	ld a,(hl)
	ld (hl),d
	inc h
	ld b,(hl)
	inc h
	ld c,(hl)
	ld l,d
	ld (hl),c
	dec h
	ld (hl),b
	dec h
	ld (hl),a
	pop bc
	jr FillLoopFromStart
StartNoSplit:
	ld l,a
	inc h
	ld a,(hl)
	dec h
	cp b
	jr c,CullLoopFromFill
	jr FillLoopFromCull

; l = fill start x
; e = end x
CullToFill:
	ld d,l
	jr FillLoopFromCull

; a = x
; d = fill start x
; e = end x
FillLoop:
	ld l,a
	inc h
	ld a,(hl)
	dec h
	cp b
	jr c,FillToCull
FillLoopFromCull:
	ld a,(hl)
FillLoopFromStart:
	cp e
	jr c,FillLoop
	jr z,FillEndNoSplit
FillEndSplit:
	push bc
	inc h
	ld b,(hl)
	inc h
	ld c,(hl)
	ld l,e
	ld (hl),c
	dec h
	ld (hl),b
	dec h
	ld (hl),a
	pop bc
FillEndNoSplit:
	ld l,d
	ld (hl),e
	inc h
	ld (hl),b
	inc h
	ld (hl),c
	dec h
	dec h
	ret

; d = fill start x
; l = fill end x
; e = end x
FillToCull:
	ld a,l
	ld l,d
	ld (hl),a
	inc h
	ld (hl),b
	inc h
	ld (hl),c
	dec h
	dec h
	ld l,a
	jr CullLoopFromFill

; a = x
; e = end x
CullLoop:
	ld l,a
	inc h
	ld a,(hl)
	dec h
	cp b
	jr nc,CullToFill
CullLoopFromFill:
	ld a,(hl)
	cp e
	jr c,CullLoop
	ret
	ENDP

;
	SECTION RAM

	ALIGN 100H
SpanBuffer_instance: SpanBuffer

	ENDS
