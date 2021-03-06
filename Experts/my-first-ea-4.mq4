//+------------------------------------------------------------------+
//|                                                  My First EA.mq4 |
//|                                     MQL4 tutorial on quivofx.com |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, brigacy"
#property link      ""
#property strict

//--- input parameters
input int Risk                = 2;
input int Day_Volatility_Back = 3;
input int Slippage            = 3;
input int MagicNumber         = 7777;

input bool intraday   		= false;
input int StartingDay  		=  1;  //Starting Day: 0-Sunday,1,2,3,4,5,6
input int StartingHour  	=  9; // Starting Hour
input int StartingMinute  	=  30; // Starting Minutes
input int EndingDay  		=  5;	//Ending Day: 0-Sunday,1,2,3,4,5,6
input int EndingHour  		=  21; // Ending Hour
input int EndingMinute  	=  45; // Ending Minutes

//--- indicator inputs
sinput string        indi = "";                // ------ Indicators -----  
//input int            RSI_Period = 14;          // RSI Period
//input int            RSI_Level  = 30;          // Above RSI Level
//input int            MA_Period  = 20;          // MA Period
input ENUM_TIMEFRAMES   TRADING_Timeframe  = PERIOD_M15;
input int               MA_Period_Fast  = 8;     // MA Period Fast
input int               MA_Period_Slow  = 21;     // MA Period Slow
input int				ATR_Averiaging_Period = 14;
input ENUM_TIMEFRAMES   Filter_1_Timeframe = PERIOD_M30;
input ENUM_TIMEFRAMES   Filter_2_Timeframe = PERIOD_H1;
input ENUM_TIMEFRAMES   Filter_3_Timeframe = PERIOD_D1;
//input ENUM_MA_METHOD MA_Method  = MODE_SMA;    // MA Method

//--- global variables
double MyPoint;
int    MySlippage;
double MyVolatility;
double VolatilityHight;
double VolatilityLow;
string CommentOrder;
int    R1_Multiple; 

//--- debug enable
bool   debug = true;

//--- indicators
double MA, RSI, ATR;
double MACD_1[2],MACD_2[2],fast_MA[3],slow_MA[3];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   MyPoint = MyPoint();
   MySlippage = MySlippage();

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   
   int nbOrders = TotalOpenOrders();
   
	if(IsTradingTime()) {
	
	   if(IsNewBar()) { 
	   
	      // Initialize Indicators
			InitIndicators();
			
			//Update volatilityl
			MyVolatility = MyVolatility();
			
			
			if (nbOrders == 0) {
			  
			  // Check Buy Entry
			  if(BuySignal())
				 OpenBuy();
				 
			  // Check Sell Entry
			  else if(SellSignal())
				 OpenSell();  
		   } else {
			   //check trailing stop and taking profit
				CheckOpenOrder();
		   }
	   }
   }else {
      //close order
		if(nbOrders > 0) {
			CloseOrder();
		}
  }
}

//+------------------------------------------------------------------+
//| Market Logic                                                 |
//+------------------------------------------------------------------+

// Initialize Indicators
void InitIndicators()
{
   // RSI
   //RSI = iRSI(_Symbol,PERIOD_CURRENT,RSI_Period,PRICE_CLOSE,1);
   
   // Moving Average
   //MA = iMA(_Symbol,PERIOD_H1,PERIOD_CURRENT,0,MODE_SMA,PRICE_CLOSE,1);
   
   // ATR
   ATR = iATR(_Symbol,TRADING_Timeframe,ATR_Averiaging_Period,1);
      
   for(int i=0;i<2;i++)
     {
      // MACD (0-MODE_MAIN, 1-MODE_SIGNAL) -- MACD day period
      MACD_1[i]=iMACD(_Symbol,Filter_1_Timeframe,12,26,9,PRICE_CLOSE,i,0);
	  MACD_2[i]=iMACD(_Symbol,Filter_2_Timeframe,12,26,9,PRICE_CLOSE,i,0);

      // Fast MA -- current period
      fast_MA[i+1]=iMA(_Symbol,TRADING_Timeframe,MA_Period_Fast,0,MODE_EMA,PRICE_CLOSE,1+i);

      // Slow MA -- current period
      slow_MA[i+1]=iMA(_Symbol,TRADING_Timeframe,MA_Period_Slow,0,MODE_LWMA,PRICE_CLOSE,1+i);
     }
   
}

// Buy Logic
bool BuySignal()
{
   CommentOrder = "";
   
   // MACD zero line filter
   if(!(MACD_1[0] > 0 && MACD_1[1] > 0))return(false);
   if(!(MACD_2[0] > 0 && MACD_2[1] > 0))return(false);

	// MACD trend filter ( ! MAIN > Signal)
   if(!(MACD_1[0] > MACD_1[1]))return(false);
   if(!(MACD_2[0] > MACD_2[1]))return(false);
   
	// Check Signal
    if(BuyCrossMA()) {
      CommentOrder = StringConcatenate (CommentOrder, ";CrossMA");
      return(true);
    }
   
   //TODO: Ajouter RSI ???
   //if(RSI <= RSI_Level && Low[1] >= MA)
	//return(true);

   return(false);
}


//Buy Signal
bool BuyCrossMA()
{
	// Check Signal
   if(fast_MA[1] > slow_MA[1] && fast_MA[2] < slow_MA[2]) {
      return(true);
   }
   
   return false;

}
//Close a Buy Order open with Cross MA
bool CloseBuyCrossMA()
{
	if(fast_MA[1] < slow_MA[1] )
	   return true;
	   	 
	return false;
}

// Sell Logic
bool SellSignal()
{
   CommentOrder = "";

   // MACD zero line filter
   if(!(MACD_1[0] < 0 && MACD_1[1] < 0))return(false);
   if(!(MACD_2[0] < 0 && MACD_2[1] < 0))return(false);

	// MACD trend filter
   if(!(MACD_1[0] < MACD_1[1]))return(false);
   if(!(MACD_2[0] < MACD_2[1]))return(false);

	// Check Signal
   if(SellCrossMA()) {
      CommentOrder = StringConcatenate (CommentOrder, ";CrossMA");
      return(true);
   }
   
   //TODO: Ajouter RSI ???
   //if(RSI >= 100-RSI_Level && High[1] <= MA)
   //   return(true);
   
   return(false);
}

//Sell Signal
bool SellCrossMA() {
     // Check Signal
   if(fast_MA[1] < slow_MA[1] && fast_MA[2] > slow_MA[2]) {
      return(true);
   }
   
   return false;

}

//Close a Sell Order open with Cross MA
bool CloseSellCrossMA()
{	
	if(fast_MA[1] > slow_MA[1])
		return true;
		
	return false;
}


//+------------------------------------------------------------------+
//| ORDER OPERATION                                                 |
//+------------------------------------------------------------------+ 
 
// Open Buy Order
void OpenBuy()
{
   double lotSize;
   
   lotSize = MyLotSize(); 
   if(lotSize == 0) return ;
   
   CommentOrder = StringConcatenate (MyVolatility, CommentOrder);
   R1_Multiple = 0;
   int ticket = OrderSend(_Symbol,OP_BUY,lotSize,Ask,MySlippage,0,0,CommentOrder,MagicNumber, 0, Green);
   
   //permet de selectionner l'ordre créé
   int totalOrder = TotalOpenOrders();
      
      if(ticket<0)
         PrintError("OrderSend");
      else {
         bool res= OrderSelect(ticket,SELECT_BY_TICKET);
         UpdateOriginOrder(MyVolatility);
      }
}


// Open Sell Order
void OpenSell()
{
   //Open Sell Order
   double lotSize = MyLotSize();
   if(lotSize == 0) return ;
   
   CommentOrder = StringConcatenate (MyVolatility, CommentOrder);
   R1_Multiple = 0;
   int ticket = OrderSend(_Symbol,OP_SELL,lotSize,Bid,MySlippage,0,0,CommentOrder,MagicNumber, 0, Red);
   
      
      if(ticket<0)
         PrintError("OrderSend");
      else {
         bool res= OrderSelect(ticket,SELECT_BY_TICKET);
         UpdateOriginOrder(MyVolatility);
      }
}

//Update the trailing stop and the take profit if there where no stoploss yet define
/*
void UpdateOrder() {
	
	bool res = false;
	double stopLoss, takeProfit, volatility;
	
	volatility = MyVolatility();
	
	//update BUY
	if(OrderType() == OP_BUY ) {
		stopLoss = MathMin( (Ask - (volatility/2)), VolatilityLow);
		if(OrderStopLoss() > 0) {
			takeProfit = OrderTakeProfit();
		} else {
			takeProfit = MathMax ((Ask + (volatility)) , VolatilityHight);
		}
		
		res = OrderModify(OrderTicket(),OrderOpenPrice(),stopLoss, takeProfit,0, Blue);
		
	//update SELL
	} else {
		stopLoss = MathMax( (Bid + (volatility/2)), VolatilityHight);
		if(OrderStopLoss() > 0) {
			takeProfit = OrderTakeProfit();
		} else {
			takeProfit = MathMax ( (Bid - volatility) , VolatilityLow);
		}

		res = OrderModify(OrderTicket(),OrderOpenPrice(),stopLoss, takeProfit,0, Purple);
	}
	
	if(!res) PrintError("OrderModify");
		 
}
*/

//Update the origin order with stoploss and the take profit
void UpdateOriginOrder(double volatilityOrder) {
	
	bool res = true;
	double stopLoss, takeProfit;

	//update BUY
	if(OrderType() == OP_BUY ) {
		stopLoss = NormalizeDouble( OrderOpenPrice() - (volatilityOrder/2), _Digits);
		takeProfit = NormalizeDouble(OrderOpenPrice() + volatilityOrder, _Digits);
		
		res = OrderModify(OrderTicket(), OrderOpenPrice(),stopLoss, takeProfit,0, Blue);
	}
		
	//update SELL
	else {
		stopLoss = NormalizeDouble(OrderOpenPrice() + (volatilityOrder/2), _Digits);
		takeProfit = NormalizeDouble(OrderOpenPrice() - volatilityOrder, Digits);
		
		res = OrderModify(OrderTicket(),OrderOpenPrice(),stopLoss, takeProfit,0, Purple);
	}
	
	if(!res) {
		Print("stopLoss = " , stopLoss);
		Print("takeProfit = " , takeProfit );
		Print ("OrderOpenPrice() - ", OrderOpenPrice() ); 
		Print ("Ask - ", Ask ); 
		Print ("Bid - ", Bid ); 
		Print("volatilityOrder", volatilityOrder ); 
		Print("MyVolatility", MyVolatility ); 
		Print("AccountStopoutLevel()", AccountStopoutLevel() );
		Print("_Digits= ", _Digits);
		PrintError("UpdateOriginOrder");
	}
		 
}


// Close Sell Order
void CloseOrder()
{
	bool res = true;
	
	if(OrderType() == OP_BUY ) {
		res = OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(), MODE_BID), MySlippage, Orange);
	} else {
		res = OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(), MODE_ASK), MySlippage, Orange);
	}
	
	if(!res)
      PrintError("OrderClose");
}

// Returns the number of total open orders for this Symbol and MagicNumber
int TotalOpenOrders()
{
   int total_orders = 0;
   
   for(int order = 0; order < OrdersTotal(); order++) 
   {
      if(OrderSelect(order,SELECT_BY_POS,MODE_TRADES)==false) break;
      
      if(OrderMagicNumber() == MagicNumber && OrderSymbol() == _Symbol)
         {
            total_orders++;
         }
   }
   
   return(total_orders);
}

//Checks and update the open Order
void CheckOpenOrder()
{   
	string lstPattern;
	ushort u_sep;
	string pattern[];
	int nbPattern;
	bool toClose = false;
	string message = "";
		 
	//Only 1 oder can be open, select the order.
    if(OrderMagicNumber() == MagicNumber && OrderSymbol() == _Symbol)
    {
		lstPattern = OrderComment();
		u_sep=StringGetCharacter(";",0);
		nbPattern = StringSplit(lstPattern,u_sep,pattern);
		
		if( (lstPattern == "") || (!nbPattern > 1) ) {
			 PrintError("Order close without Pattern!!");
			 CloseOrder();
		}
        
         //check buy signal still valid
		if(OrderType() == OP_BUY )
		{
			message = CheckOpenOrderBuy(nbPattern , pattern);  
		}
		
		//check sell signal still valid
		if(OrderType() == OP_SELL )
		{
			message = CheckOpenOrderSell(nbPattern , pattern);	
		}
		
		if (StringLen(message) > 0) {
			PrintNotification(message); 
			CloseOrder();
			return; 
		}
		
		double volatilityOrder = (double) pattern[0]; 
		//Update if Stop loss not set yet;
        if(OrderStopLoss() == 0) UpdateOriginOrder(volatilityOrder);
		else UpdateOrder(volatilityOrder);
    }
}

//Check to close buy order
string CheckOpenOrderBuy(int nbPattern, string& pattern[]) {
	string message = "";
	for(int i=1 ; i<nbPattern ; i++) {
		if( (StringCompare(pattern[i],"CrossMA") == 0) && CloseBuyCrossMA() ) {
			message = StringConcatenate(message,"Close Cross MA;");
		}
	}
	return message;
}

//Check to close sell order
string CheckOpenOrderSell(int nbPattern, string& pattern[]) {
	string message = "";
	for(int i=1 ; i<nbPattern ; i++) {
		if( (StringCompare(pattern[i],"CrossMA") == 0) && CloseSellCrossMA() ) {
				message = StringConcatenate(message,"Close Cross MA;");
		}
	}
	return message;
}

// Update trailing stop and take profit if the R1 multiple is passed
void UpdateOrder(double volatilityOrder) {
	bool res = true;
	int r_m;
	double pipsWon, stopLoss, takeProfit;

	if(OrderType() == OP_BUY )
	{
		pipsWon = Ask - OrderOpenPrice();
		
		r_m = (int) (pipsWon/(volatilityOrder/2));
		
		if(r_m > R1_Multiple) {
			
			stopLoss = NormalizeDouble(Ask - (volatilityOrder/2) , _Digits);
			takeProfit = NormalizeDouble(Ask + volatilityOrder , _Digits);
			
			res = OrderModify(OrderTicket(),OrderOpenPrice(),stopLoss, takeProfit,0, Blue);
			
			//update R1 Multiple
			R1_Multiple = r_m;
		}
	}
	
	//check sell signal still valid
	if(OrderType() == OP_SELL )
	{
		pipsWon = OrderOpenPrice() - Bid;
		r_m = (int) (pipsWon / (volatilityOrder/2));
		if(r_m > R1_Multiple) {
			
			stopLoss = NormalizeDouble( Bid + (volatilityOrder/2) ,_Digits);
			takeProfit = NormalizeDouble( (Bid - volatilityOrder ) , _Digits);
			
			res = OrderModify(OrderTicket(),OrderOpenPrice(),stopLoss, takeProfit,0, Purple);
			//update R1 Multiple
			R1_Multiple = r_m;
		}
	}
	
	if(!res) {
		Print("r_m=",r_m);
		Print("stopLoss = " , stopLoss);
		Print("takeProfit = " , takeProfit );
		Print ("OrderOpenPrice() - ", OrderOpenPrice() ); 
		Print ("Ask = ", Ask ); 
		Print ("Bid = ", Bid ); 
		Print("volatilityOrder", volatilityOrder ); 
		Print("MyVolatility", MyVolatility ); 
		Print("MyPoint= ", MyPoint);
		PrintError("UpdateOrder");
	}
}

//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+

   
// Get My Points   
double MyPoint()
{
   double CalcPoint = 0;
   
   if(_Digits == 2 || _Digits == 3) CalcPoint = 0.01;
   else if(_Digits == 4 || _Digits == 5) CalcPoint = 0.0001;
   else if(_Digits == 1) CalcPoint = 1;
   
   return(CalcPoint);
}


// Get My Slippage
int MySlippage()
{
   int CalcSlippage = 0;
   
   if(_Digits == 2 || _Digits == 4) CalcSlippage = Slippage;
   else if(_Digits == 3 || _Digits == 5) CalcSlippage = Slippage * 10;
   
   return(CalcSlippage);
}

   
// Check if there is a new bar
bool IsNewBar()   
{        
   static datetime LastBarTime=0;
   datetime ThisBarTime = Time[0];
      
   if (ThisBarTime == LastBarTime)
   {
      return(false);
   }
   else
   {
      LastBarTime = ThisBarTime;
      return(true);
   }
}   

   
//Returns true if the current time is in the valid windows time ( eg: 9h30 - 22h30)
bool IsTradingTime()
{
	int day, hour, minute;
	
	hour = Hour();
	minute = Minute();
	
	if(!intraday) {
		day = DayOfWeek();
		//if weekend => return false
		if(day > 1 && day < 5)
			return true;
		if( day == 1 && ((hour > StartingHour) ||  (hour >= StartingHour && minute >= StartingMinute)) )
			return true;
		if( day == 5 && ((hour < EndingHour) ||  (hour <= EndingHour && minute <= EndingMinute) ) )
			return true;
		
	} else {	
		if( ((hour > StartingHour) ||  (hour >= StartingHour && minute >= StartingMinute) )
			&& ((hour < EndingHour) ||  (hour <= EndingHour && minute <= EndingMinute) ) )
			return true;
	}		
	return false;
}



//Update the volatility based the last days
double MyVolatility()
{
   
	double volatility;
	double minStop = AccountStopoutLevel() * MyPoint;
	/*
	int highestBar, lowestBar;
	
	highestBar = iHighest(NULL,PERIOD_D1,MODE_HIGH,Day_Volatility_Back,0);
	lowestBar = iLowest(NULL,PERIOD_D1,MODE_LOW,Day_Volatility_Back,0);
	
	VolatilityHight = iHigh(NULL, PERIOD_D1, highestBar);
	VolatilityLow = iLow(NULL, PERIOD_D1, lowestBar);
	
	volatility = NormalizeDouble(VolatilityHight - VolatilityLow, _Digits);
	*/

	if (ATR > minStop) volatility = ATR ;
	else volatility = minStop;
	
	return NormalizeDouble(volatility, _Digits);
}


//Calculate my Lot size
double MyLotSize()
{
   double oneLotMargin, freeMargin, lotMM, lotStep, committed, volatility;
   long leverage;
   
  oneLotMargin = MarketInfo(Symbol(),MODE_MARGINREQUIRED);
  freeMargin = AccountFreeMargin();
  lotStep = MarketInfo(Symbol(),MODE_LOTSTEP);
  leverage = AccountLeverage();
  
  lotMM = freeMargin/oneLotMargin * Risk/100;
  lotMM = NormalizeDouble(lotMM/lotStep,0) * lotStep;
  
  
  committed = lotMM * oneLotMargin;
  //volatility = MyVolatility/2 * oneLotMargin * leverage;
   volatility = MyVolatility/2 * lotMM * leverage;
      
   //the money committed must be higher than Volatility committed
   if(committed <  volatility  ) lotMM = 0;
   
   if(debug) {
	  Print("OneLotMargin :", oneLotMargin);
	  Print("FreeMargin :", freeMargin);
	  Print("lotMM :", lotMM);
	  Print("LotStep :", lotStep);
	  Print("AccountStopoutLevel :", AccountStopoutLevel());
	  Print("leverage :", leverage);
	  Print("committed :", committed);
	  Print("volatility :", volatility);
	  Print("MyVolatility:", MyVolatility);
	  Print("ATR= ", ATR);
	  Print("MyPoint= ", MyPoint);
  }
  
   return lotMM;
}

//Print Error and Send notification
void PrintError (string fct) 
{
   string message;
   
		 message = StringConcatenate("Error in ", fct, ". Error code=#" , GetLastError());
		 Print(message);
		 if(!SendNotification(message)) 
		   Print("Error in SendNotification. Error code=#" ,GetLastError());   
      else Print(fct," done successfully.");
}

//Print Notification and send notification
void PrintNotification (string message) {
	Print(message);
	if(!SendNotification(message)) 
		Print("Error in SendNotification. Error code=#" ,GetLastError());
}