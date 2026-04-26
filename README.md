# x86dither
Simple png grayscale ditherer written in x86 assembly.
The goal of this project was to quantize an 8 bpp grayscale image to black and white (2 levels only) using dithering.
It was implemented using x86 assembly, both 32 and 64 bit. There are two versions of the algorithm - old (proper Floyd-Steinberg dithering) and new (simpler dithering with no carry over between rows). The old one produces much prettier images, while the new one uses fewer memory references at the cost of image quality.

## Disclaimer
This project uses stb_image and stb_image_write by Sean Barrett.
These libraries are licensed under the MIT License.
Source: https://github.com/nothings/stb
