#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
##########################################################
###
##  File: director.rb
##  Desc: Director to orchestrate multiple actors in a scene
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'debug_me'
include DebugMe

require 'yaml'
require 'redis'
require 'smart_message'

# Load message classes
require_relative 'messages/dialog_message'
require_relative 'messages/scene_control_message'
require_relative 'messages/stage_direction_message'
require_relative 'messages/meta_message'

class Director
  attr_reader :scene_info, :actor_processes, :transcript

  # Initialize the Director
  #
  # @param scene_file [String] Path to scene YAML file
  # @param character_dir [String] Directory containing character YAML files (optional, auto-detected)
  def initialize(scene_file:, character_dir: nil)
    @scene_file    = scene_file
    @character_dir = character_dir || detect_character_dir(scene_file)
    @scene_info    = load_scene
    @actor_processes = []
    @transcript    = []
    @running       = false
    @redis         = Redis.new

    debug_me("Director initialized") {
      [@scene_info[:scene_name], @scene_info[:characters].join(', '), @character_dir]
    }
  end

  # Start the scene with all actors
  def action!
    puts "\n" + "=" * 60
    puts "SCENE #{@scene_info[:scene_number]}: #{@scene_info[:scene_name]}"
    puts "Location: #{@scene_info[:location]}"
    puts "Characters: #{@scene_info[:characters].join(', ')}"
    puts "=" * 60 + "\n"

    @running = true

    # Start all actor processes
    start_actors

    # Send start scene control message
    send_control_message('start')

    # Listen to dialog and manage the scene
    monitor_scene

    # Cleanup
    stop_actors
  end

  # Stop the scene and all actors
  def cut!
    @running = false
    send_control_message('stop')
    puts "\n[DIRECTOR: CUT! Scene ended.]"
  end

  # Save the transcript to a file
  #
  # @param filename [String] Output filename
  def save_transcript(filename = nil)
    filename ||= "transcript_scene_#{@scene_info[:scene_number]}_#{Time.now.to_i}.txt"

    File.open(filename, 'w') do |file|
      file.puts "SCENE #{@scene_info[:scene_number]}: #{@scene_info[:scene_name]}"
      file.puts "Location: #{@scene_info[:location]}"
      file.puts "Week: #{@scene_info[:week]}"
      file.puts "\n" + "-" * 60 + "\n"

      @transcript.each do |entry|
        case entry[:type]
        when :dialog
          file.puts "#{entry[:character]}: #{entry[:line]}"
        when :stage_direction
          file.puts "[#{entry[:character].upcase} #{entry[:action]}]"
        when :beat
          file.puts "\n--- #{entry[:content]} ---\n"
        end
      end
    end

    puts "Transcript saved to: #{filename}"
    filename
  end

  # Get scene statistics
  def statistics
    total_lines = @transcript.count { |e| e[:type] == :dialog }
    lines_by_character = @transcript
      .select { |e| e[:type] == :dialog }
      .group_by { |e| e[:character] }
      .transform_values(&:count)

    {
      total_lines: total_lines,
      lines_by_character: lines_by_character,
      duration: @transcript.last&.dig(:timestamp).to_i - @transcript.first&.dig(:timestamp).to_i,
      scene: @scene_info[:scene_number]
    }
  end

  private

  # Auto-detect character directory from scene file path
  # If scene is in projects/PROJECT_NAME/scenes/, look for projects/PROJECT_NAME/characters/
  # Otherwise fall back to 'characters' in current directory
  def detect_character_dir(scene_file)
    scene_path = File.expand_path(scene_file)
    scene_dir = File.dirname(scene_path)

    # Check if scene is in a project structure (projects/PROJECT_NAME/scenes/)
    if scene_dir =~ %r{projects/([^/]+)/scenes}
      project_name = $1
      character_dir = File.join('projects', project_name, 'characters')

      if Dir.exist?(character_dir)
        debug_me("Auto-detected character directory") { character_dir }
        return character_dir
      end
    end

    # Fall back to looking for 'characters' relative to scene directory
    character_dir = File.join(scene_dir, '..', 'characters')
    if Dir.exist?(character_dir)
      debug_me("Found character directory relative to scene") { character_dir }
      return File.expand_path(character_dir)
    end

    # Final fallback
    debug_me("Using default character directory") { 'characters' }
    'characters'
  end

  def load_scene
    unless File.exist?(@scene_file)
      raise "Scene file not found: #{@scene_file}"
    end

    scene = YAML.load_file(@scene_file)

    # Convert string keys to symbols
    scene.transform_keys(&:to_sym)
  end

  def start_actors
    puts "\n[DIRECTOR: Calling actors to the stage...]\n"

    @scene_info[:characters].each do |character_name|
      character_file = File.join(@character_dir, "#{character_name.downcase}.yml")

      unless File.exist?(character_file)
        puts "Warning: Character file not found: #{character_file}"
        next
      end

      puts "  - #{character_name} is taking their position..."

      # Spawn actor process
      pid = spawn(
        "ruby", "actor.rb",
        "-c", character_file,
        "-s", @scene_file,
        out: "logs/#{character_name.downcase}_#{Time.now.to_i}.log",
        err: "logs/#{character_name.downcase}_#{Time.now.to_i}_err.log"
      )

      @actor_processes << { name: character_name, pid: pid }

      # Give actors time to initialize
      sleep 0.5
    end

    puts "\n[DIRECTOR: All actors ready!]\n"
    sleep 1  # Give them time to subscribe to channels
  end

  def stop_actors
    puts "\n[DIRECTOR: Dismissing actors...]\n"

    @actor_processes.each do |actor|
      begin
        Process.kill('INT', actor[:pid])
        Process.wait(actor[:pid])
        puts "  - #{actor[:name]} has left the stage"
      rescue Errno::ESRCH
        # Process already ended
      end
    end

    @actor_processes.clear
  end

  def send_control_message(command)
    message = case command
    when 'start'
      SceneControlMessage.start_scene(@scene_info[:scene_number])
    when 'stop'
      SceneControlMessage.stop_scene(@scene_info[:scene_number])
    when 'end'
      SceneControlMessage.end_scene(@scene_info[:scene_number])
    else
      return
    end

    message.publish
    debug_me("Sent control message: #{command}")
  end

  def monitor_scene
    puts "\n[SCENE BEGINS]\n\n"

    line_count = 0
    max_lines  = ENV['MAX_LINES']&.to_i || 50  # Default to 50 lines

    # Subscribe to dialog messages
    DialogMessage.subscribe('writers_room:dialog') do |message|
      break unless @running
      break if line_count >= max_lines

      # Only show messages for this scene
      next unless message.scene == @scene_info[:scene_number]

      # Record in transcript
      @transcript << {
        type: :dialog,
        character: message.from,
        line: message.content,
        timestamp: message.timestamp,
        emotion: message.emotion
      }

      # Display dialog
      emotion_tag = message.emotion ? " [#{message.emotion}]" : ""
      puts "#{message.from}#{emotion_tag}: #{message.content}"

      line_count += 1

      # Check if we should end the scene
      if line_count >= max_lines
        puts "\n[DIRECTOR: Maximum lines reached]"
        cut!
      end
    end
  end
end

##########################################################
# Main execution when run as a script

if __FILE__ == $PROGRAM_NAME
  require 'optparse'
  require 'fileutils'

  options = {
    scene_file: nil,
    character_dir: nil,  # Auto-detect from scene path
    output: nil,
    max_lines: 50
  }

  OptionParser.new do |opts|
    opts.banner = "Usage: director.rb [options]"

    opts.on("-s", "--scene FILE", "Scene YAML file (required)") do |file|
      options[:scene_file] = file
    end

    opts.on("-c", "--characters DIR", "Character directory (auto-detected if not specified)") do |dir|
      options[:character_dir] = dir
    end

    opts.on("-o", "--output FILE", "Transcript output file") do |file|
      options[:output] = file
    end

    opts.on("-l", "--max-lines N", Integer, "Maximum lines before ending (default: 50)") do |n|
      options[:max_lines] = n
    end

    opts.on("-h", "--help", "Show this help") do
      puts opts
      exit
    end
  end.parse!

  # Validate required options
  unless options[:scene_file] && File.exist?(options[:scene_file])
    puts "Error: Scene file required and must exist"
    puts "Usage: director.rb -s scene.yml"
    exit 1
  end

  # Set max lines environment variable for monitoring
  ENV['MAX_LINES'] = options[:max_lines].to_s

  # Create logs directory if it doesn't exist
  FileUtils.mkdir_p('logs')

  # Create and run director
  director = Director.new(
    scene_file: options[:scene_file],
    character_dir: options[:character_dir]
  )

  # Handle graceful shutdown
  trap('INT') do
    puts "\n[DIRECTOR: Interrupt received]"
    director.cut!

    # Save transcript
    filename = director.save_transcript(options[:output])

    # Show statistics
    stats = director.statistics
    puts "\n" + "=" * 60
    puts "SCENE STATISTICS"
    puts "=" * 60
    puts "Total lines: #{stats[:total_lines]}"
    puts "\nLines by character:"
    stats[:lines_by_character].sort_by { |_, count| -count }.each do |char, count|
      puts "  #{char}: #{count}"
    end
    puts "=" * 60

    exit 0
  end

  # Start the scene
  director.action!

  # Save transcript when done
  filename = director.save_transcript(options[:output])

  # Show statistics
  stats = director.statistics
  puts "\n" + "=" * 60
  puts "SCENE STATISTICS"
  puts "=" * 60
  puts "Total lines: #{stats[:total_lines]}"
  puts "\nLines by character:"
  stats[:lines_by_character].sort_by { |_, count| -count }.each do |char, count|
    puts "  #{char}: #{count}"
  end
  puts "=" * 60
end
