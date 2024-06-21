package funkin.menus.ui;

#if (ALPHABET_TESTING)
/**
 * TEMPORARY CLASS.
 */
class NewAlphabetTest extends MusicBeatState {
	var alphabet:NewAlphabet;

	override function create() {
		super.create();
		MusicBeatState.skipTransIn = true;
		bgColor = 0xFF808080;

		alphabet = new NewAlphabet(100, 360, "bold");
		alphabet.text = "hi tarr\ninsert smiley face";
		alphabet.alignment = CENTER;
		add(alphabet);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (controls.BACK) {
			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();
			FlxG.resetState();
		}
	}
}
#end