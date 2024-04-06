package openfl.utils;

import openfl.display.MovieClip;
#if lime
import lime.graphics.Image;
import lime.media.AudioBuffer;
import lime.text.Font;
import lime.utils.AssetLibrary as LimeAssetLibrary;
import lime.utils.AssetType;
import lime.utils.AssetManifest;
import lime.utils.Bytes;
#end

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class AssetLibrary #if lime extends LimeAssetLibrary #end
{
	#if lime
	@:noCompletion private var __proxy:LimeAssetLibrary;

	// Had to edit this file for mainly this, its similar to proxy but doesnt cover everything  - Nex
	public var subLibraries:Array<LimeAssetLibrary> = [];

	@:noCompletion private function set_subLibraries(value:Array<LimeAssetLibrary>):Array<LimeAssetLibrary> {
		if (value == null) value = [];
		return subLibraries = value;
	}
	#end

	public function new()
	{
		#if lime
		super();
		#end
	}

	public function bind(className:String, instance:Dynamic = null):Bool
	{
		return false;
	}

	#if lime
	public override function exists(id:String, type:String):Bool
	{
		if (__proxy != null)
		{
			return __proxy.exists(id, type);
		}
		else
		{
			for(lib in subLibraries) if(lib != null && lib.exists(id, type)) return true;
			return super.exists(id, type);
		}
	}
	#end

	public static function fromBundle(bundle:AssetBundle):AssetLibrary
	{
		#if lime
		var library = LimeAssetLibrary.fromBundle(bundle);

		if (library != null)
		{
			if ((library is AssetLibrary))
			{
				return cast library;
			}
			else
			{
				var _library = new AssetLibrary();
				_library.__proxy = library;
				return _library;
			}
		}
		else
		{
			return null;
		}
		#else
		return null;
		#end
	}

	public static function fromBytes(bytes:ByteArray, rootPath:String = null):AssetLibrary
	{
		#if lime
		return cast fromManifest(AssetManifest.fromBytes(bytes, rootPath));
		#else
		return null;
		#end
	}

	public static function fromFile(path:String, rootPath:String = null):AssetLibrary
	{
		#if lime
		return cast fromManifest(AssetManifest.fromFile(path, rootPath));
		#else
		return null;
		#end
	}

	public static function fromManifest(manifest:AssetManifest):#if (java && lime) LimeAssetLibrary #else AssetLibrary #end
	{
		#if lime
		var library = LimeAssetLibrary.fromManifest(manifest);

		if (library != null)
		{
			if ((library is AssetLibrary))
			{
				return cast library;
			}
			else
			{
				var _library = new AssetLibrary();
				_library.__proxy = library;
				return _library;
			}
		}
		else
		{
			return null;
		}
		#else
		return null;
		#end
	}

	#if lime
	public override function getAsset(id:String, type:String):Dynamic
	{
		if (__proxy != null)
		{
			return __proxy.getAsset(id, type);
		}
		else
		{
			var val:Dynamic = null;
			for(lib in subLibraries) if(lib != null && (val = lib.getAsset(id, type)) != null) return val;
			return super.getAsset(id, type);
		}
	}
	#end

	#if lime
	public override function getAudioBuffer(id:String):AudioBuffer
	{
		if (__proxy != null)
		{
			return __proxy.getAudioBuffer(id);
		}
		else
		{
			var val:Dynamic = null;
			for(lib in subLibraries) if(lib != null && (val = lib.getAudioBuffer(id)) != null) return val;
			return super.getAudioBuffer(id);
		}
	}
	#end

	#if lime
	public override function getBytes(id:String):Bytes
	{
		if (__proxy != null)
		{
			return __proxy.getBytes(id);
		}
		else
		{
			var val:Dynamic = null;
			for(lib in subLibraries) if(lib != null && (val = lib.getBytes(id)) != null) return val;
			return super.getBytes(id);
		}
	}
	#end

	#if lime
	public override function getFont(id:String):Font
	{
		if (__proxy != null)
		{
			return __proxy.getFont(id);
		}
		else
		{
			var val:Dynamic = null;
			for(lib in subLibraries) if(lib != null && (val = lib.getFont(id)) != null) return val;
			return super.getFont(id);
		}
	}
	#end

	#if lime
	public override function getImage(id:String):Image
	{
		if (__proxy != null)
		{
			return __proxy.getImage(id);
		}
		else
		{
			var val:Dynamic = null;
			for(lib in subLibraries) if(lib != null && (val = lib.getImage(id)) != null) return val;
			return super.getImage(id);
		}
	}
	#end

	public function getMovieClip(id:String):MovieClip
	{
		return null;
	}

	#if lime
	public override function getPath(id:String):String
	{
		if (__proxy != null)
		{
			return __proxy.getPath(id);
		}
		else
		{
			var val:Dynamic = null;
			for(lib in subLibraries) if(lib != null && (val = lib.getPath(id)) != null) return val;
			return super.getPath(id);
		}
	}
	#end

	#if lime
	public override function getText(id:String):String
	{
		if (__proxy != null)
		{
			return __proxy.getText(id);
		}
		else
		{
			var val:Dynamic = null;
			for(lib in subLibraries) if(lib != null && (val = lib.getText(id)) != null) return val;
			return super.getText(id);
		}
	}
	#end

	#if lime
	public override function isLocal(id:String, type:String):Bool
	{
		if (__proxy != null)
		{
			return __proxy.isLocal(id, type);
		}
		else
		{
			for(lib in subLibraries) if(lib != null && lib.isLocal(id, type)) return true;
			return super.isLocal(id, type);
		}
	}
	#end

	#if lime
	public override function list(type:String):Array<String>
	{
		if (__proxy != null)
		{
			return __proxy.list(type);
		}
		else
		{
			var finalArr:Array<String> = [];
			for(lib in subLibraries.concat([this])) if(lib != null) for(f in lib.list(type)) if(!finalArr.contains(f)) finalArr.push(f);
			return finalArr;
		}
	}
	#end

	#if lime
	public override function loadAsset(id:String, type:String):Future<Dynamic>
	{
		if (__proxy != null)
		{
			return __proxy.loadAsset(id, type);
		}
		else
		{
			for(lib in subLibraries) if(lib != null && lib.checkSpecificAsset(id, type)) return lib.loadAsset(id, type);
			return super.loadAsset(id, type);
		}
	}
	#end

	#if lime
	public override function load():Future<LimeAssetLibrary>
	{
		if (__proxy != null)
		{
			return __proxy.load();
		}
		else
		{
			// TODO: Make this work by using multiple Futures
			for(lib in subLibraries) if(lib != null) return lib.load();
			return super.load();
		}
	}
	#end

	#if lime
	public override function loadAudioBuffer(id:String):Future<AudioBuffer>
	{
		if (__proxy != null)
		{
			return __proxy.loadAudioBuffer(id);
		}
		else
		{
			for(lib in subLibraries) if(lib != null && lib.checkSpecificAsset(id, MUSIC)) return lib.loadAudioBuffer(id);
			return super.loadAudioBuffer(id);
		}
	}
	#end

	#if lime
	public override function loadBytes(id:String):Future<Bytes>
	{
		if (__proxy != null)
		{
			return __proxy.loadBytes(id);
		}
		else
		{
			for(lib in subLibraries) if(lib != null && lib.checkSpecificAsset(id, BINARY)) return lib.loadBytes(id);
			return super.loadBytes(id);
		}
	}
	#end

	#if lime
	public override function loadFont(id:String):Future<Font>
	{
		if (__proxy != null)
		{
			return __proxy.loadFont(id);
		}
		else
		{
			for(lib in subLibraries) if(lib != null && lib.checkSpecificAsset(id, FONT)) return lib.loadFont(id);
			return super.loadFont(id);
		}
	}
	#end

	public static function loadFromBytes(bytes:ByteArray, rootPath:String = null):#if (java && lime) Future<LimeAssetLibrary> #else Future<AssetLibrary> #end
	{
		#if lime
		return AssetManifest.loadFromBytes(bytes, rootPath).then(function(manifest)
		{
			return loadFromManifest(manifest);
		});
		#else
		return cast Future.withValue(null);
		#end
	}

	public static function loadFromFile(path:String, rootPath:String = null):#if (java && lime) Future<LimeAssetLibrary> #else Future<AssetLibrary> #end
	{
		#if lime
		return AssetManifest.loadFromFile(path, rootPath).then(function(manifest)
		{
			return loadFromManifest(manifest);
		});
		#else
		return cast Future.withValue(null);
		#end
	}

	public static function loadFromManifest(manifest:AssetManifest):#if (java && lime) Future<LimeAssetLibrary> #else Future<AssetLibrary> #end
	{
		#if lime
		var library:AssetLibrary = cast fromManifest(manifest);

		if (library != null)
		{
			return library.load().then(function(library)
			{
				return Future.withValue(cast library);
			});
		}
		else
		{
			return cast Future.withError("Could not load asset manifest");
		}
		#else
		return cast Future.withValue(null);
		#end
	}

	#if lime
	public override function loadImage(id:String):Future<Image>
	{
		if (__proxy != null)
		{
			return __proxy.loadImage(id);
		}
		else
		{
			for(lib in subLibraries) if(lib != null && lib.checkSpecificAsset(id, IMAGE)) return lib.loadImage(id);
			return super.loadImage(id);
		}
	}
	#end

	public function loadMovieClip(id:String):Future<MovieClip>
	{
		return Future.withValue(getMovieClip(id));
	}

	#if lime
	public override function loadText(id:String):Future<String>
	{
		if (__proxy != null)
		{
			return __proxy.loadText(id);
		}
		else
		{
			for(lib in subLibraries) if(lib != null && lib.checkSpecificAsset(id, TEXT)) return lib.loadText(id);
			return super.loadText(id);
		}
	}
	#end

	#if lime
	public override function unload():Void
	{
		if (__proxy != null)
		{
			return __proxy.unload();
		}
		else
		{
			for(lib in subLibraries) if(lib != null) lib.unload();
			return super.unload();
		}
	}
	#end
}
