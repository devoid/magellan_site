# config.ru
# $ rackup -p 4567

system 'git submodule init'
system 'git submodule update'
require './MagellanWiki'
run MagellanWiki
