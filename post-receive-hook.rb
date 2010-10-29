#!/usr/bin/env ruby
#
# An example hook script for the "post-receive" event.
#
# The "post-receive" script is run after receive-pack has accepted a pack
# and the repository has been updated.  It is passed arguments in through
# stdin in the form
#  <oldrev> <newrev> <refname>
# For example:
#  aa453216d1b3e49e7f6f98441fa56946ddcd6a20 68f7abf4e6f922807889f52bc043ecd31b79f814 refs/heads/master
#
# see contrib/hooks/ for a sample, or uncomment the next line and
# rename the file to "post-receive".

#. /usr/share/doc/git-core/contrib/hooks/post-receive-email
require 'rubygems'
require 'httparty'
require "grit"
require 'json'
require 'pathname'
include Grit
class GitPush 
    include HTTParty
    #base_uri "localhost:3000/admin"
    base_uri "http://morning-sunset-84.heroku.com/admin"
    
    def self.report(info)
        options = {:query => {:payload => info} }
        begin
            res = post "/turnin", options
            puts "Tu examen ya fue actualizado y el docente, notificado"
        rescue
            puts "No se pudo actualizar el servidor de entregas"
        end
    end
end
stdins = []; stdins << $_ while gets
old_revision = stdins[0]
new_revision = stdins[1]
ref = stdins[2]
repo = Repo.init_bare_or_open(ENV["GIT_DIR"])
info = {}

#populate the commit info:
new_commit = repo.commit new_revision
info[:repo] = Pathname.new(repo.path).basename.to_s.gsub(".git", "")
info[:commiter] = "#{new_commit.author.name} <#{new_commit.author.email}>"
info[:when] = new_commit.date
info[:stats] = new_commit.stats.to_hash
GitPush.report JSON.unparse(info)
