import std.stdio;
import std.datetime;
import util.log;
import dateparser;

void main()
{
    log = Log(stderrLogger, stdoutLogger(LogLevel.info), fileLogger("log"));
    log.info("hello xmake");

    assert(parse("2003-09-25") == SysTime(DateTime(2003, 9, 25)));
    assert(parse("09/25/2003") == SysTime(DateTime(2003, 9, 25)));
    assert(parse("Sep 2003")   == SysTime(DateTime(2003, 9, 1)));
}
