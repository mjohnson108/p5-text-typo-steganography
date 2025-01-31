# p5-text-typo-steganography

Approaches to steganography often take the form of introducing what looks like noise to a signal (the "carrier"), however the "noise" is actually a hidden signal (the "payload"). This is done so that others inspecting the carrier do not suspect the presence of the hidden payload - only the intended recipients know to look for the payload.

Many methods use images as the carrier. The approach presented here involves introducing 'plausible' typos to a document so that they encode a payload text. A carrier text is broken into large chunks (e.g. 1,000 chars) and the typos introduced into each successive chunk until a simple digest of the chunk encodes a payload character. To make the typos 'plausible', a measure of keyboard distance is used, so that characters are used which are keyboard-adjacent on a QWERTY keyboard to a carrier text char. This gives the impression that someone has been typing hastily. The typos are introduced systematically to minimize the number of typos in the chunk.

Decoding the package (carrier encoded with payload) is a simple matter of chunking the text and passing through the digest function, the output of which directly codes for a payload character.

