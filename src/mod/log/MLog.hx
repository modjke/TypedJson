package mod.log ;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.MacroType;
import haxe.macro.TypeTools;
import haxe.rtti.Meta;
import haxe.Timer;

/**
 * MLog
 * 
 * Manual usage(import mod.log.MLog.mlog) 
 * 	mlog(arg1,arg2,arg3...)
 * 
 * Automatic logging for the whole class
 * 	(by default all class methods are affected)
 * 
 * 	@:build(mod.log.MLog.autoLog())
 * 	class YourClass {...}
 * 
 * Method arguments logging
 * 	By default mlog logs only values of basic types 
 * 	and uses type name for other types (null if value is null),
 * 	to enable logging for all values add
 * 	@:logComplexArgs metadata to corresponding method,
 * 	so mlog will call Std.string on all values
 * 
 * Metadata
 * @:logComplexArgs (method only) - enable logging for complex values
 * @:noLog (class, method) - ignore all mlog call (automatic + manual)
 * @:noAutoLog (method only) - disable auto logging for this method only
 */
class MLog
{	
	public static var creationTime = Timer.stamp();

	macro public static inline function mlog(rest:Array<Expr>)
	{
		for (meta in  Context.getLocalClass().get().meta.get())
			if (meta.name == ":noLog")			
				return macro null;		
	
		for (field in Context.getLocalClass().get().fields.get())
		{
			if (field.name == Context.getLocalMethod())						
			{
				for (meta in field.meta.get())
					if (meta.name == ":noLog")
						return macro null;
			}
		}

		var class_method = "[" + Context.getLocalClass().toString() + "::" + Context.getLocalMethod() + "]";				
		
		rest.unshift(Context.makeExpr(class_method, Context.currentPos()));
		rest.unshift(macro Std.int((haxe.Timer.stamp() - mod.log.MLog.creationTime) * 1000));				
			
		return macro trace( $a { rest } );
	}
	
	#if macro
	public static function autoLog():Array<Field>
    {	
		var fields:Array<Field> = Context.getBuildFields();		
		
		for (field in fields)
		{
			switch (field.kind)
			{
				default:
				case FFun(f):
				{
					var noAutoLog = Lambda.exists(field.meta, function (meta) { return meta.name == ":noAutoLog"; } );	
					if (noAutoLog) continue;
					
					var complexArgs = Lambda.exists(field.meta, function (meta) { return meta.name == ":logComplexArgs"; } );			
					var values:Array<Expr> = new Array<Expr>();										
					for (arg in f.args)					
						if (complexArgs)
							values.push( macro Std.string($i { arg.name } ) )
						else 
						{
							if (arg.type != null)
							{
								values.push(
									switch (arg.type)
									{
										default: macro "unknown";
										case TPath(p):
											switch (p.name)
											{
												case "Int": macro $i{arg.name}
												case "Bool": macro $i { arg.name }
												case "String": macro $i { arg.name }
												case "Float": macro $i {arg.name }
												default:												
													macro $i{arg.name} != null ? "[" + $v{p.name} + "]" : "null";
											}
									}							
								);
							} else 
								values.push(macro "unknown");
							
						}
		
						
					switch (f.expr.expr)
					{
						default:
						case EBlock(exprs):
							exprs.unshift(macro mod.log.MLog.mlog($a{values}));
					}
				}
			}
		}
        return fields;
    }
	#end
}