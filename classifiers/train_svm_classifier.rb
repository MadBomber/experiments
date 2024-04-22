#!/usr/bin/env ruby
######################################################################
###
##  File: train_svm_classifier.rb
##  Desc: Train a classifier for the current directory.
##
##  Makes use of the following common *nix pgms:
##    html2text
##    pdf2txt
##    catdoc
##    strings
#

puts "gem hoatzin is a problem"
raise "Outdated!"

#require 'bag_of_words'
require 'amazing_print'

require 'pathname'  # STDLIB
require 'hoatzin'   # GEM that implements an SVM-based classifier
#require 'summary'   # GEM that summarizes a document
require 'pp'        # STDLIB

stored_classifier_name  = 'classifier'
scn_metadata            = stored_classifier_name + '.metadata'
scn_model               = stored_classifier_name + '.model'

$stop_words = %w(
  able about above abroad according accordingly across actually adj after afterwards again
  against ago ahead ain't all allow allows almost alone along alongside already also although
  always am amid amidst among amongst an and another any anybody anyhow anyone anything anyway
  anyways anywhere apart appear appreciate appropriate are aren't around as a's aside ask asking
  associated at available away awfully back backward backwards be became because become becomes
  becoming been before beforehand begin behind being believe below beside besides best better
  between beyond both brief but by came can cannot cant can't caption cause causes certain
  certainly changes cid clearly c'mon co co. com come comes concerning consequently consider
  considering contain containing contains corresponding could couldn't course c's currently
  dare daren't definitely described despite did didn't different directly do does doesn't
  doing done don't down downwards during each edu eg eight eighty either else elsewhere
  end ending enough entirely especially et etc even ever evermore every everybody everyone
  everything everywhere ex exactly example except fairly far farther few fewer fifth first
  five followed following follows for forever former formerly forth forward found four from
  further furthermore get gets getting given gives go goes going gone got gotten greetings
  had hadn't half happens hardly has hasn't have haven't having he he'd he'll hello help
  hence her here hereafter hereby herein here's hereupon hers herself he's hi him himself
  his hither hopefully how howbeit however hundred i'd ie if ignored i'll i'm immediate in
  inasmuch inc inc. indeed indicate indicated indicates inner inside insofar instead into
  inward is isn't it it'd it'll its it's itself i've just k keep keeps kept know known
  knows last lately later latter latterly least less lest let let's like liked likely likewise
  little look looking looks low lower ltd made mainly make makes many may maybe mayn't me
  mean meantime meanwhile merely might mightn't mine minus miss more moreover most mostly mr
  mrs much must mustn't my myself name namely nd near nearly necessary need needn't needs
  neither never neverf neverless nevertheless new next nine ninety no nobody non none nonetheless
  noone no-one nor normally not nothing notwithstanding novel now nowhere obviously of off
  often oh ok okay old on once one ones one's only onto opposite or other others otherwise
  ought oughtn't our ours ourselves out outside over overall own particular particularly past
  per perhaps placed please plus possible presumably probably provided provides que quite qv
  rather rd re really reasonably recent recently regarding regardless regards relatively
  respectively right round said same saw say saying says second secondly see seeing seem
  seemed seeming seems seen self selves sensible sent serious seriously seven several shall
  shan't she she'd she'll she's should shouldn't since six so some somebody someday somehow
  someone something sometime sometimes somewhat somewhere soon sorry specified specify
  specifying still sub such sup sure take taken taking tell tends th than thank thanks
  thanx that that'll thats that's that've the their theirs them themselves then thence
  there thereafter thereby there'd therefore therein there'll there're theres there's
  thereupon there've these they they'd they'll they're they've thing things think third
  thirty this thorough thoroughly those though three through throughout thru thus till
  to together too took toward towards tried tries truly try trying t's twice two un
  under underneath undoing unfortunately unless unlike unlikely until unto up upon
  upwards us use used useful uses using usually v value various versus very via viz
  vs want wants was wasn't way we we'd welcome well we'll went were we're weren't we've
  what whatever what'll what's what've when whence whenever where whereafter whereas
  whereby wherein where's whereupon wherever whether which whichever while whilst whither
  who who'd whoever whole who'll whom whomever who's whose why will willing wish with
  within without wonder won't would wouldn't yes yet you you'd you'll your you're
  yours yourself yourselves you've zero
  software system project manager managers
  microsoft word document
  ion
)



def keywords(string_of_words)

  words = Hash.new

  string_of_words.split.each do |w|
    if words[w].nil?
      words[w] = 1
    else
      words[w] += 1
    end
  end

  cutoff = words.values.max.to_f / 4.0

  return words.select {|k,v| v >= cutoff}.keys

end


class Pathname
  def is_archive?
    case extname.downcase
      when '.bz2', '.tgz', '.gz', '.tar', '.zip' then
        true
      else
        false
    end
  end
end


class String
  def remove_stop_words
    self.split(" ").select{|w| 2<w.length and !$stop_words.include?(w)}.join(" ")
  end
  def remove_stuff(seq="\n")
    self.gsub(seq, ' ').gsub(/[^a-z]/, ' ').strip.squeeze(" ").remove_stop_words
  end
end # class String



def summarize_file(a_path)
  #GC::start
  puts
  puts "   File: #{a_path.basename.to_s}"
  ext       = a_path.extname.downcase
  title     = a_path.basename.to_s.downcase.remove_stuff(ext)
  puts "  Title: #{title}"

  summary   = title + " "

  case ext
    when '.html', '.htm' then
      text = `html2text '#{a_path.to_s}'`
      summary += text.downcase.remove_stuff      # .summary(1500, " ")
      summary = keywords(summary).join(', ')

    when '.pdf' then
      text = `pdf2txt '#{a_path.to_s}'`
      summary += text.downcase.remove_stuff      # .summary(1500, " ")
      summary = keywords(summary).join(', ')

    when '.doc', '.docx' then
      text = `catdoc '#{a_path.to_s}'`
      summary += text.gsub(/[^a-zA-Z]/,' ').downcase.remove_stuff     # .summary(1500, " ")
      summary = keywords(summary).join(', ')

    when '.txt' then
      text = a_path.read
      summary += text.downcase.remove_stuff     # .summary(1500, " ")
      summary = keywords(summary).join(', ')

    else
      text = `strings '#{a_path.to_s}'`
      summary += text.downcase.remove_stuff     # .summary(1500, " ")
      summary = keywords(summary).join(', ')
  end # end case ext

  puts "Summary: #{summary}"

  return summary
end # end of def summarize_file(a_path)

# The top-level directory holding both sub-directories of
# already classified files and at the top level, files which
# not yet been classified.

cwd               = Pathname.pwd + 'training_data'
scn_metadata_path = cwd + scn_metadata
scn_model_path    = cwd + scn_model

# Get the sub-directories
# establish the category_hash
category_hash = Hash.new

cwd.children.select{|c| c if c.directory?}.each do |dir|
  category                = dir.basename.to_s.downcase
  category_hash[category] = dir
end


puts "Train a classifier (#{category_hash.keys}) for this directory: #{cwd}"

# These are files which have not been categorized
files_without_category = cwd.children.select do |c|
  c if c.file?  &&
       '.model'    != c.extname.to_s.downcase &&
       '.metadata' != c.extname.to_s.downcase
end

if scn_metadata_path.exist?
  classifier = Hoatzin::Classifier.new( :metadata => scn_metadata_path.to_s,
                                        :model    => scn_model_path.to_s)
else
  classifier = Hoatzin::Classifier.new()
end


category_hash.each_pair do | category, dir |

  puts "-" * 45

  classifier.train category, category.remove_stuff

  puts "Training #{category} ..."


  dir.children.each do |f|

#    bag = BagOfWords.new

    unless f.directory?
      summary = summarize_file(f)
      unless summary.empty?
#        bag.add_doc summary
        classifier.train category, summary
      end
    end

#    ap bag

  end

end




# Force the calculation of the feature vectors and
# preparation of the SVM model.  This can take some
# time if the corpus is large
classifier.sync


classifier.save(  :metadata => scn_metadata_path.to_s,
                  :model    => scn_model_path.to_s,
                  :update   => true)


puts
puts "=" * 45

files_without_category.each do |f|

  next if f.extname.to_s == '.metadata'
  next if f.extname.to_s == '.model'
  
  summary = summarize_file(f)

  category  = classifier.classify summary
  puts
  puts "Category: #{category}"
  puts
  print "Do you want to move the file? (no) "
  answer = gets.strip.downcase
  if !answer.empty? && 'y' == answer[0]
    system "mv -i '#{f}' '#{category_hash[category]}'"
  end
end


__END__

retrieve the classifier from the directory for update

for each sub-directory

  used the cwd.basename as the classification

  for each file
    get a summary
    train the classifier on the summary

store the classifier in the directory

for each unknown file in the directory
  get a summary
  classify the summary
  move the file into the proper sub-directory as
    directed by the user
