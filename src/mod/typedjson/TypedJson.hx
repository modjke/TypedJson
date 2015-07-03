package mod.typedjson;
import haxe.ds.IntMap;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.ExprOf;
import mod.typedjson.TypedJson.TypedJsonParser;

using haxe.macro.Tools;

class TypedJson
{
	public static var OBJECT_REFERENCE_PREFIX = "@~obRef#";
}

class TypedJsonParser
{
	var pos:Int;
	var json:String;
	var lastSymbolQuoted:Bool; //true if the last symbol was in quotes.
	var currentLine:Int;
	var cache:Array<Dynamic>;
	var floatRegex:EReg;
	var intRegex:EReg;
	
	public function new(vjson:String)
    {
		json = vjson;
		currentLine = 1;
        lastSymbolQuoted = false;
		pos = 0;
		floatRegex = ~/^-?[0-9]*\.[0-9]+$/;
		intRegex = ~/^-?[0-9]+$/;	
		cache = new Array();
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
		if (lastSymbolQuoted) throw "Quoted int";		
		return o;
	}
	
	public function float():Float
	{
		var f = floatOrThrow(getNextSymbol());
		if (lastSymbolQuoted) throw "Quoted float";
		return f;
	}	

	public function bool():Bool
	{
		var b = boolOrThrow(getNextSymbol());
		if (lastSymbolQuoted) throw "Quoted bool";
		return b;
	}
	
	public function string():String
	{
		var sym = getNextSymbol();
		if (!lastSymbolQuoted) throw "Not a string";
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
		do {
			var field = getNextSymbol();
			var comma = getNextSymbol();
			
		} while (getNextSymbol() != "}");
		
		return o;
	}
	
	public function skip()
	{
		getNextSymbol();
		if (!lastSymbolQuoted)
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
	
	/*
    function doParse():Dynamic{
    	try{
			//determine if objector array
			return switch (getNextSymbol()) {
				case '{': doObject();
				case '[': doArray();
				case s: convertSymbolToProperType(s);
			}
		}catch(e:String){
			throw "Exception parsing json on line " + currentLine + ": " + e;
		}
	}

	private function doObject():Dynamic{
		var o:Dynamic = { };
		var val:Dynamic ='';
		var key:String;
		var isClassOb:Bool = false;
		cache.push(o);
		while(pos < json.length){
			key=getNextSymbol();
			if(key == "," && !lastSymbolQuoted)continue;
			if(key == "}" && !lastSymbolQuoted){
				//end of the object. Run the TJ_unserialize function if there is one
				if( isClassOb && #if flash9 try o.TJ_unserialize != null catch( e : Dynamic ) false #elseif (cs || java) Reflect.hasField(o, "TJ_unserialize") #else o.TJ_unserialize != null #end  ) {
					o.TJ_unserialize();
				}
				return o;
			}

			var seperator = getNextSymbol();
			if(seperator != ":"){
				throw("Expected ':' but got '"+seperator+"' instead.");
			}

			var v = getNextSymbol();

			if(key == '_hxcls'){
				var cls =Type.resolveClass(v);
				if(cls==null) throw "Invalid class name - "+v;
				o = Type.createEmptyInstance(cls);
				cache.pop();
				cache.push(o);
				isClassOb = true;
				continue;
			}


			if(v == "{" && !lastSymbolQuoted){
				val = doObject();
			}else if(v == "[" && !lastSymbolQuoted){
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
			if(val == ',' && !lastSymbolQuoted){
				continue;
			}
			else if(val == ']' && !lastSymbolQuoted){
				return a;
			}
			else if(val == "{" && !lastSymbolQuoted){
				val = doObject();
			}else if(val == "[" && !lastSymbolQuoted){
				val = doArray();
			}else{
				val = convertSymbolToProperType(val);
			}
			a.push(val);
		}
		throw "Unexpected end of file. Expected ']'";
	}

	private function convertSymbolToProperType(symbol):Dynamic{
		if(lastSymbolQuoted) {
			//value was in quotes, so it's a string.
			//look for reference prefix, return cached reference if it is
			if(StringTools.startsWith(symbol,TypedJson.OBJECT_REFERENCE_PREFIX)){
				var idx:Int = Std.parseInt(symbol.substr(TypedJson.OBJECT_REFERENCE_PREFIX.length));
				return cache[idx];
			}
			return symbol; //just a normal string so return it
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


	private function looksLikeFloat(s:String):Bool{
		return floatRegex.match(s) || (
			intRegex.match(s) && {
				var intStr = intRegex.matched(0);
				if (intStr.charCodeAt(0) == "-".code)
					intStr > "-2147483648";
				else
					intStr > "2147483647";
			}
		);
	}

	private function looksLikeInt(s:String):Bool{
		return intRegex.match(s);
	}
	*/
	public function getNextSymbol(){
		lastSymbolQuoted=false;
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
					lastSymbolQuoted = true;
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