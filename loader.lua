local script = "ScriptName.lua"

dofile(table.concat({
	os.getenv("APPDATA"),
	"\\XIVLauncher\\pluginConfigs\\Peon\\init.lua"
}))(script)