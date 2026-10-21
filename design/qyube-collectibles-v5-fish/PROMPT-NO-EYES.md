# Eye removal comparison

Built-in image_gen edit. Source: `01-fish-collection-sheet.png`. Output: `02-fish-collection-sheet-no-eyes.png`.

Use case: precise-object-edit.
Input image 1 is the edit target: the qyube watercolor collection sheet of 32 fish in 8 columns by 4 rows.
Primary request: make an exact comparison version with absolutely ZERO EYES on every fish. Remove every eye mark throughout the sheet, including all tiny black pin-dots, pale eyes, eye rings, pupils, eye sockets, central erroneous face dots, and the eyes at the lateral tips of the hammerhead. On the ray remove every small facial eye dot too. Replace eye pixels with the local adjacent body color and watercolor texture, seamlessly continuing the existing paint. No closed-eye strokes, no lashes, no replacement marks or empty sockets.
Constraints: Change only the eye marks. Preserve all 32 species, their exact positions, silhouettes, proportions, poses, orientations, mouths, gills, fins, species-specific body patterns, colors, paper grain, warm ivory background, composition, canvas aspect ratio and hand-drawn watercolor charcoal style as closely as possible. Preserve ordinary decorative body spots that are not eyes, including the yellow boxfish's blue spots, the eel's spots, and the large round flank marking of the John Dory. The user specifically wants to see the difference caused solely by removing eyes, so do not redesign the fish or change their mouths. Return ONE full sheet image. No text or labels.
