"use strict";
// Native client-only range particles. No hidden enemy data or server effects.
(function () {
  var hovered="", effects=[], signature="";
  function clear() {
    effects.forEach(function(p){Particles.DestroyParticleEffect(p,true);Particles.ReleaseParticleIndex(p);});
    effects=[];signature="";
  }
  function particle(name,hero) {
    var p=Particles.CreateParticle(name,ParticleAttachment_t.PATTACH_WORLDORIGIN,hero);
    effects.push(p);Particles.SetParticleControl(p,3,[1,0,0]);return p;
  }
  function point(p,cp,v){Particles.SetParticleControl(p,cp,v);}
  function show(_,name){hovered=name||"";return false;}
  $.RegisterForUnhandledEvent("DOTAShowAbilityTooltip",show);
  $.RegisterForUnhandledEvent("DOTAShowAbilityTooltipForEntityIndex",show);
  $.RegisterForUnhandledEvent("DOTAHideAbilityTooltip",function(){hovered="";clear();return false;});
  function tick() {
    var hero=Players.GetLocalPlayerPortraitUnit(),active=Abilities.GetLocalPlayerActiveAbility();
    var a=active,aim=active>=0;
    if(!aim&&hovered&&hero>=0) {
      for(var i=0;i<Entities.GetAbilityCount(hero);i++) {
        var candidate=Entities.GetAbility(hero,i);
        if(Abilities.GetAbilityName(candidate)===hovered){a=candidate;break;}
      }
    }
    var name=a>=0?Abilities.GetAbilityName(a):"";
    var all=CustomNetTables.GetTableValue("rift_match","geometry")||{},g=all[name];
    if(!g||hero<0||!Entities.IsAlive(hero)) {clear();$.Schedule(.05,tick);return;}
    // Point/unit circles belong to the engine's native targeting renderer.
    // A second world-position circle lags and disagrees with unit snapping.
    if(g.shape==="cross"||(g.shape==="circle"&&g.target!=="none")) {
      clear();$.Schedule(0,tick);return;
    }
    var origin=Entities.GetAbsOrigin(hero),cursor=GameUI.GetScreenWorldPosition(GameUI.GetCursorPosition());
    var forward=Entities.GetForward(hero),length=g.length||0,castRange=Abilities.GetCastRange(a);
    var radius=Abilities.GetAOERadius(a)||g.radius;
    var dx=cursor?cursor[0]-origin[0]:forward[0],dy=cursor?cursor[1]-origin[1]:forward[1];
    var dist=Math.sqrt(dx*dx+dy*dy),dir=dist>1?[dx/dist,dy/dist,0]:forward;
    var center=origin;
    if(g.target!=="none"&&aim&&cursor) {
      var scale=castRange>0&&dist>castRange?castRange/dist:1;
      center=[origin[0]+dx*scale,origin[1]+dy*scale,cursor[2]];
    }
    var key=hero+":"+name+":"+aim;
    if(signature!==key) {
      clear();signature=key;
      var p=particle(g.shape==="circle"?"particles/ui_mouseactions/range_display.vpcf":"particles/ui_mouseactions/range_finder_linear.vpcf",hero);
      Particles.SetParticleControlEnt(p,0,hero,ParticleAttachment_t.PATTACH_ABSORIGIN_FOLLOW,"",[0,0,0],true);
    }
    if(g.shape==="circle") {
      point(effects[0],1,[radius,0,0]);
    } else {
      var start=g.shape==="cross"?center:origin;
      for(var r=0;r<effects.length;r++) {
        var angle=r*Math.PI/2,c=Math.cos(angle),s=Math.sin(angle);
        var v=[dir[0]*c-dir[1]*s,dir[0]*s+dir[1]*c,0];
        point(effects[r],0,start);point(effects[r],1,[start[0]+v[0]*length,start[1]+v[1]*length,start[2]]);
        point(effects[r],2,[0,radius,radius]);point(effects[r],15,[0,1,0]);
      }
    }
    $.Schedule(0,tick);
  }
  tick();
})();
