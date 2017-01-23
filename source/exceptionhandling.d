module exceptionhandling;

/**
   version(exceptionhandling_release_asserts)
   
   releases all assertXXXXs
*/

private {
	version(unittest) {
		import core.exception : AssertError;
		alias ExceptionType = AssertError;
	} else {
		alias ExceptionType = Exception;
	}

	import std.math : approxEqual;
	bool cmpFloat(T)(T tt, T tc) {
		return approxEqual(tt, tc);
	}

	bool cmpFloatNot(T)(T tt, T tc) {
		return !approxEqual(tt, tc);
	}

	bool cmpNot(T,S)(T tt, S tc) {
		return tt != tc;
	}

	bool cmp(T,S)(T tt, S tc) {
		return tt == tc;
	}

	bool cmpLess(T,S)(T tt, S tc) {
		return tt < tc;
	}

	bool cmpGreater(T,S)(T tt, S tc) {
		return tt > tc;
	}

	bool cmpLessEqual(T,S)(T tt, S tc) {
		return tt <= tc;
	}

	bool cmpGreaterEqual(T,S)(T tt, S tc) {
		return tt >= tc;
	}

	bool cmpLessEqualFloat(T)(T tt, T tc) {
		return tt < tc || approxEqual(tt, tc);
	}

	bool cmpGreaterEqualFloat(T)(T tt, T tc) {
		return tt > tc || approxEqual(tt, tc);
	}
}

template getCMP(T, alias FCMP, alias ICMP) {
	import std.traits : isFloatingPoint;
	import std.range : ElementType, isInputRange;

	static if(isInputRange!T) {
		static if(isFloatingPoint!(ElementType!(T))) {
			alias getCMP = FCMP;
		} else {
			alias getCMP = ICMP;
		}
	} else {
		static if(isFloatingPoint!T) {
			alias getCMP = FCMP;
		} else {
			alias getCMP = ICMP;
		}
	}
}

/** Assert that `toTest` is equal to `toCompareAgainst`.
If `T` is a floating point `approxEqual` is used to compare the values.
`toTest` is returned if the comparision is correct.
If the comparision is incorrect an Exception is thrown. If assertEqual is used
in a unittest block an AssertError is thrown an Exception otherwise.
*/
auto ref T assertEqual(T,S)(auto ref T toTest, auto ref S toCompareAgainst,
		const string file = __FILE__, const int line = __LINE__)
{
	version(assert) {
		alias CMP = getCMP!(T, cmpFloat, cmp);
		return AssertImpl!(T,S, CMP, "==")(toTest, toCompareAgainst,
				file, line
		);
	} else {
		return toTest;
	}
}

/// ditto
auto ref T assertNotEqual(T,S)(auto ref T toTest, auto ref S toCompareAgainst,
		const string file = __FILE__, const int line = __LINE__)
{
	version(assert) {
		alias CMP = getCMP!(T,cmpFloatNot, cmpNot);
		return AssertImpl!(T,S, CMP, "!=")(toTest, toCompareAgainst, file,
				line
		);
	} else {
		return toTest;
	}
}

/// ditto
auto ref T assertLess(T,S)(auto ref T toTest, auto ref S toCompareAgainst,
		const string file = __FILE__, const int line = __LINE__)
{
	version(assert) {
		return AssertImpl!(T,S, cmpLess, "<")(toTest, toCompareAgainst,
				file, line
		);
	} else {
		return toTest;
	}
}

/// ditto
auto ref T assertGreater(T,S)(auto ref T toTest, auto ref S toCompareAgainst,
		const string file = __FILE__, const int line = __LINE__)
{
	version(assert) {
		return AssertImpl!(T,S, cmpGreater, ">")(toTest, toCompareAgainst,
				file, line
		);
	} else {
		return toTest;
	}
}

/// ditto
auto ref T assertGreaterEqual(T,S)(auto ref T toTest, auto ref S toCompareAgainst,
		const string file = __FILE__, const int line = __LINE__)
{
	version(assert) {
		alias CMP = getCMP!(T,cmpGreaterEqualFloat, cmpGreaterEqual);
		return AssertImpl!(T,S, CMP, ">=")(toTest,
				toCompareAgainst, file, line
		);
	} else {
		return toTest;
	}
}

/// ditto
auto ref T assertLessEqual(T,S)(auto ref T toTest, auto ref S toCompareAgainst,
		const string file = __FILE__, const int line = __LINE__)
{
	version(assert) {
		alias CMP = getCMP!(T,cmpLessEqualFloat, cmpLessEqual);
		return AssertImpl!(T,S, CMP, "<=")(toTest,
				toCompareAgainst, file, line
		);
	} else {
		return toTest;
	}
}

private auto ref T AssertImpl(T,S,alias Cmp, string cmpMsg)(auto ref T toTest,
		auto ref S toCompareAgainst, const string file, const int line)
{
	import std.format : format;
	import std.range : isForwardRange, isInputRange;

	static assert(!isInputRange!T || isForwardRange!T);
	version(exceptionhandling_release_asserts) {
		return toTest;
	} else {
		bool cmpRslt = false;
		try {
			static if(isForwardRange!T && isForwardRange!S) {
				import std.algorithm.comparison : equal;
				import std.traits : isImplicitlyConvertible;
				import std.range.primitives : isInputRange, ElementType;
				import std.functional : binaryFun;
				import std.array : empty, front, popFront;
				static assert(isImplicitlyConvertible!(
						ElementType!(T),
						ElementType!(S)),
						format("You can not compare ranges of type %s to"
							~ " ranges of type %s.", ElementType!(T).stringof,
							ElementType!(S).stringof)
				);
				alias CMP = Cmp!(ElementType!T,ElementType!S);
				while(!toTest.empty && !toCompareAgainst.empty) {
					if(!CMP(toTest.front, toCompareAgainst.front)) {
						cmpRslt = false;
						goto fail;
					}
					if(!toTest.empty && !toCompareAgainst.empty) {
						toTest.popFront();
						toCompareAgainst.popFront();
					} 
				}
				if(toTest.empty != toCompareAgainst.empty) {
					cmpRslt = false;
					goto fail;
				}
				cmpRslt = true;
				
				fail:
			} else {
				cmpRslt = Cmp(toTest, toCompareAgainst);
			}
		} catch(Exception e) {
			throw new ExceptionType(
				format("Exception thrown while \"toTest(%s) " ~ cmpMsg
					~ " toCompareAgainst(%s)\"",
				toTest, toCompareAgainst), file, line, e
			);
		}

		if(!cmpRslt) {
			throw new ExceptionType(format("toTest(%s) " ~ cmpMsg ~
				" toCompareAgainst(%s) failed", toTest, toCompareAgainst), file, 
					line
			);
		}
		return toTest;
	}
}

unittest {
	import core.exception : AssertError;
	import std.exception : assertThrown;
	import std.meta : AliasSeq;

	foreach(T; AliasSeq!(byte,int,float,double)) {
		T zero = 0;
		T one = 1;
		T two = 2;

		T ret = assertEqual(one, one).assertGreater(zero).assertLess(two);
		cast(void)assertEqual(ret, one);
		ret = assertNotEqual(one, zero).assertGreater(zero).assertLess(two);
		cast(void)assertEqual(ret, one);
		ret = assertLessEqual(one, two)
			.assertGreaterEqual(zero)
			.assertEqual(one);
		cast(void)assertEqual(ret, one);

		cast(void)assertEqual(cast(const(T))one, one);
		cast(void)assertNotEqual(cast(const(T))one, zero);
		cast(void)assertEqual(one, cast(const(T))one);
		cast(void)assertNotEqual(one, cast(const(T))zero);

		bool t = false;
		try {
			cast(void)assertEqual(one, zero);
		} catch(Throwable e) {
			t = true;
		}
		assert(t);
	}

	cast(void)assertEqual(1, 1);
	cast(void)assertNotEqual(1, 0);
}

unittest {
	import core.exception : AssertError;
	import std.exception : assertThrown;

	class Foo {
		int a;
		this(int a) { this.a = a; }
		override bool opEquals(Object o) {
			throw new Exception("Another test");
		}
	}

	auto f = new Foo(1);
	auto g = new Foo(1);

	assertThrown!AssertError(assertEqual(f, cast(Foo)null));
	assertThrown!AssertError(assertEqual(f, g));
	assertNotThrown!AssertError(assertEqual([0,1,2,3,4], [0,1,2,3,4]));
	assertThrown!AssertError(assertEqual([0,2,3,4], [0,1,2,3,4]));
	assertThrown!AssertError(assertEqual([0,2,3,4], [0,1,2]));
	assertThrown!AssertError(assertEqual([0,1,2,3,5], [0,1,2,3,4]));
	assertThrown!AssertError(assertEqual([0,1,2,3], [0,1,2,3,4]));

	import std.container.array : Array;

	auto ia = Array!int([0,1,2,3,4]);
	assertNotThrown!AssertError(assertEqual(ia[], [0,1,2,3,4]));
	assertThrown!AssertError(assertEqual(ia[], [0,1,2,3]));
	assertThrown!AssertError(assertEqual(ia[], [0,1,2,3,4,5]));
}

/** Calls `exp` if `exp` does not throw the return value from `exp` is
returned, if `exp` throws the Exception is cought, a new Exception is
constructed with a message made of `args` space seperated and the previously
cought exception is nested in the newly created exception.
*/
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

unittest {
	import std.string : indexOf;
	import std.exception : assertThrown;

	string barMsg = "Fun will thrown, I'm sure";
	string funMsg = "Hopefully this is true";

	void fun() {
		throw new Exception(funMsg);
	}

	void bar() {
		expect(fun(), barMsg);
	}

	bool func() {
		throw new Exception("e");
	}


	bool didThrow = false;
	try {
		bar();
	} catch(Exception e) {
		assert(e.msg.indexOf(barMsg) != -1, "\"" ~ e.msg ~ "\" " ~ barMsg);
		assert(e.next !is null);
		assert(e.next.msg.indexOf(funMsg) != -1, e.next.msg);
		didThrow = true;
	}

	assert(didThrow);

	assertThrown(assertEqual(func(), true));
}

///
auto ref ensure(ET = ExceptionType, E, int line = __LINE__,
		string file = __FILE__, Args...)(lazy E exp, Args args)
{
	typeof(exp) rslt;

	try {
		rslt = exp();
	} catch(Throwable e) {
		throw new Exception(
			"Exception thrown will calling \"ensure\"", file, line, e
		);
	}

	if(!rslt) {
		throw new Exception(joinElem("Ensure failed", args), file, line);
	} else {
		return rslt;
	}
}

///
unittest {
	import core.exception : AssertError;
	//import std.exception : assertThrown, assertNotThrown;
	bool func() {
		throw new Exception("e");
	}

	auto e = assertThrown!Exception(ensure(func()));
	assert(e.line == __LINE__ - 1);
	auto e2 = assertThrown!Exception(ensure(false));
	assert(e2.line == __LINE__ - 1);
	bool b = assertNotThrown!Exception(ensure(true));
	assert(b);
}

E assertThrown(E,T)(lazy T t, int line = __LINE__,
		string file = __FILE__)
{
	try {
		t();
	} catch(E e) {
		return e;
	}
	throw new ExceptionType("Exception of type " ~ E.stringof ~
			" was not thrown even though expected.", file, line
	);
}

auto assertNotThrown(E,T)(lazy T t, int line = __LINE__,
		string file = __FILE__)
{
	try {
		return t();
	} catch(E e) {
		throw new ExceptionType("Exception of type " ~ E.stringof ~
				" caught unexceptionally", file, line
		);
	}
}

///
unittest {
	import core.exception : AssertError;
	//import std.exception : assertThrown, assertNotThrown;
	bool foo() {
		throw new Exception("e");
	}

	bool bar() {
		return true;
	}

	assertThrown!(AssertError)(assertThrown!(AssertError)(bar()));
	assertThrown!(AssertError)(assertNotThrown!(Exception)(foo()));
}

unittest {
	struct C {
		int a;

		bool opEquals(int other) const {
			return this.a == other;
		}

		bool opEquals(C other) const {
			return this.a == other.a;
		}

		int opCmp(int other) const {
			return this.a < other ? -1 : this.a > other ? 1 : 0;
		}

		int opCmp(C other) const {
			return this.a < other.a ? -1 : this.a > other.a ? 1 : 0;
		}
	}

	assertEqual(C(10), 10);
	assertLess(C(7), 9);
	assertGreater(C(10), 9);
	assertLessEqual(C(7), 9);
	assertGreaterEqual(C(10), 9);
	assertLessEqual(C(7), 7);
	assertGreaterEqual(C(10), 10);

	assertEqual(C(10), C(10));
	assertLess(C(7), C(9));
	assertGreater(C(10), C(9));
	assertLessEqual(C(7), C(9));
	assertGreaterEqual(C(10), C(9));
	assertLessEqual(C(7), C(7));
	assertGreaterEqual(C(10), C(10));
}
