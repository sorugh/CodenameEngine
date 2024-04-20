package funkin.editors.stage;

import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import funkin.backend.system.framerate.Framerate;
import funkin.backend.utils.XMLUtil.AnimData;
import funkin.editors.stage.elements.*;
import funkin.editors.stage.elements.StageSpriteButton.StageSpriteEditScreen;
import funkin.editors.ui.UIContextMenu.UIContextMenuOption;
import funkin.game.Character;
import funkin.game.Stage;
import haxe.xml.Access;
import haxe.xml.Printer;
import lime.ui.MouseCursor;
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
	//public var guideCamera:FlxCamera;
	public var uiCamera:FlxCamera;

	public var selection:Selection = new Selection();
	public var mouseMode:StageEditorMouseMode = NONE;
	public var mousePoint:FlxPoint = new FlxPoint();
	public var clickPoint:FlxPoint = new FlxPoint();
	public var storedPos:FlxPoint = new FlxPoint();
	public var storedScale:FlxPoint = new FlxPoint();
	public var storedSkew:FlxPoint = new FlxPoint();
	public var storedAngle:Float = 0;

	public var showCharacters:Bool = true;

	public static inline var SPRITE_WINDOW_WIDTH:Int = 400;
	public static inline var SPRITE_WINDOW_BUTTON_HEIGHT:Int = 64;

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
					/*{
						label: "Undo",
						keybind: [CONTROL, Z],
						onSelect: _edit_undo,
					},
					{
						label: "Redo",
						keybind: [CONTROL, SHIFT, Z],
						onSelect: _edit_redo,
					},
					null,*/
					{
						label: "Edit Stage Info",
						onSelect: (_) -> {
							openSubState(new UISoftcodedWindow(
								"layouts/stage/stageInfoScreen",
								[
									"winTitle" => "Editing Stage Info",
									"hasSaveButton" => true,
									"hasCloseButton" => true,
									"stage" => stage,
									"Stage" => Stage,
									"exID" => exID
								]
							));
						},
					}
				]
			},
			{
				label: "Select",
				childs: [
					{
						label: "All",
						keybind: [CONTROL, A],
						onSelect: (_) -> _select_all(_),
					},
					{
						label: "Deselect",
						keybind: [CONTROL, D],
						onSelect: (_) -> _select_deselect(_),
					},
					{
						label: "Inverse",
						keybind: [CONTROL, SHIFT, I],
						onSelect: (_) -> _select_inverse(_),
					},
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
						label: "Show Characters",
						//keybind: [CONTROL, NUMPADMINUS],
						onSelect: _editor_showCharacters,
						icon: showCharacters ? 1 : 0
					}
				]
			},
		];

		stageCamera = FlxG.camera;

		//guideCamera = new FlxCamera();
		//guideCamera.bgColor = 0;

		uiCamera = new FlxCamera();
		uiCamera.bgColor = 0;

		uiCameras = [uiCamera];

		//FlxG.cameras.add(guideCamera, false);
		FlxG.cameras.add(uiCamera, false);

		// Load from xml
		var order:Array<Dynamic> = [];
		var orderNodes:Array<Access> = [];
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
			var parent = new Access(node.x.parent);
			//var name = "";
			//trace(node, sprite);
			if(sprite is FlxSprite) {
				//sprite.forceIsOnScreen = true; // hack
			}
			if(sprite is FunkinSprite) {
				var sprite:FunkinSprite = cast sprite;
				//name = sprite.name;
				sprite.extra.set(exID("node"), node);
				sprite.extra.set(exID("type"), node.name);
				sprite.extra.set(exID("imageFile"), '${node.getAtt("sprite").getDefault(sprite.name)}');
				sprite.extra.set(exID("parentNode"), parent);
				sprite.extra.set(exID("highMemory"), parent.name == "highMemory");
				sprite.extra.set(exID("lowMemory"), parent.name == "lowMemory");
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
				//name = charPos.name;
				var char = new Character(0,0, charName, stage.isCharFlipped(charPos.name, charName == "bf"), true);
				char.name = charName;
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
				function setEx(name:String, value:Dynamic) {
					char.extra.set(exID(name), value);
					charPos.extra.set(exID(name), value);
				}
				setEx("node", node);
				setEx("pos", charPos);
				setEx("char", char);

				setEx("parentNode", parent);
				setEx("highMemory", parent.name == "highMemory");
				setEx("lowMemory", parent.name == "lowMemory");
				chars.push(char);
			}
			order.push(sprite);
			orderNodes.push(node);
			xmlMap.set(sprite, node);

			return sprite;
		}
		stage.loadXml(stage.stageXML, true);
		add(stage);

		for(char in chars) {
			var charPos = char.extra.get(exID("pos"));
			//var node:Access = cast char.extra.get(exID("node"));

			stage.applyCharStuff(char, charPos.name, 0);
			charMap[charPos.name] = char;
		}

		setZoom(stage.defaultZoom);

		topMenuSpr = new UITopMenu(topMenu);
		topMenuSpr.cameras = uiGroup.cameras = [uiCamera];

		final margin = 0;//22;
		final width = SPRITE_WINDOW_WIDTH;
		final TOP_MENU_HEIGHT = 25;
		var buttonSize:FlxPoint = FlxPoint.get(width-margin*2, SPRITE_WINDOW_BUTTON_HEIGHT);
		stageSpritesWindow = new UIButtonList<StageElementButton>(Std.int(FlxG.width - width), TOP_MENU_HEIGHT, width, Std.int(FlxG.height - TOP_MENU_HEIGHT), "Stage Sprites", buttonSize);
		stageSpritesWindow.collapsable = true;
		stageSpritesWindow.topAlpha = 0.9;
		stageSpritesWindow.middleAlpha = 0.5;
		stageSpritesWindow.bottomAlpha = 0.5;
		stageSpritesWindow.buttonSpacing = 0;
		stageSpritesWindow.dragCallback = (button, oldID, newID) -> {
			var sprite:FunkinSprite = button.getSprite();
			var idx = members.indexOf(sprite);
			members.splice(idx, 1);
			members.insert(newID, sprite);
		}
		stageSpritesWindow.addButton.callback = () -> {
			var lastDrawCam = stageSpritesWindow.addButton.__lastDrawCameras[0];
			var screenPos = stageSpritesWindow.addButton.getScreenPosition(null, lastDrawCam == null ? FlxG.camera : lastDrawCam);
			openContextMenu([
				{
					label: "Sprite",
					onSelect: _sprite_new,
					color: 0xFF00FF00,
					icon: 2
				},
				{
					label: "Box",
					onSelect: function(_) {
						UIState.state.displayNotification(new UIBaseNotification("Creating a box isnt implemented yet!", 2, BOTTOM_LEFT));
						CoolUtil.playMenuSFX(WARNING, 0.45);
					},
					color: 0xFF00FF00,
					icon: 2
				},
				{
					label: "Character",
					onSelect: _character_new,
					color: 0xFF00FF00,
					icon: 2
				}
			], null, lastDrawCam.x + screenPos.x, lastDrawCam.y + screenPos.y + stageSpritesWindow.addButton.bHeight, stageSpritesWindow.addButton.bWidth);
			screenPos.put();
		}
		for (i=>sprite in order) {
			var xml = (sprite != null) ? xmlMap.get(sprite) : orderNodes[i];
			if(xml != null) {
				if(sprite is FunkinSprite) {
					var sprite:FunkinSprite = cast sprite;
					var type = sprite.extra.get(exID("type"));
					var button:StageElementButton = (type == "box" || type == "solid") ? new StageSolidButton(0,0, sprite, xml) : new StageSpriteButton(0,0, sprite, xml);
					sprite.extra.set(exID("button"), button);
					stageSpritesWindow.add(button);
				}
				else if(sprite is StageCharPos) {
					var charPos:StageCharPos = cast sprite;
					var char = charMap[charPos.name];
					var button = new StageCharacterButton(0,0, charPos, xml);
					char.extra.set(exID("button"), button);
					charPos.extra.set(exID("button"), button);
					stageSpritesWindow.add(button);
				} else if(sprite == null) {
					var button = new StageUnknownButton(0,0, xml);
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

	private var movedTillRel:FlxPoint = FlxPoint.get(0,0);
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

			var prevMode = mouseMode;

			// TODO: make this work with multiple selections
			if(selection.length == 1) {
				for(sprite in selection) {
					if(sprite is FunkinSprite) {
						handleSelection(cast sprite);
					}
				}
			}

			//if (FlxG.mouse.justReleasedRight) {
			//	closeCurrentContextMenu();
			//	openContextMenu(topMenu[2].childs);
			//}

			if (mouseMode == NONE && prevMode == NONE) {
				if (FlxG.mouse.pressed) {
					var x = FlxG.mouse.deltaScreenX;
					var y = FlxG.mouse.deltaScreenY;
					movedTillRel.x += x; movedTillRel.y += y;
					nextScroll.set(nextScroll.x - x, nextScroll.y - y);
					currentCursor = HAND;
				}

				if (FlxG.mouse.justReleased) {
					if (Math.abs(movedTillRel.x) < 16 && Math.abs(movedTillRel.y) < 16) {
						var point = FlxG.mouse.getWorldPosition(stageCamera, _point);
						var sprites = getRealSprites();
						for (i in 0...sprites.length) {
							var sprite = sprites[sprites.length - i - 1];
							if(sprite.animateAtlas != null) continue;

							calcSpriteBounds(sprite);
							if (cast(sprite.extra.get(exID("bounds")), FlxRect).containsPoint(point)) {
								selectSprite(sprite); break;
							}
						}
					}
					movedTillRel.set();
				}
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

	// TOP MENU OPTIONS
	#if REGION
	function _file_exit(_) {
		if (undos.unsaved) SaveWarning.triggerWarning();
		else FlxG.switchState(new StageSelection());
	}

	function _file_save(_) {
		#if sys
		CoolUtil.safeSaveFile(
			'${Paths.getAssetsRoot()}/data/stages/${__stage}.xml',
			buildStage()
		);
		undos.save();
		#else
		_file_saveas(_);
		#end
	}

	function _file_saveas(_) {
		openSubState(new SaveSubstate(buildStage(), {
			defaultSaveFile: '${__stage}.xml'
		}));
		undos.save();
	}

	function _sprite_new(_) {
		var node:Access = new Access(Xml.createElement("sprite"));
		stage.stageXML.x.addChild(node.x);
		node.att.name = "sprite_" + stageSpritesWindow.buttons.length;

		var sprite:FunkinSprite = new FunkinSprite();
		insert(members.indexOf(stage), sprite);
		sprite.extra.set(exID("node"), node);
		sprite.extra.set(exID("type"), node.name);
		sprite.extra.set(exID("imageFile"), '');
		sprite.extra.set(exID("parentNode"), stage.stageXML.x);
		sprite.extra.set(exID("highMemory"), false);
		sprite.extra.set(exID("lowMemory"), false);
		xmlMap.set(sprite, node);

		var button:StageSpriteButton = new StageSpriteButton(0, 0, sprite, node);
		sprite.extra.set(exID("button"), button);
		stageSpritesWindow.add(button);

		var substate = new StageSpriteEditScreen(button);
		substate.newSprite = true;
		openSubState(substate);
	}

	function _character_new(_) {
		var node:Access = new Access(Xml.createElement("char"));
		stage.stageXML.x.addChild(node.x);
		node.att.name = "character_" + stageSpritesWindow.buttons.length;

		var charPos = new StageCharPos();
		charPos.visible = charPos.active = false;
		charPos.name = "character_" + stageSpritesWindow.buttons.length;
		charPos.extra.set(exID("extraChar"), true);
		stage.characterPoses[charPos.name] = charPos;

		var char = new Character(0,0, "bf", stage.isCharFlipped(charPos.name, true), true);
		char.name = "bf";
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
		function setEx(name:String, value:Dynamic) {
			char.extra.set(exID(name), value);
			charPos.extra.set(exID(name), value);
		}
		setEx("node", node);
		setEx("pos", charPos);
		setEx("char", char);

		setEx("parentNode", stage.stageXML);
		setEx("highMemory", false);
		setEx("lowMemory", false);
		chars.push(char);

		stage.applyCharStuff(char, charPos.name, 0);
		charMap[charPos.name] = char;

		var button = new StageCharacterButton(0,0, charPos, node);
		char.extra.set(exID("button"), button);
		charPos.extra.set(exID("button"), button);
		stageSpritesWindow.add(button);
	}

	function saveToXml(xml:Xml, name:String, value:Dynamic, ?defaultValue:Dynamic) {
		if(value == null || value == defaultValue) return xml;
		xml.set(name, Std.string(value));
		return xml;
	}
	function savePointToXml(xml:Xml, name:String, point:FlxPoint, ?defaultValueX:Float, ?defaultValueY:Float) {
		if (point == null) return xml;
		if(defaultValueY == null) defaultValueY = defaultValueX;
		if(point.x == point.y) {
			saveToXml(xml, name, point.x, defaultValueX);
		} else {
			saveToXml(xml, name + "x", point.x, defaultValueX);
			saveToXml(xml, name + "y", point.y, defaultValueY);
		}
		return xml;
	}

	function getBoolOfNode(node:Access, name:String) {
		var xml:Xml = cast node;

		return xml.exists(name) && xml.get(name) == "true";
	}

	function buildStage():String {
		var xml = Xml.createElement("stage");
		saveToXml(xml, "zoom", stage.defaultZoom, 1.05);
		saveToXml(xml, "name", stage.stageName);
		saveToXml(xml, "folder", stage.spritesParentFolder);
		saveToXml(xml, "startCamPosX", stage.startCam.x, 0);
		saveToXml(xml, "startCamPosY", stage.startCam.y, 0);

		for(prop in stage.extra.keys())
			if(!Stage.DEFAULT_ATTRIBUTES.contains(prop) && !prop.startsWith("stageEditor."))
				saveToXml(xml, prop, stage.extra.get(prop));

		var group:Xml = null;
		var curGroup:String = null;

		for(sprite in getSprites()) {
			var button:StageElementButton = sprite.extra.get(exID("button"));
			var newNode:Xml = null;
			var sprite:FunkinSprite = button.getSprite();
			if(button is StageSolidButton) {
				var button:StageSolidButton = cast button;
				var node:Access = cast sprite.extra.get(exID("node"));
				Logs.trace("SOLID / BOX isnt implemented yet!");
			} else if(button is StageSpriteButton) {
				var button:StageSpriteButton = cast button;
				var node:Access = cast sprite.extra.get(exID("node"));
				var spriteXML = Xml.createElement("sprite");
				saveToXml(spriteXML, "name", sprite.name);
				saveToXml(spriteXML, "x", sprite.x, 0);
				saveToXml(spriteXML, "y", sprite.y, 0);
				saveToXml(spriteXML, "sprite", sprite.extra.get(exID("imageFile")));
				savePointToXml(spriteXML, "scale", sprite.scale, 1);
				savePointToXml(spriteXML, "scroll", sprite.scrollFactor, 0);
				saveToXml(spriteXML, "skewx", sprite.skew.x, 0);
				saveToXml(spriteXML, "skewy", sprite.skew.y, 0);
				saveToXml(spriteXML, "alpha", sprite.alpha, 1);
				saveToXml(spriteXML, "angle", sprite.angle, 0);
				//saveToXml(spriteXML, "graphicSize", sprite.width, sprite.width);
				//saveToXml(spriteXML, "graphicSizex", sprite.height, sprite.height);
				//saveToXml(spriteXML, "graphicSizey", sprite.height, sprite.height);
				saveToXml(spriteXML, "zoomfactor", sprite.zoomFactor, 1);
				saveToXml(spriteXML, "updateHitbox", getBoolOfNode(node, "updateHitbox"), false);
				saveToXml(spriteXML, "antialiasing", sprite.antialiasing, true);
				//saveToXml(spriteXML, "width", sprite.width);
				//saveToXml(spriteXML, "height", sprite.height);
				saveToXml(spriteXML, "playOnCountdown", getBoolOfNode(node, "playOnCountdown"), false);
				saveToXml(spriteXML, "interval", node.getAtt("beatInterval"), 2);
				saveToXml(spriteXML, "interval", node.getAtt("interval"), 2);
				saveToXml(spriteXML, "beatOffset", node.getAtt("beatOffset"), 0);
				saveToXml(spriteXML, "type", sprite.spriteAnimType, LOOP);
				saveToXml(spriteXML, "color", sprite.color.toWebString(), "#FFFFFF");
				// TODO: save custom parameters
				//saveToXml(spriteXML, "flipX", sprite.flipX, false);
				newNode = spriteXML;
			} else if(button is StageCharacterButton) {
				var button:StageCharacterButton = cast button;
				var charPos:StageCharPos = button.charPos;
				var char:Character = cast charPos.extra.get(exID("char"));
				var node:Access = cast charPos.extra.get(exID("node"));
				var nodeName = switch(charPos.name) {
					case "boyfriend": "boyfriend";
					case "dad": "dad";
					case "girlfriend": "girlfriend";
					default: "character";
				}
				var defaultPos = Stage.getDefaultPos(charPos.name);
				var charXML:Xml = Xml.createElement(nodeName);
				if(nodeName == "character")
					saveToXml(charXML, "name", char.curCharacter);
				saveToXml(charXML, "x", charPos.x, defaultPos.x);
				saveToXml(charXML, "y", charPos.y, defaultPos.y);
				saveToXml(charXML, "camxoffset", charPos.camxoffset, 0);
				saveToXml(charXML, "camyoffset", charPos.camyoffset, 0);
				saveToXml(charXML, "skewx", charPos.skewX, 0);
				saveToXml(charXML, "skewy", charPos.skewY, 0);
				saveToXml(charXML, "spacingx", charPos.charSpacingX, 20);
				saveToXml(charXML, "spacingy", charPos.charSpacingY, 0);
				saveToXml(charXML, "alpha", charPos.alpha, 1);
				saveToXml(charXML, "angle", charPos.angle, 0);
				saveToXml(charXML, "zoomfactor", charPos.zoomFactor, 1);
				saveToXml(charXML, "flipX", charPos.flipX, defaultPos.flip);
				savePointToXml(charXML, "scroll", charPos.scrollFactor, defaultPos.scroll);
				savePointToXml(charXML, "scale", charPos.scale, 1);
				// TODO: save custom parameters
				newNode = charXML;
			} else if(button is StageUnknownButton) {
				var button:StageUnknownButton = cast button;
				newNode = button.xml.x;
			}
			else {
				Logs.trace("Unknown Stage Type : " + Type.getClassName(Type.getClass(button)));
				Logs.trace("> Sprite : " + Type.getClassName(Type.getClass(sprite)));
			}

			if(newNode != null && sprite != null) {
				var isLowMemory = sprite.extra.get(exID("lowMemory")) == true;
				var isHighMemory = sprite.extra.get(exID("highMemory")) == true;
				/* // Only if this compiled :sob:
				var groupName:String = null;
				if ((groupName = isLowMemory ? "low-memory" : isHighMemory ? "high-memory" : null) != null) {
					var a = group != null && groupName != curGroup && ((group = cast xml.addChild(group)) != null);
					(group = (group == null ? Xml.createElement(curGroup = groupName) : group)).addChild(newNode);
				}else xml.addChild(newNode);
				*/

				var groupName = isLowMemory ? "low-memory" : isHighMemory ? "high-memory" : null;
				if(group != null && groupName != curGroup) {
					xml.addChild(group);
					group = null;
				}
				if(groupName != null)
					(group = (group == null ? Xml.createElement(curGroup = groupName) : group)).addChild(newNode);
				else
					xml.addChild(newNode);
			}
		}

		Logs.trace(Printer.print(xml, true));

		return "<!DOCTYPE codename-engine-stage>\n" + Printer.print(xml, true);
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

	/*public function editInfoWithUI() {
		FlxG.state.openSubState(new StageInfoScreen(stage, (_) -> {
			if (_ != null) editInfo(_);
		}));
	}*/

	public function editInfo(newInfo:Xml, addtoUndo:Bool = true) {
		/*var oldInfo = stage.buildXML();
		stage.applyXML(new Access(newInfo));

		if (addtoUndo)
			undos.addToUndo(CEditInfo(oldInfo, newInfo));*/
	}

	public function selectSprite(_sprite:FunkinSprite) {
		if(!UIUtil.getKeyState(CONTROL, PRESSED))
			_select_deselect(null, false);

		if(_sprite is FunkinSprite) {
			if(selection.contains(_sprite))
				selection.remove(_sprite);
			else
				selection.push(_sprite);
		}
		updateSelection();
	}

	function getSprites() {
		return stageSpritesWindow.buttons.members.map((o) -> o.getSprite()).filter((o) -> o != null);
	}
	function getRealSprites() {
		return stageSpritesWindow.buttons.members.filter(o -> o.canRender()).map((o) -> o.getSprite()).filter((o) -> o != null);
	}

	function updateSelection() {
		var sprites = getRealSprites();
		// Unselect all
		for(sprite in sprites) {
			if(sprite is FunkinSprite) {
				var sprite:FunkinSprite = cast sprite;
				sprite.extra.set(exID("selected"), false);
				sprite.extra.get(exID("button")).selected = false;
			}
		}
		// Mark selected as selected
		for(sprite in selection) {
			if(sprite is FunkinSprite) {
				var sprite:FunkinSprite = cast sprite;
				sprite.extra.set(exID("selected"), true);
				sprite.extra.get(exID("button")).selected = true;
				Logs.trace("Selected " + sprite.name);
			}
		}
	}

	function _select_all(_, checkSelection:Bool = true) {
		_select_deselect(null, false);
		var sprites = getRealSprites();
		selection = new Selection(sprites);
		if(checkSelection) updateSelection();
	}

	function _select_deselect(_, checkSelection:Bool = true) {
		selection = new Selection();
		if(checkSelection) updateSelection();
	}

	function _select_inverse(_, checkSelection:Bool = true) {
		var oldSelection = selection;
		_select_all(null, false);
		for(sprite in oldSelection) {
			selection.remove(sprite);
		}
		if(checkSelection) updateSelection();
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

	function _editor_showCharacters(t) {
		showCharacters = !showCharacters;
		t.icon = showCharacters ? 1 : 0;
		for(char in chars) {
			var button:StageCharacterButton = char.extra.get(exID("button"));
			button.isHidden = !showCharacters;
			button.updateInfo();
		}
	}
	#end

	override function draw() {
		super.draw();

		mousePoint = FlxG.mouse.getWorldPosition(stageCamera, mousePoint);
		if(dot == null) {
			dot = new FlxSprite().loadGraphic(Paths.image("editors/stage/selectionDot"), true, 32, 32);
			dot.antialiasing = true;
			dot.animation.add("default", [0], 0, false);
			dot.animation.add("hollow", [1], 0, false);
			dot.animation.play("default");
			//dot = new FlxSprite().makeGraphic(30, 30, FlxColor.WHITE);
			dot.camera = stageCamera;
			dot.forceIsOnScreen = true;

			line = new FlxSprite().makeGraphic(30, 30, FlxColor.WHITE);
			line.camera = stageCamera;
			line.color = lineColor;
			line.forceIsOnScreen = true;
		}
		for(sprite in selection) {
			if(sprite is FunkinSprite) {
				@:privateAccess if(sprite._frame == null) continue;
				drawGuides(cast sprite);
			}
		}
	}

	var lineColor:FlxColor = 0xFFb794b6;
	var circleColor:FlxColor = 0xFF99a8f2;
	var hollowColor:FlxColor = 0xffb2beff;

	function drawGuides(sprite:FlxSprite) {
		var corners = calcSpriteBounds(sprite);
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

		drawLine(corners[0], corners[1]); // tl - tr
		drawLine(corners[0], corners[2]); // tl - bl
		drawLine(corners[1], corners[3]); // tr - br
		drawLine(corners[2], corners[3]); // bl - br

		drawLine(corners[7], corners[9], 0.3); // tc - ac // top center to angle center

		// cross
		//drawLine(corners[0], corners[3]); // tl - br
		//drawLine(corners[1], corners[2]); // tr - bl

		dot.color = circleColor;

		final ANGLE_INDEX = StageEditorEdge.ROTATE_CIRCLE.toInt();
		final CENTER_INDEX = StageEditorEdge.CENTER_CIRCLE.toInt();

		dot.animation.play("default");

		for(i in 0...corners.length) {
			var corner = corners[i];
			if(i != CENTER_INDEX) {
				if(i == ANGLE_INDEX)  {
					dot.color = hollowColor;
					drawDot(corner.x, corner.y);
					dot.animation.play("hollow");
					dot.color = circleColor;
					drawDot(corner.x, corner.y);
				} else {
					drawDot(corner.x, corner.y);
				}
				buttonBoxes.push(corner);
			}
			else if(sprite.visible){
				dot.color = circleColor;
				drawDot(corner.x, corner.y, 0.7);
				dot.animation.play("hollow");
				buttonBoxes.push(corner);
			}
			
		}

		if(funkinSprite == null) {
			for(corner in buttonBoxes) {
				corner.put();
			}
		}
	}

	function calcSpriteBounds(sprite:FlxSprite) {
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
			FlxPoint.get(0.5, 0.5),
			//FlxPoint.get(0.5, -100/sprite.frameHeight) // angle
			FlxPoint.get(0.5, -0.5) // angle
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

		// reset hitbox to old values
		sprite.width = oldWidth;
		sprite.height = oldHeight;

		return corners;
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

		CENTER_CIRCLE, //FlxPoint.get(0.5, -0.5)

		ROTATE_CIRCLE, //FlxPoint.get(0.5, -0.5)
	];

	function tryUpdateHitbox(sprite:FunkinSprite) {
		call("tryUpdateHitbox", [sprite]);
	}

	function handleSelection(sprite:FunkinSprite) {
		if(!sprite.extra.exists(exID("buttonBoxes"))) return;
		var buttonBoxes:Array<FlxPoint> = cast sprite.extra.get(exID("buttonBoxes"));

		dotCheckSize = dot.frameWidth / 0.7/stageCamera.zoom; // basically adjust it to the zoom.

		if(FlxG.mouse.justPressed) {
			for (i in StageEditorMouseMode.SKEW_TOP...(StageEditorMouseMode.SKEW_BOTTOM + 1)) {
				var cappedI1 = Math.max(i - StageEditorMouseMode.SKEW_TOP - 1, 0);
				var cappedI2 = Math.min(i - StageEditorMouseMode.SKEW_TOP + 1, 3);
				var point1 = buttonBoxes[Std.int(cappedI1)];
				var point2 = buttonBoxes[Std.int(cappedI2)];
				if (checkLine(point1, point2, point2.x - point1.x, point2.y - point1.y)) {
					mousePoint.copyTo(clickPoint);
					storedPos.set(sprite.x, sprite.y);
					storedSkew.copyFrom(sprite.skew);
					storedScale.copyFrom(sprite.scale);
					storedAngle = sprite.angle;
					mouseMode = i;
				}
			}

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
						case CENTER_CIRCLE: MOVE_CENTER;
						case ROTATE_CIRCLE: ROTATE;
						default: NONE;
					}
					Logs.trace("Clicked Dot: " + mouseMode.toString());
					mousePoint.copyTo(clickPoint);
					storedPos.set(sprite.x, sprite.y);
					storedSkew.set(sprite.skew.x, sprite.skew.y);
					storedScale.copyFrom(sprite.scale);
					storedAngle = sprite.angle;
				}
				
				if(mouseMode == MOVE_CENTER){
					trace(mouseMode);
					storedPos.set(sprite.x, sprite.y);
				}
			}
		}
		for(i=>edge in edges) {
			if(checkDot(buttonBoxes[i])) {
				// TODO: make it show both sided arrows when resizing, unless its at minimum size then show only one
				// TODO: make this rotate with the sprite
				currentCursor = switch(edge) {
					// RESIZE_NESW; //RESIZE_NS; //RESIZE_NWSE; //RESIZE_WE;
					case TOP_LEFT: RESIZE_TL;
					case TOP_MIDDLE: RESIZE_T;
					case TOP_RIGHT: RESIZE_TR;
					case MIDDLE_LEFT: RESIZE_L;
					case CENTER_CIRCLE: 
						#if (mac) FlxG.mouse.pressed ? DRAG : DRAG_OPEN 
						#elseif (linux) FlxG.mouse.pressed ? DRAG : CLICK 
						#else MOVE #end;
					case MIDDLE_RIGHT: RESIZE_R;
					case BOTTOM_LEFT: RESIZE_BL;
					case BOTTOM_MIDDLE: RESIZE_B;
					case BOTTOM_RIGHT: RESIZE_BR;
					//case TOP_LEFT | BOTTOM_RIGHT: MouseCursor.RESIZE_NWSE;
					//case TOP_MIDDLE | BOTTOM_MIDDLE: MouseCursor.RESIZE_NS;
					//case TOP_RIGHT | BOTTOM_LEFT: MouseCursor.RESIZE_NESW;
					//case MIDDLE_LEFT | MIDDLE_RIGHT: MouseCursor.RESIZE_WE;

					case ROTATE_CIRCLE: FlxG.mouse.pressed ? DRAG : #if mac DRAG_OPEN #else CLICK #end;
					default: ARROW;
				}
				break;
			}
		}

		mouseMode = (FlxG.mouse.justReleased) ? NONE : mouseMode;
		if(mouseMode == NONE) return;
		var relative = clickPoint.subtractNew(mousePoint);
		// todo: make this origin based
		//relative.rotateByDegrees(sprite.angle);
		call(mouseMode.toString(), [sprite, relative]);
		cast(sprite.extra.get(exID("button")), StageElementButton).updateInfo();
		relative.put();
	}

	var dotCheckSize:Float = 53;

	function checkDot(point:FlxPoint):Bool {
		if(point!=null){
			var rect = new FlxRect(point.x - dotCheckSize/2, point.y - dotCheckSize/2, dotCheckSize, dotCheckSize);
			return rect.containsPoint(mousePoint);
		}
		return false;
	}

	inline function drawDot(x:Float, y:Float, ?scale:Float = 1) {
		dot.setPosition(x, y);
		dot.scale.set(0.7/stageCamera.zoom * scale, 0.7/stageCamera.zoom * scale);
		dot.x -= dot.width / 2;
		dot.y -= dot.height / 2;
		dot.draw();
	}

	function checkLine(point1:FlxPoint, point2:FlxPoint, dx:Float, dy:Float) {
		var leftRegion = Math.min(point1.x, point2.x) - dotCheckSize * 0.2;
		var rightRegion = Math.max(point1.x, point2.x) + dotCheckSize * 0.2;
		var topRegion = Math.min(point1.y, point2.y) - dotCheckSize * 0.2;
		var bottomRegion = Math.max(point1.y, point2.y) + dotCheckSize * 0.2;

		if (dx == 0.0 || dy == 0.0)
			return (mousePoint.x >= leftRegion && mousePoint.x <= rightRegion)
				&& (mousePoint.y >= topRegion && mousePoint.y <= bottomRegion);

		var inc = dx * ((mousePoint.y - point1.y) / dy);
		leftRegion += inc;
		rightRegion += inc;

		inc = dy * ((mousePoint.x - point1.x) / dx);
		topRegion += inc;
		bottomRegion += inc;
			
		return (mousePoint.x >= leftRegion && mousePoint.x <= rightRegion)
			&& (mousePoint.y >= topRegion && mousePoint.y <= bottomRegion);
	}

	function drawLine(point1:FlxPoint, point2:FlxPoint, sizeModify:Float = 1) {
		var dx:Float = point2.x - point1.x;
		var dy:Float = point2.y - point1.y;

		var angle:Float = Math.atan2(dy, dx);
		var distance:Float = Math.sqrt(dx * dx + dy * dy);

		line.setPosition(point1.x, point1.y);
		line.angle = angle * FlxAngle.TO_DEG;
		line.origin.set(0, line.frameHeight / 2);
		line.scale.x = distance / line.frameWidth;
		line.scale.y = 0.20/stageCamera.zoom * sizeModify;
		//line.x -= line.width / 2;
		line.y -= line.height / 2;
		line.draw();
		// Reset the angle and scale
		line.angle = 0;
		line.scale.x = line.scale.y = 1;
		line.updateHitbox();
	}

	var dot:FlxSprite = null;
	var line:FlxSprite = null;
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

enum abstract StageEditorMouseMode(Int) from Int to Int {
	var NONE;

	var SCALE_LEFT;
	var SCALE_BOTTOM;
	var SCALE_TOP;
	var SCALE_RIGHT;
	var SCALE_TOP_LEFT;
	var SCALE_TOP_RIGHT;
	var SCALE_BOTTOM_LEFT;
	var SCALE_BOTTOM_RIGHT;

	var MOVE_CENTER;

	var SKEW_TOP;
	var SKEW_LEFT;
	var SKEW_RIGHT;
	var SKEW_BOTTOM;

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
			case MOVE_CENTER: "MOVE_CENTER";
			case SKEW_LEFT: "SKEW_LEFT";
			case SKEW_BOTTOM: "SKEW_BOTTOM";
			case SKEW_TOP: "SKEW_TOP";
			case SKEW_RIGHT: "SKEW_RIGHT";
			case ROTATE: "ROTATE";
		}
	}
}

enum abstract StageEditorEdge(Int) {
	var NONE = -1;

	var TOP_LEFT = 0;
	var TOP_MIDDLE;
	var TOP_RIGHT;
	var MIDDLE_LEFT;
	//var MIDDLE_MIDDLE;
	var MIDDLE_RIGHT;
	var BOTTOM_LEFT;
	var BOTTOM_MIDDLE;
	var BOTTOM_RIGHT;
	var CENTER_CIRCLE;

	var ROTATE_CIRCLE;

	public function toString():String {
		return switch(cast this) {
			case NONE: "NONE";
			case TOP_LEFT: "TOP_LEFT";
			case TOP_MIDDLE: "TOP_MIDDLE";
			case TOP_RIGHT: "TOP_RIGHT";
			case MIDDLE_LEFT: "MIDDLE_LEFT";
			//case MIDDLE_MIDDLE: "MIDDLE_MIDDLE";
			case MIDDLE_RIGHT: "MIDDLE_RIGHT";
			case BOTTOM_LEFT: "BOTTOM_LEFT";
			case BOTTOM_MIDDLE: "BOTTOM_MIDDLE";
			case BOTTOM_RIGHT: "BOTTOM_RIGHT";
			case CENTER_CIRCLE: "CENTER_CIRCLE";
			case ROTATE_CIRCLE: "ROTATE_CIRCLE";
		}
	}

	public function toInt():Int {
		return switch(cast this) {
			case NONE: -1;
			case TOP_LEFT: 0;
			case TOP_MIDDLE: 1;
			case TOP_RIGHT: 2;
			case MIDDLE_LEFT: 3;

			case MIDDLE_RIGHT: 4;
			case BOTTOM_LEFT: 5;
			case BOTTOM_MIDDLE: 6;
			case BOTTOM_RIGHT: 7;
			case CENTER_CIRCLE: 8;
			case ROTATE_CIRCLE: 9;
		}
	}
}

class StageXMLEditScreen extends UISoftcodedWindow {
	public var xml:Access;
	public var saveCallback:Void->Void;

	public function new(xml:Access, saveCallback:Void->Void, type:String = "Unknown") {
		this.xml = xml;
		this.saveCallback = saveCallback;
		super("layouts/stage/xmlEditScreen", [
			"stage" => StageEditor.instance.stage,
			"xml" => xml,
			"exID" => StageEditor.exID,
			"type" => type
		]);
	}

	override function saveData() {
		super.saveData();
		if(saveCallback != null) saveCallback();
	}
}
