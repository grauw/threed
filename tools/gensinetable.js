for (var degree = 0; degree < 256; degree++) {
	var sin = (Math.round(Math.sin(degree * Math.PI / 256) * 256) + 65536) % 65536;
	console.log("\tdb " + (sin % 256));
}
for (var degree = 0; degree < 256; degree++) {
	var sin = (Math.round(Math.sin(degree * Math.PI / 256) * 256) + 65536) % 65536;
	console.log("\tdb " + Math.floor(sin / 256));
}
