package funkin.backend.assets;

import openfl.utils.AssetLibrary;
import lime.media.AudioBuffer;
import lime.graphics.Image;
import lime.text.Font;
import lime.utils.Bytes;

class TranslatedAssetLibrary extends AssetLibrary implements IModsAssetLibrary {
	public var libName:String;
	public var modName:String;
	public var basePath:String;
	public var prefix:String = Paths.translFolderName + "/";

	public function new(langFolder:String) {
		this.libName = this.modName = langFolder;
		this.basePath = prefix + libName + "/";
		super();
	}

	function toString():String
		return '(TranslatedAssetLibrary: The labguage folder is $libName)';

	public override function getAudioBuffer(id:String):AudioBuffer
	{
		for(lib in ModsFolder.getLoadedModsLibs()) {
			if(!(lib is AssetLibrary)) continue;

			var mainPath = lib.prefix;
			if(!mainPath.endsWith('/')) mainPath += '/';
			var val = cast(lib, AssetLibrary).getAudioBuffer(mainPath + getAssetPath() + id);
			if(val != null) return val;
		}
		return null;
	}

	public override function getBytes(id:String):Bytes
	{
		for(lib in ModsFolder.getLoadedModsLibs()) {
			if(!(lib is AssetLibrary)) continue;

			var mainPath = lib.prefix;
			if(!mainPath.endsWith('/')) mainPath += '/';
			var val = cast(lib, AssetLibrary).getBytes(mainPath + getAssetPath() + id);
			if(val != null) return val;
		}
		return null;
	}

	public override function getFont(id:String):Font
	{
		for(lib in ModsFolder.getLoadedModsLibs()) {
			if(!(lib is AssetLibrary)) continue;

			var mainPath = lib.prefix;
			if(!mainPath.endsWith('/')) mainPath += '/';
			var val = cast(lib, AssetLibrary).getFont(mainPath + getAssetPath() + id);
			if(val != null) return val;
		}
		return null;
	}

	public override function getImage(id:String):Image
	{
		for(lib in ModsFolder.getLoadedModsLibs()) {
			if(!(lib is AssetLibrary)) continue;

			var mainPath = lib.prefix;
			if(!mainPath.endsWith('/')) mainPath += '/';
			var val = cast(lib, AssetLibrary).getImage(mainPath + getAssetPath() + id);
			if(val != null) return val;
		}
		return null;
	}

	public override function getPath(id:String):String
	{
		for(lib in ModsFolder.getLoadedModsLibs()) {
			if(!(lib is AssetLibrary)) continue;

			var mainPath = lib.prefix;
			if(!mainPath.endsWith('/')) mainPath += '/';
			var val = cast(lib, AssetLibrary).getPath(mainPath + getAssetPath() + id);
			if(val != null) return val;
		}
		return null;
	}

	#if MOD_SUPPORT
	public var _parsedAsset:String = null;  // Theres no need to actually make this work  - Nex

	public function getFiles(folder:String):Array<String>
	{
		for(lib in ModsFolder.getLoadedModsLibs()) {
			var mainPath = lib.prefix;
			if(!mainPath.endsWith('/')) mainPath += '/';
			var val = lib.getFiles(mainPath + getAssetPath() + folder);
			if(val != []) return val;
		}
		return [];
	}

	public function getFolders(folder:String):Array<String>
	{
		for(lib in ModsFolder.getLoadedModsLibs()) {
			var mainPath = lib.prefix;
			if(!mainPath.endsWith('/')) mainPath += '/';
			var val = lib.getFolders(mainPath + getAssetPath() + folder);
			if(val != []) return val;
		}
		return [];
	}

	private inline function getAssetPath():String
		return basePath;

	private function __isCacheValid(cache:Map<String, Dynamic>, asset:String, isLocal:Bool = false):Bool
	{
		for(lib in ModsFolder.getLoadedModsLibs()) {
			if(!(lib is AssetLibrary)) continue;

			// are you fucking serious (no the fucking switch doesnt work here)  - Nex
			var _lib = cast(lib, AssetLibrary);
			var libCache = (cache == cachedAudioBuffers) ? _lib.cachedAudioBuffers :
				(cache == cachedBytes) ? _lib.cachedBytes :
				(cache == cachedFonts) ? _lib.cachedFonts :
				(cache == cachedImages) ? _lib.cachedImages :
				(cache == cachedText) ? _lib.cachedText : cache;

			var mainPath = lib.prefix;
			if(!mainPath.endsWith('/')) mainPath += '/';
			@:privateAccess if(lib.__isCacheValid(libCache, mainPath + getAssetPath() + asset, isLocal)) return true;
		}
		return false;
	}

	private function __parseAsset(asset:String):Bool
	{
		for(lib in ModsFolder.getLoadedModsLibs()) {
			var mainPath = lib.prefix;
			if(!mainPath.endsWith('/')) mainPath += '/';
			@:privateAccess if(lib.__parseAsset(mainPath + getAssetPath() + asset)) return true;
		}
		return false;
	}
	#end

	public override function exists(id:String, type:String):Bool
	{
		for(lib in ModsFolder.getLoadedModsLibs()) {
			if(!(lib is AssetLibrary)) continue;

			var mainPath = lib.prefix;
			if(!mainPath.endsWith('/')) mainPath += '/';
			if(cast(lib, AssetLibrary).exists(mainPath + getAssetPath() + id, type)) return true;
		}
		return false;
	}
}