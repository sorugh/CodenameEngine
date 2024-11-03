package funkin.editors.alphabet;

import flixel.math.FlxPoint;
import funkin.backend.system.framerate.Framerate;
import funkin.backend.utils.XMLUtil.AnimData;
import funkin.editors.ui.UIContextMenu.UIContextMenuOption;
import funkin.game.Character;
import haxe.xml.Access;
import haxe.xml.Printer;

@:access(funkin.menus.ui.Alphabet)
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

	public var tape:Alphabet;
	public var bigletter:Alphabet;
	public var curLetter:Int = 0;
	public var targetX:Float = 0;

	public var curSelectedComponent:AlphabetComponent = null;

	public var allChars:Array<String> = [];

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
				label: "Move Tape Left",
				keybind: [LEFT],
				onSelect: _tape_left
			},
			{
				label: "Move Tape Right",
				keybind: [RIGHT],
				onSelect: _tape_right
			}
		];

		editorCamera = FlxG.camera;

		uiCamera = new FlxCamera();
		uiCamera.bgColor = 0;

		FlxG.cameras.add(uiCamera, false);

		var bg = new FlxSprite(0, 0).makeSolid(Std.int(FlxG.width + 100), Std.int(FlxG.height + 100), 0xFF7f7f7f);
		bg.cameras = [editorCamera];
		bg.scrollFactor.set();
		bg.screenCenter();
		add(bg);

		topMenuSpr = new UITopMenu(topMenu);
		topMenuSpr.cameras = uiGroup.cameras = [uiCamera];

		//var alphabet:Alphabet = new Alphabet(0, 0, __typeface);
		//add(alphabet);

		allChars = [];

		var helperAlphabet = new Alphabet(0, 0, "meow", __typeface);
		for(cc in 33...0xffff) {
			// todo: unicode
			var letter = String.fromCharCode(cc);
			var data = helperAlphabet.fastGetData(letter);
			if(data == null) continue;
			if(data.components.length == 0) continue;

			var hasAnim = true;
			var component;
			for (i in 0...data.components.length) {
				component = data.components[i];
				var anim = helperAlphabet.fastGetLetterAnim(letter, data, component, i);
				if(anim == null) {
					hasAnim = false;
					break;
				}
			}
			if(!hasAnim) continue;

			allChars.push(letter);
		}


		trace(allChars.join(" "));
		tape = new Alphabet(0, 70, allChars.join(" "), __typeface);
		tape.alignment = CENTER;
		tape.renderMode = MONOSPACE;
		tape.x = targetX = FlxG.width * 0.5 - tape.defaultAdvance * 0.5;
		add(tape);

		bigletter = new Alphabet(0, 0, "A", __typeface);
		bigletter.alignment = CENTER;
		bigletter.scale.set(4, 4);
		// TODO: fix the offset issues
		bigletter.updateHitbox();
		bigletter.screenCenter();
		add(bigletter);

		var infoWindow = new GlyphInfoWindow();
		infoWindow.info.text = [
			//"Char: " + allChars.charAt(randomIndex),
			//"Anim Name: " + allChars.charAt(randomIndex) + " bold0",
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
			//info.text = "[0] Letter (" + allChars.charAt(randomIndex) + ")";
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

		if(curSelectedComponent != null) {
			if(FlxG.keys.pressed.I) {
				curSelectedComponent.y -= 100 * elapsed;
			}
			if(FlxG.keys.pressed.K) {
				curSelectedComponent.y += 100 * elapsed;
			}
			if(FlxG.keys.pressed.J) {
				curSelectedComponent.x -= 100 * elapsed;
			}
			if(FlxG.keys.pressed.L) {
				curSelectedComponent.x += 100 * elapsed;
			}
		}

		tape.x = lerp(tape.x, targetX, 0.25);
	}

	function changeLetter(inc:Int) {
		curLetter = CoolUtil.positiveModuloInt(curLetter + inc, allChars.length);
		targetX = FlxG.width * 0.5 - tape.defaultAdvance * (0.5 + curLetter * 2);
		bigletter.text = allChars[curLetter];
		bigletter.updateHitbox();
		bigletter.screenCenter();
	}

	function _tape_left(_) {
		changeLetter(-1);
	}
	function _tape_right(_) {
		changeLetter(1);
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

/*

/===============\
| Components    |
|===============|
|[ Component 1 ]|
|[ Component 2 ]|
|[ Component 3 ]|
|[ Component 4 ]|
|[ Component 5 ]|
|[ Add component]|
\===============/

*/

class ComponentInfoWindow extends UIButtonList<ComponentButton> {
	public function new(x:Float, y:Float) {
		super(x, y, )
	}
}

class ComponentButton extends UIButton {
	public var component:AlphabetComponent;
	public function new(component:AlphabetComponent) {
		super(0, 0, component.name, function() {
			AlphabetEditor.instance.curSelectedComponent = component;
		});
		this.component = component;
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