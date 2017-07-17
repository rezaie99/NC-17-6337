
#ifndef DECODER_H
#define DECODER_H

#include <stdio.h>

void buildBinaryTree(int32_t optCodeBookFlag);
void freeBinaryTree();
void decodePacket(uint32_t* bitStream, uint32_t byteCount, int32_t* opt, int16_t* accX, int16_t* accY, int16_t* accZ, uint32_t *errorFlag);

#endif /* DECODER_H */
