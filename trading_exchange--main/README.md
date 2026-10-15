# 🚀 Apex Stock Order Matching Engine & Full-Stack Trading Platform

A high-performance stock order matching engine and full-stack trading exchange with an advanced **Flutter mobile/web frontend**, **Java 21 ACID-compliant matching backend**, and **MySQL persistence layer**.

---

## 📁 Repository Structure

The codebase is organized into three clean directories:

```
trading_exchange--main/
├── frontend/               # Flutter mobile & web trading application
│   ├── lib/
│   │   ├── models/         # Stock, Order, User, Position, OrderBook models
│   │   ├── services/       # ApiService, AuthService, CryptoHelper (Pure SHA-256)
│   │   ├── screens/        # Auth, MainNav, Explore, StockDetail, BuySell, Holdings, Positions, Orders
│   │   └── widgets/        # Custom Numpad, Chart Canvas, Market Depth, Profile Modal, Dialogs
│   ├── web/                # Web application runner
│   ├── pubspec.yaml        # Flutter specifications
│   └── README.md
│
├── backend/                # Java 21 FIFO Matching Engine & REST/SSE Server
│   ├── src/main/java/com/engine/
│   │   ├── api/            # TradingHttpServer, SSE Broadcaster
│   │   ├── core/           # MatchingEngine, OrderBook, CircuitBreaker, OrderValidator
│   │   ├── db/             # AuthManager, DatabaseManager
│   │   ├── model/          # Stock, Order, Position, UserProfile, TradeRecord
│   │   └── Main.java       # Exchange startup & Initial market shares bootstrap
│   ├── run.bat             # 1-click Windows compilation & startup
│   ├── run.sh              # 1-click Linux/macOS startup
│   └── README.md
│
└── database/               # Database schemas & persistence migrations
    ├── schema.sql          # MySQL schema (Users, Accounts, Stocks, Positions, Orders, Trades)
    ├── seed.sql            # Initial market shares bootstrap & liquidity pool
    └── README.md
```

---

## 🌟 Key Application Features

### 1. Flutter Client Interface
- **Authentication**:
  - Zero hardcoded users.
  - New traders start with **₹0.00** balance.
  - Encrypted password storage (SHA-256).
  - **Eye blink option** (password visibility toggle) on all password fields.
  - Instant redirection to the main app upon sign-in or registration.
- **Main Navigation (4 Bottom Tabs)**:
  1. **Explore Stocks (Default)**: Browse listed markets with live ₹ prices, % growth badges, 24h volume, and initial market shares.
  2. **Holdings**: Portfolio valuation in ₹, total invested capital, current worth, and P&L breakdown.
  3. **Open Positions**: Active intraday positions, market exposure, and unrealized P&L.
  4. **Orders**: Categorized order history (`All`, `Open`, `Filled`, `Cancelled`) with one-click cancellation for open resting orders.
- **Top-Right Profile Menu**:
  - Displays user **PFP** (avatar) and **Name directly under it**.
  - Current available balance in Rupees (₹).
  - **3 Options**:
    1. **Add Balance**: Deposit funds into account (starting from ₹0).
    2. **Change/View Account Details**: View trader details, update name, email, and password (with eye blink toggle).
    3. **Log Out**: Sign out and return to authentication screen.
- **Stock Detail & Interactive Charting**:
  - Live price in ₹, day growth (+/- ₹ and %).
  - Custom interactive chart with timeframe selector: **1D (1 Day)**, **1M (1 Month)**, **1Y (1 Year)**, and **ALL (All Time)**.
  - Touch/cursor hover crosshair and price tooltip.
  - **Market Depth Ladder (Order Book)**: Level-2 Bid Price + Qty (buyers in green) and Ask Price + Qty (sellers in red) with volume depth bars.
  - Prominent **BUY** and **SELL** buttons.
- **Dedicated Buy / Sell Page (Order Placement)**:
  - Redirects to a dedicated order pad screen.
  - BUY (Green) and SELL (Red) side toggle.
  - Order type selector:
    - **LIMIT** (Enter limit price and quantity)
    - **MARKET** (Immediate execution at current market price)
    - **STOP ORDER** (Input **Stop Threshold** trigger price and quantity)
  - **Custom on-screen Numpad** for fast, tactile numeric entry on mobile devices.
  - Live order calculation: Total Estimated ₹, Brokerage fee (0.1%), Available Cash Balance / Available Shares.

---

### 2. ACID Transaction Guarantees
- **Atomicity**: Trade settlement atomically transfers shares and debits/credits rupees. In the event of insufficient balance or shares, the order is rejected without partial state changes.
- **Consistency**: Invariants `balance >= 0` and `shares >= 0` are enforced at all times.
- **Isolation**: FIFO price-time matching worker executes orders serially on a dedicated thread, eliminating double-spending and race conditions.
- **Durability**: Orders, trades, and balances are persisted to MySQL with InnoDB storage engine.

---

### 3. Listed Markets with Initial Shares
All listed markets have initial shares (100, 20, 200, 300, etc.) present on the order book via the Exchange System Liquidity Provider (`SYS_MM`):

| Ticker | Company Name | Initial Shares | Base Price (₹) | Tick Size |
| :--- | :--- | :--- | :--- | :--- |
| `RELIANCE` | Reliance Industries Ltd. | 200 shs | ₹2,850.50 | 0.05 |
| `TCS` | Tata Consultancy Services | 100 shs | ₹3,920.00 | 0.05 |
| `INFY` | Infosys Ltd. | 300 shs | ₹1,520.75 | 0.05 |
| `HDFCBANK` | HDFC Bank Ltd. | 250 shs | ₹1,680.00 | 0.05 |
| `TATAMOTORS` | Tata Motors Ltd. | 200 shs | ₹985.25 | 0.05 |
| `AAPL` | Apple Inc. | 150 shs | ₹185.50 | 0.01 |
| `TSLA` | Tesla Inc. | 100 shs | ₹245.00 | 0.05 |
| `MSFT` | Microsoft Corp. | 80 shs | ₹420.00 | 0.01 |

---

## ⚡ Quick Start Guide

### Step 1: Run Backend Matching Engine
Requirements: **Java 21** or later.

#### Windows:
```cmd
cd backend
run.bat
```

#### Linux / macOS:
```bash
cd backend
chmod +x run.sh
./run.sh
```

Server starts on: **http://localhost:8080**

---

### Step 2: Run Flutter App
Requirements: **Flutter SDK**.

```bash
cd frontend
flutter pub get

# For Web:
flutter run -d chrome

# For Android:
flutter run -d android

# For Windows Desktop:
flutter run -d windows
```

---

### Step 3: Database Setup (Optional)

#### Windows (PowerShell):
```powershell
cd database
Get-Content schema.sql | mysql -u root -p
Get-Content seed.sql | mysql -u root -p
```

#### Windows (Command Prompt - cmd.exe) / Linux / macOS:
```bash
cd database
mysql -u root -p < schema.sql
mysql -u root -p < seed.sql
```
*(If MySQL is not running, the platform operates seamlessly in high-speed in-memory mode).*