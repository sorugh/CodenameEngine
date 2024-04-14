package funkin.editors.ui;

import flixel.util.typeLimit.OneOfTwo;

class UIDropDown extends UISliceSprite {
	public var dropButton:UIButton;
	public var label:UIText;

	public var index:Int = 0;
	public var options:Array<String>;
	public var items:Array<DropDownItem>;
	public var key(get, never):String;
	inline function get_key():String {
		return items[index].label;
	}
	public var value(get, never):Dynamic;
	inline function get_value():Dynamic {
		return items[index].value;
	}

	public var onChange:Int->Void;

	var curMenu:UIContextMenu = null;

	public static function getItems(options:Array<String>):Array<DropDownItem> {
		return [for(i=>o in options) {label: o, value: i}];
	}

	public function new(x:Float, y:Float, width:Int = 320, height:Int = 32, _options:Array<OneOfTwo<DropDownItem, String>>, index:Int = 0) {
		super(x, y, width - height, height, 'editors/ui/inputbox'); // using same sprite cause fuck you

		var _items:Array<DropDownItem> = [];

		if(_options.length > 0) {
			if(_options[0] is String) {
				_items = getItems(_options);
			} else {
				_items = cast _options;
			}
		}

		this.items = _items;
		this.options = [for(o in _items) o.label]; // backwards compatibility
		this.index = index;

		cursor = BUTTON;

		label = new UIText(0, 0, width - height, items[index].label);
		members.push(label);

		dropButton = new UIButton(0, 0, "V", null, height, height);
		members.push(dropButton);
	}

	public static function indexOfItemValue(items:Array<DropDownItem>, value:Dynamic):Int {
		return [for(o in items) o.value].indexOf(value);
	}

	public static function indexOfItemLabel(items:Array<DropDownItem>, str:String):Int {
		return [for(o in items) o.label].indexOf(str);
	}

	public function setOption(newIndex:Int) {
		if (index != (index = newIndex)) {
			label.text = items[index].label;
			if (onChange != null)
				onChange(index);
		}
	}

	public override function update(elapsed:Float) {
		var opened = curMenu.contextMenuOpened();
		framesOffset = (opened || (hovered && FlxG.mouse.pressed)) ? 18 : (hovered ? 9 : 0);
		if (FlxG.mouse.justReleased && (hovered || dropButton.hovered)) {
			if (opened)
				UIState.state.curContextMenu.preventOutOfBoxClickDeletion();
			else
				openContextMenu();
		}

		super.update(elapsed);

		label.follow(this, 4, Std.int((bHeight - label.height) / 2));
		dropButton.follow(this, bWidth - bHeight, 0);
	}

	public function openContextMenu() {
		var screenPos = getScreenPosition(null, __lastDrawCameras[0] == null ? FlxG.camera : __lastDrawCameras[0]);
		curMenu = UIState.state.openContextMenu([
			for(k=>o in items) {
				icon: (k == index) ? 1 : 0,
				label: o.label
			}
		], function(_, i, _) {
			setOption(i);
		}, __lastDrawCameras[0].x + screenPos.x, __lastDrawCameras[0].y + screenPos.y + bHeight);
	}
}

typedef DropDownItem = {
	var label:String;
	var value:Dynamic;
}