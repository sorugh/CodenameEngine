package funkin.editors.character;

import funkin.editors.extra.AxisGizmo;
import flixel.math.FlxRect;
import funkin.editors.stage.StageEditor;
import funkin.game.Stage;
import funkin.editors.ui.UITopMenu.UITopMenuButton;
import funkin.editors.extra.CameraHoverDummy;
import openfl.display.BitmapData;
import flixel.math.FlxPoint;
import funkin.backend.system.framerate.Framerate;
import funkin.backend.utils.XMLUtil.AnimData;
import funkin.editors.ui.UIContextMenu.UIContextMenuOption;
import funkin.editors.ui.UIContextMenu.UIContextMenuOptionSpr;
import funkin.game.Character;
import haxe.xml.Access;
import haxe.xml.Printer;

class CharacterEditor extends UIState {
	static var __character:String;
	public var character:CharacterGhost;

	public static var instance(get, never):CharacterEditor;

	private static inline function get_instance()
		return FlxG.state is CharacterEditor ? cast FlxG.state : null;

	public var topMenu:Array<UIContextMenuOption>;
	@:noCompletion private var animationIndex:Int = 5;
	@:noCompletion private var stageIndex:Int = 3;

	public var topMenuSpr:UITopMenu;
	// public var dragOffsetsCheckbox:UICheckbox;
	// public var lockCameraCheckbox:UICheckbox;
	
	public var axisGizmo:AxisGizmo;
	public var characterGizmo:CharacterGizmos;
	public var uiGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();

	public var cameraHoverDummy:CameraHoverDummy;

	public var characterPropertiesWindow:CharacterPropertiesWindow;
	public var characterAnimsWindow:CharacterAnimsWindow;

	public var charCamera:FlxCamera;
	public var gizmosCamera:FlxCamera;
	public var uiCamera:FlxCamera;

	public var animationText:UIText;

	public var currentStage:String = null;
	public var stage:Stage = null;

	public var stageSprites:Array<FlxBasic> = [];
	public var stagePosition:String  = null;

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
						label: "Copy Offset",
						keybind: [CONTROL, C],
						onSelect: _edit_copy_offset
					},
					{
						label: "Paste Offset",
						keybind: [CONTROL, V],
						onSelect: _edit_paste_offset
					},
					null,
					{
						label: "Undo",
						keybind: [CONTROL, Z],
						onSelect: _edit_undo
					},
					{
						label: "Redo",
						keybinds: [[CONTROL, Y], [CONTROL, SHIFT, Z]],
						onSelect: _edit_redo
					},
					null,
					{
						label: "Edit information",
						color: 0xFF959829, icon: 4,
						onCreate: function (button:UIContextMenuOptionSpr) {button.label.offset.x = button.icon.offset.x = -2;},
						onSelect: _edit_info
					},
					{
						label: "Edit sprite",
						color: 0xFF959829, icon: 4,
						onCreate: function (button:UIContextMenuOptionSpr) {button.label.offset.x = button.icon.offset.x = -2;},
						onSelect: _edit_sprite
					}
				]
			},
			{
				label: "Offsets",
				childs: [
					{
						label: "Move Left",
						keybind: [LEFT],
						onSelect: _offsets_left,
					},
					{
						label: "Move Up",
						keybind: [UP],
						onSelect: _offsets_up,
					},
					{
						label: "Move Down",
						keybind: [DOWN],
						onSelect: _offsets_down,
					},
					{
						label: "Move Right",
						keybind: [RIGHT],
						onSelect: _offsets_right,
					},
					null,
					{
						label: "Move Extra Left",
						keybind: [SHIFT, LEFT],
						onSelect: _offsets_extra_left,
					},
					{
						label: "Move Extra Up",
						keybind: [SHIFT, UP],
						onSelect: _offsets_extra_up,
					},
					{
						label: "Move Extra Down",
						keybind: [SHIFT, DOWN],
						onSelect: _offsets_extra_down,
					},
					{
						label: "Move Extra Right",
						keybind: [SHIFT, RIGHT],
						onSelect: _offsets_extra_right,
					},
					null,
					{
						label: "Drag Offsets With Mouse?",
						onSelect: _offsets_drag_offsets_mouse,
						icon: Options.characterDragging ? 1 : 0
					},
					{
						label: "Clear Offsets",
						keybind: [CONTROL, R],
						onSelect: _offsets_clear,
					}
				]
			},
			{
				label: "Stage",
				childs: buildStagesUI()
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
					null,
					{
						label: "Character Hitbox?",
						onSelect: _view_character_show_hitbox,
						icon: Options.characterHitbox ? 1 : 0
					},
					{
						label: "Character Camera?",
						onSelect: _view_character_show_camera,
						icon: Options.characterCamera ? 1 : 0
					},
					{
						label: "XY Axis?",
						onSelect: _view_character_show_axis,
						icon: Options.characterAxis ? 1 : 0
					}
				]
			},
			{
				label: "Animation >",
				childs: [
					{
						label: "Play Animation",
						keybind: [SPACE],
						onSelect: _animation_play,
					},
					{
						label: "Stop Animation",
						onSelect: _animation_stop
					},
					null,
					{
						label: "Change Animation ↑",
						keybind: [W],
						onSelect: _animation_up
					},
					{
						label: "Change Animation ↓",
						keybind: [S],
						onSelect: _animation_down
					}
				]
			},
		];

		charCamera = FlxG.camera;

		gizmosCamera = new FlxCamera();
		gizmosCamera.bgColor = 0;
		FlxG.cameras.add(gizmosCamera);

		axisGizmo = new AxisGizmo();
		axisGizmo.cameras = [gizmosCamera];
		add(axisGizmo);

		characterGizmo = new CharacterGizmos();
		characterGizmo.boxGizmo = Options.characterHitbox;
		characterGizmo.cameraGizmo = Options.characterCamera;
		characterGizmo.cameras = [gizmosCamera];
		add(characterGizmo);

		uiCamera = new FlxCamera();
		uiCamera.bgColor = 0;

		FlxG.cameras.add(uiCamera);

		character = new CharacterGhost(0,0, __character, false, false);
		character.debugMode = true;
		character.cameras = [charCamera];

		characterGizmo.character = character;

		changeCharacterIsPlayer(character.playerOffsets);

		add(character);

		uiGroup.cameras = [uiCamera];
		add(cameraHoverDummy = new CameraHoverDummy(uiGroup, FlxPoint.weak(0, 0)));

		characterPropertiesWindow = new CharacterPropertiesWindow((FlxG.width-(440)-16) - (((500-16)-(440))/2), 23+12+10, character);
		uiGroup.add(characterPropertiesWindow);

		topMenuSpr = new UITopMenu(topMenu);
		uiGroup.add(topMenuSpr);

		animationText = new UIText(0, 0, 0, "");
		uiGroup.add(animationText);

		characterAnimsWindow = new CharacterAnimsWindow((FlxG.width-(500-16)-16), characterPropertiesWindow.y+224+16, character);
		uiGroup.add(characterAnimsWindow);

		add(uiGroup);

		playAnimation(character.getAnimOrder()[0]);
		changeStage("stage");

		_view_focus_character(null);

		if(Framerate.isLoaded) {
			Framerate.fpsCounter.alpha = 0.4;
			Framerate.memoryCounter.alpha = 0.4;
			Framerate.codenameBuildField.alpha = 0.4;
		}

		DiscordUtil.call("onEditorLoaded", ["Character Editor", __character]);
	}

	override function destroy() {
		_point.put();
		draggingOffset.put();
		clipboard.put();

		super.destroy();
		if(Framerate.isLoaded) {
			Framerate.fpsCounter.alpha = 1;
			Framerate.memoryCounter.alpha = 1;
			Framerate.codenameBuildField.alpha = 1;
		}
	}

	var _point:FlxPoint = new FlxPoint();
	var _nextScroll:FlxPoint = FlxPoint.get(0,0);
	var _cameraZoomMulti:Float = 1;

	public var draggingCharacter:Bool = false;
	public var draggingOffset:FlxPoint = new FlxPoint();
	public override function update(elapsed:Float) {
		if(FlxG.keys.justPressed.ANY)
			UIUtil.processShortcuts(topMenu);

		if (cameraHoverDummy.hovered && !draggingCharacter) {
			if (FlxG.mouse.wheel != 0) {
				zoom += 0.25 * FlxG.mouse.wheel;
				__camZoom = Math.pow(2, zoom);
			}

			if (FlxG.mouse.justReleasedRight) {
				closeCurrentContextMenu();
				openContextMenu(topMenu[2].childs);
			}

			if (FlxG.mouse.pressed && !FlxG.mouse.justPressed) {
				_nextScroll.set(_nextScroll.x - FlxG.mouse.deltaScreenX, _nextScroll.y - FlxG.mouse.deltaScreenY);
				cameraHoverDummy.cursor = HAND;
			} else
				cameraHoverDummy.cursor = ARROW;
		} else if (!FlxG.mouse.pressed)
			currentCursor = ARROW;

		charCamera.scroll.set(
			lerp(charCamera.scroll.x, _nextScroll.x, 0.35),
			lerp(charCamera.scroll.y, _nextScroll.y, 0.35)
		);

		charCamera.zoom = lerp(charCamera.zoom, __camZoom*_cameraZoomMulti, 0.125);

		if (topMenuSpr.members[animationIndex] != null) {
			var animationTopButton:UITopMenuButton = cast topMenuSpr.members[animationIndex];
			animationText.x = animationTopButton.x + animationTopButton.bWidth + 6;
			animationText.y = Std.int((animationTopButton.bHeight - animationText.height) / 2);
		}
		animationText.text = '"${character.getAnimName()}"';

		if (Options.characterDragging)
			handleMouseOffsets();

		super.update(elapsed);
	}

	inline function handleMouseOffsets() {
		if (draggingCharacter) {
			cameraHoverDummy.cursor = DRAG;

			if (FlxG.mouse.justReleased) {
				draggingOffset.x /= character.scale.x;
				draggingOffset.y /= character.scale.y;

				_change_offset((draggingOffset.x * (character.isPlayer != character.playerOffsets  ? -1 : 1)), draggingOffset.y);

				draggingOffset.set(0, 0); draggingCharacter = false;
				character.extraOffset = draggingOffset;
			} else {
				draggingOffset.x += FlxG.mouse.deltaScreenX; draggingOffset.y += FlxG.mouse.deltaScreenY;
				character.extraOffset = draggingOffset;
			}
		} else {
			var point = FlxG.mouse.getWorldPosition(charCamera, _point);
			if(character.animateAtlas == null) {
				StageEditor.calcSpriteBounds(character);
				var bounds:FlxRect = cast character.extra.get(StageEditor.exID("bounds"));
				if (bounds.containsPoint(point)) {
					cameraHoverDummy.cursor = #if (mac) DRAG_OPEN; #else CLICK; #end
					if (FlxG.mouse.justPressed)
						draggingCharacter = true;
				}
			}
		}
	}

	// TOP MENU OPTIONS
	#if REGION
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

	function _file_exit(_) {
		/*if (undos.unsaved) SaveWarning.triggerWarning();
		else*/ FlxG.switchState(new CharacterSelection());
	}

	function buildCharacter():String {
		if (character.extra.exists(StageEditor.exID("bounds")))
			character.extra.remove(StageEditor.exID("bounds"));
		
		var charXML:Xml = character.buildXML([
			for (button in characterAnimsWindow.buttons.members)
				button.anim
		]);

		return "<!DOCTYPE codename-engine-character>\n" + Printer.print(charXML, true);
	}

	var clipboard:FlxPoint = FlxPoint.get();
	function _edit_copy_offset(_) {
		clipboard.copyFrom(character.animOffsets[character.getAnimName()]);
	}
	function _edit_paste_offset(_) {
		_set_offset(clipboard.x, clipboard.y);
	}

	function _edit_undo(_) {}
	function _edit_redo(_) {}

	function _edit_info(_)
		characterPropertiesWindow.editCharacterInfoUI();
	function _edit_sprite(_) {}

	function _offsets_left(_) _change_offset(-1, 0);
	function _offsets_up(_) _change_offset(0, -1);
	function _offsets_down(_) _change_offset(0, 1);
	function _offsets_right(_) _change_offset(1, 0);
	function _offsets_extra_left(_) _change_offset(-5, 0);
	function _offsets_extra_up(_) _change_offset(0, -5);
	function _offsets_extra_down(_) _change_offset(0, 5);
	function _offsets_extra_right(_) _change_offset(5, 0);

	function _offsets_drag_offsets_mouse(t) {
		t.icon = (Options.characterDragging = !Options.characterDragging) ? 1 : 0;
	}

	function _offsets_clear(_) {
		for (anim => button in characterAnimsWindow.animButtons)
			button.changeOffset(0, 0);
	}

	function _change_offset(x:Float, y:Float) {
		_set_offset(
			character.animOffsets[character.getAnimName()].x - x,
			character.animOffsets[character.getAnimName()].y - y
		);
	}

	function _set_offset(x:Float, y:Float) {
		characterAnimsWindow.animButtons.get(character.getAnimName()).changeOffset(
			FlxMath.roundDecimal(x, 2), FlxMath.roundDecimal(y, 2)
		);
	}

	function buildStagesUI() {
		var stageTopButton:UITopMenuButton = topMenuSpr == null ? null : cast topMenuSpr.members[stageIndex];
		var newChilds:Array<UIContextMenuOption> = [];

		var stageFileList = Stage.getList(true);
		if (stageFileList.length == 0) stageFileList = Stage.getList(false);

		for (stage in stageFileList)
			newChilds.push({
				label: 'Use "$stage"?',
				icon: currentStage == stage ? 1 : 0,
				onSelect: (_) -> {changeStage(stage);}
			});

		newChilds.push(null);
		newChilds.push({
			label: "Use No Stage?",
			icon: currentStage == null ? 1 : 0,
			onSelect: (_) -> {changeStage(null);}
		});

		if (stageTopButton != null) stageTopButton.contextMenu = newChilds;
		return newChilds;
	}

	function changeStage(__stage:String) {
		if (stage != null) {
			if (stage.characterPoses.exists(stagePosition))
				stage.characterPoses[stagePosition].revertCharacter(character);

			for (sprite in stageSprites) {
				remove(sprite);
				sprite.destroy();
			}
			stageSprites.clear();

			stage.destroy();
			stage = null;
		}
		remove(character);

		if (__stage == null) {
			updateStagePositions([]);
			changeStagePosition("NONE");

			add(character);
		} else {
			stage = new Stage(__stage, this, false);
			stage.onAddSprite = (sprite:FlxBasic) -> {
				sprite.cameras = [charCamera];
				stageSprites.push(sprite);
			};

			stage.loadXml(stage.stageXML, true);
			add(stage);

			stagePosition = character.playerOffsets || character.isPlayer ? "BOYFRIEND" : "DAD";
			updateStagePositions([
				for (pose in stage.characterPoses.keys())
					pose.toUpperCase()
			]);

			changeStagePosition(stagePosition);
			changeCharacterDesginedAs(stagePosition.toUpperCase() == "BOYFRIEND");
		}

		currentStage = __stage;
		buildStagesUI();
	}

	function updateStagePositions(stagePositions:Array<String>) @:privateAccess {
		if (stage != null && stagePositions.length > 0) {
			characterPropertiesWindow.testAsDropDown.items =
				UIDropDown.getItems(characterPropertiesWindow.testAsDropDown.options = stagePositions);
		} else
			characterPropertiesWindow.testAsDropDown.items =
				UIDropDown.getItems(characterPropertiesWindow.testAsDropDown.options = ["NONE"]);
	}

	public function changeStagePosition(position:String) {
		if (stage != null && position != "NONE") {
			if (stage.characterPoses.exists(stagePosition))
				stage.characterPoses[stagePosition].revertCharacter(character);
	
			stagePosition = position.toLowerCase();
			remove(character);
	
			if (stage.characterPoses.exists(stagePosition))
				stage.applyCharStuff(character, stagePosition, 0);
			_animation_play(null);
		} else
			stagePosition = position.toLowerCase();

		characterPropertiesWindow.testAsDropDown.index = characterPropertiesWindow.testAsDropDown.options.indexOf(stagePosition.toUpperCase());
		characterPropertiesWindow.testAsDropDown.label.text = stagePosition.toUpperCase();
	}

	public function changeCharacterDesginedAs(player:Bool) @:privateAccess {
		if (stage == null) {
			changeCharacterIsPlayer(player);
			return;
		}

		if (stage.characterPoses.exists(stagePosition))
			stage.characterPoses[stagePosition].revertCharacter(character);

		changeCharacterIsPlayer(player);
		remove(character);

		if (stage.characterPoses.exists(stagePosition))
			stage.applyCharStuff(character, stagePosition, 0);
		_animation_play(null);

		characterPropertiesWindow.designedAsDropDown.index = characterPropertiesWindow.designedAsDropDown.options.indexOf(player ? "BOYFRIEND" : "DAD");
		characterPropertiesWindow.designedAsDropDown.label.text = player ? "BOYFRIEND" : "DAD";
	}

	public function changeCharacterIsPlayer(player:Bool) @:privateAccess {
		if (character.__swappedLeftRightAnims)
			character.swapLeftRightAnimations();
		if (character.isPlayer) 
			character.flipX = !character.__baseFlipped;

		character.isPlayer = player;
		character.fixChar(false, false);
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

	function _view_character_show_hitbox(t) {
		t.icon = (Options.characterHitbox = !Options.characterHitbox) ? 1 : 0;
		characterGizmo.boxGizmo = Options.characterHitbox;
	}

	function _view_character_show_camera(t) {
		t.icon = (Options.characterCamera = !Options.characterCamera) ? 1 : 0;
		characterGizmo.cameraGizmo = Options.characterCamera;
	}

	function _view_character_show_axis(t) {
		t.icon = (Options.characterAxis = !Options.characterAxis) ? 1 : 0;
		axisGizmo.visible = Options.characterAxis;
	}

	function _view_focus_character(_) {
		if (character == null) return;

		var characterMidpoint:FlxPoint = character.getMidpoint();
		characterMidpoint.x -= (FlxG.width/2)-character.globalOffset.x;
		characterMidpoint.y -= (FlxG.height/2)-character.globalOffset.y;
		_nextScroll.set(characterMidpoint.x, characterMidpoint.y);
		characterMidpoint.put();
	}

	var zoom(default, set):Float = 0;
	var __camZoom(default, set):Float = 1;
	function set_zoom(val:Float) {
		return zoom = CoolUtil.bound(val, -3.5, 1.75); // makes zooming not lag behind when continuing scrolling
	}
	function set___camZoom(val:Float) {
		return __camZoom = CoolUtil.bound(val, 0.1, 3);
	}

	function _animation_play(_) {
		if (character.getNameList().length != 0)
			playAnimation(character.getAnimName());
	}

	function _animation_stop(_) {
		if (character.getNameList().length != 0)
			character.stopAnimation();
	}

	function _animation_up(_)
		playAnimation(
			characterAnimsWindow.animsList[
				FlxMath.wrap(
					characterAnimsWindow.animsList.indexOf(characterFakeAnim) - 1, 
					0, characterAnimsWindow.animsList.length-1
			)]
		);
	function _animation_down(_)
		playAnimation(
			characterAnimsWindow.animsList[FlxMath.wrap(
					characterAnimsWindow.animsList.indexOf(characterFakeAnim) + 1, 
					0, characterAnimsWindow.animsList.length-1
			)]
		);

	// The animation thats playing regardless if its valid or not
	public var characterFakeAnim:String = "";
	public function playAnimation(anim:String) {
		characterFakeAnim = anim;
		if (characterAnimsWindow.animButtons[anim] != null && characterAnimsWindow.animButtons[anim].valid) {
			character.playAnim(anim, true);
			character.colorTransform.redMultiplier = character.colorTransform.greenMultiplier = character.colorTransform.blueMultiplier = character.colorTransform.alphaMultiplier = 1;
			character.colorTransform.redOffset = character.colorTransform.greenOffset = character.colorTransform.blueOffset = character.colorTransform.alphaOffset = 0;
		} else {
			var validAnimation:String = characterAnimsWindow.findValid();
			if (validAnimation != null) character.playAnim(validAnimation, true);
			_animation_stop(null);
			character.colorTransform.color = 0xFFEF0202;
		}

		for(i in characterAnimsWindow.buttons.members)
			i.alpha = i.anim == anim ? 1 : 0.25;
	}
	#end
}