#!/usr/bin/env ruby
# base.rb

module M
end

class M::Base
end


class M::One < M::Base
end

class M::Two < M::Base
end

class M::Three < M::Base
end

names = ObjectSpace
					.each_object(Class)
					.select { |klass| klass < M::Base }
					.map(&:name)

puts names.join(", ")

puts names.map{|n| n.split('::').last}.join(", ")

