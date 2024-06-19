package funkin.menus.ui;

#if (ALPHABET_TESTING)
/**
 * TEMPORARY CLASS.
 */
class NewAlphabetTest extends MusicBeatState {
	var alphabet:NewAlphabet;

	override function create() {
		super.create();
		bgColor = 0xFF808080;

		alphabet = new NewAlphabet(100, 360, "bold");
		alphabet.text = "hi tarr\ninsert smiley face";
		alphabet.alignment = CENTER;
		add(alphabet);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.ACCEPT) {
			switch (alphabet.alignment) {
				case LEFT:
					alphabet.text = "hey dont put me\non center.";
					alphabet.alignment = CENTER;
				case CENTER:
					alphabet.text = "hey put me\nback! >:(";
					alphabet.alignment = RIGHT;
				case RIGHT:
					alphabet.text = "Thank you.\nJeez some people.";
					alphabet.alignment = LEFT;
			}
		}
	}
}
#end