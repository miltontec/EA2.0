//+------------------------------------------------------------------+
//|                                           TradingStrategy.mq5    |
//|                              NEURAL CONSENSUS TRADING SYSTEM v2.0|
//|                        6-PHASE ADAPTIVE TRADING ARCHITECTURE     |
//+------------------------------------------------------------------+
#property copyright "Trading Strategy v2.0 - Neural Consensus System"
#property link      "https://github.com/your-repo"
#property version   "2.00"
#property description "Complete 6-phase trading cycle with ML memory core"
#property strict

//+------------------------------------------------------------------+
//| INCLUDES - The Brain Modules                                     |
//+------------------------------------------------------------------+
#include <SupportResistance.mqh>
#include <VotingStatistics.mqh>
#include <MetaLearningSystem.mqh>
#include <OrderExecution.mqh>
#include <AccumulationZones.mqh>
#include <PatternMemory.mqh>
#include <BreakoutDetector_fixed.mqh>
#include <InstitutionalPlanFinder_fixed.mqh>
#include <RegimeDetectionSystem.mqh>
#include <EpisodicMemorySystem.mqh>

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - User Configuration                           |
//+------------------------------------------------------------------+
input group "=== RISK MANAGEMENT ==="
input double   InpRiskPercent = 1.0;              // Risk per trade (%)
input double   InpMaxDailyRisk = 3.0;             // Max daily risk (%)
input int      InpMaxOrdersPerCycle = 3;          // Max orders per cycle

input group "=== TIMEFRAME CONFIGURATION ==="
input ENUM_TIMEFRAMES InpTF_H4 = PERIOD_H4;       // Higher timeframe
input ENUM_TIMEFRAMES InpTF_H1 = PERIOD_H1;       // Medium timeframe
input ENUM_TIMEFRAMES InpTF_M15 = PERIOD_M15;     // Lower timeframe

input group "=== CONSENSUS SETTINGS ==="
input double   InpMinConsensusStrength = 0.65;    // Min consensus strength (0-1)
input double   InpMinTotalConviction = 0.70;      // Min total conviction (0-1)
input bool     InpRequireEpisodicConfirm = true;  // Require episodic memory confirmation

input group "=== VISUAL & DEBUG ==="
input bool     InpShowVisuals = true;             // Show visual elements
input bool     InpDebugMode = false;              // Enable debug logging

//+------------------------------------------------------------------+
//| ENUMERATIONS - State Machine Definition                         |
//+------------------------------------------------------------------+
enum ENUM_CYCLE_PHASE
{
   PHASE_0_WAITING_SR,        // Phase 0: Waiting for SR touch
   PHASE_1_SR_TOUCHED,        // Phase 1: SR level touched
   PHASE_2_ACCUMULATION,      // Phase 2: Checking accumulation
   PHASE_3_NEURAL_VOTE,       // Phase 3: Neural consensus voting
   PHASE_4_EXECUTING,         // Phase 4: Order execution
   PHASE_5_MONITORING,        // Phase 5: Position monitoring + trailing
   PHASE_6_LEARNING,          // Phase 6: Learning from results
   PHASE_COMPLETE             // Cycle complete, ready to restart
};

//+------------------------------------------------------------------+
//| STRUCTURES - Cycle Data Tracking                                |
//+------------------------------------------------------------------+
struct CycleContext
{
   // Cycle identification
   ulong          episodeId;              // Unique episode ID
   ulong          consensusId;            // Consensus ID from voting
   ENUM_CYCLE_PHASE currentPhase;         // Current phase of cycle
   datetime       cycleStartTime;         // When cycle started

   // Phase 1: SR Touch data
   TouchContext   srTouch;                // SR touch information
   double         touchPrice;             // Price at touch
   ENUM_SR_TYPE   touchType;              // Support or Resistance

   // Phase 2: Accumulation data
   AccumulationContext accumulation;      // Accumulation zone info
   bool           accumValid;             // Accumulation validated
   int            accumBars;              // Bars in accumulation

   // Phase 3: Voting data
   NeuralConsensusResult neuralResult;    // Neural voting result
   ConsensusMemory consensusMemory;       // Consensus memory record
   ENUM_VOTE_DIRECTION finalDirection;    // Final voted direction
   double         consensusStrength;      // Strength of consensus
   string         leadingAgent;           // Agent with highest confidence

   // Phase 4: Execution data
   int            ordersExecuted;         // Number of orders executed
   ENUM_TRADE_DIRECTION tradeDirection;   // Buy or Sell

   // Phase 5: Monitoring data
   bool           trailingActive;         // Trailing stop active
   double         maxProfitReached;       // Max profit during cycle
   double         maxDrawdownReached;     // Max drawdown during cycle

   // Phase 6: Learning data
   bool           cycleSuccessful;        // Was cycle profitable
   double         totalProfit;            // Total profit/loss in points
   int            cycleDurationBars;      // Duration in bars
};

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES - System Components                            |
//+------------------------------------------------------------------+
// Core modules
CSupportResistance*      g_SR = NULL;
VotingStatistics*        g_Voting = NULL;
CMetaLearningSystem*     g_MetaLearning = NULL;
OrderExecution*          g_OrderExec = NULL;
CAccumulationZones*      g_Accumulation = NULL;
CPatternMemory*          g_PatternMemory = NULL;
CBreakoutDetector*       g_BreakoutDetector = NULL;
CInstitutionalPlanFinder* g_InstitutionalFinder = NULL;
RegimeDetectionSystem*   g_RegimeDetector = NULL;
EpisodicMemorySystem*    g_EpisodicMemory = NULL;

// Cycle management
CycleContext g_Cycle;
bool g_SystemInitialized = false;
bool g_TradingEnabled = true;
datetime g_LastBarTime = 0;

// Performance tracking
double g_DailyProfit = 0.0;
datetime g_LastDailyReset = 0;
int g_TotalCyclesCompleted = 0;
int g_SuccessfulCycles = 0;

//+------------------------------------------------------------------+
//| EXPERT INITIALIZATION FUNCTION                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("╔══════════════════════════════════════════════════════════════╗");
   Print("║  TRADING STRATEGY v2.0 - NEURAL CONSENSUS SYSTEM             ║");
   Print("║  6-Phase Adaptive Architecture with ML Memory Core           ║");
   Print("╚══════════════════════════════════════════════════════════════╝");

   // Initialize cycle context
   ZeroMemory(g_Cycle);
   g_Cycle.currentPhase = PHASE_0_WAITING_SR;
   g_Cycle.cycleStartTime = TimeCurrent();

   // Create and initialize modules
   if(!InitializeModules())
   {
      Print("❌ FATAL: Module initialization failed");
      return INIT_FAILED;
   }

   // Cross-link modules
   if(!LinkModules())
   {
      Print("❌ FATAL: Module linking failed");
      return INIT_FAILED;
   }

   // Validate system integrity
   if(!ValidateSystem())
   {
      Print("❌ FATAL: System validation failed");
      return INIT_FAILED;
   }

   g_SystemInitialized = true;
   g_LastBarTime = iTime(Symbol(), InpTF_M15, 0);

   Print("✅ System initialized successfully");
   Print("📊 Symbol: ", Symbol());
   Print("⏰ Timeframes: H4=", EnumToString(InpTF_H4), " H1=", EnumToString(InpTF_H1), " M15=", EnumToString(InpTF_M15));
   Print("🎯 Risk: ", InpRiskPercent, "% per trade, ", InpMaxDailyRisk, "% daily max");
   Print("🧠 ML Memory: ACTIVE | Episodic Memory: ", g_EpisodicMemory != NULL ? "ACTIVE" : "INACTIVE");
   Print("🔄 Starting Phase 0: Waiting for SR touch...");

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| EXPERT DEINITIALIZATION FUNCTION                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("╔══════════════════════════════════════════════════════════════╗");
   Print("║  SYSTEM SHUTDOWN - Saving state and cleaning up...          ║");
   Print("╚══════════════════════════════════════════════════════════════╝");

   // Print final statistics
   double winRate = g_TotalCyclesCompleted > 0 ?
                    (double)g_SuccessfulCycles / g_TotalCyclesCompleted * 100.0 : 0.0;

   Print("📊 FINAL STATISTICS:");
   Print("   Total Cycles: ", g_TotalCyclesCompleted);
   Print("   Successful: ", g_SuccessfulCycles);
   Print("   Win Rate: ", DoubleToString(winRate, 1), "%");
   Print("   Daily P/L: ", DoubleToString(g_DailyProfit, 2), " points");

   // Save episodic memory state (auto-saved during operation)

   // Cleanup modules
   if(g_SR != NULL) { delete g_SR; g_SR = NULL; }
   if(g_Voting != NULL) { delete g_Voting; g_Voting = NULL; }
   if(g_MetaLearning != NULL) { delete g_MetaLearning; g_MetaLearning = NULL; }
   if(g_OrderExec != NULL) { delete g_OrderExec; g_OrderExec = NULL; }
   if(g_Accumulation != NULL) { delete g_Accumulation; g_Accumulation = NULL; }
   if(g_PatternMemory != NULL) { delete g_PatternMemory; g_PatternMemory = NULL; }
   if(g_BreakoutDetector != NULL) { delete g_BreakoutDetector; g_BreakoutDetector = NULL; }
   if(g_InstitutionalFinder != NULL) { delete g_InstitutionalFinder; g_InstitutionalFinder = NULL; }
   if(g_RegimeDetector != NULL) { delete g_RegimeDetector; g_RegimeDetector = NULL; }
   if(g_EpisodicMemory != NULL) { delete g_EpisodicMemory; g_EpisodicMemory = NULL; }

   Print("✅ Shutdown complete. Reason: ", GetDeinitReasonText(reason));
}

//+------------------------------------------------------------------+
//| EXPERT TICK FUNCTION - The Heart Beat                           |
//+------------------------------------------------------------------+
void OnTick()
{
   // Safety checks
   if(!g_SystemInitialized || !g_TradingEnabled) return;

   // Reset daily profit counter
   CheckDailyReset();

   // Check if new bar formed on working timeframe
   datetime currentBarTime = iTime(Symbol(), InpTF_M15, 0);
   bool newBar = (currentBarTime != g_LastBarTime);

   if(newBar)
   {
      g_LastBarTime = currentBarTime;

      // Update all market context modules
      UpdateMarketContext();

      // Process the 6-phase cycle
      ProcessCycle();
   }

   // Monitor active positions (runs every tick)
   if(g_Cycle.currentPhase == PHASE_5_MONITORING)
   {
      MonitorActivePositions();
   }
}

//+------------------------------------------------------------------+
//| CORE FUNCTION: Process 6-Phase Trading Cycle                    |
//+------------------------------------------------------------------+
void ProcessCycle()
{
   switch(g_Cycle.currentPhase)
   {
      case PHASE_0_WAITING_SR:
         Phase0_WaitForSRTouch();
         break;

      case PHASE_1_SR_TOUCHED:
         Phase1_ValidateSRTouch();
         break;

      case PHASE_2_ACCUMULATION:
         Phase2_CheckAccumulation();
         break;

      case PHASE_3_NEURAL_VOTE:
         Phase3_NeuralConsensus();
         break;

      case PHASE_4_EXECUTING:
         Phase4_ExecuteOrders();
         break;

      case PHASE_5_MONITORING:
         Phase5_MonitorAndTrail();
         break;

      case PHASE_6_LEARNING:
         Phase6_LearnFromResults();
         break;

      case PHASE_COMPLETE:
         ResetCycle();
         break;
   }
}

//+------------------------------------------------------------------+
//| PHASE 0: Wait for Support/Resistance Touch                      |
//+------------------------------------------------------------------+
void Phase0_WaitForSRTouch()
{
   // Update SR levels
   g_SR.UpdateLevels();

   // Check for SR touch
   double currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   TouchContext touch = g_SR.DetectSRTouch(currentPrice);

   if(touch.valid)
   {
      // SR level touched!
      g_Cycle.srTouch = touch;
      g_Cycle.touchPrice = touch.price;
      g_Cycle.touchType = touch.level.type;
      g_Cycle.cycleStartTime = TimeCurrent();

      if(InpDebugMode)
      {
         Print("✨ PHASE 0→1: SR Touch detected at ", DoubleToString(touch.price, _Digits),
               " | Type: ", EnumToString(touch.level.type),
               " | Quality: ", DoubleToString(touch.quality, 2),
               " | Strength: ", DoubleToString(touch.levelStrength, 2));
      }

      TransitionToPhase(PHASE_1_SR_TOUCHED);
   }
}

//+------------------------------------------------------------------+
//| PHASE 1: Validate SR Touch Quality                              |
//+------------------------------------------------------------------+
void Phase1_ValidateSRTouch()
{
   // Validate touch quality meets minimum threshold
   if(g_Cycle.srTouch.quality < 0.5)
   {
      if(InpDebugMode)
         Print("⚠️ PHASE 1→0: Touch quality too low (", DoubleToString(g_Cycle.srTouch.quality, 2), ") - Resetting");

      ResetCycle();
      return;
   }

   // Touch validated, move to accumulation check
   if(InpDebugMode)
      Print("✅ PHASE 1→2: SR Touch validated - Checking for accumulation...");

   TransitionToPhase(PHASE_2_ACCUMULATION);
}

//+------------------------------------------------------------------+
//| PHASE 2: Check for Accumulation Zone                            |
//+------------------------------------------------------------------+
void Phase2_CheckAccumulation()
{
   // Get SR levels for accumulation detection
   SRLevel srLevels[];
   int srCount = g_SR.GetLevels(srLevels);

   // Find accumulation zones
   AccumulationZone zones[];
   int zoneCount = g_Accumulation.FindAccumulations(srLevels, srCount, zones);

   // Check if current price is in accumulation zone
   double currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   bool inAccumulation = false;

   for(int i = 0; i < zoneCount; i++)
   {
      if(g_Accumulation.IsInAccumulationZone(currentPrice, zones[i]))
      {
         g_Cycle.accumulation.range = zones[i].highPrice - zones[i].lowPrice;
         g_Cycle.accumulation.barCount = zones[i].barCount;
         g_Cycle.accumulation.startTime = zones[i].startTime;
         g_Cycle.accumulation.centerPrice = (zones[i].highPrice + zones[i].lowPrice) / 2.0;
         g_Cycle.accumulation.highPrice = zones[i].highPrice;
         g_Cycle.accumulation.lowPrice = zones[i].lowPrice;
         g_Cycle.accumulation.valid = true;
         g_Cycle.accumulation.volumeConfirmation = (zones[i].volumeAvg > 1.0);
         g_Cycle.accumValid = true;
         g_Cycle.accumBars = zones[i].barCount;

         inAccumulation = true;
         break;
      }
   }

   if(inAccumulation)
   {
      if(InpDebugMode)
      {
         Print("✅ PHASE 2→3: Accumulation confirmed - ", g_Cycle.accumBars, " bars");
         Print("   Range: ", DoubleToString(g_Cycle.accumulation.range / _Point, 1), " points");
         Print("   Center: ", DoubleToString(g_Cycle.accumulation.centerPrice, _Digits));
      }

      TransitionToPhase(PHASE_3_NEURAL_VOTE);
   }
   else
   {
      // No accumulation, but we can still proceed if touch is strong enough
      if(g_Cycle.srTouch.quality >= 0.7 && g_Cycle.srTouch.levelStrength >= 7.0)
      {
         // Strong touch without accumulation - create minimal accumulation context
         g_Cycle.accumulation.valid = false;
         g_Cycle.accumulation.barCount = 1;
         g_Cycle.accumValid = false;

         if(InpDebugMode)
            Print("⚡ PHASE 2→3: Strong SR touch without accumulation - Proceeding to vote");

         TransitionToPhase(PHASE_3_NEURAL_VOTE);
      }
      else
      {
         if(InpDebugMode)
            Print("⚠️ PHASE 2→0: No accumulation and weak touch - Resetting");

         ResetCycle();
      }
   }
}

//+------------------------------------------------------------------+
//| PHASE 3: Neural Consensus Voting                                |
//+------------------------------------------------------------------+
void Phase3_NeuralConsensus()
{
   // Reset votes from previous cycle
   g_Voting.ResetVotes();

   // Get current regime for adaptive parameters
   ENUM_MARKET_REGIME currentRegime = g_RegimeDetector.GetCurrentRegime();
   RegimeParameters regimeParams = g_RegimeDetector.GetCurrentParameters();

   if(InpDebugMode)
      Print("🧠 PHASE 3: Neural Voting | Regime: ", EnumToString(currentRegime));

   // === AGENT 1: Pattern Memory ===
   ENUM_TREND_DIRECTION pmDirection = g_PatternMemory.GetImmediateDirection();
   double pmConfidence = g_PatternMemory.GetDirectionConfidence() / 100.0;
   ENUM_VOTE_DIRECTION pmVote = TrendToVote(pmDirection);

   if(pmVote != VOTE_NONE)
   {
      g_Voting.RecordVote("PatternMemory", pmVote,
                         DirectionToPosition(pmVote),
                         pmConfidence,
                         0.6); // Medium flexibility
   }

   // === AGENT 2: Breakout Detector ===
   ENUM_TREND_DIRECTION boDirection = g_BreakoutDetector.GetImmediateDirection();
   double boConfidence = g_BreakoutDetector.GetDirectionConfidence() / 100.0;
   ENUM_VOTE_DIRECTION boVote = TrendToVote(boDirection);

   if(boVote != VOTE_NONE)
   {
      g_Voting.RecordVote("BreakoutDetector", boVote,
                         DirectionToPosition(boVote),
                         boConfidence,
                         0.4); // Lower flexibility for breakouts
   }

   // === AGENT 3: Institutional Plan Finder ===
   ENUM_TREND_DIRECTION instDirection = g_InstitutionalFinder.GetImmediateDirection();
   double instConfidence = g_InstitutionalFinder.GetDirectionConfidence() / 100.0;
   ENUM_VOTE_DIRECTION instVote = TrendToVote(instDirection);

   if(instVote != VOTE_NONE)
   {
      g_Voting.RecordVote("InstitutionalFinder", instVote,
                         DirectionToPosition(instVote),
                         instConfidence,
                         0.5); // Medium flexibility
   }

   // === AGENT 4: Accumulation Zones ===
   double accumConf = 0;
   ENUM_TREND_DIRECTION accumDirection = g_Accumulation.GetVoteDirection(accumConf);
   ENUM_VOTE_DIRECTION accumVote = TrendToVote(accumDirection);

   if(accumVote != VOTE_NONE)
   {
      g_Voting.RecordVote("AccumulationZones", accumVote,
                         DirectionToPosition(accumVote),
                         accumConf,
                         0.7); // Higher flexibility
   }

   // === AGENT 5: Meta Learning System ===
   // MetaLearning provides strategic direction based on historical performance
   int mlTrend = g_MetaLearning.AnalyzeTrend();
   ENUM_VOTE_DIRECTION mlVote = VOTE_NONE;
   double mlConfidence = 0.0;

   if(mlTrend > 0)
   {
      mlVote = VOTE_LONG;
      mlConfidence = g_MetaLearning.CalculateSignalStrength();
   }
   else if(mlTrend < 0)
   {
      mlVote = VOTE_SHORT;
      mlConfidence = g_MetaLearning.CalculateSignalStrength();
   }

   if(mlVote != VOTE_NONE)
   {
      g_Voting.RecordVote("MetaLearning", mlVote,
                         DirectionToPosition(mlVote),
                         mlConfidence,
                         0.3); // Low flexibility - ML is confident
   }

   // === MAKE FINAL DECISION ===
   MarketEmotion emotion;
   emotion.fear = 0.3;
   emotion.greed = 0.3;
   emotion.uncertainty = 0.4;
   emotion.excitement = 0.0;

   g_Cycle.neuralResult = g_Voting.MakeFinalDecision(emotion);

   if(InpDebugMode)
   {
      Print("🎯 Neural Consensus Result:");
      Print("   Direction: ", EnumToString(g_Cycle.neuralResult.final_direction));
      Print("   Strength: ", DoubleToString(g_Cycle.neuralResult.consensus_strength, 3));
      Print("   Conviction: ", DoubleToString(g_Cycle.neuralResult.total_conviction, 3));
      Print("   Leading Agent: ", g_Cycle.neuralResult.leading_agent);
      Print("   Strong Consensus: ", g_Cycle.neuralResult.strong_consensus ? "YES" : "NO");
      Print("   Veto Used: ", g_Cycle.neuralResult.veto_used ? "YES" : "NO");
   }

   // Check if consensus meets minimum requirements
   if(g_Cycle.neuralResult.final_direction == VOTE_NONE)
   {
      if(InpDebugMode)
         Print("⚠️ PHASE 3→0: No consensus reached - Resetting");

      ResetCycle();
      return;
   }

   if(g_Cycle.neuralResult.consensus_strength < InpMinConsensusStrength)
   {
      if(InpDebugMode)
         Print("⚠️ PHASE 3→0: Consensus too weak (",
               DoubleToString(g_Cycle.neuralResult.consensus_strength, 2), ") - Resetting");

      ResetCycle();
      return;
   }

   if(g_Cycle.neuralResult.total_conviction < InpMinTotalConviction)
   {
      if(InpDebugMode)
         Print("⚠️ PHASE 3→0: Conviction too low (",
               DoubleToString(g_Cycle.neuralResult.total_conviction, 2), ") - Resetting");

      ResetCycle();
      return;
   }

   // === EPISODIC MEMORY PREDICTION ===
   if(InpRequireEpisodicConfirm)
   {
      // Convert touch context for episodic memory
      EM_TouchContext emTouch;
      emTouch.valid = g_Cycle.srTouch.valid;
      emTouch.price = g_Cycle.srTouch.price;
      emTouch.time = TimeCurrent();
      emTouch.touchType = TOUCH_RETEST;
      emTouch.quality = g_Cycle.srTouch.quality;
      emTouch.strength = 1.0;
      emTouch.levelStrength = g_Cycle.srTouch.levelStrength;
      emTouch.touchNumber = g_Cycle.srTouch.touchNumber;
      emTouch.atr = 50 * _Point;

      // Find similar historical episodes
      TradingEpisode similarEpisodes[];
      int similarCount = g_EpisodicMemory.FindSimilarEpisodes(
         emTouch,
         g_Cycle.accumulation,
         currentRegime,
         similarEpisodes,
         10
      );

      // Predict outcome based on similar episodes
      HistoricalPrediction prediction = g_EpisodicMemory.PredictOutcome(similarEpisodes, similarCount);

      if(InpDebugMode)
      {
         Print("📚 Episodic Memory Prediction:");
         Print("   Similar Episodes: ", prediction.samplesUsed);
         Print("   Success Probability: ", DoubleToString(prediction.successProbability * 100, 1), "%");
         Print("   Expected Profit: ", DoubleToString(prediction.expectedProfit, 1), " points");
         Print("   Confidence: ", DoubleToString(prediction.confidence * 100, 1), "%");
         Print("   Should Trade: ", prediction.shouldTrade ? "YES" : "NO");
         if(prediction.warning != "")
            Print("   ⚠️ Warning: ", prediction.warning);
      }

      // Check if episodic memory approves the trade
      if(!prediction.shouldTrade && prediction.samplesUsed >= 3)
      {
         Print("🛑 PHASE 3→0: Episodic memory advises against trade - Resetting");
         Print("   Reason: ", prediction.warning);

         ResetCycle();
         return;
      }
   }

   // === ALL VALIDATIONS PASSED ===
   g_Cycle.consensusId = g_Cycle.neuralResult.consensus_id;
   g_Cycle.finalDirection = g_Cycle.neuralResult.final_direction;
   g_Cycle.consensusStrength = g_Cycle.neuralResult.consensus_strength;
   g_Cycle.leadingAgent = g_Cycle.neuralResult.leading_agent;

   // Create consensus memory record
   g_Cycle.consensusMemory.consensus_id = g_Cycle.consensusId;
   g_Cycle.consensusMemory.timestamp = TimeCurrent();
   g_Cycle.consensusMemory.consensus_strength = g_Cycle.neuralResult.consensus_strength;
   g_Cycle.consensusMemory.agent_count = 5;
   g_Cycle.consensusMemory.direction = g_Cycle.finalDirection;
   g_Cycle.consensusMemory.emotional_score = emotion.fear + emotion.greed;
   g_Cycle.consensusMemory.agreement_level = g_Cycle.neuralResult.consensus_strength;
   g_Cycle.consensusMemory.dominant_agent = g_Cycle.leadingAgent;

   Print("✅ PHASE 3→4: Strong consensus achieved - Executing orders");

   TransitionToPhase(PHASE_4_EXECUTING);
}

//+------------------------------------------------------------------+
//| PHASE 4: Execute Orders                                         |
//+------------------------------------------------------------------+
void Phase4_ExecuteOrders()
{
   // Set consensus ID for order execution
   g_OrderExec.SetCurrentConsensusID(g_Cycle.consensusId);

   // Convert vote direction to trade direction
   ENUM_TRADE_DIRECTION tradeDir = (g_Cycle.finalDirection == VOTE_LONG) ? TRADE_BUY : TRADE_SELL;
   g_Cycle.tradeDirection = tradeDir;

   // Calculate market emotion for lot sizing
   MarketEmotion emotion = g_Cycle.neuralResult.market_emotion;

   // Execute first order
   bool success = g_OrderExec.ExecuteFirstOrder(
      tradeDir,
      g_Cycle.consensusStrength,
      g_Cycle.neuralResult.total_conviction,
      emotion
   );

   if(!success)
   {
      Print("❌ PHASE 4→0: Order execution failed - Resetting");
      ResetCycle();
      return;
   }

   g_Cycle.ordersExecuted = 1;

   // Start episodic memory episode
   EM_TouchContext emTouch;
   emTouch.valid = g_Cycle.srTouch.valid;
   emTouch.price = g_Cycle.srTouch.price;
   emTouch.time = TimeCurrent();
   emTouch.quality = g_Cycle.srTouch.quality;
   emTouch.levelStrength = g_Cycle.srTouch.levelStrength;
   emTouch.touchNumber = g_Cycle.srTouch.touchNumber;
   emTouch.atr = 50 * _Point;

   g_Cycle.episodeId = g_EpisodicMemory.StartNewEpisode(
      emTouch,
      g_Cycle.accumulation,
      g_Cycle.consensusMemory,
      g_Cycle.neuralResult
   );

   Print("✅ PHASE 4→5: Order executed successfully");
   Print("   Episode ID: ", g_Cycle.episodeId);
   Print("   Consensus ID: ", g_Cycle.consensusId);
   Print("   Direction: ", EnumToString(tradeDir));

   // Initialize monitoring variables
   g_Cycle.maxProfitReached = 0.0;
   g_Cycle.maxDrawdownReached = 0.0;
   g_Cycle.trailingActive = false;

   TransitionToPhase(PHASE_5_MONITORING);
}

//+------------------------------------------------------------------+
//| PHASE 5: Monitor Positions and Manage Trailing                  |
//+------------------------------------------------------------------+
void Phase5_MonitorAndTrail()
{
   // Monitor positions (called every tick in OnTick)
   // This phase just ensures we stay here until positions close

   // Check if all positions are closed
   bool hasOpenPositions = PositionSelect(Symbol());

   if(!hasOpenPositions)
   {
      if(InpDebugMode)
         Print("📊 PHASE 5→6: All positions closed - Moving to learning phase");

      TransitionToPhase(PHASE_6_LEARNING);
   }
}

//+------------------------------------------------------------------+
//| PHASE 6: Learn from Results                                     |
//+------------------------------------------------------------------+
void Phase6_LearnFromResults()
{
   // Calculate cycle results
   double totalProfit = 0.0;
   bool cycleSuccess = false;
   int durationBars = Bars(Symbol(), InpTF_M15, g_Cycle.cycleStartTime, TimeCurrent());

   // Get cycle profit from order execution module
   // (OrderExecution tracks this internally)

   // For now, we'll estimate from history
   HistorySelect(g_Cycle.cycleStartTime, TimeCurrent());
   int totalDeals = HistoryDealsTotal();

   for(int i = 0; i < totalDeals; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0)
      {
         if(HistoryDealGetString(ticket, DEAL_SYMBOL) == Symbol())
         {
            totalProfit += HistoryDealGetDouble(ticket, DEAL_PROFIT);
         }
      }
   }

   cycleSuccess = (totalProfit > 0);

   g_Cycle.cycleSuccessful = cycleSuccess;
   g_Cycle.totalProfit = totalProfit;
   g_Cycle.cycleDurationBars = durationBars;

   // Update daily profit
   g_DailyProfit += totalProfit;

   // Update cycle statistics
   g_TotalCyclesCompleted++;
   if(cycleSuccess)
      g_SuccessfulCycles++;

   // Update voting statistics with results
   // (This is handled by OrderExecution.NotifyOrderClosed during position close)

   // Complete episodic memory episode
   CompleteTradeRecord tradeRecord;
   tradeRecord.consensus_id = g_Cycle.consensusId;
   tradeRecord.order_profit_points = totalProfit / _Point;
   tradeRecord.order_success = cycleSuccess;
   tradeRecord.order_duration_bars = durationBars;
   tradeRecord.max_favorable_excursion = g_Cycle.maxProfitReached;
   tradeRecord.max_adverse_excursion = g_Cycle.maxDrawdownReached;

   g_EpisodicMemory.CompleteEpisode(g_Cycle.episodeId, tradeRecord, cycleSuccess);

   // Print cycle summary
   Print("╔══════════════════════════════════════════════════════════════╗");
   Print("║  CYCLE COMPLETE - Learning Phase                            ║");
   Print("╠══════════════════════════════════════════════════════════════╣");
   Print("║  Episode ID: ", g_Cycle.episodeId);
   Print("║  Consensus ID: ", g_Cycle.consensusId);
   Print("║  Direction: ", EnumToString(g_Cycle.finalDirection));
   Print("║  Leading Agent: ", g_Cycle.leadingAgent);
   Print("║  Duration: ", durationBars, " bars");
   Print("║  Result: ", cycleSuccess ? "✅ PROFITABLE" : "❌ LOSS");
   Print("║  Profit: ", DoubleToString(totalProfit, 2), " (", DoubleToString(totalProfit / _Point, 1), " pts)");
   Print("║  Max Profit Reached: ", DoubleToString(g_Cycle.maxProfitReached, 1), " pts");
   Print("║  Max Drawdown: ", DoubleToString(g_Cycle.maxDrawdownReached, 1), " pts");
   Print("╠══════════════════════════════════════════════════════════════╣");
   Print("║  Total Cycles: ", g_TotalCyclesCompleted, " | Win Rate: ",
         DoubleToString((double)g_SuccessfulCycles / g_TotalCyclesCompleted * 100, 1), "%");
   Print("║  Daily P/L: ", DoubleToString(g_DailyProfit, 2));
   Print("╚══════════════════════════════════════════════════════════════╝");

   // Print agent statistics
   if(InpDebugMode)
   {
      g_Voting.PrintAgentStatistics();
   }

   TransitionToPhase(PHASE_COMPLETE);
}

//+------------------------------------------------------------------+
//| Monitor Active Positions (Called every tick in Phase 5)         |
//+------------------------------------------------------------------+
void MonitorActivePositions()
{
   // Update trailing stop for all cycle positions
   g_OrderExec.UpdateCycleTrailingStop();

   // Track max profit and drawdown
   if(PositionSelect(Symbol()))
   {
      double currentProfit = PositionGetDouble(POSITION_PROFIT) / _Point;

      if(currentProfit > g_Cycle.maxProfitReached)
         g_Cycle.maxProfitReached = currentProfit;

      if(currentProfit < 0 && MathAbs(currentProfit) > g_Cycle.maxDrawdownReached)
         g_Cycle.maxDrawdownReached = MathAbs(currentProfit);
   }

   // Check for additional order execution based on profit
   if(g_Cycle.ordersExecuted < InpMaxOrdersPerCycle)
   {
      if(g_Cycle.maxProfitReached > 50) // 50 points profit
      {
         // Consider adding another order
         bool added = g_OrderExec.ExecuteAdditionalOrder(
            g_Cycle.tradeDirection,
            g_Cycle.consensusStrength
         );

         if(added)
         {
            g_Cycle.ordersExecuted++;
            Print("📈 Additional order added to cycle (", g_Cycle.ordersExecuted, "/", InpMaxOrdersPerCycle, ")");
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Update Market Context (All modules)                             |
//+------------------------------------------------------------------+
void UpdateMarketContext()
{
   // Update regime detection
   g_RegimeDetector.UpdateRegimeDetection();

   // Update SR levels (already called in Phase 0, but refresh is good)
   // g_SR.UpdateLevels(); // Commented to avoid double update

   // Update meta learning indicators
   g_MetaLearning.UpdateIndicators();

   // Update breakout detection
   SRLevel levels[];
   int levelCount = g_SR.GetLevels(levels);
   g_BreakoutDetector.AnalyzeBreakouts(levels, levelCount);

   // Update institutional analysis
   AccumulationZone zones[];
   g_InstitutionalFinder.AnalyzeInstitutionalActivity(zones, 0);

   // Update pattern memory
   // (Pattern memory updates internally on each call)
}

//+------------------------------------------------------------------+
//| Reset Cycle to Phase 0                                          |
//+------------------------------------------------------------------+
void ResetCycle()
{
   if(InpDebugMode)
      Print("🔄 Resetting cycle to Phase 0");

   // Clear cycle data but keep statistics
   ulong prevEpisodeId = g_Cycle.episodeId;
   ulong prevConsensusId = g_Cycle.consensusId;

   ZeroMemory(g_Cycle);

   g_Cycle.currentPhase = PHASE_0_WAITING_SR;
   g_Cycle.cycleStartTime = TimeCurrent();

   // Clear direction lock in voting system
   g_Voting.ClearDirectionLock();

   // Visual refresh
   if(InpShowVisuals)
   {
      g_SR.UpdateLevels();
   }
}

//+------------------------------------------------------------------+
//| Transition to Next Phase                                        |
//+------------------------------------------------------------------+
void TransitionToPhase(ENUM_CYCLE_PHASE newPhase)
{
   ENUM_CYCLE_PHASE oldPhase = g_Cycle.currentPhase;
   g_Cycle.currentPhase = newPhase;

   if(InpDebugMode)
      Print("🔄 Phase Transition: ", EnumToString(oldPhase), " → ", EnumToString(newPhase));
}

//+------------------------------------------------------------------+
//| Check Daily Reset                                               |
//+------------------------------------------------------------------+
void CheckDailyReset()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));

   if(g_LastDailyReset != today)
   {
      // New day started
      if(g_LastDailyReset != 0) // Not first run
      {
         Print("📅 Daily Reset | Previous Day P/L: ", DoubleToString(g_DailyProfit, 2));
      }

      g_DailyProfit = 0.0;
      g_LastDailyReset = today;

      // Check if we should pause trading due to max daily risk
   }

   // Pause trading if daily loss exceeds max
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double maxDailyLoss = accountBalance * InpMaxDailyRisk / 100.0;

   if(g_DailyProfit < -maxDailyLoss)
   {
      if(g_TradingEnabled)
      {
         Print("🛑 DAILY RISK LIMIT REACHED - Trading paused for today");
         Print("   Daily Loss: ", DoubleToString(g_DailyProfit, 2));
         Print("   Max Allowed: -", DoubleToString(maxDailyLoss, 2));

         g_TradingEnabled = false;

         // Close all positions if any
         while(PositionSelect(Symbol()))
         {
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            g_OrderExec.ClosePosition(ticket);
         }
      }
   }
   else if(!g_TradingEnabled && g_DailyProfit >= -maxDailyLoss)
   {
      // Re-enable trading if conditions improve
      g_TradingEnabled = true;
      Print("✅ Trading re-enabled");
   }
}

//+------------------------------------------------------------------+
//| INITIALIZATION HELPER FUNCTIONS                                 |
//+------------------------------------------------------------------+
bool InitializeModules()
{
   Print("⚙️ Initializing system modules...");

   // Support/Resistance Detection
   g_SR = new CSupportResistance();
   if(!g_SR.Init(InpTF_H1, InpShowVisuals))
   {
      Print("❌ Failed to initialize SR system");
      return false;
   }
   Print("✓ SR Detection initialized");

   // Voting Statistics
   g_Voting = new VotingStatistics();
   if(!g_Voting.Initialize())
   {
      Print("❌ Failed to initialize Voting system");
      return false;
   }
   Print("✓ Voting System initialized");

   // Meta Learning System
   g_MetaLearning = new CMetaLearningSystem();
   if(!g_MetaLearning.Initialize())
   {
      Print("❌ Failed to initialize MetaLearning system");
      return false;
   }
   Print("✓ MetaLearning System initialized");

   // Order Execution
   g_OrderExec = new OrderExecution();
   if(!g_OrderExec.Initialize(g_MetaLearning))
   {
      Print("❌ Failed to initialize OrderExecution");
      return false;
   }
   Print("✓ Order Execution initialized");

   // Accumulation Zones
   g_Accumulation = new CAccumulationZones();
   if(!g_Accumulation.Init(InpTF_M15, InpShowVisuals))
   {
      Print("❌ Failed to initialize Accumulation system");
      return false;
   }
   Print("✓ Accumulation Zones initialized");

   // Pattern Memory
   g_PatternMemory = new CPatternMemory();
   if(!g_PatternMemory.Init(InpTF_H1, InpShowVisuals))
   {
      Print("❌ Failed to initialize Pattern Memory");
      return false;
   }
   Print("✓ Pattern Memory initialized");

   // Breakout Detector
   g_BreakoutDetector = new CBreakoutDetector();
   if(!g_BreakoutDetector.Init(InpTF_M15, InpShowVisuals))
   {
      Print("❌ Failed to initialize Breakout Detector");
      return false;
   }
   Print("✓ Breakout Detector initialized");

   // Institutional Plan Finder
   g_InstitutionalFinder = new CInstitutionalPlanFinder();
   if(!g_InstitutionalFinder.Init(InpTF_H1, InpShowVisuals))
   {
      Print("❌ Failed to initialize Institutional Finder");
      return false;
   }
   Print("✓ Institutional Finder initialized");

   // Regime Detection System
   g_RegimeDetector = new RegimeDetectionSystem();
   // Initialize with forward references (will be linked later)
   Print("✓ Regime Detector created");

   // Episodic Memory System
   g_EpisodicMemory = new EpisodicMemorySystem();
   Print("✓ Episodic Memory created");

   return true;
}

//+------------------------------------------------------------------+
//| Link Modules Together                                           |
//+------------------------------------------------------------------+
bool LinkModules()
{
   Print("🔗 Linking system modules...");

   // Initialize Regime Detector with Episodic Memory and MetaLearning
   if(!g_RegimeDetector.Initialize(g_EpisodicMemory, g_MetaLearning))
   {
      Print("❌ Failed to link Regime Detector");
      return false;
   }
   Print("✓ Regime Detector linked");

   // Initialize Episodic Memory with Regime Detector and MetaLearning
   if(!g_EpisodicMemory.Initialize(g_RegimeDetector, g_MetaLearning))
   {
      Print("❌ Failed to link Episodic Memory");
      return false;
   }
   Print("✓ Episodic Memory linked");

   return true;
}

//+------------------------------------------------------------------+
//| Validate System Integrity                                       |
//+------------------------------------------------------------------+
bool ValidateSystem()
{
   Print("🔍 Validating system integrity...");

   bool valid = true;

   if(g_SR == NULL) { Print("❌ SR is NULL"); valid = false; }
   if(g_Voting == NULL) { Print("❌ Voting is NULL"); valid = false; }
   if(g_MetaLearning == NULL) { Print("❌ MetaLearning is NULL"); valid = false; }
   if(g_OrderExec == NULL) { Print("❌ OrderExec is NULL"); valid = false; }
   if(g_Accumulation == NULL) { Print("❌ Accumulation is NULL"); valid = false; }
   if(g_PatternMemory == NULL) { Print("❌ PatternMemory is NULL"); valid = false; }
   if(g_BreakoutDetector == NULL) { Print("❌ BreakoutDetector is NULL"); valid = false; }
   if(g_InstitutionalFinder == NULL) { Print("❌ InstitutionalFinder is NULL"); valid = false; }
   if(g_RegimeDetector == NULL) { Print("❌ RegimeDetector is NULL"); valid = false; }
   if(g_EpisodicMemory == NULL) { Print("❌ EpisodicMemory is NULL"); valid = false; }

   if(valid)
      Print("✅ All modules validated successfully");

   return valid;
}

//+------------------------------------------------------------------+
//| UTILITY FUNCTIONS                                               |
//+------------------------------------------------------------------+
ENUM_VOTE_DIRECTION TrendToVote(ENUM_TREND_DIRECTION trend)
{
   if(trend == TREND_UP) return VOTE_LONG;
   if(trend == TREND_DOWN) return VOTE_SHORT;
   return VOTE_NONE;
}

double DirectionToPosition(ENUM_VOTE_DIRECTION vote)
{
   if(vote == VOTE_LONG) return 1.0;
   if(vote == VOTE_SHORT) return -1.0;
   return 0.0;
}

string GetDeinitReasonText(int reason)
{
   switch(reason)
   {
      case REASON_PROGRAM: return "Program stopped by user";
      case REASON_REMOVE: return "EA removed from chart";
      case REASON_RECOMPILE: return "EA recompiled";
      case REASON_CHARTCHANGE: return "Chart symbol/period changed";
      case REASON_CHARTCLOSE: return "Chart closed";
      case REASON_PARAMETERS: return "Input parameters changed";
      case REASON_ACCOUNT: return "Account changed";
      case REASON_TEMPLATE: return "Template changed";
      case REASON_INITFAILED: return "Initialization failed";
      case REASON_CLOSE: return "Terminal closed";
      default: return "Unknown reason";
   }
}

//+------------------------------------------------------------------+
//| END OF TRADING STRATEGY v2.0                                    |
//| "Simplicity is the ultimate sophistication" - Leonardo da Vinci |
//+------------------------------------------------------------------+
