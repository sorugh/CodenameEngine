package funkin;

import lime.app.Application;
import funkin.backend.system.macros.GitCommitMacro;
import flixel.util.FlxColor;

using StringTools;

class Constants {
	public static var COMMIT_NUMBER = GitCommitMacro.commitNumber;
	public static var COMMIT_HASH = GitCommitMacro.commitHash;
	public static var COMMIT_MESSAGE = 'Commit $COMMIT_NUMBER ($COMMIT_HASH)';

	public static var REPO_NAME = "CodenameEngine";
	public static var REPO_OWNER = "FNF-CNE-Devs";

	public static var REPO_URL:String = 'https://github.com/$REPO_OWNER/$REPO_NAME';

	// make this empty once you guys are done with the project.
	// good luck /gen <3 @crowplexus
	public static var RELEASE_CYCLE:String = "Beta";

	/**
	 * Preferred sound extension for the game's audio files.
	 * Currently is set to `mp3` for web targets, and `ogg` for other targets.
	 */
	public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	public static var VIDEO_EXT = "mp4";
	public static var IMAGE_EXT = "png";

	public static var DISCORD_LOGO_KEY = "icon";
	public static var DISCORD_CLIENT_ID = "1027994136193810442";
	public static var DISCORD_LOGO_TEXT = "Codename Engine";

	public static var DEFAULT_CHARACTER = "bf";
	public static var DEFAULT_GIRLFRIEND = "gf";
	public static var DEFAULT_OPPONENT = "dad";

	public static var DEFAULT_DIFFICULTY = "normal";
	public static var DEFAULT_STAGE = "stage";
	public static var DEFAULT_SCROLL_SPEED = 2.0;
	//public static var DEFAULT_NOTE_TYPE:String = null;
	public static var DEFAULT_HEALTH_ICON = "face";

	public static var DEFAULT_BPM = 100.0;
	public static var DEFAULT_BEATS_PER_MEASURE = 4;
	public static var DEFAULT_STEPS_PER_BEAT = 4;

	public static var SUPPORTED_CHART_RUNTIME_FORMATS = ["Legacy", "Psych Engine"];
	public static var SUPPORTED_CHART_FORMATS = ["BaseGame"];

	public static var BASEGAME_SONG_METADATA_VERSION = "2.2.2";
	public static var BASEGAME_SONG_CHART_DATA_VERSION = "2.0.0";
	public static var BASEGAME_DEFAULT_NOTE_STYLE = 'funkin';
	public static var BASEGAME_DEFAULT_ALBUM_ID = 'volume1';
	public static var BASEGAME_DEFAULT_PREVIEW_START = 0;
	public static var BASEGAME_DEFAULT_PREVIEW_END = 15000;

	public static var DEFAULT_COOP_ALLOWED = false;
	public static var DEFAULT_OPPONENT_MODE_ALLOWED = false;
	public static var DEFAULT_COOP_MODE = false; // used in playstate if it doesnt find it
	public static var DEFAULT_OPPONENT_MODE = false;

	public static var DEFAULT_NOTE_MS_LIMIT:Float = 1500;

	public static var DEFAULT_NOTE_SCALE = 0.7;

	/**
	 * Default background colors for songs without bg color
	 */
	public static var DEFAULT_COLOR:FlxColor = 0xFF9271FD;

	public static var JSON_PRETTY_PRINT = "\t";

	public static var UNDO_PREFIX = "* ";

	// -- PlayState --

	public static var DEFAULT_GAMEOVER_CHARACTER = "bf-dead";
	public static var DEFAULT_GAMEOVER_SONG = "gameOver";
	public static var DEFAULT_GAMEOVER_LOSS_SFX = "gameOverSFX";
	public static var DEFAULT_GAMEOVER_RETRY_SFX = "gameOverEnd";

	public static var DEFAULT_CAM_ZOOM_INTERVAL = 4;
	public static var DEFAULT_CAM_ZOOM_STRENGTH = 1;
	public static var DEFAULT_CAM_ZOOM = 1.05; // what zoom level it defaults to
	public static var DEFAULT_HUD_ZOOM = 1.0;
	public static var MAX_CAMERA_ZOOM = 1.35;

	public static var DEFAULT_PAUSE_ITEMS = ['Resume', 'Restart Song', 'Change Controls', 'Change Options', 'Exit to menu', "Exit to charter"];
	public static var DEFAULT_CUTSCENE_PAUSE_ITEMS = ['Resume Cutscene', 'Skip Cutscene', 'Restart Cutscene', 'Exit to menu'];
	public static var DEFAULT_GITAROO = true;
	public static var GITAROO_CHANCE = 0.1;
	public static var DEFAULT_CAN_ACCESS_DEBUG_MENUS = true;
	public static var DEFAULT_MUTE_VOCALS_ON_MISS = true;

	public static var DEFAULT_MAX_HEALTH = 2.0;
	public static var DEFAULT_HEALTH = DEFAULT_MAX_HEALTH / 2.0;


	public static var PIXEL_ART_SCALE = 6.0;

	public static var DEFAULT_COMBO_GROUP_MAX_SIZE = 25;

	public static var DEFAULT_STRUM_AMOUNT = 4;
	public static var DEFAULT_CAMERA_FOLLOW_SPEED = 0.04;

	public static var ICON_OFFSET = 26;
	public static var ICON_LERP = 0.33;

	public static var VOCAL_OFFSET_VIOLATION_THRESHOLD = 25;

	public static var DEFAULT_CAM_ZOOM_LERP = 0.05;
	public static var DEFAULT_HUD_ZOOM_LERP = 0.05;

	public static var BOP_ICON_SCALE = 1.2;

	public static var CAM_BOP_STRENGTH = 0.015;
	public static var HUD_BOP_STRENGTH = 0.03;


	public static var MAX_SPLASHES = 8;

	public static var STUNNED_TIME = 5 / 60;

	// Usage: Codename Credits
	public static var MAIN_DEVS_COLOR:FlxColor = 0xFF9C35D5;
	public static var MIN_CONTRIBUTIONS_COLOR:FlxColor = 0xFFB4A7DA;


	public static var DEFAULT_NOTE_FIELDS:Array<String> = ["time", "id", "type", "sLen"];
}