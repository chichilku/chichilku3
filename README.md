# chichilku3
Part 3 of the chichilku series written in ruby.
Simple 2d multiplayer stick figure battle game.
![Demo Picture](screenshots/chichilku3.png)

# Installing as gem

```
# install binarys
gem install chichilku3

# run the server
chichilku3-server

# run the client
chichilku3
```

# Building from source

## macOS

```
brew install sdl2
git clone https://github.com/chichilku/chichilku3
cd chichilku3
bundle install
```

## linux

```
# debian
sudo apt install git libfontconfig1-dev libsndfile1-dev libsdl2-dev libmpg123-dev libopenal1 libopenal-dev

# ubuntu
sudo apt-get install build-essential libsdl2-dev libgl1-mesa-dev libopenal-dev libsndfile-dev libmpg123-dev libgmp-dev libfontconfig1-dev

# arch
sudo pacman -S openal pango sdl2 sdl2_ttf libsndfile pkg-config mpg123

# fedora
sudo dnf install --assumeyes mpg123-devel mesa-libGL-devel openal-devel libsndfile-devel gcc-c++ redhat-rpm-config SDL2-devel fontconfig-devel

git clone https://github.com/chichilku/chichilku3
cd chichilku3
bundle install
```

# Running

## Client

``ruby lib/client/chichilku3.rb``

## Server

``ruby lib/server/chichilku3_server.rb``

# Testing

```
rspec
```

# License

The whole code base and all images are licensed under public domain.
All graphics were handcrafted by [ChillerDragon](https://github.com/ChillerDragon) same goes for the code.
You are free to use any of it for anything. You are free to copy/redistribute/sell/edit this project without any limitations.
Without any warranty tho for more information see LICENSE file at the root of this repository.


Credit is appreciated but not required.
