/* Game data: map, waves, squad, enemies. Tune numbers here. */
const W=10,H=12,TURNS=8,CONS=20;
const MAP=[
"..........",
"..#....#..",
".c..cc..c.",
"....##....",
".c......c.",
"##.c..c.##",
"....cc....",
".#......#.",
".c.c..c.c.",
"....##....",
"....OO....",
".........."];
const WAVES={1:['trooper','trooper','trooper'],3:['trooper','trooper','heavy'],5:['acolyte','trooper','trooper']};
const LAST_WAVE=5;
const ROSTER=[
 {n:'Kira Venn',cls:'Guardian',rank:'Knight',jedi:1,hp:9,aim:80,mob:5,dmg:[4,6],range:1.5,deflect:20,guardDef:70,maxF:4,init:14,x:3,y:9,col:'#62b3ff',abil:['strike','guard','push','throw','collapse','choke','subdue','meditate']},
 {n:'Tor Saalen',cls:'Consular',rank:'Padawan',jedi:1,hp:6,aim:75,mob:5,dmg:[3,4],range:1.5,deflect:10,guardDef:50,maxF:4,init:12,x:6,y:9,col:'#72e0a4',abil:['strike','guard','push','stun','choke','subdue','meditate']},
 {n:'Sgt. Rhal Dax',cls:'Soldier',hp:7,aim:70,mob:5,dmg:[3,5],range:8,init:10,x:2,y:8,abil:['shoot','overwatch','subdue']},
 {n:'Ilsa Myr',cls:'Scout',hp:5,aim:80,mob:6,dmg:[4,6],range:11,init:15,x:9,y:9,abil:['shoot','overwatch','subdue']},
 {n:'Doc Bren',cls:'Medic',hp:6,aim:65,mob:5,dmg:[2,3],range:6,kits:2,init:9,x:4,y:11,abil:['shoot','heal','overwatch','subdue']},
 {n:'Grak Ordo',cls:'Heavy',hp:8,aim:60,mob:4,dmg:[3,5],range:7,nades:2,init:7,x:5,y:8,abil:['shoot','grenade','overwatch','subdue']}];
const FOES={
 trooper:{n:'Sith Trooper',sym:'T',hp:4,aim:65,mob:5,dmg:[2,4],range:8,init:8},
 heavy:{n:'Sith Heavy',sym:'H',hp:6,aim:60,mob:4,dmg:[3,4],range:7,nades:1,init:6},
 acolyte:{n:'Sith Acolyte',sym:'A',hp:8,aim:75,mob:6,dmg:[4,5],range:1.5,deflect:20,guardDef:20,init:13}};
