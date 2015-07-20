package ;
import flash.Lib;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import haxe.Constraints.IMap;
import haxe.Json;
import haxe.Timer;
import mod.typedjson.IParsable;
import mod.typedjson.TypedJsonParser;
import tjson.TJSON;

class Main
{

	public static function main() 
	{		
		//trace(Response.deserializeFromString(CompileTime.readFile("response.json")));		
		//TODO:implement
		//trace(Response.deserializeArrayFromString(CompileTime.readFile("array.json")));
		
		runBenchmark();
		
		//var input = CompileTime.readFile("all.json");
		//All.parseUsing(new TypedJsonParser(input));
	}
	
	static function runBenchmark()
	{
		var input = CompileTime.readFile("all-no-comments.json");
		
		var tf = new TextField();	
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.multiline = true;
		Lib.current.addChild(tf);
		
		tf.appendText("Testing...\n");
		
		function bench(name:String, count:Int, callback:Void->Void)
		{
			tf.appendText(name + ": ");
			var start = Timer.stamp();		
			for (i in 0...count) callback();
			var elapsed = Timer.stamp() - start;
			tf.appendText('$elapsed ms\n');
		}
		Timer.delay(function () 
		{
			bench("Typed json", 2000, function () All.parseUsing(new TypedJsonParser(input)));
			bench("Haxe json", 2000, function () Json.parse(input));
			bench("TJSON", 2000, function () TJSON.parse(input));
		}, 1000);
		
	}
	
	
}

class All implements IParsable
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
	
	/*
	public static function parseUsing(p:TypedJsonParser):All
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
				case "typed": 	o.typed = p.typed(TypedItem.parseUsing);
				
				case "boolArray": 	o.boolArray = p.arrayOfBool();
				case "intArray": 	o.intArray = p.arrayOfInt();
				case "floatArray": 	o.floatArray = p.arrayOfFloat();
				case "stringArray": o.stringArray = p.arrayOfString();
				case "anyArray":	o.anyArray = p.arrayOfAny();
				case "typedArray": 	o.typedArray = p.arrayOf(TypedItem.parseUsing);
				
				case "stringMapOfBool":		o.stringMapOfBool 	= p.stringMapOfBool();
				case "stringMapOfInt":		o.stringMapOfInt 	= p.stringMapOfInt();
				case "stringMapOfFloat":	o.stringMapOfFloat 	= p.stringMapOfFloat();
				case "stringMapOfString":	o.stringMapOfString = p.stringMapOfString();
				case "stringMapOfAny":		o.stringMapOfAny	= p.stringMapOfAny();
				case "stringMapOfTyped":	o.stringMapOfTyped	= p.stringMapOf(TypedItem.parseUsing);
				
				case "intMapOfBool":	o.intMapOfBool 		= p.intMapOfBool();
				case "intMapOfInt":		o.intMapOfInt 		= p.intMapOfInt();
				case "intMapOfFloat":	o.intMapOfFloat 	= p.intMapOfFloat();
				case "intMapOfString":	o.intMapOfString 	= p.intMapOfString();
				case "intMapOfAny":		o.intMapOfAny		= p.intMapOfAny();
				case "intMapOfTyped":	o.intMapOfTyped		= p.intMapOf(TypedItem.parseUsing);
				
				case _: 
				    p.skip();
					throw "Unknown propery: " + f;
			}
		}		
		
		return o;
	}
	*/
}

class TypedItem implements IParsable
{
	var index:Int;
	var content:String;
	
	/*
	public static function parseUsing(p:TypedJsonParser):TypedItem
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
	*/
}
