package funkin.backend.system.framerate;

import funkin.backend.system.macros.GitCommitMacro;
import openfl.text.TextField;

class CodenameBuildField extends TextField {
	public function new() {
		super();
		defaultTextFormat = Framerate.textFormat;
		autoSize = LEFT;
		multiline = wordWrap = false;
		text = 'Codename Engine ${Main.releaseCycle}\nCommit ${GitCommitMacro.commitNumber} (${GitCommitMacro.commitHash})';
	}
}
