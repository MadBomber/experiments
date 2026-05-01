#!/usr/bin/env ruby

class MadBomberCelebration
  def initialize
    @width = 80
    @height = 20
  end

  def run
    # Sequence: fireworks -> madbomber -> grand_finale (wipes out madbomber) -> madbomber -> explosion
    fireworks
    sleep 0.5
    
    # First MADBOMBER - stays on screen
    display_madbomber
    sleep 2
    
    # Grand finale that slowly wipes out the MADBOMBER
    grand_finale_wipe
    
    # Display MADBOMBER again
    display_madbomber
    sleep 1
    
    # Final explosion effect that wipes out MADBOMBER
    madbomber_explosion
    
    puts "\n\n"
  end

  private

  def clear_screen
    print "\e[2J\e[H"
  end

  def fireworks
    clear_screen
    puts "\n" * 3
    puts " " * 30 + "🎆 FIREWORKS! 🎆"
    sleep 0.5
    
    8.times do
      x = rand(10..70)
      y = @height - 2
      
      # Launch
      y.downto(rand(3..10)) do |launch_y|
        print "\e[#{launch_y};#{x}H|"
        sleep 0.05
        print "\e[#{launch_y};#{x}H "
      end
      
      # Explosion
      explosion_y = rand(3..10)
      chars = ['*', '✦', '✨', '💥']
      3.times do |radius|
        (-radius..radius).each do |dy|
          (-radius..radius).each do |dx|
            if Math.sqrt(dx*dx + dy*dy) <= radius
              px = x + dx
              py = explosion_y + dy
              if px > 0 && px < @width && py > 0 && py < @height
                print "\e[#{py};#{px}H#{chars.sample}"
              end
            end
          end
        end
        sleep 0.1
      end
      sleep 0.2
      clear_screen
    end
  end

  def display_madbomber
    clear_screen
    
    # ASCII art for MADBOMBER
    madbomber = [
      "███╗   ███╗ █████╗ ██████╗ ██████╗  ██████╗ ███╗   ███╗██████╗ ███████╗██████╗ ",
      "████╗ ████║██╔══██╗██╔══██╗██╔══██╗██╔═══██╗████╗ ████║██╔══██╗██╔════╝██╔══██╗",
      "██╔████╔██║███████║██║  ██║██████╔╝██║   ██║██╔████╔██║██████╔╝█████╗  ██████╔╝",
      "██║╚██╔╝██║██╔══██║██║  ██║██╔══██╗██║   ██║██║╚██╔╝██║██╔══██╗██╔══╝  ██╔══██╗",
      "██║ ╚═╝ ██║██║  ██║██████╔╝██████╔╝╚██████╔╝██║ ╚═╝ ██║██████╔╝███████╗██║  ██║",
      "╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝"
    ]
    
    # Center and display
    start_y = 8
    madbomber.each_with_index do |line, i|
      # Center horizontally
      padding = [(@width - line.length) / 2, 0].max
      print "\e[#{start_y + i};#{padding}H\e[31m#{line}\e[0m"
    end
    
    # Add bomb emoji decoration
    print "\e[#{start_y - 1};#{@width/2 - 5}H💣 💣 💣"
    print "\e[#{start_y + 7};#{@width/2 - 5}H💣 💣 💣"
    
    STDOUT.flush
  end

  def grand_finale_wipe
    # Grand finale that slowly wipes out MADBOMBER from multiple directions
    wipe_chars = ['✨', '🌟', '⭐', '✦', '★', '☆', '✧']
    colors = [33, 36, 35, 32, 34] # Yellow, Cyan, Magenta, Green, Blue
    
    # Store current screen state (we'll progressively overwrite it)
    15.times do |frame|
      # Wave effect from left to right
      wave_x = (frame * 6)
      
      # Top to bottom cascade
      cascade_y = frame
      
      # Diagonal wipe
      (0..@height).each do |y|
        (0..@width).each do |x|
          # Create multiple wipe patterns
          if x < wave_x || y < cascade_y || (x + y) < (frame * 8)
            if rand(100) < 70 # 70% chance to place a character
              char = wipe_chars.sample
              color = colors.sample
              print "\e[#{y};#{x}H\e[#{color}m#{char}\e[0m"
            end
          end
        end
      end
      
      # Add some sparkle text in the middle
      if frame == 7
        text = "✨ GRAND FINALE ✨"
        print "\e[12;#{(@width - text.length) / 2}H\e[1;33m#{text}\e[0m"
      end
      
      sleep 0.3
      STDOUT.flush
    end
    
    # Final burst to completely clear
    clear_screen
    50.times do
      x = rand(0..@width)
      y = rand(0..@height)
      char = wipe_chars.sample
      color = colors.sample
      print "\e[#{y};#{x}H\e[#{color}m#{char}\e[0m"
    end
    sleep 0.5
    clear_screen
  end

  def madbomber_explosion
    # The MADBOMBER text explodes outward
    sleep 0.5
    
    # Create explosion effect from center
    center_x = @width / 2
    center_y = 10
    
    explosion_frames = [
      { radius: 2, chars: ['💥', '💣'], delay: 0.1 },
      { radius: 4, chars: ['*', '✦', '💥'], delay: 0.1 },
      { radius: 8, chars: ['·', '∘', '*', '✨'], delay: 0.15 },
      { radius: 12, chars: ['·', '.', '∘'], delay: 0.2 },
      { radius: 20, chars: ['.', ' ', '·'], delay: 0.25 }
    ]
    
    explosion_frames.each do |frame|
      clear_screen
      
      # Draw explosion ring
      (0..@height).each do |y|
        (0..@width).each do |x|
          distance = Math.sqrt((x - center_x)**2 + (y - center_y)**2)
          if distance <= frame[:radius] && distance >= frame[:radius] - 3
            if rand(100) < 60 # 60% density
              char = frame[:chars].sample
              color = [31, 33, 37].sample # Red, Yellow, White
              print "\e[#{y};#{x}H\e[#{color}m#{char}\e[0m"
            end
          end
        end
      end
      
      # Add "BOOM!" text in the center for first frame
      if frame[:radius] == 2
        boom_text = "💥 BOOM! 💥"
        print "\e[#{center_y};#{center_x - 5}H\e[1;31m#{boom_text}\e[0m"
      end
      
      STDOUT.flush
      sleep frame[:delay]
    end
    
    # Final fade out
    3.times do |i|
      (0..@height).each do |y|
        (0..@width).each do |x|
          if rand(100) < (30 - i * 10)
            print "\e[#{y};#{x}H."
          end
        end
      end
      sleep 0.2
    end
    
    clear_screen
    
    # Final message
    final_msg = "💣 MADBOMBER 💣"
    print "\e[#{@height/2};#{(@width - final_msg.length)/2}H\e[31m#{final_msg}\e[0m"
    sleep 1
  end
end

# Run the celebration if called directly
if __FILE__ == $0
  celebration = MadBomberCelebration.new
  celebration.run
end