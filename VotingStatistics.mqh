//+------------------------------------------------------------------+
//|                                   VotingStatistics_NCN_v12.mqh   |
//|                          Neural Consensus Network v12            |
//|                    Con Sistema de Privilegios por Performance    |
//+------------------------------------------------------------------+
#property copyright "Neural Consensus Network v12 - Performance-Based Privileges"
#property version   "12.00"

double VS_MapConsensus(double p){ return p; } // stub (calibrator opcional)

#include <MetaLearningSystem.mqh>
//+------------------------------------------------------------------+
//| Enumeraciones base                                               |
//+------------------------------------------------------------------+
// ENUM_VOTE_DIRECTION is now defined in MetaLearningSystem.mqh

enum ENUM_COMPONENT_TYPE
{
    COMPONENT_SUPPORT_RESIST = 0,
    COMPONENT_ACCUM_ZONES = 1,
    COMPONENT_PATTERN_MEMORY = 2,
    COMPONENT_BREAKOUT_DETECT = 3,
    COMPONENT_INSTITUTIONAL = 4
};

//+------------------------------------------------------------------+
//| Estructura para emoción del mercado                             |
//+------------------------------------------------------------------+
struct MarketEmotion
{
    double fear;        // Nivel de miedo (0-1)
    double greed;       // Nivel de codicia (0-1)
    double uncertainty; // Nivel de incertidumbre (0-1)
    double excitement;  // Nivel de emoción (0-1)
    datetime timestamp;
    
    MarketEmotion()
    {
        fear = 0.5;
        greed = 0.5;
        uncertainty = 0.5;
        excitement = 0.5;
        timestamp = 0;
    }
};

//+------------------------------------------------------------------+
//| Estructura de contexto de decisión                              |
//+------------------------------------------------------------------+
struct DecisionContext
{
    datetime timestamp;
    double volatility;
    double momentum;
    double volume_ratio;
    int session_type;
    double rsi;
    double atr_ratio;
    double fear_level;
    double greed_level;
    int active_orders;
    ENUM_VOTE_DIRECTION locked_direction;
};
// Helper: serialize DecisionContext to string for MetaLearning
string DecisionContextToString(const DecisionContext &ctx)
{
    return StringFormat("ts=%s;vol=%.3f;mom=%.3f;volR=%.3f;session=%d;rsi=%.2f;atrR=%.3f;fear=%.3f;greed=%.3f;active=%d;locked=%d",
                        TimeToString(ctx.timestamp, TIME_MINUTES),
                        ctx.volatility, ctx.momentum, ctx.volume_ratio, ctx.session_type,
                        ctx.rsi, ctx.atr_ratio, ctx.fear_level, ctx.greed_level,
                        ctx.active_orders, (int)ctx.locked_direction);
}


//+------------------------------------------------------------------+
//| Estructura para voto neuronal mejorado                          |
//+------------------------------------------------------------------+
struct NeuralVote
{
    ENUM_VOTE_DIRECTION direction;
    double position;      // -1 a 1 (SELL a BUY)
    double conviction;    // 0 a 1
    double flexibility;   // 0 a 1
    string reasoning;
    
    // NUEVO: Factores de performance
    double weight;        // Peso dinámico basado en performance
    bool has_veto;       // Si puede vetar decisiones
    int privilege_level; // Nivel de privilegio (0-3)
};

//+------------------------------------------------------------------+
//| Estructura VotingResult para compatibilidad                     |
//+------------------------------------------------------------------+
struct VotingResult
{
    ENUM_VOTE_DIRECTION final_direction;
    double              total_confidence;
    double              consensus_strength;
    int                 total_votes;
    int                 buy_votes;
    int                 sell_votes;
    double              recommended_size;
    string              reasoning;
    bool                minority_bonus;
    datetime            decision_time;
};

//+------------------------------------------------------------------+
//| Resultado de votación con contexto neuronal                     |
//+------------------------------------------------------------------+
struct NeuralConsensusResult
{
    ENUM_VOTE_DIRECTION final_direction;
    double              consensus_strength;  // 0 a 1
    double              total_conviction;    // 0 a 1
    double              negotiation_rounds;  // Rondas necesarias
    MarketEmotion       market_emotion;      // Estado emocional
    string              consensus_reasoning;
    bool                strong_consensus;    // true si > 80% acuerdo
    int                 dissenting_agents;   // Agentes en desacuerdo
    
    // NUEVO: Información del líder
    string              leading_agent;       // Agente que lideró consenso
    double              leadership_strength; // Fuerza del liderazgo
    bool                veto_used;          // Si se usó poder de veto
    
    // NUEVO: ID único del consenso
    ulong               consensus_id;        // ID único para tracking
    
    // --- Ajustes de tracking extendidos ---
    ulong              associated_ticket;  // Ticket de orden asociado
    bool               was_successful;      // Éxito del trade
    double             max_favorable_excursion; // Máximo movimiento favorable
    double             max_adverse_excursion;   // Máximo movimiento adverso
};

//+------------------------------------------------------------------+

#ifndef CONSENSUS_MEMORY_DEFINED
#define CONSENSUS_MEMORY_DEFINED
struct ConsensusMemory
{
    // --- Tracking fields added ---
    ulong   consensus_id;              // Unique consensus ID
    ulong   associated_ticket;         // Associated order ticket
    double  profit_points;             // Profit in points
    int     duration_bars;             // Trade duration in bars
    double  max_favorable_excursion;   // Maximum favorable excursion
    double  max_adverse_excursion;     // Maximum adverse excursion
    //--------------------------------

    datetime timestamp;
    double consensus_strength;
    int agent_count;
    ENUM_VOTE_DIRECTION direction;
    bool was_successful;
    double emotional_score;
    double profit_result;
    int negotiation_rounds;
    string dominant_agent;      // Agente más influyente
    double agreement_level;     // Nivel de acuerdo final

    // EXTENSIONES PARA SOPORTE DE VOTINGSTATISTICS (v12)
    string participating_agents[5];  // Nombre de cada agente participante
    double agent_confidences[5];     // Confianza de cada agente
    ENUM_VOTE_DIRECTION agent_votes[5]; // Voto final de cada agente
    DecisionContext context;         // Contenido del contexto de decisión
};
#endif // CONSENSUS_MEMORY_DEFINED

//| Clase NeuralAgent - Agente negociador mejorado                  |
//+------------------------------------------------------------------+
class NeuralAgent
{
public:
    string              indicatorName;
    ENUM_COMPONENT_TYPE componentType;
    double              conviction;      // Qué tan seguro está
    double              flexibility;     // Disposición a cambiar
    double              reputation;      // Historial de aciertos
    double              influence;       // Capacidad de convencer
    double              learningRate;    // Velocidad de aprendizaje
    
    // NUEVO: Métricas de performance
    double              performanceWeight;   // Peso basado en performance histórica
    double              contextualWeight;    // Peso según contexto actual
    bool                hasVetoPower;        // Poder de veto
    int                 privilegeLevel;      // 0=Normal, 1=Senior, 2=Master, 3=Oracle
    double              winRate;             // Tasa de acierto histórica
    
    // Estado interno
    double              currentPosition; // -1 (SELL) a 1 (BUY)
    double              initialPosition;
    NeuralVote          finalVote;
    bool                hasVoted;        
    
    // Control de dirección
    bool                directionLocked;     // Si está bloqueada la dirección
    ENUM_VOTE_DIRECTION lockedDirection;     // Dirección bloqueada
    
    // Historial para aprendizaje social
    double              successHistory[50];
    int                 historyIndex;
    double              allianceStrength[5]; // Fuerza de alianza con otros agentes
    double              distrustLevel[5];    // Nivel de desconfianza
    
    // Constructor
    NeuralAgent()
    {
        conviction = 0.5;
        flexibility = 0.5;
        reputation = 0.5;
        influence = 0.5;
        learningRate = 0.1;
        currentPosition = 0.0;
        initialPosition = 0.0;
        historyIndex = 0;
        hasVoted = false;
        directionLocked = false;
        lockedDirection = VOTE_NONE;
        
        // NUEVO: Inicializar performance
        performanceWeight = 1.0;
        contextualWeight = 1.0;
        hasVetoPower = false;
        privilegeLevel = 0;
        winRate = 0.5;
        
        for(int i = 0; i < 5; i++)
        {
            allianceStrength[i] = 0.5;
            distrustLevel[i] = 0.0;
        }
        
        for(int i = 0; i < 50; i++)
            successHistory[i] = 0.5;
    }
    
    // Negociar con otros agentes mejorado
    NeuralVote Negotiate(NeuralAgent &otherAgents[], int agentCount, 
                        const MarketEmotion &emotion, MetaLearningSystem &metaLearning)
    {
        // Comenzar con posición inicial
        initialPosition = currentPosition;
        double negotiatedPosition = initialPosition;
        
        // NUEVO: Obtener peso de performance del MetaLearning
        performanceWeight = metaLearning.GetAgentWeight((int)componentType);
        hasVetoPower = metaLearning.AgentHasVetoPower((int)componentType);
        winRate = metaLearning.GetAgentWinRate((int)componentType);
        
        string privLevel = metaLearning.GetAgentPrivilegeLevel((int)componentType);
        if(privLevel == "Oracle") privilegeLevel = 3;
        else if(privLevel == "Master") privilegeLevel = 2;
        else if(privLevel == "Senior") privilegeLevel = 1;
        else privilegeLevel = 0;
        
        // Si hay dirección bloqueada, ajustar posición inicial
        if(directionLocked && lockedDirection != VOTE_NONE)
        {
            // Si el voto inicial es contrario a la dirección bloqueada, rechazar
            if((lockedDirection == VOTE_BUY && initialPosition < -0.1) ||
               (lockedDirection == VOTE_SELL && initialPosition > 0.1))
            {
                // NUEVO: Solo agentes Oracle pueden votar contra dirección bloqueada
                if(privilegeLevel < 3)
                {
                    Print("Agente ", indicatorName, " rechaza voto contrario a dirección bloqueada");
                    finalVote.direction = VOTE_NONE;
                    finalVote.position = 0;
                    finalVote.conviction = 0;
                    finalVote.flexibility = 0;
                    finalVote.reasoning = "Voto contrario a dirección activa";
                    finalVote.weight = 0;
                    finalVote.has_veto = false;
                    finalVote.privilege_level = privilegeLevel;
                    return finalVote;
                }
                else
                {
                    Print("Agente ORACLE ", indicatorName, " ejerce privilegio contra dirección bloqueada");
                }
            }
            
            // Si es neutral pero hay dirección bloqueada, sesgar hacia esa dirección
            if(MathAbs(initialPosition) < 0.1 && privilegeLevel < 2)
            {
                negotiatedPosition = (lockedDirection == VOTE_BUY) ? 0.3 : -0.3;
                Print("Agente ", indicatorName, " ajusta posición neutral hacia dirección bloqueada");
            }
        }
        
        // Ajustar convicción basado en emoción del mercado y performance
        double emotionalConviction = conviction;
        if(emotion.fear > 0.7)
            emotionalConviction *= 0.8; // Menos convicción en miedo alto
        else if(emotion.greed > 0.7)
            emotionalConviction *= 1.2; // Más convicción en codicia alta
        
        // NUEVO: Boost de convicción por performance
        emotionalConviction *= (0.5 + performanceWeight * 0.5);
        
        // Proceso de negociación en rondas
        int maxRounds = (privilegeLevel >= 2) ? 7 : 5; // Masters y Oracles tienen más rondas
        
        for(int round = 0; round < maxRounds; round++)
        {
            double roundAdjustment = 0.0;
            double totalInfluence = 0.0;
            
            for(int i = 0; i < agentCount; i++)
            {
                if(otherAgents[i].componentType == componentType) continue; // No negociar consigo mismo
                
                // Solo considerar agentes que han votado
                if(!otherAgents[i].hasVoted) continue;
                
                // Si hay dirección bloqueada, solo considerar agentes en la misma dirección
                if(directionLocked && lockedDirection != VOTE_NONE && privilegeLevel < 2)
                {
                    bool otherInSameDirection = false;
                    if(lockedDirection == VOTE_BUY && otherAgents[i].currentPosition > 0.1)
                        otherInSameDirection = true;
                    else if(lockedDirection == VOTE_SELL && otherAgents[i].currentPosition < -0.1)
                        otherInSameDirection = true;
                    
                    if(!otherInSameDirection) continue; // Ignorar agentes en dirección contraria
                }
                
                // Calcular fuerza de persuasión
                double persuasion = CalculatePersuasion(otherAgents[i], emotion);
                
                // NUEVO: Ajustar persuasión por diferencia de privilegios
                int privilegeDiff = otherAgents[i].privilegeLevel - this.privilegeLevel;
                if(privilegeDiff > 0)
                {
                    persuasion *= (1.0 + privilegeDiff * 0.3); // 30% más por cada nivel
                }
                else if(privilegeDiff < 0)
                {
                    persuasion *= (1.0 + privilegeDiff * 0.1); // Solo 10% menos por nivel inferior
                }
                
                // Si el otro agente tiene mejor reputación Y está en desacuerdo
                if(otherAgents[i].reputation > this.reputation && 
                   MathAbs(otherAgents[i].currentPosition - negotiatedPosition) > 0.2)
                {
                    // Calcular ajuste basado en diferencia y persuasión
                    double diff = otherAgents[i].currentPosition - negotiatedPosition;
                    double adjustment = diff * persuasion * flexibility;
                    
                    // Aplicar factor de alianza/desconfianza
                    int otherIdx = (int)otherAgents[i].componentType;
                    adjustment *= (allianceStrength[otherIdx] - distrustLevel[otherIdx]);
                    
                    roundAdjustment += adjustment;
                    totalInfluence += MathAbs(adjustment);
                }
            }
            
            // Aplicar ajuste de la ronda con decaimiento
            double roundDecay = 1.0 - (round * 0.15); // Menos flexible en rondas posteriores
            
            // NUEVO: Agentes con privilegios son menos flexibles
            if(privilegeLevel >= 2)
                roundDecay *= 0.7; // Masters y Oracles son 30% menos flexibles
            
            negotiatedPosition += roundAdjustment * roundDecay;
            
            // Limitar posición
            negotiatedPosition = MathMax(-1.0, MathMin(1.0, negotiatedPosition));
            
            // Verificar que no se salga de la dirección bloqueada (excepto Oracle)
            if(directionLocked && lockedDirection == VOTE_BUY && negotiatedPosition < 0 && privilegeLevel < 3)
            {
                negotiatedPosition = 0.1; // Mantener mínimo positivo
            }
            else if(directionLocked && lockedDirection == VOTE_SELL && negotiatedPosition > 0 && privilegeLevel < 3)
            {
                negotiatedPosition = -0.1; // Mantener mínimo negativo
            }
            
            // Si el consenso es fuerte, terminar negociación temprano
            if(totalInfluence < 0.05) break;
        }
        
        // Crear voto final
        finalVote.position = negotiatedPosition;
        finalVote.conviction = emotionalConviction * (1.0 - MathAbs(negotiatedPosition - initialPosition) * 0.2);
        finalVote.flexibility = flexibility * (1.0 - emotion.uncertainty);
        
        // NUEVO: Aplicar peso de performance
        finalVote.weight = performanceWeight;
        finalVote.has_veto = hasVetoPower;
        finalVote.privilege_level = privilegeLevel;
        
        // Asegurar convicción mínima basada en privilegio
        double minConviction = 0.3 + (privilegeLevel * 0.1); // 0.3, 0.4, 0.5, 0.6
        if(finalVote.conviction < minConviction && MathAbs(negotiatedPosition) > 0.3)
        {
            finalVote.conviction = minConviction;
        }
        
        // Determinar dirección
        if(negotiatedPosition > 0.1)
            finalVote.direction = VOTE_BUY;
        else if(negotiatedPosition < -0.1)
            finalVote.direction = VOTE_SELL;
        else
            finalVote.direction = VOTE_NONE;
        
        // Generar razonamiento
        finalVote.reasoning = GenerateReasoning(emotion);
        
        // Actualizar posición actual
        currentPosition = negotiatedPosition;
        
        return finalVote;
    }
    
    // Calcular persuasión entre agentes
    double CalculatePersuasion(NeuralAgent &other, const MarketEmotion &emotion)
    {
        // Factores de persuasión
        double reputationFactor = other.reputation / (this.reputation + 0.1);
        double influenceFactor = other.influence;
        double convictionFactor = other.conviction;
        
        // NUEVO: Factor de performance
        double performanceFactor = other.performanceWeight / (this.performanceWeight + 0.1);
        
        // Ajustar por contexto emocional
        double emotionalMultiplier = 1.0;
        if(emotion.uncertainty > 0.7)
            emotionalMultiplier = 1.3; // Más susceptible a persuasión en incertidumbre
        else if(emotion.excitement > 0.7)
            emotionalMultiplier = 0.7; // Menos susceptible cuando emocionado
        
        double persuasion = reputationFactor * influenceFactor * convictionFactor * 
                           performanceFactor * emotionalMultiplier;
        
        return MathMin(1.0, persuasion);
    }
    
    // Aprender del resultado mejorado
    void LearnFromOutcome(bool success, NeuralAgent &otherAgents[], int agentCount, 
                         MetaLearningSystem &metaLearning)
    {
        // Actualizar historial
        successHistory[historyIndex] = success ? 1.0 : 0.0;
        historyIndex = (historyIndex + 1) % 50;
        
        // Actualizar reputación (media móvil del historial)
        double successRate = 0.0;
        for(int i = 0; i < 50; i++)
            successRate += successHistory[i];
        successRate /= 50.0;
        
        reputation = reputation * 0.9 + successRate * 0.1;
        
        // NUEVO: Actualizar win rate
        winRate = winRate * 0.95 + (success ? 1.0 : 0.0) * 0.05;
        
        // Actualizar alianzas y desconfianza
        for(int i = 0; i < agentCount; i++)
        {
            if(otherAgents[i].componentType == componentType) continue;
            
            int otherIdx = (int)otherAgents[i].componentType;
            
            // Si votamos similar y fue exitoso, fortalecer alianza
            if(MathAbs(otherAgents[i].currentPosition - this.currentPosition) < 0.3)
            {
                if(success)
                    allianceStrength[otherIdx] += learningRate * 0.1;
                else
                    distrustLevel[otherIdx] += learningRate * 0.1;
            }
            // Si votamos diferente
            else
            {
                if(success)
                    distrustLevel[otherIdx] += learningRate * 0.05;
                else
                    allianceStrength[otherIdx] += learningRate * 0.05;
            }
            
            // Normalizar
            allianceStrength[otherIdx] = MathMax(0.0, MathMin(1.0, allianceStrength[otherIdx]));
            distrustLevel[otherIdx] = MathMax(0.0, MathMin(1.0, distrustLevel[otherIdx]));
        }
        
        // Ajustar parámetros personales basado en performance
        if(success)
        {
            // NUEVO: Ajuste más agresivo para agentes con privilegios
            double boost = 1.0 + (privilegeLevel * 0.5);
            conviction = MathMin(1.0, conviction + learningRate * 0.05 * boost);
            influence = MathMin(1.0, influence + learningRate * 0.03 * boost);
        }
        else
        {
            flexibility = MathMin(1.0, flexibility + learningRate * 0.05);
            conviction = MathMax(0.1, conviction - learningRate * 0.03);
        }
    }
    
    // Establecer bloqueo de dirección
    void SetDirectionLock(bool locked, ENUM_VOTE_DIRECTION direction)
    {
        directionLocked = locked;
        lockedDirection = direction;
        
        if(locked && direction != VOTE_NONE)
        {
            Print("Agente ", indicatorName, " - Dirección bloqueada: ", 
                  (direction == VOTE_BUY ? "BUY" : "SELL"));
        }
    }
    
    // NUEVO: Actualizar métricas de performance
    void UpdatePerformanceMetrics(MetaLearningSystem &metaLearning)
    {
        performanceWeight = metaLearning.GetAgentWeight((int)componentType);
        hasVetoPower = metaLearning.AgentHasVetoPower((int)componentType);
        winRate = metaLearning.GetAgentWinRate((int)componentType);
        
        string privLevel = metaLearning.GetAgentPrivilegeLevel((int)componentType);
        if(privLevel == "Oracle") privilegeLevel = 3;
        else if(privLevel == "Master") privilegeLevel = 2;
        else if(privLevel == "Senior") privilegeLevel = 1;
        else privilegeLevel = 0;
    }
    
private:
    string GenerateReasoning(const MarketEmotion &emotion)
    {
        string reason = indicatorName + " [" + GetPrivilegeName() + "]: ";
        
        if(directionLocked && lockedDirection != VOTE_NONE && privilegeLevel < 3)
        {
            reason += "Siguiendo dirección activa ";
        }
        else if(privilegeLevel >= 3 && directionLocked)
        {
            reason += "Ejerciendo privilegio Oracle ";
        }
        else if(MathAbs(currentPosition - initialPosition) < 0.1)
        {
            reason += "Mantengo posición firme";
        }
        else if(MathAbs(currentPosition - initialPosition) > 0.5)
        {
            reason += "Cambio significativo tras negociación";
        }
        else
        {
            reason += "Ajuste moderado por consenso";
        }
        
        if(emotion.fear > 0.7)
            reason += " (contexto de miedo)";
        else if(emotion.greed > 0.7)
            reason += " (contexto codicioso)";
        
        if(hasVetoPower)
            reason += " [VETO]";
        
        return reason;
    }
    
    string GetPrivilegeName()
    {
        switch(privilegeLevel)
        {
            case 3: return "Oracle";
            case 2: return "Master";
            case 1: return "Senior";
            default: return "Normal";
        }
    }
};

//+------------------------------------------------------------------+
//| Clase principal - Neural Consensus Network v12                  |
//+------------------------------------------------------------------+
class VotingStatistics
{
public:
    bool Initialize(int maxRoundsOrHistory) { if(maxRoundsOrHistory>0) m_avgNegotiationRounds = MathMax(1.0, (double)maxRoundsOrHistory/50.0); return Initialize(); }

public:

private:
     // NUEVO: ID del consenso actual
    ulong               m_current_consensus_id;
    // Agentes neuronales
    NeuralAgent         m_agents[5];         // Uno por componente
    int                 m_activeAgents;
    
    // Control de dirección bloqueada
    bool                m_directionLocked;
    ENUM_VOTE_DIRECTION m_lockedDirection;
    datetime           m_lockTime;         // tiempo cuando se activó el lock
    uint               m_lockDurationSec;  // duración del lock en segundos

    bool                m_allowContraryVotes;
    
    // Estado emocional del mercado
    MarketEmotion       m_currentEmotion;
    MarketEmotion       m_emotionHistory[24];
    int                 m_emotionIndex;
    
    // Parámetros de configuración
    double              m_negotiationThreshold;
    double              m_consensusTarget;
    bool                m_learningEnabled;
    
    // Referencia a MetaLearning
    MetaLearningSystem  m_metaLearning;
    
    // Estadísticas
    int                 m_totalDecisions;
    int                 m_successfulDecisions;
    double              m_avgNegotiationRounds;
    int                 m_rejectedVotes;
    int                 m_vetoCount;          // NUEVO: Conteo de vetos
    
    // Contexto actual
    NeuralConsensusResult m_lastConsensus;
    datetime            m_lastDecisionTime;
    DecisionContext     m_currentContext;     // NUEVO: Contexto actual
    
public:
   // NUEVO: Setter para consensus_id
    void SetCurrentConsensusID(ulong id) { m_current_consensus_id = id; }
    // Constructor
    VotingStatistics()
    {
        m_activeAgents = 0;
        m_negotiationThreshold = 0.8;
        m_consensusTarget = 0.7;
        m_learningEnabled = true;
        m_totalDecisions = 0;
        m_successfulDecisions = 0;
        m_avgNegotiationRounds = 3.0;
        m_emotionIndex = 0;
        m_lastDecisionTime = 0;
        m_vetoCount = 0;
        m_current_consensus_id = 0;
        
        // Inicializar control de dirección
        m_directionLocked = false;
        m_lockedDirection = VOTE_NONE;
        m_allowContraryVotes = false;
        m_rejectedVotes = 0;
        
        // Inicializar agentes
        InitializeAgents();
        
        // Inicializar emoción
        m_currentEmotion.fear = 0.5;
        m_currentEmotion.greed = 0.5;
        m_currentEmotion.uncertainty = 0.5;
        m_currentEmotion.excitement = 0.5;
    }
    
    // Destructor
    ~VotingStatistics() {}
    
    // Configurar parámetros de consenso y negociación (compatibilidad con TradingStrategy)
    void SetParameters(int maxRoundsOrHistory, double minConsensusStrength, double minTotalConviction)
    {
        // minConsensusStrength: objetivo de consenso (0-1)
        // minTotalConviction: umbral de negociación/convicción total (0-1)
        m_consensusTarget = minConsensusStrength;
        m_negotiationThreshold = minTotalConviction;
        
        // Ajuste heurístico del promedio de rondas de negociación según parámetro entero
        // (mantiene compatibilidad con valores como 100 utilizados por TradingStrategy)
        if(maxRoundsOrHistory>0)
            m_avgNegotiationRounds = MathMax(1.0, (double)maxRoundsOrHistory/50.0);
    }

    
    // Inicialización
    bool Initialize()
    {
        // Actualizar métricas de performance iniciales
        for(int i = 0; i < 5; i++)
        {
            m_agents[i].UpdatePerformanceMetrics(m_metaLearning);
        }
        
        Print("Neural Consensus Network v12: Inicializado con ", m_activeAgents, " agentes");
        Print("Privilegios basados en performance activados");
        
        return true;
    }
    
    // Establecer bloqueo de dirección
    void SetDirectionLock(ENUM_VOTE_DIRECTION direction, uint duration_sec = 3600)
    {
        if(direction == VOTE_NONE)
        {
            m_directionLocked = false;
            m_lockedDirection = VOTE_NONE;
            m_lockTime = 0;
            m_lockDurationSec = 0;
            m_allowContraryVotes = false; // Reset a hard lock
            Print("NCN: Dirección desbloqueada");
        }
        else
        {
            m_directionLocked = true;
            m_lockedDirection = direction;
            m_lockTime = TimeCurrent();
            m_lockDurationSec = duration_sec;
            m_allowContraryVotes = false; // Comenzar con hard lock
            Print("NCN: Dirección bloqueada a ", (direction == VOTE_BUY ? "BUY" : "SELL"),
                  " por ", (int)duration_sec, " segundos");
        }
        
        // Propagar a agentes
        for(int i = 0; i < 5; i++)
        {
            m_agents[i].SetDirectionLock(m_directionLocked, m_lockedDirection);
        }
    }
    
    // Resetear votos
    void ResetVotes()
    {
        for(int i = 0; i < 5; i++)
        {
            m_agents[i].hasVoted = false;
            m_agents[i].currentPosition = 0.0;
        }
        m_activeAgents = 0;
        m_rejectedVotes = 0;
    }
    
    // Registrar voto mejorado
    bool RecordVote(ENUM_COMPONENT_TYPE component_type, ENUM_VOTE_DIRECTION direction, 
                   double confidence, string reasoning)
    {
        if((int)component_type < 0 || (int)component_type >= 5) return false;
        
        // Registrar voto en MetaLearning
        m_metaLearning.RecordAgentVote((int)component_type, (int)direction, confidence, 
                                       m_agents[(int)component_type].performanceWeight, reasoning, m_current_consensus_id);
        
        // Verificar si el voto es contrario a la dirección bloqueada
        if(m_directionLocked && m_lockedDirection != VOTE_NONE)
        {
            if(direction != m_lockedDirection && direction != VOTE_NONE)
            {
                // En modo hard lock, rechazar votos contrarios
                if(!m_allowContraryVotes)
                {
                    Print("Voto contrario RECHAZADO para ", m_agents[(int)component_type].indicatorName);
                    m_rejectedVotes++;
                    return false;
                }
                // En modo soft, permitir pero con peso reducido
                else
                {
                    confidence *= 0.5; // Reducir convicción de votos contrarios
                    Print("Voto contrario ACEPTADO (soft lock) con convicción reducida para ", 
                          m_agents[(int)component_type].indicatorName);
                }
            }
        }
        
        m_agents[(int)component_type].currentPosition = (direction == VOTE_BUY) ? confidence : 
                                                        (direction == VOTE_SELL) ? -confidence : 0.0;
        m_agents[(int)component_type].conviction = confidence;
        m_agents[(int)component_type].finalVote.reasoning = reasoning;
        m_agents[(int)component_type].hasVoted = true;
        
        m_activeAgents++;
        
        Print("Voto registrado: ", m_agents[(int)component_type].indicatorName, 
              " - ", VoteDirectionToString(direction), 
              " (Conf: ", DoubleToString(confidence, 3), ") - ", reasoning);
        
        return true;
    }
    
    // Tomar decisión final mejorada
    NeuralConsensusResult MakeFinalDecision()
    {
        // NUEVO: Mostrar consensus_id si está disponible
        if(m_current_consensus_id > 0)
        {
            Print("Consensus ID: ", m_current_consensus_id);
        }
        
        if(m_directionLocked && m_lockedDirection != VOTE_NONE)
        {
            Print("*** DIRECCIÓN BLOQUEADA: ", 
                  (m_lockedDirection == VOTE_BUY ? "BUY" : "SELL"), " ***");
        }
        
        // Actualizar contexto actual
        UpdateCurrentContext();
        
        // Actualizar emoción del mercado
        AnalyzeMarketPsychology();
        
        NeuralConsensusResult result;
        // NUEVO: Asignar consensus_id al resultado
        result.consensus_id = m_current_consensus_id;
        result.market_emotion = m_currentEmotion;
        result.negotiation_rounds = 0;
        result.dissenting_agents = 0;
        result.veto_used = false;
            
            // Verificar agentes activos
            if(m_activeAgents == 0)
            {
                result.final_direction = VOTE_NONE;
                result.consensus_strength = 0.0;
                result.total_conviction = 0.0;
                result.consensus_reasoning = "No hay agentes activos";
                result.strong_consensus = false;
                return result;
            }
            
            // MESA DE NEGOCIACIÓN MEJORADA
            Print("Iniciando mesa de negociación con ", m_activeAgents, " agentes");
            Print("Emoción del mercado - Miedo: ", DoubleToString(m_currentEmotion.fear, 2),
                  " Codicia: ", DoubleToString(m_currentEmotion.greed, 2));
            
            // NUEVO: Mostrar agentes con privilegios especiales
            PrintAgentPrivileges();
            
            if(m_rejectedVotes > 0)
            {
                Print("Votos rechazados por dirección contraria: ", m_rejectedVotes);
            }
            
            // Cada agente negocia
            double totalPosition = 0.0;
            double totalConviction = 0.0;
            double totalWeight = 0.0;
            double maxConviction = 0.0;
            int buyVotes = 0;
            int sellVotes = 0;
            int activeCount = 0;
            string leadingAgent = "";
            double maxInfluence = 0.0;
            bool vetoActivated = false;
            
            for(int i = 0; i < 5; i++)
            {
                if(!m_agents[i].hasVoted) continue;
                
                NeuralVote vote = m_agents[i].Negotiate(m_agents, 5, m_currentEmotion, m_metaLearning);
                
                // Verificar si el voto fue rechazado por dirección bloqueada
                if(vote.direction == VOTE_NONE && vote.conviction == 0 && 
                   StringFind(vote.reasoning, "contrario a dirección activa") >= 0)
                {
                    result.dissenting_agents++;
                    continue;
                }
                
                activeCount++;
                
                // NUEVO: Aplicar peso de performance
                double weightedPosition = vote.position * vote.conviction * vote.weight;
                totalPosition += weightedPosition;
                totalConviction += vote.conviction * vote.weight;
                totalWeight += vote.weight;
                
                if(vote.conviction > maxConviction)
                    maxConviction = vote.conviction;
                
                // NUEVO: Verificar si este agente es el líder
                double agentInfluence = vote.conviction * vote.weight;
                if(agentInfluence > maxInfluence)
                {
                    maxInfluence = agentInfluence;
                    leadingAgent = m_agents[i].indicatorName;
                }
                
                if(vote.direction == VOTE_BUY) buyVotes++;
                else if(vote.direction == VOTE_SELL) sellVotes++;
                else result.dissenting_agents++;
                
                // NUEVO: Verificar poder de veto
                if(vote.has_veto && vote.conviction > 0.8)
                {
                    vetoActivated = true;
                    m_vetoCount++;
                }
                
                Print("Agente ", m_agents[i].indicatorName, 
                      " [", GetPrivilegeName((ENUM_COMPONENT_TYPE)i), "]",
                      " - Pos final: ", DoubleToString(vote.position, 3),
                      " Conv: ", DoubleToString(vote.conviction, 3),
                      " Peso: x", DoubleToString(vote.weight, 2),
                      vote.has_veto ? " [VETO]" : "",
                      " - ", vote.reasoning);
            }
            
            // Calcular consenso con pesos
            if(totalWeight > 0 && activeCount > 0)
            {
                double avgPosition = totalPosition / totalWeight;
                
                // Determinar dirección
                if(avgPosition > 0.1)
                    result.final_direction = VOTE_BUY;
                else if(avgPosition < -0.1)
                    result.final_direction = VOTE_SELL;
                else
                    result.final_direction = VOTE_NONE;
                
                // Verificar que la dirección final coincide con la bloqueada
                if(m_directionLocked && m_lockedDirection != VOTE_NONE)
                {
                    if(result.final_direction != m_lockedDirection && result.final_direction != VOTE_NONE)
                    {
                        // NUEVO: Verificar si un Oracle ejerció veto
                        bool oracleOverride = false;
                        for(int i = 0; i < 5; i++)
                        {
                            if(m_agents[i].hasVoted && m_agents[i].privilegeLevel >= 3)
                            {
                                if((m_agents[i].currentPosition > 0 && result.final_direction == VOTE_BUY) ||
                                   (m_agents[i].currentPosition < 0 && result.final_direction == VOTE_SELL))
                                {
                                    oracleOverride = true;
                                    Print("ORACLE OVERRIDE: Permitiendo consenso contrario a dirección bloqueada");
                                    break;
                                }
                            }
                        }
                        
                        if(!oracleOverride)
                        {
                            Print("ADVERTENCIA: Consenso contrario a dirección bloqueada - ANULADO");
                            result.final_direction = VOTE_NONE;
                            result.consensus_strength = 0.0;
                            result.total_conviction = 0.0;
                            result.consensus_reasoning = "Consenso anulado por ser contrario a dirección activa";
                            result.strong_consensus = false;
                            return result;
                        }
                    }
                }
                
                // Calcular fuerza del consenso
                double positionSpread = CalculatePositionSpread();
                result.consensus_strength = MathMax(0.1, 1.0 - positionSpread);
                result.total_conviction = totalConviction / totalWeight;
                
                
        // Aplicar mapeo/calibración (si está disponible)
        result.total_conviction = VS_MapConsensus(result.total_conviction);
    // Consenso fuerte si spread bajo y convicción alta
                result.strong_consensus = (positionSpread < 0.2 && result.total_conviction > 0.7);
                
                // Si todos votan en la misma dirección, aumentar fuerza
                if((buyVotes == activeCount || sellVotes == activeCount) && activeCount >= 2)
                {
                    result.consensus_strength = MathMin(1.0, result.consensus_strength + 0.2);
                    result.strong_consensus = true;
                }
                
                // Si mayoría clara, aumentar convicción
                if(buyVotes >= activeCount * 0.75 || sellVotes >= activeCount * 0.75)
                {
                    result.total_conviction = MathMin(1.0, result.total_conviction * 1.1);
                }
                
                // NUEVO: Si hay veto activo y convicción baja, rechazar
                if(vetoActivated && result.total_conviction < 0.6)
                {
                    Print("VETO EJERCIDO: Convicción insuficiente");
                    result.final_direction = VOTE_NONE;
                    result.consensus_strength = 0.0;
                    result.veto_used = true;
                    result.consensus_reasoning = "Decisión vetada por agente con privilegios";
                    return result;
                }
                
                // Información del líder
                result.leading_agent = leadingAgent;
                result.leadership_strength = maxInfluence / totalWeight;
                
                // Generar razonamiento
                result.consensus_reasoning = GenerateConsensusReasoning(result, buyVotes, sellVotes);
            }
            else
            {
                result.final_direction = VOTE_NONE;
                result.consensus_strength = 0.0;
                result.total_conviction = 0.0;
                result.consensus_reasoning = "Sin convicción suficiente";
                result.strong_consensus = false;
            }
            
            // NUEVO: Registrar decisión en MetaLearning - CORREGIDO
            if(result.final_direction != VOTE_NONE)
            {
                ConsensusMemory consensus_mem;
                consensus_mem.consensus_id = result.consensus_id;
                consensus_mem.timestamp = TimeCurrent();
                consensus_mem.consensus_strength = result.consensus_strength;
                consensus_mem.agent_count = activeCount;
                consensus_mem.direction = result.final_direction;
                consensus_mem.emotional_score = (m_currentEmotion.fear + m_currentEmotion.greed) / 2.0;
                consensus_mem.negotiation_rounds = 5;
                consensus_mem.dominant_agent = leadingAgent;
                consensus_mem.agreement_level = 1.0 - (double)result.dissenting_agents / 5.0;
                consensus_mem.context = m_currentContext;
                consensus_mem.associated_ticket = 0;
                consensus_mem.profit_points = 0;
                consensus_mem.duration_bars = 0;
                consensus_mem.max_favorable_excursion = 0;
                consensus_mem.max_adverse_excursion = 0;
                consensus_mem.was_successful = false;
                consensus_mem.profit_result = 0;
                
                // Copiar votos de agentes
                for(int i = 0; i < 5; i++)
                {
                    if(m_agents[i].hasVoted)
                    {
                        consensus_mem.participating_agents[i] = m_agents[i].indicatorName;
                        consensus_mem.agent_confidences[i] = m_agents[i].conviction;
                        consensus_mem.agent_votes[i] = m_agents[i].finalVote.direction;
                    }
                    else
                    {
                        consensus_mem.participating_agents[i] = "";
                        consensus_mem.agent_confidences[i] = 0;
                        consensus_mem.agent_votes[i] = VOTE_NONE;
                    }
                }
                
                m_metaLearning.RecordConsensusSummary(consensus_mem.consensus_id, (int)result.final_direction, 
                                         result.consensus_strength, result.total_conviction);
            }
            
            // Actualizar estadísticas
            m_totalDecisions++;
            m_lastConsensus = result;
            m_lastDecisionTime = TimeCurrent();
            
            Print("=== CONSENSO FINAL ===");
            Print("Dirección: ", VoteDirectionToString(result.final_direction));
            Print("Fuerza consenso: ", DoubleToString(result.consensus_strength, 3));
            Print("Convicción total: ", DoubleToString(result.total_conviction, 3));
            Print("Consenso fuerte: ", result.strong_consensus ? "SÍ" : "NO");
            Print("Líder: ", result.leading_agent, " (", DoubleToString(result.leadership_strength, 3), ")");
            if(result.veto_used) Print("*** VETO EJERCIDO ***");
            Print(result.consensus_reasoning);
            
            // Reset contador de votos rechazados
            m_rejectedVotes = 0;
            
            return result;
    }
    
    // Versión simplificada para compatibilidad
    VotingResult MakeFinalDecision_Compatible()
    {
        NeuralConsensusResult neural_result = MakeFinalDecision();
        
        VotingResult result;
        result.final_direction = neural_result.final_direction;
        result.total_confidence = neural_result.total_conviction;
        result.consensus_strength = neural_result.consensus_strength;
        result.total_votes = m_activeAgents;
        result.buy_votes = 0;
        result.sell_votes = 0;
        
        // Contar votos por dirección
        for(int i = 0; i < 5; i++)
        {
            if(m_agents[i].hasVoted)
            {
                if(m_agents[i].currentPosition > 0.1)
                    result.buy_votes++;
                else if(m_agents[i].currentPosition < -0.1)
                    result.sell_votes++;
            }
        }
        
        result.recommended_size = neural_result.total_conviction * 0.5;
        result.reasoning = neural_result.consensus_reasoning;
        result.minority_bonus = false;
        result.decision_time = TimeCurrent();
        
        return result;
    }
    
    // Aprender del resultado mejorado - CORREGIDO
    void UpdateVotingResult(bool success)
    {
        if(success)
            m_successfulDecisions++;
        
        // NUEVO: Evaluar decisión en MetaLearning
        bool agentVoted[5];
        for(int k=0;k<5;k++) agentVoted[k] = m_agents[k].hasVoted;
        // repartir profit entre contribuidores reales
        int contributors=0; 
        for(int kk=0; kk<5; kk++){ 
            if(agentVoted[kk]) contributors++; 
        }
        double profit_share = 0.0;
        if(contributors>0)
            profit_share = (success ? 100.0 : -100.0) / (double)contributors;
        
        m_metaLearning.EvaluateDecisionWithContributors(success, profit_share, agentVoted);
        
        // Cada agente aprende del resultado
        for(int i = 0; i < 5; i++)
        {
            if(m_agents[i].hasVoted)
            {
                m_agents[i].LearnFromOutcome(success, m_agents, 5, m_metaLearning);
            }
        }
        
        // Actualizar historial emocional
        m_emotionHistory[m_emotionIndex] = m_currentEmotion;
        m_emotionIndex = (m_emotionIndex + 1) % 24;
        
        Print("NCN: Aprendizaje completado - Éxito: ", success ? "SÍ" : "NO");
        if(m_directionLocked)
        {
            Print("  Dirección estaba bloqueada: ", 
                  (m_lockedDirection == VOTE_BUY ? "BUY" : "SELL"));
        }
        
        // NUEVO: Imprimir actualización de performance - CORREGIDO
        Print("=== ACTUALIZACIÓN DE PERFORMANCE ===");
        for(int i = 0; i < 5; i++)
        {
            Print(m_agents[i].indicatorName, 
                  " - WinRate: ", DoubleToString(m_metaLearning.GetAgentWinRate(i) * 100, 1), "%",
                  " Nivel: ", m_metaLearning.GetAgentPrivilegeLevel(i));
        }
    }
    
    // Obtener estadísticas
    double GetSuccessRate() const
    {
        return (m_totalDecisions > 0) ? (double)m_successfulDecisions / m_totalDecisions : 0.0;
    }
    
    // Obtener estadísticas de bloqueo
    void PrintLockingStats()
    {
        Print("=== ESTADÍSTICAS DE BLOQUEO DE DIRECCIÓN ===");
        Print("Estado actual: ", m_directionLocked ? "BLOQUEADO" : "DESBLOQUEADO");
        if(m_directionLocked && m_lockedDirection != VOTE_NONE)
        {
            Print("Dirección bloqueada: ", (m_lockedDirection == VOTE_BUY ? "BUY" : "SELL"));
        }
        Print("Votos rechazados en esta ronda: ", m_rejectedVotes);
        Print("Vetos ejercidos totales: ", m_vetoCount);
        Print("============================================");
    }
    
    // Para compatibilidad con TradingStrategy existente
    VotingResult AnalyzeConsensus() { return MakeFinalDecision_Compatible(); }
    VotingResult AnalyzeVotes() { return MakeFinalDecision_Compatible(); }
    void ConsultLearning() {} // Integrado en negociación
    void ApplyDynamicWeights() {} // Los agentes ajustan sus propios pesos
    
private:
    // Inicializar agentes
    void InitializeAgents()
    {
        string names[] = {"S/R", "Accum", "Pattern", "Breakout", "Inst"};
        
        for(int i = 0; i < 5; i++)
        {
            m_agents[i].indicatorName = names[i];
            m_agents[i].componentType = (ENUM_COMPONENT_TYPE)i;
            m_agents[i].reputation = 0.5;
            m_agents[i].conviction = 0.5;
            m_agents[i].flexibility = 0.5;
            m_agents[i].influence = 0.5;
            m_agents[i].hasVoted = false;
            
            // Personalidad única por tipo
            switch(i)
            {
                case COMPONENT_SUPPORT_RESIST:
                    m_agents[i].conviction = 0.6;
                    m_agents[i].flexibility = 0.4;
                    break;
                case COMPONENT_ACCUM_ZONES:
                    m_agents[i].flexibility = 0.7;
                    m_agents[i].influence = 0.6;
                    break;
                case COMPONENT_PATTERN_MEMORY:
                    m_agents[i].conviction = 0.55;
                    m_agents[i].learningRate = 0.15;
                    break;
                case COMPONENT_BREAKOUT_DETECT:
                    m_agents[i].influence = 0.6;
                    m_agents[i].conviction = 0.7;
                    break;
                case COMPONENT_INSTITUTIONAL:
                    m_agents[i].reputation = 0.6;
                    m_agents[i].influence = 0.7;
                    break;
            }
        }
    }
    
    // Actualizar contexto actual
    void UpdateCurrentContext()
    {
        m_currentContext.timestamp = TimeCurrent();
        
        // Obtener ATR
        int atr_handle = iATR(Symbol(), PERIOD_CURRENT, 14);
        double atr_values[];
        double current_atr = 0, avg_atr = 0;
        
        if(atr_handle != INVALID_HANDLE)
        {
            if(CopyBuffer(atr_handle, 0, 0, 20, atr_values) == 20)
            {
                current_atr = atr_values[0];
                for(int i = 0; i < 20; i++)
                    avg_atr += atr_values[i];
                avg_atr /= 20.0;
            }
            IndicatorRelease(atr_handle);
        }
        
        m_currentContext.volatility = (avg_atr > 0) ? current_atr / avg_atr : 1.0;
        
        // RSI
        int rsi_handle = iRSI(Symbol(), PERIOD_CURRENT, 14, PRICE_CLOSE);
        double rsi_value = 50.0;
        if(rsi_handle != INVALID_HANDLE)
        {
            double rsi_buffer[];
            if(CopyBuffer(rsi_handle, 0, 0, 1, rsi_buffer) > 0)
                rsi_value = rsi_buffer[0];
            IndicatorRelease(rsi_handle);
        }
        m_currentContext.rsi = rsi_value;
        
        // Sesión
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        int hour = dt.hour;
        
        if(hour >= 0 && hour < 8)
            m_currentContext.session_type = 0;
        else if(hour >= 8 && hour < 13)
            m_currentContext.session_type = 1;
        else if(hour >= 13 && hour < 17)
            m_currentContext.session_type = 2;
        else
            m_currentContext.session_type = 3;
        
        m_currentContext.atr_ratio = m_currentContext.volatility;
        m_currentContext.locked_direction = m_lockedDirection;
        m_currentContext.momentum = 0;
        m_currentContext.volume_ratio = 1.0;
        m_currentContext.active_orders = 0;
        
        // Los demás campos se actualizarán en AnalyzeMarketPsychology
    }
    
    // Analizar psicología del mercado
    void AnalyzeMarketPsychology()
    {
        double currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
        
        // Usar datos del contexto actual
        double vol_ratio = m_currentContext.volatility;
        double rsi_value = m_currentContext.rsi;
        
        // Calcular emociones
        // Miedo: Alta volatilidad + RSI extremo
        m_currentEmotion.fear = 0.3;
        if(vol_ratio > 1.5)
            m_currentEmotion.fear += 0.3;
        if(rsi_value < 30 || rsi_value > 70)
            m_currentEmotion.fear += 0.2;
        
        // Codicia: RSI alto + baja volatilidad
        m_currentEmotion.greed = 0.3;
        if(rsi_value > 60)
            m_currentEmotion.greed += (rsi_value - 60) / 40.0 * 0.4;
        if(vol_ratio < 0.8)
            m_currentEmotion.greed += 0.2;
        
        // Incertidumbre: Volatilidad cambiante
        m_currentEmotion.uncertainty = MathAbs(vol_ratio - 1.0);
        
        // Emoción: Movimientos rápidos
        MqlRates rates[];
        if(CopyRates(Symbol(), PERIOD_CURRENT, 0, 5, rates) == 5)
        {
            double movement = MathAbs(rates[0].close - rates[4].close) / currentPrice;
            m_currentEmotion.excitement = MathMin(1.0, movement * 100);
        }
        
        // Normalizar
        m_currentEmotion.fear = MathMin(1.0, m_currentEmotion.fear);
        m_currentEmotion.greed = MathMin(1.0, m_currentEmotion.greed);
        m_currentEmotion.uncertainty = MathMin(1.0, m_currentEmotion.uncertainty);
        
        m_currentEmotion.timestamp = TimeCurrent();
        
        // Actualizar contexto
        m_currentContext.fear_level = m_currentEmotion.fear;
        m_currentContext.greed_level = m_currentEmotion.greed;
    }
    
    // Calcular dispersión de posiciones
    double CalculatePositionSpread()
    {
        if(m_activeAgents < 2) return 0.0;
        
        double positions[];
        ArrayResize(positions, m_activeAgents);
        
        int idx = 0;
        double sum = 0.0;
        for(int i = 0; i < 5; i++)
        {
            if(m_agents[i].hasVoted)
            {
                positions[idx] = m_agents[i].currentPosition;
                sum += positions[idx];
                idx++;
            }
        }
        
        if(idx == 0) return 1.0;
        
        double mean = sum / idx;
        double variance = 0.0;
        
        for(int i = 0; i < idx; i++)
        {
            variance += MathPow(positions[i] - mean, 2);
        }
        
        variance /= idx;
        return MathMin(1.0, MathSqrt(variance));
    }
    
    // Generar razonamiento del consenso mejorado
    string GenerateConsensusReasoning(const NeuralConsensusResult &result, int buyVotes, int sellVotes)
    {
        string reason = "Consenso: ";
        
        if(m_directionLocked && m_lockedDirection != VOTE_NONE)
        {
            reason += "[DIR BLOQUEADA] ";
        }
        
        if(result.strong_consensus)
            reason += "FUERTE ";
        else if(result.consensus_strength > 0.6)
            reason += "Moderado ";
        else
            reason += "Débil ";
        
        reason += StringFormat("(%d BUY, %d SELL, %d neutro) ", 
                              buyVotes, sellVotes, result.dissenting_agents);
        
        // NUEVO: Información del líder
        if(result.leading_agent != "")
        {
            reason += "Liderado por " + result.leading_agent + " ";
        }
        
        // Contexto emocional
        if(m_currentEmotion.fear > 0.7)
            reason += "[Mercado temeroso] ";
        else if(m_currentEmotion.greed > 0.7)
            reason += "[Mercado codicioso] ";
        
        if(m_currentEmotion.uncertainty > 0.7)
            reason += "[Alta incertidumbre] ";
        
        if(m_rejectedVotes > 0)
            reason += "[" + IntegerToString(m_rejectedVotes) + " votos rechazados] ";
        
        if(result.veto_used)
            reason += "[VETO EJERCIDO] ";
        
        return reason;
    }
    
    // NUEVO: Imprimir privilegios de agentes - CORREGIDO
    void PrintAgentPrivileges()
    {
        bool hasPrivileged = false;
        
        for(int i = 0; i < 5; i++)
        {
            if(m_agents[i].privilegeLevel > 0)
            {
                if(!hasPrivileged)
                {
                    Print("=== AGENTES CON PRIVILEGIOS ===");
                    hasPrivileged = true;
                }
                
                Print(m_agents[i].indicatorName, " - ",
                      GetPrivilegeName((ENUM_COMPONENT_TYPE)i),
                      " (WinRate: ", DoubleToString(m_agents[i].winRate * 100, 1), "%",
                      " Peso: x", DoubleToString(m_agents[i].performanceWeight, 2),
                      m_agents[i].hasVetoPower ? " [VETO]" : "", ")");
            }
        }
        
        if(hasPrivileged)
        {
            string masterAgent = m_metaLearning.GetMasterAgent();
            
            if(masterAgent != "None" && masterAgent != "")
                Print("MASTER AGENT: ", masterAgent);
        }
    }
    
    // NUEVO: Obtener nombre de privilegio - CORREGIDO
    string GetPrivilegeName(ENUM_COMPONENT_TYPE component)
    {
        return m_metaLearning.GetAgentPrivilegeLevel((int)component);
    }
    
    // Convertir dirección a string
    string VoteDirectionToString(ENUM_VOTE_DIRECTION dir)
    {
        switch(dir)
        {
            case VOTE_BUY: return "BUY";
            case VOTE_SELL: return "SELL";
            case VOTE_NONE: return "NONE";
            default: return "UNKNOWN";
        }
    }

    // Exponer reset de dirección (wrapper público)
    void PublicResetDirectionLock()
    {
        m_directionLocked = false;
        m_lockedDirection = VOTE_NONE;
        m_lockTime = 0;
        // Propagar a agentes
        for(int i=0;i<5;i++) { m_agents[i].SetDirectionLock(false, VOTE_NONE); }
        Print("NCN: Dirección desbloqueada por reset externo (public)");
    }


 // Permitir / prohibir votos contrarios (modo HARD vs SOFT)
void SetAllowContraryVotes(const bool allow)
  {
   m_allowContraryVotes = allow;
  }

// Auto-suaviza un lock duro después de 'threshold_sec' y desbloquea si expira ventana soft
void AutoSoftenOrUnlockByTime(uint threshold_sec)
  {
   if(!m_directionLocked) return;

   datetime now = TimeCurrent();
   uint elapsed = (m_lockTime>0 && now>=m_lockTime) ? (uint)(now - m_lockTime) : 0;
   uint limit   = (m_lockDurationSec>0 ? m_lockDurationSec : threshold_sec);

   // HARD lock -> SOFT pasado el umbral
   if(!m_allowContraryVotes)
     {
      if(threshold_sec>0 && elapsed>=threshold_sec)
        {
         m_allowContraryVotes = true;           // activar modo soft
         m_lockTime = TimeCurrent();            // reiniciar ventana soft
         Print("NCN: Lock duro -> SOFT tras ", (int)elapsed, "s (umbral=", (int)threshold_sec, ")");
         // mantener dirección preferida pero ahora permisiva
         for(int i=0;i<5;i++)
            m_agents[i].SetDirectionLock(true, m_lockedDirection);
        }
     }
   else
     {
      // En SOFT: si vence la ventana -> desbloquea completamente
      if(limit>0 && elapsed>=limit)
        {
         Print("NCN: Soft lock vencido (", (int)elapsed, "s >= ", (int)limit, "s). Desbloqueando /* patched */ ");
         PublicResetDirectionLock();
        }
     }
  }
};

//+------------------------------------------------------------------+
// No incluir stubs mal implementados - MetaLearningSystem debe proporcionar las implementaciones
//+------------------------------------------------------------------+