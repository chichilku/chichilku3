# Map Version 1

## Filesystem

### server

The server expects a map directory at

    ~/.chichilku/chichilku3/maps/mapname

And on server start it creates a zip at

    ~/.chichilku/chichilku3/maps/mapname.zip

And a base64 encoded txt file of the zip at

    ~/.chichilku/chichilku3/maps_b64/mapname_checksum.zip

### client

The client downloads the base64 encoded zip chunk by chunk to

    ~/.chichilku/chichilku3/tmp/mapname

On finish it is extracted and moved to

    ~/.chichilku/chichilku3/downloadedmaps/mapname_checksum



## Structure

The map is a directory containing:

 - background.png (16:9 background image)
 - gametiles.txt (ascii representation of the gametiles)
 - metadata.json (json data about the map)

It can also contain other files such as .xcf source files for the background image.
Any other file than the ones required for the map will be ignored by the server and not sent to the client.


Example maps directory:

    maps
    └── battle
       ├── background.png
       ├── battle1024x576.xcf
       ├── gametiles.txt
       └── metadata.json

### background.png

1024x576 is the expected resolution

### gametiles.txt

A map consists of 16x9 tiles and no other format is allowed

gametiles:

    'X'     kill tile
    'O'     collision
    ' '     air

The gametiles are surrounded by + - and | to better work with spaces

A sample gametiles file could look like this:

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

### metadata.json

The metadata for the map is stored in json format.

* Required keys by client and server:
    + chichilku3-map-version
        - integer: map standard version (should always be 1 for version 1)

* Keys displayed by the server and client are:
    + name
        - string: map name
    + version
        - string: map version
    + authors
        - array of strings: names of the map authors

* Optional non used keys are:
    + license
        - string
    + chichilku3-version
        - string: game version

metadata.json
```json
{
    "name": "battle",
    "version": "1.0",
    "authors": ["ChillerDragon"],
    "license": "Unlicense",
    "chichilku3-version": "0015",
    "chichilku3-map-version": 1
}
```
