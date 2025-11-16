//+------------------------------------------------------------------+
//|                                    OrderExecution_NCN_v11.03.mqh |
//|                        Sistema con Neural Consensus Network      |
//|                        Trailing Stop Sincronizado para Ciclo     |
//|                        VERSIÓN MEJORADA PARA FOREX               |
//+------------------------------------------------------------------+
#ifndef ORDER_EXECUTION_NCN_V11_03_MQH
#define ORDER_EXECUTION_NCN_V11_03_MQH
#property copyright "Trading System v11.03 - Synchronized Trailing Stop"
#property version   "11.03"
#property strict

#include <Trade/Trade.mqh>
#include <SupportResistance.mqh>
#include <VotingStatistics.mqh>
#include <MetaLearningSystem.mqh>
#include <RegimeDetectionSystem.mqh>

//+------------------------------------------------------------------+
//| ENUMERACIONES                                                    |
//+------------------------------------------------------------------+
#ifndef ENUM_TRADE_DIRECTION_DEF
#define ENUM_TRADE_DIRECTION_DEF
enum ENUM_TRADE_DIRECTION
  {
   DIRECTION_NONE,   // 0
   DIRECTION_BUY,    // 1
   DIRECTION_SELL    // 2
  };
#endif

//+------------------------------------------------------------------+
//| ESTRUCTURAS PARA MULTI-ORDEN                                    |
//+------------------------------------------------------------------+
#ifndef MULTI_ORDER_CYCLE_STRUCT
#define MULTI_ORDER_CYCLE_STRUCT
struct MultiOrderCycle
  {
   ulong             tickets[10];
   double            lotSizes[10];
   double            entryPrices[10];
   double            stopLosses[10];
   double            takeProfits[10];
   int               orderCount;
   double            baseLotSize;
   ENUM_TRADE_DIRECTION direction;
   datetime          cycleStartTime;
   bool              cycleActive;
   double            totalPartialClosed;
   double            cycleProfit;

   // Campos para Neural Consensus
   double            consensusStrength;
   double            emotionalContext;
   int               emotionalAlerts;
   double            maxFearLevel;
   double            avgConviction;
   // NUEVO: Tracking de consenso
   ulong             initial_consensus_id;
   ulong             consensus_ids[10];

   // NUEVO: Trailing sincronizado del ciclo
   bool              cycleTrailingActive;
   double            cycleTrailingLevel;
   double            cycleTrailingActivationPrice;
   datetime          cycleLastTrailingUpdate;
   double            cycleMaxProfit;
   double            maxDrawdown;
   int               dissenting_agents;
  };
#endif // MULTI_ORDER_CYCLE_STRUCT

//+------------------------------------------------------------------+
//| Estructura mejorada para configuración de trailing              |
//+------------------------------------------------------------------+
struct SmartTrailingConfig
  {
   // Valores en PIPS (no puntos)
   double            activationPips;      // Pips de profit para activar
   double            trailingPips;        // Distancia del trailing en pips
   double            stepPips;            // Paso mínimo para actualizar
   bool              useATR;              // Usar ATR dinámico
   double            atrMultiplier;       // Multiplicador de ATR

   // Control de actualización
   int               updateIntervalSec;   // Segundos entre actualizaciones
   datetime          lastUpdateTime;    // Última actualización

   // Estado del trailing
   bool              isActive;            // Trailing activo
   double            currentStopLevel;    // Nivel actual del stop
   double            activationPrice;     // Precio de activación
   double            maxProfit;          // Máximo profit alcanzado
  };

struct PositionInfo
  {
   ulong             ticket;
   datetime          openTime;
   double            openPrice;
   double            currentSL;
   double            currentTP;
   double            maxProfit;
   double            currentLot;
   bool              isPartOfCycle;
   int               cycleIndex;
   double            emotionalScore;

   // Info de trailing
   bool              trailingActive;
   int               trailingStage;
   double            lastTrailingPrice;
  };

//+------------------------------------------------------------------+
//| NUEVA ESTRUCTURA: Configuración de Lot Inteligente              |
//+------------------------------------------------------------------+
struct IntelligentLotConfig
  {
   // Multiplicadores base
   double            minRiskMultiplier;
   double            maxRiskMultiplier;

   // Pesos de componentes
   double            consensusWeight;
   double            convictionWeight;
   double            emotionalWeight;
   double            metaLearningWeight;

   // Umbrales de confianza
   double            highConfidenceThreshold;
   double            lowConfidenceThreshold;

   // Ajustes emocionales
   double            fearReductionFactor;
   double            greedBoostFactor;
   double            uncertaintyPenalty;
  };

//+------------------------------------------------------------------+
//| ENUMERACIONES ADICIONALES                                        |
//+------------------------------------------------------------------+
enum ENUM_EXECUTION_PHASE
  {
   PHASE_VALIDATION,
   PHASE_CALCULATION,
   PHASE_EXECUTION,
   PHASE_MANAGEMENT,
   PHASE_EMOTIONAL_CHECK
  };

enum ENUM_MARKET_CONTEXT
  {
   CONTEXT_RALLY,
   CONTEXT_ACCUMULATION,
   CONTEXT_HIGH_VOL,
   CONTEXT_NORMAL,
   CONTEXT_FEARFUL,
   CONTEXT_GREEDY
  };

enum ENUM_EMOTIONAL_ACTION
  {
   ACTION_NONE,
   ACTION_REDUCE_SIZE,
   ACTION_TIGHTEN_STOPS,
   ACTION_PARTIAL_CLOSE,
   ACTION_FULL_EXIT
  };

//+------------------------------------------------------------------+
//| CLASE PRINCIPAL OrderExecution v11.03                           |
//+------------------------------------------------------------------+
class OrderExecution
  {

   // ✅ NUEVOS MÉTODOS PARA CONTROL DE CICLO MEJORADO
   bool              TryAddProgressiveOrders();      // Agregar órdenes progresivamente
   bool              UpdateCycleTrailingStop();      // Trailing a nivel de ciclo completo
   bool              ValidateNewCycleExecution(int direction);  // Evitar ciclos duplicados

private:
   // NUEVO: ID del consenso actual
   ulong             m_current_consensus_id;

   // NUEVO: Tracking de órdenes cerradas
   struct ClosedOrderInfo
     {
      ulong          ticket;
      ulong          consensus_id;
      double         profit;
      bool           success;
      datetime       close_time;
     };
   ClosedOrderInfo   m_closed_orders[];
   int               m_closed_count;

   // Referencias a otros módulos
   MetaLearningSystem*   m_metaLearning;

   // Parámetros de configuración
   double               m_riskPercent;
   double               m_maxLotSize;
   double               m_atrMultiplier;
   double               m_emergencyDD;
   int                  m_magicNumber;

   // Parámetros multi-orden
   double               m_orderReduction;
   double               m_partialClosePercent;
   int                  m_trailingDistance;
   int                  m_trailingStart;
   int                  m_maxOrdersPerCycle;
   int               m_plannedOrdersForCycle; // ✅ NUEVO: Órdenes planificadas para este ciclo

   // Parámetros emocionales
   double               m_fearThreshold;
   double               m_greedThreshold;
   double               m_emotionalReduction;
   bool                 m_useEmotionalStops;

   // NUEVO: Configuración de lote inteligente
   IntelligentLotConfig m_lotConfig;
   double               m_lastConsensusStrength;
   double               m_lastTotalConviction;

   // NUEVOS: Configuración de trailing dinámico
   SmartTrailingConfig  m_trailingStages[5];  // CAMBIADO A SmartTrailingConfig
   bool                 m_useDynamicTrailing;
   double               m_trailingATRPeriod;

   // NUEVOS: Parámetros de trailing desde inputs
   double               m_trailingStartPercent;
   double               m_trailingStepPercent;
   bool                 m_useATRTrailing;
   double               m_trailingStartATR;

   // Estado interno
   double               m_currentATR;
   double               m_accountEquity;
   double               m_volatilityRatio;
   ENUM_MARKET_CONTEXT  m_marketContext;
   bool                 m_emergencyActive;
   MarketEmotion        m_currentEmotion;

   // Estadísticas
   int                  m_totalTrades;
   double               m_totalProfit;
   double               m_maxDrawdown;
   int                  m_emotionalExits;

   // Variables para tracking de órdenes multi-ciclo
   double            m_initialEntryPrice;         // Precio de entrada de la primera orden
   datetime          m_lastOrderTime;             // Timestamp de la última orden ejecutada
   datetime          m_lastAdditionalOrderCheck;  // Timestamp de la última verificación

   // Control de trade
   CTrade               m_trade;

public:
   // Multi-orden público
   MultiOrderCycle      m_multiOrder;
   // -- Declaraciones añadidas para consenso y ciclo multi-orden
   void              ResetMultiOrderCycle();
   void              SetCurrentConsensusID(ulong consensus_id);
   void              NotifyOrderClosed(ulong ticket, double profit, bool success);

   // Constructor y destructor
                     OrderExecution();
                    ~OrderExecution();

   // Inicialización
   bool              Initialize(MetaLearningSystem* metaLearning = NULL);
   void              SetParameters(double riskPercent, double maxLot, double atrMult);
   void              SetMultiOrderParams(double reduction, double partialClose, int trailingStart, int trailingStep, int maxOrders);
   void              SetEmotionalParams(double fearThreshold, double greedThreshold, double emotionalReduction);
   void              SetMagicNumber(int magic) { m_magicNumber = magic; }

   // Configuración de trailing dinámico
   void              SetDynamicTrailingParams(bool useDynamic, double atrPeriod = 14);
   void              ConfigureTrailingStage(int stage, int activation, int distance, double protection, bool useATR, double atrMult);
   void              SetTrailingInputParams(double startPercent, double stepPercent, bool useATR, double atrStart);

   // MÉTODOS PRINCIPALES MULTI-ORDEN
   bool              ExecuteFirstOrder(int direction, double conviction, double touchPrice);
   bool              ExecuteAdditionalOrder(int direction, double conviction);
   void              UpdateAllTrailingStops();
   bool              ExecutePartialCloses();
   void              MonitorMultiplePositions();
   bool              CheckCycleIntegrity();
   void              FinalizeCycle();

   // Verificar si hay órdenes in profit
   bool              HasOrdersInProfit(int &ordersInProfit, double &totalProfit);
   double            GetFirstOrderProfit();
   double            GetFirstOrderMovement();
   void              PrintCycleStatus();
   // Métodos emocionales
   void              UpdateEmotionalContext(const MarketEmotion &emotion);
   ENUM_EMOTIONAL_ACTION AnalyzeEmotionalAction();
   bool              ExecuteEmotionalAction(ENUM_EMOTIONAL_ACTION action);
   void              AdjustStopsForEmotion();
   double            GetEmotionalMultiplier();

   // Métodos de cálculo
   double            CalculateLotSize(double stopDistance, double conviction);
   double            CalculateEmotionalLotSize(double baseLot, const MarketEmotion &emotion);
   double            CalculateReducedLotSize(int orderIndex);
   double            CalculateStopLoss(double entryPrice, int direction, bool isAdditional = false);
   double            CalculateTakeProfit(double entryPrice, int direction);
   double            CalculateEmotionalStop(double normalStop, int direction);

   // Gestión de posiciones mejorada
   bool              UpdateCycleTrailing();
   bool              ApplyCycleTrailingToOrder(int orderIndex);
   bool              CheckTrailingActivation();
   bool              ClosePartialPosition(ulong ticket, double closePercent);
   bool              EmergencyCloseAll(string reason);
   bool              IsTicketInCycle(ulong ticket);
   int               GetOrderIndexByTicket(ulong ticket);
   bool              CheckEmergencyStop();

   // Comunicación con otros módulos
   void              SendCycleToMetaLearning();
   void              UpdateConsensusContext(double consensusStrength, double conviction);
   void              UpdateStatus(string status);

   // Utilidades
   void              UpdateATR();
   void              UpdateAccountInfo();
   bool              ValidateExecution(double price, double lot);
   void              LogExecutionEvent(string message);
   void              PrintEmotionalStatus();
   void              PrintTrailingStatus();

   // NUEVAS FUNCIONES PÚBLICAS CRÍTICAS
   double            PipsToPoints(double pips);
   double            PointsToPips(double points);
   double            CalculateProfitInPips(double entryPrice, double currentPrice, int direction);
   string            GetInstrumentType();
   void              AdjustTrailingForInstrument();

   bool              ShouldAddAdditionalOrder();
   // ═══════════════════════════════════════════════════════════════
   // SISTEMA MULTI-ÓRDENES MEJORADO - Métodos adicionales
   // ═══════════════════════════════════════════════════════════════
   
   // Determinar número óptimo de órdenes basado en ML
   int               DetermineOptimalOrderCount(double consensusStrength, double mlScore);
   
   // Calcular lote progresivo para órdenes adicionales
   double            CalculateProgressiveLot(int orderIndex, double baseLot);
   
   // Validar si se puede ejecutar la siguiente orden
   bool              CanExecuteNextOrder(int orderIndex);
   
   // Ejecutar orden individual con reintentos inteligentes
   bool              ExecuteOrderWithRetry(int orderIndex, int direction, double lotSize, double conviction, double touchPrice);
   
   // Actualizar precio promedio de entrada
   void              UpdateAverageEntry();
   
   // Actualizar profit no realizado del ciclo
   void              UpdateUnrealizedProfit();
   
   // Mostrar resumen del ciclo multi-orden
   void              ShowMultiOrderSummary();
   
   // Proceso principal optimizado de ejecución multi-orden
   int               ExecuteMultiOrderCycleOptimized(int direction, double baseLotSize, 
                                                      int plannedOrders, double consensusStrength,
                                                      double mlScore, double conviction, double touchPrice);


private:
   // Métodos internos
   bool              ExecuteMarketOrder(int direction, double lotSize, double entryPrice, double stopPrice, double tpPrice);
   void              RecalculateActiveOrders();
   void              CompactOrderArrays();
   bool              CheckOrderClosed(ulong ticket);
   double            GetUpdatedPrice(int direction);
   int               CalculateDynamicSlippage();
   void              UpdateMarketContext();
   double            CalculateEmotionalScore();
   void              LogEmotionalEvent(string event, double score);
   double            m_actualRiskUsed;
   bool              m_overrideMinLot;

   // Métodos privados para trailing
   void              InitializeTrailingConfig();
   int               DetermineTrailingStage(double profitPoints);
   double            GetATRValue(ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT);
   double            CalculateCycleTrailingStop(double currentPrice);

   // NUEVOS: Métodos mejorados para forex
   double            NormalizeToPips(double points);
   bool              IsForexPair();
   double            GetAdaptiveActivationThreshold(int stage);

   // NUEVOS: Métodos para cálculo inteligente de lote
   void              InitializeLotConfig();
   double            CalculateIntelligentLotSize(double baseRisk, double stopDistance);
   double            CalculateConfidenceMultiplier();
   double            CalculateEmotionalAdjustment();
   double            GetMetaLearningBoost();
   double            NormalizeLotSize(double lot);
   void              PrintLotCalculationDetails(double finalLot);

   // NUEVA FUNCIÓN CRÍTICA
   double            CalculateOptimalTrailingDistance();

   ulong             GetCurrentConsensusID() const
     {
      return m_current_consensus_id;
     }
  };

//+------------------------------------------------------------------+
//| Clase para gestión y ejecución de órdenes                       |
//+------------------------------------------------------------------+
class COrderExecution
  {
private:
   int               m_magicNumber;        // Magic number para identificar órdenes
   int               m_slippage;            // Slippage permitido
   int               m_maxRetries;          // Máximo de reintentos
   double            m_minLotSize;          // Tamaño mínimo de lote
   double            m_maxLotSize;          // Tamaño máximo de lote
   double            m_lotStep;             // Step del lote

   // Funciones privadas de validación
   bool              ValidateVolume(double volume);
   bool              ValidatePrice(double price);
   bool              ValidateStopLevels(double price, double sl, double tp, ENUM_ORDER_TYPE orderType);
   double            NormalizeVolume(double volume);

public:
   // Constructor y destructor
                     COrderExecution();
                    ~COrderExecution() { /* no-op */ }

   // Configuración
   void              SetMagicNumber(int magic) { m_magicNumber = magic; }
   void              SetSlippage(int slippage) { m_slippage = slippage; }
   void              SetMaxRetries(int retries) { m_maxRetries = retries; }

   // Funciones principales de trading
   bool              Buy(double volume, double sl = 0, double tp = 0);
   bool              Sell(double volume, double sl = 0, double tp = 0);
   bool              ClosePosition(ulong ticket);
   bool              CloseAllPositions();
   bool              ModifyPosition(ulong ticket, double sl, double tp);

   // Funciones de información
   int               GetOpenPositionsCount();
   double            GetTotalProfit();
   bool              HasOpenPositions() { return GetOpenPositionsCount() > 0; }
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
OrderExecution::OrderExecution()
  {
   m_actualRiskUsed = 0.0;
   m_overrideMinLot = false;
// Parámetros por defecto - CAMBIO: Riesgo máximo 5%
   m_riskPercent = 5.0;  // CAMBIADO DE 2.0 A 5.0
   m_maxLotSize = 1.0;
   m_atrMultiplier = 1.5;
   m_emergencyDD = 10.0;
   m_magicNumber = 123456;
   m_metaLearning = NULL;

// Multi-orden por defecto
   m_orderReduction = 0.65;
   m_partialClosePercent = 0.20;
   m_trailingDistance = 150;
   m_trailingStart = 200;
   m_maxOrdersPerCycle = 5;

// Parámetros emocionales por defecto
   m_fearThreshold = 0.7;
   m_greedThreshold = 0.7;
   m_emotionalReduction = 0.3;
   m_useEmotionalStops = true;

// NUEVO: Configuración de lote inteligente
   InitializeLotConfig();
   m_lastConsensusStrength = 0.5;
   m_lastTotalConviction = 0.5;

// Trailing dinámico por defecto
   m_useDynamicTrailing = true;
   m_trailingATRPeriod = 14;
   m_trailingStartPercent = 0.25;
   m_trailingStepPercent = 0.125;
   m_useATRTrailing = true;
   m_trailingStartATR = 0.50;
   InitializeTrailingConfig();

// Estado inicial
   m_currentATR = 0.0;
   m_accountEquity = 0.0;
   m_marketContext = CONTEXT_NORMAL;
   m_emergencyActive = false;

// Estadísticas
   m_totalTrades = 0;
   m_totalProfit = 0.0;
   m_maxDrawdown = 0.0;
   m_emotionalExits = 0;

// Inicializar multi-orden
   ResetMultiOrderCycle();

// Inicializar emoción
   m_currentEmotion.fear = 0.5;
   m_currentEmotion.greed = 0.5;
   m_currentEmotion.uncertainty = 0.5;
   m_currentEmotion.excitement = 0.5;

// Configurar CTrade
   m_trade.SetExpertMagicNumber(m_magicNumber);
   m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   m_trade.SetDeviationInPoints(10);
  }
  
  //+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
COrderExecution::COrderExecution()
{
    m_magicNumber = 0;
    m_slippage = 10;
    m_maxRetries = 3;
    
    // Obtener especificaciones del símbolo
    m_minLotSize = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    m_maxLotSize = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    m_lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
OrderExecution::~OrderExecution()
  {
// Liberar recursos si es necesario
  }

//+------------------------------------------------------------------+
//| Inicialización                                                   |
//+------------------------------------------------------------------+
bool OrderExecution::Initialize(MetaLearningSystem* metaLearning)
  {
   m_metaLearning = metaLearning;
   UpdateAccountInfo();
   UpdateATR();
   return true;
  }

//+------------------------------------------------------------------+
//| Configurar parámetros generales                                  |
//+------------------------------------------------------------------+
void OrderExecution::SetParameters(double riskPercent, double maxLot, double atrMult)
  {
   m_riskPercent = riskPercent;
   m_maxLotSize = maxLot;
   m_atrMultiplier = atrMult;
  }

//+------------------------------------------------------------------+
//| NUEVA FUNCIÓN: Convertir pips a puntos según el símbolo         |
//+------------------------------------------------------------------+
double OrderExecution::PipsToPoints(double pips)
  {
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

// Para forex con 5 o 3 decimales
   if(digits == 5 || digits == 3)
      return pips * 10 * point;
   else
      return pips * point;
  }

//+------------------------------------------------------------------+
//| NUEVA FUNCIÓN: Convertir puntos a pips según el símbolo         |
//+------------------------------------------------------------------+
double OrderExecution::PointsToPips(double points)
  {
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

// Para forex con 5 o 3 decimales
   if(digits == 5 || digits == 3)
      return points / 10.0;
   else
      return points;
  }

//+------------------------------------------------------------------+
//| NUEVA FUNCIÓN: Calcular profit en pips desde precio de entrada  |
//+------------------------------------------------------------------+
double OrderExecution::CalculateProfitInPips(double entryPrice, double currentPrice, int direction)
  {
   double priceMove = 0;

   if(direction > 0) // BUY
      priceMove = currentPrice - entryPrice;
   else // SELL
      priceMove = entryPrice - currentPrice;

// Convertir movimiento de precio a pips
   return PointsToPips(priceMove / _Point);
  }

//+------------------------------------------------------------------+
//| Configurar parámetros multi-orden MEJORADO                      |
//+------------------------------------------------------------------+
void OrderExecution::SetMultiOrderParams(double reduction, double partialClose, int trailingStart, int trailingStep, int maxOrders)
  {
   m_orderReduction = reduction;
   m_partialClosePercent = partialClose;
   m_maxOrdersPerCycle = maxOrders;

// IMPORTANTE: Los valores vienen en PIPS, no en puntos
   if(IsForexPair())
     {
      // Para forex, usar directamente como pips
      m_trailingStages[0].activationPips = trailingStart;
      m_trailingStages[0].trailingPips = trailingStep;

      Print("Trailing configurado desde inputs:");
      Print("  Activación: ", trailingStart, " pips");
      Print("  Distancia: ", trailingStep, " pips");
     }
   else
     {
      // Para otros instrumentos, convertir si es necesario
      m_trailingStart = trailingStart;
      m_trailingDistance = trailingStep;
     }
  }

//+------------------------------------------------------------------+
//| Configurar parámetros emocionales                                |
//+------------------------------------------------------------------+
void OrderExecution::SetEmotionalParams(double fearThreshold, double greedThreshold, double emotionalReduction)
  {
   m_fearThreshold = fearThreshold;
   m_greedThreshold = greedThreshold;
   m_emotionalReduction = emotionalReduction;
  }

//+------------------------------------------------------------------+
//| NUEVO: Configurar parámetros de trailing desde inputs           |
//+------------------------------------------------------------------+
void OrderExecution::SetTrailingInputParams(double startPercent, double stepPercent, bool useATR, double atrStart)
  {
   m_trailingStartPercent = startPercent;
   m_trailingStepPercent = stepPercent;
   m_useATRTrailing = useATR;
   m_trailingStartATR = atrStart;

   Print("Trailing inputs configurados: Start=", startPercent, "% Step=", stepPercent,
         "% UseATR=", useATR, " ATRStart=", atrStart);
  }

//+------------------------------------------------------------------+
//| NUEVO: Normalizar puntos a pips                                |
//+------------------------------------------------------------------+
double OrderExecution::NormalizeToPips(double points)
  {
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
// Para 5 o 3 dígitos, 10 puntos = 1 pip
   return points / (digits == 5 || digits == 3 ? 10.0 : 1.0);
  }

//+------------------------------------------------------------------+
//| NUEVO: Detectar si es par forex                                |
//+------------------------------------------------------------------+
bool OrderExecution::IsForexPair()
  {
   string symbol = _Symbol;
// Buscar las principales divisas
   if(StringFind(symbol, "USD") >= 0 || StringFind(symbol, "EUR") >= 0 ||
      StringFind(symbol, "GBP") >= 0 || StringFind(symbol, "JPY") >= 0 ||
      StringFind(symbol, "CHF") >= 0 || StringFind(symbol, "CAD") >= 0 ||
      StringFind(symbol, "AUD") >= 0 || StringFind(symbol, "NZD") >= 0)
     {
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| NUEVO: Obtener umbral de activación adaptativo                  |
//+------------------------------------------------------------------+
double OrderExecution::GetAdaptiveActivationThreshold(int stage)
  {
   if(stage < 0 || stage >= 5)
      return 100;
   double baseThreshold = m_trailingStages[stage].activationPips;
   if(m_useATRTrailing && m_currentATR > 0)
     {
      double atrInPips = PointsToPips(m_currentATR / _Point);
      baseThreshold = atrInPips * m_trailingStages[stage].atrMultiplier;
     }
   if(IsForexPair())
      baseThreshold *= 0.5;
   return baseThreshold;
  }



//+------------------------------------------------------------------+
//| NUEVO: Inicializar configuración de lote inteligente            |
//+------------------------------------------------------------------+
void OrderExecution::InitializeLotConfig()
  {
// Multiplicadores base
   m_lotConfig.minRiskMultiplier = 0.1;
   m_lotConfig.maxRiskMultiplier = 1.0;

// Pesos de componentes (deben sumar 1.0)
   m_lotConfig.consensusWeight = 0.4;
   m_lotConfig.convictionWeight = 0.3;
   m_lotConfig.emotionalWeight = 0.2;
   m_lotConfig.metaLearningWeight = 0.1;

// Umbrales de confianza
   m_lotConfig.highConfidenceThreshold = 0.8;
   m_lotConfig.lowConfidenceThreshold = 0.3;

// Ajustes emocionales
   m_lotConfig.fearReductionFactor = 0.5;
   m_lotConfig.greedBoostFactor = 1.2;
   m_lotConfig.uncertaintyPenalty = 0.3;
  }

//+------------------------------------------------------------------+
//| Inicializar configuración de trailing MEJORADO PARA FOREX       |
//+------------------------------------------------------------------+
void OrderExecution::InitializeTrailingConfig()
  {
   bool isForex = IsForexPair();

   if(isForex)
     {
      // Etapa 1: Protección inicial (15 pips para activar, 10 pips trailing)
      m_trailingStages[0].activationPips = 30.0; // CORREGIDO: de 15 a 30 pips
      m_trailingStages[0].trailingPips = 20.0; // CORREGIDO: de 10 a 20 pips
      m_trailingStages[0].stepPips = 2.0;
      m_trailingStages[0].useATR = true;
      m_trailingStages[0].atrMultiplier = 1.5;

      // Etapa 2: Protección media (30 pips para activar, 15 pips trailing)
      m_trailingStages[1].activationPips = 30.0;
      m_trailingStages[1].trailingPips = 15.0;
      m_trailingStages[1].stepPips = 3.0;
      m_trailingStages[1].useATR = true;
      m_trailingStages[1].atrMultiplier = 1.2;

      // Etapa 3: Runner (50 pips para activar, 20 pips trailing)
      m_trailingStages[2].activationPips = 50.0;
      m_trailingStages[2].trailingPips = 20.0;
      m_trailingStages[2].stepPips = 5.0;
      m_trailingStages[2].useATR = true;
      m_trailingStages[2].atrMultiplier = 1.0;

      // Etapa 3 - MOMENTUM (agresiva)
      m_trailingStages[3].activationPips = m_trailingStages[2].activationPips + 50.0;
      m_trailingStages[3].trailingPips    = m_trailingStages[2].trailingPips + 20.0;
      m_trailingStages[3].stepPips        = m_trailingStages[2].stepPips + 5.0;
      m_trailingStages[3].useATR          = true;
      m_trailingStages[3].atrMultiplier   = m_trailingStages[2].atrMultiplier + 0.5;

      // Etapa 4 - CUSTOM (según régimen)
      m_trailingStages[4].activationPips = m_trailingStages[3].activationPips + 80.0;
      m_trailingStages[4].trailingPips    = m_trailingStages[3].trailingPips + 30.0;
      m_trailingStages[4].stepPips        = m_trailingStages[3].stepPips + 5.0;
      m_trailingStages[4].useATR          = true;
      m_trailingStages[4].atrMultiplier   = m_trailingStages[3].atrMultiplier + 1.0;
     }
   else
     {
      // Para índices/commodities (valores en puntos)
      m_trailingStages[0].activationPips = 100.0;
      m_trailingStages[0].trailingPips = 80.0;
      m_trailingStages[0].stepPips = 10.0;
      m_trailingStages[0].useATR = true;
      m_trailingStages[0].atrMultiplier = 1.5;

      m_trailingStages[1].activationPips = 200.0;
      m_trailingStages[1].trailingPips = 100.0;
      m_trailingStages[1].stepPips = 20.0;
      m_trailingStages[1].useATR = true;
      m_trailingStages[1].atrMultiplier = 1.2;

      m_trailingStages[2].activationPips = 300.0;
      m_trailingStages[2].trailingPips = 150.0;
      m_trailingStages[2].stepPips = 30.0;
      m_trailingStages[2].useATR = true;
      m_trailingStages[2].atrMultiplier = 1.0;

      // Etapa 3 - MOMENTUM (agresiva)
      m_trailingStages[3].activationPips = m_trailingStages[2].activationPips + 50.0;
      m_trailingStages[3].trailingPips    = m_trailingStages[2].trailingPips + 20.0;
      m_trailingStages[3].stepPips        = m_trailingStages[2].stepPips + 5.0;
      m_trailingStages[3].useATR          = true;
      m_trailingStages[3].atrMultiplier   = m_trailingStages[2].atrMultiplier + 0.5;

      // Etapa 4 - CUSTOM (según régimen)
      m_trailingStages[4].activationPips = m_trailingStages[3].activationPips + 80.0;
      m_trailingStages[4].trailingPips    = m_trailingStages[3].trailingPips + 30.0;
      m_trailingStages[4].stepPips        = m_trailingStages[3].stepPips + 5.0;
      m_trailingStages[4].useATR          = true;
      m_trailingStages[4].atrMultiplier   = m_trailingStages[3].atrMultiplier + 1.0;
     }

   Print("Trailing configurado para ", (isForex ? "FOREX" : "OTROS"));

// NUEVO: Ajustar trailing de forma más específica por instrumento
   AdjustTrailingForInstrument();
   for(int i = 0; i < 3; i++)
     {
      Print("Etapa ", i+1, ": Activación=", m_trailingStages[i].activationPips,
            " pips, Distancia=", m_trailingStages[i].trailingPips, " pips");
     }
  }

//+------------------------------------------------------------------+
//| Ejecutar orden de compra                                        |
//+------------------------------------------------------------------+
bool COrderExecution::Buy(double volume, double sl = 0, double tp = 0)
{
    // Validar y normalizar volumen
    volume = NormalizeVolume(volume);
    if(!ValidateVolume(volume))
    {
        Print("Error: Volumen inválido: ", volume);
        return false;
    }
    
    // Obtener precio actual
    double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    // Validar niveles de stop
    if(!ValidateStopLevels(price, sl, tp, ORDER_TYPE_BUY))
    {
        Print("Error: Niveles de stop inválidos");
        return false;
    }
    
    // Preparar solicitud
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = volume;
    request.type = ORDER_TYPE_BUY;
    request.price = price;
    request.sl = NormalizeDouble(sl, _Digits);
    request.tp = NormalizeDouble(tp, _Digits);
    request.deviation = m_slippage;
    request.magic = m_magicNumber;
    request.comment = "Buy Order";
    request.type_filling = ORDER_FILLING_IOC;
    
    // Intentar ejecutar con reintentos
    for(int i = 0; i < m_maxRetries; i++)
    {
        if(OrderSend(request, result))
        {
            if(result.retcode == TRADE_RETCODE_DONE)
            {
                Print("COMPRA exitosa - Ticket: ", result.order, 
                      " Volumen: ", volume, 
                      " Precio: ", result.price);
                return true;
            }
        }
        
        // Si falla, actualizar precio y reintentar
        Sleep(500);
        request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    }
    
    Print("Error ejecutando COMPRA - Error: ", GetLastError(), 
          " Retcode: ", result.retcode);
    return false;
}

//+------------------------------------------------------------------+
//| Ejecutar orden de venta                                         |
//+------------------------------------------------------------------+
bool COrderExecution::Sell(double volume, double sl = 0, double tp = 0)
{
    // Validar y normalizar volumen
    volume = NormalizeVolume(volume);
    if(!ValidateVolume(volume))
    {
        Print("Error: Volumen inválido: ", volume);
        return false;
    }
    
    // Obtener precio actual
    double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // Validar niveles de stop
    if(!ValidateStopLevels(price, sl, tp, ORDER_TYPE_SELL))
    {
        Print("Error: Niveles de stop inválidos");
        return false;
    }
    
    // Preparar solicitud
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = volume;
    request.type = ORDER_TYPE_SELL;
    request.price = price;
    request.sl = NormalizeDouble(sl, _Digits);
    request.tp = NormalizeDouble(tp, _Digits);
    request.deviation = m_slippage;
    request.magic = m_magicNumber;
    request.comment = "Sell Order";
    request.type_filling = ORDER_FILLING_IOC;
    
    // Intentar ejecutar con reintentos
    for(int i = 0; i < m_maxRetries; i++)
    {
        if(OrderSend(request, result))
        {
            if(result.retcode == TRADE_RETCODE_DONE)
            {
                Print("VENTA exitosa - Ticket: ", result.order, 
                      " Volumen: ", volume, 
                      " Precio: ", result.price);
                return true;
            }
        }
        
        // Si falla, actualizar precio y reintentar
        Sleep(500);
        request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    }
    
    Print("Error ejecutando VENTA - Error: ", GetLastError(), 
          " Retcode: ", result.retcode);
    return false;
}

//+------------------------------------------------------------------+
//| Cerrar posición específica                                      |
//+------------------------------------------------------------------+
bool COrderExecution::ClosePosition(ulong ticket)
{
    if(!PositionSelectByTicket(ticket))
    {
        Print("Error: No se puede seleccionar posición ", ticket);
        return false;
    }
    
    // Preparar solicitud de cierre
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.position = ticket;
    request.symbol = PositionGetString(POSITION_SYMBOL);
    request.volume = PositionGetDouble(POSITION_VOLUME);
    request.deviation = m_slippage;
    request.magic = m_magicNumber;
    request.comment = "Close Position";
    
    // Determinar tipo de orden de cierre
    ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    if(posType == POSITION_TYPE_BUY)
    {
        request.type = ORDER_TYPE_SELL;
        request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    }
    else
    {
        request.type = ORDER_TYPE_BUY;
        request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    }
    
    request.type_filling = ORDER_FILLING_IOC;
    
    // Intentar cerrar con reintentos
    for(int i = 0; i < m_maxRetries; i++)
    {
        if(OrderSend(request, result))
        {
            if(result.retcode == TRADE_RETCODE_DONE)
            {
                Print("Posición cerrada exitosamente - Ticket: ", ticket);
                return true;
            }
        }
        
        // Actualizar precio si falla
        Sleep(500);
        if(posType == POSITION_TYPE_BUY)
            request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        else
            request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    }
    
    Print("Error cerrando posición ", ticket, " - Error: ", GetLastError());
    return false;
}

//+------------------------------------------------------------------+
//| Cerrar todas las posiciones                                     |
//+------------------------------------------------------------------+
bool COrderExecution::CloseAllPositions() {
   bool allClosed = true;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket!=0 && PositionSelectByTicket(ticket))
      {
         if((long)PositionGetInteger(POSITION_MAGIC) == (long)m_magicNumber &&
            PositionGetString(POSITION_SYMBOL) == _Symbol)
         {
            ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            MqlTradeRequest request;
            MqlTradeResult  result;
            ZeroMemory(request);
            ZeroMemory(result);
            request.action = TRADE_ACTION_DEAL;
            request.symbol = _Symbol;
            request.position = ticket;
            request.deviation = m_slippage;
            request.magic = m_magicNumber;
            if(posType == POSITION_TYPE_BUY)
            {
               request.type = ORDER_TYPE_SELL;
               request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            }
            else
            {
               request.type = ORDER_TYPE_BUY;
               request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            }
            request.type_filling = ORDER_FILLING_IOC;
            if(OrderSend(request, result))
            {
               if(result.retcode != TRADE_RETCODE_DONE)
               {
                  allClosed = false;
               }
            }
            else
            {
               allClosed = false;
            }
         }
      }
   }
   return allClosed;
}

//+------------------------------------------------------------------+
//| Modificar posición                                              |
//+------------------------------------------------------------------+
bool COrderExecution::ModifyPosition(ulong ticket, double sl, double tp)
{
    if(!PositionSelectByTicket(ticket))
    {
        return false;
    }
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_SLTP;
    request.position = ticket;
    request.symbol = PositionGetString(POSITION_SYMBOL);
    request.sl = NormalizeDouble(sl, _Digits);
    request.tp = NormalizeDouble(tp, _Digits);
    request.magic = m_magicNumber;
    
    if(OrderSend(request, result))
    {
        if(result.retcode == TRADE_RETCODE_DONE)
        {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Obtener número de posiciones abiertas                           |
//+------------------------------------------------------------------+
int COrderExecution::GetOpenPositionsCount() {
   int count = 0;
   for(int i = 0; i < PositionsTotal(); ++i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket!=0 && PositionSelectByTicket(ticket))
      {
         if((long)PositionGetInteger(POSITION_MAGIC) == (long)m_magicNumber &&
            PositionGetString(POSITION_SYMBOL) == _Symbol)
         {
            ++count;
         }
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Obtener profit total                                            |
//+------------------------------------------------------------------+
double COrderExecution::GetTotalProfit() {
   double totalProfit = 0.0;
   for(int i = 0; i < PositionsTotal(); ++i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket!=0 && PositionSelectByTicket(ticket))
      {
         if((long)PositionGetInteger(POSITION_MAGIC) == (long)m_magicNumber &&
            PositionGetString(POSITION_SYMBOL) == _Symbol)
         {
            totalProfit += PositionGetDouble(POSITION_PROFIT);
         }
      }
   }
   return totalProfit;
}

//+------------------------------------------------------------------+
//| Validar volumen                                                 |
//+------------------------------------------------------------------+
bool COrderExecution::ValidateVolume(double volume)
{
    if(volume < m_minLotSize || volume > m_maxLotSize)
    {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Normalizar volumen                                              |
//+------------------------------------------------------------------+
double COrderExecution::NormalizeVolume(double volume)
{
    double normalizedVolume = MathRound(volume / m_lotStep) * m_lotStep;
    
    if(normalizedVolume < m_minLotSize)
        normalizedVolume = m_minLotSize;
    if(normalizedVolume > m_maxLotSize)
        normalizedVolume = m_maxLotSize;
    
    return NormalizeDouble(normalizedVolume, 2);
}

//+------------------------------------------------------------------+
//| Validar precio                                                  |
//+------------------------------------------------------------------+
bool COrderExecution::ValidatePrice(double price)
{
    if(price <= 0)
    {
        return false;
    }
    
    double minPrice = SymbolInfoDouble(_Symbol, SYMBOL_SESSION_PRICE_LIMIT_MIN);
    double maxPrice = SymbolInfoDouble(_Symbol, SYMBOL_SESSION_PRICE_LIMIT_MAX);
    
    if(minPrice != 0 && price < minPrice)
        return false;
    if(maxPrice != 0 && price > maxPrice)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Validar niveles de stop                                         |
//+------------------------------------------------------------------+
bool COrderExecution::ValidateStopLevels(double price, double sl, double tp, ENUM_ORDER_TYPE orderType)
{
    int stopLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double minDistance = stopLevel * point;
    
    if(sl != 0)
    {
        if(orderType == ORDER_TYPE_BUY)
        {
            if(price - sl < minDistance)
            {
                Print("SL muy cerca del precio de entrada");
                return false;
            }
        }
        else // SELL
        {
            if(sl - price < minDistance)
            {
                Print("SL muy cerca del precio de entrada");
                return false;
            }
        }
    }
    
    if(tp != 0)
    {
        if(orderType == ORDER_TYPE_BUY)
        {
            if(tp - price < minDistance)
            {
                Print("TP muy cerca del precio de entrada");
                return false;
            }
        }
        else // SELL
        {
            if(price - tp < minDistance)
            {
                Print("TP muy cerca del precio de entrada");
                return false;
            }
        }
    }
    
    return true;
}


//+------------------------------------------------------------------+
//| Reset del ciclo multi-orden                                     |
//+------------------------------------------------------------------+
void OrderExecution::ResetMultiOrderCycle()
  {
   for(int i = 0; i < 10; i++)
     {
      m_multiOrder.tickets[i] = 0;
      m_multiOrder.lotSizes[i] = 0;
      m_multiOrder.entryPrices[i] = 0;
      m_multiOrder.stopLosses[i] = 0;
      m_multiOrder.takeProfits[i] = 0;
      m_multiOrder.consensus_ids[i] = 0;
      m_multiOrder.maxDrawdown = 0.0;
      m_multiOrder.dissenting_agents = 0;
     }

   m_multiOrder.orderCount = 0;
   m_multiOrder.cycleActive = false;
   m_multiOrder.direction = DIRECTION_NONE;
   m_multiOrder.baseLotSize = 0;
   m_multiOrder.cycleStartTime = 0;
   m_multiOrder.totalPartialClosed = 0;
   m_multiOrder.cycleProfit = 0;
   m_multiOrder.consensusStrength = 0;
   m_multiOrder.emotionalContext = 0.5;
   m_multiOrder.emotionalAlerts = 0;
   m_multiOrder.maxFearLevel = 0;
   m_multiOrder.avgConviction = 0;
   m_multiOrder.initial_consensus_id = 0;

// NUEVO: Reset trailing sincronizado
   m_multiOrder.cycleTrailingActive = false;
   m_multiOrder.cycleTrailingLevel = 0;
   m_multiOrder.cycleTrailingActivationPrice = 0;
   m_multiOrder.cycleLastTrailingUpdate = 0;
   m_multiOrder.cycleMaxProfit = 0;
  }

//+------------------------------------------------------------------+
//| Configurar parámetros de trailing dinámico                      |
//+------------------------------------------------------------------+
void OrderExecution::SetDynamicTrailingParams(bool useDynamic, double atrPeriod)
  {
   m_useDynamicTrailing = useDynamic;
   m_trailingATRPeriod = MathMax(5, MathMin(50, atrPeriod));

   Print("OrderExecution: Trailing dinámico ", (useDynamic ? "ACTIVADO" : "DESACTIVADO"));
   if(useDynamic)
     {
      Print("  Período ATR: ", m_trailingATRPeriod);
     }
  }

//+------------------------------------------------------------------+
//| Configurar etapa de trailing específica                         |
//+------------------------------------------------------------------+
void OrderExecution::ConfigureTrailingStage(int stage, int activation, int distance,
      double protection, bool useATR, double atrMult)
  {
   if(stage < 0 || stage > 2)
      return;

   m_trailingStages[stage].activationPips = activation;
   m_trailingStages[stage].trailingPips = distance;
   m_trailingStages[stage].stepPips = MathMax(1.0, protection * 10);
   m_trailingStages[stage].useATR = useATR;
   m_trailingStages[stage].atrMultiplier = MathMax(0.5, MathMin(3.0, atrMult));

   Print("Trailing Etapa ", stage+1, " configurada: ",
         "Act=", activation, " Dist=", distance, " Step=", m_trailingStages[stage].stepPips);
  }

//+------------------------------------------------------------------+
//| MEJORADO: Calcular tamaño de lote con sistema inteligente      |
//+------------------------------------------------------------------+
double OrderExecution::CalculateLotSize(double stopDistance, double conviction)
  {
   if(stopDistance <= 0 || m_accountEquity <= 0)
      return 0;

// 1. Calcular riesgo base del balance (ahora con 5% máximo)
   double baseRiskAmount = m_accountEquity * (m_riskPercent / 100.0);

// 2. Usar el nuevo sistema de cálculo inteligente
   double finalLot = CalculateIntelligentLotSize(baseRiskAmount, stopDistance);

// 3. Log detallado del cálculo (solo si hay convicción significativa)
   if(conviction > 0.2)
     {
      PrintLotCalculationDetails(finalLot);
     }

   return finalLot;
  }

//+------------------------------------------------------------------+
//| NUEVO SISTEMA DE LOTAJE INTELIGENTE                            |
//+------------------------------------------------------------------+
double OrderExecution::CalculateIntelligentLotSize(double baseRisk, double stopDistance)
  {
// 1. CÁLCULO BASE FIJO (No se toca)
   double pipValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(pipValue <= 0)
      pipValue = 1.0;

   double baseLot = baseRisk / (stopDistance * pipValue);

// 2. AJUSTE POR CONFIANZA (Máximo ±30%)
   double confidenceAdjustment = CalculateConfidenceMultiplier();

// 3. AJUSTE POR CONTEXTO DE MERCADO (Máximo ±10%)
   double marketAdjustment = 1.0;

// Solo en volatilidad extrema
   if(m_volatilityRatio > 2.5)
      marketAdjustment = 0.90;
   else
      if(m_volatilityRatio < 0.5)
         marketAdjustment = 1.10;

// 4. SEGURIDAD EMOCIONAL (Solo en casos extremos)
   double emotionalSafety = 1.0;
   if(m_currentEmotion.fear > 0.9)  // Solo miedo EXTREMO
      emotionalSafety = 0.80;

// 5. CÁLCULO FINAL
   double finalMultiplier = confidenceAdjustment * marketAdjustment * emotionalSafety;

// Ajuste total (mínimo 0.5x, max 1.5x)
   finalMultiplier = MathMax(0.5, MathMin(1.5, finalMultiplier));

   double finalLot = baseLot * finalMultiplier;

// 6. NORMALIZACIÓN
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

// Asegurar mínimo razonable
   double reasonableMin = minLot;

   finalLot = MathMax(reasonableMin, MathMin(m_maxLotSize, finalLot));
   finalLot = MathRound(finalLot / stepLot) * stepLot;

// 7. LOG CLARO Y TRANSPARENTE
   double actualRiskPercent = (finalLot * stopDistance * pipValue) / m_accountEquity * 100.0;

   Print("=== CÁLCULO DE LOTE INTELIGENTE ===");
   Print("Equity : $", DoubleToString(m_accountEquity, 2));
   Print("Riesgo configurado: ", DoubleToString(m_riskPercent, 1), "%");
   Print("Riesgo real: ", DoubleToString(actualRiskPercent, 2), "%");
   Print("Ajustes aplicados:");
   Print("  * Confianza: x", DoubleToString(confidenceAdjustment, 2),
         " (Consenso: ", DoubleToString(m_lastConsensusStrength, 2), ")");
   if(marketAdjustment != 1.0)
      Print("  * Mercado: x", DoubleToString(marketAdjustment, 2));
   if(emotionalSafety != 1.0)
      Print("  * Seguridad: x", DoubleToString(emotionalSafety, 2));
   Print("Multiplicador total: x", DoubleToString(finalMultiplier, 2));
   Print("Lote final: ", DoubleToString(finalLot, 3));
   Print("===================================");

   return finalLot;
  }

//+------------------------------------------------------------------+
//| NUEVO: Calcular multiplicador de confianza                      |
//+------------------------------------------------------------------+
double OrderExecution::CalculateConfidenceMultiplier()
  {
// Componente 1: Consenso (40%)
   double consensusComponent = m_lastConsensusStrength * m_lotConfig.consensusWeight;

// Componente 2: Convicción (30%)
   double convictionComponent = m_lastTotalConviction * m_lotConfig.convictionWeight;

// Componente 3: Confianza combinada
   double combinedConfidence = consensusComponent + convictionComponent;

// Aplicar curva de confianza no lineal
   double confidenceMultiplier;

   if(combinedConfidence >= m_lotConfig.highConfidenceThreshold)
     {
      confidenceMultiplier = 1.3;
     }
   else
      if(combinedConfidence >= m_lotConfig.lowConfidenceThreshold)
        {
         confidenceMultiplier = 1.0;
        }
      else
        {
         confidenceMultiplier = 0.7;
        }

// Ajuste adicional basado en MetaLearning si está disponible
   double metaBoost = GetMetaLearningBoost();
   confidenceMultiplier *= metaBoost;

// Limitar el multiplicador
   confidenceMultiplier = MathMax(m_lotConfig.minRiskMultiplier,
                                  MathMin(m_lotConfig.maxRiskMultiplier, confidenceMultiplier));

   return confidenceMultiplier;
  }

//+------------------------------------------------------------------+
//| NUEVO: Calcular ajuste emocional                               |
//+------------------------------------------------------------------+
double OrderExecution::CalculateEmotionalAdjustment()
  {
   double adjustment = 1.0;

   if(m_currentEmotion.fear > m_fearThreshold)
     {
      adjustment *= m_lotConfig.fearReductionFactor;
     }
   if(m_currentEmotion.greed > m_greedThreshold)
     {
      adjustment *= m_lotConfig.greedBoostFactor;
     }
   if(m_currentEmotion.uncertainty > 0.8)
     {
      adjustment *= (1.0 - m_lotConfig.uncertaintyPenalty);
     }

   return adjustment;
  }

//+------------------------------------------------------------------+
//| NUEVO: Obtener boost de MetaLearning                           |
//+------------------------------------------------------------------+
double OrderExecution::GetMetaLearningBoost()
  {
   return 1.0; // Sin boost por defecto
  }

//+------------------------------------------------------------------+
//| Normalizar tamaño de lote                                       |
//+------------------------------------------------------------------+
double OrderExecution::NormalizeLotSize(double lot)
  {
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   lot = MathMax(minLot, MathMin(maxLot, lot));
   lot = MathRound(lot / stepLot) * stepLot;

   return lot;
  }

//+------------------------------------------------------------------+
//| Imprimir detalles del cálculo de lote                           |
//+------------------------------------------------------------------+
void OrderExecution::PrintLotCalculationDetails(double finalLot)
  {
   Print("Detalles del cálculo de lote:");
   Print("  Lote final: ", DoubleToString(finalLot, 3));
   Print("  Consenso: ", DoubleToString(m_lastConsensusStrength, 2));
   Print("  Convicción: ", DoubleToString(m_lastTotalConviction, 2));
  }

//+------------------------------------------------------------------+
//| NUEVA FUNCIÓN: Calcular distancia óptima de trailing            |
//+------------------------------------------------------------------+
double OrderExecution::CalculateOptimalTrailingDistance()
  {
   double basePips = 40.0; // Por defecto 25 pips - CORREGIDO

// Calcular profit actual en pips
   double avgProfitPips = 0;
   int validOrders = 0;
   int ordersInProfit = 0; // ✅ NUEVO: Contar órdenes en profit

   for(int i = 0; i < m_multiOrder.orderCount; i++)
     {
      if(m_multiOrder.tickets[i] > 0 && PositionSelectByTicket(m_multiOrder.tickets[i]))
        {
         double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         int posType = (int)PositionGetInteger(POSITION_TYPE);
         int direction = (posType == POSITION_TYPE_BUY) ? 1 : -1;

         avgProfitPips += CalculateProfitInPips(entryPrice, currentPrice, direction);
         validOrders++;
        }
     }

   if(validOrders > 0)
      avgProfitPips /= validOrders;

// Determinar etapa según profit
   int stage = -1;
   if(avgProfitPips >= 120)
      stage = 2;      // Runner - CORREGIDO
   else
      if(avgProfitPips >= 80)
         stage = 1; // Medio - CORREGIDO
      else
         if(avgProfitPips >= 50)
            stage = 0; // Inicial - CORREGIDO

   if(stage >= 0)
     {
      basePips = m_trailingStages[stage].trailingPips;

      // Si usa ATR, ajustar
      if(m_trailingStages[stage].useATR && m_currentATR > 0)
        {
         double atrPips = PointsToPips(m_currentATR / _Point);
         basePips = atrPips * m_trailingStages[stage].atrMultiplier;
        }
     }

// Ajustes por contexto emocional
   if(m_currentEmotion.fear > 0.7)
      basePips *= 0.8; // Más ajustado si hay miedo
   else
      if(m_currentEmotion.greed > 0.7)
         basePips *= 1.2; // Más amplio si hay codicia

// Límites razonables para forex
   basePips = MathMax(40.0, MathMin(100.0, basePips)); // ✅ Mínimo 40 pips

   return basePips;
  }

//+------------------------------------------------------------------+
//| Actualizar ATR                                                 |
//+------------------------------------------------------------------+
void OrderExecution::UpdateATR()
  {
   int atr_handle = iATR(_Symbol, PERIOD_CURRENT, 14);
   if(atr_handle != INVALID_HANDLE)
     {
      double atr_buffer[];
      if(CopyBuffer(atr_handle, 0, 0, 1, atr_buffer) > 0)
        {
         m_currentATR = atr_buffer[0];
        }
      IndicatorRelease(atr_handle);
     }

   if(m_currentATR <= 0)
     {
      m_currentATR = 50 * _Point;
     }
  }

//+------------------------------------------------------------------+
//| Actualizar información de cuenta                                |
//+------------------------------------------------------------------+
void OrderExecution::UpdateAccountInfo()
  {
   m_accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
  }

//+------------------------------------------------------------------+
//| Actualizar contexto de mercado                                  |
//+------------------------------------------------------------------+
void OrderExecution::UpdateMarketContext()
  {
   double atrRatio = 1.0;
   m_volatilityRatio = atrRatio;
   int atr_handle = iATR(_Symbol, PERIOD_CURRENT, 14);
   if(atr_handle != INVALID_HANDLE)
     {
      double atr_buffer[];
      if(CopyBuffer(atr_handle, 0, 0, 20, atr_buffer) == 20)
        {
         double avgATR = 0;
         for(int i = 0; i < 20; i++)
            avgATR += atr_buffer[i];
         avgATR /= 20.0;

         if(avgATR > 0)
            atrRatio = m_currentATR / avgATR;
        }
      IndicatorRelease(atr_handle);
     }

   if(atrRatio > 1.5)
      m_marketContext = CONTEXT_HIGH_VOL;
   else
      if(atrRatio < 0.7)
         m_marketContext = CONTEXT_ACCUMULATION;
      else
         m_marketContext = CONTEXT_NORMAL;

   if(m_currentEmotion.fear > m_fearThreshold)
      m_marketContext = CONTEXT_FEARFUL;
   else
      if(m_currentEmotion.greed > m_greedThreshold)
         m_marketContext = CONTEXT_GREEDY;
  }

//+------------------------------------------------------------------+
//| Validar ejecución                                              |
//+------------------------------------------------------------------+
bool OrderExecution::ValidateExecution(double price, double lot)
  {
   if(!TerminalInfoInteger(TERMINAL_CONNECTED) ||
      !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
     {
      LogExecutionEvent("Terminal no conectado o trading no permitido");
      return false;
     }

   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
     {
      LogExecutionEvent("Trading no permitido en este EA");
      return false;
     }

   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   if(lot < minLot || lot > maxLot)
     {
      LogExecutionEvent("Lot size fuera de rango: " + DoubleToString(lot, 3));
      return false;
     }

   if(price <= 0)
     {
      LogExecutionEvent("Precio inválido: " + DoubleToString(price, _Digits));
      return false;
     }

   double margin_required = 0;
   if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lot, price, margin_required))
     {
      LogExecutionEvent("Error calculando margen");
      return false;
     }

   if(margin_required > AccountInfoDouble(ACCOUNT_MARGIN_FREE))
     {
      LogExecutionEvent("Margen insuficiente");
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Registrar evento de ejecución                                   |
//+------------------------------------------------------------------+
void OrderExecution::LogExecutionEvent(string message)
  {
   string logMessage = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) +
                       " [OrderExecution v11.03] " + message;
   Print(logMessage);
  }

//+------------------------------------------------------------------+
//| Obtener precio actualizado                                     |
//+------------------------------------------------------------------+
double OrderExecution::GetUpdatedPrice(int direction)
  {
   if(direction > 0)
      return SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   else
      return SymbolInfoDouble(_Symbol, SYMBOL_BID);
  }

//+------------------------------------------------------------------+
//| Calcular slippage dinámico                                      |
//+------------------------------------------------------------------+
int OrderExecution::CalculateDynamicSlippage()
  {
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   int baseSlippage = (int)MathMax(10, spread * 2);

   if(m_marketContext == CONTEXT_HIGH_VOL || m_currentEmotion.excitement > 0.7)
      baseSlippage *= 2;

   return MathMin(50, baseSlippage);
  }

//+------------------------------------------------------------------+
//| Calcular puntuación emocional                                   |
//+------------------------------------------------------------------+
double OrderExecution::CalculateEmotionalScore()
  {
   double score = (m_currentEmotion.fear * 0.4 +
                   m_currentEmotion.greed * 0.3 +
                   m_currentEmotion.uncertainty * 0.2 +
                   m_currentEmotion.excitement * 0.1);

   return score;
  }

//+------------------------------------------------------------------+
//| Registrar evento emocional                                      |
//+------------------------------------------------------------------+
void OrderExecution::LogEmotionalEvent(string event, double score)
  {
   string message = "EVENTO EMOCIONAL: " + event + " (Score: " + DoubleToString(score, 3) + ")";
   LogExecutionEvent(message);
  }

//+------------------------------------------------------------------+
//| Imprimir estado emocional                                       |
//+------------------------------------------------------------------+
void OrderExecution::PrintEmotionalStatus()
  {
   Print("=== ESTADO EMOCIONAL - ORDEREXECUTION ===");
   Print("Fear: ", DoubleToString(m_currentEmotion.fear, 3));
   Print("Greed: ", DoubleToString(m_currentEmotion.greed, 3));
   Print("Uncertainty: ", DoubleToString(m_currentEmotion.uncertainty, 3));
   Print("Excitement: ", DoubleToString(m_currentEmotion.excitement, 3));
   Print("Contexto: ", EnumToString(m_marketContext));
   Print("Multiplicador emocional: ", DoubleToString(GetEmotionalMultiplier(), 2));

   if(m_multiOrder.cycleActive)
     {
      Print("Ciclo - Alertas emocionales: ", m_multiOrder.emotionalAlerts);
      Print("Ciclo - Max fear: ", DoubleToString(m_multiOrder.maxFearLevel, 2));
      Print("Ciclo - Contexto promedio: ", DoubleToString(m_multiOrder.emotionalContext, 2));
     }
   Print("========================================");
  }

//+------------------------------------------------------------------+
//| Ejecutar orden de mercado                                       |
//+------------------------------------------------------------------+
bool OrderExecution::ExecuteMarketOrder(int direction, double lotSize,
                                        double entryPrice, double stopPrice, double tpPrice)
  {
   m_trade.SetExpertMagicNumber(m_magicNumber);
   m_trade.SetDeviationInPoints(CalculateDynamicSlippage());
   m_trade.SetTypeFilling(ORDER_FILLING_IOC);

   bool success = false;
// SL SIEMPRE: si no se especifica stopPrice, calcular uno seguro por ATR/PIPs
   if(stopPrice <= 0.0)
     {
      double atr = GetATRValue(PERIOD_CURRENT);
      double basePips = 0.0;
      if(atr > 0)
        {
         double atrPips = PointsToPips(atr / _Point);
         basePips = MathMax(20.0, atrPips * 2.0);
        }
      else
        {
         if(IsForexPair())
            basePips = 30.0;
         else
            basePips = 100.0;
        }
      double dist = PipsToPoints(basePips);
      if(direction > 0)
         stopPrice = entryPrice - dist;
      else
         stopPrice = entryPrice + dist;
      int spreadInt = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      double spreadPts = spreadInt * _Point;
      if(direction > 0)
         stopPrice -= spreadPts;
      else
         stopPrice += spreadPts;
      stopPrice = NormalizeDouble(stopPrice, _Digits);
     }

   string comment = "NCN_v11.03_" + IntegerToString(m_multiOrder.orderCount + 1) +
                    "_E" + DoubleToString(m_multiOrder.emotionalContext, 1);

   if(m_current_consensus_id > 0)
     {
      comment += "_CID" + IntegerToString(m_current_consensus_id);
     }

   if(direction > 0)
     {
      success = m_trade.Buy(lotSize, _Symbol, entryPrice, stopPrice, tpPrice, comment);
     }
   else
     {
      success = m_trade.Sell(lotSize, _Symbol, entryPrice, stopPrice, tpPrice, comment);
     }

   if(success)
     {
      ulong ticket = m_trade.ResultOrder();
      double realPrice = m_trade.ResultPrice();

      int idx = m_multiOrder.orderCount;
      m_multiOrder.tickets[idx] = ticket;
      m_multiOrder.lotSizes[idx] = lotSize;
      m_multiOrder.entryPrices[idx] = realPrice;
      m_multiOrder.stopLosses[idx] = stopPrice;
      m_multiOrder.takeProfits[idx] = tpPrice;

      if(idx == 0)
        {
         m_multiOrder.initial_consensus_id = m_current_consensus_id;
         m_multiOrder.consensus_ids[idx] = m_current_consensus_id;
        }
      else
        {
         m_multiOrder.consensus_ids[idx] = m_multiOrder.initial_consensus_id;
        }

      m_multiOrder.orderCount++;

      if(m_metaLearning != NULL && m_multiOrder.consensus_ids[idx] > 0)
        {
         Print("Orden registrada - Ticket: ", ticket,
               " Consensus ID: ", m_multiOrder.consensus_ids[idx]);
        }

      if(m_closed_count < ArraySize(m_closed_orders))
        {
         m_closed_orders[m_closed_count].ticket = ticket;
         m_closed_orders[m_closed_count].consensus_id = m_multiOrder.consensus_ids[idx];
         m_closed_orders[m_closed_count].profit = 0;
         m_closed_orders[m_closed_count].success = false;
         m_closed_orders[m_closed_count].close_time = 0;
        }

      return true;
     }
   else
     {
      int error = GetLastError();
      LogExecutionEvent("ERROR: " + m_trade.ResultRetcodeDescription() + " (" + IntegerToString(error) + ")");
      LogExecutionEvent("Consensus ID no registrado: " + IntegerToString(m_current_consensus_id));
      return false;
     }
  }

//+------------------------------------------------------------------+
//| Recalcular número de órdenes activas                           |
//+------------------------------------------------------------------+
void OrderExecution::RecalculateActiveOrders()
  {
   int activeCount = 0;

   for(int i = 0; i < 10; i++)
     {
      if(m_multiOrder.tickets[i] > 0)
        {
         if(PositionSelectByTicket(m_multiOrder.tickets[i]))
           {
            activeCount++;
           }
         else
           {
            m_multiOrder.tickets[i] = 0;
            m_multiOrder.lotSizes[i] = 0;
            m_multiOrder.consensus_ids[i] = 0;
           }
        }
     }

   m_multiOrder.orderCount = activeCount;

   LogExecutionEvent("Órdenes activas recalculadas: " + IntegerToString(activeCount));
  }

//+------------------------------------------------------------------+
//| Verificar si la orden está cerrada                              |
//+------------------------------------------------------------------+
bool OrderExecution::CheckOrderClosed(ulong ticket)
  {
   return !PositionSelectByTicket(ticket);
  }

//+------------------------------------------------------------------+
//| Determinar etapa de trailing MEJORADO                          |
//+------------------------------------------------------------------+
int OrderExecution::DetermineTrailingStage(double profitPoints)
  {
// Régimen opcional
   for(int i = 4; i >= 0; --i)
     {
      // Si está en rango, limitar a etapa 1
      double threshold = GetAdaptiveActivationThreshold(i);
      if(profitPoints >= threshold)
        {
         Print("Trailing Stage ", i+1, " activado. Profit: ", profitPoints, " >= Threshold: ", threshold);
         return i;
        }
     }
   return -1;
  }

//+------------------------------------------------------------------+
//| Obtener valor ATR                                              |
//+------------------------------------------------------------------+
double OrderExecution::GetATRValue(ENUM_TIMEFRAMES timeframe)
  {
   int atr_handle = iATR(_Symbol, timeframe, (int)m_trailingATRPeriod);
   if(atr_handle != INVALID_HANDLE)
     {
      double atr_buffer[];
      if(CopyBuffer(atr_handle, 0, 0, 1, atr_buffer) > 0)
        {
         IndicatorRelease(atr_handle);
         return atr_buffer[0];
        }
      IndicatorRelease(atr_handle);
     }

   return m_currentATR > 0 ? m_currentATR : 50 * _Point;
  }

//+------------------------------------------------------------------+
//| Configurar ID de consenso actual                                |
//+------------------------------------------------------------------+
void OrderExecution::SetCurrentConsensusID(ulong consensus_id)
  {
   m_current_consensus_id = consensus_id;
  }

//+------------------------------------------------------------------+
//| Notificar cierre de orden                                       |
//+------------------------------------------------------------------+
void OrderExecution::NotifyOrderClosed(ulong ticket, double profit, bool success)
  {
   ulong consensus_id = 0;
   for(int i = 0; i < 10; i++)
     {
      if(m_multiOrder.tickets[i] == ticket)
        {
         consensus_id = m_multiOrder.consensus_ids[i];
         break;
        }
     }

   if(m_closed_count < ArraySize(m_closed_orders))
     {
      m_closed_orders[m_closed_count].ticket = ticket;
      m_closed_orders[m_closed_count].consensus_id = consensus_id;
      m_closed_orders[m_closed_count].profit = profit;
      m_closed_orders[m_closed_count].success = success;
      m_closed_orders[m_closed_count].close_time = TimeCurrent();
      m_closed_count++;
     }
  }

//+------------------------------------------------------------------+
//| Compactar los arreglos de órdenes dentro de m_multiOrder         |
//+------------------------------------------------------------------+
void OrderExecution::CompactOrderArrays()
  {
   int newIndex = 0;

   for(int i = 0; i < 10; i++)
     {
      if(m_multiOrder.tickets[i] > 0)
        {
         if(i != newIndex)
           {
            m_multiOrder.tickets[newIndex]       = m_multiOrder.tickets[i];
            m_multiOrder.lotSizes[newIndex]      = m_multiOrder.lotSizes[i];
            m_multiOrder.entryPrices[newIndex]   = m_multiOrder.entryPrices[i];
            m_multiOrder.stopLosses[newIndex]    = m_multiOrder.stopLosses[i];
            m_multiOrder.takeProfits[newIndex]   = m_multiOrder.takeProfits[i];
            m_multiOrder.consensus_ids[newIndex] = m_multiOrder.consensus_ids[i];
           }
         newIndex++;
        }
     }

   for(int i = newIndex; i < 10; i++)
     {
      m_multiOrder.tickets[i]       = 0;
      m_multiOrder.lotSizes[i]      = 0;
      m_multiOrder.entryPrices[i]   = 0;
      m_multiOrder.stopLosses[i]    = 0;
      m_multiOrder.takeProfits[i]   = 0;
      m_multiOrder.consensus_ids[i] = 0;
     }

   m_multiOrder.orderCount = newIndex;
  }

//+------------------------------------------------------------------+
//| Ejecutar primera orden                                          |
//+------------------------------------------------------------------+
bool OrderExecution::ExecuteFirstOrder(int direction, double conviction, double touchPrice)
  {
   if(m_multiOrder.cycleActive)
     {
      LogExecutionEvent("Ciclo ya activo, no se puede ejecutar primera orden");
      return false;
     }

   double lotSize = CalculateLotSize(m_trailingDistance * _Point, conviction);
   if(lotSize <= 0)
     {
      LogExecutionEvent("Tamaño de lote inválido");
      return false;
     }

   double entryPrice = touchPrice;
   if(entryPrice <= 0)
      entryPrice = GetUpdatedPrice(direction);

   double stopPrice = CalculateStopLoss(entryPrice, direction);
   double tpPrice = CalculateTakeProfit(entryPrice, direction);

   if(!ValidateExecution(entryPrice, lotSize))
      return false;

   if(ExecuteMarketOrder(direction, lotSize, entryPrice, stopPrice, tpPrice))
     {
      // ✅ CAMBIO CRÍTICO: Guardar precio inicial y timestamp
      m_initialEntryPrice = entryPrice;
      m_lastOrderTime = TimeCurrent();
      
      m_multiOrder.cycleActive = true;
      m_multiOrder.direction = (ENUM_TRADE_DIRECTION)direction;
      m_multiOrder.baseLotSize = lotSize;
      m_multiOrder.cycleStartTime = TimeCurrent();
      m_multiOrder.consensusStrength = m_lastConsensusStrength;
      m_multiOrder.avgConviction = conviction;
      LogExecutionEvent("Primera orden ejecutada. Dirección: " + EnumToString(m_multiOrder.direction));
      return true;
     }

   return false;
  }

// ============================================================================
// CAMBIO 4: Corregir función ExecuteAdditionalOrder
// Ubicación: ~línea 2066
// REEMPLAZAR COMPLETAMENTE LA FUNCIÓN
// ============================================================================
bool OrderExecution::ExecuteAdditionalOrder(int direction, double conviction)
  {
   if(!m_multiOrder.cycleActive || m_multiOrder.orderCount >= m_maxOrdersPerCycle)
     {
      LogExecutionEvent("No se puede añadir orden: Ciclo inactivo o límite alcanzado");
      return false;
     }

   if(direction != m_multiOrder.direction)
     {
      LogExecutionEvent("Dirección inconsistente con el ciclo");
      return false;
     }

   double lotSize = CalculateReducedLotSize(m_multiOrder.orderCount);
   if(lotSize <= 0)
     {
      LogExecutionEvent("Tamaño de lote inválido para orden adicional");
      return false;
     }

   double entryPrice = GetUpdatedPrice(direction);
   double stopPrice = CalculateStopLoss(entryPrice, direction, true);
   double tpPrice = CalculateTakeProfit(entryPrice, direction);

   if(!ValidateExecution(entryPrice, lotSize))
      return false;

   if(ExecuteMarketOrder(direction, lotSize, entryPrice, stopPrice, tpPrice))
     {
      // ✅ CAMBIO CRÍTICO: Guardar precio inicial y timestamp
      m_initialEntryPrice = entryPrice;
      m_lastOrderTime = TimeCurrent();
      
      // ✅ CAMBIO CRÍTICO: Actualizar timestamp
      m_lastOrderTime = TimeCurrent();
      
      m_multiOrder.avgConviction = (m_multiOrder.avgConviction * m_multiOrder.orderCount + conviction) /
                                   (m_multiOrder.orderCount + 1);
      LogExecutionEvent("Orden adicional ejecutada. Total órdenes: " + IntegerToString(m_multiOrder.orderCount) +
                       " Precio: " + DoubleToString(entryPrice, _Digits));
      return true;
     }

   return false;
  }
  
  // ============================================================================
// CAMBIO 5: NUEVA FUNCIÓN - ShouldAddAdditionalOrder
// Ubicación: Después de ExecuteAdditionalOrder (~línea 2104)
// AGREGAR ESTA FUNCIÓN COMPLETA
// ============================================================================
//+------------------------------------------------------------------+
//| Evaluar si se debe agregar una orden adicional                  |
//+------------------------------------------------------------------+
bool OrderExecution::ShouldAddAdditionalOrder()
  {
   // 1. Verificar ciclo activo
   if(!m_multiOrder.cycleActive)
     {
      return false;
     }

   // 2. Verificar límite máximo de órdenes
   if(m_multiOrder.orderCount >= m_maxOrdersPerCycle)
     {
      Print("  ❌ Límite máximo de órdenes alcanzado: ", m_multiOrder.orderCount);
      return false;
     }

   // 3. Verificar tiempo mínimo entre órdenes (5 segundos)
   if(TimeCurrent() - m_lastOrderTime < 5)
     {
      return false;
     }

   // 4. Verificar movimiento mínimo desde entrada inicial (8 puntos)
   if(m_initialEntryPrice == 0)
     {
      Print("  ❌ Precio inicial no guardado");
      return false;
     }

   double currentPrice = (m_multiOrder.direction == DIRECTION_BUY) ?
                        SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                        SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   double movement = MathAbs(currentPrice - m_initialEntryPrice) / _Point;

   Print("🔍 Evaluando orden adicional #", m_multiOrder.orderCount + 1);
   Print("    Movimiento: ", DoubleToString(movement, 1), " puntos");
   Print("    Requerido: 8.0 puntos");

   if(movement < 8.0)
     {
      return false;
     }

   Print("✅ Condición cumplida: Movimiento suficiente");

   // 5. Verificar que al menos 1 orden esté en profit
   int ordersInProfit = 0;
   double totalProfit = 0;
   HasOrdersInProfit(ordersInProfit, totalProfit);

   if(ordersInProfit == 0)
     {
      Print("  ❌ Ninguna orden en profit");
      return false;
     }

   Print("✅ Condiciones cumplidas. Órdenes en profit: ", ordersInProfit);
   return true;
  }

//+------------------------------------------------------------------+
//| Actualizar todos los trailing stops                            |
//+------------------------------------------------------------------+
void OrderExecution::UpdateAllTrailingStops()
  {
   if(!m_multiOrder.cycleActive || !m_multiOrder.cycleTrailingActive)
      return;

   for(int i = 0; i < m_multiOrder.orderCount; i++)
     {
      if(m_multiOrder.tickets[i] > 0)
        {
         ApplyCycleTrailingToOrder(i);
        }
     }
  }

//+------------------------------------------------------------------+
//| Ejecutar cierres parciales                                     |
//+------------------------------------------------------------------+
bool OrderExecution::ExecutePartialCloses()
  {
   bool closed = false;

   for(int i = 0; i < m_multiOrder.orderCount; i++)
     {
      ulong ticket = m_multiOrder.tickets[i];
      if(ticket == 0)
         continue;

      if(!PositionSelectByTicket(ticket))
         continue;

      double profit = PositionGetDouble(POSITION_PROFIT);

      if(profit <= 0.0)
         continue;

      if(ClosePartialPosition(ticket, m_partialClosePercent))
        {
         LogExecutionEvent("Cierre parcial ejecutado para ticket " + IntegerToString(ticket));
         closed = true;
        }
     }

   return closed;
  }

//+------------------------------------------------------------------+
//| Monitorear múltiples posiciones MEJORADO                       |
//+------------------------------------------------------------------+
void OrderExecution::MonitorMultiplePositions()
  {
   if(!m_multiOrder.cycleActive)
      return;

// Actualizar información cada vez
   UpdateAccountInfo();
   UpdateATR();
   UpdateMarketContext();

   if(CheckEmergencyStop())
     {
      EmergencyCloseAll("Drawdown de emergencia alcanzado");
      return;
     }

// MEJORADO: Actualizar trailing más frecuentemente
   if(UpdateCycleTrailing())
     {
      // ✅ UpdateCycleTrailing ya aplica el trailing internamente
     }

   // ✅ NUEVO: Verificar si agregar órdenes adicionales
   if(m_multiOrder.orderCount < m_plannedOrdersForCycle && 
      m_multiOrder.orderCount < m_maxOrdersPerCycle)
     {
      if(ShouldAddAdditionalOrder())
        {
         Print("╔══════════════════════════════════════════════════════╗");
         Print("║  AGREGANDO ORDEN ADICIONAL #", m_multiOrder.orderCount + 1, "                     ║");
         Print("╚══════════════════════════════════════════════════════╝");
         
         int direction = (m_multiOrder.direction == DIRECTION_BUY) ? 1 : -1;
         double conviction = m_multiOrder.avgConviction;
         
         if(ExecuteAdditionalOrder(direction, conviction))
           {
            Print("✅ Orden adicional agregada");
            Print("   Total activas: ", m_multiOrder.orderCount);
           }
         else
           {
            Print("❌ Fallo al agregar orden adicional");
           }
        }
     }

   ENUM_EMOTIONAL_ACTION action = AnalyzeEmotionalAction();
   if(action != ACTION_NONE)
     {
      ExecuteEmotionalAction(action);
     }

   if(ExecutePartialCloses())
     {
      RecalculateActiveOrders();
     }

   if(!CheckCycleIntegrity())
     {
      FinalizeCycle();
     }
  }

//+------------------------------------------------------------------+
//| Verificar integridad del ciclo                                 |
//+------------------------------------------------------------------+
bool OrderExecution::CheckCycleIntegrity()
  {
   int activeOrders = 0;

   for(int i = 0; i < 10; i++)
     {
      if(m_multiOrder.tickets[i] > 0)
        {
         if(!CheckOrderClosed(m_multiOrder.tickets[i]))
           {
            activeOrders++;
           }
         else
           {
            m_multiOrder.tickets[i] = 0;
            m_multiOrder.lotSizes[i] = 0;
           }
        }
     }

   m_multiOrder.orderCount = activeOrders;

   if(activeOrders > 0 && activeOrders < 10)
     {
      CompactOrderArrays();
     }

   if(activeOrders == 0)
     {
      m_multiOrder.cycleActive = false;
     }

   return m_multiOrder.cycleActive;
  }

//+------------------------------------------------------------------+
//| Finalizar ciclo                                                |
//+------------------------------------------------------------------+
void OrderExecution::FinalizeCycle()
  {
   if(!m_multiOrder.cycleActive)
      return;

   LogExecutionEvent("Finalizando ciclo multi-orden");
   LogExecutionEvent("Órdenes totales: " + IntegerToString(m_multiOrder.orderCount));
   LogExecutionEvent("Profit total: " + DoubleToString(m_multiOrder.cycleProfit, 2));
   LogExecutionEvent("Duración: " + IntegerToString((int)(TimeCurrent() - m_multiOrder.cycleStartTime)/60) + " min");
   LogExecutionEvent("Consenso: " + DoubleToString(m_multiOrder.consensusStrength, 2));
   LogExecutionEvent("Convicción avg: " + DoubleToString(m_multiOrder.avgConviction, 2));
   LogExecutionEvent("Contexto emocional: " + DoubleToString(m_multiOrder.emotionalContext, 2));
   LogExecutionEvent("  Max fear: " + DoubleToString(m_multiOrder.maxFearLevel, 2));
   LogExecutionEvent("  Alertas emocionales: " + IntegerToString(m_multiOrder.emotionalAlerts));
   LogExecutionEvent("  Trailing sincronizado: " + (m_multiOrder.cycleTrailingActive ? "SE ACTIVÓ" : "NO SE ACTIVÓ"));

   if(m_multiOrder.cycleTrailingActive)
     {
      LogExecutionEvent("  Nivel final de trailing: " + DoubleToString(m_multiOrder.cycleTrailingLevel, _Digits));
     }

   m_totalProfit += m_multiOrder.cycleProfit;

   SendCycleToMetaLearning();

   ResetMultiOrderCycle();
  }

//+------------------------------------------------------------------+
//| Verificar si hay órdenes en profit                              |
//+------------------------------------------------------------------+
bool OrderExecution::HasOrdersInProfit(int &ordersInProfit, double &totalProfit)
  {
   ordersInProfit = 0;
   totalProfit = 0.0;

   for(int i = 0; i < m_multiOrder.orderCount; i++)
     {
      if(m_multiOrder.tickets[i] > 0)
        {
         if(PositionSelectByTicket(m_multiOrder.tickets[i]))
           {
            double profit = PositionGetDouble(POSITION_PROFIT);
            if(profit > 0)
              {
               ordersInProfit++;
               totalProfit += profit;
              }
           }
        }
     }

   return ordersInProfit > 0;
  }

//+------------------------------------------------------------------+
//| Obtener profit de la primera orden                              |
//+------------------------------------------------------------------+
double OrderExecution::GetFirstOrderProfit()
  {
   if(m_multiOrder.orderCount == 0 || m_multiOrder.tickets[0] == 0)
      return 0.0;

   if(PositionSelectByTicket(m_multiOrder.tickets[0]))
     {
      return PositionGetDouble(POSITION_PROFIT);
     }

   return 0.0;
  }

//+------------------------------------------------------------------+
//| Obtener movimiento de la primera orden                          |
//+------------------------------------------------------------------+
double OrderExecution::GetFirstOrderMovement()
  {
   if(m_multiOrder.orderCount == 0 || m_multiOrder.tickets[0] == 0)
      return 0.0;

   if(PositionSelectByTicket(m_multiOrder.tickets[0]))
     {
      double currentPrice = m_multiOrder.direction == DIRECTION_BUY ?
                            SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                            SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      return (currentPrice - m_multiOrder.entryPrices[0]) *
             (m_multiOrder.direction == DIRECTION_BUY ? 1 : -1);
     }

   return 0.0;
  }

//+------------------------------------------------------------------+
//| Actualizar contexto emocional                                   |
//+------------------------------------------------------------------+
void OrderExecution::UpdateEmotionalContext(const MarketEmotion &emotion)
  {
   m_currentEmotion = emotion;
   m_multiOrder.emotionalContext = CalculateEmotionalScore();
   if(m_currentEmotion.fear > m_multiOrder.maxFearLevel)
      m_multiOrder.maxFearLevel = m_currentEmotion.fear;
  }

//+------------------------------------------------------------------+
//| Analizar acción emocional                                       |
//+------------------------------------------------------------------+
ENUM_EMOTIONAL_ACTION OrderExecution::AnalyzeEmotionalAction()
  {
   if(!m_multiOrder.cycleActive || m_multiOrder.orderCount == 0)
      return ACTION_NONE;

   if(m_currentEmotion.fear > 0.9)
     {
      LogEmotionalEvent("MIEDO EXTREMO detectado", m_currentEmotion.fear);
      m_multiOrder.emotionalAlerts++;
      return ACTION_FULL_EXIT;
     }

   if(m_currentEmotion.fear > m_fearThreshold && m_multiOrder.orderCount > 1)
     {
      LogEmotionalEvent("Miedo alto - considerar cierre parcial", m_currentEmotion.fear);
      m_multiOrder.emotionalAlerts++;
      return ACTION_PARTIAL_CLOSE;
     }

   if(m_currentEmotion.greed > m_greedThreshold)
     {
      LogEmotionalEvent("Codicia alta - ajustar stops", m_currentEmotion.greed);
      return ACTION_TIGHTEN_STOPS;
     }

   if(m_currentEmotion.uncertainty > 0.8)
     {
      LogEmotionalEvent("Incertidumbre alta", m_currentEmotion.uncertainty);
      return ACTION_REDUCE_SIZE;
     }

   return ACTION_NONE;
  }

//+------------------------------------------------------------------+
//| Ejecutar acción emocional                                       |
//+------------------------------------------------------------------+
bool OrderExecution::ExecuteEmotionalAction(ENUM_EMOTIONAL_ACTION action)
  {
   bool result = false;

   switch(action)
     {
      case ACTION_REDUCE_SIZE:
         result = true;
         break;

      case ACTION_TIGHTEN_STOPS:
         AdjustStopsForEmotion();
         result = true;
         break;

      case ACTION_PARTIAL_CLOSE:
         for(int i = 0; i < m_multiOrder.orderCount; i++)
           {
            if(m_multiOrder.tickets[i] > 0)
              {
               ClosePartialPosition(m_multiOrder.tickets[i], 0.5);
              }
           }
         result = true;
         break;

      case ACTION_FULL_EXIT:
         result = EmergencyCloseAll("Contexto emocional crítico");
         m_emotionalExits++;
         break;

      default:
         break;
     }

   return result;
  }

//+------------------------------------------------------------------+
//| Ajustar stops por emoción MEJORADO                             |
//+------------------------------------------------------------------+
void OrderExecution::AdjustStopsForEmotion()
  {
   if(!m_multiOrder.cycleActive || m_multiOrder.orderCount == 0)
      return;

   LogExecutionEvent("Ajustando stops por contexto emocional");

   if(m_multiOrder.cycleTrailingActive)
     {
      double adjustmentFactor = 1.0;

      if(m_currentEmotion.fear > 0.6)
        {
         // Limitar ajuste emocional para no ser demasiado agresivo
         adjustmentFactor = MathMax(0.5, 1.0 - (m_currentEmotion.fear - 0.6) * 0.5);
        }
      else
         if(m_currentEmotion.greed > 0.7)
           {
            adjustmentFactor = 0.8;
           }

      double currentPrice = (m_multiOrder.direction == DIRECTION_BUY) ?
                            SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                            SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      double newDistance = m_trailingDistance * _Point * adjustmentFactor;

      // Usar ATR si está configurado
      if(m_useATRTrailing && m_currentATR > 0)
        {
         newDistance = m_currentATR * m_trailingStartATR * adjustmentFactor;
        }

      double newSL;

      if(m_multiOrder.direction == DIRECTION_BUY)
        {
         newSL = currentPrice - newDistance;
         if(newSL > m_multiOrder.cycleTrailingLevel)
           {
            m_multiOrder.cycleTrailingLevel = newSL;
            UpdateAllTrailingStops();
            LogExecutionEvent("Trailing ajustado por emoción a: " + DoubleToString(newSL, _Digits));
           }
        }
      else
        {
         newSL = currentPrice + newDistance;
         if(newSL < m_multiOrder.cycleTrailingLevel)
           {
            m_multiOrder.cycleTrailingLevel = newSL;
            UpdateAllTrailingStops();
            LogExecutionEvent("Trailing ajustado por emoción a: " + DoubleToString(newSL, _Digits));
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Calcular tamaño de lote emocional                               |
//+------------------------------------------------------------------+
double OrderExecution::CalculateEmotionalLotSize(double baseLot, const MarketEmotion &emotion)
  {
   double emotionalMultiplier = GetEmotionalMultiplier();

   double adjustedLot = baseLot * emotionalMultiplier;

   if(MathAbs(emotionalMultiplier - 1.0) > 0.05)
     {
      LogExecutionEvent("Lot ajustado por emoción: " +
                        DoubleToString(baseLot, 3) + " -> " +
                        DoubleToString(adjustedLot, 3) +
                        " (x" + DoubleToString(emotionalMultiplier, 2) + ")");
     }

   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   adjustedLot = MathMax(minLot, adjustedLot);

   return adjustedLot;
  }

//+------------------------------------------------------------------+
//| Obtener multiplicador emocional                                 |
//+------------------------------------------------------------------+
double OrderExecution::GetEmotionalMultiplier()
  {
   double multiplier = 1.0;

   if(m_currentEmotion.fear > 0.5)
     {
      double fearReduction = (m_currentEmotion.fear - 0.5) * 0.6;
      multiplier *= (1.0 - fearReduction);
     }

   if(m_currentEmotion.uncertainty > 0.6)
     {
      double uncertaintyReduction = (m_currentEmotion.uncertainty - 0.6) * 0.4;
      multiplier *= (1.0 - uncertaintyReduction);
     }

   if(m_currentEmotion.greed > 0.7 && m_currentEmotion.fear < 0.3)
     {
      double greedBoost = (m_currentEmotion.greed - 0.7) * 0.2;
      multiplier *= (1.0 + greedBoost);
     }

   multiplier = MathMax(0.3, MathMin(1.2, multiplier));

   return multiplier;
  }

//+------------------------------------------------------------------+
//| Calcular tamaño de lote reducido                                |
//+------------------------------------------------------------------+
double OrderExecution::CalculateReducedLotSize(int orderIndex)
  {
   if(orderIndex == 0)
      return m_multiOrder.baseLotSize;

   double reduction = MathPow(m_orderReduction, orderIndex);
   double newLot = m_multiOrder.baseLotSize * reduction;

   if(m_lastConsensusStrength > 0.85 && orderIndex <= 2)
     {
      reduction = MathPow(m_orderReduction + 0.05, orderIndex);
      newLot = m_multiOrder.baseLotSize * reduction;
     }

   return NormalizeLotSize(newLot);
  }

//+------------------------------------------------------------------+
//| Calcular stop loss                                             |
//+------------------------------------------------------------------+
double OrderExecution::CalculateStopLoss(double entryPrice, int direction, bool isAdditional)
  {
   double stopDistance;

   if(isAdditional)
     {
      stopDistance = m_trailingDistance * _Point;
     }
   else
     {
      stopDistance = m_currentATR * m_atrMultiplier;
     }

   double stopPrice;
   if(direction > 0)
     {
      stopPrice = entryPrice - stopDistance;
     }
   else
     {
      stopPrice = entryPrice + stopDistance;
     }

   return NormalizeDouble(stopPrice, _Digits);
  }

//+------------------------------------------------------------------+
//| Calcular take profit                                           |
//+------------------------------------------------------------------+
double OrderExecution::CalculateTakeProfit(double entryPrice, int direction)
  {
   return 0.0;
  }

//+------------------------------------------------------------------+
//| Calcular stop emocional                                        |
//+------------------------------------------------------------------+
double OrderExecution::CalculateEmotionalStop(double normalStop, int direction)
  {
   double currentPrice = GetUpdatedPrice(direction);

   double normalDistance = MathAbs(currentPrice - normalStop);

   double adjustedDistance = normalDistance;

   if(m_currentEmotion.fear > 0.6)
     {
      adjustedDistance *= (1.0 - (m_currentEmotion.fear - 0.6) * 0.4);
     }
   else
      if(m_currentEmotion.greed > 0.7)
        {
         adjustedDistance *= (1.0 + (m_currentEmotion.greed - 0.7) * 0.2);
        }

   double emotionalStop;
   if(direction > 0)
     {
      emotionalStop = currentPrice - adjustedDistance;
     }
   else
     {
      emotionalStop = currentPrice + adjustedDistance;
     }

   return NormalizeDouble(emotionalStop, _Digits);
  }

//+------------------------------------------------------------------+
//| Cerrar posición parcial                                        |
//+------------------------------------------------------------------+
bool OrderExecution::ClosePartialPosition(ulong ticket, double closePercent)
  {
   if(!PositionSelectByTicket(ticket))
      return false;

   double currentVolume = PositionGetDouble(POSITION_VOLUME);
   double closeVolume = NormalizeDouble(currentVolume * closePercent, 2);

   double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   closeVolume = NormalizeDouble(closeVolume / stepLot, 0) * stepLot;

   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(closeVolume < minLot)
      return false;

   if(m_trade.PositionClosePartial(ticket, closeVolume))
     {
      double profit = 0.0;
      ulong last_deal = m_trade.ResultDeal();
      if(last_deal > 0 && HistoryDealSelect(last_deal))
         profit = HistoryDealGetDouble(last_deal, DEAL_PROFIT);
      m_multiOrder.totalPartialClosed += profit;
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Cerrar todas las posiciones en emergencia                      |
//+------------------------------------------------------------------+
bool OrderExecution::EmergencyCloseAll(string reason)
  {
   LogExecutionEvent("=== CIERRE DE EMERGENCIA: " + reason + " ===");

   bool allClosed = true;

   for(int i = 0; i < m_multiOrder.orderCount; i++)
     {
      if(m_multiOrder.tickets[i] > 0)
        {
         if(PositionSelectByTicket(m_multiOrder.tickets[i]))
           {
            if(!m_trade.PositionClose(m_multiOrder.tickets[i]))
              {
               allClosed = false;
               LogExecutionEvent("Error cerrando ticket " + IntegerToString(m_multiOrder.tickets[i]));
              }
            else
              {
               m_multiOrder.tickets[i] = 0;
              }
           }
        }
     }

   if(allClosed)
     {
      FinalizeCycle();
     }

   return allClosed;
  }

//+------------------------------------------------------------------+
//| Verificar si un ticket está en el ciclo                        |
//+------------------------------------------------------------------+
bool OrderExecution::IsTicketInCycle(ulong ticket)
  {
   for(int i = 0; i < m_multiOrder.orderCount; i++)
     {
      if(m_multiOrder.tickets[i] == ticket)
         return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Obtener índice de orden por ticket                             |
//+------------------------------------------------------------------+
int OrderExecution::GetOrderIndexByTicket(ulong ticket)
  {
   for(int i = 0; i < m_multiOrder.orderCount; i++)
     {
      if(m_multiOrder.tickets[i] == ticket)
         return i;
     }
   return -1;
  }

//+------------------------------------------------------------------+
//| Verificar stop de emergencia                                   |
//+------------------------------------------------------------------+
bool OrderExecution::CheckEmergencyStop()
  {
   double currentDD = (AccountInfoDouble(ACCOUNT_BALANCE) - AccountInfoDouble(ACCOUNT_EQUITY)) /
                      AccountInfoDouble(ACCOUNT_BALANCE) * 100;

   double adjustedEmergencyDD = m_emergencyDD;
   if(m_currentEmotion.fear > 0.7)
     {
      adjustedEmergencyDD *= 0.8;
     }

   if(currentDD >= adjustedEmergencyDD)
     {
      m_emergencyActive = true;
      return true;
     }

   if(m_emergencyActive && currentDD < adjustedEmergencyDD * 0.5)
     {
      m_emergencyActive = false;
     }

   return m_emergencyActive;
  }

//+------------------------------------------------------------------+
//| Enviar ciclo a MetaLearning                                    |
//+------------------------------------------------------------------+
void OrderExecution::SendCycleToMetaLearning()
  {
   if(m_metaLearning == NULL || CheckPointer(m_metaLearning) != POINTER_DYNAMIC)
      return;

   MultiOrderCycle cycleData;
   cycleData.initial_consensus_id = m_multiOrder.initial_consensus_id;

   for(int i = 0; i < m_multiOrder.orderCount; i++)
     {
      cycleData.tickets[i] = m_multiOrder.tickets[i];
     }

   LogExecutionEvent("Datos del ciclo enviados a MetaLearning con consenso ID: " +
                     IntegerToString(m_multiOrder.initial_consensus_id));
  }

//+------------------------------------------------------------------+
//| Actualizar contexto de consenso                                |
//+------------------------------------------------------------------+
void OrderExecution::UpdateConsensusContext(double consensusStrength, double conviction)
  {
   m_lastConsensusStrength = consensusStrength;
   m_lastTotalConviction = conviction;
   m_multiOrder.consensusStrength = consensusStrength;
   m_multiOrder.avgConviction = conviction;
  }

//+------------------------------------------------------------------+
//| Actualizar estado                                              |
//+------------------------------------------------------------------+
void OrderExecution::UpdateStatus(string status)
  {
   LogExecutionEvent("Status: " + status);
  }

//+------------------------------------------------------------------+
//| NUEVA FUNCIÓN MEJORADA: Verificar activación del trailing       |
//+------------------------------------------------------------------+
bool OrderExecution::CheckTrailingActivation()
  {
   if(!m_multiOrder.cycleActive || m_multiOrder.orderCount == 0)
      return false;

// Si ya está activo, no re-activar
   if(m_multiOrder.cycleTrailingActive)
      return true;

// NUEVO: Verificar tiempo mínimo desde inicio del ciclo (300 segundos = 5 minutos)
   if(TimeCurrent() - m_multiOrder.cycleStartTime < 300)
     {
      int timeElapsed = (int)(TimeCurrent() - m_multiOrder.cycleStartTime);
      if(timeElapsed % 60 == 0) // Log cada minuto
        {
         Print("⏱ Esperando tiempo mínimo para trailing: ", 
               timeElapsed, " / 300 seg (", (300-timeElapsed)/60, " min restantes)");
        }
      return false;
     }

// Calcular profit promedio en PIPS
   double totalProfitPips = 0;
   int validOrders = 0;
   int ordersInProfit = 0; // ✅ NUEVO: Contar órdenes en profit

   for(int i = 0; i < m_multiOrder.orderCount; i++)
     {
      if(m_multiOrder.tickets[i] > 0 && PositionSelectByTicket(m_multiOrder.tickets[i]))
        {
         double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         int posType = (int)PositionGetInteger(POSITION_TYPE);
         int direction = (posType == POSITION_TYPE_BUY) ? 1 : -1;

         double profitPips = CalculateProfitInPips(entryPrice, currentPrice, direction);
         totalProfitPips += profitPips;
         validOrders++;
         
         // ✅ NUEVO: Contar si está en profit
         if(profitPips > 0)
            ordersInProfit++;
        }
     }

   if(validOrders == 0)
      return false;

   // ✅ VALIDACIÓN: Todas las órdenes deben estar en profit
   if(ordersInProfit < validOrders)
     {
      Print("❌ Trailing NO activado: No todas las órdenes en profit");
      Print("   Órdenes en profit: ", ordersInProfit, " / ", validOrders);
      return false;
     }

   double avgProfitPips = totalProfitPips / validOrders;

   Print("Verificando activación trailing: Profit=", DoubleToString(avgProfitPips, 1), " pips");

// Verificar contra umbral de activación
   double activationThreshold = 50.0; // ✅ AUMENTADO de 30 a 50 pips - CORREGIDO

// Si está configurado usar porcentaje del movimiento
   if(m_trailingStartPercent > 0)
     {
      // Convertir porcentaje a pips basado en ATR
      double atrPips = PointsToPips(m_currentATR / _Point);
      activationThreshold = atrPips * (m_trailingStartPercent / 100.0);
     }
// Si está configurado usar ATR
   else
      if(m_useATRTrailing && m_currentATR > 0)
        {
         double atrPips = PointsToPips(m_currentATR / _Point);
         activationThreshold = atrPips * m_trailingStartATR;
        }
      // Usar configuración por etapas
      else
        {
         activationThreshold = m_trailingStages[0].activationPips;
        }

// Asegurar umbral mínimo razonable
   activationThreshold = MathMax(50.0, MathMin(200.0, activationThreshold));

   if(avgProfitPips >= activationThreshold)
     {
      Print("✓ TRAILING ACTIVADO! Profit ", DoubleToString(avgProfitPips, 1),
            " >= Umbral ", DoubleToString(activationThreshold, 1), " pips");
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| NUEVA FUNCIÓN MEJORADA: Actualizar trailing del ciclo          |
//+------------------------------------------------------------------+
bool OrderExecution::UpdateCycleTrailing()
  {
   if(!m_multiOrder.cycleActive || m_multiOrder.orderCount == 0)
      return false;

// Verificar si debe activarse
   if(!m_multiOrder.cycleTrailingActive)
     {
      if(CheckTrailingActivation())
        {
         m_multiOrder.cycleTrailingActive = true;
         m_multiOrder.cycleLastTrailingUpdate = TimeCurrent();

         // Calcular nivel inicial
         double currentPrice = (m_multiOrder.direction == DIRECTION_BUY) ?
                               SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                               SymbolInfoDouble(_Symbol, SYMBOL_ASK);

         double trailingDistancePips = CalculateOptimalTrailingDistance();
         double trailingDistancePrice = PipsToPoints(trailingDistancePips) / _Point;

         if(m_multiOrder.direction == DIRECTION_BUY)
            m_multiOrder.cycleTrailingLevel = currentPrice - trailingDistancePrice;
         else
            m_multiOrder.cycleTrailingLevel = currentPrice + trailingDistancePrice;

         Print("Trailing inicial establecido en ",
               DoubleToString(m_multiOrder.cycleTrailingLevel, _Digits));
         return true;
        }
      return false;
     }

// Trailing ya activo - verificar si actualizar
   double currentPrice = (m_multiOrder.direction == DIRECTION_BUY) ?
                         SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                         SymbolInfoDouble(_Symbol, SYMBOL_ASK);

// Calcular nueva distancia óptima
   double trailingDistancePips = CalculateOptimalTrailingDistance();
   double trailingDistancePrice = PipsToPoints(trailingDistancePips) / _Point;

   double newTrailingLevel = 0;
   bool shouldUpdate = false;

   if(m_multiOrder.direction == DIRECTION_BUY)
     {
      newTrailingLevel = currentPrice - trailingDistancePrice;

      // Solo actualizar si el nuevo nivel es mejor (más alto para BUY)
      if(newTrailingLevel > m_multiOrder.cycleTrailingLevel)
        {
         // Verificar step mínimo (evitar micro-ajustes)
         double stepPips = 5.0; // Mínimo 2 pips de mejora
         double improvement = PointsToPips((newTrailingLevel - m_multiOrder.cycleTrailingLevel) / _Point);

         if(improvement >= stepPips)
           {
            shouldUpdate = true;
           }
        }
     }
   else // SELL
     {
      newTrailingLevel = currentPrice + trailingDistancePrice;

      // Solo actualizar si el nuevo nivel es mejor (más bajo para SELL)
      if(newTrailingLevel < m_multiOrder.cycleTrailingLevel ||
         m_multiOrder.cycleTrailingLevel == 0)
        {
         double stepPips = 5.0;
         double improvement = PointsToPips((m_multiOrder.cycleTrailingLevel - newTrailingLevel) / _Point);

         if(improvement >= stepPips || m_multiOrder.cycleTrailingLevel == 0)
           {
            shouldUpdate = true;
           }
        }
     }

   if(shouldUpdate)
     {
      double oldLevel = m_multiOrder.cycleTrailingLevel;
      m_multiOrder.cycleTrailingLevel = newTrailingLevel;
      m_multiOrder.cycleLastTrailingUpdate = TimeCurrent();

      Print("Trailing actualizado: ", DoubleToString(oldLevel, _Digits),
            " → ", DoubleToString(newTrailingLevel, _Digits));

      // Aplicar a todas las órdenes
      for(int i = 0; i < m_multiOrder.orderCount; i++)
        {
         ApplyCycleTrailingToOrder(i);
        }

      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| FUNCIÓN MEJORADA: Aplicar trailing a orden específica          |
//+------------------------------------------------------------------+
bool OrderExecution::ApplyCycleTrailingToOrder(int orderIndex)
  {
   if(orderIndex < 0 || orderIndex >= m_multiOrder.orderCount)
      return false;

   ulong ticket = m_multiOrder.tickets[orderIndex];
   if(!PositionSelectByTicket(ticket))
      return false;

   double currentSL = PositionGetDouble(POSITION_SL);
   double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
   double newSL = m_multiOrder.cycleTrailingLevel;
   int posType = (int)PositionGetInteger(POSITION_TYPE);

// Protecciones por vela actual
   datetime bar0 = iTime(_Symbol, PERIOD_CURRENT, 0);
   datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   if(openTime >= bar0)
     {
      if(posType == POSITION_TYPE_BUY)
         newSL = MathMin(newSL, openPrice - 5*_Point);
      else
         newSL = MathMax(newSL, openPrice + 5*_Point);
     }

// Ajuste spread/slippage (usar entero spread -> puntos)
   int spreadInt = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   double spreadBuf = spreadInt * _Point + PipsToPoints(1.0);
   if(posType == POSITION_TYPE_BUY)
      newSL -= spreadBuf;
   else
      newSL += spreadBuf;

// Validación de seguridad - no mover SL en contra de la posición
//     int posType = (int)PositionGetInteger(POSITION_TYPE);

   bool shouldModify = false;

   if(posType == POSITION_TYPE_BUY)
     {
      // Para BUY: nuevo SL debe ser mayor que el actual y menor que el precio
      if(newSL > currentSL && newSL < currentPrice - 5 * _Point) // 5 puntos de margen
        {
         shouldModify = true;
        }
     }
   else // SELL
     {
      // Para SELL: nuevo SL debe ser menor que el actual (o no existir) y mayor que el precio
      if((currentSL == 0 || newSL < currentSL) && newSL > currentPrice + 5 * _Point)
        {
         shouldModify = true;
        }
     }

   if(shouldModify)
     {
      MqlTradeRequest request = {};
      MqlTradeResult result = {};

      request.action = TRADE_ACTION_SLTP;
      request.position = ticket;
      request.symbol = _Symbol;
      request.sl = NormalizeDouble(newSL, _Digits);
      request.tp = 0; // Sin TP, solo trailing
      request.magic = m_magicNumber;

      if(OrderSend(request, result))
        {
         if(result.retcode == TRADE_RETCODE_DONE)
           {
            m_multiOrder.stopLosses[orderIndex] = newSL;

             double slDistance = MathAbs(currentPrice - newSL) / _Point;
            double slPips = slDistance / 10.0;  // Puntos a pips
            
            // Determinar stage basado en profi
            double profitPoints = MathAbs(currentPrice - openPrice) / _Point;
            double profitPips = profitPoints / 10.0;
            
            string stage = "";
            if(profitPips >= 8 && profitPips < 15) stage = "BREAKEVEN";
            else if(profitPips >= 15 && profitPips < 30) stage = "PROTECTION";
            else if(profitPips >= 30 && profitPips < 45) stage = "RUNNER";
            else if(profitPips >= 45) stage = "MOMENTUM";
            
            Print("✅ TRAILING ACTIVADO para ticket ", ticket);
            Print("    Profit: ", DoubleToString(profitPips, 1), " pts");
            Print("    Nuevo SL: ", DoubleToString(newSL, _Digits));
            Print("    Stage: ", stage);

            return true;
           }
         else
           {
            Print("Error actualizando SL: ", result.retcode, " - ", result.comment);
           }
        }
      else
        {
         Print("Error enviando orden: ", GetLastError());
        }
     }

   return false;
  }

// ============================================================================
// CAMBIO 7: Corregir función CalculateCycleTrailingStop
// Ubicación: ~línea 3066
// REEMPLAZAR COMPLETAMENTE LA FUNCIÓN
// ============================================================================
double OrderExecution::CalculateCycleTrailingStop(double currentPrice)
  {
   // Obtener profit total y órdenes en profit
   double totalProfit = 0;
   int ordersInProfit = 0;
   HasOrdersInProfit(ordersInProfit, totalProfit);

   if(ordersInProfit == 0 || m_multiOrder.orderCount == 0)
     {
      return m_multiOrder.cycleTrailingLevel;  // Sin cambio si no hay profit
     }

   // Calcular profit promedio por orden en PUNTOS
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(tickValue <= 0)
      tickValue = 1.0;

   double avgProfitInMoney = totalProfit / m_multiOrder.orderCount;
   double avgProfitPoints = avgProfitInMoney / tickValue;
   
   // Convertir puntos a pips (para 5 dígitos: dividir entre 10)
   double avgProfitPips = avgProfitPoints / 10.0;

   Print("Verificando activación trailing: Profit=", DoubleToString(avgProfitPips, 1), " pips");

   // Determinar distancia de trailing según etapa
   double distancePips = 0;
   string stage = "";

   if(avgProfitPips >= 8.0 && avgProfitPips < 15.0)
     {
      // ETAPA 1: BREAKEVEN - Proteger capital
      distancePips = 1.0;
      stage = "TRAILING_BREAKEVEN";
     }
   else
      if(avgProfitPips >= 15.0 && avgProfitPips < 30.0)
        {
         // ETAPA 2: PROTECTION - Asegurar 30% del profit
         distancePips = avgProfitPips * 0.30;
         stage = "TRAILING_PROTECTION";
        }
      else
         if(avgProfitPips >= 30.0 && avgProfitPips < 45.0)
           {
            // ETAPA 3: RUNNER - Asegurar 20% del profit
            distancePips = avgProfitPips * 0.20;
            stage = "TRAILING_RUNNER";
           }
         else
            if(avgProfitPips >= 45.0)
              {
               // ETAPA 4: MOMENTUM - Asegurar 15% del profit
               distancePips = avgProfitPips * 0.15;
               stage = "TRAILING_MOMENTUM";
              }
            else
              {
               // Sin trailing activo aún
               return m_multiOrder.cycleTrailingLevel;
              }

   // Convertir distancia de pips a puntos (para 5 dígitos: multiplicar por 10)
   double distancePoints = distancePips * 10.0 * _Point;

   // Asegurar distancia mínima
   double minDistance = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   if(minDistance == 0)
      minDistance = 10 * _Point;  // Mínimo 1 pip

   distancePoints = MathMax(distancePoints, minDistance);

   // Calcular nuevo SL según dirección
   double newSL;

   if(m_multiOrder.direction == DIRECTION_BUY)
     {
      // ✅ PARA BUY: SL DEBAJO del precio actual
      newSL = currentPrice - distancePoints;
     }
   else
     {
      // ✅ PARA SELL: SL ARRIBA del precio actual
      newSL = currentPrice + distancePoints;
     }

   // Validar que el nuevo SL no esté demasiado cerca del precio
   double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;

   if(m_multiOrder.direction == DIRECTION_BUY)
     {
      // Para BUY: asegurar que SL esté al menos stopLevel debajo del precio
      double minSL = currentPrice - (stopLevel + 2 * _Point);
      newSL = MathMin(newSL, minSL);
     }
   else
     {
      // Para SELL: asegurar que SL esté al menos stopLevel arriba del precio
      double maxSL = currentPrice + (stopLevel + 2 * _Point);
      newSL = MathMax(newSL, maxSL);
     }

   Print("Trailing calculado - Stage: ", stage,
         " Distance: ", DoubleToString(distancePips, 1), " pips",
         " New SL: ", DoubleToString(newSL, _Digits));

   return NormalizeDouble(newSL, _Digits);
  }

//+------------------------------------------------------------------+
//| Imprimir estado del trailing                                    |
//+------------------------------------------------------------------+
void OrderExecution::PrintTrailingStatus()
  {
   Print("=== ESTADO DE TRAILING - ORDEREXECUTION ===");
   Print("Trailing dinámico: ", m_useDynamicTrailing ? "ACTIVADO" : "DESACTIVADO");
   Print("Período ATR: ", m_trailingATRPeriod);
   for(int i = 0; i < 3; i++)
     {
      Print("Etapa ", i+1, ":");
      Print("  Activación: ", m_trailingStages[i].activationPips, " pips");
      Print("  Distancia: ", m_trailingStages[i].trailingPips, " pips");
      Print("  Step: ", m_trailingStages[i].stepPips, " pips");
      Print("  Usa ATR: ", m_trailingStages[i].useATR ? "SÍ" : "NO");
      if(m_trailingStages[i].useATR)
         Print("  Multiplicador ATR: ", m_trailingStages[i].atrMultiplier);
     }
   if(m_multiOrder.cycleActive)
     {
      Print("Ciclo - Trailing activo: ", m_multiOrder.cycleTrailingActive ? "SÍ" : "NO");
      if(m_multiOrder.cycleTrailingActive)
        {
         Print("Ciclo - Nivel de trailing: ", DoubleToString(m_multiOrder.cycleTrailingLevel, _Digits));
         Print("Ciclo - Precio de activación: ", DoubleToString(m_multiOrder.cycleTrailingActivationPrice, _Digits));
         Print("Ciclo - Última actualización: ", TimeToString(m_multiOrder.cycleLastTrailingUpdate));
        }
     }
   Print("========================================");
  }


//+------------------------------------------------------------------+
//| NUEVA FUNCIÓN: Detectar tipo de instrumento                     |
//+------------------------------------------------------------------+
string OrderExecution::GetInstrumentType()
  {
   string symbol = _Symbol;
   string symbolUpper = symbol;
   StringToUpper(symbolUpper);

// Detectar divisas (pares de forex)
   string forexPairs[] = {"EURUSD", "GBPUSD", "USDJPY", "USDCHF", "AUDUSD", "NZDUSD",
                          "USDCAD", "EURGBP", "EURJPY", "GBPJPY", "AUDJPY", "EURAUD",
                          "EURCHF", "AUDCAD", "NZDCAD", "AUDNZD", "GBPAUD", "GBPCAD",
                          "GBPCHF", "GBPNZD", "CADJPY", "CHFJPY", "NZDJPY", "AUDCHF",
                          "CADCHF", "EURNZD", "EURCAD", "NZDCHF"
                         };

   for(int i = 0; i < ArraySize(forexPairs); i++)
     {
      if(StringFind(symbolUpper, forexPairs[i]) >= 0)
         return "FOREX";
     }

// Detectar metales
   if(StringFind(symbolUpper, "GOLD") >= 0 || StringFind(symbolUpper, "XAUUSD") >= 0)
      return "GOLD";
   if(StringFind(symbolUpper, "SILVER") >= 0 || StringFind(symbolUpper, "XAGUSD") >= 0)
      return "SILVER";
   if(StringFind(symbolUpper, "PLATINUM") >= 0 || StringFind(symbolUpper, "XPTUSD") >= 0)
      return "METAL";
   if(StringFind(symbolUpper, "PALLADIUM") >= 0 || StringFind(symbolUpper, "XPDUSD") >= 0)
      return "METAL";

// Detectar índices
   string indices[] = {"US30", "US100", "US500", "NAS100", "SPX500", "DJ30", "DAX",
                       "FTSE", "CAC", "NIKKEI", "HSI", "ASX", "STOXX", "RUSSELL"
                      };

   for(int i = 0; i < ArraySize(indices); i++)
     {
      if(StringFind(symbolUpper, indices[i]) >= 0)
         return "INDEX";
     }

// Detectar petróleo
   if(StringFind(symbolUpper, "WTI") >= 0 || StringFind(symbolUpper, "BRENT") >= 0 ||
      StringFind(symbolUpper, "OIL") >= 0 || StringFind(symbolUpper, "CRUDE") >= 0)
      return "OIL";

// Por defecto, asumir forex
   return "FOREX";
  }
  


//+------------------------------------------------------------------+
//| NUEVA FUNCIÓN: Ajustar trailing según instrumento               |
//+------------------------------------------------------------------+
void OrderExecution::AdjustTrailingForInstrument()
  {
   string instrumentType = GetInstrumentType();

   Print("Tipo de instrumento detectado: ", instrumentType);

   if(instrumentType == "FOREX")
     {
      // Configuración para divisas - más conservadora
      // Etapa 0 - Inicial
      m_trailingStages[0].activationPips = 50.0;  // Activar después de 50 pips
      m_trailingStages[0].trailingPips = 30.0;    // Trailing a 30 pips
      m_trailingStages[0].stepPips = 5.0;         // Step de 5 pips
      m_trailingStages[0].useATR = true;
      m_trailingStages[0].atrMultiplier = 2.0;

      // Etapa 1 - Medio
      m_trailingStages[1].activationPips = 80.0;  // Después de 80 pips
      m_trailingStages[1].trailingPips = 40.0;    // Trailing a 40 pips
      m_trailingStages[1].stepPips = 10.0;
      m_trailingStages[1].useATR = true;
      m_trailingStages[1].atrMultiplier = 2.5;

      // Etapa 2 - Runner
      m_trailingStages[2].activationPips = 120.0; // Después de 120 pips
      m_trailingStages[2].trailingPips = 50.0;    // Trailing a 50 pips
      m_trailingStages[2].stepPips = 15.0;
      m_trailingStages[2].useATR = true;
      m_trailingStages[2].atrMultiplier = 3.0;

      // Etapa 3 - MOMENTUM (agresiva)
      m_trailingStages[3].activationPips = m_trailingStages[2].activationPips + 50.0;
      m_trailingStages[3].trailingPips    = m_trailingStages[2].trailingPips + 20.0;
      m_trailingStages[3].stepPips        = m_trailingStages[2].stepPips + 5.0;
      m_trailingStages[3].useATR          = true;
      m_trailingStages[3].atrMultiplier   = m_trailingStages[2].atrMultiplier + 0.5;

      // Etapa 4 - CUSTOM (según régimen)
      m_trailingStages[4].activationPips = m_trailingStages[3].activationPips + 80.0;
      m_trailingStages[4].trailingPips    = m_trailingStages[3].trailingPips + 30.0;
      m_trailingStages[4].stepPips        = m_trailingStages[3].stepPips + 5.0;
      m_trailingStages[4].useATR          = true;
      m_trailingStages[4].atrMultiplier   = m_trailingStages[3].atrMultiplier + 1.0;
     }
   else
      if(instrumentType == "GOLD")
        {
         // Configuración para oro - más amplia por la volatilidad
         // Etapa 0
         m_trailingStages[0].activationPips = 150.0; // $1.50 de movimiento
         m_trailingStages[0].trailingPips = 100.0;   // $1.00 de trailing
         m_trailingStages[0].stepPips = 20.0;
         m_trailingStages[0].useATR = true;
         m_trailingStages[0].atrMultiplier = 2.5;

         // Etapa 1
         m_trailingStages[1].activationPips = 250.0; // $2.50
         m_trailingStages[1].trailingPips = 150.0;   // $1.50
         m_trailingStages[1].stepPips = 30.0;
         m_trailingStages[1].useATR = true;
         m_trailingStages[1].atrMultiplier = 3.0;

         // Etapa 2
         m_trailingStages[2].activationPips = 400.0; // $4.00
         m_trailingStages[2].trailingPips = 200.0;   // $2.00
         m_trailingStages[2].stepPips = 50.0;
         m_trailingStages[2].useATR = true;
         m_trailingStages[2].atrMultiplier = 3.5;

         // Etapa 3 - MOMENTUM (agresiva)
         m_trailingStages[3].activationPips = m_trailingStages[2].activationPips + 50.0;
         m_trailingStages[3].trailingPips    = m_trailingStages[2].trailingPips + 20.0;
         m_trailingStages[3].stepPips        = m_trailingStages[2].stepPips + 5.0;
         m_trailingStages[3].useATR          = true;
         m_trailingStages[3].atrMultiplier   = m_trailingStages[2].atrMultiplier + 0.5;

         // Etapa 4 - CUSTOM (según régimen)
         m_trailingStages[4].activationPips = m_trailingStages[3].activationPips + 80.0;
         m_trailingStages[4].trailingPips    = m_trailingStages[3].trailingPips + 30.0;
         m_trailingStages[4].stepPips        = m_trailingStages[3].stepPips + 5.0;
         m_trailingStages[4].useATR          = true;
         m_trailingStages[4].atrMultiplier   = m_trailingStages[3].atrMultiplier + 1.0;
        }
      else
         if(instrumentType == "SILVER")
           {
            // Configuración para plata
            // Etapa 0
            m_trailingStages[0].activationPips = 30.0;  // $0.30
            m_trailingStages[0].trailingPips = 20.0;    // $0.20
            m_trailingStages[0].stepPips = 5.0;
            m_trailingStages[0].useATR = true;
            m_trailingStages[0].atrMultiplier = 2.0;

            // Etapa 1
            m_trailingStages[1].activationPips = 50.0;  // $0.50
            m_trailingStages[1].trailingPips = 30.0;    // $0.30
            m_trailingStages[1].stepPips = 10.0;
            m_trailingStages[1].useATR = true;
            m_trailingStages[1].atrMultiplier = 2.5;

            // Etapa 2
            m_trailingStages[2].activationPips = 80.0;  // $0.80
            m_trailingStages[2].trailingPips = 40.0;    // $0.40
            m_trailingStages[2].stepPips = 15.0;
            m_trailingStages[2].useATR = true;
            m_trailingStages[2].atrMultiplier = 3.0;

            // Etapa 3 - MOMENTUM (agresiva)
            m_trailingStages[3].activationPips = m_trailingStages[2].activationPips + 50.0;
            m_trailingStages[3].trailingPips    = m_trailingStages[2].trailingPips + 20.0;
            m_trailingStages[3].stepPips        = m_trailingStages[2].stepPips + 5.0;
            m_trailingStages[3].useATR          = true;
            m_trailingStages[3].atrMultiplier   = m_trailingStages[2].atrMultiplier + 0.5;

            // Etapa 4 - CUSTOM (según régimen)
            m_trailingStages[4].activationPips = m_trailingStages[3].activationPips + 80.0;
            m_trailingStages[4].trailingPips    = m_trailingStages[3].trailingPips + 30.0;
            m_trailingStages[4].stepPips        = m_trailingStages[3].stepPips + 5.0;
            m_trailingStages[4].useATR          = true;
            m_trailingStages[4].atrMultiplier   = m_trailingStages[3].atrMultiplier + 1.0;
           }
         else
            if(instrumentType == "INDEX")
              {
               // Configuración para índices
               // Etapa 0
               m_trailingStages[0].activationPips = 100.0;
               m_trailingStages[0].trailingPips = 60.0;
               m_trailingStages[0].stepPips = 15.0;
               m_trailingStages[0].useATR = true;
               m_trailingStages[0].atrMultiplier = 2.0;

               // Etapa 1
               m_trailingStages[1].activationPips = 200.0;
               m_trailingStages[1].trailingPips = 100.0;
               m_trailingStages[1].stepPips = 25.0;
               m_trailingStages[1].useATR = true;
               m_trailingStages[1].atrMultiplier = 2.5;

               // Etapa 2
               m_trailingStages[2].activationPips = 350.0;
               m_trailingStages[2].trailingPips = 150.0;
               m_trailingStages[2].stepPips = 40.0;
               m_trailingStages[2].useATR = true;
               m_trailingStages[2].atrMultiplier = 3.0;

               // Etapa 3 - MOMENTUM (agresiva)
               m_trailingStages[3].activationPips = m_trailingStages[2].activationPips + 50.0;
               m_trailingStages[3].trailingPips    = m_trailingStages[2].trailingPips + 20.0;
               m_trailingStages[3].stepPips        = m_trailingStages[2].stepPips + 5.0;
               m_trailingStages[3].useATR          = true;
               m_trailingStages[3].atrMultiplier   = m_trailingStages[2].atrMultiplier + 0.5;

               // Etapa 4 - CUSTOM (según régimen)
               m_trailingStages[4].activationPips = m_trailingStages[3].activationPips + 80.0;
               m_trailingStages[4].trailingPips    = m_trailingStages[3].trailingPips + 30.0;
               m_trailingStages[4].stepPips        = m_trailingStages[3].stepPips + 5.0;
               m_trailingStages[4].useATR          = true;
               m_trailingStages[4].atrMultiplier   = m_trailingStages[3].atrMultiplier + 1.0;
              }
            else
               if(instrumentType == "OIL")
                 {
                  // Configuración para petróleo
                  // Etapa 0
                  m_trailingStages[0].activationPips = 80.0;
                  m_trailingStages[0].trailingPips = 50.0;
                  m_trailingStages[0].stepPips = 10.0;
                  m_trailingStages[0].useATR = true;
                  m_trailingStages[0].atrMultiplier = 2.0;

                  // Etapa 1
                  m_trailingStages[1].activationPips = 150.0;
                  m_trailingStages[1].trailingPips = 80.0;
                  m_trailingStages[1].stepPips = 20.0;
                  m_trailingStages[1].useATR = true;
                  m_trailingStages[1].atrMultiplier = 2.5;

                  // Etapa 2
                  m_trailingStages[2].activationPips = 250.0;
                  m_trailingStages[2].trailingPips = 120.0;
                  m_trailingStages[2].stepPips = 30.0;
                  m_trailingStages[2].useATR = true;
                  m_trailingStages[2].atrMultiplier = 3.0;

                  // Etapa 3 - MOMENTUM (agresiva)
                  m_trailingStages[3].activationPips = m_trailingStages[2].activationPips + 50.0;
                  m_trailingStages[3].trailingPips    = m_trailingStages[2].trailingPips + 20.0;
                  m_trailingStages[3].stepPips        = m_trailingStages[2].stepPips + 5.0;
                  m_trailingStages[3].useATR          = true;
                  m_trailingStages[3].atrMultiplier   = m_trailingStages[2].atrMultiplier + 0.5;

                  // Etapa 4 - CUSTOM (según régimen)
                  m_trailingStages[4].activationPips = m_trailingStages[3].activationPips + 80.0;
                  m_trailingStages[4].trailingPips    = m_trailingStages[3].trailingPips + 30.0;
                  m_trailingStages[4].stepPips        = m_trailingStages[3].stepPips + 5.0;
                  m_trailingStages[4].useATR          = true;
                  m_trailingStages[4].atrMultiplier   = m_trailingStages[3].atrMultiplier + 1.0;
                 }

   Print("Trailing configurado para ", instrumentType, ":");
   Print("  Etapa 0: Activación=", m_trailingStages[0].activationPips,
         " Trailing=", m_trailingStages[0].trailingPips,
         " Step=", m_trailingStages[0].stepPips);
   Print("  Etapa 1: Activación=", m_trailingStages[1].activationPips,
         " Trailing=", m_trailingStages[1].trailingPips,
         " Step=", m_trailingStages[1].stepPips);
   Print("  Etapa 2: Activación=", m_trailingStages[2].activationPips,
         " Trailing=", m_trailingStages[2].trailingPips,
         " Step=", m_trailingStages[2].stepPips);
  }



//+------------------------------------------------------------------+
//| IMPLEMENTACIONES DEL SISTEMA MULTI-ÓRDENES MEJORADO              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Determinar número óptimo de órdenes basado en confianza ML       |
//+------------------------------------------------------------------+
int OrderExecution::DetermineOptimalOrderCount(double consensusStrength, double mlScore)
{
    // Combinación de consenso y ML para determinar número de órdenes
    double combinedScore = (consensusStrength * 0.6) + (mlScore * 0.4);
    
    int orderCount = 1; // Mínimo 1 orden
    
    if(combinedScore > 0.75)
    {
        orderCount = MathMin(m_maxOrdersPerCycle, 4); // Alta confianza: hasta 4 órdenes
        Print("▶ ALTA CONFIANZA (", DoubleToString(combinedScore, 3), ") → ", orderCount, " órdenes");
    }
    else if(combinedScore > 0.60)
    {
        orderCount = 3; // Confianza media-alta: 3 órdenes
        Print("▶ CONFIANZA MEDIA-ALTA (", DoubleToString(combinedScore, 3), ") → ", orderCount, " órdenes");
    }
    else if(combinedScore > 0.45)
    {
        orderCount = 2; // Confianza media: 2 órdenes
        Print("▶ CONFIANZA MEDIA (", DoubleToString(combinedScore, 3), ") → ", orderCount, " órdenes");
    }
    else
    {
        orderCount = 1; // Baja confianza: solo 1 orden
        Print("▶ CONFIANZA BÁSICA (", DoubleToString(combinedScore, 3), ") → ", orderCount, " orden");
    }
    
    return orderCount;
}


//+------------------------------------------------------------------+
//| Calcular lote progresivo para órdenes adicionales                |
//+------------------------------------------------------------------+
double OrderExecution::CalculateProgressiveLot(int orderIndex, double baseLot)
{
    if(orderIndex == 0)
        return baseLot; // Primera orden usa lote base
    
    // Reducción progresiva: cada orden usa un % menos
    double reductionFactor = m_orderReduction / 100.0;
    double progressiveLot = baseLot * MathPow(1.0 - reductionFactor, orderIndex);
    
    // Asegurar que no sea menor al mínimo del símbolo
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    
    progressiveLot = MathMax(minLot, progressiveLot);
    progressiveLot = MathMin(maxLot, progressiveLot);
    
    // Normalizar al step del símbolo
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    progressiveLot = MathRound(progressiveLot / lotStep) * lotStep;
    
    return progressiveLot;
}

//+------------------------------------------------------------------+
//| Validar si se puede ejecutar la siguiente orden                  |
//+------------------------------------------------------------------+
bool OrderExecution::CanExecuteNextOrder(int orderIndex)
{
    // Si es la primera orden, siempre se puede ejecutar
    if(orderIndex == 0)
        return true;
    
    // Verificar que la orden anterior fue exitosa
    if(orderIndex > 0 && orderIndex <= m_multiOrder.orderCount)
    {
        ulong prevTicket = m_multiOrder.tickets[orderIndex - 1];
        if(prevTicket == 0)
        {
            Print("✗ Orden anterior #", orderIndex, " no tiene ticket válido");
            return false;
        }
        
        // Verificar que la posición aún existe
        if(!PositionSelectByTicket(prevTicket))
        {
            Print("✗ Orden anterior #", orderIndex, " ya fue cerrada");
            return false;
        }
    }
    
    // Verificar movimiento favorable del precio
    if(m_multiOrder.orderCount > 0)
    {
        double firstEntryPrice = m_multiOrder.entryPrices[0];
        int direction = (m_multiOrder.direction == DIRECTION_BUY) ? 1 : -1;
        
        double currentPrice = (direction > 0) ? 
                             SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                             SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        
        double priceMovement = (direction > 0) ? 
                              (currentPrice - firstEntryPrice) :
                              (firstEntryPrice - currentPrice);
        
        double minMovement = 10 * _Point; // Mínimo 10 puntos
        
        // Reducir requisito para segunda orden
        if(orderIndex == 1)
            minMovement *= 0.5; // Solo 50% para segunda orden (5 puntos)
        else if(orderIndex == 2)
            minMovement *= 0.75; // 75% para tercera orden (7.5 puntos)
        
        if(priceMovement < minMovement)
        {
            Print("⚠ Movimiento insuficiente para orden #", orderIndex + 1, 
                  ": ", DoubleToString(priceMovement/_Point, 1), " pts (req: ",
                  DoubleToString(minMovement/_Point, 1), " pts)");
            return false;
        }
    }
    
    // Verificar tiempo mínimo entre órdenes
    if(m_multiOrder.cycleStartTime > 0)
    {
        if(TimeCurrent() - m_multiOrder.cycleStartTime < 2)
        {
            Print("⚠ Esperando intervalo mínimo entre órdenes");
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Ejecutar orden individual con reintentos inteligentes            |
//+------------------------------------------------------------------+
bool OrderExecution::ExecuteOrderWithRetry(int orderIndex, int direction, 
                                            double lotSize, double conviction, double touchPrice)
{
    const int MAX_RETRIES = 4;
    const int RETRY_DELAY_MS = 200;
    
    bool success = false;
    int attempts = 0;
    
    Print("───────────────────────────────────────");
    Print("📤 Ejecutando Orden #", orderIndex + 1);
    Print("  Dirección: ", (direction > 0 ? "BUY" : "SELL"));
    Print("  Lote: ", DoubleToString(lotSize, 3));
    
    while(!success && attempts < MAX_RETRIES)
    {
        ResetLastError();
        
        // Primera orden usa ExecuteFirstOrder, adicionales usan ExecuteAdditionalOrder
        if(orderIndex == 0)
        {
            success = ExecuteFirstOrder(direction, conviction, touchPrice);
        }
        else
        {
            success = ExecuteAdditionalOrder(direction, conviction);
        }
        
        if(success)
        {
            Print("✅ Orden #", orderIndex + 1, " ejecutada exitosamente");
            break;
        }
        
        int err = GetLastError();
        attempts++;
        
        Print("✗ Intento ", attempts, "/", MAX_RETRIES, " fallido. Error: ", err);
        
        // Analizar tipo de error
        if(err == TRADE_RETCODE_REQUOTE || err == TRADE_RETCODE_PRICE_CHANGED || err == 4756)
        {
            // Errores transitorios - reintentar con delay
            Sleep(RETRY_DELAY_MS);
            continue;
        }
        else if(err == TRADE_RETCODE_INVALID_STOPS || err == TRADE_RETCODE_INVALID_PRICE)
        {
            // Error de stops - salir del bucle
            Print("⚠ Error de stops inválidos");
            break;
        }
        else if(err == TRADE_RETCODE_NO_MONEY)
        {
            // Sin dinero - no reintentar
            Print("✗ Fondos insuficientes");
            return false;
        }
        else
        {
            // Otros errores - un reintento más
            Sleep(RETRY_DELAY_MS / 2);
        }
    }
    
    return success;
}

//+------------------------------------------------------------------+
//| Actualizar precio promedio de entrada                            |
//+------------------------------------------------------------------+
void OrderExecution::UpdateAverageEntry()
{
    double totalWeightedPrice = 0.0;
    double totalLots = 0.0;
    
    for(int i = 0; i < m_multiOrder.orderCount; i++)
    {
        if(m_multiOrder.tickets[i] > 0)
        {
            if(PositionSelectByTicket(m_multiOrder.tickets[i]))
            {
                double price = PositionGetDouble(POSITION_PRICE_OPEN);
                double lot = PositionGetDouble(POSITION_VOLUME);
                
                totalWeightedPrice += price * lot;
                totalLots += lot;
            }
        }
    }
    
    if(totalLots > 0)
    {
        double avgEntry = totalWeightedPrice / totalLots;
        // Actualizar si es diferente
        if(MathAbs(m_multiOrder.entryPrices[0] - avgEntry) > _Point)
        {
            Print("📊 Precio promedio actualizado: ", DoubleToString(avgEntry, _Digits));
        }
    }
}

//+------------------------------------------------------------------+
//| Actualizar profit no realizado del ciclo                         |
//+------------------------------------------------------------------+
void OrderExecution::UpdateUnrealizedProfit()
{
    double totalProfit = 0.0;
    int activeCount = 0;
    
    for(int i = 0; i < m_multiOrder.orderCount; i++)
    {
        if(m_multiOrder.tickets[i] > 0)
        {
            if(PositionSelectByTicket(m_multiOrder.tickets[i]))
            {
                totalProfit += PositionGetDouble(POSITION_PROFIT);
                activeCount++;
            }
        }
    }
    
    m_multiOrder.cycleProfit = totalProfit;
    
    // Actualizar máximo profit
    if(totalProfit > m_multiOrder.cycleMaxProfit)
    {
        m_multiOrder.cycleMaxProfit = totalProfit;
    }
}

//+------------------------------------------------------------------+
//| Mostrar resumen del ciclo multi-orden                            |
//+------------------------------------------------------------------+
void OrderExecution::ShowMultiOrderSummary()
{
    Print("╔══════════════════════════════════════════════════════╗");
    Print("║       RESUMEN DEL CICLO MULTI-ORDEN                  ║");
    Print("╚══════════════════════════════════════════════════════╝");
    Print("  Órdenes ejecutadas:   ", m_multiOrder.orderCount);
    Print("  Dirección:            ", (m_multiOrder.direction == DIRECTION_BUY ? "BUY" : "SELL"));
    Print("  Lote base:            ", DoubleToString(m_multiOrder.baseLotSize, 3));
    Print("  Profit actual:        $", DoubleToString(m_multiOrder.cycleProfit, 2));
    Print("  Profit máximo:        $", DoubleToString(m_multiOrder.cycleMaxProfit, 2));
    Print("  Consenso:             ", DoubleToString(m_multiOrder.consensusStrength, 3));
    Print("╚══════════════════════════════════════════════════════╝");
}

//+------------------------------------------------------------------+
//| Imprimir estado detallado del ciclo                             |
//+------------------------------------------------------------------+
void OrderExecution::PrintCycleStatus()
  {
   if(!m_multiOrder.cycleActive)
      return;

   Print("═══ ESTADO DEL CICLO ═══");
   Print("Dirección: ", EnumToString(m_multiOrder.direction));
   Print("Órdenes activas: ", m_multiOrder.orderCount, "/", m_maxOrdersPerCycle);
   Print("Precio inicial: ", DoubleToString(m_initialEntryPrice, _Digits));
   
   double currentPrice = (m_multiOrder.direction == DIRECTION_BUY) ?
                        SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                        SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   double movement = MathAbs(currentPrice - m_initialEntryPrice) / _Point;
   Print("Movimiento: ", DoubleToString(movement, 1), " puntos");
   
   int ordersInProfit = 0;
   double totalProfit = 0;
   HasOrdersInProfit(ordersInProfit, totalProfit);
   Print("Órdenes en profit: ", ordersInProfit, "/", m_multiOrder.orderCount);
   Print("P&L total: $", DoubleToString(totalProfit, 2));
   Print("═══════════════════════");
  }


//+------------------------------------------------------------------+
//| Proceso principal optimizado de ejecución multi-orden            |
//+------------------------------------------------------------------+
int OrderExecution::ExecuteMultiOrderCycleOptimized(int direction, double baseLotSize,
                                                     int plannedOrders, double consensusStrength,
                                                     double mlScore, double conviction, double touchPrice)
{
    Print("╔═══════════════════════════════════════════════════════╗");
    Print("║    EJECUTANDO CICLO MULTI-ORDEN OPTIMIZADO           ║");
    Print("╚═══════════════════════════════════════════════════════╝");
    
    // ✅ VALIDACIÓN CRÍTICA: Verificar que no haya ciclo activo
    if(!ValidateNewCycleExecution(direction))
    {
        Print("✗ Validación fallida - No se puede ejecutar nuevo ciclo");
        return 0;
    }
    
    
    // ✅ VALIDACIÓN: Limitar órdenes planificadas
    plannedOrders = MathMin(plannedOrders, m_maxOrdersPerCycle);
    plannedOrders = MathMin(plannedOrders, 3); // Hard limit
    
    // Guardar para referencia
    m_plannedOrdersForCycle = plannedOrders;
    
    // Reiniciar ciclo
    ResetMultiOrderCycle();
    
    // Configurar ciclo
    m_multiOrder.cycleActive = true;
    m_multiOrder.direction = (direction > 0) ? DIRECTION_BUY : DIRECTION_SELL;
    m_multiOrder.baseLotSize = baseLotSize;
    m_multiOrder.consensusStrength = consensusStrength;
    m_multiOrder.cycleStartTime = TimeCurrent();
    m_initialEntryPrice = 0;
    m_lastOrderTime = TimeCurrent();
    
    Print("📋 Configuración del ciclo:");
    Print("   Dirección: ", (direction > 0 ? "BUY" : "SELL"));
    Print("   Lote base: ", DoubleToString(baseLotSize, 3));
    Print("   Órdenes planificadas: ", plannedOrders);
    Print("   Consenso: ", DoubleToString(consensusStrength, 3));
    
    // ✅ CORRECCIÓN CRÍTICA: Ejecutar SOLO la primera orden
    Print("▶ Ejecutando ORDEN #1 (primera)");
    
    double lotForFirstOrder = baseLotSize;
    
    bool success = ExecuteOrderWithRetry(0, direction, lotForFirstOrder, conviction, touchPrice);
    
    if(success)
    {
        Print("✅ Primera orden ejecutada exitosamente");
        Print("   Ticket: ", m_multiOrder.tickets[0]);
        Print("   Lote: ", DoubleToString(lotForFirstOrder, 3));
        Print("   Entry: ", DoubleToString(m_multiOrder.entryPrices[0], _Digits));
        
        m_initialEntryPrice = m_multiOrder.entryPrices[0];
        
        if(plannedOrders > 1)
        {
            Print("⏳ Las órdenes adicionales se agregarán progresivamente");
        }
        
        UpdateAverageEntry();
        UpdateUnrealizedProfit();
        
        return 1;
    }
    else
    {
        Print("✗ Fallo al ejecutar primera orden - Abortando ciclo");
        ResetMultiOrderCycle();
        return 0;
    }
}



//+------------------------------------------------------------------+
//| ✅ MÉTODO NUEVO: Intentar agregar órdenes progresivamente        |
//+------------------------------------------------------------------+
bool OrderExecution::TryAddProgressiveOrders()
{
    // ═══════════════════════════════════════════════════════════════
    // Este método se debe llamar desde OnTick() del EA principal
    // para agregar órdenes adicionales al ciclo activo
    // ═══════════════════════════════════════════════════════════════
    
    // 1. VALIDAR CICLO ACTIVO
    if(!m_multiOrder.cycleActive)
    {
        return false; // No hay ciclo activo
    }
    
    if(m_multiOrder.orderCount == 0)
    {
        Print("⚠ Ciclo activo pero sin órdenes - Estado inconsistente");
        return false;
    }
    
    // 2. VERIFICAR SI YA SE COMPLETARON TODAS LAS ÓRDENES PLANIFICADAS
    if(m_multiOrder.orderCount >= m_plannedOrdersForCycle)
    {
        return false; // Ya se ejecutaron todas las órdenes planificadas
    }
    
    // 3. VERIFICAR TIEMPO MÍNIMO DESDE LA ÚLTIMA ORDEN
    int minTimeBetweenOrders = 30; // 30 segundos mínimo
    if(TimeCurrent() - m_lastOrderTime < minTimeBetweenOrders)
    {
        return false; // Muy pronto para agregar otra orden
    }
    
    // 4. OBTENER PRECIO ACTUAL Y DIRECCIÓN
    double currentPrice;
    if(m_multiOrder.direction == DIRECTION_BUY)
        currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    else
        currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    // 5. CALCULAR MOVIMIENTO DESDE ENTRADA INICIAL
    double movementPoints = MathAbs(currentPrice - m_initialEntryPrice) / _Point;
    double movementPips = PointsToPips(movementPoints);
    
    // 6. VERIFICAR MOVIMIENTO MÍNIMO (10 pips)
    double minMovementPips = 10.0;
    if(movementPips < minMovementPips)
    {
        // Print("⏳ Movimiento insuficiente: ", DoubleToString(movementPips, 1), " pips");
        return false;
    }
    
    // 7. VERIFICAR QUE EL MOVIMIENTO SEA FAVORABLE
    bool movementFavorable = false;
    if(m_multiOrder.direction == DIRECTION_BUY && currentPrice > m_initialEntryPrice)
        movementFavorable = true;
    else if(m_multiOrder.direction == DIRECTION_SELL && currentPrice < m_initialEntryPrice)
        movementFavorable = true;
    
    if(!movementFavorable)
    {
        Print("⚠ Movimiento desfavorable - Precio actual vs entrada: ", 
              DoubleToString(currentPrice, _Digits), " vs ", 
              DoubleToString(m_initialEntryPrice, _Digits));
        return false;
    }
    
    // 8. ACTUALIZAR Y VERIFICAR PROFIT DEL CICLO
    UpdateUnrealizedProfit();
    
    if(m_multiOrder.cycleProfit <= 0)
    {
        Print("⚠ Ciclo aún sin profit ($", DoubleToString(m_multiOrder.cycleProfit, 2), 
              ") - No agregar órdenes");
        return false;
    }
    
    // 9. VERIFICAR PROFIT MÍNIMO (equivalente a 5 pips de la primera orden)
    double minProfitRequired = 5.0; // En dólares (ajustar según cuenta)
    if(m_multiOrder.cycleProfit < minProfitRequired)
    {
        Print("⚠ Profit insuficiente para agregar orden: $", 
              DoubleToString(m_multiOrder.cycleProfit, 2), 
              " (mínimo: $", minProfitRequired, ")");
        return false;
    }
    
    // ✅ TODAS LAS VALIDACIONES PASADAS - EJECUTAR SIGUIENTE ORDEN
    int nextOrderIndex = m_multiOrder.orderCount;
    
    Print("╔════════════════════════════════════════════════════════╗");
    Print("║  AGREGANDO ORDEN PROGRESIVA #", nextOrderIndex + 1, "                      ║");
    Print("╚════════════════════════════════════════════════════════╝");
    Print("  Movimiento favorable: ", DoubleToString(movementPips, 1), " pips");
    Print("  Profit del ciclo: $", DoubleToString(m_multiOrder.cycleProfit, 2));
    Print("  Órdenes actuales: ", m_multiOrder.orderCount, "/", m_plannedOrdersForCycle);
    
    // 10. CALCULAR LOTE PROGRESIVO (REDUCIDO)
    double lotForNextOrder = m_multiOrder.baseLotSize * m_orderReduction;
    
    // Normalizar el lote
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    lotForNextOrder = MathMax(minLot, lotForNextOrder);
    lotForNextOrder = MathMin(maxLot, lotForNextOrder);
    lotForNextOrder = MathFloor(lotForNextOrder / lotStep) * lotStep;
    
    Print("  Lote calculado: ", DoubleToString(lotForNextOrder, 3));
    
    // 11. EJECUTAR LA ORDEN CON REINTENTOS
    int direction = (m_multiOrder.direction == DIRECTION_BUY) ? 1 : -1;
    
    bool success = ExecuteOrderWithRetry(nextOrderIndex, direction, lotForNextOrder, 
                                         m_multiOrder.consensusStrength, currentPrice);
    
    if(success)
    {
        Print("✅ Orden #", nextOrderIndex + 1, " agregada exitosamente");
        Print("   Ticket: ", m_multiOrder.tickets[nextOrderIndex]);
        Print("   Lote: ", DoubleToString(lotForNextOrder, 3));
        Print("   Entry: ", DoubleToString(m_multiOrder.entryPrices[nextOrderIndex], _Digits));
        Print("   Órdenes en ciclo: ", m_multiOrder.orderCount, "/", m_plannedOrdersForCycle);
        Print("╚════════════════════════════════════════════════════════╝");
        
        // Actualizar timestamp
        m_lastOrderTime = TimeCurrent();
        
        // Actualizar métricas del ciclo
        UpdateAverageEntry();
        UpdateUnrealizedProfit();
        
        return true;
    }
    else
    {
        Print("✗ Fallo al agregar orden #", nextOrderIndex + 1);
        Print("╚════════════════════════════════════════════════════════╝");
        return false;
    }
}

//+------------------------------------------------------------------+
//| ✅ MÉTODO MEJORADO: Trailing a nivel de CICLO completo          |
//+------------------------------------------------------------------+
bool OrderExecution::UpdateCycleTrailingStop()
{
    // ═══════════════════════════════════════════════════════════════
    // TRAILING A NIVEL DE CICLO - NO POR ORDEN INDIVIDUAL
    // Esto evita cierres prematuros y gestiona todo el ciclo como
    // una sola posición
    // ═══════════════════════════════════════════════════════════════
    
    if(!m_multiOrder.cycleActive || m_multiOrder.orderCount == 0)
        return false;
    
    // Actualizar profit actual del ciclo
    UpdateUnrealizedProfit();
    
    double cycleProfit = m_multiOrder.cycleProfit;
    
    // Configuración del trailing (basado en profit del ciclo)
    double activationProfitUSD = 15.0; // Activar trailing con $15 de profit
    double trailingDistancePercent = 0.5; // Proteger 50% del max profit
    
    // Verificar si se debe activar el trailing
    if(!m_multiOrder.cycleTrailingActive)
    {
        if(cycleProfit >= activationProfitUSD)
        {
            m_multiOrder.cycleTrailingActive = true;
            m_multiOrder.cycleMaxProfit = cycleProfit;
            m_multiOrder.cycleTrailingActivationPrice = (m_multiOrder.direction == DIRECTION_BUY) ?
                                                        SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                                                        SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            
            Print("╔════════════════════════════════════════════════════════╗");
            Print("║     TRAILING ACTIVADO PARA EL CICLO COMPLETO          ║");
            Print("╚════════════════════════════════════════════════════════╝");
            Print("  Profit actual: $", DoubleToString(cycleProfit, 2));
            Print("  Protección: ", DoubleToString(trailingDistancePercent * 100, 0), "%");
        }
        return false;
    }
    
    // Actualizar máximo profit alcanzado
    if(cycleProfit > m_multiOrder.cycleMaxProfit)
    {
        m_multiOrder.cycleMaxProfit = cycleProfit;
        Print("📈 Nuevo máximo profit del ciclo: $", DoubleToString(cycleProfit, 2));
    }
    
    // Calcular nivel de protección
    double protectedProfit = m_multiOrder.cycleMaxProfit * trailingDistancePercent;
    
    // Verificar si el profit cayó por debajo del nivel de protección
    if(cycleProfit < protectedProfit)
    {
        Print("╔════════════════════════════════════════════════════════╗");
        Print("║     TRAILING ALCANZADO - CERRANDO CICLO COMPLETO      ║");
        Print("╚════════════════════════════════════════════════════════╝");
        Print("  Profit máximo alcanzado: $", DoubleToString(m_multiOrder.cycleMaxProfit, 2));
        Print("  Profit actual: $", DoubleToString(cycleProfit, 2));
        Print("  Nivel de protección: $", DoubleToString(protectedProfit, 2));
        Print("  Órdenes a cerrar: ", m_multiOrder.orderCount);
        
        // Cerrar TODAS las órdenes del ciclo
        bool allClosed = true;
        for(int i = 0; i < m_multiOrder.orderCount; i++)
        {
            if(m_multiOrder.tickets[i] > 0)
            {
                if(PositionSelectByTicket(m_multiOrder.tickets[i]))
                {
                    Print("  Cerrando orden #", i + 1, " (Ticket: ", m_multiOrder.tickets[i], ")");
                    
                    if(!m_trade.PositionClose(m_multiOrder.tickets[i]))
                    {
                        Print("  ⚠ Error cerrando ticket ", m_multiOrder.tickets[i], 
                              " - Error: ", GetLastError());
                        allClosed = false;
                    }
                    else
                    {
                        Print("  ✅ Orden #", i + 1, " cerrada exitosamente");
                    }
                }
            }
        }
        
        if(allClosed)
        {
            Print("✅ Ciclo completo cerrado por trailing");
            Print("╚════════════════════════════════════════════════════════╝");
            
            // Finalizar el ciclo
            ResetMultiOrderCycle();
            return true;
        }
        else
        {
            Print("⚠ Algunas órdenes no se pudieron cerrar");
            Print("╚════════════════════════════════════════════════════════╝");
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| ✅ VALIDACIÓN MEJORADA: Evitar ciclos duplicados                |
//+------------------------------------------------------------------+
bool OrderExecution::ValidateNewCycleExecution(int direction)
{
    // Verificar si ya hay un ciclo activo
    if(m_multiOrder.cycleActive && m_multiOrder.orderCount > 0)
    {
        Print("⚠ VALIDACIÓN FALLIDA: Ya hay un ciclo activo");
        Print("  Ciclo actual: ", m_multiOrder.orderCount, " órdenes");
        Print("  Dirección actual: ", EnumToString(m_multiOrder.direction));
        Print("  ❌ RECHAZANDO nueva ejecución");
        return false;
    }
    
    // Verificar que no haya posiciones abiertas del magic number
    int totalPositions = PositionsTotal();
    int cyclePositions = 0;
    
    for(int i = 0; i < totalPositions; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket))
        {
            if(PositionGetInteger(POSITION_MAGIC) == m_magicNumber &&
               PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
                cyclePositions++;
            }
        }
    }
    
    if(cyclePositions > 0)
    {
        Print("⚠ VALIDACIÓN FALLIDA: Hay ", cyclePositions, " posiciones abiertas");
        Print("  ❌ Completar o cerrar ciclo anterior antes de iniciar nuevo");
        return false;
    }
    
    Print("✅ Validación exitosa - Puede iniciar nuevo ciclo");
    return true;
}

#endif // ORDER_EXECUTION_NCN_V11_03_MQH
//+------------------------------------------------------------------+
