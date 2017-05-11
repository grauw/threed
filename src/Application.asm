;
; Top-level program class
;
Application: MACRO
	ENDM

Application_Main:
	call VDP_GetVersion
	cp 2
	ret c

	call ROM_Init
	call RAM_Init

	IF R800
	call System_EnableTurbo
	ELSE
	call System_DisableTurbo
	ENDIF

	call MemoryTest_Test

	ld ix,Application_instance
	call Application_Construct
	call Application_EnterMainLoop

	call KILBUF
	ret

; ix = this
Application_Construct:
	ret

; ix = this
Application_EnterMainLoop:
	call VDP_EnableBlank
	ld a,0
	ld (CLIKSW),a  ; disable key click
	ld a,0
	ld (BAKCLR),a
	ld a,5
	call VDP_InitScreen
	call VDP_DisableSprites
	call VDP_Enable60Hz
	ld a,0F1H
	call VDP_SetColor

	call VDP_DisableBlank

	call Application_MainLoop
	ret

; ix = this
Application_MainLoop:
	push ix
	ld ix,Application_mvp
	ld iy,Application_projection
	call Matrix4x4_Multiply
	pop ix

	push ix
	ld ix,Application_mvp
	ld iy,Application_vertices
	ld bc,Application_vertices_COUNT
	call Matrix4x4_MultiplyVector4Array
	pop ix

	push ix
	ld ix,Application_vertices
	ld bc,Application_vertices_COUNT
	call PointRenderer_Draw
	pop ix

	jr $
	jp Application_MainLoop
	ret

;
	SECTION RAM

Application_instance: Application

Application_vertices:
	Vector4 80H, 80H, 80H, 100H
	Vector4 -80H, 80H, 80H, 100H
	Vector4 80H, -80H, 80H, 100H
	Vector4 -80H, -80H, 80H, 100H
	Vector4 80H, 80H, -80H, 100H
	Vector4 -80H, 80H, -80H, 100H
	Vector4 80H, -80H, -80H, 100H
	Vector4 -80H, -80H, -80H, 100H

Application_vertices_COUNT: equ 8

Application_projection:
	Matrix4x4   40H,    0H,    0H,   80H,
	             0H,   40H,    0H,   6AH,
	             0H,    0H,   40H,    0H,
	             0H,    0H,    0H,  100H

Application_mvp:
	IdentityMatrix4x4

	ENDS
