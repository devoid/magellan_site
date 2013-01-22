# config.ru
# $ rackup -p 4567

# Intialize Bunlder
require 'rubygems'
require 'bundler'
Bundler.require

# Initalize git submodule(s)
system 'git submodule init'
system 'git submodule update'

# Start the app
require './MagellanWiki'
run MagellanWiki
