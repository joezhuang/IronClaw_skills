# fetch_crypto_price Skill

This skill retrieves the current market price of various cryptocurrencies in USD using the CoinGecko public API.

### Requirements
- Active internet connection to reach `api.coingecko.com`.
- Standard macOS Python 3 environment.

### Logic
1. **Normalization**: The skill converts input to Title Case and maps common symbols (BTC, ETH, SOL, etc.) to the specific IDs required by the CoinGecko API.
2. **Network**: It uses the built-in `urllib` library to ensure compatibility without external dependencies like `requests`.
3. **Formatting**: It returns a structured JSON object containing the normalized name and the price.

### Example Usage
- `fetch_crypto_price(coin_input="BTC")` -> Returns Bitcoin price.
- `fetch_crypto_price(coin_input="ethereum")` -> Returns Ethereum price.
- `fetch_crypto_price(coin_input="Solana")` -> Returns Solana price.