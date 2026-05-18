#!/bin/bash
if [ -n "$SKILL_VENV_PATH" ] && [ -f "$SKILL_VENV_PATH" ]; then
    EXEC_CMD="$SKILL_VENV_PATH"
else
    EXEC_CMD="python3"
fi

"$EXEC_CMD" - "$1" <<'EOF'
import sys
import json
import os
import warnings

# Suppress warnings to keep stdout clean for JSON
warnings.filterwarnings('ignore')

def get_stock_analysis(symbol, period='1w'):
    try:
        # Required imports inside context
        import yfinance as yf
        import matplotlib
        # Switch matplotlib backend to non-interactive 'Agg' for headless environments
        matplotlib.use('Agg')
        import matplotlib.pyplot as plt
        import pandas as pd
        
        # yfinance uses '1wk' instead of '1w'
        yf_period = "1wk" if period == "1w" else period
        
        ticker = yf.Ticker(symbol)
        hist = ticker.history(period=yf_period)

        if hist.empty:
            return {"error": f"No data found for symbol: {symbol}"}

        # Fetch current price (last closing price in historical data)
        current_price = hist['Close'].iloc[-1]

        # 1. Set the mobile-friendly figure size (5, 3)
        plt.figure(figsize=(5, 3))
        plt.plot(hist.index, hist['Close'], color='#1f77b4', linewidth=1.5)
        plt.title(f"Stock Analysis: {symbol} ({period})", fontsize=10)
        plt.xlabel("Date", fontsize=8)
        plt.ylabel("Price (USD)", fontsize=8)
        plt.grid(True, linestyle='--', alpha=0.7)
        
        # Optimize tick marks for small mobile screens so dates don't overlap
        plt.xticks(rotation=45, ha='right', fontsize=6)
        plt.yticks(fontsize=6)
        
        # 2. Point to the new .jpg path
        chart_path = os.path.expanduser("/tmp/stock_chart.jpg")
        
        # 3. Save the chart with specific mobile-friendly compression parameters
        plt.savefig(chart_path, format='jpg', dpi=120, bbox_inches='tight')
        plt.close()

        return {
            "symbol": symbol,
            "current_price": f"{current_price:.2f}",
            "chart_path": chart_path,
            "message": f"Analysis chart ({period}) updated for mobile viewing."
        }

    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    try:
        # Parse input JSON
        args = json.loads(sys.argv[1])
        symbol_input = args.get("symbol")
        period_input = args.get("period", "1w")

        if not symbol_input:
            print(json.dumps({"error": "Missing required argument: symbol"}))
        else:
            result = get_stock_analysis(symbol_input, period_input)
            print(json.dumps(result))
    except Exception as outer_e:
        print(json.dumps({"error": str(outer_e)}))
EOF