G.DeclareManifest({
name:'Example mod manifest',
updates:{
	'Example mod*':'mod.js',//we're updating any mod with a name that begins with "Example mod"
	//you could declare other mod updates here if you wanted
}
});