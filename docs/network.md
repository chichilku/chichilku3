### pStatus

pSTATUS is a status of the current message type
Different status codes:
'l' lonley single packet
's' start package of a series (not implemented)
'e' end of a series (not implemented)
'1','2','3',..,'9' index of current series (not implemented)

### gamestates

g = default ingame state
f = failure/error gamestate
e = round end gamestate (somebody won)

### encoding

most integers like aim, position, slots and playercount are base 91 encoded
player ids are encoded as single character hexadecimal numbers




# Client packages:
--------------------------------------------------------------------------------------------------------------
### Update package
```
Error package (not used yet)
type  pSTATUS errorcode
0     l       000000000
```

--------------------------------------------------------------------------------------------------------------
### ID request package
```
type    pSTATUS  version        unused (type=0 is the join type)
1       l        0000           00000
```

--------------------------------------------------------------------------------------------------------------
### move requests
```
        (crouch/dir l=left r=right/jump/fire)
type  pSTATUS id cdjf aimX aimY
2     l       0  0000 00   00
```

--------------------------------------------------------------------------------------------------------------
### request usernames (resets positions ->  should happen 1time at join)
```
type  pSTATUS username
3     l       000000000
```

--------------------------------------------------------------------------------------------------------------
### cmd send
```
type  pSTATUS id  command
4     l       0   00000000
```

--------------------------------------------------------------------------------------------------------------
### map info response
```
type  pSTATUS id  (accept=1 decline=0)    encoding(preffered)    encoding(supported)     unused
5     l       0   0                       b64                    1                       000
```




# Server packages

### Error package (404=server full)
```
type  pSTATUS   errorcode error message
0     l         404       00000000000000000000000000000000000000000000000
```

### Error package (004=server outdated)
```
type  pSTATUS   errorcode server version    error message
0     l         004       0002              0000000000000000000000000000000000000000000
```

### Error package (005=client outdated)
```
type  pSTATUS   errorcode server version    error message
0     l         005       0002              0000000000000000000000000000000000000000000
```

--------------------------------------------------------------------------------------------------------------
# Update package
```
                                           player (repeats depending on player count)
                                              |
                                _____________/ \______________________
                               /                                      \
type  pSTATUS     playercount  id                             posx posy
|     |           |  gamestate | score  projectileX    aimY   |   |
|     |           |  |         | |state     |projectileY |    |   |
|     |           |  |         | |   |projR | |    aimX  |    |   |
|     |           |  |         | |   ||     | |       |  |    |   |
1     l           0  g         1 0   00    00 00      00 00   00 00
```

player states:
b - blood splash
c - crouching
s - slipping (c+b)
1 - bow1
2 - bow2
3 - bow3
x - bow1 + blood
y - bow2 + blood
z - bow3 + blood

--------------------------------------------------------------------------------------------------------------
# Set ID package
```
type  pSTATUS     playercount   slots   ID      unused  version unused
2     l           0             3       1       1       0000    000000000000000000000000000000000000000000
```

--------------------------------------------------------------------------------------------------------------
# Username package
```
                               player1          player2        player3
                                    |              |              |
                                ___/ \__        __/ \___       __/ \___
                               /        \      /        \     /        \
type  pSTATUS     playercount  id    name      id    name     id    name     empty
|     |           |  gamestate | score |       | score |       | score |       |
|     |           |  |         | |     |       | |     |       | |     |       |
3     l           3  g         1 0   000000000 2 0   000000000 3 0   000000000 000000000000000
```

--------------------------------------------------------------------------------------------------------------
# cmd response package
```
type  pSTATUS     response
4     l           00000000000000000000000000000000000000000000000000
```

--------------------------------------------------------------------------------------------------------------
# map info package
```
type  pSTATUS     sha1sum(of the zipped map)               unused
5     l           fe6bb781c95a3d1da2867dc239defa08ff3aef6d 0000000000
```

--------------------------------------------------------------------------------------------------------------
# map download init package
```
type  pSTATUS     size(base91)         mapname(MAX_MAPNAME_LEN)
6     l           000000               00000000000000000000000000000000000000000000
```

--------------------------------------------------------------------------------------------------------------
# map download chunk package
```
type  pSTATUS     mapchunk(base64)
7     l           iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAIAAADZF8uwAAAACX
```
