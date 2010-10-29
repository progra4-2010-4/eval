require 'sinatra/base'
class  Exam < Sinatra::Base
    
    set :views, File.dirname(__FILE__) + '/admin_views'    
    set :public, File.dirname(__FILE__) + '/public'

    get '/' do 
        haml :enunciado
    end
end
