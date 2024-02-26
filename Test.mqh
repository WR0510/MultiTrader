#include "MultiTraderClasses.mqh"

class CFoo{
public:
    int var1;
    double var2;
    CFoo(){//default constructor
        var1 = 1;
        var2 = 2.0;
    }
    };
class CBar{
public:
    int var1;
    double var2;
    CBar(){//default constructor
        var1 = 1;
        var2 = 2.0;
    }
    };

class CTest{
public:
   
    CTest(){//default constructor
    }
    CTest(int general){//parametric constructor
        Print(general);
    }
    double func(CFoo *foo_pointer_in){
        Print(foo_pointer_in);
        return foo_pointer_in.var2;
    }
    int getVar1(CFoo *foo){
        return foo.var1;
    }
    double getVar2(CFoo *foo){
        return foo.var2;
    }
    void funcPassSymbolPointer(CSymbolHandler *symbol){
        Print(symbol);
    }
    int getMaxSpread(CSymbolHandler *symbol){
        return symbol.general.maxSpread;
        //return maxSpread_Symbol1;
    }
    };


    //usage example:
    //CFoo *foo_pointer = new CFoo();//--- declare a pointer to an object and create it using the 'new' operator
    //CTest *test;//declare a pointer to an object
    //test = new CTest();//create the object using the pointer declared earlier
    //int res1 = test.getVar1(foo_pointer);
    //double res2 = test.getVar2(foo_pointer);
    //int spread = test.getMaxSpread(GetPointer(this));

   