#ifndef GPT_CGPT_VM_H
#define GPT_CGPT_VM_H


#include "COptions.hpp"


class CGptVm
{
public:
   CGptVm( COptions *options );
   int run( );
private:
   COptions *_options;
};

#endif

