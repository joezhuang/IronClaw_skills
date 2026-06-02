# read_article Skill

This skill is a universal, highly intelligent article scraper. It automatically detects whether a URL is a direct external news site or a internal Briefly news cluster, dynamically adjusting its extraction strategy to bypass videos, paywalls, and React lazy-loading.

### Functionality:

1. **Universal Routing:** Automatically identifies standard external links (e.g., Reuters, TechCrunch) versus Briefly app cluster URLs, deploying the appropriate scraping strategy for each.
2. **Hunter-Seeker Polling (Briefly Links):** Uses active DOM polling to bypass React lazy-loading, harvesting all available outbound source links from a Briefly cluster and queuing them for extraction.
3. **Smart Filtering & Video Bypass:** Automatically skips known video platforms (YouTube, Vimeo, TikTok) based on URL patterns. If a page loads but contains shallow text (e.g., hidden video players or hard paywalls), it dynamically rejects the link and moves to the next available source in the queue.
4. **Dynamic DOM Extraction:** Intelligently strips away heavy publisher clutter (paywall banners, scripts, navigation bars, and ad-injectors) and targets the semantic text core (`<article>`, `<main>`) to capture raw, unfiltered news copy.
5. **Media Capture & Payload Delivery:** Scans the page's OpenGraph metadata to locate the canonical article image, downloads it locally, and formats the final text using the standard `--- DEEP ARTICLE READ ---` delimiter required by the IronClaw state machine.
