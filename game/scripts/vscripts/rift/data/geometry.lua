-- Preview geometry only. Damage adapters use the same balance definitions.
local E=require("rift.data.expansion")
local B=require("rift.data.hero_balance")
local G={}
for name,d in pairs(E.abilities) do
 if d.radius>0 then
  G[name]={shape=(d.mode=="line" or d.line) and "line" or "circle",target=d.target,
    radius=d.radius,length=d.range,expand=d.expand or 0,ticks=d.ticks or 1}
 end
end
G.ta_psionic_crystal={shape="circle",target="point",radius=B.ta.crystal_physical.radius}
G.ta_psionic_blast={shape="circle",target="unit",radius=B.ta.trap_magical.radius}
for _,name in ipairs({"ta_refraction_magical","ta_meld_dash","ta_psi_wave"}) do
 G[name]={shape="line",target=name=="ta_refraction_magical" and "none" or "point",radius=B.ta.waves_magical.width/2,length=B.ta.waves_magical.length}
end
G.lc_statue={shape="cross",target="point",radius=B.lc.statue.beam_half_width,length=B.lc.statue.beam_range}
G.sf_requiem_physical={shape="circle",target="none",radius=0}
return G
