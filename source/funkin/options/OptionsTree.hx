// REMOVE THIS WHEN COMPLETE

package funkin.options;

class OptionsTree extends FlxTypedGroup<OptionsScreen> {
	public var lastMenu:OptionsScreen;
	public var treeParent:TreeMenu;
	public var wasClosing:Bool = false;
	//public override function new() {
	//	super();
	//}

	public override function update(elapsed:Float) {
		var last = members.last();
		if (last != null)
			last.update(elapsed);
	}

	public function updateAll(elapsed:Float) {
		for (member in members) {
			if(member == null) continue;
			if(member.active && member.exists) {
				member.update(elapsed);
			}
		}
	}

	public override function draw() {
		super.draw();
		if (lastMenu != null) { // manually draw lastMenu since it got removed from the members list
			lastMenu.draw();
		}
	}

	public function reloadStrings() {
		for(o in members) {
			o.reloadStrings();
		}
	}

	public override function add(m:OptionsScreen) {
		super.add(m);
		setup(m);
		clearLastMenu();
		wasClosing = false;
		onMenuChange();
		return m;
	}
	public override function insert(pos:Int, m:OptionsScreen) {
		var last = members.last();
		super.insert(pos, m);
		setup(m);
		if (last != members.last()) {
			wasClosing = false;
			onMenuChange();
		}
		return m;
	}

	public function setup(m:OptionsScreen) {
		m.onClose = __subMenuClose;
		m.id = members.indexOf(m);
		m.parent = this;
		m.update(0);
	}

	function __subMenuClose(m:OptionsScreen) {
		wasClosing = true;
		clearLastMenu();
		lastMenu = m;
		remove(m, true);
		onMenuChange();
		onMenuClose(m);
	}

	public function clearLastMenu() {
		lastMenu = FlxDestroyUtil.destroy(lastMenu);
	}

	public override function destroy() {
		super.destroy();
		lastMenu = FlxDestroyUtil.destroy(lastMenu);
	}

	public dynamic function onMenuChange() {

	}

	public dynamic function onMenuClose(m:OptionsScreen) {
	}
}