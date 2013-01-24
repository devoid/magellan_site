require 'sinatra'
require 'gollum'
require 'pygments'
require 'haml'
require 'data_mapper'
require 'json'

@dir = File.dirname(__FILE__)
@database    = 'sqlite://' + @dir + '/status.db'
$gollum_wiki = @dir + '/wiki'
$wiki_root   = 'docs'
$api_token   = ""

# Database Configuration
DataMapper.setup(:default, @database)
# Model for Status updates, which are one-line posts
# with a timestamp and a flag { good, alert, down }
class Status
  include DataMapper::Resource
  property :id, Serial
  property :status, String, :required => true
  property :message, String
  property :timestamp, DateTime

  def to_json(*a)
    {
      'status'    => self.status,
      'message'   => self.message,
      'timestamp' => self.timestamp.to_s,
    }.to_json(*a)
  end
end
DataMapper.finalize
Status.auto_upgrade!

# Sinatra App
class MagellanWiki < Sinatra::Base
  set :public_folder, File.dirname(__FILE__) + '/static'
  # Index is special, uses the index template
  get '/' do
    erb :index, :locals => { :title => "The Argonne National Lab Cloud" }
  end
  # Wiki 
  get '/wiki/:page_name' do |page_name|
    wiki = Gollum::Wiki.new($gollum_wiki, :base_path => '/wiki')
    if page = wiki.paged(page_name, nil, exact = true)
      erb :wiki, :locals => {
        :content => page.formatted_data, 
        :title   => page_name
      }
    elsif file = wiki.file(page_name)
      content_type = file.mime_type
      halt 200, { 'Content-Type' => content_type }, file.raw_data
    else
      pass
    end
  end
  # System Status API
  post '/status/api' do 
    # rewind in case it was already read
    request.body.rewind
    data = JSON.parse request.body.read
    if !data.has_key?('status')
      status 400
    end
    
    if data.has_key?('amend') and data['amend']
      obj = Status.first(:limit => 1, :offset => 0, :order => :timestap.desc)
      obj.status = data['status']
      obj.message = data['message']   
      obj.timestamp = Time.now.getutc
    end
    if !obj 
      obj = Status.create(
        :status => data['status'],
        :message => data['message'],
        :timestamp => Time.now.getutc
      )
    end
    obj.save()
    status 200
    obj.to_json
  end 
  get '/status/api' do
    s = Status.first(:limit => 1, :offset => 0, :order => :timestamp.desc)
    if !s
        s = Status.create(
            :status => 'good',
            :message => "All systems OK!",
            :timestamp => Time.now.getutc
        )
        s.save()
    end 
    status 200
    content_type :json
    s.to_json
  end
  not_found do
    erb :error, :locals => { :title => "Not Found" }
  end
  run! if app_file == $0
end
