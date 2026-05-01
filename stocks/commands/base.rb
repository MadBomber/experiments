# .../sqa/cli/commands/base.rb

# SQA.config will be built with its defaults
# and envar over-rides BEFORE a command is
# process.  This means that options do not
# need to have a "default" value.

# Establish a Base command class that has global options
# available to all commands.

class Commands::Base < Dry::CLI::Command
  # keys from Dry::Cli options which we do not want in the
  # config object.
  IGNORE_OPTIONS = %i[ version ]

  global_header <<~EOS

    SQA - Stock Quantitative Analysis
    by: MadBomber

    This is a work in progress.  It is not fit for anything
    other than play time.  ** Do not ** use it to make any
    kind of serious trading decisions.

  EOS

  global_footer <<~EOS

    SARNING: This product is a work in progress.  DO NOT USE
    for serious trading decisions.

    Copyright (c) 2023 - MadBomber Software

  EOS

  option :debug,
    required: false,
    type:     :boolean,
    desc:     'Print debug information',
    aliases:  %w[-d --debug]

  option :verbose,
    required: false,
    type:     :boolean,
    desc:     'Print verbose information',
    aliases:  %w[-v --verbose]


  option :version,
    required: false,
    type:     :boolean,
    default:  false,
    desc:     'Print version(s) and exit',
    aliases:  %w[--version]


  option :config_file,
    required: false,
    type:     :string,
    desc:     "Path to the config file"


  option :log_level,
    required: false,
    type:     :string,
    values:   %w[debug info warn error fatal ],
    desc:     "Set the log level"


  option :portfolio,
    required: false,
    aliases:  %w[ --portfolio --folio --file -f ],
    type:     :string,
    desc:     "Set the filename of the portfolio"


  option :trades,
    required: false,
    aliases:  %w[ --trades ],
    type:     :string,
    desc:     "Set the filename into which trades are stored"


  option :data_dir,
    required: false,
    aliases:  %w[ --data-dir --data --dir ],
    type:     :string,
    desc:     "Set the directory for the SQA data"


  option :dump_config,
    required: false,
    type:     :string,
    desc:     "Dump the current configuration to a file"


  # All command class call methods should start with
  # super so that this method is invoked.
  #
  # params is a Hash from Dry::CLI where keys are Symbol

  def call(params)
    show_versions_and_exit if params[:version]

    unless params[:config_file].nil? || params[:config_file].empty?
      SQA.config.config_file = params[:config_file]
      SQA.config.from_file
    end

    update_config(params)

    unless params[:dump_config].nil? || params[:dump_config].empty?
      SQA.config.config_file = params[:dump_config]
      SQA.config.dump_file
    end

    SQA.config
  end

  ################################################
  private

  def show_versions_and_exit
    self.class.ancestors.each do |ancestor|
      next unless ancestor.const_defined?(:VERSION)
      puts "#{ancestor}: #{ancestor::VERSION}"
    end

    puts "SQA: #{SQA::VERSION}" if SQA.const_defined?(:VERSION)

    exit(0)
  end

  def update_config(params)
    SQA.config.inject_additional_properties
    my_hash = params.reject { |key, _| IGNORE_OPTIONS.include?(key) }
    SQA.config.merge!(my_hash)
  end
end
