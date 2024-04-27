package commands;

class Compiler {
	public static function test(args:Array<String>) {
		__runLime(args, ["test", getBuildTarget(), "-DTEST_BUILD"]);
	}
	public static function build(args:Array<String>) {
		__runLime(args, ["build", getBuildTarget(), "-DTEST_BUILD"]);
	}
	public static function release(args:Array<String>) {
		__runLime(args, ["build", getBuildTarget()]);
	}
	public static function testRelease(args:Array<String>) {
		__runLime(args, ["test", getBuildTarget()]);
	}

	public static function run(args:Array<String>) {
		__runLime(args, ["run", getBuildTarget()]);
	}

	private static function __runLime(args:Array<String>, arg:Array<String>) {
		for(a in args)
			arg.push(a);
		Sys.command("lime", arg);
	}

	public static function getBuildTarget() {
		return switch(Sys.systemName()) {
			case "Windows":
				"windows";
			case "Mac":
				"macos";
			case "Linux":
				"linux";
			case def:
				def.toLowerCase();
		}
	}
}