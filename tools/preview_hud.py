#!/usr/bin/env python3
"""Build a standalone browser design mock from the actual Panorama layout/style.

This adapter is NOT a Source 2 renderer and sends no network/game events. Portraits
are labelled placeholders; the game uses its native Dota hero textures.
"""
from pathlib import Path
import html
import json
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
base = ROOT / 'content/panorama'
tokens = dict(re.findall(r'^\s*"([^"]+)"\s+"((?:[^"\\]|\\.)*)"', (ROOT / 'game/resource/addon_russian.txt').read_text(), re.M))
xml = ET.parse(base / 'layout/custom_game/rift_hud.xml').getroot()
def element(e):
    tag = 'button' if e.tag == 'Button' else 'div'
    attrs = []
    for k, v in e.attrib.items():
        if k in ('id', 'class'): attrs.append(f'{k}="{html.escape(v, quote=True)}"')
        elif k == 'onactivate': attrs.append(f'onclick="{html.escape(v, quote=True)}"')
    text = e.attrib.get('text', '')
    if text.startswith('#'): text = tokens.get(text[1:], text)
    return f'<{tag} {" ".join(attrs)}>{html.escape(text)}' + ''.join(element(c) for c in e) + f'</{tag}>'
markup = element(next(e for e in xml if e.tag == 'Panel'))
css = (base / 'styles/custom_game/rift_hud.css').read_text()
def gradient(m):
    colors = re.findall(r'#[0-9a-fA-F]+', m[0])
    angle = '90deg' if '100% 0%' in m[0] else '145deg'
    return 'background: linear-gradient(' + angle + ', ' + ', '.join(colors) + ');'
css = re.sub(r'background-color:\s*gradient\([^;]+;', gradient, css)
css = css.replace('flow-children: right-wrap;', 'display: flex; flex-flow: row wrap;')
css = css.replace('flow-children: right;', 'display: flex; flex-direction: row;')
css = css.replace('flow-children: down;', 'display: flex; flex-direction: column;')
css = css.replace('width: fill-parent-flow(1);', 'flex: 1; min-width: 0;')
css = css.replace('visibility: collapse;', 'display: none;')
css = css.replace('visibility: visible;', 'display: flex;')
css += '''
* {box-sizing:border-box; flex-shrink:0} body {margin:0;background:#111a25;color:#cbd4e3;font-family:Georgia,serif}
button {font:inherit;cursor:pointer;color:inherit;outline:0;border:0} div {position:relative} .RiftHudRoot {position:relative;width:1920px;height:1080px;overflow:hidden;background:radial-gradient(ellipse at 50% 40%,#344350,#121d2d 65%)}
.TopBar {position:absolute;top:0;left:50%;transform:translateX(-50%)} .MatchClock>* {text-align:center} .TopPlayers{margin-top:4px}
.MatchSummary {position:absolute;top:0;left:50%;transform:translateX(-50%)} .HudActions {position:absolute;top:0;right:0}
.RelicPanel {position:absolute;top:0;left:50%;transform:translateX(-50%)} .Board{position:absolute;top:0;right:0}
.BuildPanel {position:absolute;top:45%;left:0} .OfferPanel,.OfferOpenButton {position:absolute;top:50%;right:0;transform:translateY(-50%)}
.PlayerSeat>div {position:absolute} .SeatPortrait{top:0;display:flex;align-items:center;justify-content:center;font:18px Georgia;color:#e9ddc4;background:linear-gradient(135deg,#475463,#212e40)}
.SeatRank {top:0;left:0}.SeatName{top:0}.SeatScore{bottom:0;left:0;width:100%;text-align:center}.SeatPath{top:0;right:0}.SeatDeath{top:0;left:0;width:100%;text-align:center}.SeatPortrait{font-size:12px;overflow:hidden}.OfferCard{text-align:left}
.Onboarding,.Result {position:absolute;left:50%;top:53%;transform:translate(-50%,-50%)} .Onboarding.Hidden,.Hidden{display:none!important}
.MenuWordmark{font-family:Georgia,serif}.MenuAlpha{margin-left:auto}.MenuFooter{align-items:center}.MenuFooter .RiftButton{margin-left:auto}
.GalleryPortrait {display:flex;align-items:center;justify-content:center;color:#d1d9e5;font-size:13px;background:linear-gradient(135deg,#506070,#1d293c)}
.RiftButton:hover,.OfferCard:hover,.GalleryCard:hover{filter:brightness(1.3)} .PreviewPath{min-width:0;white-space:normal;text-align:left}
.HeroGallery{align-content:flex-start;flex:0 0 auto}.GalleryCard{padding:0}.MenuRoster{min-width:0}.RuleText,.PreviewDesc{line-height:1.25}
.LabPanel{position:absolute;top:132px;left:18px;margin:0}.LabBody{flex:1;min-height:0;overflow-y:auto}.LabHero{position:relative;padding:0;background:#192b42}.LabHero>*{position:absolute;left:0}.LabHeroName{bottom:0;white-space:nowrap;overflow:hidden}.LabHeroPortrait{display:flex;align-items:center;justify-content:center;font-size:11px;background:#263c52}.ClockProgress{transition:width .45s}.MockNote{position:absolute;bottom:16px;right:20px;font:13px sans-serif;letter-spacing:1px;color:#7990a6}
.MockActions {position:absolute;left:16px;bottom:16px;display:flex;gap:8px}.MockActions button{padding:10px;background:#334255;color:#d8e2ed}
'''
# Read the roster/directions from Lua itself instead of maintaining another roster.
import subprocess
lua = '''package.path="game/scripts/vscripts/?.lua;"..package.path
local seen={};for _,d in ipairs(require("rift.data.ultimate_directions")) do
local h=seen[d.hero_id] or {hero=d.hero_id};seen[d.hero_id]=h;h[d.direction]={name=d.loc_name,desc=d.loc_desc} end
for name,h in pairs(seen) do print(name.."|"..h.physical.name.."|"..h.physical.desc.."|"..h.magical.name.."|"..h.magical.desc) end'''
lines = subprocess.check_output(['lua5.1', '-e', lua], cwd=ROOT, text=True).splitlines()
roster=[]
for line in sorted(lines):
    h,pn,pd,mn,md=line.split('|')
    roster.append({'hero':h,'physical':{'name':pn,'desc':pd},'magical':{'name':mn,'desc':md}})
mock = r'''
function adapt(p) {
 if(p._adapted)return p;p._adapted=true;
 p.AddClass=c=>p.classList.add(c);p.RemoveClass=c=>p.classList.remove(c);p.ToggleClass=c=>p.classList.toggle(c);
 p.SetHasClass=(c,b)=>p.classList.toggle(c,b);p.GetParent=()=>p.parentNode;p.Children=()=>Array.from(p.children).map(adapt);
 p.RemoveAndDeleteChildren=()=>p.replaceChildren();p.DeleteAsync=()=>p.remove();p.SetPanelEvent=(e,f)=>p.addEventListener(e==='onactivate'?'click':e.slice(2),f);
 p.SetImage=s=>{var hero=s.match(/npc_dota_hero_([^.]+)/);if(hero){p.textContent=hero[1].replace(/_/g,' ').toUpperCase()}else{p.textContent='◆';p.style.display='grid';p.style.placeItems='center'}};
 Object.defineProperty(p,'text',{get:()=>p.textContent,set:v=>p.textContent=v});return p;
}
var $=s=>adapt(document.querySelector(s));$.CreatePanel=(t,p,id)=>{var e=document.createElement(t==='Button'?'button':'div');if(id)e.id=id;p.append(e);return adapt(e)};
$.Localize=t=>TOKENS[t.replace(/^#/,'')]||t.replace('#npc_dota_hero_','').replace(/_/g,' ');
$.Schedule=(s,fn)=>setTimeout(fn,s*1000);
var Players={GetLocalPlayer:()=>0,GetPlayerName:i=>['YOU','FROST','VANGUARD','EMBER','GHOST','ORACLE','IRON','STORM'][i]||'Spectator'};
var Game={GetGameTime:()=>performance.now()/1000},GameUI={SetDefaultUIEnabled:()=>{},SelectUnit:()=>{}};
var DotaDefaultUIElement_t={DOTA_DEFAULT_UI_TOP_HEROES:0,DOTA_DEFAULT_UI_TOP_TIMEOFDAY:1};
var LISTENERS={},EVENTS={};
var CustomNetTables={SubscribeNetTableListener:(t,fn)=>(LISTENERS[t]||(LISTENERS[t]=[])).push(fn),GetTableValue:(t,k)=>DATA[t]&&DATA[t][k]};
var GameEvents={Subscribe:(e,f)=>EVENTS[e]=f,SendCustomGameEventToServer:()=>{}};
function publish(t,k,v){(DATA[t]||(DATA[t]={}))[k]=v;(LISTENERS[t]||[]).forEach(f=>f(t,k,v))}
var DATA={rift_match:{state:{state:'ACTIVE',remaining:824,active_total:1080},roster:{heroes:ROSTER}},rift_scores:{board:{rows:{}}}};
var heroNames=['phantom_assassin','crystal_maiden','axe','lina','juggernaut','nevermore','windrunner','sven'];
heroNames.forEach((h,i)=>DATA.rift_scores.board.rows[i+1]={pid:i,hero:'npc_dota_hero_'+h,score:24-i*2,kills:8-i,deaths:2,assists:i,direction:i%2?'magical':'physical',alive:i!==5?1:0,respawn:i===5?7:0});
function mockOffer(){RiftHideOnboarding();EVENTS.rift_private_state({visible_offer:1,pending:{1:{id:1,type:'ultimate_direction',remaining:45,options:{1:{id:'a',kind:'direction',direction:'physical',loc_name:ROSTER[0].physical.name,loc_desc:ROSTER[0].physical.desc,icon:'axe_culling_blade',is_default:1},2:{id:'b',kind:'direction',direction:'magical',loc_name:ROSTER[0].magical.name,loc_desc:ROSTER[0].magical.desc,icon:'axe_culling_blade'}}}},build:{}})}
function mockLab(){RiftHideOnboarding();EVENTS.rift_private_state({visible_offer:-1,pending:{},build:{}});publish('rift_match','state',{state:'ACTIVE',remaining:824,active_total:1080,lab:1});publish('rift_match','lab',{available:1,enabled:1,owner:0,hero:ROSTER[0].hero,path:'physical',rank:3,free:0,gallery_count:11,target_count:1,active_entity:42});}
'''
script = '\n'.join((base / f'scripts/custom_game/{name}.js').read_text() for name in ['rift_ui_model', 'rift_hud', 'rift_lab'])
out = ROOT / 'docs/design/hud-preview.html'
out.write_text('<!doctype html><html lang="ru"><meta charset="utf-8"><title>DUALITY — design mock</title><style>'+css+'</style>'+markup+'<div class="MockActions"><button onclick="RiftOpenMenu()">МЕНЮ</button><button onclick="mockOffer()">ВЫБОР ПУТИ</button><button onclick="mockLab()">ПОЛИГОН</button><button onclick="RiftHideOnboarding();RiftCollapseOffer()">HUD</button></div><div class="MockNote">BROWSER DESIGN MOCK · NOT A DOTA TEST · PORTRAIT PLACEHOLDERS</div><script>var TOKENS='+json.dumps(tokens,ensure_ascii=False)+';var ROSTER='+json.dumps(roster)+';'+mock+script+'\nRiftOpenMenu();</script></html>')
print(out)
