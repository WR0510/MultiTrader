TODO:
-sometimes the bar close price seems to be wrong, why? iClose to test(iClose makes the same mistake as rates, testing getting the bid price and use it as the close price)

v1.39
-Refactoring directory structure to allow for multiple projects with the same MetaTrader terminal

v1.38
-changed: lotsize calculation improve automatically changing the lotsize

v1.37
-add setting to use the cutoff value or not

v1.36
-cutoff value for closing all positions on high drawdown
-adjusted input parameters, grouped per symbol

v1.35
-added martingale strategy always the same lotsize
-improve multiple positions trading

v1.34
-added the heiken ashi smoothed indicator  
-added the option to use indicators for closing positions in the handleSignals function

v1.33
-adjusted, improve indicators debugging
-added breakout mode to envelopes indicator
-use the bid price as the close price

v1.32
-added debug information when opening a position

v1.31
-updated config comments
-added input for strategy description(only way to know which set is loaded)

v1.30
-changed, do not export statistics when in tester mode
-added, 2nd dynamic symbol

v1.29
-changed, added logging before opening a position
-changed, inputs order

v1.28
-changed, removed the canvas title bar and use the background color for the info canvas
-export daily profit to the common files folder

v1.27
-log and show an alert in the alert box when a symbol is requested which is not available in the market watch window
-refactoring the lotsize calculation into a seperate library
-refactoring openposition function
-set the correct currency symbol in the canvas by getting in from account info automatically
-add printing statistics when shutting down the EA: maximum drawdown

v1.26
-fix stopploss calculation. The problem was the pointvalue was not set correctly in the symbol constructor.
-added check on lotsize calculation when trading opposite direction, set lotsize to standard when 0.

v1.25
-changed stoploss calculation for positions different type from the first position
-changed make inputs for the symbol name. This is to allow using differnt names for the same symbol. For example when the symbol ends with a "." .
-added settings a seperate lot size for positions different type from the first position
-added trace function entry on initialization

v1.24
-changed, set stop loss outside the recoverable zone when opening a position of the other type than the first position. This is to prevent stop loss getting hit when a trade could be recovered.
-comment out unused inputs

v1.23
-added update rates in the process bar complete for update

v1.22
-changed, use the timeframe from the settings instead of the chart
-changed, moved the symbol activation settings to the top of the parameters list
-changed, refactoring the stop loss calculations

v1.21
-Add GRID_EXIT_TRAILINGSTOP mode which sets a trailing stop after recovering a losing trade

v1.20
-Fix setting first position when multiple trades are open

v1.19
-Add functionality to open trades in the opposite direction while recovering form a losing trade. If the opposite trade becomes the losing trade after recovering the first losing trade the opposite trade becomes the trade to be recovered. Not working with zone recovery.
-Count positions per type on init before setting trading mode
-Adjust pendingorders check and set the first position when a trade in the opposite direction is open
-Changed setting price for the first position 
-Changed check trade recovery, profit calculation

v1.18
-zone recovery, check for maximum spread
-zone recovery: close all positions when equity to low
-check soundOnOff
-create dynamic symbol settings, not fixed symbols
-refactoring the tradingutilities into tradeextended
-add steps for partial position closing, unfinished

v1.17
-zone recovery improvements
-optimized for EURUSD and USDCAD

v1.16
-change version in the EA properties
-added zone recovery
-optimized zone recovery for EURUSD and USDJPY

v1.15
-Added maximum amount of symbols at the same time

v1.14
-Optimezed for pair USDCHF
-Added pair AUDNZD
-Added play sound when opening an new position

v1.13
-optimized for pair EURGBP: Envelopes + MA
-optimized for pair GBPUSD: Bollinger bands
-changed debug mode selection input, debug always off when testing
-making a sound when closing a position
-canvas adjusted numbers display on info canvas
-changed order price deviation calculation
-optimization after adjustment in calculation: EURUSD, USDJPY, GBPUSD, EURGBP
-fix account balance on canvas

v1.12
-change order placing procedure to apply a minimum deviation to the stoploss
-auto adjust stoploss for open positions when the minimum deviation is not met to continue the trade recovery
-refactoring includes
-added isDebug check for logging
-updating default settings
-added grid deviation factor, different distance from the first position price for the orders.
-added TradeExtended class, refactored some methods from the symbolHandler to this new class
-set debug to true when debugging
-added trailing stop after recovering a losing position
-optimized for pair USDJPY: Envelopes + moving average
-optimized for pair EURUSD: Envelopes + RSI

v1.11
-change default input values(USDJPY less risk)

v1.10
-refactoring the deleteOrder function in order to prevent deleting pending market orders.
-add separate function to check if parameters need to be resetted after deleting orders.
-refactoring canvas today's profit

v1.09
-search for first postion when restarting the ea, this is required for placing grid orders
-added account balance and today's profit to canvas
-bugfix in stoploss calculation
-update default inputs
-convert check per tick to check per second(faster)
-removed unused calculateStopLossBuy

v1.08
-added logging sl tp check

v1.07
-changed delete orders functions, keep looping all orders even when selecting an order failed
-added logging after calcutating the price for an order

v1.06
-fix bug in delete orders function
-refactoring canvas class, seperate title and info class

v1.05
-input canvas on or off(off required for backtesting)
-adjusted canvas class improved
-added check pending orders every tick, pending orders will be closed when there is no position open for the symbol

v1.04
-adjusting default configuration for specific symbols
-fix adjusted tradeTransactionEvent for resetting trading mode
-fix Envelopes indicator check under lower values bound
-updated default settings EURUSD,GBPUSD
-added canvas with total amount of positions and orders

v1.03
-refactoring the placing orders code
-storing the symbol_point in every symbol object because this is not the same for all symbols and is required for placing orders
-refactoring changing tradingmode
-improved logging

v1.02
-add output to logfile
-add symbol USDCAD,EURGBP
-changed logging system because importing ex5-files is not allowed for market EA's. Created class for logging. Using the Print statement writes to a file as well. Included log levels for information

v1.01
-improve debugging info
-fix memory leaks
-adding logging
-resize symbolHandler array on deInit, otherwise the size will increase when changing timeframe on the chart

V1.00
-Initial work on the multi currency trader. The goal is to use a class for every symbol.
-Check price and stoploss and takeprofit before placing an order
-available symbols EURUSD,GBPUSD,USDCHF,USDJPY























