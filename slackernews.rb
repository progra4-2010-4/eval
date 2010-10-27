require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'
require 'datehelper'
require 'hpricot'
require 'open-uri'
require 'coderay'
require 'rdiscount'

include DateHelper

class User 
    include DataMapper::Resource
    property :id, Serial
    property :username, String
    has n, :threads
    has n, :comments
end

class Thread 
    include DataMapper::Resource
    property :id, Serial
    property :title, String, :required=>false
    property :url, String, :required=>false
    property :points, Integer, :default=>0
    property :created_at, DateTime
    property :content, Text

    belongs_to :user
    has n, :comments

    def popularity 
        t = Date.day_fraction_to_time(DateTime.now - @created_at)[0]
        (@points-1) / (t+2)**1.8
    end

    def most_popular 
        Thread.all.sort{|a,b| a.popularity <=> b.popularity }
    end

    def when(options={})
        #precision=>3 is hourly precision
        distance_of_time_in_words @created_at, DateTime.now , false , options
    end
end

class Comment 
    require DataMapper::Resource
    property :id, Serial
    property :points, Integer, :default=>0
    property :created_at, DateTime
    property :text, Text

    belongs_to :user
    belongs_to :thread 
    
    def when(options={})
        #precision=>3 is hourly precision
        distance_of_time_in_words @created_at, DateTime.now , false , options
    end
end


configure do 
    DataMapper.setup(:default, (ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/development.sqlite3"))
    DataMapper.auto_upgrade!
end
helpers do 
    def logged_in? 
        !!session[:user_id]
    end

    def get_title(uri)
       begin
           doc = Hpricot open(uri).read
           title = doc.search("title").inner_text
           title.strip.empty? ? uri : title
       rescue
           uri
       end
    end

    def display_formatted(raw_markdown) 
        #convert to html
        md = RDiscount.new raw_markdown
        #examine with hpricot
        html = Hpricot md.to_html
        #search for code and highlight it
        html.search "pre" do |code| 
            lang = ""
            lines = code.innerText.split "\n"
            lines.each do |line|
                if line[0..2] == "@@@"
                    lang = line.gsub "@@@", '' 
                    break
                end
            end
            #ok, we have the lang, now, color it
            newhtml = Hpricot CodeRay.scan(lines[1..-1].join("\n"), lang.to_sym).div :line_numbers => :inline, :css => :class
            html.replace_child code, newhtml
        end
        #return the string representation of the note
        html.to_s
    end
end

get '/' do 
    #return hottest news
    @news = Threads.most_popular
    haml :index
end

get '/newest' do 
    @news = Threads.all :order => [:created_at.desc]
    haml :index
end

get '/submit' do 
    #submit, validate and shit
    redirect '/' unless logged_in?
    haml :submit
end

get '/threads/:id' do |thread_id|
    #view comments on a thread
    @thread = Thread.get thread_id
    haml :thread
end

get '/threads/:user' do |user_id|
    #get threads submitted by user
    @news = User.get(user_id).threads.all
    haml :index
end

get '/login' do 
    #get login form
    redirect '/' if logged_in?
    haml :login
end

post '/comments' do 
    #assign a comment to a thread
    Comment.create :content=>params[:content], :thread=>Thread.get(params[:thread]), :user => User.get(session[:user_id])
    redirect "/threads/#{params[:thread]}"
end

post '/threads' do 
    #create a thread, validate stuff
    @errors = []
    @errors << "Tenés que proveer o un título o una url" unless params[:title] || params[:url]
    redirect '/submit' if @errors

    t = Thread.new
    t.title = params[:title] ? params[:title] : get_title(params[:url])
    t.user = User.get session[:user_id]
    t.content= params[:content] || " "
    t.save
    t.url = params[:url] ? params[:url] : "/threads/#{t.id}"
    t.save

    redirect '/newest'
end

post '/login' do 
    #login the user
    u = User.first_or_create :username => params["username"]
    session[:user_id] = u.id
    redirect '/'
end

