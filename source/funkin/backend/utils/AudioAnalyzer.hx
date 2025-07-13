package funkin.backend.utils;

import flixel.sound.FlxSound;
import lime.media.AudioBuffer;
import lime.utils.ArrayBufferView;

#if lime_vorbis
import lime.media.vorbis.Vorbis;
import lime.media.vorbis.VorbisFile;
#end

// ORIGINAL CODES FROM YOSH & LUNAR https://github.com/CodenameCrew/YoshiCrafterEngine/blob/main/source/WaveformSprite.hx
// REWRITTEN BY RALTYRO
class AudioAnalyzer {
	public var buffer:AudioBuffer;
	var __toBits:Float;
	var __wordSize:Int;
	var __bitUnsignedSize:Int;
	var __bitSize:Int;

	#if lime_vorbis
	var __vorbis:VorbisFile;
	#end

	public function new(sound:FlxSound) {
		buffer = sound.buffer;

		__bitUnsignedSize = 1 << buffer.bitsPerSample;
		__bitSize = 1 << (buffer.bitsPerSample - 1);
		__toBits = buffer.sampleRate / 1000 * buffer.channels * (__wordSize = buffer.bitsPerSample >> 3);

		#if lime_vorbis
		__prepareVorbis();
		#end
	}

	public function analyze(startPos:Float, endPos:Float):Float {
		if (buffer.data != null) return __analyze(startPos, endPos);
		#if lime_vorbis
		else if (__prepareVorbis()) return __analyzeVorbis(startPos, endPos);
		#end
		return 0;
	}

	inline function __analyze(startPos:Float, endPos:Float):Float {
		var pos = Math.floor(startPos * __toBits), end = Math.floor(endPos * __toBits), buf = #if js buffer.data #else buffer.data.buffer #end;
		var max = 0, b = 0;
		if (__wordSize == 1) { // 8-bit audio data is unsigned (0 is 128, 128 is 256, -128 is 0)
			while (pos < end) {
				if (max < (b = #if js buf[pos] #else buf.get(pos) #end - __bitSize)) max = b;
				pos++;
			}
		}
		else {
			pos -= pos % __wordSize;
			end -= end % __wordSize;

			var w = 0;
			while (pos < end) {
				while (w < buffer.bitsPerSample) {
					b |= #if js buf[pos] #else buf.get(pos) #end << w;
					w += 8;
					pos++;
				}
				if (b > __bitSize) b -= __bitUnsignedSize;
				if (max < b) max = b;
				w = b = 0;
			}
		}

		return max / __bitSize;
	}

	#if lime_vorbis // As far i know, only native supports vorbis
	var __buffer:ArrayBufferView;
	function __prepareVorbis():Bool @:privateAccess {
		if (buffer.__srcVorbisFile == null) return __vorbis != null;
		if (__vorbis != null) return true;
		if ((__vorbis = buffer.__srcVorbisFile.clone()) != null) { // IM HOPING IT HAVE A GC CLOSURE.
			__buffer = new ArrayBufferView(0x1000, buffer.bitsPerSample == 32 ? Int32 : buffer.bitsPerSample == 16 ? Int16 : Int8);
			return true;
		}
		return false;
	}

	var prevPos:Int = 0;
	inline function __analyzeVorbis(startPos:Float, endPos:Float):Float {
		var n = Math.floor((endPos - startPos) * __toBits);
		if (n < __wordSize) return 0;

		n -= n % __wordSize;

		if (prevPos != Math.floor(startPos)) {
			__vorbis.timeSeek(startPos / 1000);
			prevPos = Math.floor(endPos);
		}

		var isBigEndian = lime.system.System.endianness == lime.system.Endian.BIG_ENDIAN, bufferSize = __buffer.length, buf = __buffer.buffer;
		var max = 0, b = 0, pos = 0, w = 0, result;
		while (n > 0) {
			n -= (result = __vorbis.read(buf, 0, n < bufferSize ? n : bufferSize, isBigEndian, __wordSize, true));

			if (result == Vorbis.HOLE) continue;
			else if (result <= 0) break;

			while (pos < result) {
				while (w < buffer.bitsPerSample) {
					b |= #if js buf[pos] #else buf.get(pos) #end << w;
					w += 8;
					pos++;
				}
				if (b > __bitSize) b -= __bitUnsignedSize;
				if (max < b) max = b;
				w = b = 0;
			}
			pos = 0;
		}

		return max / __bitSize;
	}
	#end
}