# Standing distraction penguin

The built-in image generator used the approved slim penguin studies to make the two sprite sheets. The prompts are in `bloom-prompt.txt` and `lights-prompt.txt`. Run `python3 docs/companion/standing-distractions/prepare-assets.py` with Pillow to package the sheets into the PixelCoveV2 asset catalog.

Crystal Bloom starts each batch on the first breath frame, 0.5 seconds into the batch. The last crouch drawing in the source is reserved. During distraction the character settles into a standing pose. When distraction ends the companion returns through its existing cast animation.

The light switch drawing reaches DOWN at the start of dimming and UP at the start of brightening. Both beats also drive the sound cursor, including when cycles shorten.
