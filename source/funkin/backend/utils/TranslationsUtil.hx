package funkin.backend.utils;

import openfl.utils.Assets;
import haxe.io.Path;
import haxe.xml.Access;
import haxe.Exception;

/**
 * The class used for translations based on the XMLs inside the translations folders.
 *
 * Made by @NexIsDumb originally for the Poldhub mod.
 */
class TranslationsUtil
{
	/**
	 * The current language selected translation map; If the current language it's english, this map will be empty.
	 *
	 * Using this class function it'll never be `null`.
	 */
	public static var transMap(default, null):Map<String, String> = [];

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
	inline public static function is_defaultLanguage():Bool
		return Options.language == DEFAULT_LANGUAGE;

	/**
	 * Returns if any translation is loaded.
	 */
	inline public static function is_anyTransLoaded():Bool
		return transMap != [];

	/**
	 * Changes the translations map.
	 *
	 * If `name` is `null`, it's gonna use the current language.
	 */
	public static function setTransl(?name:String)
		transMap = loadLanguage(name == null ? curLanguage : name);

	/**
	 * This is for checking a translation, `defString` it's just the string that gets returned just in case it won't find the translation OR the current language selected is ``DEFAULT_LANGUAGE``.
	 *
	 * If `id` is `null` then it's gonna search using `defString`.
	 */
	public static function checkTransl(defString:String, ?id:String):String
	{
		#if TRANSLATIONS_SUPPORT
		if(id == null) id = defString;
		if(transMap.exists(id)) return transMap.get(id);
		#end
		return defString;
	}

	/**
	 * Returns an array that specifies which translations were found.
	 */
	public static function translList():Array<String>
	{
		var translations:Array<String> = [];
		#if TRANSLATIONS_SUPPORT
		var main:String = Paths.translationsMain('');
		for(l in Paths.assetsTree.getFolders(main)) for(f in Paths.assetsTree.getFiles(main + l))
			if(Path.extension('$l/$f') == "xml") translations.push(Path.withoutExtension('$l/$f'));
		#end
		return translations;
	}

	/**
	 * Returns a map of translations based on its XML.
	 */
	public static function loadLanguage(name:String):Map<String, String>
	{
		#if TRANSLATIONS_SUPPORT
		var path:String = Paths.translationsMain(name);
		if(!path.endsWith(".xml")) path += ".xml";
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

		var leMap:Map<String, String> = [];
		for(node in xml.node.translations.elements) {
			switch(node.name) {
				case "trans":
					if (!node.has.id) {
						FlxG.log.warn("A translation node requires an ID attribute.");
						continue;
					}
					if (!node.has.string) {
						FlxG.log.warn("A translation node requires a string attribute.");
						continue;
					}
					leMap.set(node.att.id, node.att.string);
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
class FormatInfo {
	public var strings:Array<String> = [];
	public var indexes:Array<Int> = [];

	public function new(str:String) {
		var i = 0;

		while(i < str.length) {
			var fi = str.indexOf("{", i); // search from the start of i

			if(fi == -1) {
				strings.push(str.substring(i));
				break;
			}

			var fe = str.indexOf("}", fi);

			strings.push(str.substring(i, fi));
			indexes.push(Std.parseInt(str.substring(fi+1, fe)));
			i = fe + 1;
		}
	}

	public function format(values:Array<Dynamic>):String {
		var str:String = "";
		for(i=>s in strings) {
			str += s;
			if(i < strings.length-1)
				str += values[indexes[i]];
		}

		return str;
	}
}