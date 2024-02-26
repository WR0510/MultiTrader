#include <Trade\PositionInfo.mqh>
#include "LoggerClass.mqh"
CLoggerClass Logger;

void debug(string text){
    if(verbose){
        Print(text);
    }
    }
string boolToText(bool bool_in){
    if(bool_in){
        return "true";
    }else{
        return "false";
    }
    }
void logTrace(string func,string msg){
    if(debug){Logger.logTrace(func,logFuncLenght,msg);}
    }
void logDebug(string func,string msg){
    if(debug){Logger.logDebug(func,logFuncLenght,msg);}
    }
void logInfo(string func,string msg){
    if(debug){Logger.logInfo(func,logFuncLenght,msg);}
    }
void logWarn(string func,string msg){
    if(debug){Logger.logWarn(func,logFuncLenght,msg);}
    }
void logError(string func,string msg){
    if(debug){Logger.logError(func,logFuncLenght,msg);}
    }
void logAlert(string func,string msg){
    if(debug){Logger.logError(func,logFuncLenght,msg);}
    Alert(msg);
    }
void logFatal(string func,string msg){
    if(debug){Logger.logFatal(func,logFuncLenght,msg);}
    }
void logEntry(string func){
    if(debug){Logger.logEntry(func,logFuncLenght);}
    }
void logEntry(string func,string msg){  
    if(debug){Logger.logEntry(func,logFuncLenght,msg);}
    }

bool isMarketOpenStatus(){
    trade.OrderDelete(0);
    switch(trade.ResultRetcode()){
        case 10017: return false; // Trade Disabled
        case 10018: return false; // Market Closed
        case 10027: return false; // Auto-Trading disabled
        case 10031: return false; // No Connection
        case 10032: return false; // Only Live Accounts
        case 10033: return false; // Max Number of Limit Orders
        // ADD OTHER RELEVANT ResultCodes HERE
        default: return true;
    }
}
double todaysProfit(){
    datetime dayStart = StringToTime(TimeToString(TimeCurrent(),TIME_DATE));
    double dayProfit = 0.0;
    if(!historyPositionInfo.HistorySelect(dayStart,TimeCurrent())){
        Alert("CHistoryPositionInfo::HistorySelect() failed!");
        return dayProfit;
    }else{
        if(historyPositionInfo.PositionsTotal() > 0){
            for(int i=historyPositionInfo.PositionsTotal()-1;i>=0;i--){
                if(historyPositionInfo.SelectByIndex(i)){
                    dayProfit += historyPositionInfo.Profit();
                }
            }
        }            
    }
    return dayProfit;
    }