# Generation prompts — qyube compact v1

Built-in image_gen; 2026-10-02. Reference for all seven new screens: `02-home-history.png`. Images 01 and 02 were approved in the preceding conversation and copied into this folder. These are static UI proposals, not application screenshots.

## Shared prompt

Use case: ui-mockup. Make ONE high fidelity compact macOS qyube screen matching the supplied reference EXACTLY in window proportions, pure WHITE #FFFFFF surface, charcoal typography and buttons, pale neutral gray outside, thin outline icons and very subtle shadow. Portrait window roughly 420x700 logical points. Flat front view, full window in frame. No sidebar, cream, blue UI accents, gradients, heavy borders, inner card proliferation, large headings or marketing annotations. Use restrained readable sans serif and ample whitespace. Header has close x, small lowercase qyube and analytics/inventory/settings icons. Penguin when specified must faithfully preserve reference watercolor charcoal baby penguin, no glasses, no ice floe, no bucket, no water or shadow. Maintain compact professional desktop proportions. All text legible. 

## 03-new-session

New Session screen: back arrow under header, small seated fishing penguin centered in upper area. Then compact title 'New session'. Field label 'What are you working on?' and light gray rounded text field 'Design exploration'. Below 'Mode' with minimal rounded selector 'Allowing' and down chevron, row of three recognizable app icons Safari, Figma, Notes and an Edit text action. Below 'Duration' with '10 min' selected and a fine horizontal ruler with separate '180' at the very LEFT followed by 10,20,30,40,50,60 minute marks, selected 10. Footer centered charcoal 'Start session' button. No tags, daily target, break, subscription or other fields.

## 04-home-active

Home DURING an active session. Keep summary upper-left 'Today', '1h 20m', 'Focused today', watercolor fishing penguin upper-right. Session list has first active row: tiny outlined timer icon, 'Writing chapter', right '17:00', subtitle 'In progress · 8m focused', a small text action 'Show timer' under it. Then completed Design exploration 35m, Reading 25m, and interrupted Planning 12m as smaller quiet past rows. One centered bottom charcoal 'Show timer' button instead of New session. No Start another session action. This is a main home window, not floating timer; no separate floating windows drawn. No progress bars or colored status badges.

## 05-fishing-report

Completed Fishing Report screen. Small pleased watercolor penguin in upper center, holding rod loosely, no ice or props other than rod. Heading 'Session complete', subtitle 'Design exploration'. Two plain text metrics side by side '35m' / 'Focused' and '175' / 'Catches'. Small '3 new discoveries' text. Under label 'Highlights' show exactly THREE small watercolor illustrations in a row: clownfish, little yellow submarine, seaweed, names beneath, no big cards. These represent highlights, not all 175 catches. Below small text link 'View in Catalog'. Bottom charcoal centered button 'Start another session', then small 'Back to Home'. No Continue or break option, no confetti, stars, grades or new rewards tied to completion.

## 06-catalog

Catalog screen. Small back arrow, title 'Catalog', subtitle '12 of 24 discovered'. Restrained tabs 'All', 'Fish', 'Ocean finds' with All selected dark text underline. Grid EXACTLY 5 columns by about 5 rows, small item drawings with plenty of whitespace, optional very faint neutral square backgrounds, no big cards or long descriptions. 12 discovered items in muted watercolor colors: clownfish, sardine, pufferfish, seahorse, crab, jellyfish, seaweed, coral, little yellow submarine, boot, bottle, starfish. Small count badges such as ×42, ×8, ×3 below discovered items. Remaining cells DARK solid silhouettes shaped like fish/shark/ray/shell/ship etc with tiny '?' underneath; no count for undiscovered. Illustrations are examples and do not imply purchase mechanics. A small selected clownfish detail strip near bottom shows its slightly larger drawing, 'Clownfish', 'Caught 42 times', 'First caught today'. No buying/selling, locks, premium badges, aquarium or daily targets. Grid is the protagonist; no penguin on this screen.

## 07-insight-day

Insight Day screen. Small back arrow and 'Insight'. Compact segmented text tabs 'Day  Week  Month  Year', Day selected. Date navigation '<  Today, Oct 2  >'. At top content 'Latest catches' with small 'View all' at right and THREE small polaroid-style catch cards in horizontal row showing clownfish, clownfish, seaweed; duplicates intentionally separate cards, tiny timestamps. Then metrics '1h 12m' Focused, '2' Completed, '1' Interrupted in a clean row. Small comparison '12m more than yesterday'. Compact neutral dark-gray hourly bar chart labeled 'Focus distribution' with a few time ticks. Then 'Sessions' showing Design exploration 35m, Reading 25m, Planning 12m. At very bottom visible 'Daily catch summary' and two small rows Clownfish ×42, Seaweed ×8, 'View all' text. Indicate vertical scroll with subtle right scroll thumb. No task tags, daily goals, colored charts or cards wrapping every group. No mascot so data stays readable. This is a scrollable page, not all data needs to fit.

## 08-insight-week

Insight Week screen. Small back arrow and 'Insight'. Compact tabs 'Day  Week  Month  Year', Week selected. Date navigation '<  Sep 28 – Oct 4  >'. Upper metric '6h 40m' with small 'Focused this week', alongside '12 completed' and '2 interrupted'. Small '+1h 10m vs last week'. Simple seven-bar charcoal chart with M T W T F S S labels, restrained gray baseline. Then label 'Catches' with 'View all' right. EXACTLY five small bordered catch thumbnails per row, 3 rows visible, including repeated fish and seaweed/submarine images, NO polaroid borders or captions. Then 'Catch summary' with Clownfish ×186, Seaweed ×34, Submarine ×2. Scrollable compact one-column layout with a subtle right scrollbar. No penguin, tag distribution, goal, colored charts or giant metric cards. Period navigation pattern is reusable for Month and Year.

## 09-settings

Settings page with a SMALL settings menu OPEN from header gear in upper-right, same pure-white compact qyube window as reference. Main content below header left back arrow and heading 'Settings'. Form groups simple rows: 'Sound' then 'Session sound' with 'Soft bell' and chevron; 'Volume' with understated charcoal slider. 'Appearance' group with 'Reduce motion' off toggle and 'Use system appearance' off toggle. 'App' group with 'Launch at login' off toggle and 'Version' 'Prototype'. These are visual proposals only. Popover anchored to gear overlays upper-right, narrow width around 200 logical points, white fill subtle shadow, small dark line icons and exact rows 'Settings', 'Manage subscription', 'Sign out', 'Help', 'Give feedback', separated last 'Quit'. Menu should cover only upper content, leaving lower settings rows visible. No sidebar, modal dark scrim, blue toggle, account email, payment card fields or aquarium controls. One coherent screen showing open menu and underlying settings.

## Final corrections

06: changed discovery subtitle to `12 of 25 discovered` to match the 25 grid cells.

09: aligned Session sound with Soft bell, aligned Volume with its slider, removed the proposed Use system appearance row, and used a payment-card icon for Manage subscription. The native layout must not shift underlying content when its menu opens.

