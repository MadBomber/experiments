#!/usr/bin/env ruby
######################################################################
###
##  File: train_bayes_classifier.rb
##  Desc: Train a classifier for the current directory.
#
require 'debug_me'
include DebugMe

require 'pathname'    # STDLIB

require 'summary'     # GEM that summarizes a document
# NOTE: the 'summary' gem monkey patches String with a summary method
#       and SO DOES the 'classifier' gem.  So we make an alias so that
#       we can access to 'summary' gem's method.
class String
  alias :tdv_summary :summary
end

require 'classifier-reborn'  # GEM that implements both a bayes and an LSI classifier

# my fork reclassifier is a fork of a fork of classifier.
# The original classifier has been updated more recently than
# in intervening forks of reclassifier.  Time to resync to the
# original?



require 'systemu'     # STDLIB
require 'pp'          # STDLIB

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
  certainly changes clearly c'mon co co. com come comes concerning consequently consider
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
)




class String
  def remove_stop_words
    self.split(" ").select{|w| 2<w.length && !$stop_words.include?(w)}.join(" ")
  end
  def remove_stuff(seq="\n")
    self.gsub(seq, ' ').gsub(/[_\-\.\,0-9\W]/, ' ').strip.squeeze(" ").remove_stop_words
  end
end # class String



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
files_without_category = cwd.children.select {|c| c if c.file? }


classifier = ClassifierReborn::Bayes.new(category_hash.keys)



category_hash.each_pair do | category, dir |

  debug_me{[ :category, :dir ]}

  classifier.train(category, category.remove_stuff)

  puts "Training #{category} ..."
  dir.children.sort.each do |f|
    unless f.directory?
      #puts "  Summary of #{f}"
      # get summary of file
      ext       = f.extname.downcase
      title     = f.basename.to_s.downcase.remove_stuff(ext)
      puts "  Title: #{title}"
      classifier.train category, title
      summary = ""
      case ext
        when '.html', '.htm' then
          a,b,c = systemu "html2text #{f.to_s}"
          summary = b.downcase.remove_stuff.tdv_summary(500, " ")
        when '.pdf' then
          a,b,c = systemu "pdf2txt #{f.to_s}"
          summary = b.downcase.remove_stuff.tdv_summary(500, " ")
        when '.txt' then
          fc = f.read
          summary = fc.downcase.remove_stuff.tdv_summary(500, " ")
        else
          # noop
      end
      unless summary.empty?
        puts "Summary: #{summary}"
        classifier.train category, summary
      end
    end
  end

end




files_without_category.each do |f|

  next if f.extname == '.model'  ||  f.extname == '.metadata'

  puts "File: #{f.basename}"
  ext       = f.extname.downcase
  summary   = f.basename.to_s.downcase.remove_stuff(ext) + " "

  case ext
    when '.html', '.htm' then
      a,b,c = systemu "html2text #{f.to_s}"
      summary += b.downcase.remove_stuff.tdv_summary(500, " ")
    when '.pdf' then
      a,b,c = systemu "pdf2txt #{f.to_s}"
      summary += b.downcase.remove_stuff.tdv_summary(500, " ")
    when '.txt' then
      fc = f.read
      summary += fc.downcase.remove_stuff.tdv_summary(500, " ")
    else
      # noop
  end


  category_weights_hash = classifier.classifications summary

  category  = classifier.classify summary
  score     = category_weights_hash[category]

  puts "Summary: #{summary}"
  puts
  puts "Category: #{score}   #{category}"
  puts
  puts "  Others: \n#{category_weights_hash.pretty_inspect}"
  puts

  if score > -10.0
    print "Do you want to move the file? (no) "
    answer = gets.strip.downcase
    if !answer.empty? && 'y' == answer[0]
      system "mv -i '#{f}' '#{category_hash[category.downcase]}'"
    end
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


