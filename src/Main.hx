package ;
import haxe.Constraints.IMap;
import haxe.ds.Option;
import haxe.Json;
import mod.typedjson.IJsonSerializable;
import mod.typedjson.TypedJson;
import test.SomeClass;
import tjson.TJSON;

class Main
{

	public static function main() 
	{		
		//trace(Response.deserializeFromString(CompileTime.readFile("response.json")));
		
		var p = new TypedJsonParser(CompileTime.readFile("response.json"));
		var response = Response.deserialize(p);

		trace(Json.stringify(response, null, "   "));

		
		//TODO:implement
		//trace(Response.deserializeArrayFromString(CompileTime.readFile("array.json")));
	}
	
}


class Response 
{
	var int:Int;
	var bool:Bool;
	var intArray:Array<Int>;
	var floatArray:Array<Float>;
	var boolArray:Array<Bool>;
	var objectArray:Array<Item>;
	var float:Float;
	var string:String;
	var stringMap:IMap<String, Item>;
	var intMap:IMap<Int, Item>;	
	
	public function new() {}
	
	public static function deserialize(p:TypedJsonParser):Response
	{
		var o = new Response();
		
		p.object();
		var f:Null<String> = null;
		while ((f = p.field()) != null)
		{			
			switch (f)
			{
				case "int": o.int = p.int();
				case "bool": o.bool = p.bool();
				case "floatArray": o.floatArray = p.arrayOfFloat();
				case "boolArray": o.boolArray = p.arrayOfBool();
				case "intArray": o.intArray = p.arrayOfInt();
				case "objectArray": o.objectArray = p.arrayOf(Item.deserialize);
				case "float": o.float = p.float();
				case "string": o.string = p.string();
				//case "stringMap": o.stringMap = p.stringMapOf(Item.deserialize);
				//case "intMap": o.intMap = p.intMapOf(Item.deserialize); 
				case _: 
					p.skip();
					trace('Unknown property: $f');
			}
		}		
		
		return o;
	}
	
}

class Item implements IJsonSerializable
{
	var index:Int;
	var contents:String;
	
	public static function deserialize(p:TypedJsonParser):Item
	{
		var o = new Item();
		
		p.object();
		var f:Null<String> = null;
		while ((f = p.field()) != null)
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

/*
@:notNull
class Response implements IJsonSerializable
{	
	var int:Int;	
	var intArray:Array<Int>;
	var float:Float;
	var string:String;
	var stringMap:IMap<String, Item>;
	var intMap:IMap<Int, Item>;	
}

class Item implements IJsonSerializable
{
	var index:Int;
	var contents:String;
}
*/