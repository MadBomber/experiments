require 'json'
require 'rethinkdb'
include RethinkDB::Shortcuts

require 'nobrainer'

$conn = r.connect(:host => 'localhost', :port => 28015).repl
$conn.use('test') # use the default database

$db_list = r.db_list.run

table_list = r.table_list.run

r.create_table('meditations').run unless table_list.include?('meditations')

M = r.table('meditations')

def json_file_to_hash(a_filename)
  a_hash = Hash.new
  File.open(a_filename,'r') do |f|
    a_hash = JSON.parse f.read
  end
  return a_hash
end # def json_file_to_hash(a_filename)

def load_json_files(a_dirpath)
  a_dirpath.children.each do |c|
    next unless '.json' == c.extname
    M.insert(JSON.parse(c.read)).run
  end
end

def load_json_file(a_filepath)
  M.insert(JSON.parse(a_filepath.read)).run
end

def get_pathnames_from(an_array, extnames=['.json', '.txt', '.docx'])
  an_array = [an_array] unless an_array.is_a? Array
  extnames = [extnames] unless extnames.is_a? Array
  extnames = extnames.map{|e| e.downcase}
  file_array = []
  an_array.each do |a|
    pfn = Pathname.new(a)
    if pfn.directory?
      file_array << get_pathnames_from(pfn.children, extnames)
    else
      file_array << pfn if pfn.exist? && extnames.include?(pfn.extname.downcase)
    end
  end
  return file_array.flatten
end # def get_pathnames_from(an_array, extname='.json')

puts <<EOS
# Interesting ReQL statements
# M.group{|m| m[:submission_author][:gender]}.count.run
# M.group{|m| m[:submission_author][:honorific]}.count.run
# M.group(:theme).count.run
#
# M.filter{|m| m[:submission_author][:email_address].match('dvanhoozer')}.delete.run
# M.filter{|m| m[:body_text].match('love')}.run
# M.filter{|m| m[:submission_author:][:honorific].match('Mrs.')}.run
# M.filter{|m| m[:citation].match('(?i)psalms')}.count.run
#
# test_words; nil
#
#
EOS

def test_words

  words = M.group{|m| m[:citation].match('(?i)^(\w)+')}.count.run

  a_hash = Hash.new

  words.each_pair do |k,v|
    next unless k.is_a? Hash
    w = k['str']
    a_hash[ k['str'] ] = v
  end

  return a_hash
end # test




