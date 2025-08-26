# common/status_line.rb
# Protects the bottom line of the terminal for current status

module Common
  module StatusLine
    def self.included(base)
      base.class_eval do
        # Prepend a module to hook into initialize
        prepend Module.new {
          def initialize(...)
            super(...)
            initialize_status_line if respond_to?(:initialize_status_line, true)
          end
        }
      end

      # Register a single at_exit handler for the class
      at_exit do
        begin
          if $stdout.tty?
            rows, _ = IO.popen("stty size", "r") { |io| io.read.split.map(&:to_i) }
            print "\033[1;#{rows}r"
            print "\033[#{rows};1H\033[K"
            $stdout.flush
          end
        rescue => e
          # Silently ignore terminal cleanup errors
        end
      end
    end

    def initialize_status_line
      return unless $stdout.tty?

      begin
        @terminal_rows, @terminal_columns = get_terminal_size
        @program_name = File.basename($0, ".*")

        if @terminal_rows && @terminal_columns
          # Set up scrolling region (leave bottom line for status)
          print "\033[1;#{@terminal_rows - 1}r"
          # Clear screen and position cursor at top
          print "\033[2J\033[H"
          # Set default status line to program basename
          status_line('started')
          $stdout.flush
        end
      rescue => e
        # If terminal operations fail, continue without status line
        @terminal_rows = nil
        @terminal_columns = nil
      end
    end

    def status_line(text)
      return unless @terminal_rows && @terminal_columns && $stdout.tty?

      begin
        # Save current cursor position
        print "\033[s"
        # Move to the last line
        print "\033[#{@terminal_rows};1H"
        # Clear the line
        print "\033[K"

        # Build the full status line
        full_text  = "#{@program_name}: "
        full_text += "#{@status_line_prefix}: " if @status_line_prefix
        full_text += "#{text}"

        # Truncate from the right if too long, but preserve the program name
        if full_text.length >= @terminal_columns
          max_text_length = @terminal_columns - @program_name.length - 3 # -3 for ": "
          if max_text_length > 10 # Ensure we have reasonable space for status
            truncated_text = text[0...max_text_length - 1] + "…"
            full_text = "#{@program_name}: #{truncated_text}"
          else
            # Terminal too narrow, just show program name
            full_text = @program_name[0...@terminal_columns - 1]
          end
        end

        # Print the text, padding to terminal width
        print full_text.ljust(@terminal_columns - 1)
        # Restore cursor position
        print "\033[u"
        $stdout.flush
      rescue => e
        # Silently ignore status line update errors
      end
    end

    def restore_terminal
      return unless @terminal_rows && $stdout.tty?

      begin
        # Reset scrolling region to full screen
        print "\033[1;#{@terminal_rows}r"
        # Clear the status line
        print "\033[#{@terminal_rows};1H\033[K"
        $stdout.flush
      rescue => e
        # Silently ignore terminal restore errors
      end
    end

    private

    def get_terminal_size
      rows, columns = IO.popen("stty size", "r") { |io| io.read.split.map(&:to_i) }
      return rows, columns
    rescue => e
      # Return nil if we can't get terminal size
      return nil, nil
    end
  end
end
