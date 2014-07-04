#!/usr/bin/env ruby
require 'optparse'

options = {}

option_parser = OptionParser.new do |opt|
  opt.banner = "Usage: httperf_wsesslog_generator.rb [options]"
  opt.on('-s', '--flow FLOW_NAME', 'The flow to test') do |value|
    options[:flow_name] = value
  end
  
  opt.on('-s', '--input [INPUT]', 'The default input to pass') do |value|
    options[:input] = value || ""
  end
  
  opt.on('-h', '--help', 'Display this screen' ) do
    puts opt
    exit!
  end
end

option_parser.parse!

flow = options[:flow_name] || "calculator"
input = options[:input] || ""
wsesslog = File.dirname(__FILE__) + "/httperf_wsesslog.txt"
url = "/#{flow}?msisdn=9846819066&session_id=%%sesssion_id%%&input=#{input}"
count = 10_000

File.open(wsesslog, "w") do |f|
  count.times do
    session_id = (rand * 100_000).to_i.to_s
    f.puts(url.gsub('%%sesssion_id%%', session_id))
  end
end

puts "Now run time httperf --hog --client=0/1 --server=localhost --port=9000 --wsesslog=10000,0,httperf_wsesslog.txt --rate 2"
