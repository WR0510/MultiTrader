//MultiTrader2022
#define VERSION "1.39"
#property version VERSION
#property copyright "© Wim Rens"

#include "Variables.mqh"
#include "Config.mqh"
#include "Functions.mqh"
//#include <Tools\Classes\Test.mqh>
#include "CanvasClass.mqh"
#include "MultiTraderClasses.mqh"

CSymbolHandler* symbolHandler[];
CeaCanvasInfo EAcanvasInfo;

int OnInit(){
   logEntry(__FUNCTION__);
   accountCurrency = AccountInfoString(ACCOUNT_CURRENCY);
   
   if(MQLInfoInteger(MQL_TESTER)){//set debug mode
      debug = false;//never print debug info in testing mode
   }else{
      debug = verbose;//apply user input when not in testing mode
   }
   debug = verbose;//print debug info in testing mode
   trade.SetExpertMagicNumber(EAmagic);
   if(tradeEURUSD){
      if(SymbolSelect(symbolName_EURUSD,true)){
         AddSymbol(EURUSD);
      }else{
         logAlert(__FUNCTION__,"Symbol does not exist error: " + symbolName_EURUSD);
      }
      }
   if(tradeGBPUSD){
      if(SymbolSelect(symbolName_GBPUSD,true)){
         AddSymbol(GBPUSD);
      }else{
         logAlert(__FUNCTION__,"Symbol does not exist error: " + symbolName_GBPUSD);
      }
      }
   if(tradeUSDCHF){
      if(SymbolSelect(symbolName_USDCHF,true)){
         AddSymbol(USDCHF);
      }else{
         logAlert(__FUNCTION__,"Symbol does not exist error: " + symbolName_USDCHF);
      }
      }
   if(tradeUSDJPY){
      if(SymbolSelect(symbolName_USDJPY,true)){
         AddSymbol(USDJPY);
      }else{
         logAlert(__FUNCTION__,"Symbol does not exist error: " + symbolName_USDJPY);
      }
      }
   if(tradeUSDCAD){
      if(SymbolSelect(symbolName_USDCAD,true)){
         AddSymbol(USDCAD);
      }else{
         logAlert(__FUNCTION__,"Symbol does not exist error: " + symbolName_USDCAD);
      }
      }
   if(tradeEURGBP){
      if(SymbolSelect(symbolName_EURGBP,true)){
         AddSymbol(EURGBP);
      }else{
         logAlert(__FUNCTION__,"Symbol does not exist error: " + symbolName_EURGBP);
      }
      }
   if(tradeAUDNZD){
      if(SymbolSelect(symbolName_AUDNZD,true)){
         AddSymbol(AUDNZD);
      }else{
         logAlert(__FUNCTION__,"Symbol does not exist error: " + symbolName_AUDNZD);
      }
      }
   if(trade_Symbol1){
      if(SymbolSelect(symbolName_Symbol1,true)){
         AddSymbol(SYMBOL1);
      }
      }
   if(trade_Symbol2){
      if(SymbolSelect(symbolName_Symbol2,true)){
         AddSymbol(SYMBOL2);
      }
      }
   totalBarsTrade = iBars(_Symbol,_Period);
   totalBarsUpdatePositions = iBars(_Symbol,PERIOD_M1);
   totalOnTimer = statOutputRefresh + 1;//make sure the statistics output will run first time OnTimer
   EventSetTimer(eventTimer);
   //clearCommonFiles();
   //exportStats();
   return(INIT_SUCCEEDED);
   }
void OnDeinit(const int reason){
   logInfo(__FUNCTION__,"Shutdown EA");
   int counter = ArraySize(symbolHandler);
   for(int i=0;i<counter;i++){
      logInfo(__FUNCTION__,"Printing statistics:");
      symbolHandler[i].printStats();
      logInfo(__FUNCTION__,"Deleting symbol indicators for " + symbolHandler[i].getSymbolStr());
      symbolHandler[i].deleteIndicators();
      logInfo(__FUNCTION__,"Deleting symbol handler: " + string(i)+ " for symbol : " + symbolHandler[i].getSymbolStr());
      delete symbolHandler[i];
   }
   ArrayResize(symbolHandler,0);//resize because when building an active EA the array is not deleted and grows when restarting the EA
   EAcanvasInfo.destroyCanvas();
   }
void OnTick(){
   // Handle every tick
   for(int i=0;i<ArraySize(symbolHandler);i++){// loop all activated symbols
      symbolHandler[i].processTickComplete();
   }

   // Handle completed bars(update current positions timeframe)
   int barsUpdatePositions = iBars(_Symbol,updatePositionsTimeframe);
   if(totalBarsUpdatePositions != barsUpdatePositions){// execute when the timeframe has ended wich is used for updating the trailingstop
      logEntry(__FUNCTION__,"Bar completed update timeframe");
      totalBarsUpdatePositions = barsUpdatePositions;
      for(int i=0;i<ArraySize(symbolHandler);i++){// loop all activated symbols
         symbolHandler[i].processBarCompleteUpdate();
      }
   }

   // Handle completed bars(handle trade timeframe)
   int barsTrade = iBars(_Symbol,tradeTimeframe);
   if(totalBarsTrade != barsTrade){
      logEntry(__FUNCTION__,"Bar completed trade timeframe");
      totalBarsTrade = barsTrade;
      for(int i=0;i<ArraySize(symbolHandler);i++){// loop all activated symbols
         symbolHandler[i].processBarCompleteTrade();
         //DebugBreak();
      }
   }
   }
void OnTimer(){
   if(canvas){
      //logAlert(__FUNCTION__,"canvas");
      EAcanvasInfo.updateCanvas();
   }
   handleSound();

   //Handle statisctics output
   totalOnTimer++;
   if(totalOnTimer > statOutputRefresh){
      totalOnTimer = 0;
      if(!MQLInfoInteger(MQL_TESTER)){
         if(exportStats){
            exportStats();
         }
      }
   }
   }
void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result){ 
   if (trans.type == TRADE_TRANSACTION_DEAL_ADD){
      //ulong          lastDealID   =trans.deal; 
      //ENUM_DEAL_TYPE lastDealType =trans.deal_type; 
      //double        lastDealVolume=trans.volume; 
      HistorySelect(TimeCurrent() - PeriodSeconds(PERIOD_D1),TimeCurrent()+10);
      CDealInfo deal;
      deal.Ticket(trans.deal);
      if(deal.Entry() == DEAL_ENTRY_OUT){//A position has been closed
         //double profit = deal.Profit();
         //ulong positionTicket = deal.PositionId();
         for(int i=0;i<ArraySize(symbolHandler);i++){// loop all activated symbols
            if(symbolHandler[i].getSymbolStr() == trans.symbol){
               symbolHandler[i].checkPendingOrders();
            }
         }
      }
   }
   }
int  OnTesterInit(void){
   logDebug(__FUNCTION__,"OnTesterInit called");
   return INIT_SUCCEEDED;
   }
void OnTesterDeinit(){
   logDebug(__FUNCTION__,"OnTesterDeinit called");
   }
void AddSymbol(ENUM_SYMBOLS newSymbol){
   logTrace(__FUNCTION__,"Adding symbol: " + EnumToString(newSymbol));
   int size = ArraySize(symbolHandler);
   ArrayResize(symbolHandler,size + 1);
   symbolHandler[size] = new CSymbolHandler(newSymbol,tradeTimeframe);
   if(symbolHandler[size].checkSymbolInit() == false){
      logAlert(__FUNCTION__,"Error while initializing symbol(" + EnumToString(newSymbol) + "), check indicators selection.");
      delete symbolHandler[size];
      ArrayResize(symbolHandler,size);
      return;
   }
   logDebug(__FUNCTION__,"Initialized symbol " + EnumToString(newSymbol));
   }
void handleSound(){
   if(soundOnOff){
      if(!playSoundWin && !playSoundLoss){
         double lastSecondProfit = 0.0;
         for(int i=0;i<ArraySize(symbolHandler);i++){// loop all activated symbols
            lastSecondProfit += symbolHandler[i].processSecond();
         }
         if(lastSecondProfit != 0){
            //DebugBreak();
         }
         if(lastSecondProfit > 0){
            playSoundWin = true;
         }else if(lastSecondProfit < 0){
            playSoundLoss = true;
         }
      }else{
         if(playSoundWin){
            PlaySound("\\Files\\" + winningSound);
            playSoundWin = false;
         }
         if(playSoundLoss){
            PlaySound("\\Files\\" + losingSound);
            playSoundLoss = false;
         }
      }
   }
   }
void exportStats(){
   string dataFolder = TerminalInfoString(TERMINAL_DATA_PATH);
   string terminalNr = StringSubstr(dataFolder,StringLen(dataFolder)-32);
   int h=FileOpen(folderExport + "\\" + terminalNr + ".csv",FILE_READ|FILE_WRITE|FILE_COMMON|FILE_ANSI);
   if(h==INVALID_HANDLE){
      Alert("Error opening file");
      return;
   }
   FileWrite(h,"todaysProfit;" + DoubleToString(todaysProfit()));
   FileClose(h);
   logDebug(__FUNCTION__,"statistics exported to file");
   //Alert("Added to file");
   }
void clearCommonFiles(){
   if(FolderClean(folderExport,FILE_COMMON)){//remove the cross reference file
      logDebug(__FUNCTION__,"clearing folder: %s" + folderExport);
   }else{
      logError(__FUNCTION__,"ERROR clearing folder: %s" + string(GetLastError()));
      }
   }

