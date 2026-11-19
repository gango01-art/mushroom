"use strict";
// The stock badge tests native HasScepter(), which would enable unwanted C++
// upgrades. Use confirmed DUALITY ownership, and replace its hover content too.
(function () {
  var hud=$.GetContextPanel();while(hud.GetParent())hud=hud.GetParent();
  var info=$("#AghanimInfo"),bound=null,icons=[],hover=false;
  function selected() {
    var entity=Players.GetLocalPlayerPortraitUnit();
    var board=CustomNetTables.GetTableValue("rift_scores","board");
    var rows=board&&board.rows||{};
    for(var k in rows)if(rows[k].aghanim&&rows[k].aghanim.entity===entity)return rows[k];
    return null;
  }
  function hide(){hover=false;info.AddClass("Hidden");}
  function show(){hover=true;render();}
  function render(){
    var row=selected(),a=row&&row.aghanim;
    info.SetHasClass("Hidden",!hover||!a);
    icons.forEach(function(p,i){if(!p)return;
      var kind=i===0?"scepter":"shard",owned=a&&(i===0?a.scepter:a.shard)===1;
      p.style.backgroundImage='url("s2r://panorama/images/hud/reborn/aghsstatus_'+kind+(owned?'_on':'')+'_psd.vtex")';
    });
    if(!a)return;
    $("#AghanimPath").text="DUALITY · "+$.Localize(row.direction?"#rift_dir_"+row.direction:"#rift_agh_choose_path");
    $("#AghanimScepterOwned").text=$.Localize(a.scepter===1?"#rift_agh_owned":"#rift_agh_missing");
    $("#AghanimShardOwned").text=$.Localize(a.shard===1?"#rift_agh_owned":"#rift_agh_missing");
    $("#AghanimScepterText").text=$.Localize(a.primary?"#DOTA_Tooltip_ability_"+a.primary+"_scepter_description":"#rift_agh_choose_path");
    $("#AghanimShardText").text=$.Localize(a.shared||a.primary?"#DOTA_Tooltip_ability_"+(a.shared||a.primary)+"_shard_description":"#rift_agh_choose_path");
  }
  function tick(){
    var scepter=hud.FindChildTraverse("AghsStatusScepterContainer");
    if(scepter&&bound!==scepter){
      bound=scepter;icons=[];
      var root=scepter.GetParent(),shard=root.FindChildTraverse("AghsStatusShard");
      ["RiftAghanimIcon0","RiftAghanimIcon1"].forEach(function(id){
        var old=root.FindChildTraverse(id);if(old)old.DeleteAsync(0);
      });
      [root,scepter,shard].forEach(function(p){if(!p)return;
        p.SetPanelEvent("onmouseover",show);p.SetPanelEvent("onmouseout",hide);
      });
      // Reuse the two transparent stock silhouettes. No item-image overlay or
      // black backing panel; only the texture reflects DUALITY ownership.
      icons=[root.FindChildTraverse("AghsStatusScepter"),shard];
      ["AghsStatusScepterScene","AghsStatusShardScene","AghsAquireEffects"].forEach(function(id){
        var p=root.FindChildTraverse(id);if(p)p.style.visibility="collapse";
      });
    }
    render();$.Schedule(.1,tick);
  }
  tick();
})();
