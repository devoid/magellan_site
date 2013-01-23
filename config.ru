# config.ru
# $ rackup -p 4567

# Intialize Bunlder
require 'rubygems'
require 'bundler'
Bundler.require

# Check out magellan_wiki git repo
system 'git clone git://github.com/devoid/magellan_wiki.git wiki'

# Start the app
require './MagellanWiki'
run MagellanWiki
