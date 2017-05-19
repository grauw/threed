;
; ThreeD
;

	INCLUDE "Macros.asm"

DEBUG: equ 1
R800: equ 1

	org 100H

RAM_PAGE0: ds 3F00H
RAM_PAGE1: ds 4000H

TPA_PAGE0: equ RAM_PAGE0
TPA_PAGE1: equ RAM_PAGE1
RAM_RESIDENT: equ RAM_PAGE0
RAM: equ RAM_PAGE1

	SECTION TPA_PAGE0

;
; Program entry point
;
COM_Main:
	jp Application_Main

	INCLUDE "Application.asm"
	INCLUDE "BIOS.asm"
	INCLUDE "System.asm"
	INCLUDE "Memory.asm"
	INCLUDE "MemoryTest.asm"
	INCLUDE "VDP.asm"
	INCLUDE "VDPCommand.asm"
	INCLUDE "Math.asm"
	INCLUDE "Vector2.asm"
	INCLUDE "Vector3.asm"
	INCLUDE "Vector4.asm"
	INCLUDE "Matrix4x4.asm"
	INCLUDE "Point.asm"
	INCLUDE "PointRenderer.asm"
	INCLUDE "Edge.asm"
	INCLUDE "EdgeRenderer.asm"
	INCLUDE "Face.asm"
	INCLUDE "FaceRenderer.asm"

	ENDS
