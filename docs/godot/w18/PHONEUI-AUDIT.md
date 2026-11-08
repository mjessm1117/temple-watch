# Phone screen audit — 844 × 390

Captured on 2026-11-07 in `phoneui/audit/`. This is a visual audit only; these screens were not changed in the phone HUD lane. Ranks are within each screen, with 1 the first issue to address.

| Screen | Rank | Visible phone problem |
| --- | ---: | --- |
| [Title](phoneui/audit/title.png) | 1 | The story paragraph uses small type and long lines across the lower half. |
| Title | 2 | The START, CONTINUE and DIRECT RESCUE row relies on compact text targets; confirm their full hit areas in the next lane. |
| [Temple home](phoneui/audit/temple-home.png) | 1 | The two-line header uses about a third of the height, compressing the cutaway. |
| Temple home | 2 | The mini galaxy sits over the left side of the room view; room names and small room targets are crowded. |
| [Armory](phoneui/audit/armory.png) | 1 | The tall global header and station heading leave little height for equipment content. |
| Armory | 2 | The unit selector wraps to a second row, pushing equipment below the fold. |
| Armory | 3 | Bottom navigation is obscured by the open station panel in the captured frame. |
| [Barracks](phoneui/audit/barracks.png) | 1 | The tall global header and station heading leave only the start of the recruit pool visible. |
| Barracks | 2 | The long recruit action fills the panel width and its detail must be scrolled into view. |
| Barracks | 3 | Bottom navigation is obscured by the open station panel in the captured frame. |
| [Galaxy map](phoneui/audit/galaxy-map.png) | 1 | The right briefing rail is narrow: the carousel labels and synopsis truncate. |
| Galaxy map | 2 | Small progress marks and map signals need a measured 44 px touch audit. |
| Galaxy map | 3 | The top command and resource rows consume map height. |
| [Promotion](phoneui/audit/promotion.png) | 1 | Most of the lower half is empty while the mentor and next-choice information is compressed near the top. |
| Promotion | 2 | The Done button is visually small; measure its hit area in the next lane. |
| [Mission briefing](phoneui/audit/mission-briefing.png) | 1 | A large TAP TO ADVANCE slab fills the lower panel while story and decision content sit above and below it. |
| Mission briefing | 2 | The decision area is at the bottom edge and requires scrolling to inspect. |
| [Debrief](phoneui/audit/debrief.png) | 1 | The same large advance slab wastes space, leaving the decision area at the bottom edge. |
| Debrief | 2 | The top brand and chronology strip consumes height before the outcome text. |

## Suggested lane order

1. Temple and station pages: reclaim vertical space in the shared header, then expose armory and barracks content.
2. Briefing and debrief: reduce the advance slab and bring choices into the first viewport.
3. Galaxy map: widen or collapse the briefing rail and measure map touch targets.
4. Promotion and title: use empty space for readable choices and larger text.
