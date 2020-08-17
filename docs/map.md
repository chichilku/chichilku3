# Filesystem

## server

The server expects a map directory at

    ~/.chichilku/chichilku3/maps/mapname

And on server start it creates a zip at

    ~/.chichilku/chichilku3/maps/mapname.zip

And a base64 encoded txt file of the zp at

    ~/.chichilku/chichilku3/maps_b64/mapname_checksum.zip

## client

The client downloads the base64 encoded zip chunk by chunk to

    ~/.chichilku/chichilku3/tmp/mapname

On finish it is exctracted and moved to

    ~/.chichilku/chichilku3/downloadedmaps/mapname_checksum



# Structure

The map is a directory containing:

- background.png (16:9 background image)
- gametiles.txt (ascii representation of the gametiles)

## background.png

1024x512 is the expected resolution

## gametiles.txt

A map consists of 16x9 tiles and no other format is allowed

gametiles:
  `X`     kill tile
  `O`     collision
  ` `     air

The gametiles are surrounded by + - and | to better work with spaces

A sample map could look like this:

gametiles.txt
```
+----------------+
|                |
|                |
|                |
|                |
|                |
|    OOOOOOOOO   |
|    OOOOOOOOO   |
|XXXXXXXXXXXXXXXX|
|XXXXXXXXXXXXXXXX|
+----------------+
```
