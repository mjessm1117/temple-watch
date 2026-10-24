/* Onboarding (A2): the new-campaign screen asks "Show tips?"; if yes, the first mission opens with one controls card.
   Jess 2026-10-22: minimal hand-holding, asked at start, skippable. The in-mission hints live in ui-hud.js (TIPS) and share SETTINGS.tips. */
const TUT_CARD=[
 ['Select','Click a squad member (or press Tab). Lit tiles show where it can move.'],
 ['Action points','Each unit gets 3 AP a turn. Each AP is one full move. Pistols and sabers cost 1 AP to attack, rifles 2. Shooting does not end your turn.'],
 ['Cover','Shield icons mark cover: solid = full, outline = half. End moves next to it. Hit enemies from the side to flank.'],
 ['Shoot','Pick an ability, click a target to see the hit %, then Confirm. Space aims at the best target; Space again fires.'],
 ['The Force','Jedi spend Focus on powers; Meditate refills it. Choke works but adds Darkness.'],
 ['Wounded','A downed ally bleeds out in a few turns. Stand next to them and Stabilize, or use a medkit.'],
 ['Done?','Press End turn. Click any enemy to see its plan. Codex (C) explains everything; ? lists all keys.']];
// Row for the new-campaign screen (screens.js). Default follows the Tips setting (on unless turned off).
function tutRow(){const on=SETTINGS.tips!==false;
 return `<div class="setrow" id="tutRow"><div><b>Show tips?</b><small>A short controls card before your first mission, plus hints the first time you do things.</small></div><div class="seg"><button type="button" data-tut="1" class="${on?'on':''}">Yes</button><button type="button" data-tut="0" class="${on?'':'on'}">No</button></div></div>`}
function tutWire(m){m.querySelectorAll('[data-tut]').forEach(b=>b.onclick=()=>{SETTINGS.tips=b.dataset.tut==='1';saveSettings();
 m.querySelectorAll('[data-tut]').forEach(x=>x.classList.toggle('on',x===b))})}
function tutCard(){const o=uiLayer('tut');
 o.innerHTML=`<div class="ui-card" role="dialog" aria-label="How to play"><div class="ui-head"><h2>How to play</h2><button type="button" data-ui="close" aria-label="Close">✕</button></div>
 ${TUT_CARD.map(([h,t])=>`<p><b>${h}.</b> ${t}</p>`).join('')}
 <div class="endrow"><button type="button" id="tutOff">Turn off tips</button><button type="button" class="primary" data-ui="close">Got it</button></div></div>`;
 o.querySelector('#tutOff').onclick=()=>{SETTINGS.tips=false;saveSettings();if(window.tipsReset)tipsReset(false);uiClose()}}
// New campaign: remember the choice on C, reset the hints so they show again.
const _tutNew=newCampaign;newCampaign=function(d){_tutNew(d);if(!C)return;C.tut=SETTINGS.tips!==false?1:0;if(window.tipsReset)tipsReset(!!C.tut);saveGame()};
// First mission of a campaign that said yes: show the card once, then never again.
const _tutStart=startMission;startMission=function(){const r=_tutStart.apply(this,arguments);
 if(C&&C.tut&&S){delete C.tut;tutCard()}return r};
