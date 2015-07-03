package mod.typedjson;
import haxe.EnumTools.EnumValueTools;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.Field;
import haxe.macro.Expr.FieldType;
import haxe.macro.Expr.Function;
import haxe.macro.Expr.Metadata;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.Type.MetaAccess;
import haxe.macro.TypedExprTools;
import haxe.macro.TypeTools;
import mod.typedjson.TypedJsonBuilder.TypedJsonMetaSettings;

using haxe.macro.Tools;
using Lambda;

//TODO: add type safety somethere
//TODO: add type validation somethere
class TypedJsonMetaSettings 
{
	public var notNull(default, null):Null<Bool> = null;
	public var rename(default, null):Null<String> = null;
	
	public function new(?meta:Metadata, ?initializeWith:TypedJsonMetaSettings)
	{
		if (initializeWith != null)
		{
			this.notNull = initializeWith.notNull;
			this.rename = initializeWith.rename;
		} else {
			//defaults
			notNull = false;
			rename = null;
		}
		
		//parse meta
		if (meta != null)
		{
			notNull = meta.exists(function (entry) return entry.name == ":notNull");
			var renameMeta = meta.find(function (entry) return entry.name == ":rename");
			if (renameMeta != null)
			{
				if (renameMeta.params.length != 1 || 
					!Std.is(renameMeta.params[0].getValue(), String)) 
					throw ":rename metadata accepts only one string parameter";
					
				rename = cast renameMeta.params[0];
			}
		}				
	}
}

class TypedJsonBuilder
{

	macro public static function buildJsonSerializable():Array<Field>
	{
		var localType = Context.getLocalType();
		var localCType = TypeTools.toComplexType(localType);		
		var typePath = switch (localCType)
		{
			case TPath(p): p;
			case _: null;
		}
		
		var buildFields = Context.getBuildFields();
		var classType = localType.getClass();
		
		var defaults = new TypedJsonMetaSettings(classType.meta.get());
		if (defaults.rename != null) throw ":rename metadata on class is ignored, since has no meaning";
		
		var fieldInitializers = new Array<Expr>();
		
		for (field in buildFields)
		{
			var fieldSettings = new TypedJsonMetaSettings(field.meta, defaults);
			switch (field.kind)
			{
				case FVar(t, e):					
					
					fieldInitializers.push(createFieldInitializer(field.name, t.toType(), fieldSettings));
				case FProp(get, set, t, e):
					fieldInitializers.push(createFieldInitializer(field.name, t.toType(), fieldSettings));
				case _: //
			}
		}
		
		var fun:Function = { 
			args: [ { name: "jsonString", type: macro : String } ],
			ret: localCType,
			expr: macro 
			{
				var out = new $typePath();								
				$b { fieldInitializers };
				return out;
			}
		};
		
		var deserializeFromString:Field = {
			name: "deserializeFromString",
			access: [APublic, AStatic],
			pos: Context.currentPos(),			
			kind: FieldType.FFun(fun)
		};		
		
		buildFields.push(deserializeFromString);
		
		
		// add an empty constructor if necessary
		var hasConstructor = Lambda.exists(buildFields, function (f) return f.name == "new");
		if (!hasConstructor) 
			buildFields.push(createEmptyContstructor());
		
		return buildFields;
	}	
	
	static function createFieldInitializer(name:String, type:Type, settings:TypedJsonMetaSettings):Expr
	{		
		
		var jsonField = macro $v { settings.rename != null ? settings.rename : name };
		return switch (type)
		{
			/**
				Represents a monomorph.

				@see http://haxe.org/manual/types-monomorph.html
			**/
			//TMono( t : Ref<Null<Type>> );
			case TMono (t): macro null;

			/**
				Represents an enum instance.

				@see http://haxe.org/manual/types-enum-instance.html
			**/
			//TEnum( t : Ref<EnumType>, params : Array<Type> );
			case TEnum (t, params): macro null;

			/**
				Represents a class instance.

				@see http://haxe.org/manual/types-class-instance.html
			**/
			//TInst( t : Ref<ClassType>, params : Array<Type> );
			case TInst (t, params): macro null;

			/**
				Represents a typedef.

				@see http://haxe.org/manual/type-system-typedef.html
			**/
			//TType( t : Ref<DefType>, params : Array<Type> );
			case TType (t, params): macro null;

			/**
				Represents a function type.

				@see http://haxe.org/manual/types-function.html
			**/
			//TFun( args : Array<{ name : String, opt : Bool, t : Type }>, ret : Type );
			case TFun(args, ret): macro null;

			/**
				Represents an anonymous structure type.

				@see http://haxe.org/manual/types-anonymous-structure.html
			**/
			//TAnonymous( a : Ref<AnonType> );
			case TAnonymous (a): macro null;

			/**
				Represents Dynamic.

				@see http://haxe.org/manual/types-dynamic.html
			**/
			//TDynamic( t : Null<Type> );
			case TDynamic (t): macro null;

			/**
				Used internally by the compiler to delay some typing.
			**/
			//TLazy( f : Void -> Type );
			case TLazy (f):  macro null;

			/**
				Represents an abstract type.

				@see http://haxe.org/manual/types-abstract.html
			**/
			//TAbstract( t : Ref<AbstractType>, params : Array<Type> );
			case TAbstract(_.get() => type, params): 
				macro null;
		}		
	}
	
	static function createEmptyContstructor():Field
	{
		var fun:Function = {
			args: [],
			expr: macro { },
			ret: null
		}
			
		var field:Field = { 
			access: [APublic],
			kind: FFun(fun),
			name: "new",
			pos: Context.currentPos()
		}
		return field;
	}
	
}