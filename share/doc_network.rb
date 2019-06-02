# pSTATUS is a status of the current protocol
# Different status codes:
# 'l' lonley single packet
# 's' start package of a series
# 'e' end of a series
# '1','2','3',..,'9' index of current series

# gamestates:
# g = default ingame state
# f = failure/error gamestate
# e = round end gamestate (somebody won)

####################
# Client packages: #
####################
# ----------------------------------------------------------------------------------------
# Update package
# Error package (not used yet)
# prot  pSTATUS errorcode
# 0     l       00000
#
# ----------------------------------------------------------------------------------------
# ID request package
# prot pSTATUS  username (prot=0 is the join protocol)
# 1     l        00000
#
# ----------------------------------------------------------------------------------------
# id move requests
# prot  pSTATUS id xlrj (x = spaceformore/left/right/jump)
# 2     l       0  0000
#
# ----------------------------------------------------------------------------------------
# request usernames (resets positions ->  should happen 1time at join)
# prot  pSTATUS id version
# 3     l       0  0000
#
# ----------------------------------------------------------------------------------------
# cmd send
# prot  pSTATUS id  message
# 4     l       0   0000

####################
# Server packages: #
####################
# Error package (404=server full)
# prot  pSTATUS   errorcode place for more
# 0     l         404       00000000000000000000000
#
# ----------------------------------------------------------------------------------------
# Update package
#                                player1           player2           player3
#                                     |                  |                 |
#                                 ___/ \_______     ____/ \______     ____/ \______
#                                /             \   /             \   /             \
# prot  pSTATUS     playercount  id    posx posy   id    posx posy   id    posx posy
# |     |           |  gamestate | score |   |     | score |   |     | score |
# |     |           |  |         | |     |   |     | |     |   |     | |     | 
# 1     l           0  g         1 0   000  000    2 0   000  000    3 0   000  000
#
# ----------------------------------------------------------------------------------------
# Set ID package
# prot  pSTATUS     playercount ID  version Place for more info
# 2     l           03          01  0000    000000000000000000
#
# ----------------------------------------------------------------------------------------
# Username package
#                                player1     player2     player3
#                                     |          |           |
#                                 ___/ \__    __/ \___    __/ \___
#                                /        \  /        \  /        \
# prot  pSTATUS     playercount  id    name  id    name  id    name  empty
# |     |           |  gamestate | score |   | score |   | score |    |
# |     |           |  |         | |     |   | |     |   | |     |    |
# 3     l           3  g         1 0   00000 2 0   00000 3 0   00000 000
#
# ----------------------------------------------------------------------------------------
# cmd response package ( TODO: implement it client side only prints in console for now )
# prot  pSTATUS     response
# 4     l           00000000000000000000000000
#
# ----------------------------------------------------------------------------------------
# Event package
# prot  pSTATUS eventcode event-details
# 5     l       x         0000000000000000000000000
#               EVENTS:
#  death:       eventcode x   y   place-for-more
#               d         000 000 0000000000000000000
