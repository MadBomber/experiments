#!/usr/bin/env ruby
require 'optparse'
require 'json'
require 'openai'
require 'sqlite3'
require 'sqlite_vss'
require 'find'
require 'ruby-progressbar' # Add this require statement at the top with the others

class EmbeddingStore
  def initialize(filename)
    setup_database(filename)
    @openai = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def store_with_progress(files)
    progressbar = ProgressBar.create(title: "Indexing", total: files.length, format: '%a |%b>>%i| %p%% %t')
    files.each do |file|
      content = File.read(file)
      embeddings = get_embeddings(content)
      store(content, embeddings[0]) if embeddings && !embeddings.empty?
      progressbar.increment
    end
    reindex
  end

  def recreate_database
    @db.execute("DROP TABLE IF EXISTS docs")
    @db.execute("DROP TABLE IF EXISTS vss_docs")
    setup_database(@db.filename)
  end

  def get_embeddings(texts)
    texts = Array(texts)
    res = @openai.embeddings(parameters: { model: "text-embedding-ada-002", input: texts })
    res['data'].map { |r| r['embedding'] }
  end

  def store(text, embedding)
    @db.execute("INSERT INTO docs (doc, e) VALUES (?, ?) ON CONFLICT(doc) DO UPDATE SET e=excluded.e", [text, embedding.to_json])
  end

  def reindex
    @db.execute("DELETE FROM vss_docs")
    @db.execute("INSERT INTO vss_docs (rowid, e) SELECT rowid, e FROM docs")
  end

  def search(query)
    query_embedding = get_embeddings(query).first.to_json
    @db.execute("
      WITH matches AS (
        SELECT rowid, distance
        FROM vss_docs
        WHERE vss_search(
          e, vss_search_params(?, 2)
        )
      )
      SELECT
        docs.doc, matches.distance
      FROM matches
      LEFT JOIN docs ON docs.rowid = matches.rowid", [query_embedding])
  end

  private

  def setup_database(filename)
    @db = SQLite3::Database.new(filename)
    @db.results_as_hash = true
    @db.enable_load_extension(true)
    SqliteVss.load(@db)
    @db.enable_load_extension(false)

    @db.execute("CREATE TABLE IF NOT EXISTS docs (doc TEXT, e BLOB)")
    @db.execute("CREATE UNIQUE INDEX IF NOT EXISTS docs_doc ON docs(doc)")
    @db.execute("CREATE VIRTUAL TABLE IF NOT EXISTS vss_docs USING vss0( e(1536) )")
  end
end

class FileManager
  def self.find_text_files(directory)
    text_files = []
    Find.find(directory) { |path| text_files << path if path =~ /.*\.(txt|md|rb)$/ }
    text_files
  end
end

class CLIParser
  def self.parse(options)
    OptionParser.new do |opts|
      opts.banner = "Usage: embedding_store.rb [options]"

      opts.on("-dNAME", "--database=NAME", "Database name") { |d| options[:database] = d }
      opts.on("-pPATH", "--path=PATH", "Top-level directory path") { |p| options[:path] = p }
      opts.on("--init", "Reinitialize the database") { options[:init] = true }
    end.parse!

    check_path_options(options)
  end

  def self.check_path_options(options)
    if options[:path] && !(Dir.exist?(options[:path]))
      abort "Error: Specified path does not exist or is not a directory."
    end
    
    if options[:init] && options[:path].nil?
      abort "Error: --path option is required with --init."
    end
  end
end

options = {}
CLIParser.parse(options)

# Check for database name
abort "Error: database name is required" unless options[:database]

# Check for the existence of the database unless --init is specified
unless File.exist?(options[:database]) || options[:init]
  abort "Error: The specified database does not exist. Use --init to reinitialize."
end

es = EmbeddingStore.new(options[:database])

# Handle --init option and indexing if a path is given

if options[:init]
  puts "Reinitializing database..."
  es.recreate_database
  if options[:path]
    files = FileManager.find_text_files(options[:path])
    es.store_with_progress(files)  # Use the new method with progress bar
  end
end



# Interactive search prompt
puts "Ready. Type your search query or 'exit' to quit:"
loop do
  print "> "
  query = gets.strip
  break if query.downcase == 'exit'

  puts "Searching for: #{query}"
  results = es.search(query)
  if results.count > 0
    results.each { |r| puts "#{r['doc']} (distance: #{r['distance']})" }
  else
    puts "No results found."
  end
  puts "-----"
end


