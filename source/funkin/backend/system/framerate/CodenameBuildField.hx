package funkin.backend.system.framerate;

import funkin.backend.system.macros.GitCommitMacro;
import openfl.text.TextField;

class CodenameBuildField extends TextField {
	public function new() {
		super();
		defaultTextFormat = Framerate.textFormat;
		autoSize = LEFT;
		multiline = wordWrap = false;
		reload();
	}

	public function reload() {
		var buildText = Flags.FPS_BUILD_TEXT.replace("${build}", Std.string(GitCommitMacro.commitNumber)).replace("${commit}", GitCommitMacro.commitHash);
		text = 'Codename Engine ${Main.releaseCycle}\n' + buildText;
	}
}
