package funkin.backend.utils;

import funkin.backend.utils.IniUtil;
import funkin.backend.assets.TranslatedAssetLibrary;
import funkin.backend.assets.ModsFolder;
import openfl.utils.Assets;
import haxe.io.Path;
import haxe.xml.Access;
import haxe.Exception;

/**
 * The class used for translations based on the XMLs inside the translations folders.
 *
 * Made by @NexIsDumb originally for the Poldhub mod.
 */
@:allow(funkin.backend.assets.TranslatedAssetLibrary)
class TranslationUtil
{
	/**
	 * The current language selected translation map; If the current language it's english, this map will be empty.
	 *
	 * It'll never be `null`.
	 */
	public static var stringMap(default, set):Map<String, IFormatInfo> = [];

	/**
	 * The default language used inside of the source code.
	 */
	public static var DEFAULT_LANGUAGE:String = 'en';  // no inline so psychopathic mods can edit it  - Nex

	/**
	 * Returns the current language config.
	 */
	public static var config:IniMap = [];
	/**
	 * Returns the current language.
	 */
	public static var curLanguage(get, set):String;
	/**
	 * Returns the current language name.
	 */
	public static var curLanguageName(get, set):String;

	/**
	 * Returns if the current language is the default one (`DEFAULT_LANGUAGE`).
	 */
	public static var isDefaultLanguage(get, never):Bool;

	/**
	 * Returns if any translation are loaded.
	 */
	public static var isLanguageLoaded(get, never):Bool;

	/**
	 * Returns an array has a list of the languages that were found.
	 */
	public static var foundLanguages:Array<String> = [];

	// Private
	private static inline var LANG_FOLDER:String = "languages";
	private static var langConfigs:Map<String, IniMap> = [];
	private static var nameMap:Map<String, String> = [];
	private static inline function getDefaultNameMap():Map<String, String> {
		return ['en' => 'English'];
	}
	private static inline function getDefaultConfig(name:String):IniMap {
		return ["name" => getLanguageName(name), "credits" => "", "version" => "1.0.0"];
	}

	/**
	 * Updates the language.
	 * Also changes the translations map.
	 *
	 * If `name` is `null`, its gonna use the current language.
	 * If `name` is not `null`, it will load the translations for the given language.
	 */
	public static function setLanguage(?name:String) {
		#if TRANSLATIONS_SUPPORT
		if(name == null) name = curLanguage;

		Logs.traceColored([
			Logs.getPrefix("Language"),
			Logs.logText("Setting Language To: "),
			Logs.logText('${getLanguageName(name)} ($name)', GREEN)
		], VERBOSE);

		for(mod in ModsFolder.getLoadedModsLibs(false))
			if(mod is TranslatedAssetLibrary)
				cast(mod, TranslatedAssetLibrary).langFolder = name;

		config = getConfig(name);
		stringMap = loadLanguage(name);
		#end
	}

	/**
	 * This is for checking and getting a translation, `defString` it's just the string that gets returned just in case it won't find the translation OR the current language selected is ``DEFAULT_LANGUAGE``.
	 *
	 * If `id` is `null` then it's gonna search using `defString`.
	 */
	public static inline function get(defString:String, ?id:String, ?params:Array<Dynamic>):String
		return getUnformatted(defString, id).format(params);

	public static function getUnformatted(defString:String, ?id:String):IFormatInfo
	{
		#if TRANSLATIONS_SUPPORT
		if (id == null) id = defString;
		if (stringMap.exists(id)) return stringMap.get(id);
		#end
		return FormatUtil.get(defString);
	}

	/**
	 * Returns an array that specifies which languages were found.
	 */
	public static function findAllLanguages()
	{
		#if TRANSLATIONS_SUPPORT
		foundLanguages = [];
		nameMap = getDefaultNameMap();
		var mainPath:String = translationsMain("");
		var langName:String = null;
		for (lang in Paths.assetsTree.getFolders("assets/" + mainPath)) {
			var path:String = Path.join([mainPath, lang, "config.ini"]);

			var config = getDefaultConfig(lang);

			if(Assets.exists(path)) {
				config = IniUtil.parseAsset(path, config);
			} else { // if there was no config.ini, use the file name as the language name
				for(file in Paths.getFolderContent(mainPath + lang).sortAlphabetically()) {
					if(Path.extension(path = '$lang/$file') == "xml") {
						config["name"] = Path.withoutExtension(file);
						break;
					}
				}
			}
			langName = config["name"];
			nameMap.set(lang, langName);
			langConfigs.set(lang, config);
			foundLanguages.push('$lang/$langName');
		}

		// Ensure that the default language is always first
		var englishName = TranslationUtil.DEFAULT_LANGUAGE + "/" + getLanguageName(TranslationUtil.DEFAULT_LANGUAGE);
		if (foundLanguages.contains(englishName))
			foundLanguages.remove(englishName);
		foundLanguages.insert(0, englishName);
		#end
	}

	/**
	 * Returns a map of translations based on its XML.
	 */
	public static function loadLanguage(lang:String):Map<String, IFormatInfo>
	{
		#if TRANSLATIONS_SUPPORT
		FormatUtil.clear(); // Clean up the format cache
		var mainPath:String = translationsMain(lang);
		var leMap:Map<String, IFormatInfo> = [];
		var translations = [];
		function parseXml(xml:Access) {
			for(node in xml.elements) {
				if (node.name == "group") // Cosmetic name
					parseXml(node);
				else if(node.name == "text" || node.name == "trans" || node.name == "lang" || node.name == "string")
					translations.push(node);
			}
		}

		for(file in Paths.getFolderContent(mainPath, true).sortAlphabetically()) {
			if(Path.extension(file) != "xml") continue;

			// Parse the XML
			var xml:Access = null;
			try xml = new Access(Xml.parse(Assets.getText(file)))
			catch(e) Logs.error('Error while parsing $file: ${Std.string(e)}', "Language");

			if (xml == null) continue;
			if (!xml.hasNode.language) {
				Logs.warn('File $file requires a <language> root element.', "Language");
				continue;
			}

			var langNode = xml.node.language;

			//if (langNode.has.name) {
			//	getConfig(lang).set("name", langNode.att.name);
			//}

			parseXml(langNode);
		}

		for(node in translations) {
			if (!node.has.id) {
				Logs.warn('A <${node.name}> node requires an ID attribute.', "Language");
				continue;
			}

			var value:String = node.has.string ? node.att.string : node.innerData;
			value = value.replace("\\n", "\n").replace("\r", ""); // remove stupid windows line breaks and convert newline literals to newlines
			leMap.set(node.att.id, FormatUtil.get(value));
		}

		return leMap;
		#else
		return [];
		#end
	}

	// Utils

	public static function getLanguageName(lang:String) {
		return nameMap.exists(lang) ? nameMap.get(lang) : lang;
	}

	public static function getLanguageFromName(name:String) {
		var reverseMap = new Map<String, String>();
		for(key => val in nameMap) reverseMap.set(val, key);
		return reverseMap.exists(name) ? reverseMap.get(name) : name;
	}

	public static function getConfig(lang:String):IniMap {
		return langConfigs.exists(lang) ? langConfigs.get(lang) : getDefaultConfig(lang);
	}

	public static inline function translationsMain(key:String)
		return '$LANG_FOLDER/$key';

	public static inline function translations(key:String)
		return translationsMain('$curLanguage/$key');

	// getters & setters

	@:noCompletion private static function set_stringMap(value:Map<String, IFormatInfo>):Map<String, IFormatInfo> {
		if (value == null) value = [];
		return stringMap = value;
	}

	@:noCompletion private static function get_curLanguage():String {
		return Options.language;
	}
	@:noCompletion private static function set_curLanguage(value:String):String {
		return Options.language = value;
	}

	@:noCompletion private static function get_curLanguageName():String {
		return getLanguageName(Options.language);
	}
	@:noCompletion private static function set_curLanguageName(value:String):String {
		return Options.language = getLanguageFromName(value);
	}

	@:noCompletion private static function get_isDefaultLanguage():Bool
		return Options.language == DEFAULT_LANGUAGE;

	@:noCompletion private static function get_isLanguageLoaded():Bool
		return Lambda.count(stringMap) > 0;
}

/**
 * The class used to format strings based on parameters.
 *
 * For example if the parameter list is just an `Int` which is `9`, `You have been blue balled {0} times` becomes `You have been blue balled 9 times`.
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

	public function toString():String {
		return "StrFormatInfo(" + string + ")";
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

	public function toString():String {
		return 'ParamFormatInfo([${strings.join(", ")}] [${indexes.join(", ")}])';
	}
}

interface IFormatInfo {
	public function format(params:Array<Dynamic>):String;
}