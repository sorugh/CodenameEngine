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
    public static var DEFAULT_LANGUAGE:String = 'English';  // no inline so psycopathic mods can edit it  - Nex

    /**
	 * Returns the current language.
	 */
    inline public static function get_curLanguage():String
        return Options.language;

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
		trace(transMap = loadLanguage(name == null ? get_curLanguage() : name));

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
		// to finish once done with the lib thing  - Nex
        for(l in Assets.list()) {
            var d = Path.directory(l);
            if(d.startsWith(Paths.translationsMain(''))) {
                d = (d.replace(Paths.translationsMain(''), "").split("/"))[0];
                if(!translations.contains(d)) translations.push(d);
            }
        }
		#end
        return translations;
    }

    /**
	 * Returns a map of translations based on its main.xml.
	 */
    public static function loadLanguage(name:String):Map<String, String>
    {
		#if TRANSLATIONS_SUPPORT
        var path:String = Paths.translationsMain('$name/main.xml');
        if (!Assets.exists(path, TEXT)) return [];

        var xml:Access = null;
        try xml = new Access(Xml.parse(Assets.getText(path)))
        catch(e) {
            FlxG.log.error('Error while parsing main.xml: ${Std.string(e)}');
            throw new Exception('Error while parsing main.xml: ${Std.string(e)}');
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