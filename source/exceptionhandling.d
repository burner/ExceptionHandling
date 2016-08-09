module exceptionhandling;

private {
	import std.math : approxEqual;
	bool cmpFloat(T)(T tt, T tc) {
		return approxEqual(tt, tc);
	}

	bool cmpFloatNot(T)(T tt, T tc) {
		return !approxEqual(tt, tc);
	}

	bool cmpRest(T)(T tt, T tc) {
		return tt == tc;
	}

	bool cmpRestNot(T)(T tt, T tc) {
		return tt == tc;
	}
}

ref T AssertEqual(T)(auto ref T toTest, auto ref T toCompareAgainst, 
		const string file = __FILE__, const int line = __LINE__) 
{
	import std.traits : isFloatingPoint;
	static if(isFloatingPoint!T) {
		return AssertImpl!(T, cmpFloat)(toTest, toCompareAgainst, file, line);
	} else {
		return AssertImpl!(T, cmp)(toTest, toCompareAgainst, file, line);
	}
}

ref T AssertNotEqual(T)(auto ref T toTest, auto ref T toCompareAgainst, 
		const string file = __FILE__, const int line = __LINE__) 
{
	import std.traits : isFloatingPoint;
	static if(isFloatingPoint!T) {
		return AssertImpl!(T, cmpFloatNot)(toTest, toCompareAgainst, file, line);
	} else {
		return AssertImpl!(T, cmpNot)(toTest, toCompareAgainst, file, line);
	}
}

private ref T AssertImpl(T,alias Cmp)(auto ref T toTest, auto ref T toCompareAgainst, 
		const string file, const int line) 
{
	import std.format : format;
	version(unittest) {
		import core.exception : AssertError;
		alias ExceptionType = AssertError;
	} else {
		alias ExceptionType = Exception;
	}

	try {
		auto cmpRslt = Cmp(toTest, toCompareAgainst);
		if(!cmpRslt) {
			throw new ExceptionType(format("toTest(%s) != toCompareAgainst(%s)",
				toTest, toCompareAgainst), file, line
			);
		}
		return toTest;
	} catch(ExceptionType e) {
		throw new ExceptionType(
			format("Exception thrown while \"toTest(%s) != toCompareAgainst(%s)\"",
			toTest, toCompareAgainst), file, line, e
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

auto expect(ET = Exception, F, int line = __LINE__, string file = __FILE__, Args...)
		(lazy F exp, lazy Args args)
{
	try {
		return exp();
	} catch(Exception e) {
		throw new ET(joinElem(args), file, line, e);
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
