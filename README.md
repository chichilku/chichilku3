# chichilku3
Part 3 of the chichilku series written in ruby.
Simple 2d multiplayer stick figure battle game.
![Demo Picture](screenshots/chichilku3.png)

# Setup

## macOS

```
brew install sdl2
git clone https://github.com/chichilku/chichilku3
cd chichilku3
bundle install
```

## linux (debian/ubuntu)

```
sudo apt install git libfontconfig1-dev libsndfile1-dev libsdl2-dev libmpg123-dev libopenal1 libopenal-dev
git clone https://github.com/chichilku/chichilku3
cd chichilku3
bundle install
```

# Running

## client

``ruby client/game.rb``

## server

``ruby server/server.rb``

# testing

```
rspec
```

# license

The whole code base and all images are licensed under public domain.
All graphics were handcrafted by [ChillerDragon](https://github.com/ChillerDragon) same goes for the code.
You are free to use any of it for anything. You are free to copy/redistribute/sell/edit this project without any limitations.


Credit is appreciated but not required.
