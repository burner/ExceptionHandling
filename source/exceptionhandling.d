module exceptionhandling;

void AssertEqual(T)(auto ref T toTest, auto ref T toCompareAgainst, 
		const string file = __FILE__, const int line = __LINE__) 
{
	version(unittest) {
		import core.exception : AssertError;
		alias ExceptionType = AssertError;
	} else {
		alias ExceptionType = Exception;
	}
	import std.traits : isFloatingPoint;

	static if(isFloatingPoint!T) {
		import std.math : approxEqual;
		bool cmpRslt = approxEqual(toTest, toCompareAgainst);
	} else {
		bool cmpRslt = toTest == toCompareAgainst;
	}

	if(!cmpRslt) {
		import std.format : format;
		throw new ExceptionType(format("toTest(%s) != toCompareAgainst(%s)",
			toTest, toCompareAgainst), file, line
		);
	}
}

unittest {
	import core.exception : AssertError;
	import std.exception : assertThrown;
	AssertEqual(1.0, 1.0);

	assertThrown!AssertError(AssertEqual(1.0, 0.0));
}

auto chain(ET = Exception, F, int line = __LINE__, string file = __FILE__, Args...)
		(lazy F exp, lazy Args args)
{
	try {
		return exp();
	} catch(Exception e) {
		throw new ET(joinElem(args), file, line, e);
	}
}

void expect(ET = Exception, F, int line = __LINE__, string file = __FILE__, Args...)
		(lazy F exp, lazy Args args)
{
	if(!exp) {
		throw new ET(joinElem(args), file, line);
	}
}

private string joinElem(Args...)(lazy Args args) {
	import std.array : appender;
	import std.format : formattedWrite;	

	auto app = appender!string();
	foreach(arg; args) {
		formattedWrite(app, "%s ", arg);
	}
	return app.data;
}
