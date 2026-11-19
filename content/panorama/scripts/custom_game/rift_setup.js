"use strict";
var RiftSetup={signature:"",starting:false};
function RiftSetupHost(){var p=Game.GetLocalPlayerInfo();return !!p&&!!p.player_has_host_privileges;}
function RiftSetupAssign(){if(RiftSetupHost()&&!Game.GetTeamSelectionLocked())Game.AutoAssignPlayersToTeams();}
function RiftSetupStart(){
  if(!RiftSetupHost())return;
  if(Game.GetTeamSelectionLocked()) {
    Game.SetRemainingSetupTime(-1);Game.SetTeamSelectionLocked(false);RiftSetup.starting=false;
  } else {
    Game.AutoAssignPlayersToTeams();Game.SetAutoLaunchEnabled(false);Game.SetTeamSelectionLocked(true);
    Game.SetRemainingSetupTime(3);RiftSetup.starting=true;
  }
}
(function(){
 $("#SetupLogo").SetImage("file://{images}/custom_game/duality_logo.png");
 function render(){
  var screen=$("#SetupScreen"),host=screen.GetParent();
  var container=host.GetParent();
  if(container&&container.style){container.style.margin="0px";container.style.padding="0px";container.style.width="100%";container.style.height="100%";}
  if(host.actuallayoutheight>0){var fit=RiftUIModel.canvasScale(host.actuallayoutwidth,host.actuallayoutheight,1600,920);screen.style.transform="scale3d("+fit+","+fit+",1)";}
  var setup=Game.GetState()===DOTA_GameState.DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP;
  $("#SetupScreen").GetParent().SetHasClass("Closed",!setup);
  if(!setup){$.Schedule(.25,render);return;}
  var settings=CustomNetTables.GetTableValue("rift_match","settings")||{},teams=RiftUIModel.array(settings.teams);
  if(!teams.length)teams=Game.GetAllTeamIDs();
  var count=Game.GetAllPlayerIDs().length,max=settings.max_players||teams.length;
  $("#SetupCount").text=count+" / "+max+"   "+$.Localize("#rift_setup_players");
  var host=RiftSetupHost(),locked=Game.GetTeamSelectionLocked();
  $("#SetupStart").enabled=host&&count>0;$("#SetupAssign").enabled=host&&!locked;
  var remaining=Math.max(0,Math.ceil(Game.GetStateTransitionTime()-Game.GetGameTime()));
  $("#SetupStartLabel").text=$.Localize(locked?"#rift_setup_cancel":"#rift_setup_start");
  $("#SetupStatus").text=locked?$.Localize("#rift_setup_countdown")+" "+remaining:$.Localize(host?"#rift_setup_host_hint":"#rift_setup_wait_host");
  var unassigned=Game.GetUnassignedPlayerIDs().map(function(id){return Players.GetPlayerName(id);});
  $("#SetupUnassigned").text=unassigned.length?$.Localize("#rift_setup_unassigned")+" "+unassigned.join(", "):"";
  var rows=teams.slice(0,max).map(function(team,i){var ids=Game.GetPlayerIDsOnTeam(team);return {team:team,seat:i+1,pid:ids.length?ids[0]:-1};});
  var signature=JSON.stringify(rows)+":"+locked;
  if(signature!==RiftSetup.signature){
   RiftSetup.signature=signature;var grid=$("#SetupSeats");grid.RemoveAndDeleteChildren();
   var seatRow;
   rows.forEach(function(row,index){
    if(index%2===0){seatRow=$.CreatePanel("Panel",grid,"");seatRow.AddClass("SetupSeatRow");}
    var p=$.CreatePanel("Button",seatRow,"");p.AddClass("SetupSeat");p.SetHasClass("Empty",row.pid<0);p.SetHasClass("Self",row.pid===Players.GetLocalPlayer());
    var number=$.CreatePanel("Label",p,"");number.AddClass("SetupSeatNumber");number.text=(row.seat<10?"0":"")+row.seat;
    if(row.pid>=0){var info=Game.GetPlayerInfo(row.pid);var avatar=$.CreatePanel("DOTAAvatarImage",p,"");avatar.AddClass("SetupAvatar");avatar.steamid=info.player_steamid;}
    var text=$.CreatePanel("Panel",p,"");text.AddClass("SetupSeatInfo");var name=$.CreatePanel("Label",text,"");name.AddClass("SetupPlayerName");name.text=row.pid>=0?Players.GetPlayerName(row.pid):$.Localize("#rift_setup_empty");
    var status=$.CreatePanel("Label",text,"");status.AddClass("SetupPlayerStatus");status.text=$.Localize(row.pid<0?"#rift_setup_join":row.pid===Players.GetLocalPlayer()?"#rift_setup_you":"#rift_setup_ready");
    p.enabled=!locked&&(row.pid<0||row.pid===Players.GetLocalPlayer());p.SetPanelEvent("onactivate",function(){if(!Game.GetTeamSelectionLocked())Game.PlayerJoinTeam(row.team);});
   });
  }
  $.Schedule(.25,render);
 }
 render();
})();
