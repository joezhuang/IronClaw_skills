# check_exchange_rate Skill

This skill fetches live currency exchange rates using the free, public Frankfurter API. 

### Usage
It takes a `base_currency` and a `target_currency` (standard 3-letter ISO codes) and returns a human-readable string of the current conversion rate.

### Requirements
- No external Python libraries are required as it uses the built-in `urllib` module.
- Requires an active internet connection to reach `api.frankfurter.app`.

### Supported Currencies
Supports major global currencies including: USD, EUR, GBP, JPY, AUD, CAD, CHF, CNY, HKD, NZD, SEK, KRW, SGD, NOK, MXN, INR, etc.

### Example Input
```json
{
  "base_currency": "USD",
  "target_currency": "EUR"
}
```

### Example Output
```json
{
  "exchange_rate": "1 USD is worth 0.945 EUR"
}
```