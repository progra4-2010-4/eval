require 'slackernews'
require 'exam'

map "/" do 
    run SlackerNews 
end

map "/examen" do 
    run Exam 
end


