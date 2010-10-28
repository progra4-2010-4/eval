require 'sinatra/base'
require 'dm-core'
require 'haml'

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
        @messages = PushInfo.all
        p @messages
        haml :dashboard
    end
    
    post '/turnin' do 
        PushInfo.create :message => params[:payload]
        "OK"
    end
end
