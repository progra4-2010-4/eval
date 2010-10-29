require 'sinatra/base'
require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'
require 'dm-aggregates'
require 'hpricot'
require 'open-uri'
require 'coderay'
require 'rdiscount'
require 'haml'

class User 
    include DataMapper::Resource
    property :id, Serial
    property :username, String
    has n, :discussions
    has n, :comments
end

class Discussion 
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

    def self.most_popular 
        Discussion.all.sort{|a,b| b.popularity <=> a.popularity }
    end
end

class Comment 
    include DataMapper::Resource
    property :id, Serial
    property :created_at, DateTime
    property :content, Text

    belongs_to :user
    belongs_to :discussion
end
class SlackerNews < Sinatra::Base
    enable :sessions
    set :public, File.dirname(__FILE__) + '/public'
    configure do 
        DataMapper.setup(:default, (ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/development.sqlite3"))
        DataMapper.auto_upgrade!
    end
    helpers do 
        def logged_in? 
            !!session[:user_id]
        end
        def current_user 
            User.get(session[:user_id])
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
        @news = Discussion.most_popular
        haml :index
    end

    get '/newest' do 
        @news = Discussion.all :order => [:created_at.desc]
        haml :index
    end

    get '/submit' do 
        #submit, validate and shit
        redirect '/' unless logged_in?
        haml :submit
    end

    get '/discussions/:id' do |thread_id|
        #view comments on a thread
        @thread = Discussion.get thread_id
        redirect '/' if @thread.nil?
        haml :thread
    end

    get '/users/:user' do |username|
        #get threads submitted by user
        #TODO: valid user
        u = User.first :username=>username
        redirect '/' if u.nil?
        @news = u.discussions.all
        haml :index
    end

    get '/login' do 
        #get login form
        redirect '/' if logged_in?
        haml :login
    end

    post '/comments' do 
        #assign a comment to a thread
        thread = Discussion.get params[:thread]
        Comment.create :content=>params[:content], :discussion=>thread, :user => User.get(session[:user_id])
        thread.points += 1
        thread.save
        redirect "/discussions/#{params[:thread]}"
    end

    post '/discussions/vote/:id' do |thread_id| 
        t = Discussion.get(thread_id)
        t.points += 1
        t.save
        session[:voted] ||= []
        session[:voted] << t.id
        redirect request.referer
    end

    post '/discussions' do 
        #create a thread, validate stuff
        @errors = []
        @errors << "Tenés que proveer o un título o una url" if params[:title].strip.empty? && params[:url].strip.empty?
        return haml :submit unless @errors.empty?
        t = Discussion.new
        t.title = !params[:title].empty? ? params[:title] : get_title(params[:url])
        t.user = User.get session[:user_id]
        t.content= params[:content] || " "
        t.url = params[:url]
        t.save
        unless !params[:url].empty?
            t.update :url=>"/discussions/#{t.id}"
        end
        redirect '/newest'
    end

    post '/login' do 
        #login the user
        u = User.first_or_create :username => params["username"]
        session[:user_id] = u.id
        session[:voted] = []
        redirect '/'
    end
    get '/logout' do 
        session.clear
        redirect '/'
    end
end

