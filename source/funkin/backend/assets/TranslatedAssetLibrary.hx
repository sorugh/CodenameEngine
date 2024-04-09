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

	public var langFolder(get, set):String;
	@:noCompletion private inline function get_langFolder():String {
		return libName;
	}
	@:noCompletion private inline function set_langFolder(value:String):String {
		basePath = prefix + (libName = modName = (value != null ? value : TranslationUtil.DEFAULT_LANGUAGE.split("/")[0])) + "/";
		return libName;
	}

	public function new(?langFolder:String) {
		super();
		this.langFolder = langFolder;
	}

	function toString():String
		return '(TranslatedAssetLibrary: The language folder is $libName)';

	private inline function getAssetPath():String  // because of the IModsAssetLibrary  - Nex
		return basePath;

	public inline function formatPath(mainPath:String, ?asset:String):String {
		if(!mainPath.endsWith('/')) mainPath += '/';
		return mainPath + getAssetPath() + (asset == null ? "" : asset);
	}

	public override function getAudioBuffer(id:String):AudioBuffer
	{
		for(lib in ModsFolder.getLoadedModsLibs(true)) {
			if(!(lib is AssetLibrary)) continue;
			var val = cast(lib, AssetLibrary).getAudioBuffer(formatPath(lib.prefix, id));
			if(val != null) return val;
		}
		return null;
	}

	public override function getBytes(id:String):Bytes
	{
		for(lib in ModsFolder.getLoadedModsLibs(true)) {
			if(!(lib is AssetLibrary)) continue;
			var val = cast(lib, AssetLibrary).getBytes(formatPath(lib.prefix, id));
			if(val != null) return val;
		}
		return null;
	}

	public override function getFont(id:String):Font
	{
		for(lib in ModsFolder.getLoadedModsLibs(true)) {
			if(!(lib is AssetLibrary)) continue;
			var val = cast(lib, AssetLibrary).getFont(formatPath(lib.prefix, id));
			if(val != null) return val;
		}
		return null;
	}

	public override function getImage(id:String):Image
	{
		for(lib in ModsFolder.getLoadedModsLibs(true)) {
			if(!(lib is AssetLibrary)) continue;
			var val = cast(lib, AssetLibrary).getImage(formatPath(lib.prefix, id));
			if(val != null) return val;
		}
		return null;
	}

	public override function getPath(id:String):String
	{
		for(lib in ModsFolder.getLoadedModsLibs(true)) {
			if(!(lib is AssetLibrary)) continue;
			var val = cast(lib, AssetLibrary).getPath(formatPath(lib.prefix, id));
			if(val != null) return val;
		}
		return null;
	}

	#if MOD_SUPPORT
	public var _parsedAsset:String = null;  // Theres no need to actually make this work  - Nex

	public function getFiles(folder:String):Array<String>
	{
		for(lib in ModsFolder.getLoadedModsLibs(true)) {
			if(!(lib is AssetLibrary)) continue;
			var val = lib.getFiles(formatPath(lib.prefix, folder));
			if(val != null && val.length > 0) return val;
		}
		return [];
	}

	public function getFolders(folder:String):Array<String>
	{
		for(lib in ModsFolder.getLoadedModsLibs(true)) {
			if(!(lib is AssetLibrary)) continue;
			var val = lib.getFolders(formatPath(lib.prefix, folder));
			if(val != null && val.length > 0) return val;
		}
		return [];
	}

	private function __isCacheValid(cache:Map<String, Dynamic>, asset:String, isLocal:Bool = false):Bool
	{
		for(lib in ModsFolder.getLoadedModsLibs(true)) {
			if(!(lib is AssetLibrary)) continue;

			// are you fucking serious (no the fucking switch doesnt work here)  - Nex
			var _lib = cast(lib, AssetLibrary);
			var libCache = (cache == cachedAudioBuffers) ? _lib.cachedAudioBuffers :
				(cache == cachedBytes) ? _lib.cachedBytes :
				(cache == cachedFonts) ? _lib.cachedFonts :
				(cache == cachedImages) ? _lib.cachedImages :
				(cache == cachedText) ? _lib.cachedText : cache;

			@:privateAccess if(lib.__isCacheValid(libCache, formatPath(lib.prefix, asset), isLocal)) return true;
		}
		return false;
	}

	private function __parseAsset(asset:String):Bool
	{
		@:privateAccess
		for(lib in ModsFolder.getLoadedModsLibs(true)) {
			if(!(lib is AssetLibrary)) continue;
			if(lib.__parseAsset(formatPath(lib.prefix, asset))) return true;
		}
		return false;
	}
	#end

	public override function exists(id:String, type:String):Bool
	{
		for(lib in ModsFolder.getLoadedModsLibs(true)) if(lib is AssetLibrary && cast(lib, AssetLibrary).exists(formatPath(lib.prefix, id), type)) return true;
		return false;
	}
}