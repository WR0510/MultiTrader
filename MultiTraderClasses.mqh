//#include "Test.mqh"
#include "TradeExtended.mqh"
#include "ChartInfo.mqh"
#include "IndicatorClasses.mqh"
#include "MultiTraderClasses.mqh"
#include <Math\Stat\Math.mqh>

class CSymbolHandler{
    private:
        chart_variables chart;
        MqlRates rates[];       
        CIndicatorBase *indicators[];
        CTradeExtended tradeExtended;
        CChartInfo chartInfo;
        int AddIndicator(ENUM_INDICATOR_TYPES type){
            int size = ArraySize(indicators);
            ArrayResize(indicators,size + 1);
            if(type == BOLLINGERBANDS){
               indicators[size] = new CIndicatorBB();
                }
            if(type == RSI){
                indicators[size] = new CIndicatorRSI();
                }
            if(type == ENVELOPES){
                indicators[size] = new CIndicatorEnvelopes();
                }
            if(type == MA){
                indicators[size] = new CIndicatorMA();
                }
            if(type == STOCHASTIC){
                indicators[size] = new CIndicatorStochastic();
                }
            if(type == HEIKENASHI){
                indicators[size] = new CindicatorHeikenAshiSmoothed();
                }
            return size;
            };
        void checkTradeRecovery(){
            double profit = tradeExtended.positionsProfit(EAmagic,general.symbol,recovery.firstPositionType);
            int positionsCount_l;
            if(recovery.firstPositionType == POSITION_TYPE_BUY){
                positionsCount_l = tradeExtended.positionsCountTypeBuy(EAmagic,general.symbol);
            }else if(recovery.firstPositionType == POSITION_TYPE_SELL){
                positionsCount_l = tradeExtended.positionsCountTypeSell(EAmagic,general.symbol);
            }else{
                logInfo(__FUNCTION__,"Warning: unable to check the trade recovery.");
                return;
            }
            if(positionsCount_l > 1 && profit > 0){//do not close when the first position is making a profit
                if (tradeExtended.positionsProfitWithCommission(EAmagic,general.symbol,recovery.firstPositionType,takeprofit.commission)>=0){
                    switch(recovery.exitMode){
                        case GRID_EXIT_END_TIMEFRAME:
                            logInfo(__FUNCTION__,"Position " + string(recovery.firstPositionTicket) + " recovered --> start closing all positions for the symbol");
                            tradeExtended.closeAllPositions(EAmagic,general.symbol,recovery.firstPositionType);
                            break;
                        case GRID_EXIT_TRAILINGSTOP:
                            logInfo(__FUNCTION__,"Position " + string(recovery.firstPositionTicket) + " recovered --> start trailing stop in recovery mode");
                            updateTrailingStopRecovery();
                            setTradingMode(TRADINGMODE_RECOVERY_EXIT);
                            break;
                        default:
                            logError(__FUNCTION__,"Error: invalid grid exit mode selected");
                    }
                }
            }
            };
        bool checkHoldConditions(){
            bool hold = false;
            string holdComment = "Signal cancelled, hold conditions:";
            if((rates[0].spread) > general.maxSpread){
                hold = true;
                holdComment += " max spread " + string(rates[0].spread) + " > " + string(general.maxSpread) + ", ";
            }
            if(hold){
                logDebug(__FUNCTION__,holdComment);
                return hold;
            }
            int pairsCount = tradeExtended.countTradingSymbols(EAmagic);
            if(tradeExtended.positionsCount(EAmagic,general.symbol) == 0 && pairsCount >= maxPairs){//check if the maximum amount of different symbols has been reached
                hold = true;
                holdComment += " max pairs " + string(pairsCount) + " >= " + string(maxPairs) + ", ";
            }
            if(hold){
                logDebug(__FUNCTION__,holdComment);
                return hold;
            }
            return hold;
            }            
        void checkMaxDD(){
            if(maxAccountDD > 0){
                double currentDD = AccountInfoDouble(ACCOUNT_BALANCE)-AccountInfoDouble(ACCOUNT_EQUITY);
                if(currentDD > maxAccountDD){
                    logInfo(__FUNCTION__,"Maximum drawdown detected, closing all positions");
                    tradeExtended.closeAllPositions(EAmagic);
                }
            }
            }
        void updateCurrentPositions(){//check all current positions
            logTrace(__FUNCTION__,"Handling current positions for the symbol: " + general.symbol);
            if(stoploss.trailingstopOnOff){
                if(general.tradingMode == TRADINGMODE_FIRST_POSITION_OPENED || general.tradingMode == TRADINGMODE_MULTIPLE_POSITIONS_OPEN){
                    updateStopLoss(POSITION_TYPE_BUY);
                    updateStopLoss(POSITION_TYPE_SELL);
                }else if(recovery.recover){
                    if(recovery.firstPositionType == POSITION_TYPE_BUY){
                        if(tradeExtended.positionsCountTypeBuy(EAmagic,general.symbol) == 1){//when there is only 1 trade which can be recovered
                            updateStopLoss(POSITION_TYPE_BUY);
                        }
                        if(tradeExtended.positionsCountTypeSell(EAmagic,general.symbol) > 0){//when there is a trade in the opposite direction check the stop loss
                            updateStopLoss(POSITION_TYPE_SELL);
                        }
                    }else if(recovery.firstPositionType == POSITION_TYPE_SELL){
                        if(tradeExtended.positionsCountTypeSell(EAmagic,general.symbol) == 1){
                            updateStopLoss(POSITION_TYPE_SELL);
                        }
                        if(tradeExtended.positionsCountTypeBuy(EAmagic,general.symbol) > 0){
                           updateStopLoss(POSITION_TYPE_BUY);
                        }
                    }else{
                        return;
                    }
                }
            }
            }
        void updateTrailingStopRecovery(){//update the trailing stop in recovery mode
            if(PositionSelectByTicket(recovery.firstPositionTicket)){
                double sl = PositionGetDouble(POSITION_SL);
                double tickSize = SymbolInfoDouble(general.symbol,SYMBOL_TRADE_TICK_SIZE);
                if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                    double newSl = SymbolInfoDouble(general.symbol,SYMBOL_BID) - (recovery.trailingDeviation * general.pointValue) - tickSize;
                    if(SymbolInfoDouble(general.symbol,SYMBOL_BID) - (recovery.trailingDeviation * general.pointValue) - tickSize > sl){//use tick size to prevent rounding errors resulting in changing the sl to the value it already has
                        tradeExtended.updateStopLossAllPositions(EAmagic,general.symbol,SymbolInfoDouble(general.symbol,SYMBOL_BID) - (recovery.trailingDeviation * general.pointValue),POSITION_TYPE_BUY);
                    }
                }else{
                    if(SymbolInfoDouble(general.symbol,SYMBOL_ASK) + (recovery.trailingDeviation * general.pointValue) + tickSize < sl){
                        tradeExtended.updateStopLossAllPositions(EAmagic,general.symbol,SymbolInfoDouble(general.symbol,SYMBOL_ASK) + (recovery.trailingDeviation * general.pointValue),POSITION_TYPE_SELL);
                    }
                }
            }
            }
        void handleZoneRecovery(){//handle the zone recovery in a seperate function because it is called OnTick()
            double result = 0.0;
            if(tradeExtended.getAccountEquityPercentage() < recovery.zoneRecoveryCutOffPercentage){
                setTradingMode(TRADINGMODE_CLOSING_POSITIONS);
            }
            //if(getAccountEquityDifference() > recovery.zoneRecoveryCutOffPercentage){
                //setTradingMode(TRADINGMODE_CLOSING_POSITIONS);
            //}
            if(general.tradingMode == TRADINGMODE_RECOVERY && tradeExtended.spread(general.symbol) < (general.maxSpread * general.pointValue)){
                if(recovery.firstPositionType == POSITION_TYPE_BUY){
                    if(chart.zoneLinesActive == false){
                        if(chartInfo.zoneRecoverySetLines(POSITION_TYPE_BUY,recovery.firstPositionPrice,recovery.zoneRecoveryTarget*general.pointValue,recovery.zoneRecoveryZone*general.pointValue)){
                            chart.zoneLinesActive = true;
                        }
                    }
                    // the upper target has been reached, close all positions
                    if(SymbolInfoDouble(general.symbol,SYMBOL_BID) > recovery.firstPositionPrice + (recovery.zoneRecoveryTarget * general.pointValue) + (recovery.zoneRecoveryCommission * general.pointValue)){
                        if(tradeExtended.positionsProfit(EAmagic,general.symbol)){
                            logInfo(__FUNCTION__,"Zone recovery upper target has been reached, closing all positions. First position type: Buy");
                            setTradingMode(TRADINGMODE_CLOSING_POSITIONS);
                            if(chartInfo.zoneRecoveryResetLines()){
                                chart.zoneLinesActive = false;
                            }
                        }
                        return;
                    }
                    // the lower zone limit has been reached, opening another sell position
                    if(recovery.zoneRecoveryLatestPositionType == POSITION_TYPE_BUY){
                        if(SymbolInfoDouble(general.symbol,SYMBOL_ASK) < (recovery.firstPositionPrice - (recovery.zoneRecoveryZone * general.pointValue) + (recovery.zoneRecoveryCommission * general.pointValue))){
                            double lots = calculateLotSizeZoneRecovery(POSITION_TYPE_SELL,GetPointer(this));
                            if(tradeExtended.openSell(EAmagic,general.symbol,lots)){
                                setZoneRecoveryLatestPositionType(POSITION_TYPE_SELL);
                                setZoneRecoveryLotsTotals(POSITION_TYPE_SELL,lots);
                            }
                        }
                    }else{
                        // the lower target has been reached, close all positions
                        if(SymbolInfoDouble(general.symbol,SYMBOL_ASK) < recovery.firstPositionPrice - (recovery.zoneRecoveryTarget * general.pointValue) - (recovery.zoneRecoveryZone * general.pointValue) - (recovery.zoneRecoveryCommission * general.pointValue)){
                            if(tradeExtended.positionsProfit(EAmagic,general.symbol) > 0){
                                logInfo(__FUNCTION__,"Zone recovery lower target has been reached, closing all positions. First position type: Buy");
                                setTradingMode(TRADINGMODE_CLOSING_POSITIONS);
                                if(chartInfo.zoneRecoveryResetLines()){
                                    chart.zoneLinesActive = false;
                                }
                            }
                        //the price is higher than the upper zone limit, open another buy position
                        }else if(SymbolInfoDouble(general.symbol,SYMBOL_BID) > recovery.firstPositionPrice - (recovery.zoneRecoveryCommission * general.pointValue)){
                            double lots = calculateLotSizeZoneRecovery(POSITION_TYPE_BUY,GetPointer(this));
                            if(tradeExtended.openBuy(EAmagic,general.symbol,lots)){
                                setZoneRecoveryLatestPositionType(POSITION_TYPE_BUY);
                                setZoneRecoveryLotsTotals(POSITION_TYPE_BUY,lots);
                            }
                        }
                    }
                }else if(recovery.firstPositionType == POSITION_TYPE_SELL){
                    if(chart.zoneLinesActive == false){
                        if(chartInfo.zoneRecoverySetLines(POSITION_TYPE_SELL,recovery.firstPositionPrice,recovery.zoneRecoveryTarget*general.pointValue,recovery.zoneRecoveryZone*general.pointValue)){
                            chart.zoneLinesActive = true;
                        }
                    }
                    // the lower target has been reached, close all positions
                    if(SymbolInfoDouble(general.symbol,SYMBOL_ASK) < recovery.firstPositionPrice - (recovery.zoneRecoveryTarget * general.pointValue) - (recovery.zoneRecoveryCommission * general.pointValue)){
                        if(tradeExtended.positionsProfit(EAmagic,general.symbol)){
                            logInfo(__FUNCTION__,"Zone recovery lower target has been reached, closing all positions. First position type: Sell");
                            setTradingMode(TRADINGMODE_CLOSING_POSITIONS);
                            if(chartInfo.zoneRecoveryResetLines()){
                                chart.zoneLinesActive = false;
                            }
                        }
                        return;
                    }
                    // the upper zone limit has been reached, opening another buy position
                    if(recovery.zoneRecoveryLatestPositionType == POSITION_TYPE_SELL){
                        if(SymbolInfoDouble(general.symbol,SYMBOL_BID) > recovery.firstPositionPrice + (recovery.zoneRecoveryZone * general.pointValue) - (recovery.zoneRecoveryCommission * general.pointValue)){
                            double lots = calculateLotSizeZoneRecovery(POSITION_TYPE_BUY,GetPointer(this));
                            if(tradeExtended.openBuy(EAmagic,general.symbol,lots)){
                                setZoneRecoveryLatestPositionType(POSITION_TYPE_BUY);
                                setZoneRecoveryLotsTotals(POSITION_TYPE_BUY,lots);
                            }
                        }
                    }else{
                        // the upper target has been reached, close all positions
                        if(SymbolInfoDouble(general.symbol,SYMBOL_BID) > recovery.firstPositionPrice + (recovery.zoneRecoveryTarget * general.pointValue) + (recovery.zoneRecoveryZone * general.pointValue) + (recovery.zoneRecoveryCommission * general.pointValue)){
                            if(tradeExtended.positionsProfit(EAmagic,general.symbol)){
                                logInfo(__FUNCTION__,"Zone recovery upper target has been reached, closing all positions. First position type: Sell");
                                setTradingMode(TRADINGMODE_CLOSING_POSITIONS);
                                if(chartInfo.zoneRecoveryResetLines()){
                                    chart.zoneLinesActive = false;
                                }
                            }
                        // the lower zone limit has been reached, open another sell position
                        }else if(SymbolInfoDouble(general.symbol,SYMBOL_ASK) < recovery.firstPositionPrice + (recovery.zoneRecoveryCommission * general.pointValue)){
                            double lots = calculateLotSizeZoneRecovery(POSITION_TYPE_SELL,GetPointer(this));
                            if(tradeExtended.openSell(EAmagic,general.symbol,lots)){
                                setZoneRecoveryLatestPositionType(POSITION_TYPE_SELL);
                                setZoneRecoveryLotsTotals(POSITION_TYPE_SELL,lots);
                            }
                        }
                    }
                }
            }
            }
        void handleRecoveryUsingOrders(){
            int positionsCount_l = 0;
            if(recovery.firstPositionType == POSITION_TYPE_BUY){
                positionsCount_l = tradeExtended.positionsCountTypeBuy(EAmagic,general.symbol);
            }else if(recovery.firstPositionType == POSITION_TYPE_SELL){
                positionsCount_l = tradeExtended.positionsCountTypeSell(EAmagic,general.symbol);
            }else{
                return;
            }
                if(tradeExtended.orderCount(EAmagic,general.symbol) == 0 && positionsCount_l <= recovery.maxSteps && tradeExtended.positionsProfit(EAmagic,general.symbol) < 0){//no open orders means an order needs to be added(the previous order was executed or it is the first order required for the grid martingale strategy)
                    double previousPositionOpenPrice = tradeExtended.previousPositionOpenPrice(EAmagic,general.symbol);
                    if(PositionSelectByTicket(recovery.firstPositionTicket)){
                        ulong ticket = PositionGetInteger(POSITION_TICKET);
                        double lots = PositionGetDouble(POSITION_VOLUME); //option 1:commented out, this does not work when setting a higher lotsize for positions different type from the firstposition. However it is usefull when automatically adjusting the lotsize
                        //double lots = lotsize.lotsize;//option 2:use the base lotsize for calcutating the order lotsize
                        double firstPositionSL = PositionGetDouble(POSITION_SL);
                        switch(recovery.mode){//calculate lot size depending on the mode
                            case RECOVERY_MODE_ADD:
                                lots = lots * (positionsCount_l + 1);
                                break;
                            case RECOVERY_MODE_DOUBLE:
                                for(int i=0;i<positionsCount_l;i++){
                                    lots = lots * 2;
                                }
                                break;
                            case RECOVERY_MODE_BASE_LOTS:
                                lots = PositionGetDouble(POSITION_VOLUME);
                                break;
                            default:
                                logError(__FUNCTION__,"Error: invalid recovery mode.");
                            }
                        ENUM_ORDER_TYPE_TIME type_time = ORDER_TIME_GTC;//required for orders
                        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                            double stepMultiplier = MathPowInt(recovery.stepFactor,positionsCount_l);
                            double price = PositionGetDouble(POSITION_PRICE_OPEN) - (recovery.deviation * general.pointValue * positionsCount_l * stepMultiplier);
                            if(SymbolInfoDouble(general.symbol,SYMBOL_BID) < price){//check if the price is lower than the bid price
                                double oldPrice = price;
                                price = SymbolInfoDouble(general.symbol,SYMBOL_BID);
                                logTrace(__FUNCTION__,"Price adjusted to bid:" + string(oldPrice) + "->" + string(price));
                                }
                            if(previousPositionOpenPrice < price){//check price to be lower than the previous position
                                double oldPrice = price;
                                price = previousPositionOpenPrice - (recovery.deviation * general.pointValue);
                                logTrace(__FUNCTION__,"Price adjusted to minimum deviation:" + string(oldPrice) + "->" + string(price));
                                }
                            logTrace(__FUNCTION__,"Calculated price: " + string(price) + " price first position: " + string(PositionGetDouble(POSITION_PRICE_OPEN)) + " grid deviation: " + string(recovery.deviation) + " general pointValue: " + string(general.pointValue) + " positionscount: " + string(positionsCount_l) + " deviation factor: " + string(recovery.stepFactor));
                            double limit_price = price;
                            double sl = PositionGetDouble(POSITION_SL);
                            if(sl > price - (recovery.deviation * general.pointValue)){//if the stoploss is too high(caused by slippage or large market moves)
                                sl = price - (recovery.deviation * general.pointValue);
                                logTrace(__FUNCTION__,"Stoploss must be adjusted, sl for opening position = " + string(PositionGetDouble(POSITION_SL)) + ", required sl = " + string(sl));
                            }
                            if(price > PositionGetDouble(POSITION_SL) && price < PositionGetDouble(POSITION_TP)){//check stop loss and takeprofit
                                if(trade.OrderOpen(general.symbol,ORDER_TYPE_BUY_LIMIT,lots,limit_price,price,sl,PositionGetDouble(POSITION_TP),type_time)){
                                    if(trade.ResultRetcode() == TRADE_RETCODE_DONE){//if order succesfull
                                        logInfo(__FUNCTION__,"order completed price=" + string(price) + " limit price=" + string(limit_price) + " sl=" + string(PositionGetDouble(POSITION_SL)) + " tp=" + string(PositionGetDouble(POSITION_TP)));
                                    }else{logError(__FUNCTION__,"ERROR while buy order: " + string(GetLastError()));}
                                }else{logError(__FUNCTION__,"ERROR while buy order: " + string(GetLastError()));}
                            }else{logDebug(__FUNCTION__,"Price not in range SL/TP: SL=" + string(PositionGetDouble(POSITION_SL)) + " TP=" + string(PositionGetDouble(POSITION_TP)));}
                            if((firstPositionSL + general.pointValue) > sl){
                                tradeExtended.updateStopLossAllPositions(EAmagic,general.symbol,(sl-general.pointValue),POSITION_TYPE_BUY);
                            }

                        }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                            double stepMultiplier = MathPowInt(recovery.stepFactor,positionsCount_l);
                            double price = PositionGetDouble(POSITION_PRICE_OPEN) + (recovery.deviation * general.pointValue * positionsCount_l * stepMultiplier);
                            if(SymbolInfoDouble(general.symbol,SYMBOL_BID) > price){
                                double oldPrice = price;
                                price = SymbolInfoDouble(general.symbol,SYMBOL_BID);
                                logTrace(__FUNCTION__,"Price adjusted to bid:" + string(oldPrice) + "->" + string(price));
                                }
                            if(previousPositionOpenPrice > price){
                                double oldPrice = price;
                                price = previousPositionOpenPrice + (recovery.deviation * general.pointValue);
                                logTrace(__FUNCTION__,"Price adjusted to minimum deviation:" + string(oldPrice) + "->" + string(price));
                                }
                            logTrace(__FUNCTION__,"Calculated price: " + string(price) + " price first position: " + string(PositionGetDouble(POSITION_PRICE_OPEN)) + " grid deviation: " + string(recovery.deviation) + " general pointValue: " + string(general.pointValue) + " positionscount: " + string(positionsCount_l) + " deviation factor: " + string(recovery.stepFactor));
                            double limit_price = price;
                            double sl = PositionGetDouble(POSITION_SL);
                            if(sl < price + (recovery.deviation * general.pointValue)){//if the stoploss is too low(caused by slippage or large market moves)
                                sl = price + (recovery.deviation * general.pointValue);
                                logTrace(__FUNCTION__,"Stoploss must be adjusted, sl for opening position = " + string(PositionGetDouble(POSITION_SL)) + ", required sl = " + string(sl));
                            }
                            if(price < PositionGetDouble(POSITION_SL) && price > PositionGetDouble(POSITION_TP)){//check stop loss and takeprofit
                                if(trade.OrderOpen(general.symbol,ORDER_TYPE_SELL_LIMIT,lots,limit_price,price,sl,PositionGetDouble(POSITION_TP),type_time)){
                                    if(trade.ResultRetcode() == TRADE_RETCODE_DONE){//if order succesfull
                                        logInfo(__FUNCTION__,"order completed price=" + string(price) + " limit price=" + string(limit_price) + " sl=" + string(PositionGetDouble(POSITION_SL)) + " tp=" + string(PositionGetDouble(POSITION_TP)));
                                    }else{logError(__FUNCTION__,"ERROR while sell order: " + string(GetLastError()));}
                                }else{logError(__FUNCTION__,"ERROR while sell order: " + string(GetLastError()));}
                            }else{logDebug(__FUNCTION__,"Price not in range SL/TP: SL=" + string(PositionGetDouble(POSITION_SL)) + " TP=" + string(PositionGetDouble(POSITION_TP)));}
                            if((firstPositionSL - general.pointValue) < sl){//if the sl is different from the opening position adjust stoploss for all positions
                                tradeExtended.updateStopLossAllPositions(EAmagic,general.symbol,(sl+general.pointValue),POSITION_TYPE_SELL);
                            }
                            }
                    }
                }else{//check if the position has been recovered
                    checkTradeRecovery();
                }
            }
        void handleSignals(){//handle signals for opening and closing positions and adding orders
            logTrace(__FUNCTION__,"Handling signals for the symbol: " + general.symbol);
            bool buy = true;
            bool sell = true;
            bool hold = false;
            bool closeBuy = false;
            bool closeSell = false;
            string buyComment = "Buy signal " + getSymbolStr() + " indicators: ";
            string sellComment = "Sell signal " + getSymbolStr() + " indicators: ";
            for(int i=0;i<ArraySize(indicators);i++){//check for buysignal
                if(indicators[i].getBuySignal() == false){
                    buy = false;
                    break;
                }else{
                    buyComment += indicators[i].getDescription() + "|";
                    //logDebug(__FUNCTION__,"Buy signal from indicator: " + indicators[i].getDescription() + " symbol: " + getSymbolStr());
                }
                }
            for(int i=0;i<ArraySize(indicators);i++){//check for close buy positions signal
                if(indicators[i].getCloseBuySignal() == true){
                    closeBuy = true;
                    break;
                }
                }
            for(int i=0;i<ArraySize(indicators);i++){//check for sellsignal
                if(indicators[i].getSellSignal() == false){
                    sell = false;
                    break;
                }else{
                    sellComment += indicators[i].getDescription() + "|";
                    //logDebug(__FUNCTION__,"Sell signal from indicator: " + indicators[i].getDescription() + " symbol: " + getSymbolStr());
                }
                }
            for(int i=0;i<ArraySize(indicators);i++){//check for close sell positions signal
                if(indicators[i].getCloseSellSignal() == true){
                    closeSell = true;
                    break;
                }
                }
            if(buy && checkHoldConditions()){buy = false;}
            if(buy){logInfo(__FUNCTION__,buyComment + "|Tradingmode=" + EnumToString(general.tradingMode) + "|Recovery mode=" + EnumToString(recovery.mode));}
            if(sell && checkHoldConditions()){sell = false;}
            if(sell){logInfo(__FUNCTION__,sellComment + "|Tradingmode=" + EnumToString(general.tradingMode) + "|Recovery mode=" + EnumToString(recovery.mode));}
            
            //handle close signals
            if(closeBuy){//close all buy positions
                tradeExtended.closeAllPositions(EAmagic,general.symbol,POSITION_TYPE_BUY);
                }
            if(closeSell){//close all sell positions
                tradeExtended.closeAllPositions(EAmagic,general.symbol,POSITION_TYPE_SELL);
                }

            //handle signals based on trading mode for opening positions
            if(general.tradingMode == TRADINGMODE_SEARCHING_ENTRY){
                if(buy){//open buy position
                    logTrace(__FUNCTION__,"Tradingmode=" + EnumToString(general.tradingMode) + " start opening a buy position");
                    ulong ticket = openPosition(CALCULATION_TYPE_FIRST_POSITION,POSITION_TYPE_BUY);
                    if(ticket != 0){
                        if(recovery.recover){
                            setFirstPositionParameters(TRADINGMODE_RECOVERY,ticket,POSITION_TYPE_BUY);
                        }else{
                            setFirstPositionParameters(TRADINGMODE_FIRST_POSITION_OPENED,ticket,POSITION_TYPE_BUY);
                        }
                    }
                }else if(sell){//open sell position
                    logTrace(__FUNCTION__,"Tradingmode=" + EnumToString(general.tradingMode) + " start opening a sell position");
                    ulong ticket = openPosition(CALCULATION_TYPE_FIRST_POSITION,POSITION_TYPE_SELL);
                    if(ticket != 0){
                        if(recovery.recover){
                            setFirstPositionParameters(TRADINGMODE_RECOVERY,ticket,POSITION_TYPE_SELL);
                        }else{
                            setFirstPositionParameters(TRADINGMODE_FIRST_POSITION_OPENED,ticket,POSITION_TYPE_SELL);
                        }
                    }
                    }
            }else if(general.tradingMode == TRADINGMODE_FIRST_POSITION_OPENED){
                if(buy){logTrace(__FUNCTION__,"Handling tradingmode first position opened(buy)");}
                if(sell){logTrace(__FUNCTION__,"Handling tradingmode first position opened(sell)");}
                if(buy && tradeExtended.positionsCount(EAmagic,general.symbol) < general.maxPositions){
                    logTrace(__FUNCTION__,"Tradingmode=" + EnumToString(general.tradingMode) + " start opening a buy position");
                    openPosition(CALCULATION_TYPE_MULTIPLE_ADD_NEW,POSITION_TYPE_BUY);
                    setTradingMode(TRADINGMODE_MULTIPLE_POSITIONS_OPEN);
                }else if(sell && tradeExtended.positionsCount(EAmagic,general.symbol) < general.maxPositions){
                    logTrace(__FUNCTION__,"Tradingmode=" + EnumToString(general.tradingMode) + " start opening a sell position");
                    openPosition(CALCULATION_TYPE_MULTIPLE_ADD_NEW,POSITION_TYPE_SELL);
                    setTradingMode(TRADINGMODE_MULTIPLE_POSITIONS_OPEN);
                }
            }else if(general.tradingMode == TRADINGMODE_MULTIPLE_POSITIONS_OPEN){
                if(buy && tradeExtended.positionsCount(EAmagic,general.symbol) < general.maxPositions){
                    logTrace(__FUNCTION__,"Tradingmode=" + EnumToString(general.tradingMode) + " start opening a buy position");
                    openPosition(CALCULATION_TYPE_MULTIPLE_ADD_NEW,POSITION_TYPE_BUY);
                }else if(sell && tradeExtended.positionsCount(EAmagic,general.symbol) < general.maxPositions){
                    logTrace(__FUNCTION__,"Tradingmode=" + EnumToString(general.tradingMode) + " start opening a sell position");
                    openPosition(CALCULATION_TYPE_MULTIPLE_ADD_NEW,POSITION_TYPE_SELL);
                }
            }else if(general.tradingMode == TRADINGMODE_RECOVERY){//handle trade recovery: check order status and add additional orders
                if(buy){logTrace(__FUNCTION__,"Handling tradingmode recovery(buy)");}
                if(sell){logTrace(__FUNCTION__,"Handling tradingmode recovery(sell)");}
                if(recovery.mode == RECOVERY_MODE_ADD || recovery.mode == RECOVERY_MODE_DOUBLE || recovery.mode == RECOVERY_MODE_BASE_LOTS){
                    if(buy){logTrace(__FUNCTION__,"Handling recovery mode add and double(buy)");}
                    if(sell){logTrace(__FUNCTION__,"Handling recovery mode add and double(sell)");}
                    if(buy && recovery.firstPositionType == POSITION_TYPE_SELL){//trade opposite direction from the first position
                        if(tradeExtended.positionsCountTypeBuy(EAmagic,general.symbol) == 0){
                            logTrace(__FUNCTION__,"Start opening a buy position");
                            openPosition(CALCULATION_TYPE_OPPOSITE_TRADE,POSITION_TYPE_BUY);
                            //DebugBreak();
                        }
                    }else if(sell && recovery.firstPositionType == POSITION_TYPE_BUY){//trade opposite direction from the first position
                        if(tradeExtended.positionsCountTypeSell(EAmagic,general.symbol) == 0){
                            logTrace(__FUNCTION__,"Start opening a sell position");
                            openPosition(CALCULATION_TYPE_OPPOSITE_TRADE,POSITION_TYPE_SELL);
                            //DebugBreak();
                        }
                    }
                    handleRecoveryUsingOrders();
                }
            //TRADINGMODE_CLOSING_POSITIONS:closing all positions is handled in the processTickComplete function
            }else{
                logError(__FUNCTION__,"ERROR invalid tradingmode.");
                }
            };
        
        void initTradingMode(){//Set the trading mode based on the amount of open positions
            //check if there is more than 1 position of the same type(buy/sell)
            ulong firstPositionTicket = 0;
            int positionsCount_l = tradeExtended.positionsCount(EAmagic,general.symbol);
            int maxPositionsPerType = 0;//maximum amount of open positions per type
            if(positionsCount_l > 0){
                int buyPositionsCount = tradeExtended.positionsCountTypeBuy(EAmagic,general.symbol);
                int sellPositionsCount = tradeExtended.positionsCountTypeSell(EAmagic,general.symbol);
                if(buyPositionsCount > sellPositionsCount){
                    maxPositionsPerType = buyPositionsCount;
                }else{
                    if(buyPositionsCount < sellPositionsCount){
                        maxPositionsPerType = sellPositionsCount;
                    }else{//buyPositonsCount and sellPositionsCount are equal
                        maxPositionsPerType = buyPositionsCount;
                    }
                }
            }
            //set tradingmode based on the positions count
            //0: searching for entry point
            //1: the first position has been opened
            //2: the first position is in a loss, recovery is active
            switch(maxPositionsPerType){
                case 0:
                    setTradingMode(TRADINGMODE_SEARCHING_ENTRY);
                    logDebug(__FUNCTION__,"Tradingmode initialized to TRADINGMODE_SEARCHING_ENTRY for symbol " + general.symbol);
                    break;
                case 1:
                    setTradingMode(TRADINGMODE_FIRST_POSITION_OPENED);
                    logDebug(__FUNCTION__,"Tradingmode initialized to TRADINGMODE_FIRST_POSITION_OPENED for symbol " + general.symbol);
                    
                    //search the first position for this symbol
                    firstPositionTicket = tradeExtended.getFirstPositionTicket(EAmagic,general.symbol);
                    if(firstPositionTicket != 0){
                        setFirstPositionTicket(firstPositionTicket);
                        ENUM_POSITION_TYPE posType = tradeExtended.getPositionType(firstPositionTicket);
                        if(recovery.recover){
                            setFirstPositionParameters(TRADINGMODE_RECOVERY,firstPositionTicket,posType);
                        }else{
                            setFirstPositionParameters(TRADINGMODE_FIRST_POSITION_OPENED,firstPositionTicket,posType);
                        }
                    }
                    break;
                default://more than one position is open
                    if(general.maxPositions > 1){// when multiple positions are allowed set the tradingmode to TRADINGMODE_MULTIPLE_POSITIONS
                        setTradingMode(TRADINGMODE_MULTIPLE_POSITIONS_OPEN);
                    }else{
                        setTradingMode(TRADINGMODE_RECOVERY);
                        logDebug(__FUNCTION__,"Tradingmode initialized to TRADINGMODE_RECOVERY for symbol " + general.symbol);
                        
                        //search the first position for this symbol
                        firstPositionTicket = tradeExtended.getFirstPositionTicket(EAmagic,general.symbol);
                        if(firstPositionTicket != 0){
                            setFirstPositionTicket(firstPositionTicket);
                            ENUM_POSITION_TYPE posType = tradeExtended.getPositionType(firstPositionTicket);
                            if(recovery.recover){
                                setFirstPositionParameters(TRADINGMODE_RECOVERY,firstPositionTicket,posType);
                            }else{
                                setFirstPositionParameters(TRADINGMODE_FIRST_POSITION_OPENED,firstPositionTicket,posType);
                            }
                        }
                    }
                }
            }
            
            
        void resetZoneRecovery(){
            logEntry(__FUNCTION__);
            recovery.zoneRecoveryTotalBuyLots = 0.0;
            recovery.zoneRecoveryTotalSellLots = 0.0;
            }
        ulong openPosition(ENUM_POSITION_CALCULATION_TYPE posToOpenType_in,ENUM_POSITION_TYPE posType_in){
            double stopLossSetpointOpenBuy;
            double takeProfitSetpointBuy = SymbolInfoDouble(general.symbol,SYMBOL_ASK) + (takeprofit.deviation * general.pointValue);
            double stopLossSetpointOpenSell;
            double takeProfitSetpointSell = SymbolInfoDouble(general.symbol,SYMBOL_BID) - (takeprofit.deviation * general.pointValue);

            //set the lotsize
            double lotsize_l;
            if(posToOpenType_in == CALCULATION_TYPE_FIRST_POSITION || posToOpenType_in == CALCULATION_TYPE_MULTIPLE_ADD_NEW){
                lotsize_l = calculateLotSizeSimple(GetPointer(this));
            }else if(posToOpenType_in == CALCULATION_TYPE_OPPOSITE_TRADE){
                lotsize_l = calculateLotSizeOppositeTrade(GetPointer(this));
            }else{
                lotsize_l = lotsize.lotsize;
            }
            if(lotsize_l == 0){//set the lotsize to the standard lotsize when 0
                logError(__FUNCTION__,"Opposite lotsize is 0, please enter a value for opposite lotsize");
                lotsize_l = lotsize.lotsize;
            }
            if(posType_in == POSITION_TYPE_BUY){
                //set stop loss
                if(recovery.recover && general.tradingMode == TRADINGMODE_SEARCHING_ENTRY){ //Set the recovery stop loss values
                    recovery.stoplossBuy = SymbolInfoDouble(general.symbol,SYMBOL_BID) - ((recovery.deviation * general.pointValue * recovery.maxSteps) + (recovery.deviation * general.pointValue));
                    if(SymbolInfoDouble(general.symbol,SYMBOL_BID) - (stoploss.deviationOpenTrade * general.pointValue) < recovery.stoplossBuy){
                        recovery.stoplossBuy = SymbolInfoDouble(general.symbol,SYMBOL_BID) - (stoploss.deviationOpenTrade * general.pointValue);
                    }
                    stopLossSetpointOpenBuy = recovery.stoplossBuy;
                }else if(recovery.recover && general.tradingMode == TRADINGMODE_RECOVERY){// 1 or more position(s) which can be recovered are open, set the stoploss higer than standard stoploss. Otherwise the new position might hit the stoploss and can never be recovered.
                    stopLossSetpointOpenBuy = recovery.firstPositionPrice - ((recovery.deviation * general.pointValue * recovery.maxSteps) + (stoploss.deviation * general.pointValue));
                }else{
                    stopLossSetpointOpenBuy = SymbolInfoDouble(general.symbol,SYMBOL_BID) - (stoploss.deviationOpenTrade * general.pointValue);
                }

                //execute buy trade
                if(trade.Buy(lotsize_l,general.symbol,SymbolInfoDouble(general.symbol,SYMBOL_ASK),stopLossSetpointOpenBuy,takeProfitSetpointBuy)){//opening a new Position
                    if(trade.ResultRetcode() == TRADE_RETCODE_DONE){//if trade succesfull
                        logInfo(__FUNCTION__,"Buy trade completed");
                        if(soundOnOff){tradeExtended.playSound(SOUND_OPEN_POSITION);}
                        return trade.ResultOrder();
                    }else{                    
                        logError(__FUNCTION__,"Buy() method failed. Return code="+ string(trade.ResultRetcode()) + ". Code description: " + trade.ResultRetcodeDescription());
                    }
                }else{
                    Alert("ERROR while buy trade: " + string(GetLastError()));
                    logError(__FUNCTION__,"ERROR while buy trade: " + string(GetLastError()));
                }
                return 0;
            }else if(posType_in == POSITION_TYPE_SELL){
                //set stop loss
                if(recovery.recover && general.tradingMode == TRADINGMODE_SEARCHING_ENTRY){ //Set the recovery stop loss values
                    recovery.stoplossSell = SymbolInfoDouble(general.symbol,SYMBOL_ASK) + ((recovery.deviation * general.pointValue * recovery.maxSteps) + (stoploss.deviation * general.pointValue));
                    if(SymbolInfoDouble(general.symbol,SYMBOL_ASK) + (stoploss.deviationOpenTrade * general.pointValue) > recovery.stoplossBuy){
                        recovery.stoplossSell = SymbolInfoDouble(general.symbol,SYMBOL_ASK) + (stoploss.deviationOpenTrade * general.pointValue);
                    }
                    stopLossSetpointOpenSell = recovery.stoplossSell;
                }else if(recovery.recover && general.tradingMode == TRADINGMODE_RECOVERY){
                    stopLossSetpointOpenSell = recovery.firstPositionPrice + ((recovery.deviation * general.pointValue * recovery.maxSteps) + (recovery.deviation * general.pointValue));
                }else{
                    stopLossSetpointOpenSell = SymbolInfoDouble(general.symbol,SYMBOL_ASK) + (stoploss.deviationOpenTrade * general.pointValue);
                }

                //execute sell trade
                if(trade.Sell(lotsize_l,general.symbol,SymbolInfoDouble(general.symbol,SYMBOL_BID),stopLossSetpointOpenSell,takeProfitSetpointSell)){
                    if(trade.ResultRetcode() == TRADE_RETCODE_DONE){//if trade succesfull
                        logInfo(__FUNCTION__,"Sell trade completed");
                        if(soundOnOff){tradeExtended.playSound(SOUND_OPEN_POSITION);}
                        return trade.ResultOrder();
                    }else{
                        logError(__FUNCTION__,"Sell() method failed. Return code=" + string(trade.ResultRetcode()) + ". Code description: " + trade.ResultRetcodeDescription());
                    }
                }else{
                    Alert("ERROR while sell trade: " + string(GetLastError()));
                    logError(__FUNCTION__,"ERROR while sell trade: " + string(GetLastError()));
                }
                return 0;
            }
            return 0;
            }
            
        void setFirstPositionTicket(ulong ticket_in){
            if(ticket_in != recovery.firstPositionTicket){
                logDebug(__FUNCTION__,"Setting firstPositionTicket from " + string(recovery.firstPositionTicket) + " to " + string(ticket_in));
                recovery.firstPositionTicket = ticket_in;
            }
            }
        void setFirstPositionPrice(double price_in){
            if(price_in != recovery.firstPositionPrice){
                logDebug(__FUNCTION__,"Setting firstPositionPrice from " + string(recovery.firstPositionPrice) + " to " + string(price_in));
                recovery.firstPositionPrice = price_in;
            }
            }
        void setFirstPositionType(ENUM_POSITION_TYPE posType_in){
            logDebug(__FUNCTION__,"Setting firstPositionType from " + EnumToString(recovery.firstPositionType) + " to " + EnumToString(posType_in));
            recovery.firstPositionType = posType_in;
            }
        void setZoneRecoveryLatestPositionType(ENUM_POSITION_TYPE posType_in){
            if(posType_in != recovery.zoneRecoveryLatestPositionType){
                logDebug(__FUNCTION__,"Setting zone recovery latest position type from " + string(recovery.zoneRecoveryLatestPositionType) + " to " + string(posType_in));
                recovery.zoneRecoveryLatestPositionType = posType_in;
            }
            }
        void setZoneRecoveryLotsTotals(ENUM_POSITION_TYPE posType_in, double lots_in){
            if(posType_in == POSITION_TYPE_BUY){
                logDebug(__FUNCTION__,"Setting zone recovery total buy lots from " + string(recovery.zoneRecoveryTotalBuyLots) + " to " + string(recovery.zoneRecoveryTotalBuyLots + lots_in));
                recovery.zoneRecoveryTotalBuyLots += lots_in;
            }else{
                logDebug(__FUNCTION__,"Setting zone recovery total buy lots from " + string(recovery.zoneRecoveryTotalSellLots) + " to " + string(recovery.zoneRecoveryTotalSellLots + lots_in));
                recovery.zoneRecoveryTotalSellLots += lots_in;
            }
            }
        void setFirstPositionParameters(ENUM_TRADINGMODE tradingMode_in,ulong ticket_in,ENUM_POSITION_TYPE posType_in){
            setTradingMode(tradingMode_in);
            setFirstPositionTicket(ticket_in);
            setFirstPositionPrice(tradeExtended.getPositionPrice(ticket_in));
            setFirstPositionType(posType_in);
            if(recovery.mode == RECOVERY_MODE_ZONE_RECOVERY){
                resetZoneRecovery();
                setZoneRecoveryLatestPositionType(posType_in);
                setZoneRecoveryLotsTotals(posType_in,calculateLotSizeZoneRecovery(posType_in,GetPointer(this)));
            }
            }
        void setTradingMode(ENUM_TRADINGMODE tradingMode_in){
            if(tradingMode_in != general.tradingMode){//check if the trading mode is already correct to prevent unnecessary logging
                logDebug(__FUNCTION__,"Changing trading mode from " + EnumToString(general.tradingMode) + " to " + EnumToString(tradingMode_in) + " for symbol " + general.symbol);
                general.tradingMode = tradingMode_in;
            }
            }
        void updateIndicators(double &closingPrice){//update all indicators for the symbol
            logTrace(__FUNCTION__,"updating all indicators for the symbol: " + general.symbol);
            for(int i=0;i<ArraySize(indicators);i++){
               indicators[i].updateValues(closingPrice);
            }
            };
        void updateStopLoss(ENUM_POSITION_TYPE posType_in){
            logTrace(__FUNCTION__,"Updating stoploss for symbol " + general.symbol);
            for(int i=0;i<PositionsTotal();i++){
                if(PositionGetSymbol(i)== general.symbol){
                    double positionStoploss =NormalizeDouble(PositionGetDouble(POSITION_SL),5);
                    double positionTakeprofit = NormalizeDouble(PositionGetDouble(POSITION_TP),5);
                    long ticket = PositionGetInteger(POSITION_TICKET);
                    if(posType_in == POSITION_TYPE_BUY && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                        double stopLossSetpointBuy = rates[0].close - (stoploss.deviation * general.pointValue);
                        if(positionStoploss == 0){
                            tradeExtended.modifyPosition(ticket,stopLossSetpointBuy,positionTakeprofit,positionStoploss,positionTakeprofit);//if the stop loss is not set, set the stop loss
                        }else{
                            if(stopLossSetpointBuy > (positionStoploss + (general.pointValue/2))){
                                double minimumTreshold = PositionGetDouble(POSITION_PRICE_OPEN) + (stoploss.deviationProfitTreshold * general.pointValue);
                                if(stopLossSetpointBuy > minimumTreshold){
                                    if(stopLossSetpointBuy < SymbolInfoDouble(general.symbol,SYMBOL_BID)){//check if the calculated stoploss is above the bid price, this is important when the spread is high
                                        tradeExtended.modifyPosition(ticket,stopLossSetpointBuy,positionTakeprofit,positionStoploss,positionTakeprofit);
                                    }else{
                                        logTrace(__FUNCTION__,"Calculated stoploss(" + string(stopLossSetpointBuy) + ") is above the bid price(" + string(SymbolInfoDouble(general.symbol,SYMBOL_BID)) + "), stoploss will not be adjusted. Possibly spread is high");
                                    }
                                }else{
                                    logTrace(__FUNCTION__,"Calculated stoploss(" + string(stopLossSetpointBuy) + ") is not above the minimum profit treshold(" + string(minimumTreshold) + "), no update required.");
                                }
                            }else{
                                logTrace(__FUNCTION__,"Calculated stop loss("+string(stopLossSetpointBuy)+") must be higher than current stop loss(" + string(positionStoploss) + "), no update required");
                            }
                        }
                    }else if(posType_in == POSITION_TYPE_SELL && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                        double stopLossSetpointSell = rates[0].close + (stoploss.deviation * general.pointValue);
                        if(positionStoploss == 0){
                            tradeExtended.modifyPosition(ticket,stopLossSetpointSell,positionTakeprofit,positionStoploss,positionTakeprofit);//if the stop loss is not set, set the stop loss
                        }else{
                            if(stopLossSetpointSell < positionStoploss){
                                double minimumTreshold = PositionGetDouble(POSITION_PRICE_OPEN) - (stoploss.deviationProfitTreshold * general.pointValue);
                                if(stopLossSetpointSell < minimumTreshold){
                                    if(stopLossSetpointSell > SymbolInfoDouble(general.symbol,SYMBOL_ASK)){
                                        tradeExtended.modifyPosition(ticket,stopLossSetpointSell,positionTakeprofit,positionStoploss,positionTakeprofit);
                                    }else{
                                        logTrace(__FUNCTION__,"Calculated stoploss(" + string(stopLossSetpointSell) + ") is below the ask price(" + string(SymbolInfoDouble(general.symbol,SYMBOL_ASK)) + "), stoploss will not be adjusted. Possibly spread is high");
                                    }
                                }else{
                                    logTrace(__FUNCTION__,"Calculated stoploss(" + string(stopLossSetpointSell) + ") is not below the minimum profit treshold(" + string(minimumTreshold) + "), no update required.");
                                }
                            }else{
                                logTrace(__FUNCTION__,"Calculated stop loss(" + string(stopLossSetpointSell) + ") must be lower than the current stop loss("+string(positionStoploss)+"), no update required");
                            }
                        }
                    }
                }
            }
            };
        void updateStatistics(){
            double currentDD = AccountInfoDouble(ACCOUNT_BALANCE)-AccountInfoDouble(ACCOUNT_EQUITY);
            if(currentDD > stats.maxDD){
               stats.maxDD = currentDD;
            }
            }
    public:
        general_variables general;
        lotsize_variables lotsize;
        stoploss_variables stoploss;
        takeprofit_variables takeprofit;
        recovery_variables recovery;
        statistics_variables stats;
        void CSymbolHandler(ENUM_SYMBOLS pairIn, ENUM_TIMEFRAMES period_in){//constructor
            logTrace(__FUNCTION__,"CSymbolHandler constructor called for symbol: " + EnumToString(pairIn));
            general.period = period_in;
            general.pointValue = SymbolInfoDouble(general.symbol,SYMBOL_POINT);
            lotsize.oppositeTradeLotSize = lotsize.lotsize;
            recovery.firstPositionTicket = 0;
            chart.zoneLinesActive = false;
            if (pairIn == EURUSD){
                general.symbol = symbolName_EURUSD;
                general.pointValue = SymbolInfoDouble(general.symbol,SYMBOL_POINT);
                general.maxPositions = maxPositionsEURUSD;
                general.maxSpread = maxSpreadEURUSD;
                lotsize.lotsize = baseLotSizeEURUSD;
                lotsize.oppositeTradeLotSize = oppositeTradeLotSizeEURUSD;
                lotsize.method = lotSizeCalculationMethodEURUSD;
                lotsize.equityStep = equityStepEURUSD;
                lotsize.equityMinimum = equityStartAutoSizeEURUSD;
                lotsize.risk = riskPercentageEURUSD;
                lotsize.autoIncreaseLotsize = autoIncreaseLotsizeEURUSD;
                stoploss.trailingstopOnOff = trailingstopOnOffEURUSD;
                stoploss.deviation = stopLossDeviationEURUSD;
                stoploss.deviationMinimum = stopLossDeviationMinimumEURUSD;
                stoploss.deviationOpenTrade = stopLossDeviationOpenTradeEURUSD;
                stoploss.deviationProfitTreshold = stopLossDeviationProfitTresholdEURUSD;
                takeprofit.deviation = takeProfitValueFixedEURUSD;
                recovery.recover = tradeRecoveryOnOffEURUSD;
                recovery.mode = tradeRecoveryModeEURUSD;
                recovery.maxSteps = tradeRecoveryModeMaxStepsEURUSD;
                recovery.deviation = tradeRecoveryDeviationEURUSD;
                recovery.stepFactor = tradeRecoveryDeviationFactorEURUSD;
                recovery.exitMode = tradeRecoveryExitModeEURUSD;
                recovery.trailingDeviation = tradeRecoveryTrailingDeviationEURUSD;
                recovery.zoneRecoveryTarget = tradeRecoveryZoneTargetEURUSD;
                recovery.zoneRecoveryZone = tradeRecoveryZoneEURUSD;
                recovery.zoneRecoveryCommission = tradeRecoveryZoneCommissionEURUSD;
                recovery.zoneRecoveryCutOffPercentage = tradeRecoveryZoneEquityCutOffEURUSD;
                //if(bollingerOnOffEURUSD){
                //    int id = AddIndicator(BOLLINGERBANDS);
                //    indicators[id].initialize(general.symbol,general.period,bandsPeriodEURUSD,bandsShiftEURUSD,bandsAmountEURUSD,bandsDeviationEURUSD,bandsAppPriceEURUSD);
                //}
                if(rsiOnOffEURUSD){
                    int id = AddIndicator(RSI);
                    indicators[id].initialize(general.symbol,general.period,RSIPeriodsEURUSD,RSIAppPriceEURUSD,RSIoverboughtLevelEURUSD,RSIoversoldLevelEURUSD);
                }
                if(envelopesOnOffEURUSD){
                    int id = AddIndicator(ENVELOPES);
                    indicators[id].initialize(general.symbol,general.period,envelopesSignalModeEURUSD,envelopesPeriodEURUSD,envelopesShiftEURUSD,envelopesMethodEURUSD,envelopesAppPriceEURUSD,envelopesDeviationEURUSD);
                }
                //if(movingAverageOnOffEURUSD){
                //    int id = AddIndicator(MA);
                //    indicators[id].initialize(general.symbol,general.period,MAPeriodsEURUSD,MAShiftEURUSD,MAMethodEURUSD,MAAppPriceEURUSD);
                //}
                if(heikenAshiOnOffEURUSD){
                    int id = AddIndicator(HEIKENASHI);
                    indicators[id].initialize(general.symbol,general.period,HAPeriodEURUSD,HAMethodEURUSD,HAStepEURUSD,HABetterFormulaEURUSD);
                }
                }
            if (pairIn == GBPUSD){
                general.symbol = symbolName_GBPUSD;
                general.pointValue = SymbolInfoDouble(general.symbol,SYMBOL_POINT);
                general.maxPositions = maxPositionsGBPUSD;
                general.maxSpread = maxSpreadGBPUSD;
                lotsize.lotsize = baseLotSizeGBPUSD;
                lotsize.oppositeTradeLotSize = oppositeTradeLotSizeGBPUSD;
                lotsize.method = lotSizeCalculationMethodGBPUSD;
                lotsize.equityStep = equityStepGBPUSD;
                lotsize.equityMinimum = equityStartAutoSizeGBPUSD;
                lotsize.risk = riskPercentageGBPUSD;
                lotsize.autoIncreaseLotsize = autoIncreaseLotsizeGBPUSD;
                stoploss.trailingstopOnOff = trailingstopOnOffGBPUSD;
                stoploss.deviation = stopLossDeviationGBPUSD;
                stoploss.deviationMinimum = stopLossDeviationMinimumGBPUSD;
                stoploss.deviationOpenTrade = stopLossDeviationOpenTradeGBPUSD;
                stoploss.deviationProfitTreshold = stopLossDeviationProfitTresholdGBPUSD;
                takeprofit.deviation = takeProfitValueFixedGBPUSD;
                recovery.recover = tradeRecoveryOnOffGBPUSD;
                recovery.mode = tradeRecoveryModeGBPUSD;
                recovery.maxSteps = tradeRecoveryModeMaxStepsGBPUSD;
                recovery.deviation = tradeRecoveryDeviationGBPUSD;
                recovery.stepFactor = tradeRecoveryDeviationFactorGBPUSD;
                recovery.exitMode = tradeRecoveryExitModeGBPUSD;
                recovery.trailingDeviation = tradeRecoveryTrailingDeviationGBPUSD;
                recovery.zoneRecoveryTarget = tradeRecoveryZoneTargetGBPUSD;
                recovery.zoneRecoveryZone = tradeRecoveryZoneGBPUSD;
                recovery.zoneRecoveryCommission = tradeRecoveryZoneCommissionGBPUSD;
                if(bollingerOnOffGBPUSD){
                    int id = AddIndicator(BOLLINGERBANDS);
                    indicators[id].initialize(general.symbol,general.period,bandsPeriodGBPUSD,bandsShiftGBPUSD,bandsAmountGBPUSD,bandsDeviationGBPUSD,bandsAppPriceGBPUSD);
                    }
                //if(rsiOnOffGBPUSD){
                //    int id = AddIndicator(RSI);
                //    indicators[id].initialize(general.symbol,general.period,RSIPeriodsGBPUSD,RSIAppPriceGBPUSD,RSIoverboughtLevelGBPUSD,RSIoversoldLevelGBPUSD);
                //    }
                //if(envelopesOnOffGBPUSD){
                //    int id = AddIndicator(ENVELOPES);
                //    indicators[id].initialize(general.symbol,general.period,envelopesSignalModeGBPUSD,envelopesPeriodGBPUSD,envelopesShiftGBPUSD,envelopesMethodGBPUSD,envelopesAppPriceGBPUSD,envelopesDeviationGBPUSD);
                //    }
                //if(movingAverageOnOffGBPUSD){
                //    int id = AddIndicator(MA);
                //    indicators[id].initialize(general.symbol,general.period,MAPeriodsGBPUSD,MAShiftGBPUSD,MAMethodGBPUSD,MAAppPriceGBPUSD);
                //    }
                if(heikenAshiOnOffGBPUSD){
                    int id = AddIndicator(HEIKENASHI);
                    indicators[id].initialize(general.symbol,general.period,HAPeriodGBPUSD,HAMethodGBPUSD,HAStepGBPUSD,HABetterFormulaGBPUSD);
                }
                }
            if (pairIn == USDCHF){
                general.symbol = symbolName_USDCHF;
                general.pointValue = SymbolInfoDouble(general.symbol,SYMBOL_POINT);
                general.maxPositions = maxPositionsUSDCHF;
                general.maxSpread = maxSpreadUSDCHF;
                lotsize.lotsize = baseLotSizeUSDCHF;
                lotsize.oppositeTradeLotSize = oppositeTradeLotSizeUSDCHF;
                lotsize.method = lotSizeCalculationMethodUSDCHF;
                lotsize.equityStep = equityStepUSDCHF;
                lotsize.equityMinimum = equityStartAutoSizeUSDCHF;
                lotsize.risk = riskPercentageUSDCHF;
                lotsize.autoIncreaseLotsize = autoIncreaseLotsizeUSDCHF;
                stoploss.trailingstopOnOff = trailingstopOnOffUSDCHF;
                stoploss.deviation = stopLossDeviationUSDCHF;
                stoploss.deviationMinimum = stopLossDeviationMinimumUSDCHF;
                stoploss.deviationOpenTrade = stopLossDeviationOpenTradeUSDCHF;
                stoploss.deviationProfitTreshold = stopLossDeviationProfitTresholdUSDCHF;
                takeprofit.deviation = takeProfitValueFixedUSDCHF;
                recovery.recover = tradeRecoveryOnOffUSDCHF;
                recovery.mode = tradeRecoveryModeUSDCHF;
                recovery.maxSteps = tradeRecoveryModeMaxStepsUSDCHF;
                recovery.deviation = tradeRecoveryDeviationUSDCHF;
                recovery.stepFactor = tradeRecoveryDeviationFactorUSDCHF;
                recovery.exitMode = tradeRecoveryExitModeUSDCHF;
                recovery.trailingDeviation = tradeRecoveryTrailingDeviationUSDCHF;
                recovery.zoneRecoveryTarget = tradeRecoveryZoneTargetUSDCHF;
                recovery.zoneRecoveryZone = tradeRecoveryZoneUSDCHF;
                recovery.zoneRecoveryCommission = tradeRecoveryZoneCommissionUSDCHF;
                //if(bollingerOnOffUSDCHF){
                    //int id = AddIndicator(BOLLINGERBANDS);
                    //indicators[id].initialize(general.symbol,general.period,bandsPeriodUSDCHF,bandsShiftUSDCHF,bandsAmountUSDCHF,bandsDeviationUSDCHF,bandsAppPriceUSDCHF);
                    //}
                //if(rsiOnOffUSDCHF){
                    //int id = AddIndicator(RSI);
                    //indicators[id].initialize(general.symbol,general.period,RSIPeriodsUSDCHF,RSIAppPriceUSDCHF,RSIoverboughtLevelUSDCHF,RSIoversoldLevelUSDCHF);
                    //}
                if(envelopesOnOffUSDCHF){
                    int id = AddIndicator(ENVELOPES);
                    indicators[id].initialize(general.symbol,general.period,envelopesSignalModeUSDCHF,envelopesPeriodUSDCHF,envelopesShiftUSDCHF,envelopesMethodUSDCHF,envelopesAppPriceUSDCHF,envelopesDeviationUSDCHF);
                    }
                if(movingAverageOnOffUSDCHF){
                    int id = AddIndicator(MA);
                    indicators[id].initialize(general.symbol,general.period,MAPeriodsUSDCHF,MAShiftUSDCHF,MAMethodUSDCHF,MAAppPriceUSDCHF);
                    }
                if(heikenAshiOnOffUSDCHF){
                    int id = AddIndicator(HEIKENASHI);
                    indicators[id].initialize(general.symbol,general.period,HAPeriodUSDCHF,HAMethodUSDCHF,HAStepUSDCHF,HABetterFormulaUSDCHF);
                }
                }
            if (pairIn == USDJPY){
                general.symbol = symbolName_USDJPY;
                general.pointValue = SymbolInfoDouble(general.symbol,SYMBOL_POINT);
                general.maxPositions = maxPositionsUSDJPY;
                general.maxSpread = maxSpreadUSDJPY;
                lotsize.lotsize = baseLotSizeUSDJPY;
                lotsize.oppositeTradeLotSize = oppositeTradeLotSizeUSDJPY;
                lotsize.method = lotSizeCalculationMethodUSDJPY;
                lotsize.equityStep = equityStepUSDJPY;
                lotsize.equityMinimum = equityStartAutoSizeUSDJPY;
                lotsize.risk = riskPercentageUSDJPY;
                lotsize.autoIncreaseLotsize = autoIncreaseLotsizeUSDJPY;
                stoploss.trailingstopOnOff = trailingstopOnOffUSDJPY;
                stoploss.deviation = stopLossDeviationUSDJPY;
                stoploss.deviationMinimum = stopLossDeviationMinimumUSDJPY;
                stoploss.deviationOpenTrade = stopLossDeviationOpenTradeUSDJPY;
                stoploss.deviationProfitTreshold = stopLossDeviationProfitTresholdUSDJPY;
                takeprofit.deviation = takeProfitValueFixedUSDJPY;
                recovery.recover = tradeRecoveryOnOffUSDJPY;
                recovery.mode = tradeRecoveryModeUSDJPY;
                recovery.maxSteps = tradeRecoveryModeMaxStepsUSDJPY;
                recovery.deviation = tradeRecoveryDeviationUSDJPY;
                recovery.stepFactor = tradeRecoveryDeviationFactorUSDJPY;
                recovery.exitMode = tradeRecoveryExitModeUSDJPY;
                recovery.trailingDeviation = tradeRecoveryTrailingDeviationUSDJPY;
                recovery.zoneRecoveryTarget = tradeRecoveryZoneTargetUSDJPY;
                recovery.zoneRecoveryZone = tradeRecoveryZoneUSDJPY;
                recovery.zoneRecoveryCommission = tradeRecoveryZoneCommissionUSDJPY;
                //if(bollingerOnOffUSDJPY){
                    //int id = AddIndicator(BOLLINGERBANDS);
                    //indicators[id].initialize(general.symbol,general.period,bandsPeriodUSDJPY,bandsShiftUSDJPY,bandsAmountUSDJPY,bandsDeviationUSDJPY,bandsAppPriceUSDJPY);
                    //}
                //if(rsiOnOffUSDJPY){
                    //int id = AddIndicator(RSI);
                    //indicators[id].initialize(general.symbol,general.period,RSIPeriodsUSDJPY,RSIAppPriceUSDJPY,RSIoverboughtLevelUSDJPY,RSIoversoldLevelUSDJPY);
                    //}
                if(envelopesOnOffUSDJPY){
                    int id = AddIndicator(ENVELOPES);
                    indicators[id].initialize(general.symbol,general.period,envelopesSignalModeUSDJPY,envelopesPeriodUSDJPY,envelopesShiftUSDJPY,envelopesMethodUSDJPY,envelopesAppPriceUSDJPY,envelopesDeviationUSDJPY);
                    }
                if(movingAverageOnOffUSDJPY){
                    int id = AddIndicator(MA);
                    indicators[id].initialize(general.symbol,general.period,MAPeriodsUSDJPY,MAShiftUSDJPY,MAMethodUSDJPY,MAAppPriceUSDJPY);
                    }
                if(heikenAshiOnOffUSDJPY){
                    int id = AddIndicator(HEIKENASHI);
                    indicators[id].initialize(general.symbol,general.period,HAPeriodUSDJPY,HAMethodUSDJPY,HAStepUSDJPY,HABetterFormulaUSDJPY);
                }
                }
            if (pairIn == USDCAD){
                general.symbol = symbolName_USDCAD;
                general.pointValue = SymbolInfoDouble(general.symbol,SYMBOL_POINT);
                general.maxPositions = maxPositionsUSDCAD;
                general.maxSpread = maxSpreadUSDCAD;
                lotsize.lotsize = baseLotSizeUSDCAD;
                lotsize.oppositeTradeLotSize = oppositeTradeLotSizeUSDCAD;
                lotsize.method = lotSizeCalculationMethodUSDCAD;
                lotsize.equityStep = equityStepUSDCAD;
                lotsize.equityMinimum = equityStartAutoSizeUSDCAD;
                lotsize.risk = riskPercentageUSDCAD;
                lotsize.autoIncreaseLotsize = autoIncreaseLotsizeUSDCAD;
                stoploss.trailingstopOnOff = trailingstopOnOffUSDCAD;
                stoploss.deviation = stopLossDeviationUSDCAD;
                stoploss.deviationMinimum = stopLossDeviationMinimumUSDCAD;
                stoploss.deviationOpenTrade = stopLossDeviationOpenTradeUSDCAD;
                stoploss.deviationProfitTreshold = stopLossDeviationProfitTresholdUSDCAD;
                takeprofit.deviation = takeProfitValueFixedUSDCAD;
                recovery.recover = tradeRecoveryOnOffUSDCAD;
                recovery.mode = tradeRecoveryModeUSDCAD;
                recovery.maxSteps = tradeRecoveryModeMaxStepsUSDCAD;
                recovery.deviation = tradeRecoveryDeviationUSDCAD;
                recovery.stepFactor = tradeRecoveryDeviationFactorUSDCAD;
                recovery.exitMode = tradeRecoveryExitModeUSDCAD;
                recovery.trailingDeviation = tradeRecoveryTrailingDeviationUSDCAD;
                recovery.zoneRecoveryTarget = tradeRecoveryZoneTargetUSDCAD;
                recovery.zoneRecoveryZone = tradeRecoveryZoneUSDCAD;
                recovery.zoneRecoveryCommission = tradeRecoveryZoneCommissionUSDCAD;
                //if(bollingerOnOffUSDCAD){
                    //int id = AddIndicator(BOLLINGERBANDS);
                    //indicators[id].initialize(general.symbol,general.period,bandsPeriodUSDCAD,bandsShiftUSDCAD,bandsAmountUSDCAD,bandsDeviationUSDCAD,bandsAppPriceUSDCAD);
                //}
                //if(rsiOnOffUSDCAD){
                    //int id = AddIndicator(RSI);
                    //indicators[id].initialize(general.symbol,general.period,RSIPeriodsUSDCAD,RSIAppPriceUSDCAD,RSIoverboughtLevelUSDCAD,RSIoversoldLevelUSDCAD);
                //}
                if(envelopesOnOffUSDCAD){
                    int id = AddIndicator(ENVELOPES);
                    indicators[id].initialize(general.symbol,general.period,envelopesSignalModeUSDCAD,envelopesPeriodUSDCAD,envelopesShiftUSDCAD,envelopesMethodUSDCAD,envelopesAppPriceUSDCAD,envelopesDeviationUSDCAD);
                }
                if(movingAverageOnOffUSDCAD){
                    int id = AddIndicator(MA);
                    indicators[id].initialize(general.symbol,general.period,MAPeriodsUSDCAD,MAShiftUSDCAD,MAMethodUSDCAD,MAAppPriceUSDCAD);
                }
                if(heikenAshiOnOffUSDCAD){
                    int id = AddIndicator(HEIKENASHI);
                    indicators[id].initialize(general.symbol,general.period,HAPeriodUSDCAD,HAMethodUSDCAD,HAStepUSDCAD,HABetterFormulaUSDCAD);
                }
                }
            if (pairIn == EURGBP){
                general.symbol = symbolName_EURGBP;
                general.pointValue = SymbolInfoDouble(general.symbol,SYMBOL_POINT);
                general.maxPositions = maxPositionsEURGBP;
                general.maxSpread = maxSpreadEURGBP;
                lotsize.lotsize = baseLotSizeEURGBP;
                lotsize.oppositeTradeLotSize = oppositeTradeLotSizeEURGBP;
                lotsize.method = lotSizeCalculationMethodEURGBP;
                lotsize.equityStep = equityStepEURGBP;
                lotsize.equityMinimum = equityStartAutoSizeEURGBP;
                lotsize.risk = riskPercentageEURGBP;
                lotsize.autoIncreaseLotsize = autoIncreaseLotsizeEURGBP;
                stoploss.trailingstopOnOff = trailingstopOnOffEURGBP;
                stoploss.deviation = stopLossDeviationEURGBP;
                stoploss.deviationMinimum = stopLossDeviationMinimumEURGBP;
                stoploss.deviationOpenTrade = stopLossDeviationOpenTradeEURGBP;
                stoploss.deviationProfitTreshold = stopLossDeviationProfitTresholdEURGBP;
                takeprofit.deviation = takeProfitValueFixedEURGBP;
                recovery.recover = tradeRecoveryOnOffEURGBP;
                recovery.mode = tradeRecoveryModeEURGBP;
                recovery.maxSteps = tradeRecoveryModeMaxStepsEURGBP;
                recovery.deviation = tradeRecoveryDeviationEURGBP;
                recovery.stepFactor = tradeRecoveryDeviationFactorEURGBP;
                recovery.exitMode = tradeRecoveryExitModeEURGBP;
                recovery.trailingDeviation = tradeRecoveryTrailingDeviationEURGBP;
                recovery.zoneRecoveryTarget = tradeRecoveryZoneTargetEURGBP;
                recovery.zoneRecoveryZone = tradeRecoveryZoneEURGBP;
                recovery.zoneRecoveryCommission = tradeRecoveryZoneCommissionEURGBP;
                //if(bollingerOnOffEURGBP){
                    //int id = AddIndicator(BOLLINGERBANDS);
                    //indicators[id].initialize(general.symbol,general.period,bandsPeriodEURGBP,bandsShiftEURGBP,bandsAmountEURGBP,bandsDeviationEURGBP,bandsAppPriceEURGBP);
                //}
                //if(rsiOnOffEURGBP){
                    //int id = AddIndicator(RSI);
                    //indicators[id].initialize(general.symbol,general.period,RSIPeriodsEURGBP,RSIAppPriceEURGBP,RSIoverboughtLevelEURGBP,RSIoversoldLevelEURGBP);
                //}
                if(envelopesOnOffEURGBP){
                    int id = AddIndicator(ENVELOPES);
                    indicators[id].initialize(general.symbol,general.period,envelopesSignalModeEURGBP,envelopesPeriodEURGBP,envelopesShiftEURGBP,envelopesMethodEURGBP,envelopesAppPriceEURGBP,envelopesDeviationEURGBP);
                }
                if(movingAverageOnOffEURGBP){
                    int id = AddIndicator(MA);
                    indicators[id].initialize(general.symbol,general.period,MAPeriodsEURGBP,MAShiftEURGBP,MAMethodEURGBP,MAAppPriceEURGBP);
                }
                if(heikenAshiOnOffEURGBP){
                    int id = AddIndicator(HEIKENASHI);
                    indicators[id].initialize(general.symbol,general.period,HAPeriodEURGBP,HAMethodEURGBP,HAStepEURGBP,HABetterFormulaEURGBP);
                }
                }
            if (pairIn == AUDNZD){
                general.symbol = symbolName_AUDNZD;
                general.pointValue = SymbolInfoDouble(general.symbol,SYMBOL_POINT);
                general.maxPositions = maxPositionsAUDNZD;
                general.maxSpread = maxSpreadAUDNZD;
                lotsize.lotsize = baseLotSizeAUDNZD;
                lotsize.oppositeTradeLotSize = oppositeTradeLotSizeAUDNZD;
                lotsize.method = lotSizeCalculationMethodAUDNZD;
                lotsize.equityStep = equityStepAUDNZD;
                lotsize.equityMinimum = equityStartAutoSizeAUDNZD;
                lotsize.risk = riskPercentageAUDNZD;
                lotsize.autoIncreaseLotsize = autoIncreaseLotsizeAUDNZD;
                stoploss.trailingstopOnOff = trailingstopOnOffAUDNZD;
                stoploss.deviation = stopLossDeviationAUDNZD;
                stoploss.deviationMinimum = stopLossDeviationMinimumAUDNZD;
                stoploss.deviationOpenTrade = stopLossDeviationOpenTradeAUDNZD;
                stoploss.deviationProfitTreshold = stopLossDeviationProfitTresholdAUDNZD;
                takeprofit.deviation = takeProfitValueFixedAUDNZD;
                recovery.recover = tradeRecoveryOnOffAUDNZD;
                recovery.mode = tradeRecoveryModeAUDNZD;
                recovery.maxSteps = tradeRecoveryModeMaxStepsAUDNZD;
                recovery.deviation = tradeRecoveryDeviationAUDNZD;
                recovery.stepFactor = tradeRecoveryDeviationFactorAUDNZD;
                recovery.exitMode = tradeRecoveryExitModeAUDNZD;
                recovery.trailingDeviation = tradeRecoveryTrailingDeviationAUDNZD;
                recovery.zoneRecoveryTarget = tradeRecoveryZoneTargetAUDNZD;
                recovery.zoneRecoveryZone = tradeRecoveryZoneAUDNZD;
                recovery.zoneRecoveryCommission = tradeRecoveryZoneCommissionAUDNZD;
                //if(bollingerOnOffAUDNZD){
                    //int id = AddIndicator(BOLLINGERBANDS);
                    //indicators[id].initialize(general.symbol,general.period,bandsPeriodAUDNZD,bandsShiftAUDNZD,bandsAmountAUDNZD,bandsDeviationAUDNZD,bandsAppPriceAUDNZD);
                //}
                //if(rsiOnOffAUDNZD){
                    //int id = AddIndicator(RSI);
                    //indicators[id].initialize(general.symbol,general.period,RSIPeriodsAUDNZD,RSIAppPriceAUDNZD,RSIoverboughtLevelAUDNZD,RSIoversoldLevelAUDNZD);
                //}
                if(envelopesOnOffAUDNZD){
                    int id = AddIndicator(ENVELOPES);
                    indicators[id].initialize(general.symbol,general.period,envelopesSignalModeAUDNZD,envelopesPeriodAUDNZD,envelopesShiftAUDNZD,envelopesMethodAUDNZD,envelopesAppPriceAUDNZD,envelopesDeviationAUDNZD);
                }
                if(movingAverageOnOffAUDNZD){
                    int id = AddIndicator(MA);
                    indicators[id].initialize(general.symbol,general.period,MAPeriodsAUDNZD,MAShiftAUDNZD,MAMethodAUDNZD,MAAppPriceAUDNZD);
                }
                if(heikenAshiOnOffAUDNZD){
                    int id = AddIndicator(HEIKENASHI);
                    indicators[id].initialize(general.symbol,general.period,HAPeriodAUDNZD,HAMethodAUDNZD,HAStepAUDNZD,HABetterFormulaAUDNZD);
                }
                }
            if (pairIn == SYMBOL1){
                general.symbol = symbolName_Symbol1;
                general.pointValue = SymbolInfoDouble(general.symbol,SYMBOL_POINT);
                general.maxPositions = maxPositions_Symbol1;
                general.maxSpread = maxSpread_Symbol1;
                general.pointValue = SymbolInfoDouble(general.symbol,SYMBOL_POINT);
                lotsize.lotsize = baseLotSize_Symbol1;
                lotsize.oppositeTradeLotSize = oppositeTradeLotSize_Symbol1;
                lotsize.method = lotSizeCalculationMethod_Symbol1;
                lotsize.equityStep = equityStep_Symbol1;
                lotsize.equityMinimum = equityStartAutoSize_Symbol1;
                lotsize.risk = riskPercentage_Symbol1;
                lotsize.autoIncreaseLotsize = autoIncreaseLotsize_Symbol1;
                stoploss.trailingstopOnOff = trailingstopOnOff_Symbol1;
                stoploss.deviation = stopLossDeviation_Symbol1;
                stoploss.deviationMinimum = stopLossDeviationMinimum_Symbol1;
                stoploss.deviationOpenTrade = stopLossDeviationOpenTrade_Symbol1;
                stoploss.deviationProfitTreshold = stopLossDeviationProfitTreshold_Symbol1;
                takeprofit.deviation = takeProfitValueFixed_Symbol1;
                takeprofit.commission = takeProfitCommission_Symbol1;
                recovery.recover = tradeRecoveryOnOff_Symbol1;
                recovery.mode = tradeRecoveryMode_Symbol1;
                recovery.maxSteps = tradeRecoveryModeMaxSteps_Symbol1;
                recovery.deviation = tradeRecoveryDeviation_Symbol1;
                recovery.stepFactor = tradeRecoveryDeviationFactor_Symbol1;
                recovery.exitMode = tradeRecoveryExitMode_Symbol1;
                recovery.trailingDeviation = tradeRecoveryTrailingDeviation_Symbol1;
                recovery.zoneRecoveryTarget = tradeRecoveryZoneTarget_Symbol1;
                recovery.zoneRecoveryZone = tradeRecoveryZone_Symbol1;
                recovery.zoneRecoveryCommission = tradeRecoveryZoneCommission_Symbol1;
                if(bollingerOnOff_Symbol1){
                    int id = AddIndicator(BOLLINGERBANDS);
                    indicators[id].initialize(general.symbol,general.period,bandsPeriod_Symbol1,bandsShift_Symbol1,bandsAmount_Symbol1,bandsDeviation_Symbol1,bandsAppPrice_Symbol1);
                }
                if(rsiOnOff_Symbol1){
                    int id = AddIndicator(RSI);
                    indicators[id].initialize(general.symbol,general.period,RSIPeriods_Symbol1,RSIAppPrice_Symbol1,RSIoverboughtLevel_Symbol1,RSIoversoldLevel_Symbol1);
                }
                if(envelopesOnOff_Symbol1){
                    int id = AddIndicator(ENVELOPES);
                    indicators[id].initialize(general.symbol,general.period,envelopesSignalMode_Symbol1,envelopesPeriod_Symbol1,envelopesShift_Symbol1,envelopesMethod_Symbol1,envelopesAppPrice_Symbol1,envelopesDeviation_Symbol1);
                }
                if(movingAverageOnOff_Symbol1){
                    int id = AddIndicator(MA);
                    indicators[id].initialize(general.symbol,general.period,MAPeriods_Symbol1,MAShift_Symbol1,MAMethod_Symbol1,MAAppPrice_Symbol1);
                }
                if(heikenAshiOnOff_Symbol1){
                    int id = AddIndicator(HEIKENASHI);
                    indicators[id].initialize(general.symbol,general.period,HAPeriod_Symbol1,HAMethod_Symbol1,HAStep_Symbol1,HABetterFormula_Symbol1);
                }
                }         
            if (pairIn == SYMBOL2){
                general.symbol = symbolName_Symbol2;
                general.pointValue = SymbolInfoDouble(general.symbol,SYMBOL_POINT);
                general.maxPositions = maxPositions_Symbol2;
                general.maxSpread = maxSpread_Symbol2;
                general.pointValue = SymbolInfoDouble(general.symbol,SYMBOL_POINT);
                lotsize.lotsize = baseLotSize_Symbol2;
                lotsize.oppositeTradeLotSize = oppositeTradeLotSize_Symbol2;
                lotsize.method = lotSizeCalculationMethod_Symbol2;
                lotsize.equityStep = equityStep_Symbol2;
                lotsize.equityMinimum = equityStartAutoSize_Symbol2;
                lotsize.risk = riskPercentage_Symbol2;
                lotsize.autoIncreaseLotsize = autoIncreaseLotsize_Symbol2;
                stoploss.trailingstopOnOff = trailingstopOnOff_Symbol2;
                stoploss.deviation = stopLossDeviation_Symbol2;
                stoploss.deviationMinimum = stopLossDeviationMinimum_Symbol2;
                stoploss.deviationOpenTrade = stopLossDeviationOpenTrade_Symbol2;
                stoploss.deviationProfitTreshold = stopLossDeviationProfitTreshold_Symbol2;
                takeprofit.deviation = takeProfitValueFixed_Symbol2;
                takeprofit.commission = takeProfitCommission_Symbol2;
                recovery.recover = tradeRecoveryOnOff_Symbol2;
                recovery.mode = tradeRecoveryMode_Symbol2;
                recovery.maxSteps = tradeRecoveryModeMaxSteps_Symbol2;
                recovery.deviation = tradeRecoveryDeviation_Symbol2;
                recovery.stepFactor = tradeRecoveryDeviationFactor_Symbol2;
                recovery.exitMode = tradeRecoveryExitMode_Symbol2;
                recovery.trailingDeviation = tradeRecoveryTrailingDeviation_Symbol2;
                recovery.zoneRecoveryTarget = tradeRecoveryZoneTarget_Symbol2;
                recovery.zoneRecoveryZone = tradeRecoveryZone_Symbol2;
                recovery.zoneRecoveryCommission = tradeRecoveryZoneCommission_Symbol2;
                if(bollingerOnOff_Symbol2){
                    int id = AddIndicator(BOLLINGERBANDS);
                    indicators[id].initialize(general.symbol,general.period,bandsPeriod_Symbol2,bandsShift_Symbol2,bandsAmount_Symbol2,bandsDeviation_Symbol2,bandsAppPrice_Symbol2);
                }
                if(rsiOnOff_Symbol2){
                    int id = AddIndicator(RSI);
                    indicators[id].initialize(general.symbol,general.period,RSIPeriods_Symbol2,RSIAppPrice_Symbol2,RSIoverboughtLevel_Symbol2,RSIoversoldLevel_Symbol2);
                }
                if(envelopesOnOff_Symbol2){
                    int id = AddIndicator(ENVELOPES);
                    indicators[id].initialize(general.symbol,general.period,envelopesSignalMode_Symbol2,envelopesPeriod_Symbol2,envelopesShift_Symbol2,envelopesMethod_Symbol2,envelopesAppPrice_Symbol2,envelopesDeviation_Symbol2);
                }
                if(movingAverageOnOff_Symbol2){
                    int id = AddIndicator(MA);
                    indicators[id].initialize(general.symbol,general.period,MAPeriods_Symbol2,MAShift_Symbol2,MAMethod_Symbol2,MAAppPrice_Symbol2);
                }
                if(heikenAshiOnOff_Symbol2){
                    int id = AddIndicator(HEIKENASHI);
                    indicators[id].initialize(general.symbol,general.period,HAPeriod_Symbol2,HAMethod_Symbol2,HAStep_Symbol2,HABetterFormula_Symbol2);
                }
                }         
            initTradingMode();//Set the trading mode automatically. This is required after restarting the indicator and continuing the strategy
            };
        string getSymbolStr(){return general.symbol;};
        bool checkSymbolInit(){
            bool initOK = false;
            if(ArraySize(indicators) > 0){
                initOK = true;
            }
            return initOK;
            }   
        void processBarCompleteTrade(){
            logTrace(__FUNCTION__,"Handling symbol " + general.symbol + " after a trade timeframe bar has completed");
            if(CopyRates(general.symbol,0,0,2,rates) > 0){
                //double closingPrice = iClose(general.symbol,tradeTimeframe,1);
                double closingPrice = SymbolInfoDouble(general.symbol,SYMBOL_BID);
                double closingPriceRates = rates[0].close;
                if(closingPrice - closingPriceRates > 0.001){
                    logError(__FUNCTION__,"Close prices do not match, changing rates.close");
                    rates[0].close = closingPrice;
                    //DebugBreak();
                }else{
                    logTrace(__FUNCTION__,"Lastest closing price" + string(closingPrice));
                }
                updateIndicators(closingPrice);
                checkResetParameters();
                checkPendingOrders();
                handleSignals();
            }else{
                logError(__FUNCTION__,"Error while copying rates for symbol " + general.symbol);
            }
            };
        void processBarCompleteUpdate(){
            logTrace(__FUNCTION__,"Handling symbol " + general.symbol + " after a trade timeframe bar has completed");
            if(CopyRates(general.symbol,0,0,2,rates) > 0){
                //double closingPrice = iClose(general.symbol,tradeTimeframe,1); //for some reason the close price is not always correct
                double closingPrice = SymbolInfoDouble(general.symbol,SYMBOL_BID);
                double closingPriceRates = rates[0].close;
                if(closingPrice - closingPriceRates > 0.001){
                    logError(__FUNCTION__,"Close prices do not match, changing rates.close");
                    rates[0].close = closingPrice;
                    //DebugBreak();
                }
                updateCurrentPositions();
                updateStatistics();
                checkMaxDD();
            }
            }
        void processTickComplete(){//check every tick
            if(recovery.mode == RECOVERY_MODE_ZONE_RECOVERY){
                handleZoneRecovery();
            }
            if(general.tradingMode == TRADINGMODE_RECOVERY_EXIT){
                updateTrailingStopRecovery();
            }
            if(general.tradingMode == TRADINGMODE_CLOSING_POSITIONS){
                if(tradeExtended.positionsCount(EAmagic,general.symbol) > 0){
                    tradeExtended.closeAllPositions(EAmagic,general.symbol);
                }else{
                    setTradingMode(TRADINGMODE_SEARCHING_ENTRY);
                }
            }
            }
        double processSecond(){
            double lastSecondProfit = tradeExtended.lastSecondProfit();
            return lastSecondProfit;
            
            }
        void checkPendingOrders(){
            //logEntry(__FUNCTION__,general.symbol);
            if(recovery.firstPositionType == POSITION_TYPE_BUY){
                if(tradeExtended.positionsCountTypeBuy(EAmagic,general.symbol) == 0){
                    logDebug(__FUNCTION__,"No open positions --> deleting all orders for symbol " + general.symbol);
                    tradeExtended.deleteAllOrders(EAmagic,general.symbol);
                    if(tradeExtended.positionsCount(EAmagic,general.symbol) > 0){// another position is open and must be set as the firstposition
                        initTradingMode();
                    }
                }
            }
            if(recovery.firstPositionType == POSITION_TYPE_SELL){
                if(tradeExtended.positionsCountTypeSell(EAmagic,general.symbol) == 0){
                    logDebug(__FUNCTION__,"No open positions --> deleting all orders for symbol " + general.symbol);
                    tradeExtended.deleteAllOrders(EAmagic,general.symbol);
                    if(tradeExtended.positionsCount(EAmagic,general.symbol) > 0){// another position is opoen and must be set as the firstposition
                        initTradingMode();
                    }
                }
            }
            }
        void checkResetParameters(){
            // This method should detect when positions have been closed by trailing stop.
            int positionsCount_l = tradeExtended.positionsCount(EAmagic,general.symbol);
            if(tradeExtended.getFirstPositionTicket(EAmagic,general.symbol) != recovery.firstPositionTicket){//check if the oldest position is also the first postion in the recovery settings. If not some positions have been closed by trailing
                if(positionsCount_l == 1){// in case 1 position is open
                    initTradingMode();
                }else{
                  Print(positionsCount_l);
                }
            }
            if(positionsCount_l == 0 && tradeExtended.orderCount(EAmagic,general.symbol) == 0){
                //logDebug(__FUNCTION__,"No positions and no orders for symbol, resetting parameters " + general.symbol);
                setTradingMode(TRADINGMODE_SEARCHING_ENTRY);
                setFirstPositionTicket(0);
                for(int i=0;i<ArraySize(indicators);i++){
                    indicators[i].resetIndicator();
                }
            }
            }                    
        void deleteIndicators(){
            for(int i=0;i<ArraySize(indicators);i++){
                logInfo(__FUNCTION__,"Deleting indicator " + indicators[i].getDescription());
                delete indicators[i];
            }
            }
        void printStats(){
            logInfo(__FUNCTION__,"Maximum drawdown: " + DoubleToString(stats.maxDD));
            }
};

#include "lotsizeCalculation.mqh"