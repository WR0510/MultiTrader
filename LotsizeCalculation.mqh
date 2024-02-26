double calculateLotSizeSimple(CSymbolHandler *symbol){;//main method for calculating the lotsize
    if(symbol.lotsize.autoIncreaseLotsize){
        if(symbol.lotsize.method == LOTSIZE_METHOD_RISK_BASED){
            double tickSize = SymbolInfoDouble(symbol.general.symbol,SYMBOL_TRADE_TICK_SIZE);
            double tickValue = SymbolInfoDouble(symbol.general.symbol, SYMBOL_TRADE_TICK_VALUE);
            double lotStep = SymbolInfoDouble(symbol.general.symbol, SYMBOL_VOLUME_STEP);
            if(symbol.lotsize.risk == 0){//return the lowest possible lotsize when the lotsizerisk is set to 0
            return lotStep;
            }
            if(tickSize == 0 || tickValue == 0 || lotStep == 0){
                logError(__FUNCTION__,"Error calculating lotsize risk.");
                return 0;
                }
            double riskMoney = AccountInfoDouble(ACCOUNT_EQUITY) * symbol.lotsize.risk/100;
            if(riskMoney == 0){
                logError(__FUNCTION__,"Error calculating lotsize risk Equity=" + string(AccountInfoDouble(ACCOUNT_EQUITY)));
                return 0;
                }
            double moneyLotStep = ((symbol.stoploss.deviationOpenTrade * symbol.general.pointValue) / tickSize) * tickValue * lotStep;
            double lots = MathFloor(riskMoney / moneyLotStep) * lotStep;
            if(lots == 0){
                logTrace(__FUNCTION__,"Calculated lotsize is 0, using lowest possible lotsize:" + string(SymbolInfoDouble(symbol.general.symbol,SYMBOL_VOLUME_MIN)));
                return SymbolInfoDouble(symbol.general.symbol,SYMBOL_VOLUME_MIN);
            }else{
                logTrace(__FUNCTION__,"Calculated lotsize: " + string(lots));
                return lots;
            }
        }else if(symbol.lotsize.method == LOTSIZE_METHOD_EQUITY_BASED){
            double lots = MathFloor((AccountInfoDouble(ACCOUNT_EQUITY) - symbol.lotsize.equityMinimum)/symbol.lotsize.equityStep);
            lots = lots/100;
            if(lots <= 0){
                return symbol.lotsize.lotsize;
            }
            return lots + symbol.lotsize.lotsize;
        }
    }
    logTrace(__FUNCTION__,"Automatic increase lotsize is off, using standard lotsize: " + string(symbol.lotsize.lotsize));
    return symbol.lotsize.lotsize;
    }
double calculateLotSizeOppositeTrade(CSymbolHandler *symbol){;//method for calculating the lotsize when trading opposite to the first position
    return symbol.lotsize.oppositeTradeLotSize;
    }
double calculateLotSizeZoneRecovery(ENUM_POSITION_TYPE posType_in, CSymbolHandler *symbol){;//calculation the lotsize for a zone recovery position
    double lots = 0.0;
    if(posType_in == POSITION_TYPE_BUY){
        //(mSellLots* (mTarget+mZoneSize+mSupplement) /mTarget) - mBuyLots;
        lots = ((symbol.recovery.zoneRecoveryTotalSellLots * (symbol.recovery.zoneRecoveryTarget + symbol.recovery.zoneRecoveryZone)) / symbol.recovery.zoneRecoveryTarget) - symbol.recovery.zoneRecoveryTotalBuyLots;
        lots = MathAbs(MathCeil(lots*100)/100);
        return lots;
    }else if(posType_in == POSITION_TYPE_SELL){
        lots = ((symbol.recovery.zoneRecoveryTotalBuyLots * (symbol.recovery.zoneRecoveryTarget + symbol.recovery.zoneRecoveryZone)) / symbol.recovery.zoneRecoveryTarget) - symbol.recovery.zoneRecoveryTotalSellLots;
        lots = MathAbs(MathCeil(lots*100)/100);
        return lots;
    }
    return lots;
    }