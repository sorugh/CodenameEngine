package funkin.backend.utils;

import funkin.backend.assets.TranslatedAssetLibrary;
import funkin.backend.assets.ModsFolderLibrary;
import funkin.backend.assets.ModsFolder;
import funkin.backend.assets.IModsAssetLibrary;
import funkin.backend.assets.ZipFolderLibrary;
import openfl.utils.Assets;
import haxe.io.Path;
import haxe.xml.Access;
import haxe.Exception;

/**
 * The class used for translations based on the XMLs inside the translations folders.
 *
 * Made by @NexIsDumb originally for the Poldhub mod.
 */
class TranslationUtil
{
	/**
	 * The current language selected translation map; If the current language it's english, this map will be empty.
	 *
	 * It'll never be `null`.
	 */
	public static var transMap(default, set):Map<String, IFormatInfo> = [];

	@:noCompletion private static function set_transMap(value:Map<String, IFormatInfo>):Map<String, IFormatInfo> {
		if (value == null) value = [];
		return transMap = value;
	}

	/**
	 * The default language used inside of the source code.
	 */
	public static var DEFAULT_LANGUAGE:String = 'en/English';  // no inline so psycopathic mods can edit it  - Nex

	/**
	 * Returns the current language.
	 */
	public static var curLanguage(get, set):String;
	@:noCompletion private static function get_curLanguage():String {
		return Options.language;
	}
	@:noCompletion private static function set_curLanguage(value:String):String {
		return Options.language = value;
	}

	/**
	 * Returns if the current language is the default one (`DEFAULT_LANGUAGE`).
	 */
	public static var isDefaultLanguage(get, never):Bool;
	@:noCompletion private static function get_isDefaultLanguage():Bool
		return Options.language == DEFAULT_LANGUAGE;

	/**
	 * Returns if any translation are loaded.
	 */
	public static var isAnyTransLoaded(get, never):Bool;
	@:noCompletion private static function get_isAnyTransLoaded():Bool
		return Lambda.count(transMap) > 0;

	/**
	 * Updates the language.
	 * Also changes the translations map.
	 *
	 * If `name` is `null`, its gonna use the current language.
	 * If `name` is not `null`, it will load the translations for the given language.
	 */
	public static function setLanguage(?name:String) {
		if(name == null) name = curLanguage;
		transMap = loadLanguage(name);

		for(mod in ModsFolder.getLoadedModsLibs()) if(mod is TranslatedAssetLibrary)
			cast(mod, TranslatedAssetLibrary).langFolder = name.split("/")[0];
	}

	/**
	 * This is for checking and getting a translation, `defString` it's just the string that gets returned just in case it won't find the translation OR the current language selected is ``DEFAULT_LANGUAGE``.
	 *
	 * If `id` is `null` then it's gonna search using `defString`.
	 */
	public static function get(defString:String, ?id:String, ?params:Array<Dynamic>):String
	{
		#if TRANSLATIONS_SUPPORT
		if (id == null) id = defString;
		if (transMap.exists(id)) return transMap.get(id).format(params);
		#end
		return FormatUtil.get(defString).format(params);
	}

	/**
	 * Returns an array that specifies which languages were found.
	 */
	public static function getLanguages():Array<String>
	{
		var languages:Array<String> = [];
		#if TRANSLATIONS_SUPPORT
		var main:String = Paths.translationsMain('');
		for (l in Paths.assetsTree.getFolders(main))
			for (f in Paths.assetsTree.getFiles(main + l))
				if (Path.extension('$l/$f') == "xml")
					languages.push(Path.withoutExtension('$l/$f'));
		#end
		return languages;
	}

	/**
	 * Returns a map of translations based on its XML.
	 */
	public static function loadLanguage(name:String):Map<String, IFormatInfo>
	{
		#if TRANSLATIONS_SUPPORT
		var path:String = Paths.translationsMain(name);
		if (!path.endsWith(".xml")) path += ".xml";
		if (!Assets.exists(path, TEXT)) return [];

		var xml:Access = null;
		try xml = new Access(Xml.parse(Assets.getText(path)))
		catch(e) {
			var msg:String = 'Error while parsing ${Path.withoutDirectory(name)}.xml: ${Std.string(e)}';
			FlxG.log.error(msg);
			throw new Exception(msg);
		}
		if (xml == null) return [];
		if (!xml.hasNode.translations) {
			FlxG.log.warn("A translation xml file requires a translations root element.");
			return [];
		}

		FormatUtil.clear(); // Clean up the format cache
		var leMap:Map<String, IFormatInfo> = [];
		for(node in xml.node.translations.elements) {
			switch(node.name) {
				case "trans":
					if (!node.has.id) {
						FlxG.log.warn("A translation node requires an ID attribute.");
						continue;
					}

					var string:String = node.has.string ? node.att.string : node.x.nodeValue;
					string = string.replace("\\n", "\n").replace("\r", ""); // remove stupid windows line breaks and convert newline literals to newlines
					leMap.set(node.att.id, FormatUtil.get(string));
			}
		}
		return leMap;
		#else
		return [];
		#end
	}
}

/*
input:Hello {1}, how are you, {0}

strings: ["Hello ", ", how are you, ", ""]
indexes: [1, 0]

strings[0] + values[indexes[0]] + strings[1] + values[indexes[1]] + strings[2]

*/
class FormatUtil {
	private static var cache:Map<String, IFormatInfo> = new Map();

	public static function get(id:String):IFormatInfo {
		if (cache.exists(id))
			return cache.get(id);

		var fi:IFormatInfo = ParamFormatInfo.returnOnlyIfValid(id);
		if(fi == null) fi = new StrFormatInfo(id);
		cache.set(id, fi);
		return fi;
	}

	public inline static function clear() {
		cache.clear();
	}
}

class StrFormatInfo implements IFormatInfo {
	public var string:String;

	public function new(str:String) {
		this.string = str;
	}

	public function format(params:Array<Dynamic>):String {
		return string;
	}
}

// TODO: add support for @:({0}==1?(Hello):(World))
class ParamFormatInfo implements IFormatInfo {
	public var strings:Array<String> = [];
	public var indexes:Array<Int> = [];

	public function new(str:String) {
		var i = 0;

		while (i < str.length) {
			var fi = str.indexOf("{", i); // search from the start of i

			if (fi == -1) {
				// if there are no more parameters, just add the rest of the string
				this.strings.push(str.substring(i));
				break;
			}

			var fe = str.indexOf("}", fi);

			this.strings.push(str.substring(i, fi));
			this.indexes.push(Std.parseInt(str.substring(fi+1, fe)));
			i = fe + 1;
		}
	}

	public static function isValid(str:String):Bool {
		var fi = new ParamFormatInfo(str);
		return fi.indexes.length > 0;
	}
	public static function returnOnlyIfValid(str:String):IFormatInfo {
		var fi = new ParamFormatInfo(str);
		return fi.indexes.length > 0 ? fi : null;
	}

	public function format(params:Array<Dynamic>):String {
		if (params == null) params = [];

		var str:String = "";
		for (i=>s in strings) {
			str += s;
			if (i < indexes.length)
				str += params[indexes[i]];
		}

		return str;
	}
}

interface IFormatInfo {
	public function format(params:Array<Dynamic>):String;
}