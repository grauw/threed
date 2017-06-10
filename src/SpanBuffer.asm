;
; Span buffer
;
; See http://www.cs.bu.edu/groups/bugg/Quake/sbuf_faq.txt
;     http://tfpsly.free.fr/Docs/TomHammersley/sbuffer.htm
;
; It is using a linked list approach, however to avoid needing a span allocation
; mechanism, it puts spans in 256 buckets, one for each pixel. Furthermore, to
; speed up traversing the spans list, the span fields are placed in three
; aligned arrays rather than one array of span objects.
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

; hl = this
; hl <- this
SpanBuffer_Init:
	ld (hl),0
	inc h
	ld (hl),0FFH
	inc h
	ld (hl),0
	dec h
	dec h
	ret

; d = x
; e = end x
; b = z
; c = color
; hl = this
; Modifies: af
SpanBuffer_Insert: PROC
	ld a,e
	dec a
	cp d
	call c,System_ThrowException
	push bc
	xor a
StartLoop:
	ld l,a
	ld a,(hl)
	and a
	jr z,StartLoopBreak
	cp d
	jr c,StartLoop
StartLoopBreak:
	cp d
	jr z,StartNoSplit
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
	ld a,d
StartNoSplit:
EndLoop:
	ld l,a
	ld a,(hl)
	and a
	jr z,EndLoopBreak
	cp e
	jr c,EndLoop
EndLoopBreak:
	cp e
	jr z,EndNoSplit
EndSplit:
	ld a,(hl)
	ld (hl),e
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
EndNoSplit:
	pop bc
	ld a,d
FillLoop:
	ld l,a
	inc h
	ld a,(hl)
	cp b
	jr c,FillLoopNext
	ld (hl),b
	inc h
	ld (hl),c
	dec h
FillLoopNext:
	dec h
	ld a,(hl)
	cp e
	jr nz,FillLoop
	ld l,0
	ret
	ENDP

;
	SECTION RAM

	ALIGN 100H
SpanBuffer_instance: SpanBuffer

	ENDS
