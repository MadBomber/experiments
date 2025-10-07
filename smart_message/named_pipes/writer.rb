# experiments/smart_message/named_pipes/writer.rb

# Non-blocking writer (writer_nb.rb)
path = '/tmp/myfifo'

unless File.exist?(path) && File.pipe?(path)
  system('mkfifo', path) or abort "Couldn't create FIFO at #{path}"
end

def open_fifo_writer(path)
  loop do
    begin
      fd = IO.sysopen(path, File::WRONLY | File::NONBLOCK)
      return IO.new(fd)
    rescue Errno::ENXIO
      # No reader is connected yet; retry shortly.
      sleep 0.1
    end
  end
end

io = open_fifo_writer(path)
puts "Writer: connected to #{path}"

messages = 5.times.map { |i| "hello #{i} (#{Time.now})\n" }

messages.each do |msg|
  offset = 0
  while offset < msg.bytesize
    begin
      n = io.write_nonblock(msg.byteslice(offset, msg.bytesize - offset))
      offset += n
    rescue IO::WaitWritable, Errno::EAGAIN, Errno::EWOULDBLOCK
      io.wait_writable
    rescue Errno::EPIPE
      # Reader disappeared; reopen and continue.
      io.close rescue nil
      io = open_fifo_writer(path)
    end
  end
  sleep 1
end

io.close
puts "Writer done"
