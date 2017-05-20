;
; Top-level program class
;
Application: MACRO
	frame:
		dw 0
	pointRenderer:
		PointRenderer
	edgeRenderer:
		EdgeRenderer
	faceRenderer:
		FaceRenderer
	image:
		RunLengthImage
	ENDM

Application_Main:
	call VDP_GetVersion
	cp 2
	ret c

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
	push ix
	push ix
	call Application_GetImage
	ex (sp),ix
	call Application_GetPointRenderer
	pop de
	call PointRenderer_Construct
	pop ix
	ret

; ix = this
; ix <- point renderer
Application_GetPointRenderer:
	ld de,Application.pointRenderer
	add ix,de
	ret

; ix = this
; ix <- edge renderer
Application_GetEdgeRenderer:
	ld de,Application.edgeRenderer
	add ix,de
	ret

; ix = this
; ix <- face renderer
Application_GetFaceRenderer:
	ld de,Application.faceRenderer
	add ix,de
	ret

; ix = this
; ix <- image
Application_GetImage:
	ld de,Application.image
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

	push ix
	ld ix,Application_points
	ld bc,Application_points_COUNT
	ld de,Application_verticesBuffer
	call Point_BakeArrayVertices
	pop ix

	push ix
	ld ix,Application_edges
	ld bc,Application_edges_COUNT
	ld de,Application_verticesBuffer
	call Edge_BakeArrayVertices
	pop ix

	push ix
	ld ix,Application_faces
	ld bc,Application_faces_COUNT
	ld de,Application_verticesBuffer
	call Face_BakeArrayVertices
	pop ix

	call Application_MainLoop
	ret

; ix = this
Application_MainLoop:
	push ix
	ld l,(ix + Application.frame)
	ld h,(ix + Application.frame + 1)
	add hl,hl
	add hl,hl
	add hl,hl
	ld ix,Application_rotation
	call Matrix4x4_SetRotationY
	pop ix

	push ix
	ld l,(ix + Application.frame)
	ld h,(ix + Application.frame + 1)
	add hl,hl
	ld h,0
	add hl,hl
	dec h
	add hl,hl
	ld ix,Application_model
	ld (ix + Matrix4x4.row0 + Vector4.w),l
	ld (ix + Matrix4x4.row0 + Vector4.w + 1),h
	pop ix

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
	ld iy,Application_rotation
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
	call Vector4_PerspectiveDivideArray
	pop ix

	call Application_DrawPoints
;	call Application_DrawEdges
;	call Application_DrawFaces

	ld l,(ix + Application.frame)
	ld h,(ix + Application.frame + 1)
	inc hl
	ld (ix + Application.frame),l
	ld (ix + Application.frame + 1),h

	jp Application_MainLoop
	ret

; ix = this
Application_DrawPoints:
	push ix
	call Application_GetImage
	call RunLengthImage_ClearBlack
	pop ix

	push ix
	ld iy,Application_points
	ld bc,Application_points_COUNT
	call Application_GetPointRenderer
	call PointRenderer_Draw
	pop ix

	push ix
	call Application_GetImage
	call RunLengthImage_Draw
	pop ix
	ret

; ix = this
Application_DrawEdges:
	push ix
	ld iy,Application_edges
	ld bc,Application_edges_COUNT
	call Application_GetEdgeRenderer
	call EdgeRenderer_Draw
	call EdgeRenderer_Swap
	pop ix
	ret

; ix = this
Application_DrawFaces:
	push ix
	ld iy,Application_faces
	ld bc,Application_faces_COUNT
	call Application_GetFaceRenderer
	call FaceRenderer_Draw
	call FaceRenderer_Swap
	pop ix
	ret

;
	SECTION RAM

Application_instance: Application

Application_vertices:
	Vector4 80H, 80H, 80H, 100H
	Vector4 -80H, 80H, 80H, 100H
	Vector4 -80H, -80H, 80H, 100H
	Vector4 80H, -80H, 80H, 100H
	Vector4 80H, 80H, -80H, 100H
	Vector4 -80H, 80H, -80H, 100H
	Vector4 -80H, -80H, -80H, 100H
	Vector4 80H, -80H, -80H, 100H

Application_vertices_COUNT: equ 8

Application_points:
	Point 0, 99H
	Point 1, 99H
	Point 2, 99H
	Point 3, 99H
	Point 4, 0BBH
	Point 5, 0BBH
	Point 6, 0BBH
	Point 7, 0BBH

Application_points_COUNT: equ 8

Application_edges:
	Edge 0, 1, 5
	Edge 1, 2, 5
	Edge 2, 3, 5
	Edge 3, 0, 5
	Edge 0, 4, 8
	Edge 1, 5, 8
	Edge 2, 6, 8
	Edge 3, 7, 8
	Edge 4, 5, 12
	Edge 5, 6, 12
	Edge 6, 7, 12
	Edge 7, 4, 12

Application_edges_COUNT: equ 12

Application_faces:
	Face 0, 4, 7, 8
	Face 0, 7, 3, 8
	Face 0, 1, 5, 8
	Face 0, 5, 4, 8
	Face 6, 5, 1, 8
	Face 6, 1, 2, 8
	Face 6, 2, 3, 8
	Face 6, 3, 7, 8
	Face 0, 1, 2, 5
	Face 0, 2, 3, 5
	Face 6, 5, 4, 12
	Face 6, 4, 7, 12

Application_faces_COUNT: equ 12

Application_rotation:
	IdentityMatrix4x4

Application_model:
	Matrix4x4  100H,    0H,    0H,    0H,
	             0H,  100H,    0H,    0H,
	             0H,    0H,  100H,    0H,
	             0H,    0H,    0H,  100H

Application_view:
	Matrix4x4  100H,    0H,    0H,    0H,
	             0H,  100H,    0H,    0H,
	             0H,    0H,  100H,  200H,
	             0H,    0H,    0H,  100H

Application_projection:
	Matrix4x4  100H,    0H,    0H,    0H,
	             0H,  100H,    0H,    0H,
	             0H,    0H,  100H,    0H,
	             0H,    0H,  100H,  100H

Application_mvp:
	IdentityMatrix4x4

Application_verticesBuffer:
	ds Application_vertices_COUNT * Vector4._size

	ENDS
