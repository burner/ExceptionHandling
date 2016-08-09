import std.stdio;
import exceptionhandling;

void main()
{
	chain(AssertEqual(1.0, 0.0), "WTF");
}
