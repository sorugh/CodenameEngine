package funkin.options;

import flixel.util.FlxSignal;
import funkin.backend.system.framerate.Framerate;
import funkin.editors.ui.UIState;

interface ITreeOption {
	var desc:String;
	var selected:Bool;

	function changeSelection(change:Int);
	function select():Void;
}

class TreeMenu extends UIState {
	public var onMenuClosed:FlxTypedSignal<TreeMenuScreen->Void> = new FlxTypedSignal();
	public var onMenuChanged:FlxTypedSignal<TreeMenuScreen->Void> = new FlxTypedSignal();

	public var tree(default, null):Array<TreeMenuScreen>;
	public var length(default, null):Int = 0;
	public var lastMenu:Null<TreeMenuScreen>;
	public var destroyMenus:Bool = true;

	public var exitCallback:TreeMenu->Void;

	public var titleLabel:FunkinText;
	public var descLabel:FunkinText;
	public var bgLabel:FlxSprite;

	var menuChangeTween:FlxTween;
	var _drawer:TreeMenuDrawer;

	public function new(exitCallback:TreeMenu->Void,
		scriptsAllowed:Bool = true, ?scriptName:String)
	{
		super(scriptsAllowed, scriptName);
		this.exitCallback = exitCallback;
	}

	override function create() {
		super.create();

		bgLabel = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bgLabel.alpha = 0.25;
		bgLabel.scrollFactor.set();

		titleLabel = new FunkinText(4, 4, FlxG.camera.width - 8, 32);
		titleLabel.borderSize = 1.25;
		titleLabel.scrollFactor.set();

		descLabel = new FunkinText(4, 0, FlxG.camera.width - 8, 16);
		descLabel.scrollFactor.set();
	}

	override function createPost() {
		super.createPost();

		if ((length = tree.length) != 0) {
			updateMenuPositions(true);
			tree.last().inputEnabled = true;
		}
		else
			add(new TreeMenuScreen("Fallback TreeMenuScreen", "Please insert menus into \"tree\" variable in your extended class in create or before createPost"));

		add(_drawer = new TreeMenuDrawer(this));
		add(bgLabel);
		add(titleLabel);
		add(descLabel);
		updateLabels();
	}

	public function updateMenuPositions(fromIndex:Int = 0, cameraScroll = false) {
		var last = tree[position - 1], menu:TreeMenuScreen;
		while (fromIndex < length) if ((menu = tree[fromIndex++]) != null) {
			menu.x = last == null ? 0 : last.x + Math.max(FlxG.camera.width, last.width);
			last = menu;
		}

		if (menuChangeTween != null && menuChangeTween.active) menuChangeTween.cancel();
		if (cameraScroll) FlxG.camera.scroll.x = lastMenu.x;
	}

	public function updateLabels() {
		var s = "", last = tree.last();
		for (menu in tree) if (menu != null) s += menu.name + " > ";

		titleLabel.text = s;
		descLabel.y = titleLabel.y + titleLabel.height + 2;

		updateDesc();
	}

	public function updateDesc(?customText:String) {
		var last = tree.last();

		descLabel.text = last.desc;
		if (customText != null && customText.length > 0) descLabel.text += "\n" + customText;
		else if (last.curSelected >= 0 && last.curSelected < last.length && last.members[last.curSelected] is ITreeOption)
			descLabel.text += "\n" + (cast last.members[last.curSelected]:ITreeOption).desc;

		bgLabel.scale.set(FLxG.width, descLabel.y + descLabel.height + 2);
		bgLabel.updateHitbox();

		Framerate.offset.y = bgLabel.height + 2;
	}

	public function add(menu:TreeMenuScreen):TreeMenuScreen {
		if (menu == null) return null;
		if (tree.indexOf(menu) != -1) return menu;

		tree.push(menu);
		menu.parent = this;
		length++;

		var prev = tree[length - 1];
		menu.x = prev == null ? 0 : prev.x + Math.max(FlxG.camera.width, prev.width);

		menuChanged();
		menu.inputEnabled = true;
		prev.inputEnabled = false;

		return menu;
	}

	public function insert(position:Int, menu:TreeMenuScreen):TreeMenuScreen {
		if (menu == null) return null;
		if (tree.indexOf(menu) != -1) return menu;

		if (position < 0) position = length - ((-position - 1) % length);
		tree.insert(position, menu);
		menu.parent = this;

		var lastChanged = position >= length++;
		updateMenuPositions(position, !lastChanged);

		if (lastChanged) {
			menuChanged();
			menu.inputEnabled = true;
			tree[length - 1].inputEnabled = false;
		}

		return menu;
	}

	public function pop():TreeMenuScreen {
		(lastMenu = tree.pop(position)).parent = null;
		length--;

		menuChanged();
		lastMenu.inputEnabled = false;
		menu.inputEnabled = true;

		return lastMenu;
	}

	public function remove(menu:TreeMenuScreen):TreeMenuScreen {
		return if (menu == null) null; else removePosition(tree.indexOf(menu));
	}

	public function removePosition(position:Int):TreeMenuScreen {
		if (position < 0 || position >= length) return null;

		destroyLastMenu();
		(lastMenu = tree.swapAndPop(position)).parent = null;

		if (position == --length) {
			menuChanged();
			lastMenu.inputEnabled = false;
			tree[length - 1].inputEnabled = true;
		}
		else {
			updateMenuPositions(position, true);
			updateLabels();
		}

		return lastMenu;
	}

	public function menuChanged() {
		if (length == 0) exit();
		else {
			updateLabels();

			if (menuChangeTween != null && menuChangeTween.active) menuChangeTween.cancel();

			menuChangeTween = FlxTween.tween(FlxG.camera.scroll, {x: tree.last().x}, 1.5, {ease: menuTransitionEase, onComplete: (t) -> {
				for (menu in tree) if (menu != null) menu.transitioning = false;
				lastMenu.transitioning = false;
			}});

			for (menu in tree) if (menu != null) menu.transitioning = true;
			lastMenu.transitioning = true;
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		var i = 0, menu:TreeMenuScreen;
		while (i < length) {
			if ((menu = tree[i++]) == null || !menu.active || !menu.exists) continue;
			if (i == length || menu.persistentUpdate || menu.transitioning) menu.update(elapsed);
		}

		if (lastMenu != null) {
			if (lastMenu.transitioning) lastMenu.update(elapsed);
			else destroyLastMenu();
		}

		// in case path gets so long it goes offscreen, ALTHOUGH this nevers happens anyway since we have set a expected width to the label.
		//titleLabel.x = lerp(titleLabel.x, Math.max(0, FlxG.width - 4 - titleLabel.width), 0.125);
	}

	override function destroy() {
		super.destroy();
		destroyLastMenu();
	}

	override function onResize(width:Int, height:Int) {
		super.onResize(width, height);
		if (!UIState.resolutionAware) return;

		if (width < FlxG.initialWidth || height < FlxG.initialHeight) {
			width = FlxG.initialWidth;
			height = FlxG.initialHeight;
		}

		updateMenuPositions(true);
		descLabel.width = titleLabel.width = (bgLabel.width = width) - 8;
	}

	public function reloadStrings() {
		for (menu in tree) if (menu != null) menu.reloadStrings();
	}

	public function destroyLastMenu() {
		lastMenu = destroyMenus ? FlxDestroyUtil.destroy(lastMenu) : null;
	}

	public function exit() {
		if (exitCallback != null) return exitCallback(this);

		FlxG.switchState(new MainMenuState());
	}

	public function updateAll(elapsed:Float) {
		for (menu in tree) if (menu != null && menu.active && menu.exists) menu.update(elapsed);
	}

	public dynamic function menuTransitionEase(e:Float) return FlxEase.quintInOut(FlxEase.cubeOut(e));
}

final class TreeMenuDrawer extends FlxBasic {
	public var parent:TreeMenu;
	public function new(parent:TreeMenu) {
		this.parent = parent;
		moves = false;
	}

	override function draw() {
		var i = 0, menu:TreeMenuScreen;
		while (i < parent.length) {
			if ((menu = parent.tree[i++]) == null || !menu.active || !menu.exists) continue;
			if (i == length || menu.persistentUpdate || menu.transitioning) menu.update(elapsed);
		}

		if (parent.lastMenu != null) parent.lastMenu.draw();
	}
}