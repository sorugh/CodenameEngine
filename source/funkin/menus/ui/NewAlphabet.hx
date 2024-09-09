package funkin.menus.ui;

import funkin.menus.ui.effects.RegionEffect;

import flixel.animation.FlxAnimation;
import flixel.util.FlxDirectionFlags;
import flixel.math.FlxPoint;

import haxe.xml.Access;

using StringTools;
using flixel.util.FlxColorTransformUtil;

enum abstract AlphabetAlignment(Int) from Int to Int {
	var LEFT;
	var CENTER;
	var RIGHT;

	public function getMultiplier():Float {
		return switch(this) {
			case CENTER: 0.5;
			case RIGHT: 1.0;
			default: 0.0;
		}
	}

	@:from
	public static function fromString(value:String):AlphabetAlignment
		return switch(value) {
			case "left": LEFT;
			case "center": CENTER;
			case "right": RIGHT;
			default: LEFT;
		}
}

enum abstract CaseMode(Int) from Int to Int {
	var NONE;
	var UPPER;
	var LOWER;

	@:from
	public static function fromString(value:String):CaseMode
		return switch(value) {
			case "none": NONE;
			case "upper": UPPER;
			case "lower": LOWER;
			default: NONE;
		}
}

class NewAlphabet extends FlxSprite {
	public var effects:Array<RegionEffect> = [];
	var __renderData:AlphabetRenderData;
	
	public var text(default, set):String = "";
	@:isVar public var textWidth(get, set):Float;
	public var textHeight(get, null):Float;

	public var alignment:AlphabetAlignment = LEFT;
	public var forceCase:CaseMode = NONE;

	var __laneWidths:Array<Float> = []; // TODO: add alignment.
	var __forceWidth:Float = 0.0; // TODO: implement functionality for this.
	var __queueResize:Bool = false;
	var __animTime:Float = 0.0;
	var __ogForceScreen:Bool = false;

	public var originOffset:FlxPoint = FlxPoint.get();

	public var font(default, set):String;
	var transformMult:Int = 1; // 1 if multipliers (tint), 0 if offset.
	var defaultAdvance:Float = 40.0;
	var lineGap:Float = 75.0;
	var fps:Float = 24.0;
	var defaults:Map<String, String> = [];
	var anims:Map<String, String> = [];
	var failedLetters:Array<String> = [];
	var xOffset:Map<String, Float> = [];
	var yOffset:Map<String, Float> = [];
	var advances:Map<String, Float> = [];

	public function new(?x:Float, ?y:Float, ?font:String = "bold") {
		super(x, y);
		this.font = font;
		this.__renderData = new AlphabetRenderData(this);
	}

	override function update(elapsed:Float) {
		//super.update(elapsed);
		// FLXOBJECT UPDATE
		#if FLX_DEBUG
		@:privateAccess FlxBasic.activeCount += 1;
		#end

		last.set(x, y);

		if (path != null && path.active)
			path.update(elapsed);

		if (moves)
			updateMotion(elapsed);

		wasTouching = touching;
		touching = FlxDirectionFlags.NONE;
		// FLXOBJECT UPDATE END

		__animTime += elapsed;
		for (effect in effects)
			effect.effectTime += FlxG.elapsed * effect.speed;
	}

	override function draw() {
		__ogForceScreen = forceIsOnScreen;
		forceIsOnScreen = true;
		super.draw();
	}

	override function isSimpleRender(?camera:FlxCamera):Bool {
		return false; // maybe ill get simple render working another time??? not right now tho.
	}

	override function drawComplex(camera:FlxCamera) {
		forceIsOnScreen = __ogForceScreen;

		if (__queueResize)
			recalcSizes();
		var curLine = 0;
		var lastLine = 0;
		var daText = switch (forceCase) {
			case UPPER: text.toUpperCase();
			case LOWER: text.toLowerCase();
			case NONE: text;
		}

		var alignmentMultiplier = alignment.getMultiplier();

		var ogOffX = frameOffset.x;
		var ogOffY = frameOffset.y;
		frameOffset.x -= (textWidth - __laneWidths[0]) * alignmentMultiplier;

		var isGraphicsShader = shader != null && shader is flixel.graphics.tile.FlxGraphicsShader;
		var offsetMult = (1 - transformMult) * 255; 
		var ogRed:Float = colorTransform.redMultiplier;
		var ogGreen:Float = colorTransform.greenMultiplier;
		var ogBlue:Float = colorTransform.blueMultiplier;
		var ogAlpha:Float = colorTransform.alphaMultiplier;

		for (i in 0...daText.length) {
			__renderData.reset(this, ogRed, ogGreen, ogBlue, ogAlpha, daText.charAt(i));
			for (effect in effects) {
				if (effect.willModify(i, i - lastLine, __renderData))
					effect.modify(i, i - lastLine, __renderData);
			}

			var letter = __renderData.letter;
			if (letter == "\n") {
				curLine++;
				lastLine = i + 1;
				frameOffset.x = ogOffX - (textWidth - __laneWidths[curLine]) * alignmentMultiplier;
				frameOffset.y -= lineGap;
				continue;
			}

			var anim = getLetterAnim(letter);
			var advance:Float = getAdvance(letter, anim);

			if (anim == null || __renderData.alpha <= 0.0) {
				frameOffset.x -= advance;
			} else {
				var frameToGet = Math.floor(__animTime * fps) % anim.numFrames;
				frame = frames.frames[anim.frames[frameToGet]];

				var offsetX = (xOffset.exists(letter) ? xOffset.get(letter) : 0) + __renderData.offsetX;
				var offsetY = frame.sourceSize.y - lineGap + (yOffset.exists(letter) ? yOffset.get(letter) : 0) + __renderData.offsetY;
				frameOffset.x += offsetX;
				frameOffset.y += offsetY;
				if (!isOnScreen(camera)) {
					frameOffset.y -= offsetY;
					frameOffset.x -= offsetX;
					frameOffset.x -= advance;
					continue;
				}
				if (isGraphicsShader)
					shader.setCamSize(_frame.frame.x, _frame.frame.y, _frame.frame.width, _frame.frame.height);

				setColorTransform(
					__renderData.red * transformMult, __renderData.green * transformMult, __renderData.blue * transformMult, __renderData.alpha,
					Math.round(__renderData.red * offsetMult), Math.round(__renderData.green * offsetMult), Math.round(__renderData.blue * offsetMult), 0
				);
				super.drawComplex(camera);
				frameOffset.y -= offsetY;
				frameOffset.x -= offsetX;
				frameOffset.x -= advance;
			}
		}
		
		setColorTransform(ogRed, ogGreen, ogBlue, ogAlpha, 0, 0, 0, 0);
		frameOffset.set(ogOffX, ogOffY);
	}

	override function updateHitbox() {
		width = Math.abs(scale.x) * textWidth;
		height = Math.abs(scale.y) * textHeight;
		offset.set(-0.5 * (width - textWidth), -0.5 * (height - textHeight));
		origin.set(textWidth * 0.5 + originOffset.x, textHeight * 0.5 + originOffset.y);
	}

	function recalcSizes():Void {
		__queueResize = false;
		var curLine = 0;
		var daText = switch (forceCase) {
			case UPPER: text.toUpperCase();
			case LOWER: text.toLowerCase();
			case NONE: text;
		}
		@:bypassAccessor textWidth = 0;
		textHeight = lineGap;
		__laneWidths = [0];
		for (i in 0...daText.length) {
			var letter = daText.charAt(i);
			if (letter == "\n") {
				textHeight += lineGap;
				__laneWidths.push(0);
				curLine++;
				continue;
			}

			__laneWidths[curLine] += getAdvance(letter);
			@:bypassAccessor textWidth = Math.max(textWidth, __laneWidths[curLine]);
		}

		origin.set(textWidth * 0.5 + originOffset.x, textHeight * 0.5 + originOffset.y);
	}

	function getAdvance(letter:String, ?anim:FlxAnimation):Float {
		var advance:Null<Float> = defaultAdvance;
		if(advances.exists(letter)) {
			advance = advances.get(letter);
		} else {
			var anim = anim != null ? anim : getLetterAnim(letter);
			if(anim != null)
				advance = frames.frames[anim.frames[0]].sourceSize.x;
			advances.set(letter, advance);
		}
		return advance;
	}

	function getLetterAnim(char:String):FlxAnimation {
		if (failedLetters.contains(char)) return null;
		if (animation.exists(char)) return animation.getByName(char);

		var charCode:Int = char.charCodeAt(0);

		var anim:String = null;
		if (anims.exists(char))
			anim = anims.get(char);

		if (anim == null) {
			if (charCode >= 'A'.code && charCode <= 'A'.code && defaults.exists("UPPER"))
				anim = defaults.get("UPPER").replace("LETTER", char);
			else if (charCode >= 'a'.code && charCode <= 'z'.code && defaults.exists("LOWER"))
				anim = defaults.get("LOWER").replace("LETTER", char);
			else
				anim = defaults.get("<NORMAL>").replace("LETTER", char);
		}

		if(anim == null) {
			failedLetters.push(char);
			return null;
		}

		animation.addByPrefix(char, anim, fps);
		if (!animation.exists(char)) {
			failedLetters.push(char);
			return null;
		}
		return animation.getByName(char);
	}

	function checkNode(node:Xml) {
		switch (node.nodeName) {
			case "spritesheet":
				if (frames == null)
					frames = Paths.getFrames(node.firstChild().nodeValue);
				else {
					for (frame in Paths.getFrames(node.firstChild().nodeValue).frames)
						frames.pushFrame(frame);
				}
			case "defaultAnim":
				defaults.set(node.get("casing").getDefault("<NORMAL>").toUpperCase(), node.firstChild().nodeValue);
			case "anim":
				var char = node.get("char");
				anims.set(char, node.firstChild().nodeValue);
				if (node.exists("advance")) {
					var advance = Std.parseFloat(node.get("advance")).getDefault(defaultAdvance);
					advances.set(char, advance);
				}
				if (node.exists("x")) {
					// negative since flixel is weird
					var xOff = -Std.parseFloat(node.get("x")).getDefault(0.0);
					xOffset.set(char, xOff);
				}
				if (node.exists("y")) {
					var yOff = Std.parseFloat(node.get("y")).getDefault(0.0);
					yOffset.set(char, yOff);
				}
			case "languageSection":
				var langs = [for (lang in node.get("langs").split(",")) lang.trim()];
				if (langs.contains(Options.language)) {
					for (langNode in node.elements())
						checkNode(langNode);
				}
		}
	}

	function loadFont(value:String) {
		__queueResize = true;

		var xml:Xml = Xml.parse(Assets.getText(Paths.xml("alphabet/" + value))).firstElement();

		// reset old values
		defaults = new Map();
		anims = new Map();
		advances = new Map();
		xOffset = new Map();
		yOffset = new Map();
		failedLetters = [];

		defaultAdvance = Std.parseFloat(xml.get("advance")).getDefault(40.0);
		lineGap = Std.parseFloat(xml.get("lineGap")).getDefault(75.0);
		fps = Std.parseFloat(xml.get("fps")).getDefault(24.0);
		forceCase = xml.get("forceCasing").getDefault("none").toLowerCase();
		transformMult = (xml.get("useColorOffsets") == "true") ? 0 : 1;

		frames = null;

		for (node in xml.elements())
			checkNode(node);
	}

	override function destroy() {
		originOffset = FlxDestroyUtil.destroy(originOffset);
		failedLetters = [];
		super.destroy();
	}

	function get_textWidth():Float {
		if (__queueResize)
			recalcSizes();
		return textWidth;
	}
	function set_textWidth(value:Float):Float {
		if(!__queueResize)
			__queueResize = __forceWidth != value;
		return __forceWidth = value;
	}

	function get_textHeight():Float {
		if (__queueResize)
			recalcSizes();
		return textHeight;
	}

	function set_text(value:String):String {
		if(!__queueResize)
			__queueResize = text != value;
		return text = value;
	}

	function set_font(value:String):String {
		if (font != value) {
			loadFont(font = value);
		}
		return value;
	}
}