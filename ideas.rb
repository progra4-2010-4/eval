require 'sinatra'
require 'dm-core'
require 'dm-migrations'

class Room 
    include DataMapper::Resource
    has n, :ideas
    property :id, Serial
    property :title, String
end

class Idea 
    include DataMapper::Resource
    belongs_to :room
    property :votes,   Integer, :default => 0
    property :content, String
end

configure do 
    DataMapper.setup(:default, (ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/development.sqlite3"))
    DataMapper.auto_upgrade!
end

get '/' do 
    haml :new
end

post '/rooms' do 
    Room.create :title => params[:title]
    redirect '/'
end


get '/rooms/:id' do |room_id| 
    room = Room.get room_id 
    redirect '/' unless room
    @ideas = room.ideas.all
    haml :ideas
end

post '/rooms/:id/ideas' do |room_id|
    room = Room.get room_id 
    redirect '/' unless room
    room.ideas << Idea.create :content=>params[:content]
    redirect "/rooms/#{room_id}"
end

put "/rooms/:id/ideas/:id" do |room_id, idea_id| 
    room = Room.get room_id 
    idea = Room.ideas.get idea_id
    redirect '/' unless room && idea
    idea.votes += params[:vote]
    redirect "/rooms/#{room_id}"
end
