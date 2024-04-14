package funkin.editors.stage;

import lime.ui.MouseCursor;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import funkin.backend.system.framerate.Framerate;
import funkin.backend.utils.XMLUtil.AnimData;
import funkin.editors.stage.elements.*;
import funkin.editors.ui.UIContextMenu.UIContextMenuOption;
import funkin.game.Character;
import funkin.game.Stage;
import haxe.xml.Access;
import haxe.xml.Printer;
import openfl.ui.Mouse;

using funkin.backend.utils.MatrixUtil;

class StageEditor extends UIState {
	static var __stage:String;
	public var stage:Stage;

	private var _point:FlxPoint = new FlxPoint();

	public static var instance(get, null):StageEditor;

	private static inline function get_instance()
		return FlxG.state is StageEditor ? cast FlxG.state : null;

	public var topMenu:Array<UIContextMenuOption>;
	public var topMenuSpr:UITopMenu;

	public var uiGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
	public var stageSpritesWindow:UIButtonList<StageElementButton>;

	public var xmlMap:Map<FlxObject, Access> = new Map<FlxObject, Access>();

	public var chars:Array<Character> = [];
	public var charMap:Map<String, Character> = [];

	public var stageCamera:FlxCamera;
	public var guideCamera:FlxCamera;
	public var uiCamera:FlxCamera;

	public var selection:Selection = new Selection();
	public var mouseMode:StageEditorMouseMode = NONE;
	public var mousePoint:FlxPoint = new FlxPoint();
	public var clickPoint:FlxPoint = new FlxPoint();
	public var storedPos:FlxPoint = new FlxPoint();
	public var storedScale:FlxPoint = new FlxPoint();

	public var showOutlines:Bool = true;
	public var showCharacters:Bool = true;

	public var undos:UndoList<StageChange> = new UndoList<StageChange>();

	public inline static function exID(id:String) {
		return "stageEditor." + id;
	}

	public function new(stage:String) {
		super();
		if (stage != null) __stage = stage;
	}

	public override function create() {
		super.create();

		WindowUtils.suffix = " (Stage Editor)";
		SaveWarning.selectionClass = StageSelection;
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
						label: "Focus Dad",
						//keybind: [CONTROL, NUMPADZERO],
						onSelect: _view_focusdad
					},
					{
						label: "Focus Gf",
						//keybind: [CONTROL, NUMPADZERO],
						onSelect: _view_focusgf
					},
					{
						label: "Focus BF",
						//keybind: [CONTROL, NUMPADZERO],
						onSelect: _view_focusbf
					},
					// TODO: add support for custom character focus
				]
			},
			{
				label: "Editor",
				childs: [
					{
						label: "Show Outlines",
						//keybind: [CONTROL, NUMPADPLUS],
						onSelect: _editor_showOutlines,
						icon: showOutlines ? 1 : 0
					},
					{
						label: "Show Characters",
						//keybind: [CONTROL, NUMPADMINUS],
						onSelect: _editor_showCharacters,
						icon: showCharacters ? 1 : 0
					}
				]
			},
		];

		stageCamera = FlxG.camera;

		guideCamera = new FlxCamera();
		guideCamera.bgColor = 0;

		uiCamera = new FlxCamera();
		uiCamera.bgColor = 0;

		FlxG.cameras.add(guideCamera, false);
		FlxG.cameras.add(uiCamera, false);

		// Load from xml
		var order:Array<Dynamic> = [];
		stage = new Stage(__stage, this, false);
		stage.onXMLLoaded = function(xml:Access, elems:Array<Access>) {
			return elems;
		}
		stage.onNodeFinished = function(node:Access, sprite:Dynamic) {
			if(sprite is FlxSprite) {
				sprite.moves = false;
			}
			if (sprite is FunkinSprite) {
				sprite.animEnabled = false;
				//sprite.zoomFactorEnabled = false;
			}
		}
		stage.onNodeLoaded = function(node:Access, sprite:Dynamic):Dynamic {
			var name = "";
			if(sprite is FlxSprite) {
				//sprite.forceIsOnScreen = true; // hack
			}
			if(sprite is FunkinSprite) {
				var sprite:FunkinSprite = cast sprite;
				name = sprite.name;
				sprite.extra.set(exID("node"), node);
				sprite.extra.set(exID("type"), node.name);
				sprite.extra.set(exID("imageFile"), '${node.getAtt("sprite").getDefault(sprite.name)}');
				//sprite.active = false;
			}
			if(sprite is StageCharPos) {
				var charPos:StageCharPos = cast sprite;
				// TODO: fix default characters not being added
				var charName = switch(charPos.name) {
					case "boyfriend": "bf";
					case "girlfriend": "gf";
					default: charPos.name;
				}
				name = charPos.name;
				var char = new Character(0,0, charName, stage.isCharFlipped(charPos.name, charName == "bf"), true);
				char.debugMode = true;
				// Play first anim, and make it the last frame
				var animToPlay = char.getAnimOrder()[0];
				char.playAnim(animToPlay, true, NONE);
				var lastIndx = (char.animateAtlas != null) ?
					char.animateAtlas.anim.length - 1 :
					char.animation.curAnim.numFrames - 1;
				char.playAnim(animToPlay, true, NONE, false, lastIndx);
				char.stopAnimation();

				// Add it to the stage
				char.visible = true;
				char.alpha = 0.5;
				char.extra.set(exID("node"), node);
				char.extra.set(exID("pos"), charPos);
				charPos.extra.set(exID("char"), char);
				chars.push(char);
			}
			order.push(sprite);
			xmlMap.set(sprite, node);

			return sprite;
		}
		stage.loadXml(stage.stageXML, true);
		add(stage);

		for(char in chars) {
			var charPos = char.extra.get(exID("pos"));
			var node = char.extra.get(exID("node"));

			stage.applyCharStuff(char, charPos.name, 0);
			charMap[charPos.name] = char;
		}

		setZoom(stage.defaultZoom);

		topMenuSpr = new UITopMenu(topMenu);
		topMenuSpr.cameras = uiGroup.cameras = [uiCamera];

		final margin = 22;
		final width = 470;
		final TOP_MENU_HEIGHT = 25;
		var buttonSize:FlxPoint = FlxPoint.get(width-margin*2, 32);
		stageSpritesWindow = new UIButtonList<StageElementButton>(Std.int(FlxG.width - width), TOP_MENU_HEIGHT, width, Std.int(FlxG.height - TOP_MENU_HEIGHT), "Stage Sprites", buttonSize);
		stageSpritesWindow.collapsable = true;
		stageSpritesWindow.middleAlpha = 0.5;
		stageSpritesWindow.bottomAlpha = 0.5;
		stageSpritesWindow.addButton.callback = () -> {
			// TODO: implement this
		}
		for (i=>sprite in order) {
			var xml = xmlMap.get(sprite);
			if(xml != null) {
				if(sprite is FunkinSprite) {
					var type = sprite.extra.get(exID("type"));
					var button:StageElementButton = (type == "box" || type == "solid") ? new StageSolidButton(0,0, sprite, xml) : new StageSpriteButton(0,0, sprite, xml);
					sprite.extra.set(exID("button"), button);
					stageSpritesWindow.add(button);
				}
				else if(sprite is StageCharPos) {
					var char = charMap[sprite.name];
					var button = new StageCharacterButton(0,0, sprite, xml);
					char.extra.set(exID("button"), button);
					stageSpritesWindow.add(button);
				}
			}
		}
		uiGroup.add(stageSpritesWindow);

		add(topMenuSpr);
		add(uiGroup);

		if(Framerate.isLoaded) {
			Framerate.fpsCounter.alpha = 0.4;
			Framerate.memoryCounter.alpha = 0.4;
			Framerate.codenameBuildField.alpha = 0.4;
		}

		//DiscordUtil.call("onEditorLoaded", ["Stage Editor", __stage]);
	}

	override function destroy() {
		super.destroy();
		nextScroll = FlxDestroyUtil.destroy(nextScroll);
		if(Framerate.isLoaded) {
			Framerate.fpsCounter.alpha = 1;
			Framerate.memoryCounter.alpha = 1;
			Framerate.codenameBuildField.alpha = 1;
		}
	}

	//private var movingCam:Bool = false;
	//private var camDragSpeed:Float = 1.2;

	private var nextScroll:FlxPoint = FlxPoint.get(0,0);

	public override function update(elapsed:Float) {
		super.update(elapsed);

		if (true) {
			if(FlxG.keys.justPressed.ANY)
				UIUtil.processShortcuts(topMenu);
		}

		//if (character != null)
		//	characterPropertiresWindow.characterInfo.text = '${character.getNameList().length} Animations\nFlipped: ${character.flipX}\nSprite: ${character.sprite}\nAnim: ${character.getAnimName()}\nOffset: (${character.frameOffset.x}, ${character.frameOffset.y})';

		currentCursor = ARROW;

		if ((!stageSpritesWindow.hovered && !stageSpritesWindow.dragging) && !topMenuSpr.hovered) {
			if (FlxG.mouse.wheel != 0) {
				zoom += 0.25 * FlxG.mouse.wheel;
				updateZoom();
			}

			/*if(FlxG.mouse.justPressed) {
				var bounds:Array<FlxRect> = [];
				var sprites = stageSpritesWindow.buttons.members.map((o) -> o.getSprite()).filter((o) -> o != null && o.animateAtlas == null);
				for(sprite in sprites) {
					if(sprite is FunkinSprite) {
						var sprite:FunkinSprite = cast sprite;
						if(sprite.extra.exists(exID("bounds"))) {
							bounds.push(cast(sprite.extra.get(exID("bounds")), FlxRect));
						}
					}
				}

				// sort by area
				bounds.sort((a, b) -> FlxSort.byValues(FlxSort.ASCENDING, a.width * a.height, b.width * b.height));

				Logs.trace("------------------------");
				for(bounds in bounds) {
					Logs.trace(bounds.width + "x" + bounds.height);
				}
			}*/

			/*if(FlxG.mouse.justPressed) {
				//var sprites = Lambda.array(stage.stageSprites);
				var sprites = stageSpritesWindow.buttons.members.map((o) -> o.getSprite()).filter((o) -> o != null && o.animateAtlas == null);
				trace(sprites.map((o) -> cast(o, FunkinSprite).name));
				var length = sprites.length;
				// Reset selected sprites
				for(i in 0...length) {
					var sprite = sprites[i];
					if(sprite is FunkinSprite) {
						var sprite:FunkinSprite = cast sprite;
						sprite.extra.set(exID("selected"), false);
					}
				}
				for(i in 0...length) {
					var idx = length - i - 1;
					var sprite = sprites[idx];
					if(sprite is FunkinSprite) {
						var sprite:FunkinSprite = cast sprite;
						if(!sprite.extra.exists(exID("bounds"))) continue;
						trace(idx, sprite.name);
						var bounds = cast(sprite.extra.get(exID("bounds")), FlxRect);
						var pos = FlxG.mouse.getWorldPosition(stageCamera, _point);
						trace(sprite.name, bounds, pos);
						if(bounds.containsPoint(pos)) {
							sprite.extra.set(exID("selected"), true);
							trace("Selected " + sprite.name);
							break;
						}
					}
				}
			}*/

			for(sprite in selection) {
				if(sprite is FunkinSprite) {
					handleSelection(cast sprite);
				}
			}

			//if (FlxG.mouse.justReleasedRight) {
			//	closeCurrentContextMenu();
			//	openContextMenu(topMenu[2].childs);
			//}

			if (FlxG.mouse.pressed && mouseMode == NONE) {
				nextScroll.set(nextScroll.x - FlxG.mouse.deltaScreenX, nextScroll.y - FlxG.mouse.deltaScreenY);
				currentCursor = HAND;
			}
		}/* else if (!FlxG.mouse.pressed)
			currentCursor = ARROW;*/

		stageCamera.scroll.set(
			lerp(stageCamera.scroll.x, nextScroll.x, 0.35),
			lerp(stageCamera.scroll.y, nextScroll.y, 0.35)
		);

		stageCamera.zoom = lerp(stageCamera.zoom, __camZoom, 0.125);

		WindowUtils.prefix = undos.unsaved ? "* " : "";
		SaveWarning.showWarning = undos.unsaved;
	}

	public function selectSprite(_sprite:FunkinSprite) {
		selection = new Selection([]);
		var sprites = stageSpritesWindow.buttons.members.map((o) -> o.getSprite()).filter((o) -> o != null);// && o.animateAtlas == null);
		for(sprite in sprites) {
			if(sprite is FunkinSprite) {
				var sprite:FunkinSprite = cast sprite;
				sprite.extra.set(exID("selected"), false);
				sprite.extra.get(exID("button")).selected = false;
			}
		}
		if(_sprite is FunkinSprite) {
			var sprite:FunkinSprite = cast _sprite;
			sprite.extra.set(exID("selected"), true);
			sprite.extra.get(exID("button")).selected = true;
			selection = new Selection([sprite]);
			Logs.trace("Selected " + sprite.name);
		}
	}

	// TOP MENU OPTIONS
	#if REGION
	function _file_exit(_) {
		if (undos.unsaved) SaveWarning.triggerWarning();
		else FlxG.switchState(new StageSelection());
	}

	function _file_new(_) {
	}

	function _file_save(_) {
		#if sys
		CoolUtil.safeSaveFile(
			'${Paths.getAssetsRoot()}/data/stages/${stage.stageName}.xml',
			buildStage()
		);
		undos.save();
		#else
		_file_saveas(_);
		#end
	}

	function _file_saveas(_) {
		openSubState(new SaveSubstate(buildStage(), {
			defaultSaveFile: '${stage.stageName}.xml'
		}));
		undos.save();
	}

	function buildStage():String {
		/*if (character.isPlayer != character.playerOffsets) {
			character.switchOffset('singLEFT', 'singRIGHT');
			character.switchOffset('singLEFTmiss', 'singRIGHTmiss');
		}
		var charXML:Xml = character.buildXML([
			for (button in characterAnimsWindow.buttons.members)
				button.anim
		]);

		// clean
		if (charXML.exists("gameOverChar") && character.gameOverCharacter == "bf-dead") charXML.remove("gameOverChar");
		if (charXML.exists("camx") && character.cameraOffset.x == 0) charXML.remove("camx");
		if (charXML.exists("camy") &&  character.cameraOffset.y == 0) charXML.remove("camy");
		if (charXML.exists("holdTime") && character.holdTime == 4) charXML.remove("holdTime");
		if (charXML.exists("flipX") && !character.flipX) charXML.remove("flipX");
		if (charXML.exists("scale") && character.scale.x == 1) charXML.remove("scale");
		if (charXML.exists("antialiasing") && character.antialiasing) charXML.remove("antialiasing");*/

		return "<!DOCTYPE codename-engine-stage>\n";// + Printer.print(charXML, true);
	}

	/*function _edit_undo(_) {
		var undo = undos.undo();
		switch(undo) {
			case null:
				// do nothing
			case CEditInfo(oldInfo, newInfo):
				editInfo(oldInfo, false);
			case CCreateAnim(animID, animData):
				deleteAnim(animData.name, false);
			case CEditAnim(name, oldData, animData):
				editAnim(name, oldData, false);
			case CDeleteAnim(animID, animData):
				createAnim(animData, animID, false);
			case CChangeOffset(name, change):
				changeOffset(name, change * -1, false);
			case CResetOffsets(oldOffsets):
				for (anim => offsets in oldOffsets) {
					character.animOffsets.set(anim, offsets.clone());
					ghosts.setOffsets(anim, offsets.clone());
				}

				for (charButton in characterAnimsWindow.buttons.members)
					charButton.updateInfo(charButton.anim, character.getAnimOffset(charButton.anim), ghosts.animGhosts[charButton.anim].visible);

				changeOffset(character.getAnimName(), FlxPoint.get(0, 0), false); // apply da new offsets
		}
	}

	function _edit_redo(_) {
		var redo = undos.redo();
		switch(redo) {
			case null:
				// do nothing
			case CEditInfo(oldInfo, newInfo):
				editInfo(newInfo, false);
			case CCreateAnim(animID, animData):
				createAnim(animData, animID, false);
			case CEditAnim(name, oldData, animData):
				editAnim(oldData.name, animData, false);
			case CDeleteAnim(animID, animData):
				deleteAnim(animData.name, false);
			case CChangeOffset(name, change):
				changeOffset(name, change, false);
			case CResetOffsets(oldOffsets):
				clearOffsets(false);
		}
	}*/

	public function editInfoWithUI() {
		FlxG.state.openSubState(new StageInfoScreen(stage, (_) -> {
			if (_ != null) editInfo(_);
		}));
	}

	public function editInfo(newInfo:Xml, addtoUndo:Bool = true) {
		/*var oldInfo = stage.buildXML();
		stage.applyXML(new Access(newInfo));

		if (addtoUndo)
			undos.addToUndo(CEditInfo(oldInfo, newInfo));*/
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
		updateZoom();
	}
	function _view_zoomout(_) {
		zoom -= 0.25;
		updateZoom();
	}
	function _view_zoomreset(_) {
		setZoom(stage.defaultZoom);
	}

	inline function updateZoom() {
		__camZoom = Math.pow(2, zoom);
	}

	inline function calculateZoom(zoom:Float) {
		return Math.log(zoom) / Math.log(2);
	}

	inline function setZoom(_zoom:Float) {
		zoom = calculateZoom(__camZoom = _zoom);
	}

	function _view_focusdad(_) {
		focusCharacter(charMap["dad"]);
	}
	function _view_focusgf(_) {
		focusCharacter(charMap["girlfriend"]);
	}
	function _view_focusbf(_) {
		focusCharacter(charMap["boyfriend"]);
	}

	function focusCharacter(char:Character) {
		var point = char.getCameraPosition();
		nextScroll.set(point.x - stageCamera.width / 2, point.y - stageCamera.height / 2);

		setZoom(stage.defaultZoom);
	}

	function _editor_showOutlines(t) {
		showOutlines = !showOutlines;
		t.icon = showOutlines ? 1 : 0;
	}

	function _editor_showCharacters(t) {
		showCharacters = !showCharacters;
		t.icon = showCharacters ? 1 : 0;
		for(char in chars) {
			var button:StageCharacterButton = char.extra.get(exID("button"));
			button.isHidden = !showCharacters;
			button.updateInfo(button.charPos);
		}
	}
	#end

	override function draw() {
		super.draw();

		if(!showOutlines) return;
		mousePoint = FlxG.mouse.getWorldPosition(stageCamera, mousePoint);
		if(dot == null) {
			dot = new FlxSprite().makeGraphic(30, 30, FlxColor.WHITE);
			dot.camera = stageCamera;
			dot.forceIsOnScreen = true;
		}
		for(sprite in selection) {
			if(sprite is FunkinSprite) {
				@:privateAccess if(sprite._frame == null) continue;
				drawGuides(cast sprite);
			}
		}
	}

	var lineColor = 0xFFb794b6;
	var circleColor = 0xFF99a8f2;

	function drawGuides(sprite:FlxSprite) {
		var oldWidth = sprite.width;
		var oldHeight = sprite.height;
		var oldOffset = sprite.offset.clone(FlxPoint.weak());
		var oldOrigin = sprite.origin.clone(FlxPoint.weak());
		sprite.updateHitbox();
		sprite.offset.copyFrom(oldOffset);
		sprite.origin.copyFrom(oldOrigin);

		var corners = sprite.getMatrixPosition([
			// corners
			FlxPoint.get(0, 0),
			FlxPoint.get(1, 0),
			FlxPoint.get(0, 1),
			FlxPoint.get(1, 1),
			// edges
			FlxPoint.get(0, 0.5),
			FlxPoint.get(1, 0.5),
			FlxPoint.get(0.5, 1),
			FlxPoint.get(0.5, 0),
			// center
			//FlxPoint.get(0.5, 0.5)
		], sprite.camera, sprite.frameWidth, sprite.frameHeight);

		//Logs.trace("Guide at " + corners[0].x + ", " + corners[0].y + " sprite at " + sprite.x + ", " + sprite.y);

		if(sprite is FunkinSprite) {
			var sprite:FunkinSprite = cast sprite;
			var maxX = Math.max(Math.max(corners[0].x, corners[1].x), Math.max(corners[2].x, corners[3].x));
			var maxY = Math.max(Math.max(corners[0].y, corners[1].y), Math.max(corners[2].y, corners[3].y));
			var minX = Math.min(Math.min(corners[0].x, corners[1].x), Math.min(corners[2].x, corners[3].x));
			var minY = Math.min(Math.min(corners[0].y, corners[1].y), Math.min(corners[2].y, corners[3].y));

			if(!sprite.extra.exists(exID("bounds"))) {
				sprite.extra.set(exID("bounds"), new FlxRect());
			}
			cast(sprite.extra.get(exID("bounds")), FlxRect).set(minX, minY, maxX - minX, maxY - minY);
		}
		var funkinSprite = sprite is FunkinSprite ? cast(sprite, FunkinSprite) : null;

		if(funkinSprite != null) {
			if(funkinSprite.extra.exists(exID("buttonBoxes"))) {
				var oldButtonBoxes:Array<FlxPoint> = cast funkinSprite.extra.get(exID("buttonBoxes"));
				if(oldButtonBoxes != null) {
					for(point in oldButtonBoxes) {
						point.put();
					}
				}
			}
		}
		var buttonBoxes = [];
		if(funkinSprite != null) {
			funkinSprite.extra.set(exID("buttonBoxes"), buttonBoxes);
		}

		dot.color = lineColor;

		drawLine(corners[0], corners[1]); // tl - tr
		drawLine(corners[0], corners[2]); // tl - bl
		drawLine(corners[1], corners[3]); // tr - br
		drawLine(corners[2], corners[3]); // bl - br
		// cross
		//drawLine(corners[0], corners[3]); // tl - br
		//drawLine(corners[1], corners[2]); // tr - bl

		dot.color = circleColor;

		for(corner in corners) {
			drawDot(corner.x, corner.y);
			buttonBoxes.push(corner);
		}

		if(funkinSprite == null) {
			for(corner in buttonBoxes) {
				corner.put();
			}
		}

		// reset hitbox to old values
		sprite.width = oldWidth;
		sprite.height = oldHeight;
	}

	var edges:Array<StageEditorEdge> = [
		//// corners
		TOP_LEFT, //FlxPoint.get(0, 0),
		TOP_RIGHT, //FlxPoint.get(1, 0),
		BOTTOM_LEFT, //FlxPoint.get(0, 1),
		BOTTOM_RIGHT, //FlxPoint.get(1, 1),
		//// edges
		MIDDLE_LEFT, //FlxPoint.get(0, 0.5),
		MIDDLE_RIGHT, //FlxPoint.get(1, 0.5),
		BOTTOM_MIDDLE, //FlxPoint.get(0.5, 1),
		TOP_MIDDLE, //FlxPoint.get(0.5, 0),
	];

	function tryUpdateHitbox(sprite:FunkinSprite) {
		call("tryUpdateHitbox", [sprite]);
	}

	function handleSelection(sprite:FunkinSprite) {
		var buttonBoxes = sprite.extra.get(exID("buttonBoxes"));

		dotCheckSize = dot.frameWidth / 0.7/stageCamera.zoom; // basically adjust it to the zoom.

		if(FlxG.mouse.justPressed) {
			for(i=>edge in edges) {
				if(checkDot(buttonBoxes[i])) {
					mouseMode = switch(edge) {
						case TOP_LEFT: SCALE_TOP_LEFT;
						case TOP_MIDDLE: SCALE_TOP;
						case TOP_RIGHT: SCALE_TOP_RIGHT;
						case MIDDLE_LEFT: SCALE_LEFT;
						case MIDDLE_RIGHT: SCALE_RIGHT;
						case BOTTOM_LEFT: SCALE_BOTTOM_LEFT;
						case BOTTOM_MIDDLE: SCALE_BOTTOM;
						case BOTTOM_RIGHT: SCALE_BOTTOM_RIGHT;
						default: NONE;
					}
					Logs.trace("Clicked Dot: " + mouseMode.toString());
					mousePoint.copyTo(clickPoint);
					storedPos.set(sprite.x, sprite.y);
					storedScale.copyFrom(sprite.scale);
				}
			}
		}
		for(i=>edge in edges) {
			if(checkDot(buttonBoxes[i])) {
				currentCursor = switch(edge) {
					// RESIZE_NESW; //RESIZE_NS; //RESIZE_NWSE; //RESIZE_WE;
					case TOP_LEFT | BOTTOM_RIGHT: MouseCursor.RESIZE_NWSE;
					case TOP_MIDDLE | BOTTOM_MIDDLE: MouseCursor.RESIZE_NS;
					case TOP_RIGHT | BOTTOM_LEFT: MouseCursor.RESIZE_NESW;
					case MIDDLE_LEFT | MIDDLE_RIGHT: MouseCursor.RESIZE_WE;
					default: ARROW;
				}
				break;
			}
		}

		mouseMode = (FlxG.mouse.justReleased) ? NONE : mouseMode;
		if(mouseMode == NONE) return;
		var relative = clickPoint.subtractNew(mousePoint);
		// todo: make this origin based
		relative.rotateByDegrees(sprite.angle);
		call(mouseMode.toString(), [sprite, relative]);
		cast(sprite.extra.get(exID("button")), StageElementButton).updateInfo(sprite);
		relative.put();
	}

	var dotCheckSize:Float = 50;

	function checkDot(point:FlxPoint):Bool {
		var rect = new FlxRect(point.x - dotCheckSize/2, point.y - dotCheckSize/2, dotCheckSize, dotCheckSize);
		return rect.containsPoint(mousePoint);
	}

	inline function drawDot(x:Float, y:Float) {
		dot.setPosition(x, y);
		dot.scale.set(0.7/stageCamera.zoom, 0.7/stageCamera.zoom);
		dot.x -= dot.width / 2;
		dot.y -= dot.height / 2;
		dot.draw();
	}

	function drawLine(point1:FlxPoint, point2:FlxPoint) {
		var dx:Float = point2.x - point1.x;
		var dy:Float = point2.y - point1.y;

		var angle:Float = Math.atan2(dy, dx);
		var distance:Float = Math.sqrt(dx * dx + dy * dy);

		dot.setPosition(point1.x, point1.y);
		dot.angle = angle * FlxAngle.TO_DEG;
		dot.origin.set(0, dot.frameHeight / 2);
		dot.scale.x = distance / dot.frameWidth;
		dot.scale.y = 0.20/stageCamera.zoom;
		//dot.x -= dot.width / 2;
		dot.y -= dot.height / 2;
		dot.draw();
		// Reset the angle and scale
		dot.angle = 0;
		dot.scale.x = dot.scale.y = 1;
		dot.updateHitbox();
	}

	var dot:FlxSprite = null;
}

enum StageChange {
	CEditInfo(oldInfo:Xml, newInfo:Xml);
}

@:forward abstract Selection(Array<FunkinSprite>) from Array<FunkinSprite> to Array<FunkinSprite> {
	public inline function new(?array:Array<FunkinSprite>)
		this = array == null ? [] : array;

	// too lazy to put this in every for loop so i made it a abstract
	//public inline function loop(onNote:CharterNote->Void, ?onEvent:CharterEvent->Void, ?draggableOnly:Bool = true) {
	//	for (s in this) {
	//		if (s is CharterNote && onNote != null && (draggableOnly ? s.draggable: true))
	//			onNote(cast(s, CharterNote));
	//		else if (s is CharterEvent && onEvent != null && (draggableOnly ? s.draggable: true))
	//			onEvent(cast(s, CharterEvent));
	//	}
	//}
}

enum abstract StageEditorMouseMode(Int) {
	var NONE;

	var SCALE_LEFT;
	var SCALE_BOTTOM;
	var SCALE_TOP;
	var SCALE_RIGHT;
	var SCALE_TOP_LEFT;
	var SCALE_TOP_RIGHT;
	var SCALE_BOTTOM_LEFT;
	var SCALE_BOTTOM_RIGHT;

	var SKEW_LEFT;
	var SKEW_BOTTOM;
	var SKEW_TOP;
	var SKEW_RIGHT;

	var ROTATE;

	public function toString():String {
		return switch(cast this) {
			case NONE: "NONE";
			case SCALE_LEFT: "SCALE_LEFT";
			case SCALE_BOTTOM: "SCALE_BOTTOM";
			case SCALE_TOP: "SCALE_TOP";
			case SCALE_RIGHT: "SCALE_RIGHT";
			case SCALE_TOP_LEFT: "SCALE_TOP_LEFT";
			case SCALE_TOP_RIGHT: "SCALE_TOP_RIGHT";
			case SCALE_BOTTOM_LEFT: "SCALE_BOTTOM_LEFT";
			case SCALE_BOTTOM_RIGHT: "SCALE_BOTTOM_RIGHT";
			case SKEW_LEFT: "SKEW_LEFT";
			case SKEW_BOTTOM: "SKEW_BOTTOM";
			case SKEW_TOP: "SKEW_TOP";
			case SKEW_RIGHT: "SKEW_RIGHT";
			case ROTATE: "ROTATE";
		}
	}
}

enum abstract StageEditorEdge(Int) {
	var NONE;

	var TOP_LEFT;
	var TOP_MIDDLE;
	var TOP_RIGHT;
	var MIDDLE_LEFT;
	var MIDDLE_MIDDLE;
	var MIDDLE_RIGHT;
	var BOTTOM_LEFT;
	var BOTTOM_MIDDLE;
	var BOTTOM_RIGHT;

	function toString():String {
		return switch(cast this) {
			case NONE: "NONE";
			case TOP_LEFT: "TOP_LEFT";
			case TOP_MIDDLE: "TOP_MIDDLE";
			case TOP_RIGHT: "TOP_RIGHT";
			case MIDDLE_LEFT: "MIDDLE_LEFT";
			case MIDDLE_MIDDLE: "MIDDLE_MIDDLE";
			case MIDDLE_RIGHT: "MIDDLE_RIGHT";
			case BOTTOM_LEFT: "BOTTOM_LEFT";
			case BOTTOM_MIDDLE: "BOTTOM_MIDDLE";
			case BOTTOM_RIGHT: "BOTTOM_RIGHT";
		}
	}
}