import util.log;

void main()
{
    log = Log(stderrLogger, stdoutLogger(LogLevel.info), fileLogger("log"));
    log.warn("test");
}