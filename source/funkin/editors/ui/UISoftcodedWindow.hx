package funkin.editors.ui;

import flixel.math.FlxPoint;
import funkin.backend.chart.ChartData.ChartMetaData;
import funkin.backend.scripting.HScript;
import funkin.backend.scripting.Script;
import funkin.editors.extra.PropertyButton;
import funkin.editors.stage.elements.StageElementButton;
import funkin.editors.ui.UIDropDown;
import haxe.xml.Access;
import hscript.*;
import hscript.Expr.Error;
import hscript.Interp;
import hscript.Parser;
import haxe.io.Path;

using StringTools;

class UISoftcodedWindow extends UISubstateWindow {
	public var saveButton:UIButton;
	public var closeButton:UIButton;

	var elementMap:Map<String, UISprite> = [];

	var xmlPath:String;
	var filename:String;
	var customVariables:Map<String, Dynamic>;

	public function new(xmlPath:String, customVariables:Map<String, Dynamic> = null) {
		super();
		this.xmlPath = xmlPath;
		this.filename = Path.withoutDirectory(xmlPath);
		this.customVariables = customVariables;
	}

	var parser = HScript.initParser();
	var interp = new Interp();

	function set(name:String, value:Dynamic) {
		interp.variables.set(name, value);
	}

	function get(name:String):Dynamic {
		return interp.variables.get(name);
	}

	function execString(input:String):String {
		if(input.indexOf("${") == -1) return input;
		var text = "";
		while(input.length > 0) {
			var idx = input.indexOf("${");
			if(idx == -1) {
				text += input;
				break;
			}
			text += input.substring(0, idx);
			var ei = input.indexOf("}", idx);
			if(ei == -1) {
				text += input.substring(idx);
				break;
			}
			var block = input.substring(idx+2, ei);
			text += exec(block);
			input = input.substring(ei + 1);
		}
		return text;
	}

	function execDefault(code:String, defaultValue:Dynamic):Dynamic {
		return CoolUtil.getDefault(exec(code), defaultValue);
	}

	function execAtt(el:Access, key:String, defaultValue:Dynamic):Dynamic {
		return execDefault(el.getAtt(key), defaultValue);
	}

	function exec(code:String):Dynamic {
		try {
			if (code != null && code.trim() != "")
				return interp.execute(parser.parseString(code, filename));
		} catch(e:Error) {
			_errorHandler(e);
		} catch(e) {
			_errorHandler(new Error(ECustom(e.toString()), 0, 0, filename, 0));
		}
		return null;
	}

	function _errorHandler(error:Error) {
		var fileName = error.origin;
		var fn = '$fileName:${error.line}: ';
		var err = error.toString();
		if (err.startsWith(fn)) err = err.substr(fn.length);

		Logs.traceColored([
			Logs.logText(fn, GREEN),
			Logs.logText(err, RED)
		], ERROR);
	}

	public override function create() {
		var layout = new Access(Xml.parse(Assets.getText('assets/editors/' + xmlPath)).firstElement());
		winTitle = layout.getAtt("title").getDefault(winTitle);
		winWidth = Std.parseInt(layout.getAtt("width")).getDefault(winWidth);
		winHeight = Std.parseInt(layout.getAtt("height")).getDefault(winHeight);

		for(k=>e in Script.getDefaultVariables()) {
			set(k, e);
		}
		set("self", this);
		set("hasSaveButtons", true);
		for(k=>v in customVariables) {
			set(k, v);
		}
		set("last", null);

		super.create();

		function addLabelOn(ui:UISprite, text:String)
			add(new UIText(ui.x, ui.y - 24, 0, text));

		for(el in layout.elements) {
			var type = el.name;
			//var type:String = el.getAtt("type");
			var name:String = execString(el.getAtt("name"));
			var label:String = execString(el.getAtt("label"));
			var text:String = execString(el.getAtt("text"));
			var x:Float = execAtt(el, "x", 0);
			var y:Float = execAtt(el, "y", 0);
			var width:Null<Int> = exec(el.getAtt("width"));
			var height:Null<Int> = exec(el.getAtt("height"));
			var size:Int = execAtt(el, "size", 28);

			trace(type, name, label, text, x, y, width, height, size);

			var sprite:FlxSprite = switch(type) {
				case "set":
					set(execString(el.getAtt("name")), exec(el.getAtt("value")));
					continue;
				case "image":
					var spr = XMLUtil.createSpriteFromXML(el, "", LOOP);
					cast add(spr);
				case "solid":
					var spr = new FunkinSprite(x, y).makeSolid(
						execAtt(el, "width", 100),
						execAtt(el, "height", 100),
						execAtt(el, "color", 0xFFFFFFFF)
					);
					cast add(spr);
				case "exec":
					exec(el.innerData);
					continue;
				case "textbox":
					var textBox = new UITextBox(x, y, text, width, height, execAtt(el, "multiline", false));//(el.getAtt("multiline").getDefault("false") == "true"));
					add(textBox);
					addLabelOn(textBox, label);
					textBox;
				case "title":
					cast add(new UIText(x, y, 0, text, size));
				case "stepper":
					// x:Float, y:Float, value:Float = 0, step:Float = 1, precision:Int = 0, ?min:Float, ?max:Float, w:Int = 180, h:Int = 32
					var stepper = new UINumericStepper(
						x,
						y,
						execAtt(el, "value", 0),
						execAtt(el, "step", 1),
						execAtt(el, "precision", 0),
						execAtt(el, "min", null),
						execAtt(el, "max", null),
						width,
						height
					);
					add(stepper);
					addLabelOn(stepper, label);
					stepper;
				case "checkbox":
					var checkbox = new UICheckbox(x, y, text, execAtt(el, "value", false));
					add(checkbox);
					addLabelOn(checkbox, label);
					checkbox;
				case "slider":
					var slider = new UISlider(x, y, width, execAtt(el, "value", 0), execAtt(el, "segments", []), execAtt(el, "centered", false));
					add(slider);
					addLabelOn(slider, label);
					slider;
				case "dropdown":
					var items:Array<DropDownItem> = [];
					for(i=>node in el.nodes.item)
						items.push({label: execString(node.getAtt("label")), value: execAtt(node, "value", i)});
					var curValue = execAtt(el, "value", null);
					var index = UIDropDown.indexOfItemValue(items, curValue);
					if (index == -1) index = 0;

					var dropdown = new UIDropDown(x, y, width, height, items, index);
					add(dropdown);
					addLabelOn(dropdown, label);
					dropdown;
				// UIColorwheel
				// UIAudioPlayer
				// UIButtonList
				// UIFileExplorer
				// UIAutoCompleteTextbox
				default: {
					Logs.trace("Unknown element type: " + type, ERROR, RED);
					Logs.trace("Skipping element: " + el.x.toString(), ERROR, RED);
					continue;
				}
			}

			set("last", sprite);
			if(name != null) set(name, sprite);
			if(sprite is UISprite) elementMap.set(name, cast sprite);
		}

		if(get("hasSaveButtons")) {
			saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20, windowSpr.y + windowSpr.bHeight - 20, "Save & Close", function() {
				saveData();
				close();
			}, 125);
			saveButton.x -= saveButton.bWidth;
			saveButton.y -= saveButton.bHeight;

			closeButton = new UIButton(saveButton.x - 20, saveButton.y, "Close", function() {
				close();
			}, 125);
			closeButton.color = 0xFFFF0000;
			closeButton.x -= closeButton.bWidth;
			//closeButton.y -= closeButton.bHeight;
			add(closeButton);
			add(saveButton);
		}
	}

	function getElement(name:String):UISprite {
		return elementMap.get(name);
	}

	function callFunc(name:String, args:Array<Dynamic>) {
		if (interp == null) return null;
		if (!interp.variables.exists(name)) return null;

		var func = interp.variables.get(name);
		if (func != null && Reflect.isFunction(func))
			return Reflect.callMethod(null, func, args);

		return null;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		callFunc("onUpdate", [elapsed]);
	}

	public function saveData() {
		for (el in elementMap) {
			if(el is UINumericStepper) {
				var el:UINumericStepper = cast el;
				@:privateAccess el.__onChange(el.label.text);
			}
		}

		callFunc("onSave", []);
	}
}