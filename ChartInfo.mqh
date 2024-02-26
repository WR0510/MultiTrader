class CChartInfo
    {
public:
                     CChartInfo(void);
                    ~CChartInfo(void);
    bool zoneRecoverySetLines(ENUM_POSITION_TYPE type_in, double price_in, double target_in, double zone_in);
    bool zoneRecoveryResetLines();
    };
    CChartInfo :: CChartInfo(){};
    CChartInfo :: ~CChartInfo(){};
    bool CChartInfo :: zoneRecoverySetLines(ENUM_POSITION_TYPE type_in, double price_in, double target_in, double zone_in){
        double upperTarget = 0.0;
        double lowerTarget = 0.0;
        double upperZone = 0.0;
        double lowerZone = 0.0;
        if(type_in == POSITION_TYPE_BUY){
            upperTarget = price_in + target_in;
            lowerTarget = price_in - zone_in - target_in;
            upperZone = price_in;
            lowerZone = price_in - zone_in;
        }else{
            upperTarget = price_in + target_in + zone_in;
            lowerTarget = price_in - target_in;
            upperZone = price_in + zone_in;
            lowerZone = price_in;
        }
        ObjectCreate(0,"UpperTargetLine",OBJ_HLINE,0,0,upperTarget);
        ObjectCreate(0,"LowerTargetLine",OBJ_HLINE,0,0,lowerTarget);
        ObjectCreate(0,"UpperZoneLine",OBJ_HLINE,0,0,upperZone);
        ObjectCreate(0,"LowerZoneLine",OBJ_HLINE,0,0,lowerZone);
        return true;
    }
    bool CChartInfo :: zoneRecoveryResetLines(){
        ObjectDelete(0,"UpperTargetLine");
        ObjectDelete(0,"LowerTargetLine");
        ObjectDelete(0,"UpperZoneLine");
        ObjectDelete(0,"LowerZoneLine");
        return true;
    }