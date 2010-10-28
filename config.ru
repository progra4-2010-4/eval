require 'slackernews'
require 'exam'
require 'admin'

map "/" do 
    run SlackerNews 
end

map "/examen" do 
    run Exam 
end

map "/admin" do 
    run Admin
end


