/**
 * THIS FILE IS TEMPORARY UNTIL TRANSFORMS ARE AT A USEABLE STATE.
 * TODO:
 * 		- !!!! MOVE BACK TO SOURCE !!!!
 * 		- Rotation
 * 		- Skewing
 * 		- Angle + Scale (like already at a angle)
 */

import funkin.editors.stage.StageEditor;
import funkin.backend.utils.WindowUtils;
import openfl.Lib;

var exID = StageEditor.exID;

function tryUpdateHitbox(sprite) {
	var spriteNode = sprite.extra.get(exID("node"));
	if (spriteNode.exists("updateHitbox") && spriteNode.get("updateHitbox") == "true") {
		sprite.updateHitbox();
		return true;
	}

	if (!FlxG.keys.pressed.ALT) {
		sprite.x = storedPos.x - (sprite.frameWidth * (storedScale.x - sprite.scale.x) * 0.5);
		sprite.y = storedPos.y - (sprite.frameHeight * (storedScale.y - sprite.scale.y) * 0.5);
	}
	return false;
}

function create() {
	WindowUtils.preventClosing = true;
	WindowUtils.resetClosing();
	WindowUtils.onClosing = function() {
		if(!FlxG.keys.pressed.ALT) {
			Lib.application.window.onClose.cancel();
			FlxG.switchState(new StageEditor(StageEditor.__stage));
			trace("you dont need to close doofus goofus");
		}
	}
}

function update() {
	if(FlxG.keys.justPressed.R) {
		trace("reloading");
		FlxG.switchState(new StageEditor(StageEditor.__stage));
	}
}

function genericScale(sprite, relative, doX, doY) {
	var relativeMult = 1 / (FlxMath.lerp(1, stageCamera.zoom, sprite.zoomFactor) / stageCamera.zoom) * (FlxG.keys.pressed.ALT ? 2 : 1);
	relative.x *= relativeMult;
	relative.y *= relativeMult;

	var width = sprite.frameWidth * storedScale.x;
	var height = sprite.frameHeight * storedScale.y;
	if(doX) width -= relative.x;
	if(doY) height -= relative.y;
	CoolUtil.setGraphicSizeFloat(sprite, width, height);

	if(FlxG.keys.pressed.SHIFT) {
		var nscale = Math.max(sprite.scale.x, sprite.scale.y);
		sprite.scale.set(nscale, nscale);
	}

	var updatedHitbox = tryUpdateHitbox(sprite);
	if (FlxG.keys.pressed.ALT) {
		sprite.x = storedPos.x;
		sprite.y = storedPos.y;
		if(updatedHitbox) {
			sprite.x += (sprite.frameWidth * (storedScale.x - sprite.scale.x) * 0.5);
			sprite.y += (sprite.frameHeight * (storedScale.y - sprite.scale.y) * 0.5);
		}
		return true;
	}
	return !updatedHitbox;
}

function genericOppositeScale(sprite, relative, scaleX, scaleY, repositionX, repositionY) {
	if(repositionX) relative.x *= -1;
	if(repositionY) relative.y *= -1;
	var repositioned = genericScale(sprite, relative, scaleX, scaleY);
	if (!repositioned) {
		if(repositionX) sprite.x = storedPos.x + (sprite.frameWidth * (storedScale.x - sprite.scale.x));
		if(repositionY) sprite.y = storedPos.y + (sprite.frameHeight * (storedScale.y - sprite.scale.y));
	} else if (!FlxG.keys.pressed.ALT) {
		if(repositionX) sprite.x += (sprite.frameWidth * (storedScale.x - sprite.scale.x));
		if(repositionY) sprite.y += (sprite.frameHeight * (storedScale.y - sprite.scale.y));
	}
}

function SCALE_BOTTOM_RIGHT(sprite, relative) {
	genericScale(sprite, relative, true, true);
}

function SCALE_TOP_RIGHT(sprite, relative) {
	genericOppositeScale(sprite, relative, true, true, false, true);
}

function SCALE_TOP_LEFT(sprite, relative) {
	genericOppositeScale(sprite, relative, true, true, true, true);
}

function SCALE_BOTTOM_LEFT(sprite, relative) {
	genericOppositeScale(sprite, relative, true, true, true, false);
}

function SCALE_LEFT(sprite, relative) {
	genericOppositeScale(sprite, relative, true, false, true, false);
}

function SCALE_RIGHT(sprite, relative) {
	genericScale(sprite, relative, true, false);
}

function SCALE_TOP(sprite, relative) {
	genericOppositeScale(sprite, relative, false, true, false, true);
}

function SCALE_BOTTOM(sprite, relative) {
	genericScale(sprite, relative, false, true);
}

function SKEW_LEFT(sprite, relative) {}

function SKEW_BOTTOM(sprite, relative) {}

function SKEW_TOP(sprite, relative) {}

function SKEW_RIGHT(sprite, relative) {}

function ROTATE(sprite, relative) {}

