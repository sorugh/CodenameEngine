package funkin.editors.character;

import funkin.game.Character;

class CharacterGizmos extends FlxSprite {
	public var character:Character;

	public var boxGizmo:Bool = true;
	public var cameraGizmo:Bool = true;

	public override function draw() {
		super.draw();

		if (character == null) return;

		if (boxGizmo) drawHitbox();
		if (cameraGizmo) drawCamera();
	}

	public function drawHitbox() {
		for (camera in cameras) {
			if (character.animateAtlas != null) {
				// TODO: ATLAS CALCUATIONS 
				character._rect.set();
			} else if (character._matrix != null && character.frame != null) {
				character._rect.set(character._matrix.tx, character._matrix.ty, character.frame.frame.width * character._matrix.a, character.frame.frame.height * character._matrix.d);
				character._rect.offset(-character.cameras[0].viewMarginLeft, -character.cameras[0].viewMarginTop);
				character._rect.x *= character.cameras[0].zoom;
				character._rect.y *= character.cameras[0].zoom;
				character._rect.width *= character.cameras[0].zoom;
				character._rect.height *= character.cameras[0].zoom;
			}

			if (DrawUtil.line == null) DrawUtil.createDrawers();
			DrawUtil.line.camera = camera; DrawUtil.line.alpha = 0.85;

			DrawUtil.drawRect(character._rect, 1, 0xFF007B8F);
		}
	}

	public function drawCamera() {
		for (camera in cameras) {
			var camPos:FlxPoint = character.getCameraPosition();
			camPos -= camera.scroll;

			if (DrawUtil.line == null) DrawUtil.createDrawers();
			DrawUtil.line.camera = camera; DrawUtil.line.alpha = 1;

			DrawUtil.drawLine(
				CoolUtil.pointToScreenPosition(FlxPoint.weak(camPos.x - 8, camPos.y), FlxG.camera, FlxPoint.weak()),
				CoolUtil.pointToScreenPosition(FlxPoint.weak(camPos.x + 8, camPos.y), FlxG.camera, FlxPoint.weak()),
			1, 0xFF00A0B9);

			DrawUtil.drawLine(
				CoolUtil.pointToScreenPosition(FlxPoint.weak(camPos.x, camPos.y - 8), FlxG.camera, FlxPoint.weak()),
				CoolUtil.pointToScreenPosition(FlxPoint.weak(camPos.x, camPos.y + 8), FlxG.camera, FlxPoint.weak()),
			1, 0xFF00A0B9);

			camPos.put();

		}
	}
}