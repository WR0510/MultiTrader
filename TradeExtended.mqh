CPositionInfo positionInfo;

class CTradeExtended{
private:
    bool closePosition(ulong ticket_in,ulong magic_in){
        if(PositionSelectByTicket(ticket_in)){//Select the ticketId to work with
            if(PositionGetInteger(POSITION_MAGIC) == magic_in){//Check the magic number
                bool result = trade.PositionClose(ticket_in);
                if(result){
                    logDebug(__FUNCTION__,"Position #" + string(ticket_in) + " was closed, balance: " + string(AccountInfoDouble(ACCOUNT_BALANCE)));
                    return true;
                }else{return false;}
            }else{return false;}
        }else{
            logError(__FUNCTION__," cannot close the position "+(string)ticket_in);
            return false;
        }
        }
public:
                     CTradeExtended(void);
                    ~CTradeExtended(void);
    double getAccountEquityPercentage();//get the account equity percentage compared to the balance
    double getAccountEquityDifference();//get the account difference balance - equity
    bool closeAllPositions(long magic_in);//close all the positions for the magic number
    bool closeAllPositions(long magic_in,string symbol_in);//close all the positions, magic number and symbol must match
    bool closeAllPositions(long magic_in,string symbol_in, ENUM_POSITION_TYPE posType);//close all the positions, magic number, symbol, position type must match
    int countTradingSymbols(long magic_in);//count the amount of symbols with open positions
    void deleteAllOrders(long magic,string symbol_in);//delete all orders, magic number and symbol must match
    bool deleteOrder(ulong ticket, long magic);//delete order
    ulong getFirstPositionTicket(long magic,string symbol_in);//get the first position for this EA and symbol
    ENUM_POSITION_TYPE getPositionType(ulong ticket_in);//get the first position type
    double getPositionPrice(ulong ticket_in);//get the position price
    double lastSecondProfit();//calculate profit of all closed positions in the last second
    double previousPositionOpenPrice(long magic_in,string symbol_in);//return the open price for the last position opened, magic number and symbol must match
    bool updateStopLossAllPositions(long magic_in,string symbol_in,double sl_in, ENUM_POSITION_TYPE posType);//update all positions with the given stoploss, magic number and symbol must match
    bool modifyPosition(ulong ticket_in,double sl_in,double tp_in,double oldSl,double oldTp);//update the stoploss and takeprofit for a given position by ticket
    int orderCount(long magic_in,string symbol_in);//count all orders, magic number and symbol must match
    bool openBuy(long magic_in,string symbol_in,double lots_in);//open a buy position, no sl or tp
    bool openSell(long magic_in,string symbol_in,double lots_in);//open a sell position, no sl or tp
    void playSound(ENUM_SOUND sound);//play sound
    int positionsCount(long magic_in);//count all positions for the given magic number
    int positionsCount(long magic_in,string symbol_in);//count all positions, magic number and symbol must match
    int positionsCountTypeBuy(long magic_in,string symbol_in);//count all positions, magic number, symbol, type buy must match
    int positionsCountTypeSell(long magic_in,string symbol_in);//count all positions, magic number, symbol, type sell must match
    double positionsProfit(long magic_in,string symbol_in);//combined profit for all positions for the given symbol, magic number must match
    double positionsProfit(long magic_in,string symbol_in, ENUM_POSITION_TYPE posType);//combined profit for all positions for the given symbol, magic number and position type must match
    double positionsProfitWithCommission(long magic_in,string symbol_in, ENUM_POSITION_TYPE posType, double commissionPoints);//combined profit for all positions for the given symbol, magic number and position type must match. Also calculate the commission
    double spread(string symbol_in);//return the spread for the given symbol
    };
    CTradeExtended :: CTradeExtended(){};
    CTradeExtended :: ~CTradeExtended(){};
    double CTradeExtended :: getAccountEquityPercentage(){
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        return (AccountInfoDouble(ACCOUNT_EQUITY)/AccountInfoDouble(ACCOUNT_BALANCE))*100;
        }
    double CTradeExtended :: getAccountEquityDifference(){
        return (AccountInfoDouble(ACCOUNT_BALANCE) - AccountInfoDouble(ACCOUNT_EQUITY));
        }
    bool CTradeExtended :: closeAllPositions(long magic_in){
        logDebug(__FUNCTION__,"Closing all positions for magic number: " + string(magic_in));
        int retryCounter = 0;
        while(positionsCount(magic_in) > 0 && retryCounter < 5){
            for(int i = PositionsTotal() -1 ; i >= 0; i--){//search all open positions for the symbol
                if(PositionGetInteger(POSITION_MAGIC) == magic_in){//check symbol and magic number        
                    string symbol = PositionGetSymbol(i);
                    ulong ticket = PositionGetInteger(POSITION_TICKET);
                    bool result = closePosition(ticket,magic_in);
                }
            }
            retryCounter++;
        }
        return true;
        };
    bool CTradeExtended :: closeAllPositions(long magic_in,string symbol_in){
        logDebug(__FUNCTION__,"Closing all positions for symbol: " + symbol_in);
        int retryCounter = 0;
        while(positionsCount(magic_in,symbol_in) > 0 && retryCounter < 5){
            //bool closeOK = true;
            for(int i = PositionsTotal() -1 ; i >= 0; i--){ //search all open positions for the symbol
                if(PositionGetSymbol(i)== symbol_in && PositionGetInteger(POSITION_MAGIC) == magic_in){//check symbol and magic number        
                    ulong ticket = PositionGetInteger(POSITION_TICKET);
                    bool result = closePosition(ticket,magic_in);
                }
            }
            retryCounter++;
        }
        return true;
        }
    bool CTradeExtended :: closeAllPositions(long magic_in,string symbol_in, ENUM_POSITION_TYPE posType){
        logDebug(__FUNCTION__,"Closing all positions for symbol: " + symbol_in + " and type: " + EnumToString(posType));
        int retryCounter = 0;
        while(positionsCount(magic_in,symbol_in) > 0 && retryCounter < 5){
            //bool closeOK = true;
            for(int i = PositionsTotal() -1 ; i >= 0; i--){ //search all open positions for the symbol
                if(PositionGetSymbol(i)== symbol_in && PositionGetInteger(POSITION_MAGIC) == magic_in && PositionGetInteger(POSITION_TYPE) == posType){//check symbol and magic number        
                    ulong ticket = PositionGetInteger(POSITION_TICKET);
                    bool result = closePosition(ticket,magic_in);
                }
            }
            retryCounter++;
        }
        return true;
        }
    int CTradeExtended :: countTradingSymbols(long magic_in){
        string symbolsList[];
        if(PositionsTotal() == 0){return 0;}
        if(PositionsTotal() == 1){
            return 1;
        }else{
            int symbolsCount = 0;
            for(int i = PositionsTotal() -1 ; i >= 0; i--){//loop all positions
                string symbol;
                //setting the symbol
                if(positionInfo.SelectByIndex(i)){ //select a position
                    symbol = positionInfo.Symbol();
                }else{
                    logError(__FUNCTION__,"Error selecting position: " + string(GetLastError()));
                    return INT_MAX;
                }
                //checking if the symbol is already in the list
                bool symbolFound = false;
                for(int j = 0;j < ArraySize(symbolsList); j++){
                    if(symbolsList[j] == symbol){
                        symbolFound = true;
                        continue;
                    }
                }
                //adding the symbol if it is not in the list
                if(symbolFound == false){
                    ArrayResize(symbolsList,ArraySize(symbolsList)+1);
                    symbolsList[ArraySize(symbolsList)-1] = symbol;
                }
            }
        }
        return ArraySize(symbolsList);    
        }
    void CTradeExtended :: deleteAllOrders(long magic,string symbol_in){
        logDebug(__FUNCTION__,"Start deleting all orders.");
        for(int i = 0; i < OrdersTotal();i++){
            if(OrderSelect(OrderGetTicket(i))){
                ulong ticket = OrderGetInteger(ORDER_TICKET);
                if(OrderGetString(ORDER_SYMBOL) == symbol_in){
                    if(OrderGetInteger(ORDER_MAGIC) == magic){
                        deleteOrder(ticket,magic);
                    }
                }
            }
        }
        }
    bool CTradeExtended :: deleteOrder(ulong ticket,long magic){
        if(OrderSelect(ticket)){//Select the order to work with
            if(OrderGetInteger(ORDER_MAGIC) == magic){
                if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY || OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL){
                    logTrace(__FUNCTION__,"Not deleting market order " + string(ticket));//When a new market order has just been placed it could happen this function is called before the order has been executed resulting in an error
                }else{
                    bool result = trade.OrderDelete(ticket);
                    if(result){
                        logInfo(__FUNCTION__,"Order " + string(ticket) + " deleted");
                    }else{//delete order failed
                        logAlert(__FUNCTION__,"Error deleting order ticket " + string(ticket) + ", Error:" + string(GetLastError()));
                        return false;
                    }
                    return true;
                }
            }else{return false;}//wrong magic number
        }else{return false;}//order cannot be selected
        return false;
        }
    ulong CTradeExtended :: getFirstPositionTicket(long magic_in,string symbol_in){
        for(int i=0;i<PositionsTotal();i++){ //search all open positions for the symbol
            if(PositionGetSymbol(i)== symbol_in && PositionGetInteger(POSITION_MAGIC) == magic_in){//check symbol and magic number
                ulong ticket = PositionGetInteger(POSITION_TICKET);
                logTrace(__FUNCTION__,"First position found: " + string(ticket));
                return ticket;
            }
        }
        return 0;
        }
    ENUM_POSITION_TYPE CTradeExtended :: getPositionType(ulong ticket_in){
        for(int i = PositionsTotal() -1 ; i >= 0; i--){ //search all open positions for the symbol
            if(PositionGetInteger(POSITION_TICKET) == ticket_in){
                if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                    return POSITION_TYPE_BUY;
                }
                if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                    return POSITION_TYPE_SELL;
                }
            }
        }
        return -1;
        }
    double CTradeExtended :: getPositionPrice(ulong ticket_in){
        if(PositionSelectByTicket(ticket_in)){
            return PositionGetDouble(POSITION_PRICE_OPEN);
        }
        return 0;
        }
    double CTradeExtended :: lastSecondProfit(){
        //datetime from = StringToTime(TimeToString(TimeCurrent(),TIME_DATE));
        double profit = 0.0;
        if(!historyPositionInfo.HistorySelect(TimeCurrent()-1,TimeCurrent())){
            Alert("CHistoryPositionInfo::HistorySelect() failed!");
            return profit;
        }else{
            if(historyPositionInfo.PositionsTotal() > 0){
                for(int i=historyPositionInfo.PositionsTotal()-1;i>=0;i--){
                    if(historyPositionInfo.SelectByIndex(i)){
                        profit += historyPositionInfo.Profit();
                    }
                }
            }            
        }
        return profit;
        }
    double CTradeExtended :: previousPositionOpenPrice(long magic_in,string symbol_in){
        double pricePreviousPosition = 0.0;
        for(int i = PositionsTotal() -1 ; i >= 0; i--){//loop all positions
            if(positionInfo.SelectByIndex(i)){ //select a position
                if(positionInfo.Symbol() == symbol_in && positionInfo.Magic() == magic_in){
                    pricePreviousPosition = positionInfo.PriceOpen();
                    break;
                }    
            }else{
                logError(__FUNCTION__,"Error selecting position: " + string(GetLastError()));
            }
        }
        return pricePreviousPosition;
        }
    bool CTradeExtended :: updateStopLossAllPositions(long magic_in,string symbol_in,double sl_in,ENUM_POSITION_TYPE posType){
        logDebug(__FUNCTION__,"Updating stop loss for magicnr:" + string(magic_in) + " symbol:" + string(symbol_in) + " stop loss required:" + string(sl_in) + " type:" + EnumToString(posType));
        for(int i = PositionsTotal() -1 ; i >= 0; i--){//loop all positions
            if(PositionGetSymbol(i) == symbol_in && PositionGetInteger(POSITION_MAGIC) == magic_in && PositionGetInteger(POSITION_TYPE) == posType){
                modifyPosition(PositionGetInteger(POSITION_TICKET),sl_in,PositionGetDouble(POSITION_TP),PositionGetDouble(POSITION_SL),PositionGetDouble(POSITION_TP));
            }
        }
        return true;
        }
    bool CTradeExtended :: modifyPosition(ulong ticket_in,double sl_in,double tp_in,double oldSl,double oldTp){        
        if(trade.PositionModify(ticket_in,sl_in,tp_in)){
            logDebug(__FUNCTION__,"Pos #" + string(ticket_in) + " was modified|SL:" + string(oldSl) + "->" + string(sl_in) + "|TP:" + string(oldTp) + "->" + string(tp_in));
            return true;
        }else{
            logError(__FUNCTION__,"ERROR while modifying:" + string(GetLastError()));        
        }
        return false;
        }
    int CTradeExtended :: orderCount(long magic_in,string symbol_in){
        int ordersForPair = 0;
        ulong ticket = 0;
        for(int i=0;i<OrdersTotal();i++){
            if((ticket=OrderGetTicket(i))>0){
                if(OrderGetString(ORDER_SYMBOL) == symbol_in && OrderGetInteger(ORDER_MAGIC) == magic_in){
                    //debug("order symbol = " + OrderGetString(ORDER_SYMBOL));
                    ordersForPair++;
                }
            }
        }
        return ordersForPair;
        }
    bool CTradeExtended :: openBuy(long magic_in,string symbol_in,double lots_in){
        if(trade.Buy(lots_in,symbol_in)){
            if(trade.ResultRetcode() == TRADE_RETCODE_DONE){//if trade succesfull
                return true;
            }else{
                logError(__FUNCTION__,"Buy() method failed. Return code="+ string(trade.ResultRetcode()) + ". Code description: " + trade.ResultRetcodeDescription());
            }
        }else{
            Alert("ERROR while buy trade: " + string(GetLastError()));
            logError(__FUNCTION__,"ERROR while buy trade: " + string(GetLastError()));
        }
        return false;
        }
    bool CTradeExtended :: openSell(long magic_in,string symbol_in,double lots_in){
        if(trade.Sell(lots_in,symbol_in)){
            if(trade.ResultRetcode() == TRADE_RETCODE_DONE){//if trade succesfull
                return true;
            }else{
                logError(__FUNCTION__,"Sell() method failed. Return code="+ string(trade.ResultRetcode()) + ". Code description: " + trade.ResultRetcodeDescription());
            }
        }else{
            Alert("ERROR while sell trade: " + string(GetLastError()));
            logError(__FUNCTION__,"ERROR while sell trade: " + string(GetLastError()));
        }
        return false;
        }
    void CTradeExtended :: playSound(ENUM_SOUND sound){
        switch(sound){
            case SOUND_OPEN_POSITION :
                PlaySound("\\Files\\" + openSound);
                break;
        }
        }
    int CTradeExtended :: positionsCount(long magic_in){
        int positionsForPair = 0;
        for(int i = PositionsTotal() -1 ; i >= 0; i--){ //search all open positions for the symbol
            if(PositionGetInteger(POSITION_MAGIC) == magic_in){
                positionsForPair++;
            }
        }
        return positionsForPair;
        };
    
    int CTradeExtended :: positionsCount(long magic_in,string symbol_in){
        int positionsForPair = 0;
        for(int i = PositionsTotal() -1 ; i >= 0; i--){ //search all open positions for the symbol
            if(PositionGetSymbol(i) == symbol_in && PositionGetInteger(POSITION_MAGIC) == magic_in){
                positionsForPair++;
            }
            }
        return positionsForPair;
        };
    int CTradeExtended :: positionsCountTypeBuy(long magic_in,string symbol_in){
        int positionsForPair = 0;
        for(int i = PositionsTotal() -1 ; i >= 0; i--){ //search all open positions for the symbol
            if(PositionGetSymbol(i) == symbol_in && PositionGetInteger(POSITION_MAGIC) == magic_in && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                positionsForPair++;
            }
            }
        return positionsForPair;
        };
    int CTradeExtended :: positionsCountTypeSell(long magic_in,string symbol_in){
        int positionsForPair = 0;
        for(int i = PositionsTotal() -1 ; i >= 0; i--){ //search all open positions for the symbol
            if(PositionGetSymbol(i) == symbol_in && PositionGetInteger(POSITION_MAGIC) == magic_in && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                positionsForPair++;
            }
            }
        return positionsForPair;
        };
    double CTradeExtended :: positionsProfit(long magic_in,string symbol_in){ //calculate the total profit for the symbol
        double profit = 0;
        for(int i = PositionsTotal() -1 ; i >= 0; i--){ //search all open positions for the symbol
            if(PositionGetSymbol(i) == symbol_in && PositionGetInteger(POSITION_MAGIC) == magic_in){
                profit += PositionGetDouble(POSITION_PROFIT);
            }
        }
        return profit;
        }
    double CTradeExtended :: positionsProfit(long magic_in,string symbol_in, ENUM_POSITION_TYPE posType){ //calculate the total profit for the symbol for the specific position type
        double profit = 0;
        for(int i = PositionsTotal() -1 ; i >= 0; i--){ //search all open positions for the symbol
            if(PositionGetSymbol(i) == symbol_in && PositionGetInteger(POSITION_MAGIC) == magic_in && PositionGetInteger(POSITION_TYPE) == posType){
                profit += PositionGetDouble(POSITION_PROFIT);
            }
        }
        return profit;
        }
    double CTradeExtended :: positionsProfitWithCommission(long magic_in,string symbol_in, ENUM_POSITION_TYPE posType, double commissionPoints){
        //commission price: (((1/bid_price_base_profit)*(bid_price_base_profit+tick_size_base_profit))-1)*commission_ticks*contract_size_base_profit*lotsize
        double profit = 0;
        double commission = 0;
        double contractSize = SymbolInfoDouble(symbol_in,SYMBOL_TRADE_CONTRACT_SIZE);
        double bid = SymbolInfoDouble(symbol_in,SYMBOL_BID);
        double tickSize = SymbolInfoDouble(symbol_in,SYMBOL_TRADE_TICK_SIZE);
        for(int i = PositionsTotal() -1 ; i >= 0; i--){ //search all open positions for the symbol
            if(PositionGetSymbol(i) == symbol_in && PositionGetInteger(POSITION_MAGIC) == magic_in && PositionGetInteger(POSITION_TYPE) == posType){
                double lotsize = PositionGetDouble(POSITION_VOLUME);
                double commissionForPosition_1 = lotsize * commissionPoints * contractSize;
                double commissionForPosition_2 = (((1/bid)*(bid+tickSize))-1);
                double commissionForCurrentPosition =  commissionForPosition_1 * commissionForPosition_2;
                commission += commissionForCurrentPosition;
                profit += PositionGetDouble(POSITION_PROFIT);
            }
        }
        return profit - commission;
        }
    double CTradeExtended :: spread(string symbol_in){
        return SymbolInfoDouble(symbol_in,SYMBOL_ASK) - SymbolInfoDouble(symbol_in,SYMBOL_BID);
        };
    
