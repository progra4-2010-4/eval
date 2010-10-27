require 'sinatra/base'
class  Exam < Sinatra::Base
    get '/' do 
        "ich bin admin"
    end

    get '/fr' do 
        "je suis admin"
    end
end
