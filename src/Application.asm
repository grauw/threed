;
; Top-level program class
;
Application: MACRO
	pointRenderer:
		PointRenderer
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
; ix <- point renderer
Application_GetPointRenderer:
	ld de,Application.pointRenderer
	add ix,de
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
	ld hl,Application_vertices
	ld de,Application_verticesBuffer
	ld bc,Application_vertices_COUNT * Vector4._size
	ldir

	ld hl,Application_projection
	ld de,Application_mvp
	ld bc,Matrix4x4._size
	ldir

	push ix
	ld ix,Application_mvp
	ld iy,Application_view
	call Matrix4x4_Multiply
	pop ix

	push ix
	ld ix,Application_mvp
	ld iy,Application_model
	call Matrix4x4_Multiply
	pop ix

	push ix
	ld ix,Application_mvp
	ld iy,Application_verticesBuffer
	ld bc,Application_vertices_COUNT
	call Matrix4x4_MultiplyVector4Array
	pop ix

	push ix
	ld ix,Application_verticesBuffer
	ld bc,Application_vertices_COUNT
	call PointRenderer_PerspectiveDivideArray
	pop ix

	push ix
	ld iy,Application_verticesBuffer
	ld bc,Application_vertices_COUNT
	call Application_GetPointRenderer
	call PointRenderer_Draw
	pop ix

	push ix
	call Application_GetPointRenderer
	call PointRenderer_Swap
	pop ix

	ld a,(Application_model + Matrix4x4.row0 + Vector4.w)
	add a,20H
	ld (Application_model + Matrix4x4.row0 + Vector4.w),a

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

Application_model:
	Matrix4x4  100H,    0H,    0H,    0H,
	             0H,  100H,    0H,    0H,
	             0H,    0H,  100H,    0H,
	             0H,    0H,    0H,  100H

Application_view:
	Matrix4x4  100H,    0H,    0H,    0H,
	             0H,  100H,    0H,    0H,
	             0H,    0H,  100H,  100H,
	             0H,    0H,    0H,  100H

Application_projection:
	Matrix4x4   40H,    0H,    0H,    0H,
	             0H,   40H,    0H,    0H,
	             0H,    0H,   40H,   20H,
	             0H,    0H,  100H,  100H

Application_mvp:
	IdentityMatrix4x4

Application_verticesBuffer:
	ds Application_vertices_COUNT * Vector4._size

	ENDS
