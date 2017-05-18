all:
	mkdir -p gen bin
	node tools/gensinetable.js > gen/sinetable.asm
	java -jar tools/glass.jar -I gen -I lib/neonlib/src src/COM.asm bin/threed.com bin/threed.sym

run: all
	openmsx -machine Panasonic_FS-A1GT -ext ide -script openmsx.tcl
