//general variables
string accountCurrency;
ulong totalBarsTrade;
ulong totalBarsUpdatePositions;
int totalOnTimer;
int logFuncLenght = 30;//String lenght for the function name in the logfile
bool debug = false;
bool playSoundWin = false;
bool playSoundLoss = false;
string folderExport = "stats";

//custom enums used in the EA
enum ENUM_SYMBOLS{
    EURUSD,
    GBPUSD,
    USDCHF,
    USDJPY,
    USDCAD,
    EURGBP,
    AUDNZD,
    SYMBOL1,
    SYMBOL2
    };
enum ENUM_INDICATOR_TYPES{
    BOLLINGERBANDS,
    RSI,
    ENVELOPES,
    MA,
    STOCHASTIC,
    HEIKENASHI
    };
enum ENUM_TRADINGMODE{
    TRADINGMODE_SEARCHING_ENTRY,
    TRADINGMODE_FIRST_POSITION_OPENED,
    TRADINGMODE_MULTIPLE_POSITIONS_OPEN,
    TRADINGMODE_RECOVERY,
    TRADINGMODE_RECOVERY_EXIT,
    TRADINGMODE_CLOSING_POSITIONS
    };
enum ENUM_POSITION_CALCULATION_TYPE{
    CALCULATION_TYPE_FIRST_POSITION,
    CALCULATION_TYPE_MULTIPLE_ADD_NEW,
    CALCULATION_TYPE_OPPOSITE_TRADE,
    };
enum ENUM_ENVELOPES_SIGNAL_MODE{
    ENVELOPES_MODE_PULLBACK,
    ENVELOPES_MODE_BREAKOUT,
    ENVELOPES_MODE_RE_ENTRY,
    ENVELOPES_MODE_BREAKOUT_STOCHASTIC
    };
enum ENUM_ENVELOPES_STEP{
    ENVELOPES_STEP_IN_BOUNDS,
    ENVELOPES_STEP_BREAKOUT_HIGH,
    ENVELOPES_STEP_BREAKOUT_LOW,
    ENVELOPES_STEP_WAIT_RE_ENTRY_HIGH,
    ENVELOPES_STEP_WAIT_RE_ENTRY_LOW,
    ENVELOPES_STEP_WAIT_STOCHASTIC_HIGH,
    ENVELOPES_STEP_WAIT_STOCHASTIC_LOW,
    };
enum ENUM_RECOVERY_MODE{
    RECOVERY_MODE_DOUBLE = 0,
    RECOVERY_MODE_ADD = 1,
    RECOVERY_MODE_ZONE_RECOVERY = 2,
    RECOVERY_MODE_BASE_LOTS = 3
    };
enum ENUM_GRID_EXIT{
    GRID_EXIT_END_TIMEFRAME = 1,
    GRID_EXIT_TRAILINGSTOP = 2,
    };
enum ENUM_SOUND{
    SOUND_OPEN_POSITION = 0
    };
enum ENUM_LOTSIZE_METHOD{
    LOTSIZE_METHOD_RISK_BASED,
    LOTSIZE_METHOD_EQUITY_BASED
    };

//structs used in the EA symbol handler
struct general_variables{
    ENUM_TRADINGMODE tradingMode;
    string symbol;
    ENUM_TIMEFRAMES period;
    double pointValue;
    int maxPositions;
    int maxSpread;
    };
struct lotsize_variables{
    double lotsize;
    double oppositeTradeLotSize;
    ENUM_LOTSIZE_METHOD method;
    int equityStep;
    int equityMinimum;
    double risk;
    bool autoIncreaseLotsize;
    };
struct stoploss_variables{
    bool trailingstopOnOff;
    int deviation;
    int deviationMinimum;
    int deviationOpenTrade;
    int deviationProfitTreshold;
    };
struct takeprofit_variables{
    int deviation;
    int commission;
    };
struct recovery_variables{
    bool recover;
    ENUM_RECOVERY_MODE mode;
    int maxSteps;
    int deviation;
    double stepFactor;
    double stoplossBuy;
    double stoplossSell;
    ulong firstPositionTicket;
    double firstPositionPrice;
    ENUM_POSITION_TYPE firstPositionType;
    ENUM_GRID_EXIT exitMode;
    int trailingDeviation;
    int zoneRecoveryTarget;
    int zoneRecoveryZone;
    int zoneRecoveryCommission;
    ENUM_POSITION_TYPE zoneRecoveryLatestPositionType;
    double zoneRecoveryTotalBuyLots;
    double zoneRecoveryTotalSellLots;
    double zoneRecoveryCutOffPercentage;
    };
struct chart_variables{
    bool zoneLinesActive;
    };
struct statistics_variables{
    double maxDD;
    };