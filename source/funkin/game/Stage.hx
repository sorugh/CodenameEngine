package funkin.game;

import flixel.util.typeLimit.OneOfTwo;
import flixel.FlxState;
import flixel.math.FlxPoint;
import funkin.backend.scripting.Script;
import funkin.backend.scripting.events.StageNodeEvent;
import funkin.backend.scripting.events.StageXMLEvent;
import funkin.backend.system.interfaces.IBeatReceiver;
import haxe.io.Path;
import haxe.xml.Access;

using StringTools;

class Stage extends FlxBasic implements IBeatReceiver {
	public var extra:Map<String, Dynamic> = [];

	public var stageXML:Access;
	public var stagePath:String;
	public var stageFile:String;
	public var stageName:String;
	public var stageSprites:Map<String, FlxSprite> = [];
	public var stageScript:Script;
	public var state:FlxState;
	public var characterPoses:Map<String, StageCharPos> = [];

	public var defaultZoom:Float = 1.05;
	public var startCam = new FlxPoint();

	public var onXMLLoaded:(Access, Array<Access>)->Array<Access> = null;
	public var onNodeLoaded:(Access, Dynamic)->Dynamic = null;
	public var onNodeFinished:(Access, Dynamic)->Void = null;
	public var onAddSprite:(FlxObject)->Void = null;

	private var spritesParentFolder = "";

	public inline function getSprite(name:String) {
		return stageSprites[name];
	}

	public function new(stage:String, ?state:FlxState, autoLoad:Bool = true) {
		super();

		if (state == null) state = PlayState.instance;
		if (state == null) state = FlxG.state;
		this.state = state;

		stageFile = stage;

		stagePath = Paths.xml('stages/$stageFile');
		try {
			if (Assets.exists(stagePath)) stageXML = new Access(Xml.parse(Assets.getText(stagePath)).firstElement());
		} catch(e) {
			Logs.trace('Couldn\'t load stage "$stageFile": ${e.message}', ERROR);
		}

		if (autoLoad) loadXml(stageXML);
	}

	public function loadXml(xml:Access, forceLoadAll:Bool = false) {
		if (PlayState.instance == state) {
			stageScript = Script.create(Paths.script('data/stages/$stageFile'));
			PlayState.instance.scripts.add(stageScript);
			stageScript.load();
		}

		if (xml != null) {
			var parsed:Null<Float>;
			if((parsed = Std.parseFloat(xml.getAtt("startCamPosX"))).isNotNull()) startCam.x = parsed;
			if((parsed = Std.parseFloat(xml.getAtt("startCamPosY"))).isNotNull()) startCam.y = parsed;
			if((parsed = Std.parseFloat(xml.getAtt("zoom"))).isNotNull()) defaultZoom = parsed;

			stageName = xml.getAtt("name").getDefault(stageFile);

			if (PlayState.instance == state) {
				if(xml.has.startCamPosX) PlayState.instance.camFollow.x = startCam.x;
				if(xml.has.startCamPosY) PlayState.instance.camFollow.y = startCam.y;
				if(xml.has.zoom) PlayState.instance.defaultCamZoom = defaultZoom;
				PlayState.instance.curStage = stageName;
			}
			if (xml.has.folder) {
				spritesParentFolder = xml.att.folder;
				if (!spritesParentFolder.endsWith("/")) spritesParentFolder += "/";
			}

			var elems:Array<Access> = [];
			// some way to tag that the sprites are from the group
			for(node in xml.elements) {
				if (node.name == "high-memory" && (!Options.lowMemoryMode || forceLoadAll))
					for(e in node.elements)
						elems.push(e);
				else if (node.name == "low-memory" && (Options.lowMemoryMode || forceLoadAll))
					for(e in node.elements)
						elems.push(e);
				else
					elems.push(node);
			}

			if (PlayState.instance == state) {
				var event = PlayState.instance.scripts.event("onStageXMLParsed", EventManager.get(StageXMLEvent).recycle(this, xml, elems));
				elems = event.elems;
			}
			if(onXMLLoaded != null) {
				elems = onXMLLoaded(xml, elems);
			}

			for(node in elems) {
				var sprite:Dynamic = switch(node.name) {
					case "sprite" | "spr" | "sparrow":
						if (!node.has.sprite || !node.has.name) continue;

						var spr = XMLUtil.createSpriteFromXML(node, spritesParentFolder, LOOP);

						stageSprites.set(spr.name, spr);
						addSprite(spr);
					case "box" | "solid":
						if ( !node.has.name || !node.has.width || !node.has.height) continue;

						var spr = new FunkinSprite(
							(node.has.x) ? Std.parseFloat(node.att.x).getDefault(0) : 0,
							(node.has.y) ? Std.parseFloat(node.att.y).getDefault(0) : 0
						);
						spr.name = node.getAtt("name");

						(node.name == "solid" ? spr.makeSolid : spr.makeGraphic)(
							Std.parseInt(node.att.width),
							Std.parseInt(node.att.height),
							(node.has.color) ? CoolUtil.getColorFromDynamic(node.att.color) : -1
						);

						stageSprites.set(spr.name, spr);
						addSprite(spr);
					case "boyfriend" | "bf" | "player":
						addCharPos("boyfriend", node, {
							x: 770,
							y: 100,
							scroll: 1,
							flip: true
						});
					case "girlfriend" | "gf":
						addCharPos("girlfriend", node, {
							x: 400,
							y: 130,
							scroll: 0.95,
							flip: false
						});
					case "dad" | "opponent":
						addCharPos("dad", node, {
							x: 100,
							y: 100,
							scroll: 1,
							flip: false
						});
					case "character" | "char":
						if (!node.has.name) continue;
						addCharPos(node.att.name, node);
					case "ratings" | "combo":
						if (PlayState.instance != state) continue;
						PlayState.instance.comboGroup.setPosition(
							Std.parseFloat(node.getAtt("x")).getDefault(PlayState.instance.comboGroup.x),
							Std.parseFloat(node.getAtt("y")).getDefault(PlayState.instance.comboGroup.y)
						);
						PlayState.instance.add(PlayState.instance.comboGroup);
						PlayState.instance.comboGroup;
					default: null;
				}

				if(PlayState.instance == state) {
					sprite = PlayState.instance.scripts.event("onStageNodeParsed", EventManager.get(StageNodeEvent).recycle(this, node, sprite, node.name)).sprite;
				}
				if(onNodeLoaded != null) {
					sprite = onNodeLoaded(node, sprite);
				}

				if (sprite != null) {
					for(e in node.nodes.property)
						XMLUtil.applyXMLProperty(sprite, e);
				}

				if(onNodeFinished != null) {
					onNodeFinished(node, sprite);
				}
			}
		}

		if (characterPoses["girlfriend"] == null)
			addCharPos("girlfriend", null, {
				x: 400,
				y: 130,
				scroll: 0.95,
				flip: false
			});

		if (characterPoses["dad"] == null)
			addCharPos("dad", null, {
				x: 100,
				y: 100,
				scroll: 1,
				flip: false
			});

		if (characterPoses["boyfriend"] == null)
			addCharPos("boyfriend", null, {
				x: 770,
				y: 100,
				scroll: 1,
				flip: true
			});

		if (PlayState.instance != state) return;
		for(k=>e in stageSprites) {
			stageScript.set(k, e);
		}
	}

	public function addCharPos(name:String, node:Access, ?nonXMLInfo:StageCharPosInfo):StageCharPos {
		var charPos = new StageCharPos();
		charPos.visible = charPos.active = false;
		charPos.name = name;

		if (nonXMLInfo != null) {
			charPos.setPosition(nonXMLInfo.x, nonXMLInfo.y);
			charPos.scrollFactor.set(nonXMLInfo.scroll, nonXMLInfo.scroll);
			charPos.flipX = nonXMLInfo.flip;
		}

		if (node != null) {
			charPos.x = Std.parseFloat(node.getAtt("x")).getDefault(charPos.x);
			charPos.y = Std.parseFloat(node.getAtt("y")).getDefault(charPos.y);
			charPos.camxoffset = Std.parseFloat(node.getAtt("camxoffset")).getDefault(charPos.camxoffset);
			charPos.camyoffset = Std.parseFloat(node.getAtt("camyoffset")).getDefault(charPos.camyoffset);
			charPos.skewX = Std.parseFloat(node.getAtt("skewx")).getDefault(charPos.skewX);
			charPos.skewY = Std.parseFloat(node.getAtt("skewy")).getDefault(charPos.skewY);
			charPos.alpha = Std.parseFloat(node.getAtt("alpha")).getDefault(charPos.alpha);
			charPos.flipX = (node.has.flip || node.has.flipX) ? (node.getAtt("flip") == "true" || node.getAtt("flipX") == "true") : charPos.flipX;

			var scale = Std.parseFloat(node.getAtt("scale")).getDefault(charPos.scale.x);
			charPos.scale.set(scale, scale);

			if (node.has.scroll) {
				var scroll:Null<Float> = Std.parseFloat(node.att.scroll);
				if (scroll != null) charPos.scrollFactor.set(scroll, scroll);
			} else {
				if (node.has.scrollx) {
					var scroll:Null<Float> = Std.parseFloat(node.att.scrollx);
					if (scroll != null) charPos.scrollFactor.x = scroll;
				}
				if (node.has.scrolly) {
					var scroll:Null<Float> = Std.parseFloat(node.att.scrolly);
					if (scroll != null) charPos.scrollFactor.y = scroll;
				}
			}
		}

		return addSprite(characterPoses[name] = charPos);
	}

	function addSprite<T:FlxObject>(sprite:T):T {
		state.add(sprite);
		if(onAddSprite != null) onAddSprite(sprite);
		return sprite;
	}

	public inline function isCharFlipped(posName:String, def:Bool = false)
		return characterPoses[posName] != null ? characterPoses[posName].flipX : def;

	public function applyCharStuff(char:Character, posName:String, id:Float = 0) {
		var charPos = characterPoses[char.curCharacter] != null ? characterPoses[char.curCharacter] : characterPoses[posName];
		if (charPos != null) {
			charPos.prepareCharacter(char, id);
			state.insert(state.members.indexOf(charPos), char);
		} else {
			state.add(char);
		}
	}

	public function beatHit(curBeat:Int) {}

	public function stepHit(curStep:Int) {}

	public function measureHit(curMeasure:Int) {}

	public static function getList(?mods:Bool = false, ?xmlOnly:Bool = false):Array<String> {
		var list:Array<String> = [];
		var extensions:Array<String> = ["xml"];
		if (!xmlOnly) extensions.push("hx");

		for (path in Paths.getFolderContent("data/stages/", false, mods ? MODS : BOTH)) {
			var extension = Path.extension(path);
			if (extensions.contains(extension)) {
				list.pushOnce(Path.withoutExtension(path));
			}
		}

		trace(list);

		return list;
	}
}

class StageCharPos extends FlxObject {
	public var extra:Map<String, Dynamic> = [];

	public var name:String;
	public var charSpacingX:Float = 20;
	public var charSpacingY:Float = 0;
	public var camxoffset:Float = 0;
	public var camyoffset:Float = 0;
	public var skewX:Float = 0;
	public var skewY:Float = 0;
	public var alpha:Float = 1;
	public var flipX:Bool = false;
	public var scale:FlxPoint = FlxPoint.get(1, 1);

	public function new() {
		super();
		active = false;
		visible = false;
	}

	public override function destroy() {
		scale.put();
		super.destroy();
	}

	public function prepareCharacter(char:Character, id:Float = 0) {
		char.setPosition(x + (id * charSpacingX), y + (id * charSpacingY));
		char.scrollFactor.set(scrollFactor.x, scrollFactor.y);
		char.scale.x *= scale.x; char.scale.y *= scale.y;
		char.cameraOffset += FlxPoint.weak(camxoffset, camyoffset);
		char.skew.x += skewX; char.skew.y += skewY;
		char.alpha *= alpha;
	}
}
typedef StageCharPosInfo = {
	var x:Float;
	var y:Float;
	var flip:Bool;
	var scroll:Float;
}