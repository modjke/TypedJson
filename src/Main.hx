package ;
import haxe.Constraints.IMap;
import haxe.ds.Option;
import haxe.Json;
import mod.typedjson.IJsonSerializable;
import mod.typedjson.TypedJsonParser;
import tjson.TJSON;

class Main
{

	public static function main() 
	{		
		//trace(Response.deserializeFromString(CompileTime.readFile("response.json")));
		
		var p = new TypedJsonParser(CompileTime.readFile("all.json"));
		var response = All.deserialize(p);

		trace(Json.stringify(response, null, "   "));

		
		//TODO:implement
		//trace(Response.deserializeArrayFromString(CompileTime.readFile("array.json")));
	}
	
}


class All 
{
	//single items
	var bool:	Bool;		
	var int:	Int;
	var float:	Float;
	var string:	String;		
	var any:	Dynamic;	
	var typed:	TypedItem;
	
	//arrays
	var boolArray:	Array<Bool>;
	var intArray:	Array<Int>;
	var floatArray:	Array<Float>;
	var stringArray:Array<String>;
	var anyArray:	Array<Dynamic>;
	var typedArray:	Array<TypedItem>;
	
	//string maps
	var stringMapOfBool:	IMap<String, Bool>;
	var stringMapOfInt:		IMap<String, Int>;
	var stringMapOfFloat:	IMap<String, Float>;
	var stringMapOfString:	IMap<String, String>;
	var stringMapOfAny:		IMap<String, Dynamic>;	
	var stringMapOfTyped:	IMap<String, TypedItem>;
	
	//int maps
	var intMapOfBool:		IMap<Int, Bool>;
	var intMapOfInt:		IMap<Int, Int>;
	var intMapOfFloat:		IMap<Int, Float>;
	var intMapOfString:		IMap<Int, String>;
	var intMapOfAny:		IMap<Int, Dynamic>;	
	var intMapOfTyped:		IMap<Int, TypedItem>;
	
	public function new() {}
	
	public static function deserialize(p:TypedJsonParser):All
	{
		var o = new All();
		
		p.nextObject();
		var f:Null<String> = null;
		while ((f = p.nextProperty()) != null)
		{			
			switch (f)
			{
				//single items				
				case "bool": 	o.bool = p.bool();				
				case "int": 	o.int = p.int();
				case "float":	o.float = p.float();
				case "string": 	o.string = p.string();				
				case "any": 	o.any = p.any();
				case "typed": 	o.typed = p.typed(TypedItem.deserialize);
				
				case "boolArray": 	o.boolArray = p.arrayOfBool();
				case "intArray": 	o.intArray = p.arrayOfInt();
				case "floatArray": 	o.floatArray = p.arrayOfFloat();
				case "stringArray": o.stringArray = p.arrayOfString();
				case "anyArray":	o.anyArray = p.arrayOfAny();
				case "typedArray": 	o.typedArray = p.arrayOf(TypedItem.deserialize);
				
				case "stringMapOfBool":		o.stringMapOfBool 	= p.stringMapOfBool();
				case "stringMapOfInt":		o.stringMapOfInt 	= p.stringMapOfInt();
				case "stringMapOfFloat":	o.stringMapOfFloat 	= p.stringMapOfFloat();
				case "stringMapOfString":	o.stringMapOfString = p.stringMapOfString();
				case "stringMapOfAny":		o.stringMapOfAny	= p.stringMapOfAny();
				case "stringMapOfTyped":	o.stringMapOfTyped	= p.stringMapOf(TypedItem.deserialize);
				
				case "intMapOfBool":	o.intMapOfBool 		= p.intMapOfBool();
				case "intMapOfInt":		o.intMapOfInt 		= p.intMapOfInt();
				case "intMapOfFloat":	o.intMapOfFloat 	= p.intMapOfFloat();
				case "intMapOfString":	o.intMapOfString 	= p.intMapOfString();
				case "intMapOfAny":		o.intMapOfAny		= p.intMapOfAny();
				case "intMapOfTyped":	o.intMapOfTyped		= p.intMapOf(TypedItem.deserialize);
				
				case _: 
				    p.skip();
					throw "Unknown propery: " + f;
			}
		}		
		
		return o;
	}
	
}

class TypedItem implements IJsonSerializable
{
	var index:Int;
	var contents:String;
	
	public static function deserialize(p:TypedJsonParser):TypedItem
	{
		var o = new TypedItem();
		
		p.nextObject();
		var f:Null<String> = null;
		while ((f = p.nextProperty()) != null)
		{			
			switch (f)
			{
				case "index": o.index = p.int();
				case "content": o.contents = p.string();
				case _: 
					p.skip();
					trace('Unknown property: $f');
			}
		}
		
		return o;
	}
}
