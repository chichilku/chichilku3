require 'rake'

Gem::Specification.new do |s|
  s.name        = 'chichilku3'
  s.version     = '14.0.0'
  s.executables = ['chichilku3', 'chichilku3-server']
  s.date        = '2020-04-15'
  s.summary     = "Stick battle game"
  s.description = "Simple 2d online multiplayer stick figure battle game using the gosu (SDL2 based) gem for client side graphics. The network protocol is tcp based and only using ASCII printable characters."
  s.authors     = ["ChillerDragon"]
  s.email       = 'ChillerDragon@gmail.com'
  s.files       = FileList[
    'lib/client/*.rb',
    'lib/server/*.rb',
    'lib/share/*.rb',
    'lib/client/img/*.png',
    'lib/client/img/stick128/*.png',
    'lib/client/img/bow64/*.png',
    'client.json',
    'server.json'
  ]
  s.homepage    = 'https://github.com/chichilku/chichilku3'
  s.license     = 'Unlicense'
end
