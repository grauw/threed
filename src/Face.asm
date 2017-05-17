;
;
;
Face: MACRO ?one, ?two, ?three, ?color
	one:
		dw ?one * Vector4._size
	two:
		dw ?two * Vector4._size
	three:
		dw ?three * Vector4._size
	color:
		db ?color
	_size:
	ENDM
