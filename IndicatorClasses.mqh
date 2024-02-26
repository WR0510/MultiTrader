#include <Trade\Trade.mqh> //Trades Execution Library
#include <Trade\OrderInfo.mqh> //Library for Orders Information
CTrade trade;
COrderInfo orderInfo;

class CIndicatorBase{
    protected:
        bool isInitialized;
        string description;
        string pair;
        ENUM_TIMEFRAMES period;
        int handle;
        int shift;
        int amount;
        ENUM_APPLIED_PRICE applied_price;
        bool buySignal;
        bool sellSignal;
        bool closeBuySignal;
        bool closeSellSignal;
    public:
        virtual string getDescription(){
            logWarn(__FUNCTION__,"No description for indicator found");
            return "No description found";
            };
        virtual void updateValues(double closingPrice){//This function must be present but all derived classes should have a specific variant, the virtual keyword will make sure the function is called from the derived object
            logWarn(__FUNCTION__,"Derived class has no updateValues function");
            };
        virtual bool getBuySignal(){logWarn(__FUNCTION__,"Derived class has no checkBuySignal method");return false;};
        virtual bool getSellSignal(){logWarn(__FUNCTION__,"Derived class has no checkSellSignal method");return false;};
        virtual bool getCloseBuySignal(){return false;};
        virtual bool getCloseSellSignal(){return false;};
        virtual bool resetIndicator(){;return false;};
        virtual bool initialize(string pairIn,ENUM_TIMEFRAMES period_in,int bands_period_in,int bands_shift_in,int amount_in,double deviation_in,ENUM_APPLIED_PRICE applied_price_in){return false;};//BB overload (virutal functions will be overridden by derived classes)
        virtual bool initialize(string pairIn,ENUM_TIMEFRAMES period_in,int ma_period_in,ENUM_APPLIED_PRICE applied_price_in,double RSIoverboughtLevel_in,double RSIoversoldLevel_in){return false;};//RSI overload
        virtual bool initialize(string pair_in,ENUM_TIMEFRAMES period_in,ENUM_ENVELOPES_SIGNAL_MODE signal_mode_in,int envelopes_period_in,int shift_in,ENUM_MA_METHOD method_in,ENUM_APPLIED_PRICE applied_price_in,double deviation_in){return false;};//Envelopes overload
        virtual bool initialize(string pairIn,ENUM_TIMEFRAMES period_in,int ma_period_in,int ma_shift_in,ENUM_MA_METHOD ma_method_in,ENUM_APPLIED_PRICE ma_applied_price_in){return false;};//Moving average overload
        virtual bool initialize(string pairIn,ENUM_TIMEFRAMES period_in,int Kperiod_in,int Dperiod_in,int slowing_in,ENUM_MA_METHOD ma_method_in,ENUM_STO_PRICE price_field_in){return false;};//Stochastic overload
        virtual bool initialize(string pairIn,ENUM_TIMEFRAMES period_in,int ha_period_in,ENUM_MA_METHOD ha_method,int ha_step,bool ha_formula){return false;};//Heiken Ashi Smoothed overload
    CIndicatorBase(void){};
    ~CIndicatorBase(void){};
    };
class CIndicatorBB final:public CIndicatorBase{
    private:
        int bands_period;
        double deviation;
        double base_values[];
        double upper_values[];
        double lower_values[];
    public:
        CIndicatorBB(void){//constructor
            logDebug(__FUNCTION__,"Bollinger Bands indicator loaded");
            };
        bool getIsInitialized(){return isInitialized;};
        string getDescription(){return description;};
        bool getBuySignal(){return buySignal;};
        bool getSellSignal(){return sellSignal;};
        bool initialize(string pairIn,ENUM_TIMEFRAMES period_in,int bands_period_in,int bands_shift_in,int amount_in,double deviation_in,ENUM_APPLIED_PRICE applied_price_in){
            description = "Bollinger Bands";
            pair = pairIn;
            period = period_in;
            bands_period = bands_period_in;
            shift = bands_shift_in;
            amount = amount_in;
            deviation = deviation_in;
            applied_price = applied_price_in;
            handle = iBands(pair,period,bands_period,shift,deviation,applied_price);
            if(handle==INVALID_HANDLE){
                logError(__FUNCTION__,"Failed to create handle for the iBands indicator for the symbol: " + pair + EnumToString(period) + " error code: " + string(GetLastError()));
                Alert("ERROR initializing indicator: iBands");
                isInitialized = false;
            }else{
                logDebug(__FUNCTION__,"iBands indicator succesfully initialized for the symbol:" + pair + " " + EnumToString(period));
                isInitialized = true;
            }
            if(isInitialized){
               return true;
            }else{
               return false;
            }
            };
        void updateValues(double closingPrice){
            if(isInitialized == true){
                ResetLastError();
                bool copyBufferOK = true;
                if(CopyBuffer(handle,0,shift,amount,base_values)<0){ //--- fill a part of the MiddleBuffer array with values from the indicator buffer that has 0 index 
                    logError(__FUNCTION__,"ERROR: Failed to copy data from the iBands indicator, error code: " + string(GetLastError()));//--- if the copying fails, tell the error code 
                    copyBufferOK = false;
                    } 
                if(CopyBuffer(handle,1,shift,amount,upper_values)<0){ //--- fill a part of the UpperBuffer array with values from the indicator buffer that has index 1 
                    logError(__FUNCTION__,"ERROR: Failed to copy data from the iBands indicator, error code: " + string(GetLastError())); //--- if the copying fails, tell the error code 
                    copyBufferOK = false;
                    }    
                if(CopyBuffer(handle,2,shift,amount,lower_values)<0){//--- fill a part of the LowerBuffer array with values from the indicator buffer that has index 2 
                    logError(__FUNCTION__,"ERROR: Failed to copy data from the iBands indicator, error code: " + string(GetLastError()));//--- if the copying fails, tell the error code 
                    copyBufferOK = false;
                    } 
                if(copyBufferOK){
                    logTrace(__FUNCTION__,"Bollinger bands (" + pair + ") Upper band=" + string(upper_values[0]) + ", Lower band=" + string(lower_values[0]));
                }else{
                    logError(__FUNCTION__,"ERROR while updating the values for Bollinger bands. Symbol : " + pair);
                }
                if(closingPrice < lower_values[0]){
                    buySignal = true;
                }else{
                    buySignal = false;
                }
                if(closingPrice > upper_values[0]){
                    sellSignal = true;
                }else{
                    sellSignal = false;
                }
                logTrace(__FUNCTION__,"Bollinger bands signals: buy=" + boolToText(buySignal) + " sell=" + boolToText(sellSignal) + " close:" + string(closingPrice));
            }else{
                logError(__FUNCTION__,"ERROR: The values cannot be updated because the indicator Bollinger bands is not initialized for pair: " + pair);
            }
            };
    };
class CIndicatorRSI final:public CIndicatorBase{
    private:
        int RSI_period;
        double values[];
        double RSIoverboughtLevel;
        double RSIoversoldLevel;
        bool checkPreviousSignal;
        bool previousSignalWasBuy;
        bool previousSignalWasSell;
    public:
        CIndicatorRSI(void){//constructor
            logDebug(__FUNCTION__,"RSI indicator loaded");
            };
        bool getIsInitialized(){return isInitialized;};
        string getDescription(){return description;};
        bool getBuySignal(){return buySignal;};
        bool getSellSignal(){return sellSignal;};
        bool initialize(string pairIn,ENUM_TIMEFRAMES period_in,int ma_period_in,ENUM_APPLIED_PRICE applied_price_in,double RSIoverboughtLevel_in,double RSIoversoldLevel_in){
            description = "RSI";
            pair = pairIn;
            period = period_in;
            amount = 1;
            RSI_period = ma_period_in;
            applied_price = applied_price_in;
            RSIoverboughtLevel = RSIoverboughtLevel_in;
            RSIoversoldLevel = RSIoversoldLevel_in;
            checkPreviousSignal = true;
            handle = iRSI(pair,period,RSI_period,applied_price);
            if(handle==INVALID_HANDLE){
                logError(__FUNCTION__,"Failed to create handle for the iRSI indicator for the symbol: " + pair + EnumToString(period) + " error code: " + string(GetLastError()));
                Alert("ERROR initializing indicator: iRSI");
                isInitialized = false;
            }else{
                logDebug(__FUNCTION__,"iRSI indicator succesfully initialized for the symbol: " + pair + " " + EnumToString(period));
                isInitialized = true;
            }
            if(isInitialized){
               return true;
            }else{
               return false;
            }
            };
        void updateValues(double closingPrice){
            if(isInitialized == true){
                ResetLastError();
                if(CopyBuffer(handle,0,0,amount,values)<0){ 
                    logError(__FUNCTION__,"Failed to copy data from the iRSI indicator, error code: " + string(GetLastError()));
                }
                logTrace(__FUNCTION__,"RSI values (" + pair + ") RSI=" + string(values[0]));
                if(values[0] < RSIoversoldLevel){
                    buySignal = true;
                    if(checkPreviousSignal){
                        if(previousSignalWasBuy){// the buy signal was set before, do not set again until it is reset
                            buySignal = false;// do not set the buy signal until the previous signal has been reset
                        }
                        previousSignalWasBuy = true;
                    }
                }else{
                    buySignal = false;
                    if(checkPreviousSignal){
                        previousSignalWasBuy = false;
                    }
                }
                if(values[0] > RSIoverboughtLevel){
                    sellSignal = true;
                    if(checkPreviousSignal){
                        if(previousSignalWasSell){
                            sellSignal = false;// do not set the sell signal until the previous signal has been reset
                        }
                        previousSignalWasSell = true;
                    }
                }else{
                    sellSignal = false;
                    if(checkPreviousSignal){
                        previousSignalWasSell = false;
                    }
                }
                logTrace(__FUNCTION__,"RSI signals: buy=" + boolToText(buySignal) + " sell=" + boolToText(sellSignal) + " close:" + string(closingPrice));
            }else{
                logError(__FUNCTION__,"ERROR: The values cannot be updated because the indicator RSI is not initialized for pair: " + pair);
            }
            };
    };
class CIndicatorStochastic final:public CIndicatorBase{
    private:
        int Kperiod;
        int Dperiod;
        int slowing;
        ENUM_MA_METHOD ma_method;
        ENUM_STO_PRICE price_field;
        double valuesMain[];
        double valuesSignal[];
        string signalComment;
    public:
        CIndicatorStochastic(void){
            logDebug(__FUNCTION__,"Stochastic indicator loaded");
        }
        bool getIsInitialized(){return isInitialized;};
        string getDescription(){return description;};
        bool getBuySignal(){return buySignal;};
        bool getSellSignal(){return sellSignal;};
        bool initialize(string pairIn,ENUM_TIMEFRAMES period_in,int Kperiod_in,int Dperiod_in,int slowing_in,ENUM_MA_METHOD ma_method_in,ENUM_STO_PRICE price_field_in){
            description = "Stochastic";
            pair = pairIn;
            period = period_in;
            amount = 1;
            Kperiod = Kperiod_in;
            Dperiod = Dperiod_in;
            slowing = slowing_in;
            ma_method = ma_method_in;
            price_field = price_field_in;
            handle = iStochastic(pair,period,Kperiod,Dperiod,slowing,ma_method,price_field);    
            if(handle==INVALID_HANDLE){
                logError(__FUNCTION__,"Failed to create handle for the iStochastic indicator for the symbol: " + pair + EnumToString(period) + " error code: " + string(GetLastError()));
                Alert("ERROR initializing indicator: IStochastic");
                isInitialized = false;
            }else{
                logDebug(__FUNCTION__,"iStochastic indicator succesfully initialized for the symbol:" + pair + " " + EnumToString(period));
                isInitialized = true;
            }
            if(isInitialized){
               return true;
            }else{
               return false;
            }
            }
        void updateValues(double closingPrice){
            signalComment = "";
            if(isInitialized == true){
                ResetLastError();
                bool copyBufferOK = true;
                if(CopyBuffer(handle,MAIN_LINE,0,amount,valuesMain)<0){ 
                    logError(__FUNCTION__,"Failed to copy data from the iStochastic indicator, error code: " + string(GetLastError()));//--- if the copying fails, tell the error code 
                    copyBufferOK = false;
                } 
                if(CopyBuffer(handle,SIGNAL_LINE,0,amount,valuesSignal)<0){ 
                    logError(__FUNCTION__,"Failed to copy data from the iStochastic indicator, error code: " + string(GetLastError()));//--- if the copying fails, tell the error code 
                    copyBufferOK = false;
                }
                if(copyBufferOK){
                    logTrace(__FUNCTION__,"Stochastic values (" + pair + ") main:" + string(valuesMain[0]) + ",signal:" + string(valuesSignal[0]));
                    if(valuesSignal[0] < valuesMain[0]){
                        buySignal = true;
                        sellSignal = false;
                        signalComment = " stoch buy=true(" + string(valuesSignal[0]) + "<" + string(valuesMain[0]);
                    }else{
                        buySignal = false;
                        sellSignal = true;
                        signalComment = " stoch sell=true(" + string(valuesSignal[0]) + "<" + string(valuesMain[0]);
                    }
                    //update signals
                }else{
                    logError(__FUNCTION__,"Error while updating the values for Stochastic. Symbol : " + pair);
                }
                logTrace(__FUNCTION__,"Stochastic signals: buy=" + boolToText(buySignal) + " sell=" + boolToText(sellSignal) + " close:" + string(closingPrice));
            }else{
                logError(__FUNCTION__,"ERROR: The values cannot be updated because the indicator Stochastic is not initialized for pair: " + pair);
            }
            };
    };
class CIndicatorEnvelopes final:public CIndicatorBase{
    private:
        ENUM_ENVELOPES_SIGNAL_MODE signalMode;
        ENUM_ENVELOPES_STEP stepMode;
        int envelopes_period;
        ENUM_MA_METHOD method;
        double deviation;
        double upper_values[];
        double lower_values[];
        CIndicatorStochastic Stochastic;

    public:
        CIndicatorEnvelopes(void){
            logDebug(__FUNCTION__,"Envelopes indicator loaded");
            };
        //Get/Set
        bool getIsInitialized(){return isInitialized;};
        string getDescription(){return description;};
        bool getBuySignal(){return buySignal;};
        bool getSellSignal(){return sellSignal;};
        void setSignalMode(ENUM_ENVELOPES_SIGNAL_MODE signal_mode_in){
            signalMode = signal_mode_in;
            };
        void setStep(ENUM_ENVELOPES_STEP step_in){
            if(stepMode != step_in){
                logDebug(__FUNCTION__,"Changing envelopes step from " + EnumToString(stepMode) + " to " + EnumToString(step_in));
                stepMode = step_in;
            }
            };
        //Public Functions
        bool initialize(string pair_in,ENUM_TIMEFRAMES period_in,ENUM_ENVELOPES_SIGNAL_MODE signal_mode_in,int envelopes_period_in,int shift_in,ENUM_MA_METHOD method_in,ENUM_APPLIED_PRICE applied_price_in,double deviation_in){
            description = "Envelopes";
            pair = pair_in;
            signalMode = signal_mode_in;
            stepMode = ENVELOPES_STEP_IN_BOUNDS;
            period = period_in;
            envelopes_period = envelopes_period_in;
            amount = 1;
            shift = shift_in;
            method = method_in;
            applied_price = applied_price_in;
            deviation = deviation_in;
            handle = iEnvelopes(pair,period,envelopes_period,shift,method,applied_price,deviation);
            if(handle==INVALID_HANDLE){
                logError(__FUNCTION__,"Failed to create handle for the iEnvelopes indicator for the symbol: " + pair + EnumToString(period) + " error code: " + string(GetLastError()));
                Alert("ERROR initializing indicator: iEnvelopes");
                isInitialized = false;
            }else{
                if(signalMode == ENVELOPES_MODE_BREAKOUT_STOCHASTIC){
                   if(Stochastic.initialize(pair,period,5,3,3,MODE_SMA,STO_LOWHIGH)){//init sub-indicator
                     logDebug(__FUNCTION__,"iEnvelopes sub indicator Stochastic is initialized");
                     isInitialized = true;
                   }
                }else{//no sub indicator required
                    isInitialized = true;
                }
            }
            if(isInitialized){
               logDebug(__FUNCTION__,"iEnvelopes indicator succesfully initialized for the symbol:" + pair + " " + EnumToString(period));
               return true;
            }else{
               return false;
            }
            };
        void updateValues(double closingPrice){
            if(isInitialized == true){
                ResetLastError();
                if(CopyBuffer(handle,0,shift,amount,upper_values)<0){
                    logError(__FUNCTION__,"ERROR Failed to copy data from the iEnvelope indicator upper values, error code: " + string(GetLastError()));
                    }
                if(CopyBuffer(handle,1,shift,amount,lower_values)<0){
                    logError(__FUNCTION__,"ERROR Failed to copy data from the iEnvelope indicator upper values, error code: " + string(GetLastError()));
                    }
                logTrace(__FUNCTION__,"Envelopes values (" + pair + ") Upper:" + string(upper_values[0]) + "|Lower:" + string(lower_values[0]) + "|current step=" + EnumToString(stepMode));
                string signalComment = "";
                switch(stepMode){
                    case ENVELOPES_STEP_IN_BOUNDS:
                        if(closingPrice > lower_values[0] && closingPrice < upper_values[0]){//closingprice is within upper and lower bounds
                            buySignal = false;
                            sellSignal = false;
                            break;//exit switch, no need to change the step when the closing price is within the bounds
                        }else{
                            if(closingPrice > upper_values[0]){//closing price is above upper bound
                                switch(signalMode){
                                    case ENVELOPES_MODE_PULLBACK:
                                        setStep(ENVELOPES_STEP_BREAKOUT_HIGH);
                                        break;
                                    case ENVELOPES_MODE_BREAKOUT:
                                        setStep(ENVELOPES_STEP_BREAKOUT_HIGH);
                                        break;
                                    case ENVELOPES_MODE_RE_ENTRY:
                                        setStep(ENVELOPES_STEP_WAIT_RE_ENTRY_HIGH);
                                        break;
                                    case ENVELOPES_MODE_BREAKOUT_STOCHASTIC:
                                        setStep(ENVELOPES_STEP_WAIT_STOCHASTIC_HIGH);
                                        break;
                                    default:
                                        buySignal = false;
                                        sellSignal = false;
                                }
                            }else if(closingPrice < lower_values[0]){//closing price is under lower bound
                                switch(signalMode){
                                    case ENVELOPES_MODE_PULLBACK:
                                        setStep(ENVELOPES_STEP_BREAKOUT_LOW);
                                        break;
                                    case ENVELOPES_MODE_BREAKOUT:
                                        setStep(ENVELOPES_STEP_BREAKOUT_LOW);
                                        break;
                                    case ENVELOPES_MODE_RE_ENTRY:
                                        setStep(ENVELOPES_STEP_WAIT_RE_ENTRY_LOW);
                                        break;
                                    case ENVELOPES_MODE_BREAKOUT_STOCHASTIC:
                                        
                                        setStep(ENVELOPES_STEP_WAIT_STOCHASTIC_LOW);
                                        break;
                                    default:
                                        buySignal = false;
                                        sellSignal = false;
                                }
                            }
                        }
                    }
                switch(stepMode){
                    case ENVELOPES_STEP_BREAKOUT_HIGH:
                        if(closingPrice > upper_values[0]){//check if the closing price is still above upper bound
                            if(signalMode == ENVELOPES_MODE_BREAKOUT){
                                buySignal = true;
                                signalComment += " buy=true("+ string(closingPrice) +">" + string(upper_values[0]) + ")";
                            }else if(signalMode == ENVELOPES_MODE_PULLBACK){
                                sellSignal = true;
                                signalComment += " sell=true("+ string(closingPrice) + ">" + string(upper_values[0]) + ")";
                            }
                        }else{
                            if(signalMode == ENVELOPES_MODE_BREAKOUT){
                                buySignal = false;
                                signalComment += " buy=false("+ string(closingPrice) + "<" + string(upper_values[0]) + ")";
                            }else if(signalMode == ENVELOPES_MODE_PULLBACK){
                                sellSignal = false;
                                signalComment += " sell=false("+ string(closingPrice) + "<" + string(upper_values[0]) + ")";
                            }
                            setStep(ENVELOPES_STEP_IN_BOUNDS);
                        }
                        break;
                    case ENVELOPES_STEP_BREAKOUT_LOW:
                        if(closingPrice < lower_values[0]){//check if the closing price is under lower bound
                            if(signalMode == ENVELOPES_MODE_BREAKOUT){
                                sellSignal = true;
                                signalComment += " sell=true("+ string(closingPrice) + "<" + string(lower_values[0]) + ")";
                            }else if(signalMode == ENVELOPES_MODE_PULLBACK){
                                buySignal = true;
                                signalComment += " buy=true("+ string(closingPrice) + "<" + string(lower_values[0]) + ")";
                            }
                        }else{
                            if(signalMode == ENVELOPES_MODE_BREAKOUT){
                                sellSignal = false;
                                signalComment += " sell=false("+ string(closingPrice) + ">" + string(lower_values[0]) + ")";
                            }else if(signalMode == ENVELOPES_MODE_PULLBACK){
                                buySignal = false;
                                signalComment += " buy=false("+ string(closingPrice) + ">" + string(lower_values[0]) + ")";
                            }
                            setStep(ENVELOPES_STEP_IN_BOUNDS);
                        }
                        break;
                    case ENVELOPES_STEP_WAIT_RE_ENTRY_HIGH:
                        if(closingPrice < upper_values[0]){//closing price re-entering bounds
                            sellSignal = true;
                            signalComment += " sell=true("+ string(closingPrice) + "<" + string(upper_values[0]) + ")";
                            setStep(ENVELOPES_STEP_IN_BOUNDS);
                        }else{//closing price still higher than the upper bound
                            sellSignal = false;
                            signalComment += " sell=false("+ string(closingPrice) + "<" + string(upper_values[0]) + ")";
                        }
                        break;
                    case ENVELOPES_STEP_WAIT_RE_ENTRY_LOW:
                        if(closingPrice > lower_values[0]){
                            buySignal = true;
                            signalComment += " buy=true("+ string(closingPrice) + ">" + string(lower_values[0]) + ")";
                            setStep(ENVELOPES_STEP_IN_BOUNDS);
                        }else{
                            buySignal = false;
                            signalComment += " buy=false("+ string(closingPrice) + ">" + string(lower_values[0]) + ")";
                        }
                        break;
                    case ENVELOPES_STEP_WAIT_STOCHASTIC_HIGH:
                        Stochastic.updateValues(closingPrice);
                        if(Stochastic.getSellSignal()){
                            sellSignal = true;
                            signalComment += " sell=true(stochastic sell=true)";
                        }else{
                            sellSignal = false;
                            signalComment += " waiting for stochactic sell signal";
                        }
                    case ENVELOPES_STEP_WAIT_STOCHASTIC_LOW:
                        Stochastic.updateValues(closingPrice);
                        if(Stochastic.getBuySignal()){
                            buySignal = true;
                            signalComment += " buy=true(stochastic buy=true)";
                        }else{
                            buySignal = false;
                            signalComment += " waiting for stochastic buy signal";
                        }
                    default:
                        break;
                    }
                logTrace(__FUNCTION__,"Envelopes signals: buy=" + boolToText(buySignal) + " sell=" + boolToText(sellSignal) + " comment=" + signalComment);
            }else{
                logError(__FUNCTION__,"ERROR: The values cannot be updated because the indicator Envelopes is not initialized for pair: " + pair);
            }
            };
        bool resetIndicator(){
            setStep(ENVELOPES_STEP_IN_BOUNDS);
            return true;
            };
    };
class CIndicatorMA final:public CIndicatorBase{
    private:
        int ma_period;
        ENUM_MA_METHOD method;
        double values[];
    public:
        CIndicatorMA(void){
            logDebug(__FUNCTION__,"Moving Average indicator loaded");
            };
        bool getIsInitialized(){return isInitialized;};
        string getDescription(){return description;};
        bool getBuySignal(){return buySignal;};
        bool getSellSignal(){return sellSignal;};
        bool initialize(string pairIn,ENUM_TIMEFRAMES period_in,int ma_period_in,int ma_shift_in,ENUM_MA_METHOD ma_method_in,ENUM_APPLIED_PRICE ma_applied_price_in){
            description = "Moving average";
            pair = pairIn;
            period = period_in;
            ma_period = ma_period_in;
            amount = 1;
            shift = ma_shift_in;
            method = ma_method_in;
            applied_price = ma_applied_price_in;
            handle = iMA(pair,period,ma_period,shift,method,applied_price);
            if(handle==INVALID_HANDLE){
                logError(__FUNCTION__,"Failed to create handle for the iMA indicator for the symbol: " + pair + EnumToString(period) + " error code: " + string(GetLastError()));
                Alert("ERROR initializing indicator: iMA");
                isInitialized = false;
            }else{
                logDebug(__FUNCTION__,"iMA indicator succesfully initialized for the symbol:" + pair + " " + EnumToString(period));
                isInitialized = true;
            }
            if(isInitialized){
               return true;
            }else{
               return false;
            }
            };
        void updateValues(double closingPrice){
            if(isInitialized == true){
                ResetLastError();
                if(CopyBuffer(handle,0,shift,amount,values)<0){
                    logError(__FUNCTION__,"Failed to copy data from the iMA indicator, error code: " + string(GetLastError()));
                }
                logTrace(__FUNCTION__,"Moving average(" + pair + ")" + string(values[0]));
                if(closingPrice < values[0]){
                    buySignal = true;
                }else{
                    buySignal = false;
                }
                if(closingPrice > values[0]){
                    sellSignal = true;
                }else{
                    sellSignal = false;
                }
                logTrace(__FUNCTION__,"Moving average signals: buy=" + boolToText(buySignal) + " sell=" + boolToText(sellSignal) + " close:" + string(closingPrice));
            }else{
                logError(__FUNCTION__,"ERROR: The values cannot be updated because the indicator Moving average is not initialized for pair: " + pair);
            }
        };
    };
class CindicatorHeikenAshiSmoothed : public CIndicatorBase{
    private:
        //int ha_period;
        string ha_name;
        //ENUM_MA_METHOD ha_method;
        //int ha_step;
        //bool ha_formula;
        double hah[],hal[],hao[],hac[],haC[];//Heiken Ashi Smoothed values
    public:
        CindicatorHeikenAshiSmoothed(void){
            logDebug(__FUNCTION__,"Heiken Ashi Smoothed");
            };
        bool getIsInitialized(){return isInitialized;};
        string getDescription(){return description;};
        bool getBuySignal(){return buySignal;};
        bool getSellSignal(){return sellSignal;};
        bool getCloseBuySignal(){return closeBuySignal;};
        bool getCloseSellSignal(){return closeSellSignal;};
        bool initialize(string pair_in,ENUM_TIMEFRAMES period_in,int ha_period_in,ENUM_MA_METHOD ha_method_in,int ha_step_in,bool ha_formula_in){
            description = "Heiken Ashi";
            pair = pair_in;
            period = period_in;
            ha_name = "HeikenAshiSmoothed\\Heiken Ashi Smoothed.ex5";
            //ha_period = ha_period_in;
            //ha_method = ha_method_in;
            handle = iCustom(pair,period,ha_name,ha_period_in,ha_method_in,ha_step_in,ha_formula_in);
            if(handle==INVALID_HANDLE){
                logError(__FUNCTION__,"Failed to create handle for the Heiken Ashi Smoothed indicator for the symbol: " + pair + EnumToString(period) + " error code: " + string(GetLastError()));
                Alert("ERROR initializing indicator: Heiken Ashi Smoothed");
                isInitialized = false;
            }else{
                logDebug(__FUNCTION__,"Heiken Ashi Smoothed indicator succesfully initialized for the symbol:" + pair + " " + EnumToString(period));
                isInitialized = true;
            }
            if(isInitialized){
               return true;
            }else{
               return false;
            }
        };
        void updateValues(double closingPrice){
            if(isInitialized){
                ResetLastError();
                CopyBuffer(handle,0,1,1,hao);
                CopyBuffer(handle,1,1,1,hah);
                CopyBuffer(handle,2,1,1,hal);
                CopyBuffer(handle,3,1,1,hac);
                CopyBuffer(handle,4,1,1,haC);
                //logDebug(__FUNCTION__,"hao:" + string(hao[0]));
                //logDebug(__FUNCTION__,"hah:" + string(hah[0]));
                //logDebug(__FUNCTION__,"hal:" + string(hal[0]));
                //logDebug(__FUNCTION__,"hac:" + string(hac[0]));
                //if(haC[0]==1){
                //    logDebug(__FUNCTION__,"Heiking Ahsi: green");
                //}else if(haC[0]==2){
                    //logDebug(__FUNCTION__,"Heiking Ahsi: red");
                //}else{
                    //logDebug(__FUNCTION__,"haC:" + string(haC[0]));
                //}
                if(haC[0]==1){//green bar
                    buySignal = true;
                    closeBuySignal = false;
                    sellSignal = false;
                    closeSellSignal = true;
                }else if(haC[0]==2){//red bar
                    sellSignal = true;
                    closeSellSignal = false;
                    buySignal = false;
                    closeBuySignal = true;
                }else{
                    buySignal = false;
                    sellSignal = false;
                    closeBuySignal = false;
                    closeSellSignal = false;
                }
            }
        };
    };



