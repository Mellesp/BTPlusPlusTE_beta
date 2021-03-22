# BTPlusPlusTE_beta
BT++ Tournament Edition beta

*Customized BT++ specifically designed for cups/pugs/tournament mode*

![Scoreboard](https://cdn.discordapp.com/attachments/710812298847060002/823614285157892126/unknown.png)

## Features
### General
- removed most of the nonsense
- no multi flags
- normal player collisions

### HUD
- clean hud
- jump boots charges shown
- BT timer shows timer of player you're spectating/F5'ing

### Scoreboard
- "Smart" BT scoreboard
- shows whether its in practice mode or tournament mode
- shows tournament settings etc
- shows server record & personal record in bottom corners

### BT Checkpoints
- checkpoints are enabled in practice mode (bTournament=false)
- also has !moveto <playername> feature

### Spectator
- suicide key lets you toggle to move through walls or not
- jump key when spectating a player releases you in free cam
- alt fire key when in free cam lets you spectate the player you aim at
- throw weapon key sends you to location you aim at
- grab key sends you 1500 units forward
- console command "chase player1" lets you specate player1
- increased fly speed from 300 to 500
- spectators can now use teleporters

## Installation
```
ServerPackages=BTPPUser
ServerPackages=CountryFlags3
ServerPackages=BTPlusPlusTE_beta
ServerActors=BTPlusPlusTE_beta.BTPlusPlus
```
GameType = `BTPlusPlusTE_beta.BunnyTrackGame`

BTPlusPlusTE.ini:
```
[BTPlusPlusTE_beta.BTPlusPlus]
bSuddenDeath=True
bCarcasses=True
bSaveRecords=True
CountryFlagsPackage=CountryFlags3
bEnableCheckpointsInPracticeMode=True
```

## Ideas for changes
- on the scoreboard; let the timer meter be based off player best cap time vs match best cap time

## Known bugs
- XConsole overwrites the spectator Fire & Alt Fire functions

Let me know if you find any bugs, Discord: Melle#7511
