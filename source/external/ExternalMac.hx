package external;

#if mac
@:build(external.LinkerMacro.xml('external_code.xml'))
@:native("ExternalMac")
@:include('Mac.h')
extern class ExternalMac {
	@:native("ExternalMac::setCursorIcon")
	public static function setCursorIcon(icon:Int):Bool;
}
#end