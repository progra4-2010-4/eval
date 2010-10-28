require 'sinatra/base'
require 'dm-core'
require 'haml'
require 'json'

class PushInfo 
    include DataMapper::Resource
    property :id, Serial
    property :message, String
end

class Admin < Sinatra::Base
    set :views, File.dirname(__FILE__) + '/admin_views'    
    configure do 
         DataMapper.setup(:default, (ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/turnins.sqlite3"))
         DataMapper.auto_upgrade!
    end

    get '/' do 
        @raw_messages = PushInfo.all
        @messages = @raw_messages.collect {|m| JSON.parse(m.message)}
        #p @messages
        haml :dashboard
    end
    
    post '/turnin' do 
        PushInfo.create :message => params[:payload]
        "OK"
    end
end
