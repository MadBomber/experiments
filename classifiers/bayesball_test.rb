#!/usr/bin/env ruby
###################################################
###
##  File: bayesball_test.rb
##  Desc: simple classifier
#

require 'assertions'
include Assertions

require 'amazing_print'
require 'date'

require 'bayesball'

puts "training bayesball to recognize different kinds of sports .."
sport = Bayesball::Classifier.new

puts "basketball"
sport.train('basketball', <<-EOF)
Basketball is a team sport, the objective being to shoot a ball through a basket horizontally positioned to score points while following a set of rules. Usually, two teams of five players play on a marked rectangular court with a basket at each width end. Basketball is one of the world's most popular and widely viewed sports.[1]
A regulation basketball ring consists of a rim 18 inches in diameter and 10 feet high mounted to a backboard. A team can score a field goal by shooting the ball through the basket during regular play. A field goal scores two points for the shooting team if a player is touching or closer to the basket than the three-point line, and three points (known commonly as a 3 pointer or three) if the player is behind the three-point line. The team with the most points at the end of the game wins, but additional time (overtime) may be issued when the game ends with a draw. The ball can be advanced on the court by bouncing it while walking or running (dribbling) or throwing (passing) it to a teammate. It is a violation to move without dribbling the ball (traveling), to carry it, or to double dribble (to hold the ball with both hands then resume dribbling).
Various violations are generally called "fouls". Disruptive physical contact (a personal foul) is penalized, and a free throw is usually awarded to an offensive player if he is fouled while shooting the ball. A technical foul may also be issued when certain infractions occur, most commonly for unsportsmanlike conduct on the part of a player or coach. A technical foul gives the opposing team a free throw.
Basketball has evolved many commonly used techniques of shooting, passing, dribbling, and rebounding, as well as specialized player positions and offensive and defensive structures (player positioning) and techniques. Typically, the tallest members of a team will play "center", "power forward" or "small forward" positions, while shorter players or those who possess the best ball handling skills and speed play "point guard" or "shooting guard".
While competitive basketball is carefully regulated, numerous variations of basketball have developed for casual play. Competitive basketball is primarily an indoor sport played on a carefully marked and maintained basketball court, but less regulated variations are often played outdoors in both inner city and remote areas.
EOF

puts "baseball"
sport.train('baseball', <<-EOF)
Baseball is a bat-and-ball sport played between two teams of nine players each. The aim is to score runs by hitting a thrown ball with a bat and touching a series of four bases arranged at the corners of a ninety-foot diamond. Players on the batting team take turns hitting against the pitcher of the fielding team, which tries to stop them from scoring runs by getting hitters out in any of several ways. A player on the batting team can stop at any of the bases and later advance via a teammate's hit or other means. The teams switch between batting and fielding whenever the fielding team records three outs. One turn at bat for each team constitutes an inning and nine innings make up a professional game. The team with the most runs at the end of the game wins.
Evolving from older bat-and-ball games, an early form of baseball was being played in England by the mid-eighteenth century. This game was brought by immigrants to North America, where the modern version developed. By the late nineteenth century, baseball was widely recognized as the national sport of the United States. Baseball is now popular in North America, parts of Central and South America and the Caribbean, and parts of East Asia.
In North America, professional Major League Baseball (MLB) teams are divided into the National League (NL) and American League (AL), each with three divisions: East, West, and Central. The major league champion is determined by playoffs that culminate in the World Series. Five teams make the playoffs from each league: the three regular season division winners, plus two wild card teams. Baseball is the leading team sport in both Japan and Cuba, and the top level of play is similarly split between two leagues: Japan's Central League and Pacific League; Cuba's West League and East League. In the National and Central leagues, the pitcher is required to bat, per the traditional rules. In the American, Pacific, and both Cuban leagues, there is a tenth player, a designated hitter, who bats for the pitcher. Each top-level team has a farm system of one or more minor league teams.
EOF

puts "racquetball"
sport.train('racquetball', <<-EOF)
Racquetball is a racquet sport played with a hollow rubber ball in an indoor or outdoor court. Joseph Sobek[1] is credited with inventing the modern sport of racquetball in 1950 (the outdoor, one-wall game goes back to at least 1910 in N.Y.C.),[2] adding a stringed racquet to paddleball in order to increase velocity and control. Unlike most racquet sports, such as tennis and badminton, there is no net to hit the ball over, and unlike squash no tin (out of bounds area at the bottom of front wall) to hit the ball above. Also, the court's walls, floor, and ceiling are legal playing surfaces, with the exception of court-specific designated hinders being out-of-bounds.[3] It is very similar to 40x20 handball, which is played in many countries.
EOF

puts "football"
sport.train('football', <<-EOF)
Football refers to a number of sports that involve, to varying degrees, kicking a ball with the foot to score a goal. The most popular of these sports worldwide is association football, more commonly known as just "football" or "soccer". Unqualified, the word football applies to whichever form of football is the most popular in the regional context in which the word appears, including association football, as well as American football, Australian rules football, Canadian football, Gaelic football, rugby league, rugby union[1] and other related games. These variations of football are known as football "codes".
Various forms of 'football' can be identified in history, often as popular peasant games. Contemporary codes of football can be traced back to the codification of these games at English public schools in the eighteenth and nineteenth century.[2][3] The influence and power of the British Empire allowed these rules of football to spread, including to areas of British influence outside of the directly controlled Empire,[4] though by the end of the nineteenth century, distinct regional codes were already developing: Gaelic Football, for example, deliberately incorporated the rules of local traditional football games in order to maintain their heritage.[5] In 1888, The Football League was founded in England, becoming the first of many professional football competitions. In the twentieth century, the various codes of football have become amongst the most popular team sports in the world.[6]
EOF

sport.train('football', 'field goal')

puts "training completed."
puts "now testing ..."

assert_equal 'basketball',  sport.classify('the shot did not count because he was traveling')
assert_equal 'baseball',    sport.classify('I want to play Major League Baseball some day')
assert_equal 'racquetball', sport.classify('Hitting a ball made of rubber')
assert_equal 'basketball',  sport.classify('The winning team is kicking butt. They always make the ball go in the hoop every time')
assert_equal 'tennis',      sport.classify('He put a significant slice on his serve.')
