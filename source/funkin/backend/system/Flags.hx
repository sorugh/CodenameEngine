package funkin.backend.system;

import lime.utils.AssetLibrary;
import lime.utils.AssetType;

import funkin.backend.assets.IModsAssetLibrary;
import funkin.backend.assets.ScriptedAssetLibrary;

@:build(funkin.backend.system.macros.FlagMacro.build())
class Flags {
	public static var FPS_BUILD_TEXT:String = "Commit ${build} (${commit})";

	@:bypass public static var customFlags:Map<String, String> = [];

	public static function load() {
		var flags:Map<String, String> = [];

		final flagsPath = Paths.getPath("flags.ini");

		for(lib in Paths.assetsTree.libraries) {
			if(lib.exists(flagsPath, AssetType.TEXT)) {
				var data:String = lib.getAsset(flagsPath, AssetType.TEXT);
				var trimmed:String;
				var splitContent = [for(e in data.split("\n")) if ((trimmed = e.trim()) != "") trimmed];

				for(line in splitContent) {
					if (line.startsWith(";")) continue;
					if (line.startsWith("#")) continue;
					if (line.startsWith("//")) continue;
					if(line.length == 0) continue;
					if(line.charAt(0) == "[" && line.charAt(line.length-1) == "]") continue;

					var index = line.indexOf("=");
					if(index == -1) continue;
					var name = line.substr(0, index).trim();
					var value = line.substr(index+1).trim();

					if (value.length > 1 && value.charCodeAt(0) == '"'.code && value.charCodeAt(value.length-1) == '"'.code)
						value = value.substr(1, value.length - 2);

					if (value.length == 0 || name.length == 0)
						continue;

					if(!flags.exists(name))
						flags[name] = value;
				}
			}
		}

		customFlags = [];
		reset();
		for(name=>value in flags)
			if(!parse(name, value)) {
				customFlags.set(name, value);
			}
	}

	public static function getCleanLibraryName(e:AssetLibrary) {
		var l = e;
		if (l is openfl.utils.AssetLibrary) {
			var al = cast(l, openfl.utils.AssetLibrary);
			@:privateAccess
			if (al.__proxy != null) l = al.__proxy;
		}

		if (l is ScriptedAssetLibrary)
			return '${cast(l, ScriptedAssetLibrary).scriptName} (${cast(l, ScriptedAssetLibrary).modName})';
		else if (l is IModsAssetLibrary)
			return '${cast(l, IModsAssetLibrary).modName}';
		else
			return Std.string(e);
	}
}