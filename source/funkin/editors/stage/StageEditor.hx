package funkin.editors.stage;

import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import funkin.backend.system.framerate.Framerate;
import funkin.backend.utils.XMLUtil.AnimData;
import funkin.editors.stage.elements.*;
import funkin.editors.ui.UIContextMenu.UIContextMenuOption;
import funkin.game.Character;
import funkin.game.Stage;
import haxe.xml.Access;
import haxe.xml.Printer;

using funkin.backend.utils.MatrixUtil;

class StageEditor extends UIState {
	static var __stage:String;
	public var stage:Stage;

	public static var instance(get, null):StageEditor;

	private static inline function get_instance()
		return FlxG.state is StageEditor ? cast FlxG.state : null;

	public var topMenu:Array<UIContextMenuOption>;
	public var topMenuSpr:UITopMenu;

	public var uiGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
	public var stageSpritesWindow:UIButtonList<StageElementButton>;
	public var stageSprites:FlxTypedGroup<StageSprite> = new FlxTypedGroup<StageSprite>();

	public var xmlMap:Map<FlxObject, Access> = new Map<FlxObject, Access>();

	public var chars:Array<Character> = [];
	public var charMap:Map<String, Character> = [];

	public var stageCamera:FlxCamera;
	public var guideCamera:FlxCamera;
	public var uiCamera:FlxCamera;

	public static var selection:Selection;

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

			//var t = new StageSprite(name, sprite);
			//t.node = node;
			//stageSprites.add(t);

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

		add(stageSprites);

		for(spr in order) {

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
		stageSpritesWindow.addButton.callback = () -> {
			// TODO: implement this
		}
		for (i=>sprite in order) {
			var xml = xmlMap.get(sprite);
			if(xml != null) {
				if(sprite is FunkinSprite) {
					var type = sprite.extra.get(exID("type"));
					stageSpritesWindow.add((type == "box" || type == "solid") ? new StageSolidButton(0,0, sprite, xml) : new StageSpriteButton(0,0, sprite, xml));
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

		if ((!stageSpritesWindow.hovered && !stageSpritesWindow.dragging) && !topMenuSpr.hovered) {
			if (FlxG.mouse.wheel != 0) {
				zoom += 0.25 * FlxG.mouse.wheel;
				updateZoom();
			}

			//if (FlxG.mouse.justReleasedRight) {
			//	closeCurrentContextMenu();
			//	openContextMenu(topMenu[2].childs);
			//}
			if (FlxG.mouse.pressed) {
				nextScroll.set(nextScroll.x - FlxG.mouse.deltaScreenX, nextScroll.y - FlxG.mouse.deltaScreenY);
				currentCursor = HAND;
			} else
				currentCursor = ARROW;
		} else if (!FlxG.mouse.pressed)
			currentCursor = ARROW;

		stageCamera.scroll.set(
			lerp(stageCamera.scroll.x, nextScroll.x, 0.35),
			lerp(stageCamera.scroll.y, nextScroll.y, 0.35)
		);

		stageCamera.zoom = lerp(stageCamera.zoom, __camZoom, 0.125);

		WindowUtils.prefix = undos.unsaved ? "* " : "";
		SaveWarning.showWarning = undos.unsaved;
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

		if(dot == null) {
			dot = new FlxSprite().makeGraphic(10, 10, FlxColor.RED);
			dot.camera = stageCamera;
			dot.forceIsOnScreen = true;
		}
		for(sprite in stage.stageSprites) {
			if(sprite.visible && sprite.isOnScreen(stageCamera)) {
				@:privateAccess if(sprite._frame == null) continue;
				drawGuides(sprite);
			}
		}
		if(showCharacters) {
			for(char in chars) {
				if(char.visible && char.isOnScreen(stageCamera)) {
					@:privateAccess if(char._frame == null) continue;
					drawGuides(char);
				}
			}
		}
	}

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

		for(corner in corners) {
			drawDot(corner.x, corner.y);
			corner.put();
		}

		drawLine(corners[0], corners[1]); // tl - tr
		drawLine(corners[0], corners[2]); // tl - bl
		drawLine(corners[1], corners[3]); // tr - br
		drawLine(corners[2], corners[3]); // bl - br

		// reset hitbox to old values
		sprite.width = oldWidth;
		sprite.height = oldHeight;
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

@:forward abstract Selection(Array<StageSprite>) from Array<StageSprite> to Array<StageSprite> {
	public inline function new(?array:Array<StageSprite>)
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

class StageSprite extends UISprite {
	public var tracker:FlxObject;
	public var funkinTracker:FunkinSprite;
	public var node:Access;

	public var name:String;

	public var extra:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var scrollX:Float;
	public var scrollY:Float;
	public var scaleX:Float;
	public var scaleY:Float;
	public var zoomFactor:Float = 1; // TODO: implement this
	public var skewX:Float;
	public var skewY:Float;
	public var spriteAnimType:XMLAnimType;

	public var skipNegativeBeats:Bool = false;
	public var beatInterval:Int = 0;
	public var beatOffset:Int = 0;

	public var lowMemory:Bool;
	public var highMemory:Bool;

	public var selected:Bool = false;
	public var draggable:Bool = false;

	public function new(name:String, sprite:FlxObject) {
		super(x, y);
		this.name = name;
		this.tracker = sprite;

		scrollX = tracker.scrollFactor.x;
		scrollY = tracker.scrollFactor.y;
		if(tracker is FunkinSprite) {
			var tracker:FunkinSprite = cast tracker;
			scaleX = tracker.scale.x;
			scaleY = tracker.scale.y;
			funkinTracker = tracker;
		}
		else if (tracker is StageCharPos) {
			var tracker:StageCharPos = cast tracker;
			var char:Character = tracker.extra.get(StageEditor.exID("char"));
			scaleX = tracker.scale.x;
			scaleY = tracker.scale.y;
			funkinTracker = char;
		}

		lowMemory = node.x.parent.nodeName == "low-memory";
		highMemory = node.x.parent.nodeName == "high-memory";

		if(funkinTracker != null) {
			skewX = funkinTracker.skew.x;
			skewY = funkinTracker.skew.y;
			alpha = funkinTracker.alpha;
			spriteAnimType = funkinTracker.spriteAnimType;
			antialiasing = funkinTracker.antialiasing;
			width = funkinTracker.width;
			height = funkinTracker.height;
			color = funkinTracker.color;

			skipNegativeBeats = funkinTracker.skipNegativeBeats;
			beatInterval = funkinTracker.beatInterval;
			beatOffset = funkinTracker.beatOffset;
		}

	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		if (tracker.exists) {
			tracker.x = x;
			tracker.y = y;
			tracker.scrollFactor.set(scrollX, scrollY);
			if(tracker is FlxSprite) {
				var tracker:FlxSprite = cast tracker;
			}
			else if (tracker is StageCharPos) {
				var tracker:StageCharPos = cast tracker;
				tracker.skewX = skewX;
				tracker.skewY = skewY;
			}

			if(funkinTracker != null) {
				funkinTracker.scale.set(scaleX, scaleY);
				funkinTracker.skew.set(skewX, skewY);
				funkinTracker.alpha = alpha;
				funkinTracker.spriteAnimType = spriteAnimType;
				funkinTracker.antialiasing = antialiasing;
				funkinTracker.width = width;
				funkinTracker.height = height;

				funkinTracker.skipNegativeBeats = skipNegativeBeats;
				funkinTracker.beatInterval = beatInterval;
				funkinTracker.beatOffset = beatOffset;

				funkinTracker.color = color;
			}
		}
	}

	public function handleSelection(selectionBox:UISliceSprite):Bool {
		return false;
	};
	public function handleDrag(change:FlxPoint):Void {

	};
}