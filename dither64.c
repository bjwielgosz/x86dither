/*
void bwdither(void *img, uint32_t width, uint32_t height);
Quantize an 8 bpp grayscale image to black and white (2 levels only) using dithering.
Dithering error should propagate in a serpentine pattern: horizontally within pixel rows;
left-to-right, from the rightmost pixel in a row to the rightmost pixel in the next row, then
right-to left, then down (at the left edge).
*/


#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#define STBI_NO_SIMD
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"




//void bwdither32(void *img, uint32_t width, uint32_t height, uint32_t stride);
void bwdither64new(void *img, uint32_t width, uint32_t height, uint32_t stride);
void bwdither64(void *img, uint32_t width, uint32_t height, uint32_t stride);

int main(int argc, char *argv[])
{
    
    if (argc < 4) {
        fprintf(stderr, "Usage: %s <old/new> <input_image> <output_image>\n", argv[0]);
        return 1;
    }
    int w, h, channels;
    uint8_t *data = stbi_load(argv[2], &w, &h, &channels, 1);
    if (!data) {
        fprintf(stderr, "Failed to load image\n");
        return 1;
    }
    
    //int stride = (w + 3) & ~3; // row size rounded up to multiple of 4
    int stride = w;
    printf("Loaded: %dx%d, channels=%d, stride=%d\n", w, h, channels, stride);

    if (strcmp(argv[1], "old") == 0) {
        bwdither64(data, w, h, stride);
    } else if (strcmp(argv[1], "new") == 0) {
        bwdither64new(data, w, h, stride);
    } else {
        fprintf(stderr, "Invalid option: %s. Use 'old' or 'new'.\n", argv[1]);
        stbi_image_free(data);
        return 1;
    }

    // Save the dithered result
    stbi_write_bmp(argv[3], w, h, 1, data);
    stbi_image_free(data);
    fprintf(stdout, "Dithering completed successfully.\n");
    return 0;
}