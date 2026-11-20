local staging

local function timestamp(line)
    local year, month, day, hour, minute, second = line:match(
        "^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)Z")
    assert(year, "expected timestamp YYYY-MM-DDTHH:MM:SSZ")
    assert(#line == 20 or line:sub(21, 21):match("%s"), "expected space after timestamp")
    year, month, day = tonumber(year), tonumber(month), tonumber(day)
    hour, minute, second = tonumber(hour), tonumber(minute), tonumber(second)
    local leap = year % 400 == 0 or (year % 4 == 0 and year % 100 ~= 0)
    local days = { 31, leap and 29 or 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    assert(month >= 1 and month <= 12 and day >= 1 and day <= (days[month] or 0)
        and hour <= 23 and minute <= 59 and second <= 59, "invalid timestamp")
    return line:sub(1, 20)
end

local function next_record(stream)
    local line, message = stream.file:read("l")
    assert(not message, message)
    if not line then return nil end
    line = line:gsub("\r$", "")
    local time = timestamp(line)
    assert(not stream.previous or stream.previous <= time, "input log is not sorted")
    stream.previous = time
    return { text = line, time = time }
end

local function temporary_path(output)
    local name = os.tmpname()
    os.remove(name)
    local directory = output:match("^(.*[/\\])") or ""
    return directory .. name:match("[^/\\]+$")
end

local function merge(first_path, second_path, output_path)
    local first <close> = assert(io.open(first_path, "rb"))
    local second <close> = assert(io.open(second_path, "rb"))
    staging = temporary_path(output_path)
    local output <close> = assert(io.open(staging, "wb"))
    local first_stream, second_stream = { file = first }, { file = second }
    local left, right = next_record(first_stream), next_record(second_stream)
    while left or right do
        if not right or (left and left.time <= right.time) then
            assert(output:write(left.text, "\n"))
            left = next_record(first_stream)
        else
            assert(output:write(right.text, "\n"))
            right = next_record(second_stream)
        end
    end
    assert(output:flush())
end

local function replace_output(output)
    local renamed, message = os.rename(staging, output)
    if renamed then return end
    -- Windows rename needs a separate step when the output file already exists.
    local existing = io.open(output, "rb")
    assert(existing, message)
    local _, read_error = existing:read(1)
    existing:close()
    assert(not read_error, read_error)
    local backup = temporary_path(output)
    assert(os.rename(output, backup))
    local replaced, replace_error = os.rename(staging, output)
    if not replaced then
        local restored, restore_error = os.rename(backup, output)
        assert(restored, "cannot restore output from " .. backup .. ": " .. tostring(restore_error))
        error(replace_error)
    end
    assert(os.remove(backup))
end

local function run()
    assert(#arg == 3, "usage: lua54 main.lua <first> <second> <output>")
    merge(arg[1], arg[2], arg[3])
    replace_output(arg[3])
end

local success, message = pcall(run)
if staging then os.remove(staging) end
if not success then
    io.stderr:write("Error: ", tostring(message), "\n")
    os.exit(1)
end
