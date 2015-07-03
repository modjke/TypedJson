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
import mod.typedjson.TypedJson.TypedJsonParser;

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
	
	public function object():Void
	{
		if (getNextSymbol() != "{") throw "Not an object";
	}
	
	public function field():Null<String>
	{
		var field = getNextSymbol();
		if (field == ",") field = getNextSymbol();
		if (field == "}") return null;
		
		if (getNextSymbol() != ":") throw "Not a field";
		
		return field;
	}
	
	public function int():Int
	{		
		var o = intOrThrow(getNextSymbol());
		if (quoted) throw "Quoted int";		
		return o;
	}
	
	public function float():Float
	{
		var f = floatOrThrow(getNextSymbol());
		if (quoted) throw "Quoted float";
		return f;
	}	

	public function bool():Bool
	{
		var b = boolOrThrow(getNextSymbol());
		if (quoted) throw "Quoted bool";
		return b;
	}
	
	public function string():String
	{
		var sym = getNextSymbol();
		if (!quoted) throw "Not a string";
		return sym;
	}
	
	public function arrayOfInt():Array<Int>
	{
		if (getNextSymbol() != "[") throw "Not an array";
		
		var o = new Array<Int>();		
		var s:String = getNextSymbol();
		while (s != "]")
		{
			o.push(intOrThrow(s));
			
			s = getNextSymbol();
			if (s == ",") s = getNextSymbol();
		}
		
		return o;
	}
	
	public function arrayOfFloat():Array<Float>
	{
		if (getNextSymbol() != "[") throw "Not an array";
		
		var o = new Array<Float>();		
		var s:String = getNextSymbol();
		while (s != "]")
		{
			o.push(floatOrThrow(s));
			
			s = getNextSymbol();
			if (s == ",") s = getNextSymbol();
		}
		
		return o;
	}
	
	public function arrayOfBool():Array<Bool>
	{
		if (getNextSymbol() != "[") throw "Not an array";
		
		var o = new Array<Bool>();		
		var s:String = getNextSymbol();
		while (s != "]")
		{
			o.push(boolOrThrow(s));
			
			s = getNextSymbol();
			if (s == ",") s = getNextSymbol();
		}
		
		return o;
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
			o.set(intOrThrow(s), deserialize(this));
			
			s = getNextSymbol();
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
			o.set(s, deserialize(this));
			
			s = getNextSymbol();
		}
		
		return o;
	}
	
	public function skip()
	{
		getNextSymbol();
		if (!quoted)
		{
			var c = 1;
			while (c > 0)
				switch (getNextSymbol())
				{
					case "{" | "[": c++;
					case "}" | "]": c--;
				}
		}
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

	function undoNextSymbol()
	{
		if (_lastLine == currentLine && _lastPoistion == pos)
			throw "Can't undo more than once";
			
		pos = _lastPoistion;
		quoted = _lastQuoted;
		currentLine = _lastLine;
		
	}
	
	public function getNextSymbol() {
	
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

					if(c=="u"){
                        var hexValue = 0;

                        for (i in 0...4){
                            if (pos >= json.length)
                              throw "Unfinished UTF8 character";
			                var nc = json.charCodeAt(pos++);
                            hexValue = hexValue << 4;
                            if (nc >= 48 && nc <= 57) // 0..9
                              hexValue += nc - 48;
                            else if (nc >= 65 && nc <= 70) // A..F
                              hexValue += 10 + nc - 65;
                            else if (nc >= 97 && nc <= 102) // a..f
                              hexValue += 10 + nc - 95;
                            else throw "Not a hex digit";
                        }
                        
						var utf = new haxe.Utf8();
						utf.addChar(hexValue);
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
						trace("getNextSymbol: " + symbol);
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
					trace("getNextSymbol: " + symbol);
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
					trace("getNextSymbol: " + c);
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
		
		trace("getNextSymbol: " + symbol);
		return symbol;
	}

}