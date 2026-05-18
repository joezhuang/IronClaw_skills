# get_stock_analysis Skill

This skill generates a mobile-optimized JPEG stock analysis chart for any given ticker symbol.

### Optimization Features:
- **Mobile-Friendly Dimensions**: Set to 5x3 inches for ideal viewing on mobile devices.
- **Optimized Resolution**: Saved at 60 DPI to reduce file size without sacrificing clarity.
- **JPEG Format**: Standard format for broad compatibility.
- **Headless Execution**: Uses Matplotlib's 'Agg' backend to run reliably in macOS background environments.

### Usage:
- Provide a ticker symbol (e.g., `AAPL`).
- The tool saves the chart to `/tmp/stock_chart.jpg` and returns that path.
- This path can be used by subsequent actions to display or upload the image.