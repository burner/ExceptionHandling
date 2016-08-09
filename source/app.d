import std.stdio;
import exceptionhandling;
import std.exception : assertThrown;

void main()
{
	assertThrown!Exception(
		chain(assertEqual(1.0, 0.0), "WTF")
	);
	bool value = expect(true);
}
