local C=require("rift.core.roshan")
local B=require("rift.core.config").roshan
T.case("Roshan alternates the two vacant pockets every five minutes",function()
 for _,v in ipairs({{0,1},{299,1},{300,2},{599,2},{600,1},{900,2},{1800,1}})do T.eq(C.pocket(B,v[1]),v[2])end
 T.eq(C.next_move(B,0),300);T.eq(C.next_move(B,300),600)
end)
T.case("Roshan uses native Dota grab/throw during migration and scales only at spawn",function()
 T.eq(#B.abilities,7);T.eq(B.abilities[6],"roshan_spell_block");T.eq(B.abilities[5],"roshan_bash")
 T.eq(B.slam_ability,"roshan_slam");T.eq(B.roar_ability,"roshan_revengeroar")
 T.eq(B.throw_ability,"roshan_grab_and_throw");T.eq(B.max_throws_per_trip,5)
 T.eq(C.scale(B,599),1);T.eq(C.scale(B,600),1.35);T.eq(C.scale(B,1200),1.7)
 T.eq(B.respawn_seconds,300)
end)
