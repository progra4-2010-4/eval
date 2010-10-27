require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'

class User 
    require DataMapper::Resource
    property :id, Serial
    property :username, String
    has n, :threads
    has n, :comments
end

class Thread 
    require DataMapper::Resource
    property :id, Serial
    property :title, String, :required=>false
    property :url, String, :required=>false
    property :points, Integer
    property :created_at, DateTime
    property :text, Text
    property :type, Discriminator

    belongs_to :user
    has n, :comments

    def popularity 
        t = Date.day_fraction_to_time(DateTime.now - @created_at)[0]
        (@points-1) / (t+2)**1.8
    end

    def most_popular 
        self.all.sort{|a,b| a.popularity <=> b.popularity }
    end
end

class Comment 
    require DataMapper::Resource
    property :id, Serial
    property :points, Integer
    property :created_at, DateTime
    property :text, Text
    property :type, Discriminator

    belongs_to :user
    belongs_to :thread 
end


configure do 
    DataMapper.setup(:default, (ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/development.sqlite3"))
    DataMapper.auto_upgrade!
end

get '/' do 
    #return hottest news
    @news = Threads.most_popular
    haml :index
end

get '/newest' do 
    @news = Threads.all :order => [:created_at.desc]
end

get '/submit' do 
    #submit, validate and shit
end

get '/thread/:id' do |thread_id|
    #view comments on a thread
end

post '/posts' do 
    #create a thread, validate stuff
end
