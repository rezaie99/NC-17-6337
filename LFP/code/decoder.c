#include <stdlib.h>
#include "decoder.h"
#include "codebook.c"

struct binaryTree
{
    int16_t key;
    struct binaryTree *left;
    struct binaryTree *right;
} optBinaryTree, accBinaryTree;

// Number of pointers used to create binary trees (both optical and accelerometer). It is needed to free memory at the end of the program
uint32_t treeCount=0;
uint32_t initializedOpticalTreeFlag = 0;
uint32_t initializedAccelerometerTreeFlag = 0;

// Array of pointers used to free memory at end of the program
struct binaryTree* trees[21000];

// Return the ceiling of log2 of x (np.ceil(np.log2(x)))
int32_t cielLog2( int32_t x )
{
    int32_t n=0;
    while ( (1<<n) < x)
    { n += 1; }
    return n;
}

// Returns the bit length of the input number. Assumes signed number input.
int32_t num2bitLen(int32_t number)
{
    int bitLen;
    if (number < 0)
    {
        bitLen = (int32_t)cielLog2(-1*number)+1;
    }
    else
    {
        bitLen = (int32_t)cielLog2(number+1)+1;
    }
    return bitLen;
};

// Initializes attributes and saves pointer for freeing at the end of the program.
void initializeTree(struct binaryTree* tree, int16_t noKey)
{
    tree->left = NULL;
    tree->right = NULL;
    tree->key = noKey;

    //Save pointer
    trees[treeCount] = tree;
    treeCount++;

    return;
}

// Free allocated memory used for binary trees (optical and accelerometer)
void freeBinaryTree()
{
    for (int32_t i=0; i<treeCount; i++)
    {
        free(trees[i]);
    }

    initializedOpticalTreeFlag = 0;
    initializedAccelerometerTreeFlag = 0;
    treeCount = 0;

    return;
}

/*
This function populates the optBinaryTree when optCodeBookFlag is set to  "1" or accBinaryTree when optCodeBookFlag is set to "0", using the opt and acc codebooks.
The tree is made of nodes and branches. The nodes contain a key value, a left pointer, and a right pointer. The pointers serve as branches of the tree.
A for loop iterates through each code in the codebook and another for loop iterates through the bits in a code.
We start populating the tree from the *head pointer. A "0" bit indicates a left branch, while a "1" a right branch. Depending on the bit we check is a branch (left or right) exists. If it exists, we just move the current pointer to it. If it doesn't, we create a new one and move the current pointer to it.
 As we iterate through the bits in a code and create branches, we copy noKey as the key of each node. This will indicate that this combination of bits is not a code. However, when we finish going through the bits in a code, we copy the corresponding value to the key attribute.
*/
void buildBinaryTree(int32_t optCodeBookFlag)
{
    codeBook_t* codeBook;
    int32_t codeBookLength, minEdge;
    struct binaryTree *head;

    if (optCodeBookFlag==1)
    {
        if (initializedOpticalTreeFlag==1)
        {
            //Tree was already built; return.
            return;
        }
        else
        {
            initializedOpticalTreeFlag = 1;
        }
        codeBookLength = NUMBER_OF_OPT_CODES;
        codeBook = (codeBook_t*)&optCodeBook;
        minEdge= OPT_MIN_EDGE;
        head = &optBinaryTree;
    }
    else
    {
        if (initializedAccelerometerTreeFlag==1)
        {
            //Tree was already build; return.
            return;
        }
        else
        {
            initializedAccelerometerTreeFlag=1;
        }

        initializedAccelerometerTreeFlag = 1;
        codeBookLength = NUMBER_OF_ACC_CODES;
        codeBook = (codeBook_t*)&accCodeBook;
        minEdge= ACC_MIN_EDGE;
        head = &accBinaryTree;
    }

    struct binaryTree *current, *temp;

    int16_t noKey = (int16_t)(minEdge-1); //noKey is the default value of a new branch

    // Allocate space for head or root of binary tree, and initalize attibutes
    head->right = NULL;
    head->left = NULL;
    head->key = noKey;

    //Iterate through codeBook and create branches of binary tree
    for (int32_t i=0; i<codeBookLength; i++)
    {
        int32_t key = (int16_t)(minEdge+i);
        int32_t code = codeBook[i].code;
        int32_t codeBitLength = codeBook[i].codeLength;

        // Point to the head of the tree.
        current = head;

        // Iterate through the bits in code to create branches:
        for (int32_t i=codeBitLength; i>0; i--)
        {
            int32_t bit = ( code & (1<<(i-1))) >> (i-1);

            // If bit is equal to 1: check if a right branch exists; otherwise create it
            if (bit)
            {

                if (current->right == NULL)
                {
                    // If a branch doesn't exist, create it.
                    temp = (struct binaryTree*)malloc(sizeof(struct binaryTree));
                    initializeTree(temp, noKey);

                    // Attach new branch.
                    current->right = temp;

                    // Move pointer to new branch.
                    current = temp;
                }
                else
                {
                    // If branch does exist, point to it.
                    current = current->right;
                }
            }
            else
            {
                if (current->left == NULL)
                {
                    // If a branch doesn't exist, create it.
                    temp = (struct binaryTree*)malloc(sizeof(struct binaryTree));
                    initializeTree(temp, noKey);

                    // Attach new branch.
                    current->left = temp;

                    // Move pointer to new branch.
                    current = temp;
                }
                else
                {
                    // If branch does exist, point to it.
                    current = current->left;
                }
            }
        }

        //When finished iterating through bits of a code, write in the key.
        current->key = key;
    }

    return;
}

/*
 This function reads a specified numberOfBits from bitStream at a given index and bitIndex within that index and returns its value. It also updates indexBit and index for the next reading.
 If indexBit is the same as numberOfBits, we can simply copy that current value at that index and shift right and then left to sign extend. Then increment index and reset bitIndex to 32.
 If indexBit is greater than numberOfBits, we need shift left to dispose of the extra bits on the left; then shift right and then left to sign extend. Only bitIndex gets updated.
 Lastly, if index bit is less than numberOfBits, we need to read bits from the current index, and some from the following word. First we mask out the bits we don't need, them shift to the left by the differene of (numberOfBits-indexBit). Increment index, and rest indexBit to 32. Now on the new index, mask out the left most bits we dont need. Finally we or (|) these new bits against the old ones from the previous index, resulting in the final value. Update indexBit again.
 */
int32_t getValueFromBitsInBuffer(uint32_t *bitStream, uint32_t *index, uint32_t *indexBit, uint32_t numberOfBits)
{
    int32_t value;

    if (*indexBit == numberOfBits)
    {
        value = bitStream[*index];

        // Sign extend
        value <<=(32-numberOfBits);
        value >>=(32-numberOfBits);

        // Update indices
        *index += 1;
        *indexBit = 32;
    }
    else if (*indexBit > numberOfBits)
    {
        value = (bitStream[*index]>>(*indexBit-numberOfBits));

        // Sign extend
        value <<= (32-numberOfBits);
        value >>= (32-numberOfBits);

        // Update indexBit only
        *indexBit -= numberOfBits;
    }
    else
    {
        // Copy the bits in the current index
        value = bitStream[*index] & (~(-1<<(*indexBit)));
        value <<= (numberOfBits - *indexBit);
        uint32_t bitsInNextIndex = numberOfBits-*indexBit;

        //Update indices
        *index += 1;
        *indexBit = 32;

        // Copy the rest of the bits from the next index
        value |= (bitStream[*index]>>(*indexBit - bitsInNextIndex)) & (~(-1<<(bitsInNextIndex)));

        // Sign extend
        value <<=(32-numberOfBits);
        value >>=(32-numberOfBits);

        // Update index again.
        *indexBit -=bitsInNextIndex;
    }
    return value;
}

/*
 This function performs a search on the binary tree to decode the bitStream data. The optical binary tree optBinaryTree is used if optCodeBookFlag is set to "1", and accCodeBookFlag is chosen if optCodeBookFlag is set to "0".
 The binary tree search consists of reading single bits from bitStream, and traversing through the tree. A left branch is chosen if the bit is "1", and a right branch if the bit is "0". Then, the key value at that branch is read. If the branch contains no value (noKey), a new bit is read from bitStream, and we traverse again through the tree. When a key value is found, it could either be the decoded value itself if it is within the minEdge and maxEdge, or a prefix. A prefix indicates the bitLength of the value whose value is be read as the following bits in bitStream.
decodeOpticalBits and decodeAccelerometer bits are nearly identical except for the output data type. decodeOpticalBits writes results to int32_t, while decodeAccelerometer uses int16_t.
 uint32_t* bitStream: pointer to input array of encoded data bits.
 uint32_t bitStreamMaxIndex: maximum index in bitStream that contains encoded data.
 uint32_t* index: index in bitStream that indicates what index in bitStream is currently being used to extract a bit.
 uint32_t* indexBit: indicates what bit in index in bitStream will be extracted next.

 int32_t* outValues: output array of decoded values.
 uint32_t* errorFlag: flag gets set when there is an error in decoding.
 */
void decodeOpticalBits(uint32_t* bitStream, uint32_t bitStreamMaxIndex, uint32_t* index, uint32_t* indexBit, int32_t* outValues, uint32_t* errorFlag)
{
    int32_t minEdge= OPT_MIN_EDGE;
    int32_t maxEdge = OPT_MAX_EDGE;
    int32_t edgeBitLen = OPT_EDGE_BIT_LENGTH;
    int32_t longestCode = OPT_LONGEST_HUFFMAN_CODE;
    int32_t bitResolution = OPT_BIT_RESOLUTION;
    struct binaryTree *tree = &optBinaryTree;
    int16_t noKey = (int16_t)minEdge-1;
    int16_t minCode = OPT_MIN_CODE;
    int16_t maxCode = OPT_MAX_CODE;
    int16_t successfully_decoded_flag = 0; // This flag is set when a value is successfully decoded

    // Keep a copy of the origin of the tree to reset pointer when a value is found and a new search needs to be started.
    struct binaryTree* head = tree;

    uint32_t bit, test;
    int32_t value;

    // The first value is not encoded. Read the value directly from bitStream
    outValues[0] = getValueFromBitsInBuffer(bitStream, index, indexBit, bitResolution);

    for (int32_t outIndex=1; outIndex<PACKET_LENGTH; outIndex++)
    {
        successfully_decoded_flag = 0; //reset flag
        test = longestCode;

        while (test>0)
        {
            // Decreate test count.
            test -=1;

            // Extract one bit. Shift right so that desired bit is the LSB, then mask out the bits left of the LSB.
            bit = (bitStream[*index]>>(*indexBit-1)) & 1;

            //Update indices
            *indexBit -=1;

            // Check that index does not go past maximum bitStream index
            if (*index > bitStreamMaxIndex)
            {
                *errorFlag = 1;
                return;
            }

            if (*indexBit==0)
            {
                *indexBit=32;
                *index +=1;
            }

            // Traverse tree
            if (bit==1)
            {
                if (tree->right == NULL)
                {
                    // Trying to access a non-existent node
                    *errorFlag = 1;
                    return;
                }
                else
                {
                    tree = tree->right;
                }
            }
            else
            {
                if (tree->left == NULL)
                {
                    // Trying to access a non-existent node
                    *errorFlag = 1;
                    return;
                }
                else
                {
                    tree = tree->left;
                }
            }

            // Check if value exists and that it is within range of possible decodable values
            if ( (tree->key != noKey) && (tree->key <= maxCode) && (tree->key >= minCode))
            {
                if (tree->key > maxEdge)
                {
                    uint32_t numberOfBits = edgeBitLen + tree->key - maxEdge;
                    value = getValueFromBitsInBuffer(bitStream, index, indexBit, numberOfBits);
                }
                else
                {
                    // Append found value
                    value = (int32_t)tree->key;
                }

                // Store decode value
                outValues[outIndex] = outValues[outIndex-1] + value;

                // Set test condition to zero to exit.
                test = 0;

                // Point the tree back to its origin
                tree = head;

                // Set flag
                successfully_decoded_flag = 1;
            }

        } // while

        //If flag was not set, the value was not decoded. Bits did not match anything
        if (successfully_decoded_flag==0)
        {
            *errorFlag = 1;
            return;
        }

    } //for

    return;
}

void decodeAccelerometerBits(uint32_t* bitStream, uint32_t bitStreamMaxIndex, uint32_t* index, uint32_t* indexBit, int16_t* outValues, uint32_t* errorFlag)
{
    int32_t minEdge= ACC_MIN_EDGE;
    int32_t maxEdge = ACC_MAX_EDGE;
    int32_t edgeBitLen = ACC_EDGE_BIT_LENGTH;
    int32_t longestCode = ACC_LONGEST_HUFFMAN_CODE;
    int32_t bitResolution = ACC_BIT_RESOLUTION;
    struct binaryTree *tree = &accBinaryTree;
    int16_t noKey = (int16_t)minEdge-1;
    int16_t minCode = ACC_MIN_CODE;
    int16_t maxCode = ACC_MAX_CODE;
    int16_t successfully_decoded_flag = 0; // This flag is set when a value is successfully decoded

    // Keep a copy of the origin of the tree to reset pointer when a value is found and a new search needs to be started.
    struct binaryTree* head = tree;

    uint32_t bit, test;
    int32_t value;

    // The first value is not encoded. Read the value directly from bitStream
    outValues[0] = getValueFromBitsInBuffer(bitStream, index, indexBit, bitResolution);

    for (int32_t outIndex=1; outIndex<PACKET_LENGTH; outIndex++)
    {
        successfully_decoded_flag = 0; //reset flag
        test = longestCode;

        while (test>0)
        {
            // Decreate test count.
            test -=1;

            // Extract one bit. Shift right so that desired bit is the LSB, then mask out the bits left of the LSB.
            bit = (bitStream[*index]>>(*indexBit-1)) & 1;

            // Update indices
            *indexBit -=1;

            // Check that index does not go past maximum bitStream index
            if (*index > bitStreamMaxIndex)
            {
                *errorFlag = 1;
                return;
            }

            if (*indexBit==0)
            {
                *indexBit=32;
                *index +=1;
            }

            // Traverse tree
            if (bit==1)
            {
                if (tree->right == NULL)
                {
                    // Trying to access a non-existent node
                    *errorFlag = 1;
                    return;
                }
                else
                {
                    tree = tree->right;
                }
            }
            else
            {
                if (tree->left == NULL)
                {
                    // Trying to access a non-existent node
                    *errorFlag = 1;
                    return;
                }
                else
                {
                    tree = tree->left;
                }
            }

            // Check if value exists and that it is within range of possible decodable values
            if ( (tree->key != noKey) && (tree->key <= maxCode) && (tree->key >= minCode))
            {
                if (tree->key > maxEdge)
                {
                    uint32_t numberOfBits = edgeBitLen + tree->key - maxEdge;
                    value = getValueFromBitsInBuffer(bitStream, index, indexBit, numberOfBits);
                }
                else
                {
                    // Append found value
                    value = (int32_t)tree->key;
                }

                // Store decode value
                outValues[outIndex] = outValues[outIndex-1] + value;

                // Set test condition to zero to exit.
                test = 0;

                // Point the tree back to its origin
                tree = head;

                // Set flag
                successfully_decoded_flag = 1;
            }

        } // while

        //If flag was not set, the value was not decoded. Bits did not match anything
        if (successfully_decoded_flag==0)
        {
            *errorFlag = 1;
            return;
        }

    } //for

    return;
}

// This function decodes bitStream and stores the result in the optical and accelerometer buffers.
void decodePacket(uint32_t* bitStream, uint32_t byteCount, int32_t* opt, int16_t* accX, int16_t* accY, int16_t* accZ, uint32_t *errorFlag)
{
    uint32_t index = 0;
    uint32_t indexBit = 32;
    uint32_t wordCount = byteCount/4;
    uint32_t bitStreamMaxIndex = wordCount - 1; // change count to index

    decodeOpticalBits(bitStream, bitStreamMaxIndex, &index, &indexBit, opt, errorFlag);
    if (*errorFlag)
    {
        return;
    }

    decodeAccelerometerBits(bitStream, bitStreamMaxIndex, &index, &indexBit, accX, errorFlag);
    if (*errorFlag)
    {
        return;
    }

    decodeAccelerometerBits(bitStream, bitStreamMaxIndex, &index, &indexBit, accY, errorFlag);
    if (*errorFlag)
    {
        return;
    }

    decodeAccelerometerBits(bitStream, bitStreamMaxIndex, &index, &indexBit, accZ, errorFlag);
    if (*errorFlag)
    {
        return;
    }

    int32_t wordCountRead;
    if (indexBit == 32)
    {
        wordCountRead = index;
    }
    else
    {
        wordCountRead = index + 1;
    }

    //Check that index is the same as number of encoded words
    if (wordCountRead != wordCount)
    {
        *errorFlag = 1;
    }
    else
    {
        // If index does match bitStreamMaxIndex, make sure that the rest of the bits are zero
        uint32_t bit;
        while ( (indexBit>0) && (errorFlag==0))
        {
            // Extract one bit. Shift right so that desired bit is the LSB, then mask out the bits left of the LSB.
            bit = (bitStream[index]>>(indexBit-1)) & 1;

            if (bit)
            {
                *errorFlag=1;
            }
            indexBit +=1;
        }
    }

    return;
}
