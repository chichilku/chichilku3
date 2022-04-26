# frozen_string_literal: true

require 'rake'

Gem::Specification.new do |s|
  s.name        = 'chichilku3'
  s.version     = '14.0.4'
  s.executables = %w[chichilku3 chichilku3-server]
  s.date        = '2020-07-03'
  s.summary     = 'Stick battle game'
  s.description = 'Simple 2d online multiplayer stick figure battle game using the gosu (SDL2 based) gem for client side graphics. The network protocol is tcp based and only using ASCII printable characters.'
  s.authors     = ['ChillerDragon']
  s.email       = 'ChillerDragon@gmail.com'
  s.files       = FileList[
    'lib/client/*.rb',
    'lib/server/*.rb',
    'lib/share/*.rb',
    'lib/client/img/*.png',
    'lib/client/img/stick128/*.png',
    'lib/client/img/stick128/arm64/*.png',
    'lib/client/img/stick128/noarms/*.png',
    'lib/client/img/bow64/*.png',
    'client.json',
    'server.json',
    'maps'
  ]
  s.add_dependency 'fileutils', '~> 1.2.0'
  s.add_dependency 'gosu', '~> 1.4.3'
  s.add_dependency 'os', '~> 1.0.1'
  s.add_dependency 'rspec', '~> 3.9.0'
  s.add_dependency 'rubyzip', '~> 2.3.0'
  s.homepage    = 'https://github.com/chichilku/chichilku3'
  s.license     = 'Unlicense'
end
