#include <Canvas\Canvas.mqh>//Parent class
#include <Tools\HistoryPositionInfo.mqh>
CHistoryPositionInfo historyPositionInfo;

class CeaCanvasInfo : public CCanvas{
    private:
        struct status_struct{
            bool tradeAllowed;
            string comment;
        };
        bool EAstatus;
        string programName;
        color background;
        string lines[];
        int xPosLine;
        int yPosLine;
        int yPosLineDistance;
        int m_accountCurrencyDigits;

        status_struct status;//declare struct

        //Private methods
        void addLine(string text);
        void clearLines();
    public:
                    CeaCanvasInfo(void);
                    ~CeaCanvasInfo(void);
        void loadCanvas();
        void destroyCanvas();
        void updateCanvas();
        void setBackgroundColor();
        //void updateCanvasTitle();
        double todayProfit();
    };
    void CeaCanvasInfo :: ~CeaCanvasInfo(){}//destructor
    void CeaCanvasInfo :: CeaCanvasInfo (){//constructor
        programName = MQLInfoString(MQL_PROGRAM_NAME);
        xPosLine = 5;
        yPosLine = 0;
        yPosLineDistance = 20;
        m_accountCurrencyDigits = accountCurrencyDigits;
        //background = clrKhaki;
        background = clrLime;
        }
    void CeaCanvasInfo :: addLine(string text){
        int size = ArraySize(lines);
        ArrayResize(lines,size+1);
        lines[size] = text;
        }
    void CeaCanvasInfo :: clearLines(){
        ArrayResize(lines,0);
        }
    void CeaCanvasInfo :: destroyCanvas(){
        Destroy();
        }
    void CeaCanvasInfo :: setBackgroundColor(){
        status.tradeAllowed = TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
            if(status.tradeAllowed){
                background = clrLime;
                status.comment = "EA status: Running";
            }else{
                background = clrRed;
                status.comment = "EA status: Disabled";
            }
        }
    void CeaCanvasInfo :: updateCanvas(){
        //destroyCanvas();
        setBackgroundColor();
        clearLines();
        yPosLine = 0;

        //Add all text lines first and then create the bitmap in order to make it the correct size for the amount of lines
        addLine("Positions: " + string(PositionsTotal()));
        addLine("Orders: " + string(OrdersTotal()));
        addLine("Profit: " + accountCurrency + " "  + DoubleToString(AccountInfoDouble(ACCOUNT_PROFIT),m_accountCurrencyDigits));
        addLine("Account balance: " + accountCurrency + " " + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),m_accountCurrencyDigits));
        addLine("Today's profit: " + accountCurrency + " " + DoubleToString(todaysProfit(),m_accountCurrencyDigits));

        int height = (ArraySize(lines) * yPosLineDistance) + 10;
        CreateBitmapLabel("canvas", 15, 20, 320, height, COLOR_FORMAT_ARGB_NORMALIZE);
        Erase(ColorToARGB(background,175));
        
        //Output all lines to the canvas
        FontSet("Calibri", -150);
        for(int i = 0;i<ArraySize(lines);i++){
            TextOut(xPosLine,yPosLine,lines[i],ColorToARGB(clrBlue, 255));
            yPosLine += yPosLineDistance;
        }
        Update(true);
        }
    