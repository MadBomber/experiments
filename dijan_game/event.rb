require('sourcify') unless Proc.methods.include?(:to_source)

require 'binding_of_caller'

class Event

	@@events = []

	class << self

		def new (probability, name, &block)
			@@events << [probability, name, block ]
		end

		def events
			@@events
		end

		def check
			transactions = []
			@@events.each do |e|
				if e.first > rand(100)
					proc = e.last.to_source
					# puts proc
					amount = binding.of_caller(2).eval("#{proc}.call")
					transactions << "\t   #{e[1]} #{amount<0 ? 'Lose' : 'Gain'} $#{amount.abs}"
				end
			end
			return transactions
		end

	end # class << self

end # class Event