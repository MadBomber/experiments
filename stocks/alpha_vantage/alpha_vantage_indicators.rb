require 'faraday'
require 'amazing_print'
require 'nenv'

require 'pathname'
require 'json'

require 'debug_me'
include DebugMe


#
# Rate Limitation on Alpha Vantage Free API
# =========================================
#
# Thank you for using Alpha Vantage! Our standard API call frequency
# is 5 calls per minute and 100 calls per day. Please visit
#
# Alpha Vantage does not provide its rate status in any headers; so,
# need to track our own call rates.
#
# This simple approach works fine for this specific program; however, for
# a general purpose interface we need to setup a client class and track
# the rate usage accross the entire application.
#
RATE_CNT = 5
RATE_PER = 60 # seconds

DEMO = Nenv.av_api_key

CONNECTION = Faraday.new(url: "https://www.alphavantage.co" )

INDICATORS = [
	"/query?function=ADOSC&symbol=IBM&interval=daily&fastperiod=5&apikey=#{DEMO}",
	"/query?function=ADX&symbol=IBM&interval=daily&time_period=10&apikey=#{DEMO}",
	"/query?function=ADXR&symbol=IBM&interval=daily&time_period=10&apikey=#{DEMO}",
	"/query?function=APO&symbol=IBM&interval=daily&series_type=close&fastperiod=10&matype=1&apikey=#{DEMO}",
	"/query?function=AROON&symbol=IBM&interval=daily&time_period=14&apikey=#{DEMO}",
	"/query?function=AROONOSC&symbol=IBM&interval=daily&time_period=10&apikey=#{DEMO}",
	"/query?function=ATR&symbol=IBM&interval=daily&time_period=14&apikey=#{DEMO}",
	"/query?function=BBANDS&symbol=IBM&interval=weekly&time_period=5&series_type=close&nbdevup=3&nbdevdn=3&apikey=#{DEMO}",
	"/query?function=BOP&symbol=IBM&interval=daily&apikey=#{DEMO}",
	"/query?function=CCI&symbol=IBM&interval=daily&time_period=10&apikey=#{DEMO}",
	"/query?function=CMO&symbol=IBM&interval=weekly&time_period=10&series_type=close&apikey=#{DEMO}",
	"/query?function=DEMA&symbol=IBM&interval=weekly&time_period=10&series_type=open&apikey=#{DEMO}",
	"/query?function=DX&symbol=IBM&interval=daily&time_period=10&apikey=#{DEMO}",
	"/query?function=EMA&symbol=IBM&interval=weekly&time_period=10&series_type=open&apikey=#{DEMO}",
	"/query?function=HT_DCPERIOD&symbol=IBM&interval=daily&series_type=close&apikey=#{DEMO}",
	"/query?function=HT_DCPHASE&symbol=IBM&interval=daily&series_type=close&apikey=#{DEMO}",
	"/query?function=HT_PHASOR&symbol=IBM&interval=weekly&series_type=close&apikey=#{DEMO}",
	"/query?function=HT_SINE&symbol=IBM&interval=daily&series_type=close&apikey=#{DEMO}",
	"/query?function=HT_TRENDLINE&symbol=IBM&interval=daily&series_type=close&apikey=#{DEMO}",
	"/query?function=HT_TRENDMODE&symbol=IBM&interval=weekly&series_type=close&apikey=#{DEMO}",
	"/query?function=KAMA&symbol=IBM&interval=weekly&time_period=10&series_type=open&apikey=#{DEMO}",
	"/query?function=MAMA&symbol=IBM&interval=daily&series_type=close&fastlimit=0.02&apikey=#{DEMO}",
	"/query?function=MFI&symbol=IBM&interval=weekly&time_period=10&apikey=#{DEMO}",
	"/query?function=MIDPOINT&symbol=IBM&interval=daily&time_period=10&series_type=close&apikey=#{DEMO}",
	"/query?function=MIDPRICE&symbol=IBM&interval=daily&time_period=10&apikey=#{DEMO}",
	"/query?function=MINUS_DI&symbol=IBM&interval=weekly&time_period=10&apikey=#{DEMO}",
	"/query?function=MINUS_DM&symbol=IBM&interval=daily&time_period=10&apikey=#{DEMO}",
	"/query?function=MOM&symbol=IBM&interval=daily&time_period=10&series_type=close&apikey=#{DEMO}",
	"/query?function=NATR&symbol=IBM&interval=weekly&time_period=14&apikey=#{DEMO}",
	"/query?function=OBV&symbol=IBM&interval=weekly&apikey=#{DEMO}",
	"/query?function=PLUS_DI&symbol=IBM&interval=daily&time_period=10&apikey=#{DEMO}",
	"/query?function=PLUS_DM&symbol=IBM&interval=daily&time_period=10&apikey=#{DEMO}",
	"/query?function=PPO&symbol=IBM&interval=daily&series_type=close&fastperiod=10&matype=1&apikey=#{DEMO}",
	"/query?function=ROC&symbol=IBM&interval=weekly&time_period=10&series_type=close&apikey=#{DEMO}",
	"/query?function=ROCR&symbol=IBM&interval=daily&time_period=10&series_type=close&apikey=#{DEMO}",
	"/query?function=RSI&symbol=IBM&interval=weekly&time_period=10&series_type=open&apikey=#{DEMO}",
	"/query?function=SAR&symbol=IBM&interval=weekly&acceleration=0.05&maximum=0.25&apikey=#{DEMO}",
	"/query?function=SMA&symbol=IBM&interval=weekly&time_period=10&series_type=open&apikey=#{DEMO}",
	"/query?function=STOCH&symbol=IBM&interval=daily&apikey=#{DEMO}",
	"/query?function=STOCHF&symbol=IBM&interval=daily&apikey=#{DEMO}",
	"/query?function=STOCHRSI&symbol=IBM&interval=daily&time_period=10&series_type=close&fastkperiod=6&fastdmatype=1&apikey=#{DEMO}",
	"/query?function=T3&symbol=IBM&interval=weekly&time_period=10&series_type=open&apikey=#{DEMO}",
	"/query?function=T3&symbol=IBM&interval=weekly&time_period=10&series_type=open&apikey=#{DEMO}",
	"/query?function=TEMA&symbol=IBM&interval=weekly&time_period=10&series_type=open&apikey=#{DEMO}",
	"/query?function=TRANGE&symbol=IBM&interval=daily&apikey=#{DEMO}",
	"/query?function=TRIMA&symbol=IBM&interval=weekly&time_period=10&series_type=open&apikey=#{DEMO}",
	"/query?function=TRIX&symbol=IBM&interval=daily&time_period=10&series_type=close&apikey=#{DEMO}",
	"/query?function=ULTOSC&symbol=IBM&interval=daily&timeperiod1=8&apikey=#{DEMO}",
	"/query?function=WILLR&symbol=IBM&interval=daily&time_period=10&apikey=#{DEMO}",
	"/query?function=WMA&symbol=IBM&interval=weekly&time_period=10&series_type=open&apikey=#{DEMO}",
]



counter = 0

INDICATORS.each_slice(RATE_CNT) do |group|
	start_time = Time.now.to_i # seconds

	group.each do |metric|
		counter += 1
		name = metric.scan(/function=(.*?)&/).flatten.first
		path = Pathname.new("av_" + sprintf("%02d", counter) + "_#{name}.json")

		next if path.exist?

		puts path.basename.to_s

		response = CONNECTION.get(metric)
		path.write response.to_hash[:body]
	end

	end_time = Time.now.to_i

	delay = RATE_PER - (end_time - start_time) + 1

	delay = 1 if delay < 1

	puts "  waiting #{delay} seconds ..."
	sleep(delay)
end

__END__



require 'faraday'
require 'redcarpet'
require 'securerandom'



#################################################
# Format the responses as Markdown
markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
formatted_responses = responses.map do |response|
  markdown.render(response.body)
end

# Output the formatted responses
formatted_responses.each do |formatted_response|
  puts formatted_response
  puts '-' * 80
end


