# frozen_string_literal: true

require 'rake'

Gem::Specification.new do |s|
  s.name        = 'chichilku3'
  s.version     = '15.0.3'
  s.executables = %w[chichilku3 chichilku3-server]
  s.summary     = 'Stick battle game'
  s.description = <<-DESC
  Simple 2d online multiplayer stick figure battle game using the gosu (SDL2 based) gem for client side graphics.
  The network protocol is tcp based and only using ASCII printable characters.
  DESC
  s.authors     = ['ChillerDragon']
  s.email       = 'ChillerDragon@gmail.com'
  s.files       = FileList[
    'lib/client/*.rb',
    'lib/server/*.rb',
    'lib/share/*.rb',
    'lib/external/gosu/*.rb',
    'lib/external/rubyzip/*.rb',
    'lib/client/img/*.png',
    'lib/client/img/stick128/*.png',
    'lib/client/img/stick128/arm64/*.png',
    'lib/client/img/stick128/noarms/*.png',
    'lib/client/img/grass/*.png',
    'lib/client/img/bow64/*.png',
    'client.json',
    'server.json',
    'maps'
  ]
  s.required_ruby_version = '>= 3.1.2'
  s.add_dependency 'fileutils', '~> 1.6.0'
  s.add_dependency 'gosu', '~> 1.4.3'
  s.add_dependency 'os', '~> 1.0.1'
  s.add_dependency 'rspec', '~> 3.9.0'
  s.add_dependency 'rubyzip', '~> 2.3.0'
  s.homepage    = 'https://github.com/chichilku/chichilku3'
  s.license     = 'Unlicense'
  s.metadata['rubygems_mfa_required'] = 'true'
end
