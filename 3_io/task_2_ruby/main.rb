BLOCK_SIZE = 64 * 1024

def first_difference(left, right)
  offset = 0
  loop do
    left_block = left.read(BLOCK_SIZE) || ''.b
    right_block = right.read(BLOCK_SIZE) || ''.b
    if left_block != right_block
      common_size = [left_block.bytesize, right_block.bytesize].min
      index = 0
      index += 1 while index < common_size && left_block.getbyte(index) == right_block.getbyte(index)
      return offset + index
    end
    return nil if left_block.empty?

    offset += left_block.bytesize
  end
end

def run(arguments)
  raise ArgumentError, 'usage: ruby main.rb <first> <second>' unless arguments.length == 2

  File.open(arguments[0], 'rb') do |left|
    File.open(arguments[1], 'rb') do |right|
      raise ArgumentError, 'expected regular files' unless left.stat.file? && right.stat.file?

      offset = first_difference(left, right)
      if offset.nil?
        puts "Identical (#{left.stat.size} bytes)"
        return 0
      end

      puts "First difference at byte #{offset} (0-based)"
      puts "Sizes: #{left.stat.size} and #{right.stat.size} bytes"
      return 1
    end
  end
end

begin
  exit run(ARGV)
rescue ArgumentError, SystemCallError, IOError => error
  warn "Error: #{error.message}"
  exit 2
end
