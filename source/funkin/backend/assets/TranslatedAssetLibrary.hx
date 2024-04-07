package funkin.backend.assets;

import openfl.utils.AssetLibrary;
import lime.utils.Bytes;

class TranslatedAssetLibrary extends AssetLibrary {
	public var langFolder:String;
	public var langPath:String;

	public function new(langFolder:String) {
		this.langFolder = langFolder;
		this.langPath = '${Paths.translFolderName}/$langFolder';
		super();
	}

	function toString():String
		return '(TranslatedAssetLibrary: The labguage folder is $langFolder)';

	public override function getBytes(id:String):Bytes {
		for(lib in ModsFolder.getLoadedModsLibs()) {
			if(!(lib is AssetLibrary)) continue;

			var mainPath = lib.prefix;
			if(!mainPath.endsWith('/')) mainPath += '/';
			var val = cast(lib, AssetLibrary).getBytes('$mainPath$langPath/$id');
			if(val != null) return val;
		}
		return null;
	}

	// I'll brb later and continue  - Nex
}