import java.io.File
import java.io.IOException
import java.math.BigInteger
import java.util.Scanner
import java.util.concurrent.Callable
import java.util.concurrent.ExecutionException
import java.util.concurrent.Executors

private typealias Matrix = Array<IntArray>

private fun Scanner.readInt(label: String): Int {
    require(hasNext()) { "Missing $label" }
    return requireNotNull(next().toIntOrNull()) { "Invalid integer for $label" }
}

private fun Scanner.readMatrix(name: String, oddDimensions: Boolean = false): Matrix {
    val rows = readInt("$name row count")
    val columns = readInt("$name column count")
    require(rows > 0 && columns > 0) { "$name dimensions must be positive" }
    if (oddDimensions) {
        require(rows % 2 == 1 && columns % 2 == 1) { "$name dimensions must be odd" }
    }
    return Array(rows) { IntArray(columns) { readInt("$name element") } }
}

private fun convolveRow(matrix: Matrix, kernel: Matrix, row: Int): Array<BigInteger> {
    val columns = matrix[0].size
    val kernelColumns = kernel[0].size

    return Array(columns) { column ->
        var sum = BigInteger.ZERO
        for (kernelRow in kernel.indices) {
            val sourceRow = row + kernelRow - kernel.size / 2
            if (sourceRow !in matrix.indices) continue

            for (kernelColumn in 0 until kernelColumns) {
                val sourceColumn = column + kernelColumn - kernelColumns / 2
                if (sourceColumn !in 0 until columns) continue

                val coefficient = kernel[kernel.lastIndex - kernelRow][kernelColumns - 1 - kernelColumn]
                val product = matrix[sourceRow][sourceColumn].toLong() * coefficient
                sum += BigInteger.valueOf(product)
            }
        }
        sum
    }
}

private fun convolve(matrix: Matrix, kernel: Matrix, threads: Int): Array<Array<BigInteger>> {
    val workers = minOf(threads, matrix.size)
    val rowsPerWorker = matrix.size / workers
    val extraRows = matrix.size % workers
    val result = Array(matrix.size) { emptyArray<BigInteger>() }
    val executor = Executors.newFixedThreadPool(workers)

    try {
        var nextRow = 0
        val tasks = List(workers) { worker ->
            val start = nextRow
            val end = start + rowsPerWorker + if (worker < extraRows) 1 else 0
            nextRow = end
            Callable {
                for (row in start until end) {
                    result[row] = convolveRow(matrix, kernel, row)
                }
            }
        }
        for (future in executor.invokeAll(tasks)) {
            future.get()
        }
        return result
    } finally {
        executor.shutdown()
    }
}

private fun run(args: Array<String>) {
    require(args.size in 1..2) { "Usage: java -jar convolution.jar <file> [threads]" }
    val threads = if (args.size == 2) {
        requireNotNull(args[1].toIntOrNull()?.takeIf { it > 0 }) {
            "Threads must be a positive integer"
        }
    } else {
        Runtime.getRuntime().availableProcessors()
    }

    val (matrix, kernel) = Scanner(File(args[0]), Charsets.UTF_8.name()).use { input ->
        val matrix = input.readMatrix("matrix")
        val kernel = input.readMatrix("kernel", oddDimensions = true)
        val extraInput = input.hasNext()
        input.ioException()?.let { throw it }
        require(!extraInput) { "Unexpected data after kernel" }
        matrix to kernel
    }

    for (row in convolve(matrix, kernel, threads)) {
        println(row.joinToString(" "))
    }
}

fun main(args: Array<String>) {
    try {
        run(args)
    } catch (error: IllegalArgumentException) {
        System.err.println("Error: ${error.message}")
        kotlin.system.exitProcess(1)
    } catch (error: IOException) {
        System.err.println("Error: ${error.message}")
        kotlin.system.exitProcess(1)
    } catch (error: ExecutionException) {
        System.err.println("Worker error: ${error.cause?.message}")
        kotlin.system.exitProcess(1)
    } catch (_: InterruptedException) {
        System.err.println("Error: computation interrupted")
        kotlin.system.exitProcess(1)
    }
}
