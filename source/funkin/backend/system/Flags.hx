package funkin.backend.system;

import lime.utils.AssetLibrary;
import lime.utils.AssetType;
import flixel.util.FlxColor;

import lime.app.Application;
import funkin.backend.system.macros.GitCommitMacro;
import funkin.backend.assets.IModsAssetLibrary;
import funkin.backend.assets.ScriptedAssetLibrary;

/**
 * A class that reads the `flags.ini` file, allowing to read settable Flags (customs too).
 */
@:build(funkin.backend.system.macros.FlagMacro.build())
class Flags {
	// -- Codename's Default Flags --
	public static var COMMIT_NUMBER:Int = GitCommitMacro.commitNumber;
	public static var COMMIT_HASH:String = GitCommitMacro.commitHash;
	public static var COMMIT_MESSAGE:String = 'Commit $COMMIT_NUMBER ($COMMIT_HASH)';
	@:lazy public static var VERSION_MESSAGE:String = 'Codename Engine v${Application.current.meta.get('version')}';

	public static var REPO_NAME:String = "CodenameEngine";
	public static var REPO_OWNER:String = "FNF-CNE-Devs";
	public static var REPO_URL:String = 'https://github.com/$REPO_OWNER/$REPO_NAME';

	// make this empty once you guys are done with the project.
	// good luck /gen <3 @crowplexus
	public static var RELEASE_CYCLE:String = "Beta";

	/**
	 * Preferred sound extension for the game's audio files.
	 * Currently is set to `mp3` for web targets, and `ogg` for other targets.
	 */
	public static var SOUND_EXT:String = #if web "mp3" #else "ogg" #end; // we also support wav
	public static var VIDEO_EXT:String = "mp4";
	public static var IMAGE_EXT:String = "png"; // we also support jpg

	public static var DEFAULT_DISCORD_LOGO_KEY:String = "icon";
	public static var DEFAULT_DISCORD_CLIENT_ID:String = "1027994136193810442";
	public static var DEFAULT_DISCORD_LOGO_TEXT:String = "Codename Engine";

	@:also(funkin.game.Character.FALLBACK_CHARACTER)
	public static var DEFAULT_CHARACTER:String = "bf";
	public static var DEFAULT_GIRLFRIEND:String = "gf";
	public static var DEFAULT_OPPONENT:String = "dad";

	@:also(funkin.game.PlayState.difficulty)
	public static var DEFAULT_DIFFICULTY:String = "normal";
	public static var DEFAULT_STAGE:String = "stage";
	public static var DEFAULT_SCROLL_SPEED:Float = 2.0;
	public static var DEFAULT_HEALTH_ICON:String = "face";

	public static var SONGS_LIST_MOD_MODE:Allow<"prepend", "override", "append"> = "override";
	public static var WEEKS_LIST_MOD_MODE:Allow<"prepend", "override", "append"> = "override";

	// Translations system //
	public static var DEFAULT_LANGUAGE:String = "en";
	public static var DEFAULT_LANGUAGE_NAME:String = "English";
	/**
	 * **NOTICE:** This will only contain the id of the language, not the full name.
	 * If you blacklist the default language, you will need to change DEFAULT_LANGUAGE and DEFAULT_LANGUAGE_NAME.
	 */
	public static var BLACKLISTED_LANGUAGES:Array<String> = [];
	/**
	 * **NOTICE:** This will only contain the id of the language, not the full name.
	 * If this list is not empty, the languages listed will be the only ones able to be used.
	 */
	public static var WHITELISTED_LANGUAGES:Array<String> = [];

	// Internal stuff
	public static var DEFAULT_BPM:Float = 100.0;
	public static var DEFAULT_BEATS_PER_MEASURE:Float = 4;
	public static var DEFAULT_STEPS_PER_BEAT:Int = 4;

	public static var SUPPORTED_CHART_RUNTIME_FORMATS:Array<String> = ["Legacy", "Psych Engine"];
	public static var SUPPORTED_CHART_FORMATS:Array<String> = ["BaseGame"];

	public static var BASEGAME_SONG_METADATA_VERSION:String = "2.2.2";
	public static var BASEGAME_SONG_CHART_DATA_VERSION:String = "2.0.0";
	public static var BASEGAME_DEFAULT_NOTE_STYLE:String = 'funkin';
	public static var BASEGAME_DEFAULT_ALBUM_ID:String = 'volume1';
	public static var BASEGAME_DEFAULT_PREVIEW_START:Float = 0;
	public static var BASEGAME_DEFAULT_PREVIEW_END:Float = 15000;

	/**
	 * Default background colors for songs without bg color
	 */
	public static var DEFAULT_COLOR:FlxColor = 0xFF9271FD;
	public static var DEFAULT_COOP_ALLOWED:Bool = false;
	public static var DEFAULT_OPPONENT_MODE_ALLOWED:Bool = false;

	@:also(funkin.game.PlayState.coopMode)
	public static var DEFAULT_COOP_MODE:Bool = false; // used in playstate if it doesnt find it
	@:also(funkin.game.PlayState.opponentMode)
	public static var DEFAULT_OPPONENT_MODE:Bool = false;

	public static var DEFAULT_NOTE_MS_LIMIT:Float = 1500;
	public static var DEFAULT_NOTE_SCALE:Float = 0.7;

	@:also(funkin.game.Character.FALLBACK_DEAD_CHARACTER)
	public static var DEFAULT_GAMEOVER_CHARACTER:String = "bf-dead";
	public static var DEFAULT_GAMEOVER_SONG:String = "gameOver";
	public static var DEFAULT_GAMEOVER_LOSS_SFX:String = "gameOverSFX";
	public static var DEFAULT_GAMEOVER_RETRY_SFX:String = "gameOverEnd";

	public static var DEFAULT_CAM_ZOOM_INTERVAL:Int = 4;
	public static var DEFAULT_CAM_ZOOM_STRENGTH:Int = 1;
	public static var DEFAULT_CAM_ZOOM:Float = 1.05; // what zoom level it defaults to
	public static var DEFAULT_HUD_ZOOM:Float = 1.0;
	public static var MAX_CAMERA_ZOOM:Float = 1.35;

	public static var DEFAULT_PAUSE_ITEMS:Array<String> = ['Resume', 'Restart Song', 'Change Controls', 'Change Options', 'Exit to menu', "Exit to charter"];
	public static var DEFAULT_CUTSCENE_PAUSE_ITEMS:Array<String> = ['Resume Cutscene', 'Skip Cutscene', 'Restart Cutscene', 'Exit to menu'];
	public static var DEFAULT_GITAROO:Bool = true;
	public static var GITAROO_CHANCE:Float = 0.1;
	public static var DEFAULT_CAN_ACCESS_DEBUG_MENUS:Bool = true;
	public static var DEFAULT_MUTE_VOCALS_ON_MISS:Bool = true;

	public static var DEFAULT_MAX_HEALTH:Float = 2.0;
	public static var DEFAULT_HEALTH:Null<Float> = null;//DEFAULT_MAX_HEALTH / 2.0;
	public static var BOP_ICON_SCALE:Float = 1.2;
	public static var ICON_OFFSET:Float = 26;
	public static var ICON_LERP:Float = 0.33;

	public static var CAM_BOP_STRENGTH:Float = 0.015;
	public static var HUD_BOP_STRENGTH:Float = 0.03;
	public static var DEFAULT_CAM_ZOOM_LERP:Float = 0.05;
	public static var DEFAULT_HUD_ZOOM_LERP:Float = 0.05;

	public static var MAX_SPLASHES:Int = 8;
	public static var STUNNED_TIME:Float = 5 / 60;

	@:also(funkin.game.PlayState.daPixelZoom)
	public static var PIXEL_ART_SCALE:Float = 6.0;

	public static var DEFAULT_COMBO_GROUP_MAX_SIZE:Int = 25;

	public static var DEFAULT_STRUM_AMOUNT:Int = 4;
	public static var DEFAULT_CAMERA_FOLLOW_SPEED:Float = 0.04;

	public static var VOCAL_OFFSET_VIOLATION_THRESHOLD:Float = 25;

	// Usage: Codename Credits
	public static var MAIN_DEVS_COLOR:FlxColor = 0xFF9C35D5;
	public static var MIN_CONTRIBUTIONS_COLOR:FlxColor = 0xFFB4A7DA;

	public static var UNDO_PREFIX:String = "* ";
	public static var JSON_PRETTY_PRINT:String = "\t";
	// -- End of Codename's Default Flags --

	/**
	 * Flags that Codename couldn't recognize as it's own defaults (they can only be `string`!).
	 */
	@:bypass public static var customFlags:Map<String, String> = [];

	public static function load() {
		var flags:Map<String, String> = [];

		final flagsPath = Paths.getPath("flags.ini");

		for(lib in Paths.assetsTree.libraries) {
			#if TRANSLATIONS_SUPPORT
			// skip translations since it would be useless, if you wanna modify it set the flags inside of global.hx
			if(lib is funkin.backend.assets.TranslatedAssetLibrary) continue;
			#end

			if(lib.exists(flagsPath, AssetType.TEXT)) {
				var data:String = lib.getAsset(flagsPath, AssetType.TEXT);
				var trimmed:String;
				var splitContent = [for(e in data.split("\n")) if ((trimmed = e.trim()) != "") trimmed];

				for(line in splitContent) {
					if(line.startsWith(";")) continue;
					if(line.startsWith("#")) continue;
					if(line.startsWith("//")) continue;
					if(line.length == 0) continue;
					if(line.charAt(0) == "[" && line.charAt(line.length-1) == "]") continue;

					var index = line.indexOf("=");
					if(index == -1) continue;
					var name = line.substr(0, index).trim();
					var value = line.substr(index+1).trim();

					var wasQuoted = value.length > 1 && value.charCodeAt(0) == '"'.code && value.charCodeAt(value.length-1) == '"'.code;
					if(wasQuoted) value = value.substr(1, value.length - 2);
					if((!wasQuoted && value.length == 0) || name.length == 0)
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
}