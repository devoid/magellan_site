#!/usr/bin/env ruby
require 'rest_client'
require 'optparse'
require 'rainbow'
require 'json'
require 'tempfile'


# TODO: Get OptionParser to check for multiple incompatible flags -g -a -d
options = {
  :host => "localhost:4567",
  :debug => false,
  :amend => false,
}

parser = OptionParser.new do  |opts|
  opts.banner = "Usage: magellan-status [service] [options]"
  opts.on("-g", "--good", "Set the service status to a good message") do
    options[:status]  = "good"
  end
  opts.on("-a", "--alert", "Issue a service alert") do
    options[:status]  = "alert"
  end
  opts.on("-d", "--down", "Set the service to down!!") do
    options[:status]  = "down"
  end
  opts.on("--amend", "Amend the existing status rather than push a new status") do 
    options[:amend]   = true
  end
  opts.on("-h" , "--host hostname:port", "Talk with a non-default host") do |host|
    options[:host]    = host
  end
  opts.on("-?", "--help", "Print this usage information") do
    puts opts
    exit
  end
end
parser.parse!
options[:host] = "http://" + options[:host] + "/status/api"


client = RestClient::Resource.new(options[:host])
if options.has_key?(:status)
  editor = ENV['EDITOR'] || 'vi'
  file   = Tempfile.new('foo')
  file.close()
  if `#{editor} #{file}`
    message = file.open().read() 
    file.close(unlink_now=true)
  end
  if !message
    exit
  end
  body = { 
    'status'  => options[:status],
    'message' => options[:message],
    'amend'   => options[:amend],
  }
  res = client.post body.to_json, :content_type => :json, :accept => :json
else
  # Query for existing statuses
  res = client.get
end

# Now echo back the status
obj = JSON.parse(res.body)
color = :green
if obj['status'] == "alert"
  color = :yellow
elsif obj['status'] == "down"
  color = :red
end
msg = "\nStatus: " + obj['message']
puts msg.foreground(color)
