package funkin.backend.utils;

import haxe.macro.Expr;

class MathUtil {
	public static function maxInt(...args:Int):Int {
		var max = args[0];
		for(i in 1...args.length) {
			var arg = args[i];
			if(arg > max)
				max = arg;
		}
		return max;
	}

	public static function minInt(...args:Int):Int {
		var min = args[0];
		for(i in 1...args.length) {
			var arg = args[i];
			if(arg < min)
				min = arg;
		}
		return min;
	}

	public static function maxFloat(...args:Float):Float {
		var max = args[0];
		for(i in 1...args.length) {
			var arg = args[i];
			if(arg > max)
				max = arg;
		}
		return max;
	}

	public static function minFloat(...args:Float):Float {
		var min = args[0];
		for(i in 1...args.length) {
			var arg = args[i];
			if(arg < min)
				min = arg;
		}
		return min;
	}

	/**
	 * Shortcut to `Math.max` but with infinite amount of arguments
	 * Uses `CoolUtil.maxInt` if theres only int arguments
	 *
	 * Might not preserve the order of arguments, please test this.
	 *
	 * Dont use this in hscript, it doesnt work, it only works on compile time
	**/
	@:dox(hide) public static macro function maxSmart(..._args:Expr):Expr {
		return genericMinMaxSmart(_args.toArray(), true);
	}

	/**
	 * Shortcut to `Math.min` but with infinite amount of arguments
	 * Uses `CoolUtil.minInt` if theres only int arguments
	 *
	 * Might not preserve the order of arguments, please test this.
	 *
	 * Dont use this in hscript, it doesnt work, it only works on compile time
	**/
	@:dox(hide) public static macro function minSmart(..._args:Expr):Expr {
		return genericMinMaxSmart(_args.toArray(), false);
	}

	#if macro
	@:dox(hide) private static function genericMinMaxSmart(_args:Array<Expr>, isMax:Bool):Expr {
		var args = _args.copy();
		if (args.length == 0) return macro 0;

		var isFloat = true;
		var isInt = true;

		for(arg in args) {
			if(isInt)
				isInt = arg.expr.match(EConst(CInt(_)));
			if(isFloat)
				isFloat = arg.expr.match(EConst(CFloat(_)));
		}

		var funcPath = isInt ? "funkin.backend.utils.CoolUtil.maxInt" : "Math.max";
		if (!isMax) funcPath = isInt ? "funkin.backend.utils.CoolUtil.minInt" : "Math.min";

		var func = funcPath.split(".");

		function nested(lst:Array<Expr>):Expr {
			if (lst.length == 1) {
				return macro ${lst[0]};
			} else if (lst.length == 2) {
				return macro $p{func}(${lst[0]}, ${lst[1]});
			} else {
				var mid = Std.int(lst.length / 2);
				return macro $p{func}(${nested(lst.slice(0, mid))}, ${nested(lst.slice(mid, lst.length))});
			}
		}

		var expr = nested(args);

		//var printer = new haxe.macro.Printer();
		//trace(printer.printExpr(expr));

		return macro $expr;
	}
	#end
}