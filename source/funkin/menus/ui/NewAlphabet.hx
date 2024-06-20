package funkin.menus.ui;

import haxe.xml.Access;

using StringTools;

enum abstract AlphabetAlignment(String) from String to String {
    var LEFT = "left";
    var CENTER = "center";
    var RIGHT = "right";

    public function getMultiplier():Float {
        return switch(this) {
            case CENTER: 0.5;
            case RIGHT: 1.0;
			default: 0.0;
        }
    }
}

class NewAlphabet extends FlxSprite {
	public var text(default, set):String = "";
	@:isVar public var textWidth(get, set):Float;
	public var textHeight(get, null):Float;
	public var alignment:AlphabetAlignment = LEFT;
	var __laneWidths:Array<Float> = []; // TODO: add alignment.
	var __forceWidth:Float = 0; // TODO: implement functionality for this.
	var __queueResize:Bool = false;
	var __animTime:Float = 0;

	public var font(default, set):String;
	var defaultAdvance:Float = 40;
	var forceCase:String = "none";
	var lineGap:Float = 75;
	var fps:Int = 24;
	var defaults:Map<String, String> = [];
	var anims:Map<String, String> = [];
	var failedLetters:Array<String> = [];
	var yOffset:Map<String, Float> = [];

	public function new(?x:Float, ?y:Float, ?font:String = "bold") {
		super(x, y);
		this.font = font;
	}

	override function draw() {
		__animTime += FlxG.elapsed;
		var curLine = 0;
		var daText = switch (forceCase) {
			case "upper": text.toUpperCase();
			case "lower": text.toLowerCase();
			default: text;
		}

		var ogOffX = frameOffset.x;
		var ogOffY = frameOffset.y;
		frameOffset.addPoint(origin);
		frameOffset.x -= (textWidth - __laneWidths[0]) * alignment.getMultiplier();
		offset.subtract(origin.x * scale.x, origin.y * scale.y);

		for (i in 0...daText.length) {
			var letter = daText.charAt(i);
			if (letter == "\n") {
				curLine++;
				frameOffset.x = textWidth * 0.5 - (textWidth - __laneWidths[curLine]) * alignment.getMultiplier();
				frameOffset.y -= lineGap;
				continue;
			}

			var anim = getLetterAnim(letter);
			if (anim == null) {
				frameOffset.x -= defaultAdvance;
			} else {
				var frameToGet = Math.floor(__animTime * fps) % anim.numFrames;
				frame = frames.frames[anim.frames[frameToGet]];
				var offsetY = frame.sourceSize.y - lineGap;
				frameOffset.y += offsetY + (yOffset.exists(letter) ? yOffset.get(letter) : 0);
				super.draw();
				frameOffset.y -= offsetY + (yOffset.exists(letter) ? yOffset.get(letter) : 0);
				frameOffset.x -= frame.sourceSize.x;
			}
		}

		frameOffset.set(ogOffX, ogOffY);
		offset.add(origin.x * scale.x, origin.y * scale.y);
	}

	override function updateHitbox() {
		width = Math.abs(scale.x) * textWidth;
		height = Math.abs(scale.y) * textHeight;
		offset.set(-0.5 * (width - textWidth), -0.5 * (height - textHeight));
		origin.set(textWidth * 0.5, textHeight * 0.5);
	}

	function recalcSizes():Void {
		__queueResize = false;
		var curLine = 0;
		var daText = switch (forceCase) {
			case "upper": text.toUpperCase();
			case "lower": text.toLowerCase();
			default: text;
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

			var anim = getLetterAnim(letter);
			__laneWidths[curLine] += (anim != null) ? frames.frames[anim.frames[0]].sourceSize.x : defaultAdvance;
			@:bypassAccessor textWidth = Math.max(textWidth, __laneWidths[curLine]);
		}

		origin.set(textWidth * 0.5, textHeight * 0.5);
	}

	function getLetterAnim(char:String) {
		if (failedLetters.contains(char)) return null;
		else if (animation.exists(char)) return animation.getByName(char);

		var charCode:Int = char.charCodeAt(0);

		var anim:String = defaults.get("<NORMAL>").replace("LETTER", char);
		if (charCode >= 65 && charCode <= 90 && defaults.exists("UPPER"))
			anim = defaults.get("UPPER").replace("LETTER", char);
		else if (charCode >= 97 && charCode <= 122 && defaults.exists("LOWER"))
			anim = defaults.get("LOWER").replace("LETTER", char);
		if (anims.exists(char))
			anim = anims.get(char);

		animation.addByPrefix(char, anim, fps);
		if (!animation.exists(char)) {
			failedLetters.push(char);
			return null;
		}
		return animation.getByName(char);
	}

	function get_textWidth():Float {
		if (__queueResize)
			recalcSizes();
		return textWidth;
	}
	function set_textWidth(value:Float):Float {
		__queueResize = __queueResize || (__forceWidth != value);
		return __forceWidth = value;
	}

	function get_textHeight():Float {
		if (__queueResize)
			recalcSizes();
		return textHeight;
	}

	function set_text(value:String):String {
		__queueResize = __queueResize || (text != value);
		return text = value;
	}

	function set_font(value:String):String {
		if (font != value) {
			__queueResize = true;
			var xml:Xml = Xml.parse(openfl.Assets.getText(Paths.xml("alphabet/" + value))).firstElement();
			defaultAdvance = Std.parseFloat(xml.get("advance")).getDefault(40);
			lineGap = Std.parseFloat(xml.get("lineGap")).getDefault(75);
			fps = Std.parseInt(xml.get("fps")).getDefault(24);
			forceCase = xml.get("forceCasing").getDefault("none").toLowerCase();
			for (node in xml.elements()) {
				switch (node.nodeName) {
					case "spritesheet":
						frames = Paths.getFrames(node.firstChild().nodeValue);
					case "defaultAnim":
						defaults.set(node.get("casing").getDefault("<NORMAL>").toUpperCase(), node.firstChild().nodeValue);
					case "anim":
						anims.set(node.get("char"), node.firstChild().nodeValue);
						if (node.exists("y"))
							yOffset.set(node.get("char"), Std.parseFloat(node.get("y")).getDefault(0));
				}
			}
		}
		return font = value;
	}
}