# experiments/smart_message/named_pipes/reader.rb
# Setup (one time)
`mkfifo /tmp/myfifo`

# Non-blocking reader (reader_nb.rb)
path = '/tmp/myfifo'

unless File.exist?(path) && File.pipe?(path)
  STDERR.puts "FIFO not found at #{path}. Create it with: mkfifo #{path}"
  exit 1
end

def open_fifo_reader(path)
  fd = IO.sysopen(path, File::RDONLY | File::NONBLOCK)
  IO.new(fd)
end

io = open_fifo_reader(path)
buffer = +''
puts "Reader: waiting for writers and data on #{path}..."

loop do
  begin
    io.wait_readable  # sleeps until data (or EOF) is ready
    data = io.read_nonblock(4096)  # may raise EOFError if writer closed
    buffer << data

    # Emit complete lines
    while (idx = buffer.index("\n"))
      line = buffer.slice!(0, idx+1)
      puts "Reader got: #{line.chomp}"
    end
  rescue IO::WaitReadable, Errno::EAGAIN, Errno::EWOULDBLOCK
    # No data yet; loop back and wait
    next
  rescue EOFError
    # Writer disconnected. Reopen to wait for the next writer.
    io.close rescue nil
    sleep 0.1
    io = open_fifo_reader(path)
  end
end

io.close
puts "Reader done"
