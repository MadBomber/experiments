# lib/sqa/constants.rb

module SQA
	module Constants
		Signal = {
			hold: 0,
			buy: 	1,
			sell: 2
		}.freeze

		Trend = {
			up: 	0,
			down: 1
		}.freeze

		Swing = {
			valley: 0,
			peak: 	1,
		}.freeze
	end

	include Constants
end
