//+------------------------------------------------------------------+
//|                                        CompleteTradeRecord.mqh    |
//|                         Complete Trade Record Structure          |
//+------------------------------------------------------------------+
#property copyright "Complete Trade Record Structure"
#property version   "1.00"

#ifndef __COMPLETE_TRADE_RECORD__
#define __COMPLETE_TRADE_RECORD__

// Forward declaration to avoid circular dependency
enum ENUM_VOTE_DIRECTION
{
    VOTE_NONE = 0,
    VOTE_NEUTRAL = 0,
    VOTE_BUY = 1,
    VOTE_SELL = -1
};

//+------------------------------------------------------------------+
//| Complete Trade Record Structure                                  |
//| Stores all information about a trade from consensus to close     |
//+------------------------------------------------------------------+
struct CompleteTradeRecord
{
    // Consensus Information
    ulong                   consensus_id;           // Unique ID of the consensus
    datetime                consensus_time;         // When consensus was reached
    ENUM_VOTE_DIRECTION     consensus_direction;    // Direction agreed upon
    double                  consensus_strength;     // Strength of consensus
    double                  total_conviction;       // Total conviction level
    string                  leading_agent;          // Agent that led the decision

    // Participating Agents
    string                  participating_agents[5]; // Names of agents
    double                  agent_votes[5];         // Individual votes
    double                  agent_confidences[5];   // Individual confidences

    // Decision Context
    bool                    veto_used;              // Was veto exercised
    double                  initial_volatility;     // Market volatility at entry
    double                  initial_momentum;       // Market momentum
    double                  initial_fear;           // Fear level
    double                  initial_greed;          // Greed level
    int                     session_type;           // Trading session
    double                  sr_level_strength;      // S/R level strength

    // Order Entry Information
    datetime                order_open_time;        // When order was opened
    double                  order_open_price;       // Opening price
    double                  order_lot_size;         // Position size
    double                  order_sl;               // Stop Loss
    double                  order_tp;               // Take Profit
    int                     order_position_in_cycle;// Position number in cycle
    ulong                   order_ticket;           // Order ticket number

    // Order Exit Information
    datetime                order_close_time;       // When order closed
    double                  order_close_price;      // Closing price
    double                  order_profit;           // Profit in account currency
    double                  order_profit_points;    // Profit in points
    bool                    order_success;          // Was trade successful
    int                     order_duration_bars;    // Duration in bars
    double                  max_profit_reached;     // Peak profit during trade
    double                  max_drawdown_reached;   // Worst drawdown during trade

    // Performance Impact
    double                  agent_performance_impact[5]; // Impact on each agent's performance

    // Learning Metrics
    bool                    consensus_quality_confirmed; // Did result confirm quality
    double                  learning_value;         // Value for learning (0-1)
    double                  max_favorable_excursion; // MFE metric
    double                  max_adverse_excursion;  // MAE metric

    // Constructor
    void Initialize()
    {
        consensus_id = 0;
        consensus_time = 0;
        consensus_direction = VOTE_NEUTRAL;
        consensus_strength = 0.0;
        total_conviction = 0.0;
        leading_agent = "";

        for(int i = 0; i < 5; i++)
        {
            participating_agents[i] = "";
            agent_votes[i] = 0.0;
            agent_confidences[i] = 0.0;
            agent_performance_impact[i] = 0.0;
        }

        veto_used = false;
        initial_volatility = 0.0;
        initial_momentum = 0.0;
        initial_fear = 0.0;
        initial_greed = 0.0;
        session_type = 0;
        sr_level_strength = 0.0;

        order_open_time = 0;
        order_open_price = 0.0;
        order_lot_size = 0.0;
        order_sl = 0.0;
        order_tp = 0.0;
        order_position_in_cycle = 0;
        order_ticket = 0;

        order_close_time = 0;
        order_close_price = 0.0;
        order_profit = 0.0;
        order_profit_points = 0.0;
        order_success = false;
        order_duration_bars = 0;
        max_profit_reached = 0.0;
        max_drawdown_reached = 0.0;

        consensus_quality_confirmed = false;
        learning_value = 0.0;
        max_favorable_excursion = 0.0;
        max_adverse_excursion = 0.0;
    }
};

#endif // __COMPLETE_TRADE_RECORD__
