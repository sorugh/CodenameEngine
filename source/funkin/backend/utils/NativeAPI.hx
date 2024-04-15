package funkin.backend.utils;

import haxe.macro.Expr.Case;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;
import funkin.backend.utils.native.*;

/**
 * Class for functions that talk to a lower level than haxe, such as message boxes, and more.
 * Some functions might not have effect on some platforms.
 */
class NativeAPI {
	@:dox(hide) public static function registerAudio() {
		#if windows
		Windows.registerAudio();
		#end
	}

	@:dox(hide) public static function registerAsDPICompatible() {
		#if windows
		Windows.registerAsDPICompatible();
		#end
	}

	/**
	 * Allocates a new console. The console will automatically be opened
	 */
	public static function allocConsole() {
		#if windows
		Windows.allocConsole();
		Windows.clearScreen();
		#end
	}

	public static function setDarkMode(title:String, enable:Bool) {
		#if windows
		Windows.setDarkMode(title, enable);
		#end
	}

	/**
	 * Shows a message box
	 */
	public static function showMessageBox(caption:String, message:String, icon:MessageBoxIcon = MSG_WARNING) {
		#if windows
		Windows.showMessageBox(caption, message, icon);
		#else
		lime.app.Application.current.window.alert(message, caption);
		#end
	}

	/**
	 * Sets the console colors
	 */
	public static function setConsoleColors(foregroundColor:ConsoleColor = NONE, ?backgroundColor:ConsoleColor = NONE) {
		if(Main.noTerminalColor) return;

		#if (windows && !hl)
		if(foregroundColor == NONE)
			foregroundColor = LIGHTGRAY;
		if(backgroundColor == NONE)
			backgroundColor = BLACK;

		var fg = cast(foregroundColor, Int);
		var bg = cast(backgroundColor, Int);
		Windows.setConsoleColors((bg * 16) + fg);
		#else
		#if sys
		Sys.print("\x1b[0m");
		if(foregroundColor != NONE)
			Sys.print("\x1b[" + Std.int(consoleColorToANSI(foregroundColor)) + "m");
		if(backgroundColor != NONE)
			Sys.print("\x1b[" + Std.int(consoleColorToANSI(backgroundColor) + 10) + "m");
		#end
		#end
	}

	/**
	 * Set cursor icon.
	**/
	public static function setCursorIcon(icon:CodeCursor) {
		#if mac
		Mac.setMouseCursorIcon(cast icon);
		#else
		Mouse.cursor = icon.toOpenFL();
		#end
	}

	public static function consoleColorToANSI(color:ConsoleColor) {
		return switch(color) {
			case BLACK:			30;
			case DARKBLUE:		34;
			case DARKGREEN:		32;
			case DARKCYAN:		36;
			case DARKRED:		31;
			case DARKMAGENTA:	35;
			case DARKYELLOW:	33;
			case LIGHTGRAY:		37;
			case GRAY:			90;
			case BLUE:			94;
			case GREEN:			92;
			case CYAN:			96;
			case RED:			91;
			case MAGENTA:		95;
			case YELLOW:		93;
			case WHITE | _:		97;
		}
	}

	public static function consoleColorToOpenFL(color:ConsoleColor) {
		return switch(color) {
			case BLACK:			0xFF000000;
			case DARKBLUE:		0xFF000088;
			case DARKGREEN:		0xFF008800;
			case DARKCYAN:		0xFF008888;
			case DARKRED:		0xFF880000;
			case DARKMAGENTA:	0xFF880000;
			case DARKYELLOW:	0xFF888800;
			case LIGHTGRAY:		0xFFBBBBBB;
			case GRAY:			0xFF888888;
			case BLUE:			0xFF0000FF;
			case GREEN:			0xFF00FF00;
			case CYAN:			0xFF00FFFF;
			case RED:			0xFFFF0000;
			case MAGENTA:		0xFFFF00FF;
			case YELLOW:		0xFFFFFF00;
			case WHITE | _:		0xFFFFFFFF;
		}
	}
}

enum abstract ConsoleColor(Int) {
	var BLACK = 0;
	var DARKBLUE = 1;
	var DARKGREEN = 2;
	var DARKCYAN = 3;
	var DARKRED = 4;
	var DARKMAGENTA = 5;
	var DARKYELLOW = 6;
	var LIGHTGRAY = 7;
	var GRAY = 8;
	var BLUE = 9;
	var GREEN = 10;
	var CYAN = 11;
	var RED = 12;
	var MAGENTA = 13;
	var YELLOW = 14;
	var WHITE = 15;

	var NONE = -1;
}

enum abstract MessageBoxIcon(Int) {
	var MSG_ERROR = 0x00000010;
	var MSG_QUESTION = 0x00000020;
	var MSG_WARNING = 0x00000030;
	var MSG_INFORMATION = 0x00000040;
}

enum abstract CodeCursor(String) {
	var CUSTOM;// = "arrow";
	var ARROW;// = "arrow";
	var CLICK;// = "click";
	var CROSSHAIR;// = "crosshair";
	var HAND;// = "hand";
	var IBEAM;// = "ibeam";
	var MOVE;// = "move";

	var RESIZE_H;// = "resize_we";
	var RESIZE_V;// = "resize_ns";
	var RESIZE_TL;// = "resize_nw";
	var RESIZE_TR;// = "resize_ne";
	var RESIZE_BL;// = "resize_sw";
	var RESIZE_BR;// = "resize_se";
	var RESIZE_T;// = "resize_n";
	var RESIZE_B;// = "resize_b";
	var RESIZE_L;// = "resize_w";
	var RESIZE_R;// = "resize_e";

	var WAIT;// = "wait";
	var WAIT_ARROW;// = "waitarrow";
	var DISABLED;// = "disabled";
	var DRAG;// = "drag";
	var DRAG_OPEN;// = "dragopen";

	@:to public function toOpenFL():MouseCursor {
		return @:privateAccess switch(cast this) {
			case ARROW: MouseCursor.ARROW;
			case CROSSHAIR: MouseCursor.__CROSSHAIR;
			case CLICK: MouseCursor.BUTTON;
			case IBEAM: MouseCursor.IBEAM;
			case MOVE: MouseCursor.__MOVE;
			case HAND: MouseCursor.HAND;
			case DRAG: MouseCursor.HAND;
			case DRAG_OPEN: MouseCursor.ARROW; // Could be HAND, but it might be better to use ARROW since on windows it would be weird to have the dragging cursor
			case WAIT: MouseCursor.__WAIT;
			case WAIT_ARROW: MouseCursor.__WAIT_ARROW;

			case DISABLED: MouseCursor.ARROW;

			case RESIZE_TR: MouseCursor.__RESIZE_NESW;
			case RESIZE_BL: MouseCursor.__RESIZE_NESW;
			case RESIZE_TL: MouseCursor.__RESIZE_NWSE;
			case RESIZE_BR: MouseCursor.__RESIZE_NWSE;
			case RESIZE_H: MouseCursor.__RESIZE_WE;
			case RESIZE_V: MouseCursor.__RESIZE_NS;

			case RESIZE_T: MouseCursor.__RESIZE_NS;
			case RESIZE_B: MouseCursor.__RESIZE_NS;

			case RESIZE_L: MouseCursor.__RESIZE_WE;
			case RESIZE_R: MouseCursor.__RESIZE_WE;
			case CUSTOM: MouseCursor.__CUSTOM;
			//default: ARROW;
		}
	}

	@:to public function toInt():Int {
		return switch(cast this) {
			case ARROW: 0;
			case CROSSHAIR: 1;
			case CLICK: 2;
			case IBEAM: 3;
			case MOVE: 4;
			case HAND: 5;
			case DRAG: 6;
			case DRAG_OPEN: 7;
			case WAIT: 8;
			case WAIT_ARROW: 9;

			case DISABLED: 10;

			case RESIZE_TR: 11;
			case RESIZE_BL: 12;
			case RESIZE_TL: 13;
			case RESIZE_BR: 14;
			case RESIZE_H: 15;
			case RESIZE_V: 16;

			case RESIZE_T: 17;
			case RESIZE_B: 18;

			case RESIZE_L: 19;
			case RESIZE_R: 20;

			case CUSTOM: -1;
		}
	}
}