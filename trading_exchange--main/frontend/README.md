# 📱 Apex Trader - Flutter Mobile & Web Client

A modern, high-performance Flutter trading application connected to the Apex Matching Engine with real-time level-2 market depth, ACID-validated order execution, encrypted security, and portfolio management.

---

## 🌟 Key Application Features

1. **Authentication & Security**:
   - Zero hardcoded users.
   - Dynamic registration with **₹0.00** starting balance.
   - Encrypted passwords stored cryptographically (SHA-256).
   - **Eye blink option** (password visibility toggle icon) on all password fields.
   - Seamless redirection to the main trading app upon authentication.

2. **Main Navigation (4 Bottom Tabs)**:
   - **Explore Stocks (Default)**: View all listed markets with live prices in ₹ (Rupees), growth %, day change, volume, and initial market shares badge.
   - **Holdings**: Portfolio tracking with total portfolio value, invested capital, current value, and overall P&L.
   - **Open Positions**: Active day trading positions and intraday unrealized P&L in real time.
   - **Orders**: Full order history tabbed by `All`, `Open`, `Filled`, and `Cancelled/Rejected` with one-tap order cancellation for open resting orders.

3. **Top-Right Profile Menu**:
   - Displays User PFP (avatar) and Name under it.
   - Displays User ID, username, and live cash balance in ₹.
   - **3 Options**:
     1. **Add Balance**: Deposit funds into the trading account (new user starts with ₹0.00). Quick presets (+₹500, +₹1,000, +₹5,000, +₹10,000, +₹50,000) or custom input.
     2. **Change/View Account Details**: View and update full name, email, and password (with eye blink toggle).
     3. **Log Out**: Sign out and return to the login screen.

4. **Stock Detail Screen**:
   - Stock ticker, company name, current price in ₹, growth change.
   - Interactive Canvas chart with timeframe selector: **1D (1 Day)**, **1M (1 Month)**, **1Y (1 Year)**, and **ALL (All Time)**.
   - **Market Depth Ladder (Order Book)**: Top Bid price + qty (buyers) and Top Ask price + qty (sellers) with volume depth bars.
   - Prominent **BUY** and **SELL** action buttons.

5. **Dedicated Buy / Sell Page (Order Placement)**:
   - Redirects to dedicated order execution page.
   - Side toggle: `BUY` (Emerald Green) or `SELL` (Crimson Red).
   - Order type selection:
     - `LIMIT`
     - `MARKET`
     - `STOP ORDER` (with dynamic **Stop Threshold** price input field).
   - **Custom on-screen Numpad** for fast, tactile numeric entry.
   - Live cost and brokerage calculation.
   - Strict ACID transaction validation (balance check, share check, atomicity).

---

## 📁 Architecture & File Structure

```
frontend/
├── pubspec.yaml            # Flutter project specifications & dependencies
├── analysis_options.yaml   # Linter configuration
├── web/                    # Web runner assets
│   ├── index.html
│   └── manifest.json
└── lib/
    ├── main.dart           # App entrypoint and Dark Material 3 theme
    ├── models/
    │   ├── user_model.dart
    │   ├── stock_model.dart
    │   ├── order_model.dart
    │   ├── position_model.dart
    │   ├── order_book_model.dart
    │   └── chart_point_model.dart
    ├── services/
    │   ├── api_service.dart
    │   ├── auth_service.dart
    │   └── crypto_helper.dart
    ├── screens/
    │   ├── auth_screen.dart
    │   ├── main_navigation_screen.dart
    │   ├── explore_stocks_screen.dart
    │   ├── stock_detail_screen.dart
    │   ├── buy_sell_screen.dart
    │   ├── holdings_screen.dart
    │   ├── positions_screen.dart
    │   └── orders_screen.dart
    └── widgets/
        ├── custom_numpad.dart
        ├── stock_chart_widget.dart
        ├── market_depth_widget.dart
        ├── profile_modal.dart
        ├── add_balance_dialog.dart
        └── account_details_dialog.dart
```

---

## ⚡ How to Run

Ensure Flutter SDK is installed:

```bash
cd frontend
flutter pub get

# Run on Chrome Web:
flutter run -d chrome

# Run on Android Emulator:
flutter run -d android

# Run on Windows Desktop:
flutter run -d windows
```
