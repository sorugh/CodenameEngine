package funkin.backend.utils;

import funkin.backend.utils.IniUtil;
import funkin.backend.assets.TranslatedAssetLibrary;
import funkin.backend.assets.ModsFolder;
import openfl.utils.Assets;
import haxe.io.Path;
import haxe.xml.Access;
import haxe.Exception;
import funkin.backend.utils.translations.FormatUtil;

/**
 * The class used for translations based on the XMLs inside the translations folders.
 *
 * Made by @NexIsDumb originally for the Poldhub mod.
 */
@:allow(funkin.backend.assets.TranslatedAssetLibrary)
final class TranslationUtil
{
	/**
	 * The current language selected translation map; If the current language it's english, this map will be empty.
	 *
	 * It'll never be `null`.
	 */
	public static var stringMap(default, set):Map<String, IFormatInfo> = [];

	/**
	 * The default language folder used inside of the source code.
	 */
	public static var DEFAULT_LANGUAGE:String = 'en';  // no inline so psychopathic mods can edit it  - Nex
	/**
	 * The default language used inside of the source code.
	 */
	public static var DEFAULT_LANGUAGE_NAME:String = 'English';

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

	public static var showMissingIds:Bool = false;

	// Private
	private static inline var LANG_FOLDER:String = "languages";
	private static var langConfigs:Map<String, IniMap> = [];
	private static var nameMap:Map<String, String> = [];
	private static inline function getDefaultNameMap():Map<String, String> {
		return [DEFAULT_LANGUAGE => DEFAULT_LANGUAGE_NAME];
	}
	private static inline function getDefaultLangConfigs():Map<String, IniMap> {
		return [DEFAULT_LANGUAGE => getDefaultConfig(DEFAULT_LANGUAGE)];
	}
	@:noUsing private static inline function getDefaultConfig(name:String):IniMap {
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

		showMissingIds = config.get("showMissingIds").getDefault("false") == "true";
		#end
	}

	/**
	 * This is for checking and getting a translation, `defString` it's just the string that gets returned just in case it won't find the translation OR the current language selected is ``DEFAULT_LANGUAGE``.
	 *
	 * If `id` is `null` then it's gonna search using `defString`.
	 */
	public static inline function get(?id:String, ?params:Array<Dynamic>, ?def:String):String
		return getUnformatted(id, def).format(params);

	public static inline function translate(?id:String, ?params:Array<Dynamic>, ?def:String):String
		return get(id, params, def);

	public static inline function translateDiff(?id:String, ?params:Array<Dynamic>):String
		return get("diff." + id.toLowerCase(), params, id);

	public static inline function exists(id:String):Bool
		#if TRANSLATIONS_SUPPORT
		return stringMap.exists(id);
		#else
		return false;
		#end

	public static function getUnformatted(id:String, ?def:String):IFormatInfo
	{
		#if TRANSLATIONS_SUPPORT
		if (stringMap.exists(id)) return stringMap.get(id);
		#end

		if(def != null)
			return FormatUtil.get(def);

		return FormatUtil.getStr("{" + id + "}");

		/*if(curLanguage == DEFAULT_LANGUAGE) {
			return FormatUtil.getStr("{" + id + "}");
		} else {

		}

		return FormatUtil.get(showMissingIds ? "{" + id + "}" : id);*/
	}

	/**
	 * Formats a normal string into an ID for translations.
	 *
	 * Example: `Resume Song` => `resumeSong`
	 */
	public static function raw2Id(str:String):String
	{
		var result:String = "";
		for(i => s in str.split(" ")) result += (i == 0 ? s.charAt(0).toLowerCase() : s.charAt(0).toUpperCase()) + s.substr(1);
		return result.length == 0 ? str : result;
	}

	/**
	 * Returns an array that specifies which languages were found.
	 */
	public static function findAllLanguages()
	{
		#if TRANSLATIONS_SUPPORT
		foundLanguages = [];
		nameMap = getDefaultNameMap();
		langConfigs = getDefaultLangConfigs();
		var mainPath:String = translationsMain("");
		var langName:String = null;
		for (lang in Paths.assetsTree.getFolders("assets/" + mainPath)) {
			var path:String = Path.join([mainPath, lang, "config.ini"]);

			var config = getDefaultConfig(lang);

			if(Assets.exists(path)) {
				config = IniUtil.parseAsset(path, config);
			} else { // if there was no config.ini, use the file name as the language name
				for(file in Paths.getFolderContent(mainPath + lang).sortAlphabetically()) {
					if(Path.extension(file) == "xml") {
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
		var englishName = DEFAULT_LANGUAGE + "/" + getLanguageName(DEFAULT_LANGUAGE);
		if(foundLanguages.contains(englishName)) foundLanguages.remove(englishName);
		foundLanguages.insert(0, englishName);

		if(!nameMap.exists(curLanguage)) curLanguage = DEFAULT_LANGUAGE;
		Logs.trace("Found languages: " + foundLanguages.join(", "), "Language");
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
		var translations:Array<TranslationPair> = [];
		function parseXml(xml:Access, prefix:String = "") {
			for(node in xml.elements) {
				if (node.name == "group") // Cosmetic name
					parseXml(node, prefix + (node.has.prefix ? node.att.prefix : ""));
				else if(["text", "trans", "lang", "string", "str"].contains(node.name))
					translations.push({
						prefix: prefix,
						node: node
					});
			}
		}

		for(mod in ModsFolder.getLoadedModsLibs(true)) for(file in mod.getFiles("assets/" + mainPath).sortAlphabetically().map((v)->'$mainPath/$v')) {
			if(Path.extension(file).toLowerCase() != "xml") continue;

			// Parse the XML
			var xml:Access = null;
			try xml = new Access(Xml.parse(Assets.getText("assets/" + file)))
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

		for(pair in translations) {
			var node = pair.node;
			if (!node.has.id) {
				Logs.warn('A <${node.name}> node requires an ID attribute.', "Language");
				continue;
			}
			var prefix = pair.prefix;

			var id = prefix + node.att.id;

			if(leMap.exists(id)) continue;
			var value:String = node.has.string ? node.att.string : node.innerData;
			if(node.getAtt("notrim").getDefault("true") != "true") value = value.trim();
			value = value.replace("\\n", "\n").replace("\r", ""); // remove stupid windows line breaks and convert newline literals to newlines
			leMap.set(id, FormatUtil.get(value));
			//Logs.trace("Added " + id + " -> `" + value + "`", "Language");
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

@:structInit
class TranslationPair {
	public var prefix:String;
	public var node:Access;
}