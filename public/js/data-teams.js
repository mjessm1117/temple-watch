/* Strike teams + fatigue (Chat S2, bucket 3). Logic: teams.js. Jess's picks 2026-10-20: 2 → 4 teams, "fair" auto-resolve, soft fatigue.
   Team names are Aurebesh letters (canon + Legends, High confidence). */
const TEAMS={base:2,max:4,barracks:[2,3],   // 2 teams; Barracks level 2 and level 3 each add one (max 4)
 size:4,min:2,                              // a Jedi leader + up to 3 troopers; a team needs 2 free members to go out
 names:['Aurek','Besh','Cresh','Dorn'],log:6};
// Auto-resolve odds = base + 5×Σrank + leader + bonds − tired − short-handed + risk, clamped 10–90.
// Calibration [Estimate]: start team (Jedi R2 + 2 troopers R2) ≈ 62–70%; full R3 team with bonds ≈ 85–90 (cap). Severe maps ≈ 50.
const TAUTO={base:35,perRank:5,lead:8,bond:3,bondMax:9,tired:5,short:6,min:10,max:90,
 scale:1.5,                                 // team Power × 1.5 before the risk check (a 4-unit team vs maps built for 6)
 risk:[0,6,0,-5,-18],                       // by risk level 1–4: Low, Moderate, High, Severe
 xp:12,winWound:25,                         // win: +12 XP each; each member 25% chance of a light wound
 loseFavor:-3,loseStress:15,capture:30,death:7};   // loss: one serious wound for sure; then 7% one member dies, else 30% one is captured
// Fatigue (soft, XCOM 2 WotC-style): fight 2 steps in a row (played or auto) → Tired. Tired = −10 aim and −5% auto odds. One step off clears it.
const FATIGUE={at:2,aim:-10};
