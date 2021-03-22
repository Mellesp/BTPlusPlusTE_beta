//=============================================================================
// BTSpectator made by OwYeaW
//=============================================================================
class BTSpectator expands CHSpectator;

var bool bTouchingTele, GhostSpectator;
var int SpectatorSpeed, BehindViewDistance;

replication
{
	reliable if(Role < ROLE_Authority)
		JumpFrom, Chase, TeleSpec;
}
//=============================================================================
simulated event PostBeginPlay()
{
	if(Level.NetMode != NM_DedicatedServer)
		SetTimer(0.05, true);

	Super.PostBeginPlay();
}
//=============================================================================
// STATE CHEATFLYING
//=============================================================================
state CheatFlying
{
ignores SeePlayer, HearNoise, Bump, TakeDamage;

	function AnimEnd()
	{
		PlaySwimming();
	}

	function ProcessMove(float DeltaTime, vector NewAccel, eDodgeDir DodgeMove, rotator DeltaRot)
	{
		Acceleration = Normal(NewAccel);
		Velocity = Normal(NewAccel) * SpectatorSpeed;
		AutonomousPhysics(DeltaTime);
	}

	event PlayerTick( float DeltaTime )
	{
		if ( bUpdatePosition )
			ClientUpdatePosition();

		PlayerMove(DeltaTime);
	}

	function PlayerMove(float DeltaTime)
	{
		local rotator newRotation;
		local vector X,Y,Z;

		GetAxes(ViewRotation,X,Y,Z);

		aForward *= 0.1;
		aStrafe  *= 0.1;
		aLookup  *= 0.24;
		aTurn    *= 0.24;
		aUp		 *= 0.1;

		Acceleration = aForward*X + aStrafe*Y + aUp*vect(0,0,1);  

		UpdateRotation(DeltaTime, 1);

		if(Role < ROLE_Authority) // then save this move and replicate it
			ReplicateMove(DeltaTime, Acceleration, DODGE_None, rot(0,0,0));
		else
			ProcessMove(DeltaTime, Acceleration, DODGE_None, rot(0,0,0));
	}

	function BeginState()
	{
		EyeHeight = BaseEyeHeight;
		SetPhysics(PHYS_Flying);
		if(!IsAnimating())
			PlaySwimming();
	}
}
//=============================================================================
// 3RD PERSON VIEW STUFF
//=============================================================================
function CalcBehindView(out vector CameraLocation, out rotator CameraRotation, float Dist)
{
	local vector View, HitLocation, HitNormal;
	local float ViewDist;

	CameraRotation = ViewRotation;
	View = vect(1,0,0) >> CameraRotation;
	if( Trace( HitLocation, HitNormal, CameraLocation - (Dist + 30) * vector(CameraRotation), CameraLocation ) != None )
		ViewDist = FMin( (CameraLocation - HitLocation) Dot View, Dist );
	else
		ViewDist = Dist;
	CameraLocation -= (ViewDist - 30) * View; 
}
event PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
{
	local Pawn PTarget;

	if(ViewTarget != None)
	{
		ViewActor = ViewTarget;
		CameraLocation = ViewTarget.Location;
		CameraRotation = ViewTarget.Rotation;
		PTarget = Pawn(ViewTarget);
		if(PTarget != None)
		{
			if(Level.NetMode == NM_Client)
			{
				if(PTarget.bIsPlayer)
					PTarget.ViewRotation = TargetViewRotation;
				PTarget.EyeHeight = TargetEyeHeight;
				if(PTarget.Weapon != None)
					PTarget.Weapon.PlayerViewOffset = TargetWeaponViewOffset;
			}
			if(PTarget.bIsPlayer)
				CameraRotation = PTarget.ViewRotation;
			if(!bBehindView)
				CameraLocation.Z += PTarget.EyeHeight;
		}
		if(bBehindView)
			CalcBehindView(CameraLocation, CameraRotation, BehindViewDistance);
		return;
	}

	ViewActor = Self;
	CameraLocation = Location;

	// First-person view.
	CameraRotation = ViewRotation;
	CameraLocation.Z += EyeHeight;
	CameraLocation += WalkBob;
}
//=============================================================================
// TELEPORTER STUFF
//=============================================================================
simulated function Timer()
{
	local Teleporter Tele;
	local bool bTeleFound;

	foreach VisibleCollidingActors(class'Teleporter', Tele, 39, Location, false)
	{
		if(!bTouchingTele)
		{
			TeleSpec(Tele);
			bTouchingTele = true;
		}
		bTelefound = true;
	}
	if(!bTelefound && bTouchingTele)
		bTouchingTele = false;
}
function TeleSpec(Teleporter Tele)
{
	local rotator newRot;
	local Teleporter Dest;
	local int i;

	if(Tele.bEnabled && Tele.URL != "")
	{
		if( (InStr( Tele.URL, "/" ) >= 0) || (InStr( Tele.URL, "#" ) >= 0) )
		{
			// Teleport to a level on the net.
			if(Role == ROLE_Authority)
				Level.Game.SendPlayer(Self, Tele.URL);
		}
		else
		{
			foreach AllActors(class'Teleporter', Dest)
				if(string(Dest.tag) ~= Tele.URL && Dest != Tele)
					i++;

			i = rand(i);
			foreach AllActors(class'Teleporter', Dest)
				if(string(Dest.tag) ~= Tele.URL && Dest != Tele && i-- == 0 )
					break;

			if(Dest != None)
			{
				newRot = Rotation;
				if(Dest.bChangesYaw)
				{
					newRot.Yaw = Dest.Rotation.Yaw;
					newRot.Yaw += (32768 + Rotation.Yaw - Tele.Rotation.Yaw);
				}
				SetLocation(Dest.Location);
				if(Role == ROLE_Authority)
				{
					SetRotation(newRot);
					ViewRotation = newRot;
				}
			}
			else if(Role == ROLE_Authority)
				ClientMessage( "Teleport destination for "$Tele$" not found!" );
		}
	}
}
//=============================================================================
// EXEC FUNCTIONS
//=============================================================================
// Alt Fire function taken from Higor's XC_Spec_r10 and modified
//=============================================================================
exec function AltFire(optional float F)
{
	local vector HitLocation, HitNormal;
	local Actor Other;

	if(ViewTarget != None)
	{
		bBehindView = false;
		Viewtarget = None;
	}
	else if(Level.NetMode != NM_Client)	//Server sets this one, prevents ACE kick
	{
		Other = Trace(HitLocation, HitNormal, Location + vector(ViewRotation) * 15000, Location, true);
		if(Pawn(Other) != None)
		{
			ViewTarget = Other;
			bBehindView = bChaseCam;
			ViewTarget.BecomeViewTarget();
		}
	}
}
//=============================================================================
// Jump function taken from Higor's XC_Spec_r10 and modified
//=============================================================================
exec function Jump(optional float F)
{
	if(Pawn(ViewTarget) != None)
		JumpFrom();
	else if(F != 0)
		Super.Jump(F);
}
function JumpFrom()
{
	local vector camLoc, View, HitLocation, HitNormal;
	local float ViewDist;
	local rotator camRot;

	camLoc = ViewTarget.Location;
	camRot = ViewRotation;

	if(!bBehindView)
	{
		ClientSetRotation(Pawn(ViewTarget).ViewRotation);
		ViewRotation = Pawn(ViewTarget).ViewRotation;
		camLoc.Z += Pawn(ViewTarget).EyeHeight;
	}
	else
	{
		View = vect(1,0,0) >> camRot;
		if( Trace( HitLocation, HitNormal, camLoc - (BehindViewDistance + 30) * vector(camRot), camLoc ) != None )
			ViewDist = FMin( (camLoc - HitLocation) Dot View, BehindViewDistance );
		else
			ViewDist = BehindViewDistance;
		camLoc -= (ViewDist - 30) * View;
	}

	SetLocation(camLoc);
	bBehindView = false;
	ViewTarget = None;
}
// Chase function taken from Higor's XC_Spec_r10 and modified
//=============================================================================
exec function Chase(string aPlayer)
{
	local PlayerReplicationInfo PRI;

	if(Level.NetMode != NM_CLient && aPlayer != "")
	{
		ForEach AllActors(class'PlayerReplicationInfo', PRI)
		{
			if(PRI.PlayerName != "Player" && InStr(Caps(PRI.PlayerName), Caps(aPlayer)) >= 0)
			{
				ViewTarget = PRI.Owner;
				bBehindView = true;
				return;
			}
		}
	}
}
// ThrowWeapon/Suicide function taken from Higor's XC_Spec_r10 and modified
//=============================================================================
exec function ThrowWeapon()
{
	local vector HitLocation, HitNormal;

	if(Level.NetMode != NM_Client) //Server sets this one, prevents ACE kick
	{
		if(Pawn(ViewTarget) == None)
		{
			Trace(HitLocation, HitNormal, Location + vector(ViewRotation) * 15000);
			if( HitLocation != vect(0,0,0) )
				SetLocation(HitLocation + HitNormal * 5);
		}
	}
}
// Suicide - Toggle GhostSpectator Mode
//=============================================================================
exec function Suicide()
{
	bCollideWorld = !bCollideWorld;
	GhostSpectator = !GhostSpectator;
}
// Fly function taken from Spectator.uc and modified
//=============================================================================
exec function Fly()
{
	UnderWaterTime = -1;
	GotoState('CheatFlying');
	ClientRestart();
}
// Possess function taken from Spectator.uc and modified
//=============================================================================
function Possess()
{
	bIsPlayer = true;
	DodgeClickTime = FMin(0.3, DodgeClickTime);
	EyeHeight = BaseEyeHeight;
	NetPriority = 2;
	Weapon = None;
	Inventory = None;
	Fly();
}
// Grab - Teleport 1500 units forward
//=============================================================================
exec function Grab()
{
	if(Level.NetMode != NM_Client) //Server sets this one, prevents ACE kick
		if(Pawn(ViewTarget) == None)
			SetLocation(Location + vector(ViewRotation) * 1500);
}
//=============================================================================
// REMOVE SPAMMY CLIENTMESSAGES
//=============================================================================
exec function ViewPlayerNum(optional int num)
{
	local Pawn P;

	if(!PlayerReplicationInfo.bIsSpectator && !Level.Game.bTeamGame)
		return;

	if(num >= 0)
	{
		P = Pawn(ViewTarget);
		if(P != None && P.bIsPlayer && P.PlayerReplicationInfo.TeamID == num)
		{
			ViewTarget = None;
			bBehindView = false;
			return;
		}
		for(P = Level.PawnList; P != None; P = P.NextPawn)
		{
			if(P.PlayerReplicationInfo != None && P.PlayerReplicationInfo.Team == PlayerReplicationInfo.Team && !P.PlayerReplicationInfo.bIsSpectator && P.PlayerReplicationInfo.TeamID == num )
			{
				if(P != Self)
				{
					ViewTarget = P;
					bBehindView = true;
				}
				return;
			}
		}
		return;
	}
	if(Role == ROLE_Authority)
	{
		ViewClass(class'Pawn', true);
		While( ViewTarget != None && (!Pawn(ViewTarget).bIsPlayer || Pawn(ViewTarget).PlayerReplicationInfo.bIsSpectator) )
			ViewClass(class'Pawn', true);
	}
}
exec function ViewPlayer(string S)
{
	local pawn P;

	for(P = Level.pawnList; P != None; P = P.NextPawn)
		if(P.bIsPlayer && P.PlayerReplicationInfo.PlayerName ~= S)
			break;
	if( P != None && Level.Game.CanSpectate(Self, P) )
	{
		if(P == Self)
			ViewTarget = None;
		else
			ViewTarget = P;
	}
	bBehindView = ViewTarget != None;
	if(bBehindView)
		ViewTarget.BecomeViewTarget();
}
exec function CheatView(class<actor> aClass)
{
	local actor Other, First;
	local bool bFound;

	if(!bCheatsEnabled)
		return;
	if(!bAdmin && Level.NetMode != NM_Standalone)
		return;
	First = None;
	ForEach AllActors(aClass, Other)
	{
		if(First == None && Other != Self)
		{
			First = Other;
			bFound = true;
		}
		if(Other == ViewTarget)
			First = None;
	}
	if(First != None)
		ViewTarget = First;
	else
		ViewTarget = None;
	bBehindView = ViewTarget != None;
	if(bBehindView)
		ViewTarget.BecomeViewTarget();
}
exec function ViewSelf()
{
	bBehindView = false;
	Viewtarget = None;
}
exec function ViewClass(class<actor> aClass, optional bool bQuiet)
{
	local actor Other, First;
	local bool bFound;

	if(Level.Game != None && !Level.Game.bCanViewOthers)
		return;
	First = None;
	ForEach AllActors(aClass, Other)
	{
		if( First == None && Other != Self && ( (bAdmin && Level.Game == None) || Level.Game.CanSpectate(Self, Other) ) )
		{
			First = Other;
			bFound = true;
		}
		if(Other == ViewTarget)
			First = None;
	}
	if(First != None)
		ViewTarget = First;
	else
		ViewTarget = None;
	bBehindView = ViewTarget != None;
	if(bBehindView)
		ViewTarget.BecomeViewTarget();
}
//=============================================================================
// Default Properties
//=============================================================================
defaultproperties
{
	Texture=None
	bCollideActors=False
	bCollideWorld=True
	bBlockActors=False
	bBlockPlayers=False
	bProjTarget=False
	AirSpeed=12000
	GhostSpectator=False
	SpectatorSpeed=500
	BehindViewDistance=180
}