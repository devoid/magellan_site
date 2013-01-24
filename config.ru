# config.ru
# $ rackup -p 4567

# Intialize Bunlder
require 'rubygems'
require 'bundler'
Bundler.require

# Check out magellan_wiki git repo
if !File.directory? 'wiki'
    system 'git clone git://github.com/devoid/magellan_wiki.git wiki'
else
    system 'cd wiki; git checkout --force master; git reset --hard HEAD; git pull origin/master'
end

# Start the app
require './MagellanWiki'
run MagellanWiki
