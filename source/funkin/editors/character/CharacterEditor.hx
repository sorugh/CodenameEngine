package funkin.editors.character;

import funkin.editors.extra.CameraHoverDummy;
import openfl.display.BitmapData;
import flixel.math.FlxPoint;
import funkin.backend.system.framerate.Framerate;
import funkin.backend.utils.XMLUtil.AnimData;
import funkin.editors.ui.UIContextMenu.UIContextMenuOption;
import funkin.game.Character;
import haxe.xml.Access;
import haxe.xml.Printer;

class CharacterEditor extends UIState {
	static var __character:String;
	public var character:Character;

	public static var instance(get, null):CharacterEditor;

	private static inline function get_instance()
		return FlxG.state is CharacterEditor ? cast FlxG.state : null;

	/**
	 * CHARACTER UI STUFF
	*/
	public var characterBG:FunkinSprite;
	public var topMenu:Array<UIContextMenuOption>;
	public var topMenuSpr:UITopMenu;

	public var uiGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();

	public var cameraHoverDummy:CameraHoverDummy;

	public var characterPropertiesWindow:CharacterPropertiesWindow;
	public var characterAnimsWindow:CharacterAnimsWindow;

	public var charCamera:FlxCamera;
	public var uiCamera:FlxCamera;

	public function new(character:String) {
		super();
		if (character != null) __character = character;
	}

	public override function create() {
		super.create();

		WindowUtils.suffix = " (Character Editor)";
		SaveWarning.selectionClass = CharacterSelection;
		SaveWarning.saveFunc = () -> {_file_save(null);};

		topMenu = [
			{
				label: "File",
				childs: [
					{
						label: "New",
						onSelect: _file_new,
					},
					null,
					{
						label: "Save",
						keybind: [CONTROL, S],
						onSelect: _file_save,
					},
					{
						label: "Save As...",
						keybind: [CONTROL, SHIFT, S],
						onSelect: _file_saveas,
					},
					null,
					{
						label: "Exit",
						onSelect: _file_exit
					}
				]
			},
			{
				label: "Edit",
				childs: [
					{
						label: "Undo",
						keybind: [CONTROL, Z],
					},
					{
						label: "Redo",
						keybinds: [[CONTROL, Y], [CONTROL, SHIFT, Z]],
					}
				]
			},
			{
				label: "Character",
				childs: [
					{
						label: "New Animation",
						keybind: [CONTROL, N],
					},
					{
						label: "Edit Animation",
					},
					{
						label: "Delete Animation",
						keybind: [DELETE],
					},
					null,
					{
						label: "Edit Info",
					}
				]
			},
			{
				label: "Playback",
				childs: [
					{
						label: "Play Animation",
						keybind: [SPACE],
						onSelect: _playback_play_anim,
					},
					{
						label: "Stop Animation",
						onSelect: _playback_stop_anim
					}
				]
			},
			{
				label: "Offsets",
				childs: [
					{
						label: "Move Left",
						keybind: [LEFT],
					},
					{
						label: "Move Up",
						keybind: [UP],
					},
					{
						label: "Move Down",
						keybind: [DOWN],
					},
					{
						label: "Move Right",
						keybind: [RIGHT],
					},
					null,
					{
						label: "Move Extra Left",
						keybind: [SHIFT, LEFT],
					},
					{
						label: "Move Extra Up",
						keybind: [SHIFT, UP],
					},
					{
						label: "Move Extra Down",
						keybind: [SHIFT, DOWN],
					},
					{
						label: "Move Extra Right",
						keybind: [SHIFT, RIGHT],
					},
					null,
					{
						label: "Clear Offsets",
						keybind: [CONTROL, R],
					}
				]
			},
			{
				label: "View",
				childs: [
					{
						label: "Zoom in",
						keybind: [CONTROL, NUMPADPLUS],
						onSelect: _view_zoomin
					},
					{
						label: "Zoom out",
						keybind: [CONTROL, NUMPADMINUS],
						onSelect: _view_zoomout
					},
					{
						label: "Reset zoom",
						keybind: [CONTROL, NUMPADZERO],
						onSelect: _view_zoomreset
					},

				]
			},
		];

		charCamera = FlxG.camera;

		uiCamera = new FlxCamera();
		uiCamera.bgColor = 0;

		characterBG = new FunkinSprite(0, 0, Paths.image('editors/character/WOAH'));
		characterBG.cameras = [charCamera];
		characterBG.screenCenter();
		characterBG.scale.set(FlxG.width/characterBG.width, FlxG.height/characterBG.height);
		characterBG.scrollFactor.set();
		add(characterBG);

		// characterBG.visible = false;

		FlxG.cameras.add(uiCamera);

		character = new Character(0,0, __character, false, false);
		character.debugMode = true;
		character.cameras = [charCamera];

		add(character);

		uiGroup.cameras = [uiCamera];
		add(cameraHoverDummy = new CameraHoverDummy(uiGroup, FlxPoint.weak(0, 0)));

		characterPropertiesWindow = new CharacterPropertiesWindow((FlxG.width-(532+16)), 23+12+10, character);
		uiGroup.add(characterPropertiesWindow);

		topMenuSpr = new UITopMenu(topMenu);
		topMenuSpr.cameras = [uiCamera];

		characterAnimsWindow = new CharacterAnimsWindow(characterPropertiesWindow.x, characterPropertiesWindow.y+224+16, character);
		uiGroup.add(characterAnimsWindow);

		add(uiGroup);
		add(topMenuSpr);

		playAnimation(character.getAnimOrder()[0]);
		_view_focus_character(null);


		if(Framerate.isLoaded) {
			Framerate.fpsCounter.alpha = 0.4;
			Framerate.memoryCounter.alpha = 0.4;
			Framerate.codenameBuildField.alpha = 0.4;
		}

		DiscordUtil.call("onEditorLoaded", ["Character Editor", __character]);
	}

	override function destroy() {
		super.destroy();
		if(Framerate.isLoaded) {
			Framerate.fpsCounter.alpha = 1;
			Framerate.memoryCounter.alpha = 1;
			Framerate.codenameBuildField.alpha = 1;
		}
	}

	var _nextScroll:FlxPoint = FlxPoint.get(0,0);
	var _cameraZoomMulti:Float = 1;
	public override function update(elapsed:Float) {
		if(FlxG.keys.justPressed.ANY)
			UIUtil.processShortcuts(topMenu);

		if (cameraHoverDummy.hovered) {
			if (FlxG.mouse.wheel != 0) {
				zoom += 0.25 * FlxG.mouse.wheel;
				__camZoom = Math.pow(2, zoom);
			}

			if (FlxG.mouse.justReleasedRight) {
				closeCurrentContextMenu();
				openContextMenu(topMenu[2].childs);
			}

			if (FlxG.mouse.pressed) {
				_nextScroll.set(_nextScroll.x - FlxG.mouse.deltaScreenX, _nextScroll.y - FlxG.mouse.deltaScreenY);
				currentCursor = HAND;
			} else
				currentCursor = ARROW;
		} else if (!FlxG.mouse.pressed)
			currentCursor = ARROW;

		charCamera.scroll.set(
			lerp(charCamera.scroll.x, _nextScroll.x, 0.35),
			lerp(charCamera.scroll.y, _nextScroll.y, 0.35)
		);

		charCamera.zoom = lerp(charCamera.zoom, __camZoom*_cameraZoomMulti, 0.125);

		characterBG.scale.set(FlxG.width/characterBG.width, FlxG.height/characterBG.height);
		characterBG.scale.set(characterBG.scale.x / charCamera.zoom, characterBG.scale.y / charCamera.zoom);

		super.update(elapsed);
	}

	// TOP MENU OPTIONS
	#if REGION
	function _file_exit(_) {
		/*if (undos.unsaved) SaveWarning.triggerWarning();
		else*/ FlxG.switchState(new CharacterSelection());
	}

	function _file_new(_) {
	}

	function _file_save(_) {
		#if sys
		CoolUtil.safeSaveFile(
			'${Paths.getAssetsRoot()}/data/characters/${character.curCharacter}.xml',
			buildCharacter()
		);
		#else
		_file_saveas(_);
		#end
	}

	function _file_saveas(_) {
		openSubState(new SaveSubstate(buildCharacter(), {
			defaultSaveFile: '${character.curCharacter}.xml'
		}));
	}

	function buildCharacter():String {
		if (character.isPlayer != character.playerOffsets) {
			character.switchOffset('singLEFT', 'singRIGHT');
			character.switchOffset('singLEFTmiss', 'singRIGHTmiss');
		}
		var charXML:Xml = character.buildXML([
			for (button in characterAnimsWindow.buttons.members)
				button.anim
		]);

		return "<!DOCTYPE codename-engine-character>\n" + Printer.print(charXML, true);
	}

	function _playback_play_anim(_) {
		if (character.getNameList().length != 0)
			playAnimation(character.getAnimName());
	}

	function _playback_stop_anim(_) {
		if (character.getNameList().length != 0)
			character.stopAnimation();
	}

	public function playAnimation(anim:String) {
		character.playAnim(anim, true);

		for(i in characterAnimsWindow.buttons.members)
			i.alpha = i.anim == anim ? 1 : 0.25;
	}

	var zoom(default, set):Float = 0;
	var __camZoom(default, set):Float = 1;
	function set_zoom(val:Float) {
		return zoom = FlxMath.bound(val, -3.5, 1.75); // makes zooming not lag behind when continuing scrolling
	}
	function set___camZoom(val:Float) {
		return __camZoom = FlxMath.bound(val, 0.1, 3);
	}

	function _view_zoomin(_) {
		zoom += 0.25;
		__camZoom = Math.pow(2, zoom);
	}
	function _view_zoomout(_) {
		zoom -= 0.25;
		__camZoom = Math.pow(2, zoom);
	}
	function _view_zoomreset(_) {
		zoom = 0;
		__camZoom = Math.pow(2, zoom);
	}

	function _view_focus_character(_) {
		if (character == null) return;

		var characterMidpoint:FlxPoint = character.getMidpoint();
		characterMidpoint.x -= (FlxG.width/2)-character.globalOffset.x;
		characterMidpoint.y -= (FlxG.height/2)-character.globalOffset.y+(23/4);
		_nextScroll.set(characterMidpoint.x, characterMidpoint.y);
		characterMidpoint.put();
	}
	#end
}