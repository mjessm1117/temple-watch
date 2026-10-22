// Meshy API: text → textured → rigged GLB for each unit kind. Key in env MESHY_KEY (never commit it).
// usage: MESHY_KEY=msy_... node tools/meshy/gen.mjs outDir kind1 kind2 ...   (no kinds = all in PROMPTS)
// Then: node tools/meshy/retarget.mjs public/models/human.glb outDir/<kind>.rig.glb public/models/units/<kind>.glb
import fs from 'fs';
const API='https://api.meshy.ai/openapi',K=process.env.MESHY_KEY;if(!K)throw new Error('set MESHY_KEY');
const STYLE='Stylized low-poly game miniature, Star Wars inspired, single full-body character, standing, facing forward, arms slightly away from body, clean silhouette, no base, no weapon in hands.';
export const PROMPTS={
 defender:['Jedi Defender knight in heavy layered brown robes over ornate steel armor plates, large pauldrons, long cape, hood down, stern face','worn brown cloth, brushed steel armor, blue trim'],
 shieldbearer:['Republic heavy trooper in white and grey armor, bulky shoulder plates, T-visor helmet, riot-guard bracers on the left forearm','white armor, grey panels, red unit markings'],
 acolyte:['Sith acolyte in close-fitting black tunic and trousers, short black hooded cowl, red sash belt, gaunt pale face, legs clearly visible','black cloth, red sash, pale grey skin'],
 nihilRaider:['Nihil raider pirate with a cracked gas mask respirator, mismatched scavenged armor, ragged cloak, bandoliers','rust orange and dirty teal, scratched metal, grimy cloth'],
 nihilStorm:['Nihil Storm warlord, tall, heavy scavenged armor, ornate gas mask with three lenses, tattered cape, imposing','dark teal and bronze armor, red lenses, black cape'],
 marchionRo:['Marchion Ro, Eye of the Nihil, tall slender man in a dark tunic and long coat, wearing a menacing smooth full-face helmet with a single horizontal visor slit','black and dark grey, silver helmet accents'],
 lournaDee:['Lourna Dee, Twi\'lek pirate captain woman with two long head-tails, sleek fitted flight armor, confident pose','blue skin, black and gold armor'],
 drengir:['Drengir, a tall humanoid carnivorous plant creature, thorny vine body, gaping flower head with teeth, root-like legs and arms','dark green vines, purple thorns, sickly yellow mouth'],
 nameless:['Nameless creature, a hunched bipedal predator with smooth pale chitin, long clawed arms, eyeless elongated head, shadowy and eerie','pale bone white chitin, dark purple shadows']};
// Props/scenery (no rig): name → [prompt, texture]. Run like units; the rig step is skipped.
export const PROPS={
 temple:['Jedi Temple on Coruscant: a massive stepped stone ziggurat with five tall slender spires on top, the central spire tallest, grand entrance stairs, stylized low-poly game asset, whole building, no ground','pale sandstone, bronze spire tips, warm window lights'],
 shuttle:['Small sleek Republic shuttle starship with folded wings, stylized low-poly game asset, single vehicle, no ground','white hull, red stripes, blue engine glow'],
 airtaxi:['Coruscant air taxi speeder, small flying car, stylized low-poly game asset, single vehicle, no ground','yellow and grey paint, glowing headlights']};
const H=()=>({Authorization:'Bearer '+K,'Content-Type':'application/json'});
const post=async(p,b)=>{const r=await fetch(API+p,{method:'POST',headers:H(),body:JSON.stringify(b)});const j=await r.json();if(!r.ok)throw new Error(p+' '+r.status+' '+JSON.stringify(j));return j.result};
const wait=async p=>{for(;;){const j=await(await fetch(API+p,{headers:H()})).json();if(j.status==='SUCCEEDED')return j;if(j.status==='FAILED'||j.status==='CANCELED')throw new Error(p+' '+JSON.stringify(j.task_error));await new Promise(r=>setTimeout(r,8000))}};
const get=async(u,f)=>fs.writeFileSync(f,Buffer.from(await(await fetch(u)).arrayBuffer()));
async function one(kind,out){const prop=!!PROPS[kind],[p,t]=PROPS[kind]||PROMPTS[kind],log=m=>console.log(kind+': '+m);
 const pv=await post('/v2/text-to-3d',{mode:'preview',prompt:prop?p:STYLE+' '+p,ai_model:'meshy-6',...(prop?{}:{pose_mode:'a-pose'}),should_remesh:true,target_polycount:prop?8000:12000,topology:'triangle'});log('preview '+pv);await wait('/v2/text-to-3d/'+pv);
 const rf=await post('/v2/text-to-3d',{mode:'refine',preview_task_id:pv,texture_prompt:t,enable_pbr:false});log('refine '+rf);const R=await wait('/v2/text-to-3d/'+rf);
 await get(R.model_urls.glb,`${out}/${kind}.raw.glb`);if(R.thumbnail_url)await get(R.thumbnail_url,`${out}/${kind}.png`);
 if(prop)return log('done (prop)');
 try{const rg=await post('/v1/rigging',{input_task_id:rf,height_meters:kind==='nihilStorm'||kind==='drengir'?2.1:1.8});log('rig '+rg);const G=await wait('/v1/rigging/'+rg);
  await get(G.result.rigged_character_glb_url,`${out}/${kind}.rig.glb`);log('done')}catch(e){log('rig failed: '+e.message)}}
const [out,...kinds]=process.argv.slice(2);fs.mkdirSync(out,{recursive:true});
const res=await Promise.allSettled((kinds.length?kinds:Object.keys(PROMPTS)).map(k=>one(k,out)));res.forEach(r=>r.status==='rejected'&&console.log('FAILED',r.reason.message));
