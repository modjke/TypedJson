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

using haxe.macro.Tools;
using Lambda;

enum EasyType
{
	INT; 
	FLOAT; 
	BOOL;
	STRING;	
	DYNAMIC;
	PARSABLE(classType:ClassType);
	
	STRINGMAP(valType:EasyType);
	INTMAP(valType:EasyType);
	
	ARRAY(easyType:EasyType);
	OTHER;
}

//TODO: add type safety somethere
//TODO: add type validation somethere
class ParsableBuilder
{
	inline static var parseUsingName = "parseUsing";
	
	macro public static function build():Array<Field>
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
		
		var fieldCases = new Array<Case>();
		
		for (field in buildFields)
		{
			switch (field.kind)
			{
				case FVar(t, e):										
					fieldCases.push(createFieldCase(field.name, t));
				case FProp(get, set, t, e):
					fieldCases.push(createFieldCase(field.name, t));
				case _: //
			}
		}
		
		var switchExpr:Expr = {
			pos: Context.currentPos(),
			//expr: ESwitch(macro f, fieldCases, macro throw "Unknown field " + f)
			expr: ESwitch(macro f, fieldCases, macro { p.skip(); trace("Skipped field: " + f); } )
		}
		
		var fun:Function = { 
			args: [ { name: "p", type: macro : mod.typedjson.TypedJsonParser } ],
			ret: localCType,
			expr: macro 
			{				
				p.nextObject();
				
				var out = new $typePath();								
				var f:Null<String> = null;
				while ((f = p.nextProperty()) != null) 
				{
					$switchExpr;
				}
				
				return out;
			}
		};

		var parseUsing:Field = {
			name: parseUsingName,
			access: [APublic, AStatic],
			pos: Context.currentPos(),			
			kind: FieldType.FFun(fun)
		};		
		
		buildFields.push(parseUsing);
		
		
		// add an empty constructor if necessary
		var hasConstructor = Lambda.exists(buildFields, function (f) return f.name == "new");
		if (!hasConstructor) 
			buildFields.push(createEmptyContstructor());
		
		return buildFields;
	}	
	
	static function extractEasyType(type:Type):EasyType
	{
		type = type.follow();
		return switch (type)
		{
			case TAbstract(_.get() => { pack: [], name: name }, []):
				switch (name)
				{
					case "Int": return INT;
					case "Float": return FLOAT;
					case "Bool": return BOOL;					
					case _: OTHER;
				}
			case TInst(_.get() => classType, types):
				if (parsable(classType))
					PARSABLE(classType) 
				else 
					switch [classType, types]
					{
						case [_ => { pack: [], name: "String" }, []]: STRING;
						case [_ => { pack: [], name: "Array" }, _ => [arrayType]]: ARRAY(extractEasyType(arrayType));
						case [_ => { pack: ["haxe"], name: "IMap" }, _ => [keyType, valType]]:
							switch (extractEasyType(keyType))
							{
								case INT: INTMAP(extractEasyType(valType));
								case STRING: STRINGMAP(extractEasyType(valType));
								case _: OTHER;
							}
						case _: OTHER;
					}
				
			case TDynamic(_): DYNAMIC;
			case _: OTHER;				
		}
	}
	
	static function createFieldCase(name:String, cType:ComplexType):Case
	{						
		var jsonField = name;

		var valueExpr = switch (extractEasyType(cType.toType()))
		{
			case INT: macro p.int();
			case FLOAT:	macro p.float();
			case BOOL: macro p.bool();
			case DYNAMIC: macro p.any();
			case STRING: macro p.string();
			
			case PARSABLE(classType):
				var name = classType.module + "." + classType.name + "." + parseUsingName + "(p)";
				var expr = Context.parse(name, Context.currentPos());			
				macro $expr;
				
			case INTMAP(valType):
				switch (valType)
				{
					case DYNAMIC: macro p.intMapOfAny();
					case INT: macro p.intMapOfInt();
					case FLOAT: macro p.intMapOfFloat();
					case BOOL: macro p.intMapOfBool();
					case STRING: macro p.intMapOfString();
					case PARSABLE(classType):
						var name = classType.module + "." + classType.name + "." + parseUsingName;
						var expr = Context.parse(name, Context.currentPos());									
						macro p.intMapOf($expr);
					case _: throw 'Unsupported type parameter for IntMap: $cType';
				}
			case STRINGMAP(valType):
				switch (valType)
				{
					case DYNAMIC: macro p.stringMapOfAny();
					case INT: macro p.stringMapOfInt();
					case FLOAT: macro p.stringMapOfFloat();
					case BOOL: macro p.stringMapOfBool();
					case STRING: macro p.stringMapOfString();
					case PARSABLE(classType):
						var name = classType.module + "." + classType.name + "." + parseUsingName;
						var expr = Context.parse(name, Context.currentPos());									
						macro p.stringMapOf($expr);
					case _: throw 'Unsupported type parameter for StringMap: $cType';
				}
			case ARRAY(valType):
				switch (valType)
				{
					case DYNAMIC: macro p.arrayOfAny();
					case INT: macro p.arrayOfInt();
					case FLOAT:  macro p.arrayOfFloat();
					case BOOL: macro p.arrayOfBool();
					case STRING:  macro p.arrayOfString();
					case PARSABLE(classType):
						var name = classType.module + "." + classType.name + "." + parseUsingName;
						var expr = Context.parse(name, Context.currentPos());								
						macro p.arrayOf($expr);
					case _: throw 'Unsupported type parameter for Array: $cType';
				}
			case OTHER: throw 'Field type $cType not supported';
		}
		/*
		var valueExpr = switch (cType)
		{
			case TPath(p): 
				var type:Type = cType.toType();
				
				switch (type.follow())
				{
					case TAbstract(_.get() => { pack: [], name: "Int" }, []): 	
						macro p.int();
						
					case TAbstract(_.get() => { pack: [], name: "Float" }, []):	
						macro p.float();
						
					case TAbstract(_.get() => { pack: [], name: "Bool" }, []):	
						macro p.bool();					
						
					case TInst(_.get() => { pack: [], name: "String" }, []): 	
						macro p.string();		
					
					case TInst(_.get() => ct, []) if (parsable(ct)):
						var name = ct.module + "." + ct.name + "." + parseUsingName + "(p)";
						var expr = Context.parse(name, Context.currentPos());			
						macro $expr;
					
					case TDynamic(_): 
						macro p.any();
						
					case TInst(_.get() => { pack: [], name: "Array" }, [pType]):	
						switch (pType.follow())
						{
							case TDynamic(_): macro p.arrayOfAny();
							case TAbstract(_.get() => { pack: [], name: "Int" }, []): macro p.arrayOfInt();
							case TAbstract(_.get() => { pack: [], name: "Float" }, []): macro p.arrayOfFloat();
							case TAbstract(_.get() => { pack: [], name: "Bool" }, []): macro p.arrayOfBool();														
							case TInst(_.get() => { pack: [], name: "String" }, []): macro p.arrayOfString();
							case TInst(_.get() => ct, params) if (parsable(ct)):								
								var name = ct.module + "." + ct.name + "." + parseUsingName;
								var expr = Context.parse(name, Context.currentPos());
								
								macro p.arrayOf($expr);
							default: 
								throw 'Unsupported type parameter for Array: $pType';
						}	
					case TInst(_.get() => { pack: ["haxe"], name: "IMap" }, [kt, vt]):
						switch (kt.follow())
						{
							case TInst(_.get() => { pack: [], name: "String" }, []):
								switch (vt.follow())
								{
									case TDynamic(_): macro p.stringMapOfAny();
									case TAbstract(_.get() => { pack: [], name: "Int" }, []): macro p.stringMapOfInt();
									case TAbstract(_.get() => { pack: [], name: "Float" }, []): macro p.stringMapOfFloat();
									case TAbstract(_.get() => { pack: [], name: "Bool" }, []): macro p.stringMapOfBool();													
									case TInst(_.get() => { pack: [], name: "String" }, []): macro p.stringMapOfString();
									case TInst(_.get() => ct, params) if (parsable(ct)):								
										var name = ct.module + "." + ct.name + "." + parseUsingName;
										var expr = Context.parse(name, Context.currentPos());
										
										macro p.stringMapOf($expr);
									default: 
										throw 'Unsupported value type parameter for IMap: $vt';
								}
							case TAbstract(_.get() => { pack: [], name: "Int" }, []):
								switch (vt.follow())
								{
									case TDynamic(_): macro p.intMapOfAny();
									case TAbstract(_.get() => { pack: [], name: "Int" }, []): macro p.intMapOfInt();
									case TAbstract(_.get() => { pack: [], name: "Float" }, []): macro p.intMapOfFloat();
									case TAbstract(_.get() => { pack: [], name: "Bool" }, []): macro p.intMapOfBool();													
									case TInst(_.get() => { pack: [], name: "String" }, []): macro p.intMapOfString();
									case TInst(_.get() => ct, params) if (parsable(ct)):								
										var name = ct.module + "." + ct.name + "." + parseUsingName;
										var expr = Context.parse(name, Context.currentPos());
										
										macro p.intMapOf($expr);
									default: 
										throw 'Unsupported value type parameter for IMap: $vt';
								}
							default:
								throw 'Unsupported key type paramteters for IMap: $kt';
						}
					default: 
						trace(name, type, type.follow(), cType);
						macro {					
							trace("Skipped field: " + $v { name } + " : " + $v { type.toString() } );
							p.skip();						
						}
				}
			case _: throw 'Field type ${cType.toString()} not supported';
		}
		*/
		return {
			values: [macro $v{ name }],			
			expr: macro out.$jsonField = $valueExpr
		}
	}
	
	static function parsable(classType:ClassType):Bool
	{
		return classType.interfaces.exists(function (iface: { t:Ref<ClassType>, params:Array<Type> }):Bool
		{
			var t = iface.t.get();
			return t.isInterface && t.module == "mod.typedjson.IParsable" && t.name == "IParsable";
		});
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