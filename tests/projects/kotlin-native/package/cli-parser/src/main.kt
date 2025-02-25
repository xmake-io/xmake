import kotlinx.cli.ArgParser
import kotlinx.cli.ArgType
import kotlinx.cli.default

fun main(args: Array<String>) {
    val parser = ArgParser("example")
    val name by parser.option(ArgType.String, shortName = "n", description = "Your name").default("World")
    parser.parse(args)
    println("Hello, $name!")
}
