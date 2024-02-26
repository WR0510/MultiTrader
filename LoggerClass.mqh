//class for printing a log level
//Metatrader keeps a log file in the Data Folder(Ctrl+Shift+D) --> Logs
class CLoggerClass{
    private:
        string formatFunctionName(string str,int lenght){
            int lenghtStr = StringLen(str);
            if(lenghtStr > lenght){
                string strSubstr = StringSubstr(str,lenghtStr-lenght,lenght);
                return strSubstr;
            }else{
                for(int i=0;i<lenght-lenghtStr;i++){
                    str += " ";
                }
                return str;
            }
            return "invalid string operation";
        }
    public:
        CLoggerClass(void){};
        ~CLoggerClass(void){};
        void logTrace(string func,int funcLen,string msg){
            func = formatFunctionName(func,funcLen);
            Print(func + " |TRACE| " + msg);
            }
        void logDebug(string func,int funcLen,string msg){
            func = formatFunctionName(func,funcLen);
            Print(func + " |DEBUG| " + msg);
            }
        void logInfo(string func,int funcLen,string msg){
            func = formatFunctionName(func,funcLen);
            Print(func + " |INFO | " + msg);
            }
        void logWarn(string func,int funcLen,string msg){
            func = formatFunctionName(func,funcLen);
            Print(func + " |WARN | " + msg);
            }
        void logError(string func,int funcLen,string msg){
            func = formatFunctionName(func,funcLen);
            Print(func + " |ERROR| " + msg);
            }
        void logFatal(string func,int funcLen,string msg){
            func = formatFunctionName(func,funcLen);
            Print(func + " |FATAL| " + msg);
            }
        void logEntry(string func,int funcLen){
            func = formatFunctionName(func,funcLen);
            Print(func + " |TRACE| Function entry");
            }
        void logEntry(string func,int funcLen,string msg){
            func = formatFunctionName(func,funcLen);
            Print(func + " |TRACE| Function entry " + msg);
            }
        void logExit(string func,int funcLen){
            func = formatFunctionName(func,funcLen);
            Print(func + " |TRACE| Function exit");
            }
        void logExit(string func,int funcLen,string msg){
            func = formatFunctionName(func,funcLen);
            Print(func + " |TRACE| Function exit " + msg);
            }
    };