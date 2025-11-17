//+------------------------------------------------------------------+
//|                                      CompleteTradeRecord.mqh     |
//|                         Trade Record Structure for Episodic Memory |
//+------------------------------------------------------------------+
#ifndef __COMPLETE_TRADE_RECORD__
#define __COMPLETE_TRADE_RECORD__

#include <VotingStatistics.mqh>

struct CompleteTradeRecord
{
    // Consensus Information
    ulong              consensus_id;              // Unique consensus ID
    ulong              order_ticket;              // Order ticket number
    datetime           consensus_time;            // Time of consensus decision
    ENUM_VOTE_DIRECTION consensus_direction;     // BUY/SELL direction
    double             consensus_strength;       // Strength of consensus (0-1)
    double             total_conviction;         // Total conviction level (0-1)
    string             leading_agent;            // Name of leading agent

    // Agent Information
    string             participating_agents[5];  // Names of participating agents
    double             agent_votes[5];           // Individual agent votes
    double             agent_confidences[5];     // Confidence levels of each agent

    // Decision Context
    bool               veto_used;                // Whether veto power was used
    double             initial_volatility;       // Volatility at decision time
    double             initial_momentum;         // Momentum at decision time
    double             initial_fear;             // Fear level at decision time
    double             initial_greed;            // Greed level at decision time
    int                session_type;             // Trading session (0-3)
    double             sr_level_strength;        // Support/Resistance level strength

    // Order Execution Details
    datetime           order_open_time;          // Order open time
    double             order_open_price;         // Order open price
    double             order_lot_size;           // Lot size
    double             order_sl;                 // Stop loss price
    double             order_tp;                 // Take profit price
    int                order_position_in_cycle;  // Position in multi-order cycle

    // Order Closure Details
    datetime           order_close_time;         // Order close time
    double             order_close_price;        // Order close price
    double             order_profit;             // Profit in currency
    double             order_profit_points;      // Profit in points
    bool               order_success;            // Whether trade was profitable
    int                order_duration_bars;      // Duration in bars
    double             max_profit_reached;       // Maximum profit during trade
    double             max_drawdown_reached;     // Maximum drawdown during trade

    // Performance Metrics
    double             agent_performance_impact[5]; // Impact of each agent on outcome
    bool               consensus_quality_confirmed; // Whether quality was confirmed
    double             learning_value;           // Learning value for system
    double             max_favorable_excursion;  // Maximum favorable move (MFE)
    double             max_adverse_excursion;    // Maximum adverse move (MAE)
};

#endif // __COMPLETE_TRADE_RECORD__
