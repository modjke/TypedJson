/*
 * TypedJson
 * 
 * Typed json parser and encoder for haxe
 * 
 * Copyright (c) 2015, Ignatiev Mikhail All rights reserved
 * 
 * Original json parsing code from TJSON https://github.com/martamius/TJSON
 * Thanks for "tolerant" part of the parsing logic goes to Jordan CM Wambaugh
 * https://github.com/martamius
 * jordan@wambaugh.org
 * http://jordan.wambaugh.org
 * 
 * Copyright (c) 2012, Jordan CM Wambaugh All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without modification, 
 * 
 * are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, 
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright notice, 
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND 
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
package mod.typedjson;
import haxe.ds.IntMap;
import haxe.ds.StringMap;
import mod.log.MLog.mlog;

class TypedJsonParser
{
	var pos:Int;	
	var currentLine:Int;
	var quoted:Bool; //true if the last symbol was in quotes.
	
	var json:String;	
	
	var _lastQuoted:Bool;	//used to undo
	var _lastPoistion:Int;	//used to undo
	var _lastLine:Int;		//used to undo
	

	public function new(jsonString:String)
    {
		json = jsonString;
		currentLine = 1;
		pos = 0;		
		
		_lastLine = currentLine;
        quoted = false;
		_lastPoistion = pos;		
    }
	
	public function nextObject():Void
	{
		if (getNextSymbol() != "{") throw "Not an object";
	}
	
	public function nextProperty():String
	{
		var field = getNextSymbol();
		if (field == ",") field = getNextSymbol();
		if (field == "}") return null;
		
		var next = getNextSymbol();
		if (next != ":") throw "Not a field, stopped on symbol: " + next + ", trying to read field: " + field;
		
		return field;
	}
	
	public function int():Null<Int>
	{		
		var next = getNextSymbol();
		if (!quoted && next == "null") return null;
		
		var o = intOrThrow(next);
		if (quoted) throw "Quoted int";		
		return o;
	}
	
	public function float():Null<Float>
	{
		var next = getNextSymbol();
		if (!quoted && next == "null") return null;		
		var f = floatOrThrow(next);
		if (quoted) throw "Quoted float";
		return f;
	}	

	public function bool():Null<Bool>
	{
		var next = getNextSymbol();
		if (!quoted && next == "null") return null;
		var b = boolOrThrow(next);
		if (quoted) throw "Quoted bool";
		return b;
	}
	
	public function string():String
	{
		var sym = getNextSymbol();
		if (!quoted) throw "Not a string";
		return sym;
	}
	
	public function any():Dynamic
	{
		try{
			//determine if objector array
			return switch (getNextSymbol()) {
				case '{': doObject();
				case '[': doArray();
				case s: convertSymbolToProperType(s);
			}
		}catch(e:String){
			throw "Exception on line " + currentLine + ": " + e;
		}
	}
	
	private function doObject():Dynamic{
		var o:Dynamic = { };
		var val:Dynamic ='';
		var key:String;
		var isClassOb:Bool = false;
		while(pos < json.length){
			key=getNextSymbol();
			if(key == "," && !quoted)continue;
			if(key == "}" && !quoted){
				return o;
			}

			var seperator = getNextSymbol();
			if(seperator != ":"){
				throw("Expected ':' but got '"+seperator+"' instead.");
			}

			var v = getNextSymbol();
			if(v == "{" && !quoted){
				val = doObject();
			}else if(v == "[" && !quoted){
				val = doArray();
			}else{
				val = convertSymbolToProperType(v);
			}
			Reflect.setField(o,key,val);
		}
		throw "Unexpected end of file. Expected '}'";
		
	}
	
	private function doArray():Dynamic{
		var a:Array<Dynamic> = new Array<Dynamic>();
		var val:Dynamic;
		while(pos < json.length){
			val=getNextSymbol();
			if(val == ',' && !quoted){
				continue;
			}
			else if(val == ']' && !quoted){
				return a;
			}
			else if(val == "{" && !quoted){
				val = doObject();
			}else if(val == "[" && !quoted){
				val = doArray();
			}else{
				val = convertSymbolToProperType(val);
			}
			a.push(val);
		}
		throw "Unexpected end of file. Expected ']'";
	}
	
	private function convertSymbolToProperType(symbol):Dynamic{
		if(quoted) {
			return symbol; 
		}
		if(looksLikeFloat(symbol)){
			return Std.parseFloat(symbol);
		}
		if(looksLikeInt(symbol)){
			return Std.parseInt(symbol);
		}
		if(symbol.toLowerCase() == "true"){
			return true;
		}
		if(symbol.toLowerCase() == "false"){
			return false;
		}
		if(symbol.toLowerCase() == "null"){
			return null;
		}
		
		return symbol;
	}
	
	var floatRegex = ~/^-?[0-9]*\.[0-9]+$/;
	var intRegex = ~/^-?[0-9]+$/;	
	
	private function looksLikeFloat(s:String):Bool{
		if(floatRegex.match(s)) return true;

		if(intRegex.match(s)){
			if({
				var intStr = intRegex.matched(0);
				if (intStr.charCodeAt(0) == "-".code)
					intStr > "-2147483648";
				else
					intStr > "2147483647";
			} ) return true;

			var f:Float = Std.parseFloat(s);
			if(f>2147483647.0) return true;
			else if (f<-2147483648) return true;
			
		} 
		return false;	
	}

	private function looksLikeInt(s:String):Bool{
		return intRegex.match(s);
	}


	public function typed<T>(parse:TypedJsonParser->T):T
	{
		return parse(this);
	}

	public function arrayOf<T>(deserialize:TypedJsonParser->T):Array<T>
	{
		if (getNextSymbol() != "[") throw "Not an array";
		
		var o = new Array<T>();
		var s:String = getNextSymbol();
		while (s != "]")
		{
			undoNextSymbol();
			
			o.push(deserialize(this));
			
			s = getNextSymbol();
			if (s == ",") s = getNextSymbol();
		}
		return o;
	}
	
	
	
	public function intMapOf<T>(deserialize:TypedJsonParser->T):IntMap<T>
	{
		if (getNextSymbol() != "{") throw "Not a map";
		
		var o = new IntMap<T>();	
		var s = getNextSymbol();
		while (s != "}")
		{
			if (getNextSymbol() != ":") throw "Expected a comma";
			var k = intOrThrow(s);
			if (o.exists(k)) throw "Key duplicate: " + k;
			o.set(k, deserialize(this));
			
			s = getNextSymbol();
			if (s == ",") s = getNextSymbol();
		}
		
		return o;
	}
	
	public function stringMapOf<T>(deserialize:TypedJsonParser->T):StringMap<T>
	{
		if (getNextSymbol() != "{") throw "Not a map";
		
		var o = new StringMap<T>();	
		var s = getNextSymbol();
		while (s != "}")
		{
			if (!quoted) throw "Expected string as a key";
			
			if (getNextSymbol() != ":") throw "Expected a comma";
			if (o.exists(s)) throw "Key duplicate: " + s;
			o.set(s, deserialize(this));
			
			s = getNextSymbol();
			if (s == ",") s = getNextSymbol();
		}
		
		return o;
	}
	
	public function skip():Dynamic
	{				
		var c = 0;
		do {
			switch (getNextSymbol())
			{
				case "{" | "[": c++;
				case "}" | "]": c--;
			}
		} while (c != 0);
		
		return null;
	}

	inline function boolOrThrow(s:String):Bool
	{
		return switch (s.toLowerCase())
		{
			case "true": true;
			case "false": false;
			case _: throw "Not a bool";
		}
	}
	
	inline function intOrThrow(s:String):Int
	{
		var i = Std.parseInt(s);
		if (i == null) throw "Not an int";
		return i;
	}
	
	inline function floatOrThrow(s:String):Float
	{
		var f = Std.parseFloat(s);
		if (Math.isNaN(f)) throw "Not a float";
		return f;
	}
	
	static function _parseString(parser:TypedJsonParser):String 	return parser.string();
	static function _parseAny(parser:TypedJsonParser):Dynamic 		return parser.any();
	static function _parseBool(parser:TypedJsonParser):Null<Bool> 	return parser.bool();
	static function _parseFloat(parser:TypedJsonParser):Null<Float>	return parser.float();		
	static function _parseInt(parser:TypedJsonParser):Null<Int> 	return parser.int();
	
	public function arrayOfInt():Array<Null<Int>>			return arrayOf(_parseInt);
	public function arrayOfFloat():Array<Null<Float>>		return arrayOf(_parseFloat);	
	public function arrayOfBool():Array<Null<Bool>> 		return arrayOf(_parseBool);	
	public function arrayOfString():Array<String> 			return arrayOf(_parseString);	
	public function arrayOfAny():Array<Dynamic>				return arrayOf(_parseAny);
	
	public function intMapOfInt():IntMap<Null<Int>>				return intMapOf(_parseInt);
	public function intMapOfFloat():IntMap<Null<Float>>			return intMapOf(_parseFloat);	
	public function intMapOfBool():IntMap<Null<Bool>> 			return intMapOf(_parseBool);	
	public function intMapOfString():IntMap<String> 			return intMapOf(_parseString);	
	public function intMapOfAny():IntMap<Dynamic>				return intMapOf(_parseAny);
	
	public function stringMapOfInt():StringMap<Null<Int>>			return stringMapOf(_parseInt);
	public function stringMapOfFloat():StringMap<Null<Float>>		return stringMapOf(_parseFloat);	
	public function stringMapOfBool():StringMap<Null<Bool>> 		return stringMapOf(_parseBool);	
	public function stringMapOfString():StringMap<String> 			return stringMapOf(_parseString);	
	public function stringMapOfAny():StringMap<Dynamic>				return stringMapOf(_parseAny);

	function undoNextSymbol()
	{
		if (_lastLine == currentLine && _lastPoistion == pos)
			throw "Can't undo more than once";
			
		pos = _lastPoistion;
		quoted = _lastQuoted;
		currentLine = _lastLine;
		
	}
	
	function getNextSymbol() 
	{
	
		_lastQuoted = quoted;
		_lastLine = currentLine;
		_lastPoistion = pos;
		
		quoted=false;
		var c:String = '';
		var inQuote:Bool = false;
		var quoteType:String="";
		var symbol:String = '';
		var inEscape:Bool = false;
		var inSymbol:Bool = false;
		var inLineComment = false;
		var inBlockComment = false;

		while (pos < json.length)
		{
			c = json.charAt(pos++);
			if(c == "\n" && !inSymbol)
				currentLine++;
			if(inLineComment){
				if(c == "\n" || c == "\r"){
					inLineComment = false;
					pos++;
				}
				continue;
			}

			if(inBlockComment){
				if(c=="*" && json.charAt(pos) == "/"){
					inBlockComment = false;
					pos++;
				}
				continue;
			}

			if(inQuote){
				if(inEscape){
					inEscape = false;
					if(c=="'" || c=='"'){
						symbol += c;
						continue;
					}
					if(c=="t"){
						symbol += "\t";
						continue;
					}
					if(c=="n"){
						symbol += "\n";
						continue;
					}
					if(c=="\\"){
						symbol += "\\";
						continue;
					}
					if(c=="r"){
						symbol += "\r";
						continue;
					}
					if(c=="/"){
						symbol += "/";
						continue;
					}

					if (c == "u") {
						var uc = Std.parseInt("0x" + json.substr(pos, 4));
						pos += 4;
						var utf = new haxe.Utf8();
						
						#if (neko || php || cpp)
						if( uc <= 0x7F )
							utf.addChar(uc);
						else if( uc <= 0x7FF ) {
							utf.addChar(0xC0 | (uc >> 6));
							utf.addChar(0x80 | (uc & 63));
						} else if( uc <= 0xFFFF ) {
							utf.addChar(0xE0 | (uc >> 12));
							utf.addChar(0x80 | ((uc >> 6) & 63));
							utf.addChar(0x80 | (uc & 63));
						} else {
							utf.addChar(0xF0 | (uc >> 18));
							utf.addChar(0x80 | ((uc >> 12) & 63));
							utf.addChar(0x80 | ((uc >> 6) & 63));
							utf.addChar(0x80 | (uc & 63));
						}
						#else
						utf.addChar(uc);
						#end	
						
						symbol += utf.toString();
                        
						continue;
					}


					throw "Invalid escape sequence '\\"+c+"'";
				}else{
					if(c == "\\"){
						inEscape = true;
						continue;
					}
					if (c == quoteType) {
						////trace("getNextSymbol: " + symbol);
						return symbol;
					}
					symbol+=c;
					continue;
				}
			}
			

			//handle comments
			else if(c == "/"){
				var c2 = json.charAt(pos);
				//handle single line comments.
				//These can even interrupt a symbol.
				if(c2 == "/"){
					inLineComment=true;
					pos++;
					continue;
				}
				//handle block comments.
				//These can even interrupt a symbol.
				else if(c2 == "*"){
					inBlockComment=true;
					pos++;
					continue;
				}
			}

			

			if (inSymbol){
				if(c==' ' || c=="\n" || c=="\r" || c=="\t" || c==',' || c==":" || c=="}" || c=="]"){ //end of symbol, return it
					pos--;
					////trace("getNextSymbol: " + symbol);
					return symbol;
				}else{
					symbol+=c;
					continue;
				}
				
			}
			else {
				if(c==' ' || c=="\t" || c=="\n" || c=="\r"){
					continue;
				}

				if (c == "{" || c == "}" || c == "[" || c == "]" || c == "," || c == ":") {
					////trace("getNextSymbol: " + c);
					return c;
				}



				if(c=="'" || c=='"'){
					inQuote = true;
					quoteType = c;
					quoted = true;
					continue;
				}else{
					inSymbol=true;
					symbol = c;
					continue;
				}


			}
		} // end of while. We have reached EOF if we are here.
		
		if(inQuote){
			throw "Unexpected end of data. Expected ( "+quoteType+" )";
		}
		
		return symbol;
	}

}