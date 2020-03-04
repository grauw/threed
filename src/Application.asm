;
; Top-level program class
;
Application: MACRO
	frame:
		dw 0
	image:
		dw image_
	altImage:
		dw altImage_
	rasterizer:
		Rasterizer
	image_:
		RunLengthImage
	altImage_:
		RunLengthImage
	ENDM

Application_Main:
	call VDP_GetVersion
	cp 2
	ret c

	ld hl,IDBYT2
	call System_ReadBIOS
	cp 3
	ld a,R800 ? 10000001B : 10000000B
	ld ix,CHGCPU
	call nc,System_CallBIOS

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
	call Application_GetRasterizer
	pop de
	call Rasterizer_Construct
	pop ix
	ret

; ix = this
; ix <- rasterizer
Application_GetRasterizer:
	ld de,Application.rasterizer
	add ix,de
	ret

; ix = this
; iy <- rasterizer
Application_GetRasterizer_IY:
	ld e,ixl
	ld d,ixh
	ld iy,Application.rasterizer
	add iy,de
	ret

; ix = this
; ix <- image
Application_GetImage:
	ld e,(ix + Application.image)
	ld d,(ix + Application.image + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
; ix <- image
Application_GetAltImage:
	ld e,(ix + Application.altImage)
	ld d,(ix + Application.altImage + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
Application_EnterMainLoop:
	call VDP_EnableBlank
	ld a,0
	ld (CLIKSW),a  ; disable key click
	ld a,0
	ld (BAKCLR),a
	ld a,SCREENMODE
	call VDP_InitScreen
	call VDP_DisableSprites
	call VDP_Enable60Hz
	ld a,0
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
	ld e,l
	ld d,0
	add hl,hl
	add hl,hl
	add hl,de
	call Math_Sine
	ld ix,Application_rotation
	ld (ix + Matrix4x4.row2 + Vector4.w),e
	ld (ix + Matrix4x4.row2 + Vector4.w + 1),d
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

	call Application_Draw

	ld l,(ix + Application.frame)
	ld h,(ix + Application.frame + 1)
	inc hl
	ld (ix + Application.frame),l
	ld (ix + Application.frame + 1),h

	jp Application_MainLoop
	ret

; ix = this
Application_Draw:
	push ix
	call Application_GetImage
	push ix
	call RunLengthImage_Clear
	pop de
	pop ix

	push ix
	push de
	call Application_GetRasterizer
	pop de
	call Rasterizer_SetImage
	call Rasterizer_Clear
	pop ix

	push ix
	call Application_GetRasterizer_IY
	ld ix,Application_points
	ld bc,Application_points_COUNT
;	call Point_PrepareArray
	pop ix

	push ix
	call Application_GetRasterizer_IY
	ld ix,Application_edges
	ld bc,Application_edges_COUNT
;	call Edge_PrepareArray
	pop ix

	push ix
	call Application_GetRasterizer_IY
	ld ix,Application_faces
	ld bc,Application_faces_COUNT
	call Face_PrepareArray
	pop ix

	push ix
	call Application_GetRasterizer
	call Rasterizer_StartRender
	pop ix

	push ix
	push ix
	call Application_GetAltImage
	ex (sp),ix
	pop iy
	call Application_GetImage
	call RunLengthImage_DrawDelta
	pop ix

	call Application_SwapImages
	ret

; ix = this
; ix <- image
Application_SwapImages:
	ld e,(ix + Application.image)
	ld d,(ix + Application.image + 1)
	ld l,(ix + Application.altImage)
	ld h,(ix + Application.altImage + 1)
	ld (ix + Application.image),l
	ld (ix + Application.image + 1),h
	ld (ix + Application.altImage),e
	ld (ix + Application.altImage + 1),d
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
	Point 0, Material_lightRed
	Point 1, Material_lightRed
	Point 2, Material_lightRed
	Point 3, Material_lightRed
	Point 4, Material_lightYellow
	Point 5, Material_lightYellow
	Point 6, Material_lightYellow
	Point 7, Material_lightYellow

Application_points_COUNT: equ 8

Application_edges:
	Edge 0, 1, Material_blue
	Edge 1, 2, Material_blue
	Edge 2, 3, Material_blue
	Edge 3, 0, Material_blue
	Edge 0, 2, Material_blue
	Edge 0, 4, Material_red
	Edge 1, 5, Material_red
	Edge 2, 6, Material_red
	Edge 3, 7, Material_red
	Edge 0, 5, Material_red
	Edge 1, 6, Material_red
	Edge 2, 7, Material_red
	Edge 3, 4, Material_red
	Edge 4, 5, Material_green
	Edge 5, 6, Material_green
	Edge 6, 7, Material_green
	Edge 7, 4, Material_green
	Edge 5, 7, Material_green

Application_edges_COUNT: equ 18

Application_faces:
	Face 0, 4, 7, Material_red
	Face 0, 7, 3, Material_red
	Face 0, 1, 5, Material_red
	Face 0, 5, 4, Material_red
	Face 6, 5, 1, Material_red
	Face 6, 1, 2, Material_red
	Face 6, 2, 3, Material_red
	Face 6, 3, 7, Material_red
	Face 0, 1, 2, Material_blue
	Face 0, 2, 3, Material_blue
	Face 6, 5, 4, Material_green
	Face 6, 4, 7, Material_green

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
	             0H,    0H,  100H,  300H,
	             0H,    0H,    0H,  100H

Application_projection:
	PerspectiveMatrix4x4 100H, 100H, 100H, 500H

Application_mvp:
	IdentityMatrix4x4

Application_verticesBuffer:
	ds Application_vertices_COUNT * Vector4._size

	ENDS
