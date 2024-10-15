package funkin.editors.alphabet;

import flixel.math.FlxPoint;
import funkin.backend.system.framerate.Framerate;
import funkin.backend.utils.XMLUtil.AnimData;
import funkin.editors.ui.UIContextMenu.UIContextMenuOption;
import funkin.game.Character;
import haxe.xml.Access;
import haxe.xml.Printer;

class AlphabetEditor extends UIState {
	static var __typeface:String;

	public static var instance(get, null):AlphabetEditor;

	private static inline function get_instance()
		return FlxG.state is AlphabetEditor ? cast FlxG.state : null;

	public var topMenu:Array<UIContextMenuOption>;
	public var topMenuSpr:UITopMenu;

	public var uiGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();

	var editorCamera:FlxCamera;
	var uiCamera:FlxCamera;

	public function new(typeface:String) {
		super();
		if (typeface != null) __typeface = typeface;
	}

	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("alphabetEditor." + id, args);

	public override function create() {
		super.create();

		WindowUtils.suffix = " (" + translate("name") + ")";
		SaveWarning.selectionClass = AlphabetSelection;
		SaveWarning.saveFunc = () -> {_file_save(null);};

		topMenu = [
			{
				label: translate("topBar.file"),
				childs: [
					{
						label: translate("file.save"),
						keybind: [CONTROL, S],
						onSelect: _file_save
					},
					{
						label: translate("file.saveAs"),
						keybind: [CONTROL, SHIFT, S],
						onSelect: _file_saveas
					},
					null,
					{
						label: translate("file.exit"),
						onSelect: _file_exit
					}
				]
				// TODO: add more options
			},
			{
				label: translate("topBar.glyph"),
				childs: [
					{
						label: translate("glyph.newGlyph"),
						//onSelect: _glyph_new
					},
					{
						label: translate("glyph.editGlyph"),
						//onSelect: _glyph_edit
					},
					{
						label: translate("glyph.deleteGlyph"),
						//onSelect: _glyph_delete
					}
				]
			},
			{
				label: translate("topBar.view"),
				childs: [
					{
						label: translate("view.zoomIn"),
						keybind: [CONTROL, NUMPADPLUS],
						//onSelect: _view_zoomin
					},
					{
						label: translate("view.zoomOut"),
						keybind: [CONTROL, NUMPADMINUS],
						//onSelect: _view_zoomout
					},
					{
						label: translate("view.resetZoom"),
						keybind: [CONTROL, NUMPADZERO],
						//onSelect: _view_zoomreset
					},
				]
			},
			{
				label: "                 ",
				childs: [
					{
						label: "Tape",
						//onSelect: _tape
					}
				]
			},
			{
				label: "Move Tape Left",
				childs: [
					{
						label: "Tape",
						//onSelect: _tape
					}
				]
			},
			{
				label: "Move Tape Right",
				childs: [
					{
						label: "Tape",
						//onSelect: _tape
					}
				]
			}
		];

		editorCamera = FlxG.camera;

		uiCamera = new FlxCamera();
		uiCamera.bgColor = 0;

		FlxG.cameras.add(uiCamera);

		var bg = new FlxSprite(0, 0).makeSolid(Std.int(FlxG.width + 100), Std.int(FlxG.height + 100), 0xFF7f7f7f);
		bg.cameras = [editorCamera];
		bg.scrollFactor.set();
		bg.screenCenter();
		add(bg);

		topMenuSpr = new UITopMenu(topMenu);
		topMenuSpr.cameras = uiGroup.cameras = [uiCamera];

		//var alphabet:Alphabet = new Alphabet(0, 0, __typeface);
		//add(alphabet);

		var xml = Xml.parse(Assets.getText(Paths.xml('alphabet/$__typeface'))).firstElement();
		var spritesheet = null;
		for(node in xml.elements()) {
			if (node.nodeName == "spritesheet") {
				spritesheet = node.firstChild().nodeValue;
				break;
			}
		}

		var useColorOffsets = xml.get("useColorOffsets").getDefault("false") == "true";


		// todo fix crash if invalid spritesheet;
		var alphabetFrames = Paths.getFrames(spritesheet);

		var allChars = "";
		for(frame in alphabetFrames.frames) {
			var secondChar = frame.name.charAt(1);
			if(secondChar != " ") continue;
			if(allChars.contains(frame.name.charAt(0))) continue;
			allChars += frame.name.charAt(0);
		}

		var letterSprites:Array<FlxSprite> = [];
		for(letter in allChars.split("")) {
			var spr = new FlxSprite(0, 0);
			spr.frames = alphabetFrames;
			spr.antialiasing = true;
			spr.animation.addByPrefix("letter", letter, 24);
			spr.animation.play("letter");
			add(spr);
			letterSprites.push(spr);
		}

		var length = letterSprites.length;
		var letterWidth = 70;
		var letterHeight = 80;
		//var width = 10;
		//var totalWidth = 10 * 70;
		//for(i in 0...length) {
		//	var letter = letterSprites[i];
		//	var x = i % width * 70 + (FlxG.width / 2 - totalWidth / 2);
		//	var y = Std.int(i / width) * 80 + 100;
		//	letter.setPosition(x, y);
		//}

		var randomIndex = FlxG.random.int(0, length-1);
		for(i in 0...length) {
			var letter = letterSprites[i];
			letter.alpha = 0.2;
		}
		letterSprites[randomIndex].alpha = 1;

		for(i in 0...length) {
			var letter = letterSprites[i];
			letter.x = i * letterWidth - randomIndex * letterWidth + (FlxG.width / 2 - letterWidth / 2);
			letter.y = 50;
		}

		var bigletter = new FlxSprite(0, 0);
		bigletter.frames = alphabetFrames;
		bigletter.antialiasing = true;
		bigletter.animation.addByPrefix("letter", allChars.charAt(randomIndex), 24);
		bigletter.animation.play("letter");
		bigletter.updateHitbox();
		bigletter.screenCenter();
		bigletter.scale.set(4, 4);
		add(bigletter);

		var infoWindow = new GlyphInfoWindow();
		infoWindow.info.text = [
			"Char: " + allChars.charAt(randomIndex),
			"Anim Name: " + allChars.charAt(randomIndex) + " bold0",
			"X Offset: " + 0,
			"Y Offset: " + 0,
			"ScaleX: " + 1,
			"ScaleY: " + 1,
			"Angle: " + 0,
		].join('\n');
		uiGroup.add(infoWindow);

		var leftWindow = new UIWindow(30, 720 - 170 - 30, 230, 170, "Components:");
		leftWindow.members.push({
			var info = new UIText(leftWindow.x + 28, leftWindow.y + 46, 400, "");
			info.text = "[0] Letter (" + allChars.charAt(randomIndex) + ")";
			info.alignment = LEFT;
			info;
		});
		leftWindow.members.push(new UIButton(leftWindow.x + 28, leftWindow.y + 170 - 40, "Add", function () {}));
		uiGroup.add(leftWindow);

		add(topMenuSpr);
		add(uiGroup);

		if(Framerate.isLoaded) {
			Framerate.fpsCounter.alpha = 0.4;
			Framerate.memoryCounter.alpha = 0.4;
			Framerate.codenameBuildField.alpha = 0.4;
		}

		DiscordUtil.call("onEditorLoaded", ["Alphabet Editor", __typeface]);
	}

	override function destroy() {
		super.destroy();
		if(Framerate.isLoaded) {
			Framerate.fpsCounter.alpha = 1;
			Framerate.memoryCounter.alpha = 1;
			Framerate.codenameBuildField.alpha = 1;
		}
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		if (true) {
			if(FlxG.keys.justPressed.ANY)
				UIUtil.processShortcuts(topMenu);
		}

		if(FlxG.keys.pressed.J) {
			editorCamera.scroll.x -= 100 * elapsed;
		}
		if(FlxG.keys.pressed.L) {
			editorCamera.scroll.x += 100 * elapsed;
		}
		if(FlxG.keys.pressed.I) {
			editorCamera.scroll.y -= 100 * elapsed;
		}
		if(FlxG.keys.pressed.K) {
			editorCamera.scroll.y += 100 * elapsed;
		}
	}

	function _file_save(_) {
		#if sys
		CoolUtil.safeSaveFile(
			'${Paths.getAssetsRoot()}/data/alphabet/${__typeface}.xml',
			""//alphabet.buildXML()
		);
		#else
		_file_saveas(_);
		#end
	}

	function _file_saveas(_) {
		openSubState(new SaveSubstate(""/*alphabet.buildXML()*/, {
			defaultSaveFile: '${__typeface}.xml'
		}));
	}

	function _file_exit(_) {
		/*if (undos.unsaved) SaveWarning.triggerWarning();
		else */FlxG.switchState(new AlphabetSelection());
	}
}

class GlyphInfoWindow extends UIWindow {
	public var info:UIText;
	public function new() {
		var width = 230;
		var height = 170;
		var margin = 30;
		super(FlxG.width - width - margin, FlxG.height - height - margin, width, height, "Glyph Info");

		info = new UIText(x + 28, y + 46, 400, "");
		info.alignment = LEFT;
		members.push(info);
	}
}