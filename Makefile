all:
	mkdir -p gen bin
	node tools/gensinetable.js > gen/sinetable.asm
	java -jar tools/glass.jar -I gen -I lib/neonlib/src src/ROM.asm bin/threed.rom bin/threed.sym

run: all
	openmsx -cart bin/threed.rom -romtype KonamiSCC -machine Panasonic_FS-A1GT -script openmsx.tcl
