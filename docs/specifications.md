
# Milestone 1: Core iOS/Swift fundamentals (no networking, no persistence) ✅
1. Build a simple SwiftUI app shell
• Features: Tab bar with two tabs: “Portfolio” and “Watchlist”.
• Learn: Xcode basics, Swift language fundamentals, SwiftUI Views, @State, View composition, navigation.
• Goal: Static screens with placeholder data.

2. Local Watchlist with manual entry
• Features: Add/remove ticker symbols, show a simple list.
• Learn: Lists, forms, @State, @Binding, simple models (structs).
• Goal: You can add AAPL, MSFT, etc. manually and see them in a list.

3. Persist the Watchlist locally
• Features: Save tickers between app launches.
• Learn: AppStorage, Codable + UserDefaults, or lightweight persistence via SwiftData (if you’re on iOS 17+).
• Goal: Data survives app restarts.

# Milestone 2: Networking and basic async programming ✅
4. Fetch current prices for tickers from a public API
• Features: Pull latest prices for the watchlist.
• Learn: URLSession, Swift Concurrency (async/await), decoding JSON (Codable), error handling, refresh UI.
• Goal: Show live prices and simple price change.

5. Background refresh / manual refresh 
• Features: Pull-to-refresh or a refresh button.
• Learn: Task, .refreshable in SwiftUI, cancellation, retry strategies.
• Goal: Cleanly update prices on demand.

# Milestone 3: Portfolio modeling (manual first)
6. Manual portfolio tracking
• Features: Add positions (ticker, shares, cost basis), compute total value.
• Learn: Derived state, computed properties, basic math/formatting, number/date formatting, currency.
• Goal: Portfolio screen shows total value, allocation by symbol.

7. Persist portfolio data
• Features: Save positions locally.
• Learn: SwiftData/Core Data or JSON persistence. Choose one and stick with it.
• Goal: Manual entries are durable across launches and editable.

# Milestone 4: Analytics and goals (local-only first)
8. Investment goals
• Features: Set a target portfolio value, show progress.
• Learn: Simple view models, user input validation, basic charting (if you want a sparkline with Swift Charts).
• Goal: A “Goal” screen with target, current, and gap.

9. Contribution tracking (manual)
• Features: Add a “contribution” log (date, amount).
• Learn: Lists with sections by date, sorting, filtering.
• Goal: Show average monthly contribution computed locally.

10. Projection to goal date
• Features: Compute estimated time to reach goal using average contribution and assumed growth rate (start with zero growth).
• Learn: Basic math, optional parameters, what-if sliders (growth rate, monthly contribution).
• Goal: Display projected date and sensitivity.

# Milestone 5: Better data and UX
11. Historical price chart for a single symbol
• Features: Show a simple line chart for the last N days.
• Learn: Swift Charts, time series handling, multiple API endpoints, caching.
• Goal: Tap a ticker to see a detail view with chart and stats.

12. Performance metrics
• Features: Unrealized P/L per position, total return, daily change.
• Learn: More computed metrics, number formatting, edge cases (splits, dividends later).
• Goal: Portfolio screen shows meaningful metrics.

# Milestone 6: Plaid integration (move carefully)
13. Learn OAuth/Link flow and sandbox
• Features: Integrate Plaid Link in sandbox mode only.
• Learn: Plaid setup, secure keys, environment configuration, handling tokens safely.
• Goal: Complete a Link flow and receive a public token.

14. Secure backend stub (recommended)
• Features: Stand up a minimal backend (e.g., Vapor on Swift or a simple server) to exchange public token for access token. Do not store Plaid secrets in the app.
• Learn: Basic server concepts, REST, environment secrets, simple auth.
• Goal: Your app can securely obtain data without bundling secrets.

15. Pull transactions and identify investment contributions
• Features: Use Plaid’s transactions or investments endpoints, filter for transfers to brokerages.
• Learn: Parsing, categorization, data modeling, rate limits, pagination.
• Goal: Auto-populate contribution log from Plaid data.

16. Reconcile contributions with positions (optional/advanced)
• Features: Map contributions to buys; infer DCA, handle multiple accounts.
• Learn: Data reconciliation, matching heuristics, conflict resolution.
• Goal: More accurate performance and average contribution.

# Milestone 7: Advanced projections and polish
17. Better projections
• Features: Monte Carlo or variable growth assumptions; scenario sliders.
• Learn: Async computations, charts, performance considerations.
• Goal: Show confidence intervals or multiple scenarios.

18. Notifications and widgets (optional)
• Features: Price alerts, goal milestone notifications, Home Screen widgets.
• Learn: UserNotifications, WidgetKit, background tasks.
• Goal: Alerts when price crosses thresholds or monthly contribution dips.

19. Accessibility, theming, and settings
• Features: Dark mode, dynamic type, VoiceOver, color blindness friendly charts, settings for currency and API keys.
• Learn: Accessibility modifiers, AppStorage-backed settings.
• Goal: A polished, inclusive app.

20. Testing and reliability
• Features: Unit tests for models, async network tests with mocks, UI previews.
• Learn: Swift Testing framework, dependency injection for services, preview data.
• Goal: Confidence in changes and refactors.

What to learn at each step (high-level curriculum)
• Swift basics: structs, enums, optionals, protocols, extensions, generics (gradually).
• SwiftUI: views, state management (@State, @StateObject, @ObservedObject, @Environment, @EnvironmentObject), navigation, lists, forms, modifiers.
• Data: Codable, persistence (AppStorage/UserDefaults), then SwiftData/Core Data for more complex models.
• Networking: URLSession with async/await, decoding JSON, error handling, retries, caching basics.
• Charts: Swift Charts for price/time series.
• Security: Never store API secrets in the app; use a minimal backend for Plaid token exchange.
• Architecture: MVVM with simple service protocols for networking and persistence; dependency injection to enable testing.
• Testing: Start light with model tests and gradually add more.

Suggested order to ship value quickly
• v0.1: Watchlist (manual) + price fetching + persistence.
• v0.2: Portfolio (manual) + total value + basic metrics.
• v0.3: Goals + average contributions (manual) + projection.
• v0.4: Charts + polish.
• v0.5: Plaid sandbox integration + backend token exchange.
• v0.6: Auto-contribution import + improved projections.
