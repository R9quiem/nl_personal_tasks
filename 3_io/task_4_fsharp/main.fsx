open System
open System.Collections.Generic
open System.IO
open System.Text
open System.Text.RegularExpressions

let buildIndex inputPath =
    let index = Dictionary<string, ResizeArray<int>>(StringComparer.Ordinal)
    let pattern = Regex(@"\p{L}[\p{L}\p{M}]*")
    let mutable lineNumber = 0
    for line in File.ReadLines(inputPath, UTF8Encoding(false, true)) do
        lineNumber <- lineNumber + 1
        let normalized = line.Normalize(NormalizationForm.FormC).ToLowerInvariant()
        for matched in pattern.Matches(normalized) do
            let word = matched.Value
            match index.TryGetValue(word) with
            | true, rows ->
                if rows[rows.Count - 1] <> lineNumber then
                    rows.Add(lineNumber)
            | false, _ ->
                let rows = ResizeArray<int>()
                rows.Add(lineNumber)
                index.Add(word, rows)
    index

let writeIndex outputPath (index: Dictionary<string, ResizeArray<int>>) =
    let destination = Path.GetFullPath(outputPath)
    let temporary = Path.Combine(Path.GetDirectoryName(destination), Path.GetRandomFileName())
    try
        do
            use stream = new FileStream(temporary, FileMode.CreateNew, FileAccess.Write, FileShare.None)
            use writer = new StreamWriter(stream, UTF8Encoding(false))
            let words =
                index.Keys
                |> Seq.sortWith (fun first second ->
                    let order = StringComparer.InvariantCulture.Compare(first, second)
                    if order <> 0 then order else StringComparer.Ordinal.Compare(first, second))
            for word in words do
                writer.Write(word)
                writer.Write(": ")
                writer.WriteLine(String.Join(", ", index[word]))
        File.Move(temporary, destination, true)
    finally
        if File.Exists(temporary) then File.Delete(temporary)

try
    let arguments = fsi.CommandLineArgs |> Array.skip 1
    if arguments.Length <> 2 then
        invalidArg "arguments" "usage: dotnet fsi main.fsx <input> <output>"
    let index = buildIndex arguments[0]
    writeIndex arguments[1] index
with error ->
    eprintfn "Error: %s" error.Message
    exit 1
