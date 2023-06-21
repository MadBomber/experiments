# TRANSLATES ALL PYTHON AND PERL INTO RUBY
#    ruby pypl2rb.rb <directory>
#
# See: https://gist.github.com/basicfeatures/288b6a20a610975a8cabba6e0ccbcab6
#

require "openai"
require "find"

Openai.configuration.api_key = ENV["OPENAI_API_KEY"]

def translate_code_to_ruby(code, language)
  begin
    response = Openai::Completion.create(
      engine: "text-davinci-003",
      prompt: "#{code}\n\n# #{language} equivalent in Ruby:",
      temperature: 0.5,
      max_tokens: 500
    )
    response.choices.first.text.strip
  rescue => e
    puts "Error during translation: #{e.message}"
    nil
  end
end

def process_files(path)
  Find.find(path) do |filename|
    next unless File.file?(filename)
    if File.extname(filename) == ".py"
      language = "Python"
    elsif File.extname(filename) == ".pl"
      language = "Perl"
    else
      next
    end
    code = File.read(filename)
    ruby_code = translate_code_to_ruby(code, language)
    if ruby_code
      new_filename = filename.sub(/\.(py|pl)$/, ".rb")
      File.write(new_filename, ruby_code)
    end
  end
end

# Use the first command line argument as the directory to process
if ARGV.length > 0
  process_files(ARGV[0])
else
  puts "Please provide a directory as an argument."
end

