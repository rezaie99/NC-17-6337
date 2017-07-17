
#ifndef qualityModel_h
#define qualityModel_h

#include <stdio.h>

#define NUMBER_OF_BOOSTERS 30
#define NUMBER_OF_FEATURES 51

typedef struct QualityModel
{
    int noOfBoosters;
    float scale;
    float base;
    int*    yesTree[NUMBER_OF_BOOSTERS];
    int*    noTree[NUMBER_OF_BOOSTERS];
    int*    missingTree[NUMBER_OF_BOOSTERS];
    int*    fLabel[NUMBER_OF_BOOSTERS];
    float*  fValue[NUMBER_OF_BOOSTERS];
    float*  leafValue[NUMBER_OF_BOOSTERS];

} QualityModel_t;


QualityModel_t *InitFdModel(void);
QualityModel_t *InitTdModel(void);


#endif /* qualityModel_h */
