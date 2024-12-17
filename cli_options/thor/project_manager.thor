#!/usr/bin/env ruby
# project_manager.thor
# Attempting to define module-wide common
# options for --verbose and --debug
#
# Not sure if its working exactly as desired.
# because options are not showing up in the
# usage report.
#

require 'thor'
require 'json'
require 'fileutils'


# Configuration module for global settings
module ConfigurationManager
  @verbose  = false
  @debug    = false

  class << self
    attr_accessor :verbose, :debug

    def verbose?
      @verbose
    end

    def debug?
      @debug
    end
  end
end

CM = ConfigurationManager


module ProjectManager

  # Include this in classes to provide direct access to debug? and verbose?
  module LoggingHelpers
    def debug?    = ConfigurationManager.debug?
    def verbose?  = ConfigurationManager.verbose?
  end


  # Handles project-related commands
  class Project < Thor
    include LoggingHelpers

    desc "create NAME", "Create a new project"
    def create(name)
      log "Creating project: #{name}"
      # Project creation logic here...
    end

    desc "delete NAME", "Delete a project"
    method_option :force, aliases: '-f', type: :boolean, default: false, desc: "Force delete without asking for confirmation"
    def delete(name)
      if options[:force] || yes?("Are you sure you want to delete #{name}? [y/N]", :red)
        log "Deleting project: #{name}"
        # Project deletion logic here...
      end
    end

    desc "list", "List all projects"
    def list
      log "Listing all projects"
      # Project listing logic here...
    end

    no_commands do
      include Thor::Actions

      def log(message)
        puts "INFO: #{message} verbose? #{verbose?} debug? #{debug?}"
        puts "INFO: #{message} CM.verbose? #{CM.verbose?} CM.debug? #{CM.debug?}"
        say_status "project", message, :green if verbose?
        puts "DEBUG: #{message}"              if debug?
      end
    end
  end

  # Handles task-related commands within a project
  class Task < Thor
    include LoggingHelpers

    desc "add NAME", "Add a new task to the current project"
    def add(name)
      log "Adding task: #{name}"
      # Task addition logic here...
    end

    desc "complete NAME", "Mark a task as completed"
    def complete(name)
      log "Completing task: #{name}"
      # Task completion logic here...
    end

    desc "list", "List all tasks in the current project"
    method_option :all, type: :boolean, default: false, desc: "List all tasks, including completed"
    def list
      log "Listing tasks"
      # Task listing logic here...
    end

    no_commands do
      include Thor::Actions

      def log(message)
        say_status "task", message, :yellow if verbose?
        puts "DEBUG: #{message}"            if debug?
      end
    end
  end

  # The main entry point into the CLI
  class Main < Thor
    include LoggingHelpers

    class_option :verbose, type: :boolean, default: false
    class_option :debug, type: :boolean, default: false

    def initialize(*args)
      super
      ConfigurationManager.verbose = options[:verbose]
      ConfigurationManager.debug   = options[:debug]
    end

    desc "project SUBCOMMAND ...ARGS", "Manage projects"
    subcommand "project", Project

    desc "task SUBCOMMAND ...ARGS", "Manage tasks within a project"
    subcommand "task", Task

    no_commands do
      def log(message)
        puts message if verbose?
        puts "DEBUG: #{message}" if debug?
      end
    end
  end
end

ProjectManager::Main.start(ARGV)
