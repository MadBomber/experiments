#!/usr/bin/env ruby
###################################################
###
##  File: libsvm_test.rb
##  Desc: simple classifier
#

require 'awesome_print'

# In this example let's have 3 documents.  2 of the documents
# will go into our training set and 1 will be used as our
# test set
#
# Before we can actually classify the documents we need to
# create integer representations of each of the documents.
# The best way to do this would be to use ruby to accomplish
# the task.
#
require 'libsvm'

# Let take our documents and create word vectors out of them.
# I've included labels for these already.  1 signifies that
# the document was funny, 0 means that it wasn't.
#
documents = [[1, "Why did the chicken cross the road? Because a car was coming"],
             [0, "You're an elevator tech? I bet that job has its ups and downs"]]

puts "Joke Training set:"
documents.each do |d|
  print 1==d.first ? 'Funny: ' : 'Not Funny: '
  puts d.last
end

puts 'Training ...'

# Lets create a dictionary of unique words and then we can
# create our vectors.  This is a very simple example.  If you
# were doing this in a production system you'd do things like
# stemming and removing all punctuation (in a less casual way).
#
dictionary = documents.map(&:last).map(&:split).flatten.uniq
dictionary = dictionary.map { |x| x.gsub(/\?|,|\.|\-/,'') }

training_set = []

documents.each do |doc|
  features_array = dictionary.map { |x| doc.last.include?(x) ? 1 : 0 }
  training_set << [doc.first, Libsvm::Node.features(features_array)]
end

# Lets set up libsvm so that we can test our prediction
# using the test set
#
problem   = Libsvm::Problem.new
parameter = Libsvm::SvmParameter.new

parameter.cache_size  = 1 # in megabytes
parameter.eps         = 0.001
parameter.c           = 10

# Train classifier using training set
#
problem.set_examples(training_set.map(&:first), training_set.map(&:last))
model = Libsvm::Model.train(problem, parameter)

# Now lets test our classifier using the test set
#
test_set      = [1, "Why did the chicken cross the road? To get the worm"]

puts "Testing ..."
puts test_set.last



test_document = test_set.last.split.map{ |x| x.gsub(/\?|,|\.|\-/,'') }

doc_features  = dictionary.map{|x| test_document.include?(x) ? 1 : 0 }
pred          = model.predict(Libsvm::Node.features(doc_features))

puts "Predicted #{pred==1 ? 'funny' : 'not funny'}"

puts
puts


################################################################
## try the sport example with SVM


basketball  = <<-EOF
Basketball is a team sport, the objective being to shoot a ball through a basket horizontally positioned to score points while following a set of rules. Usually, two teams of five players play on a marked rectangular court with a basket at each width end. Basketball is one of the world's most popular and widely viewed sports.[1]
A regulation basketball ring consists of a rim 18 inches in diameter and 10 feet high mounted to a backboard. A team can score a field goal by shooting the ball through the basket during regular play. A field goal scores two points for the shooting team if a player is touching or closer to the basket than the three-point line, and three points (known commonly as a 3 pointer or three) if the player is behind the three-point line. The team with the most points at the end of the game wins, but additional time (overtime) may be issued when the game ends with a draw. The ball can be advanced on the court by bouncing it while walking or running (dribbling) or throwing (passing) it to a teammate. It is a violation to move without dribbling the ball (traveling), to carry it, or to double dribble (to hold the ball with both hands then resume dribbling).
Various violations are generally called "fouls". Disruptive physical contact (a personal foul) is penalized, and a free throw is usually awarded to an offensive player if he is fouled while shooting the ball. A technical foul may also be issued when certain infractions occur, most commonly for unsportsmanlike conduct on the part of a player or coach. A technical foul gives the opposing team a free throw.
Basketball has evolved many commonly used techniques of shooting, passing, dribbling, and rebounding, as well as specialized player positions and offensive and defensive structures (player positioning) and techniques. Typically, the tallest members of a team will play "center", "power forward" or "small forward" positions, while shorter players or those who possess the best ball handling skills and speed play "point guard" or "shooting guard".
While competitive basketball is carefully regulated, numerous variations of basketball have developed for casual play. Competitive basketball is primarily an indoor sport played on a carefully marked and maintained basketball court, but less regulated variations are often played outdoors in both inner city and remote areas.
EOF

baseball  = <<-EOF
Baseball is a bat-and-ball sport played between two teams of nine players each. The aim is to score runs by hitting a thrown ball with a bat and touching a series of four bases arranged at the corners of a ninety-foot diamond. Players on the batting team take turns hitting against the pitcher of the fielding team, which tries to stop them from scoring runs by getting hitters out in any of several ways. A player on the batting team can stop at any of the bases and later advance via a teammate's hit or other means. The teams switch between batting and fielding whenever the fielding team records three outs. One turn at bat for each team constitutes an inning and nine innings make up a professional game. The team with the most runs at the end of the game wins.
Evolving from older bat-and-ball games, an early form of baseball was being played in England by the mid-eighteenth century. This game was brought by immigrants to North America, where the modern version developed. By the late nineteenth century, baseball was widely recognized as the national sport of the United States. Baseball is now popular in North America, parts of Central and South America and the Caribbean, and parts of East Asia.
In North America, professional Major League Baseball (MLB) teams are divided into the National League (NL) and American League (AL), each with three divisions: East, West, and Central. The major league champion is determined by playoffs that culminate in the World Series. Five teams make the playoffs from each league: the three regular season division winners, plus two wild card teams. Baseball is the leading team sport in both Japan and Cuba, and the top level of play is similarly split between two leagues: Japan's Central League and Pacific League; Cuba's West League and East League. In the National and Central leagues, the pitcher is required to bat, per the traditional rules. In the American, Pacific, and both Cuban leagues, there is a tenth player, a designated hitter, who bats for the pitcher. Each top-level team has a farm system of one or more minor league teams.
EOF

racquetball   = <<-EOF
Racquetball is a racquet sport played with a hollow rubber ball in an indoor or outdoor court. Joseph Sobek[1] is credited with inventing the modern sport of racquetball in 1950 (the outdoor, one-wall game goes back to at least 1910 in N.Y.C.),[2] adding a stringed racquet to paddleball in order to increase velocity and control. Unlike most racquet sports, such as tennis and badminton, there is no net to hit the ball over, and unlike squash no tin (out of bounds area at the bottom of front wall) to hit the ball above. Also, the court's walls, floor, and ceiling are legal playing surfaces, with the exception of court-specific designated hinders being out-of-bounds.[3] It is very similar to 40x20 handball, which is played in many countries.
EOF

football  = <<-EOF
Football refers to a number of sports that involve, to varying degrees, kicking a ball with the foot to score a goal. The most popular of these sports worldwide is association football, more commonly known as just "football" or "soccer". Unqualified, the word football applies to whichever form of football is the most popular in the regional context in which the word appears, including association football, as well as American football, Australian rules football, Canadian football, Gaelic football, rugby league, rugby union[1] and other related games. These variations of football are known as football "codes".
Various forms of 'football' can be identified in history, often as popular peasant games. Contemporary codes of football can be traced back to the codification of these games at English public schools in the eighteenth and nineteenth century.[2][3] The influence and power of the British Empire allowed these rules of football to spread, including to areas of British influence outside of the directly controlled Empire,[4] though by the end of the nineteenth century, distinct regional codes were already developing: Gaelic Football, for example, deliberately incorporated the rules of local traditional football games in order to maintain their heritage.[5] In 1888, The Football League was founded in England, becoming the first of many professional football competitions. In the twentieth century, the various codes of football have become amongst the most popular team sports in the world.[6]
A field goal scores 3 points.
EOF


documents   = Array.new
documents   << [1, basketball.downcase]
documents   << [2, baseball.downcase]
documents   << [3, racquetball.downcase]
documents   << [4, football.downcase]


# Lets create a dictionary of unique words and then we can
# create our vectors.  This is a very simple example.  If you
# were doing this in a production system you'd do things like
# stemming and removing all punctuation (in a less casual way).
#
dictionary = documents.map(&:last).map(&:split).flatten.uniq
dictionary = dictionary.map { |x| x.gsub(/\?|,|\.|\-/,'') }

training_set = Array.new

documents.each do |doc|
  features_array = dictionary.map { |x| doc.last.include?(x) ? 1 : 0 }
  training_set << [doc.first, Libsvm::Node.features(features_array)]
end

# Lets set up libsvm so that we can test our prediction
# using the test set
#
problem   = Libsvm::Problem.new
parameter = Libsvm::SvmParameter.new

parameter.cache_size  = 1 # in megabytes
parameter.eps         = 0.001
parameter.c           = 10

# Train classifier using training set
#
problem.set_examples(training_set.map(&:first), training_set.map(&:last))
model = Libsvm::Model.train(problem, parameter)


####################################################################################
##

# sport.classify('the shot did not count because he was traveling') #=> 'basketball'
# sport.classify('I want to play Major League Baseball some day')   #=>  'baseball'
# sport.classify('Hitting a ball made of rubber')                   #=>  'racquetball'
# sport.classify('The winning team is kicking butt. They always make the ball go in the hoop every time') #=> 'basketball'


test_set  = Array.new
test_set  << [1, 'the shot did not count because he was traveling']
test_set  << [2, 'I want to play Major League Baseball some day']
test_set  << [3, 'Hitting a ball made of rubber']
test_set  << [4, 'The winning team is kicking butt. They always make the ball go in the hoop every time']

expected_labels = %w[ xyzzy basketball baseball racquetball basketball ]


test_set.each do |ts|

  test_document = ts.last.split.map{ |x| x.gsub(/\?|,|\.|\-/,'').downcase }

  doc_features  = dictionary.map{|x| test_document.include?(x) ? 1 : 0 }
  pred          = model.predict(Libsvm::Node.features(doc_features))

  puts "Predicted  #{expected_labels[pred]} ... #{pred == ts.first ? 'correct' : 'not correct'}"

end

#ap dictionary
