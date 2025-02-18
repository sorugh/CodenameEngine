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
		// TODO: ATLAS VESION OF THIS CODE
		if (character._matrix == null || character.frame == null) return;

		for (camera in cameras) {
			character._rect.set(character._matrix.tx, character._matrix.ty, character.frame.frame.width * character._matrix.a, character.frame.frame.height * character._matrix.d);
			@:privateAccess character._rect = FlxG.camera.transformRect(character._rect);
			trace(character._rect);

			if (DrawUtil.line == null) DrawUtil.createDrawers();
			DrawUtil.line.camera = camera; DrawUtil.line.alpha = 0.75;

			DrawUtil.drawRect(character._rect, 1, 0xFF8F8A00);
			// yes i made a drawRect function for this purpose, no im not using it >:D
			DrawUtil.drawLine(
				CoolUtil.pointToScreenPosition(FlxPoint.weak(character._rect.x, character._rect.y), FlxG.camera, FlxPoint.weak()), 
				CoolUtil.pointToScreenPosition(FlxPoint.weak(character._rect.x + character._rect.width, character._rect.y), FlxG.camera, FlxPoint.weak()), 
				1, 0xFF007B8F
			);
			DrawUtil.drawLine(
				CoolUtil.pointToScreenPosition(FlxPoint.weak(character._rect.x, character._rect.y), FlxG.camera, FlxPoint.weak()), 
				CoolUtil.pointToScreenPosition(FlxPoint.weak(character._rect.x, character._rect.y + character._rect.height), FlxG.camera, FlxPoint.weak()), 
				1, 0xFF007B8F
			);
			DrawUtil.drawLine(
				CoolUtil.pointToScreenPosition(FlxPoint.weak(character._rect.x + character._rect.width, character._rect.y), FlxG.camera, FlxPoint.weak()), 
				CoolUtil.pointToScreenPosition(FlxPoint.weak(character._rect.x + character._rect.width, character._rect.y + character._rect.height), FlxG.camera, FlxPoint.weak()), 
				1, 0xFF007B8F
			);
			DrawUtil.drawLine(
				CoolUtil.pointToScreenPosition(FlxPoint.weak(character._rect.x, character._rect.y + character._rect.height), FlxG.camera, FlxPoint.weak()), 
				CoolUtil.pointToScreenPosition(FlxPoint.weak(character._rect.x + character._rect.width, character._rect.y + character._rect.height), FlxG.camera, FlxPoint.weak()), 
				1, 0xFF007B8F
			);
		}
	}

	public function drawCamera() {
		for (camera in cameras) {
			var camPos:FlxPoint = character.getCameraPosition();
			camPos -= camera.scroll;

			if (DrawUtil.line == null) DrawUtil.createDrawers();
			DrawUtil.line.camera = camera; DrawUtil.line.alpha = 0.75;

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