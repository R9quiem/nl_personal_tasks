import java.nio.file.{Files, Path}
import java.io.IOException
import java.util.concurrent.{Callable, Executors}

object Main {
  case class Run(start: Int, length: Int)
  case class Summary(from: Int, until: Int, prefix: Int, suffix: Int, best: Run) {
    def size: Int = until - from
  }

  private def better(first: Run, second: Run): Run =
    if (second.length > first.length ||
        (second.length == first.length && second.start < first.start)) second
    else first

  private def scan(values: Array[Int], from: Int, until: Int): Summary = {
    var start = from
    var prefix = until - from
    var best = Run(from, 1)
    var index = from + 1
    while (index < until) {
      if (values(index - 1) >= values(index)) {
        if (start == from) prefix = index - from
        best = better(best, Run(start, index - start))
        start = index
      }
      index += 1
    }
    val suffix = until - start
    Summary(from, until, prefix, suffix, better(best, Run(start, suffix)))
  }

  private def merge(values: Array[Int], left: Summary, right: Summary): Summary = {
    val best = better(left.best, right.best)
    if (values(left.until - 1) < values(right.from)) {
      val crossing = Run(left.until - left.suffix, left.suffix + right.prefix)
      val prefix = if (left.prefix == left.size) left.size + right.prefix else left.prefix
      val suffix = if (right.suffix == right.size) right.size + left.suffix else right.suffix
      Summary(left.from, right.until, prefix, suffix, better(best, crossing))
    } else {
      Summary(left.from, right.until, left.prefix, right.suffix, best)
    }
  }

  def longestRun(values: Array[Int], threads: Int): Option[Run] = {
    require(threads > 0, "threads must be a positive integer")
    if (values.isEmpty) return None
    val workers = math.min(threads, values.length)
    val base = values.length / workers
    val extra = values.length % workers
    val executor = Executors.newFixedThreadPool(workers)
    try {
      val tasks = Vector.tabulate(workers) { worker =>
        val from = worker * base + math.min(worker, extra)
        val until = from + base + (if (worker < extra) 1 else 0)
        executor.submit(new Callable[Summary] {
          override def call(): Summary = scan(values, from, until)
        })
      }
      val combined = tasks.iterator.map(_.get()).reduceLeft { (left, right) =>
        merge(values, left, right)
      }
      Some(combined.best)
    } finally {
      executor.shutdown()
    }
  }

  private def run(args: Array[String]): Unit = {
    require(args.length >= 1 && args.length <= 2, "usage: Main <file> [threads]")
    val threads = args.lift(1).map { raw =>
      raw.toIntOption.filter(_ > 0).getOrElse {
        throw new IllegalArgumentException("threads must be a positive integer")
      }
    }.getOrElse(Runtime.getRuntime.availableProcessors())

    val text = Files.readString(Path.of(args(0))).trim
    val values =
      if (text.isEmpty) Array.empty[Int]
      else text.split("\\s+").map { token =>
        token.toIntOption.getOrElse(throw new IllegalArgumentException(s"invalid integer: $token"))
      }

    longestRun(values, threads) match {
      case Some(Run(start, length)) =>
        println(s"length=$length start=$start end=${start + length - 1}")
      case None =>
        println("length=0 start=-1 end=-1")
    }
  }

  def main(args: Array[String]): Unit = {
    try run(args)
    catch {
      case error: IllegalArgumentException =>
        System.err.println(s"Error: ${error.getMessage}")
        sys.exit(1)
      case error: IOException =>
        System.err.println(s"Error: ${error.getMessage}")
        sys.exit(1)
    }
  }
}
