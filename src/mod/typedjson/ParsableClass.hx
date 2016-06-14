package mod.typedjson;

typedef ParsableClass<T> = {
	function parseUsing(parse:TypedJsonParser):T;
}