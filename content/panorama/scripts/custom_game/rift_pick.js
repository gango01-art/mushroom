"use strict";
var RiftPick = { roster:[], hero:null, path:"physical", pending:false, confirmed:false, state:null };
function RiftPickHero(name) {
  if (RiftPick.pending || RiftPick.confirmed) return;
  for(var i=0;i<RiftPick.roster.length;i++) if(RiftPick.roster[i].hero===name) RiftPick.hero=RiftPick.roster[i];
  RiftPickRender();
}
function RiftPickPath(path) { if(path!=="physical"&&path!=="magical") return; RiftPick.path=path; RiftPickRender(); }
function RiftPickRender() {
  var h=RiftPick.hero;if(!h)return;
  $("#PickPortrait").heroname=h.hero;
  $("#PickHeroName").text=$.Localize("#"+h.hero);
  var d=h[RiftPick.path];
  $("#PickDetails").SetHasClass("Magical",RiftPick.path==="magical");
  $("#PickPathName").text=$.Localize("#"+d.name);
  $("#PickDescription").text=$.Localize("#"+d.desc);
  $("#PickPhysical").SetHasClass("Selected",RiftPick.path==="physical");
  $("#PickMagical").SetHasClass("Selected",RiftPick.path==="magical");
  $("#PickHeroes").Children().forEach(function(group){group.Children()[1].Children().forEach(function(p){p.SetHasClass("Selected",p.hero===h.hero);});});
  var icons=$("#PickAbilities");icons.RemoveAndDeleteChildren();
  RiftUIModel.array(d.abilities||h.abilities).forEach(function(name){
    var icon=$.CreatePanel("DOTAAbilityImage",icons,"");icon.abilityname=name;icon.AddClass("PickAbility");
    icon.SetPanelEvent("onmouseover",function(){$.DispatchEvent("DOTAShowAbilityTooltip",icon,name);});
    icon.SetPanelEvent("onmouseout",function(){$.DispatchEvent("DOTAHideAbilityTooltip",icon);});
  });
  $("#PickConfirm").enabled=!RiftPick.pending&&!RiftPick.confirmed;
}
function RiftPickRoster(data) {
  if(!data)return;
  RiftPick.roster=RiftUIModel.array(data.heroes);
  var grid=$("#PickHeroes");grid.RemoveAndDeleteChildren();
  ["strength","agility","intelligence","universal"].forEach(function(attr){
    var heroes=RiftPick.roster.filter(function(h){return (h.attribute||"strength")===attr;});
    if(!heroes.length)return;
    var group=$.CreatePanel("Panel",grid,"");group.AddClass("PickGroup");group.AddClass(attr);
    var header=$.CreatePanel("Panel",group,"");header.AddClass("PickGroupHeader");
    var attributeIcon=$.CreatePanel("Image",header,"");attributeIcon.AddClass("PickAttributeIcon");
    attributeIcon.SetImage("file://{images}/primary_attribute_icons/primary_attribute_icon_"+(attr==="universal"?"all":attr)+".psd");
    var title=$.CreatePanel("Label",header,"");title.AddClass("PickGroupTitle");title.text=$.Localize("#rift_attribute_"+attr);
    var row=$.CreatePanel("Panel",group,"");row.AddClass("PickGroupRow");
    heroes.forEach(function(h){
      var p=$.CreatePanel("Button",row,"");p.AddClass("PickHero");p.hero=h.hero;
      var img=$.CreatePanel("DOTAHeroImage",p,"");img.heroname=h.hero;img.heroimagestyle="portrait";
      var movie=null;
      p.SetPanelEvent("onmouseover",function(){
        if(movie)return;movie=$.CreatePanel("DOTAHeroMovie",p,"");movie.AddClass("PickHeroMovie");movie.hittest=false;movie.heroname=h.hero;
      });
      p.SetPanelEvent("onmouseout",function(){if(movie){movie.DeleteAsync(0);movie=null;}});
      var label=$.CreatePanel("Label",p,"");label.text=$.Localize("#"+h.hero);
      p.SetPanelEvent("onactivate",function(){RiftPickHero(h.hero);});
    });
  });
  if(!RiftPick.hero&&RiftPick.roster.length)RiftPick.hero=RiftPick.roster[0];
  RiftPickRender();
}
function RiftPickPlayers(data) {
  if(!data)return;
  var rows=RiftUIModel.array(data.players),parent=$("#PickPlayers"),local=Players.GetLocalPlayer();
  parent.RemoveAndDeleteChildren();
  for(var i=0;i<(data.max_players||8);i++) {
    var row=rows[i],cell=$.CreatePanel("Panel",parent,"");cell.AddClass("PickPlayer");
    if(!row) {cell.AddClass("Empty");var empty=$.CreatePanel("Label",cell,"");empty.AddClass("PickEmpty");empty.text=$.Localize("#rift_pick_empty");continue;}
    cell.SetHasClass("Self",row.pid===local);cell.SetHasClass("Ready",!!row.hero);
    var portrait=$.CreatePanel("DOTAHeroImage",cell,"");portrait.AddClass("PickPlayerPortrait");
    if(row.hero)portrait.heroname=row.hero;
    var info=$.CreatePanel("Panel",cell,"");info.AddClass("PickPlayerInfo");
    var name=$.CreatePanel("Label",info,"");name.AddClass("PickPlayerName");name.text=Players.GetPlayerName(row.pid);
    var state=$.CreatePanel("Label",info,"");state.AddClass("PickPlayerState");state.text=row.hero?$.Localize("#"+row.hero):$.Localize("#rift_pick_"+(row.status==="loading"?"loading_short":"choosing"));
    if(row.pid===local&&row.hero) {RiftPick.confirmed=true;RiftPick.pending=false;$("#PickStatus").text=$.Localize("#rift_pick_selected");}
  }
  RiftPickRender();
}
function RiftPickConfirm() {
  if(!RiftPick.hero||RiftPick.pending||RiftPick.confirmed)return;
  RiftPick.pending=true;$("#PickStatus").text=$.Localize("#rift_pick_loading");RiftPickRender();
  GameEvents.SendCustomGameEventToServer("rift_pick_hero",{hero:RiftPick.hero.hero});
}
function RiftPickResult(ev) {
  RiftPick.pending=ev.status==="loading";RiftPick.confirmed=ev.status==="selected";
  $("#PickStatus").text=$.Localize("#rift_pick_"+(ev.status==="selected"?"selected":ev.status==="loading"?"loading":"error"));
  RiftPickRender();
}
function RiftPickState(data) {
  if(!data)return;RiftPick.state=data;
  var screen=$("#PickScreen"),host=screen.GetParent();
  if(host.actuallayoutheight>0)screen.style.transform="scale3d("+RiftUIModel.canvasScale(host.actuallayoutwidth,host.actuallayoutheight,1600,980)+","+RiftUIModel.canvasScale(host.actuallayoutwidth,host.actuallayoutheight,1600,980)+",1)";
  $("#PickScreen").GetParent().SetHasClass("Closed",data.state!=="HERO_SELECTION");
  $("#PickTimer").text=String(Math.max(0,data.selection_remaining||0));
}
(function(){
  GameEvents.Subscribe("rift_pick_result",RiftPickResult);
  CustomNetTables.SubscribeNetTableListener("rift_match",function(_,key,data){if(key==="roster")RiftPickRoster(data);if(key==="state")RiftPickState(data);if(key==="picks")RiftPickPlayers(data);});
  RiftPickRoster(CustomNetTables.GetTableValue("rift_match","roster"));
  RiftPickState(CustomNetTables.GetTableValue("rift_match","state"));
  RiftPickPlayers(CustomNetTables.GetTableValue("rift_match","picks"));
})();
