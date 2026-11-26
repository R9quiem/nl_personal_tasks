import std/[asyncdispatch, asyncnet, net, os, strutils]

type Version = object
  core: array[3, string]
  prerelease: seq[string]

proc digits(value: string): bool =
  value.len > 0 and value.allCharsInSet({'0'..'9'})

proc identifiers(value: string, prerelease: bool): seq[string] =
  result = value.split('.')
  for item in result:
    if item.len == 0 or not item.allCharsInSet({'A'..'Z', 'a'..'z', '0'..'9', '-'}):
      raise newException(ValueError, "invalid identifier")
    if prerelease and digits(item) and item.len > 1 and item[0] == '0':
      raise newException(ValueError, "leading zero in prerelease")

proc parseVersion(text: string): Version =
  let metadata = text.split('+')
  if metadata.len > 2: raise newException(ValueError, "invalid metadata")
  if metadata.len == 2: discard identifiers(metadata[1], false)
  let parts = metadata[0].split('-', maxsplit = 1)
  let core = parts[0].split('.')
  if core.len != 3: raise newException(ValueError, "expected major.minor.patch")
  for index, number in core:
    if not digits(number) or (number.len > 1 and number[0] == '0'):
      raise newException(ValueError, "invalid numeric component")
    result.core[index] = number
  if parts.len == 2: result.prerelease = identifiers(parts[1], true)

proc compareNumber(first, second: string): int =
  result = cmp(first.len, second.len)
  if result == 0: result = cmp(first, second)

proc compareVersions(first, second: Version): int =
  for index in 0..2:
    let order = compareNumber(first.core[index], second.core[index])
    if order != 0: return order
  if first.prerelease.len == 0 and second.prerelease.len == 0: return 0
  if first.prerelease.len == 0: return 1
  if second.prerelease.len == 0: return -1
  for index in 0..<min(first.prerelease.len, second.prerelease.len):
    let left = first.prerelease[index]
    let right = second.prerelease[index]
    var order: int
    if digits(left) and digits(right): order = compareNumber(left, right)
    elif digits(left): order = -1
    elif digits(right): order = 1
    else: order = cmp(left, right)
    if order != 0: return order
  cmp(first.prerelease.len, second.prerelease.len)

proc reply(command: string): string =
  try:
    let parts = command.splitWhitespace()
    if parts.len != 3 or parts[0] != "COMPARE":
      return "ERR expected COMPARE <first> <second>"
    let order = compareVersions(parseVersion(parts[1]), parseVersion(parts[2]))
    if order < 0: "OLDER"
    elif order > 0: "NEWER"
    else: "EQUAL"
  except ValueError:
    "ERR invalid semantic version"

proc handle(client: AsyncSocket) {.async.} =
  try:
    let line = await client.recvLine(maxLength = 65536)
    await client.send(reply(line) & "\n")
  except CatchableError:
    discard
  finally:
    client.close()

proc serve(port: Port) {.async.} =
  let listener = newAsyncSocket()
  listener.setSockOpt(OptReuseAddr, true)
  listener.bindAddr(port, "0.0.0.0")
  listener.listen()
  echo "Listening on ", port
  while true:
    let client = await listener.accept()
    asyncCheck handle(client)

proc main() =
  let args = commandLineParams()
  if args.len notin {2, 3}: raise newException(ValueError, "usage: semver server <port> | client <port> <command>")
  let number = parseInt(args[1])
  if number < 1 or number > 65535: raise newException(ValueError, "invalid port")
  if args.len == 2 and args[0] == "server":
    waitFor serve(Port(number))
  elif args.len == 3 and args[0] == "client":
    let client = newSocket()
    defer: client.close()
    client.connect("127.0.0.1", Port(number), timeout = 5000)
    client.send(args[2] & "\n")
    echo client.recvLine(timeout = 5000)
  else:
    raise newException(ValueError, "invalid arguments")

try:
  main()
except CatchableError as error:
  stderr.writeLine("Error: " & error.msg)
  quit(1)
