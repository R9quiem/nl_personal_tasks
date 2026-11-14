import std.algorithm.sorting : sort;
import std.digest : toHexString;
import std.digest.sha : SHA256;
import std.file : dirEntries, isDir, SpanMode;
import std.parallelism : parallel;
import std.range.primitives : empty;
import std.stdio : File, stderr, writeln;

enum bufferSize = 64 * 1024;

struct Candidate
{
    string path;
    ulong size;
}

string checksum(string path)
{
    auto file = File(path, "rb");
    SHA256 hash;
    hash.start();
    ubyte[bufferSize] buffer;
    while (true)
    {
        auto block = file.rawRead(buffer[]);
        if (block.empty)
            break;
        hash.put(block);
    }
    return toHexString(hash.finish()).idup;
}

bool sameContents(string first, string second)
{
    auto left = File(first, "rb");
    auto right = File(second, "rb");
    ubyte[bufferSize] leftBuffer;
    ubyte[bufferSize] rightBuffer;
    while (true)
    {
        auto leftBlock = left.rawRead(leftBuffer[]);
        auto rightBlock = right.rawRead(rightBuffer[]);
        if (leftBlock != rightBlock)
            return false;
        if (leftBlock.empty)
            return true;
    }
}

string[][] findDuplicates(string directory)
{
    string[][ulong] bySize;
    foreach (entry; dirEntries(directory, SpanMode.depth, false))
    {
        if (entry.isFile && !entry.isSymlink)
            bySize[entry.size] ~= entry.name;
    }

    Candidate[] candidates;
    foreach (size, paths; bySize)
    {
        if (paths.length > 1)
            foreach (path; paths)
                candidates ~= Candidate(path, size);
    }

    auto hashes = new string[candidates.length];
    if (candidates.length > 0)
    {
        foreach (index, candidate; parallel(candidates, 1))
            hashes[index] = checksum(candidate.path);
    }

    string[][string][ulong] bySizeAndHash;
    foreach (index, candidate; candidates)
        bySizeAndHash[candidate.size][hashes[index]] ~= candidate.path;

    string[][] duplicates;
    foreach (byHash; bySizeAndHash)
    {
        foreach (paths; byHash)
        {
            if (paths.length < 2)
                continue;

            string[][] groups;
            foreach (path; paths)
            {
                size_t groupIndex = 0;
                while (groupIndex < groups.length && !sameContents(groups[groupIndex][0], path))
                    ++groupIndex;

                if (groupIndex == groups.length)
                    groups ~= [path];
                else
                    groups[groupIndex] ~= path;
            }

            foreach (group; groups)
            {
                if (group.length > 1)
                {
                    sort(group);
                    duplicates ~= group;
                }
            }
        }
    }

    sort!((a, b) => a[0] < b[0])(duplicates);
    return duplicates;
}

int main(string[] args)
{
    if (args.length != 2)
    {
        stderr.writeln("Usage: duplicates <directory>");
        return 1;
    }

    try
    {
        if (!isDir(args[1]))
        {
            stderr.writeln("Error: expected a directory");
            return 1;
        }

        auto groups = findDuplicates(args[1]);
        if (groups.empty)
            writeln("No duplicates found.");
        foreach (index, group; groups)
        {
            writeln("Group ", index + 1, ":");
            foreach (path; group)
                writeln("  ", path);
        }
        return 0;
    }
    catch (Exception error)
    {
        stderr.writeln("Error: ", error.msg);
        return 1;
    }
}
