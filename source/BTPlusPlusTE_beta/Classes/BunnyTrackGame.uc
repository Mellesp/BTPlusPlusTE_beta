//=============================================================================
// BunnyTrackGame made by OwYeaW
//=============================================================================
class BunnyTrackGame extends CTFGame;

var BTPlusPlus Controller;

function ProcessServerTravel( string URL, bool bItems )
{
	DeathMatchPlus(Level.Game).SaveConfig();
	Super.ProcessServerTravel(URL, bItems);
}

function ScoreFlag(Pawn Scorer, CTFFlag theFlag)
{
	local pawn TeamMate;
	local Actor A;

	if ( Scorer.PlayerReplicationInfo.Team == theFlag.Team || Scorer.Health < 1 || Scorer.AttitudeToPlayer == ATTITUDE_Follow)
		return;

	Controller.BTCapture( Scorer );
	Teams[Scorer.PlayerReplicationInfo.Team].Score += 1.0;

	if ( bRatedGame && Scorer.IsA('PlayerPawn') )
		bFulfilledSpecial = true;

	for ( TeamMate=Level.PawnList; TeamMate!=None; TeamMate=TeamMate.NextPawn )
	{
		if ( TeamMate.IsA('PlayerPawn') )
			PlayerPawn(TeamMate).ClientPlaySound(CaptureSound[Scorer.PlayerReplicationInfo.Team]);
		else if ( TeamMate.IsA('Bot') )
			Bot(TeamMate).SetOrders(BotReplicationInfo(TeamMate.PlayerReplicationInfo).RealOrders, BotReplicationInfo(TeamMate.PlayerReplicationInfo).RealOrderGiver, true);
	}

	if (Level.Game.WorldLog != None)
		Level.Game.WorldLog.LogSpecialEvent("flag_captured", Scorer.PlayerReplicationInfo.PlayerID, Teams[theFlag.Team].TeamIndex);
	if (Level.Game.LocalLog != None)
		Level.Game.LocalLog.LogSpecialEvent("flag_captured", Scorer.PlayerReplicationInfo.PlayerID, Teams[theFlag.Team].TeamIndex);

	EndStatsClass.Default.TotalFlags++;
	BroadcastLocalizedMessage( class'CTFMessage', 0, Scorer.PlayerReplicationInfo, None, TheFlag );
	if ( theFlag.HomeBase.Event != '' )
		foreach allactors(class'Actor', A, theFlag.HomeBase.Event )
			A.Trigger(theFlag.HomeBase,	Scorer);

	if ( (bOverTime || (GoalTeamScore != 0)) && (Teams[Scorer.PlayerReplicationInfo.Team].Score >= GoalTeamScore) )
		EndGame("teamscorelimit");
	else if ( bOverTime )
		EndGame("timelimit");

	Scorer.Velocity = vect(0,0,0);
	Scorer.Acceleration = vect(0,0,0);
	Scorer.SetPhysics(PHYS_None);
	Scorer.SetLocation(Scorer.Location);
	Scorer.bBlockPlayers = False;
	Scorer.SetCollision(False);
	Scorer.Weapon.bCanThrow = false; // just in case someone doesn't play with Insta

	if (!Level.Game.bGameEnded)
	{
		Level.Game.DiscardInventory(Scorer);
		Scorer.bHidden = True;
		Scorer.SoundDampening = 0.5;
		Scorer.GoToState('Dying');
		Spawn(class'UTTeleportEffect',Scorer,, Scorer.Location, Scorer.Rotation);
	}
}

function bool RestartPlayer( pawn aPlayer )
{
	local NavigationPoint startSpot;
	local bool foundStart;

	if( bRestartLevel && Level.NetMode!=NM_DedicatedServer && Level.NetMode!=NM_ListenServer )
		return true;

	startSpot = FindPlayerStart(aPlayer, 255);
	if( startSpot == None )
	{
		log(" Player start not found!!!");
		return false;
	}
	foundStart = aPlayer.SetLocation(startSpot.Location);
	if( foundStart )
	{
		startSpot.PlayTeleportEffect(aPlayer, true);
		aPlayer.SetRotation(startSpot.Rotation);
		aPlayer.ViewRotation = aPlayer.Rotation;
		aPlayer.Acceleration = vect(0,0,0);
		aPlayer.Velocity = vect(0,0,0);
		aPlayer.SetPhysics(PHYS_Falling);	// ANTI SPAWNJUMP
		aPlayer.Health = aPlayer.Default.Health;
		aPlayer.SetCollision( true, true, true );
		aPlayer.ClientSetLocation( startSpot.Location, startSpot.Rotation );
		aPlayer.bHidden = false;
		aPlayer.DamageScaling = aPlayer.Default.DamageScaling;
		aPlayer.SoundDampening = aPlayer.Default.SoundDampening;
		AddDefaultInventory(aPlayer);
	}
	else
		log(startspot$" Player start not useable!!!");
	return foundStart;
}

function bool SetEndCams(string Reason)
{
	if (DeathMatchPlus(Level.Game).bTournament)
		CalcEndStats();
	return false;
}

function CalcEndStats()
{
	EndStatsClass.Default.TotalGames++;
	EndStatsClass.Static.StaticSaveConfig();
}

defaultproperties
{
	StartMessage=
	ScoreBoardType=BTScoreboard
	HUDType=BTHUD
	GameName="BunnyTrack"
}