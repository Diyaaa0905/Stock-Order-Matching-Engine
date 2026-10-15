# ⚙️ Apex Trading Engine Backend

High-performance matching engine and REST/SSE API server built in Java 21 adhering to ACID transactional semantics.

---

## 🚀 Key Architectural Features

- **ACID Transaction Model**:
  - **Atomicity**: Trade settlement atomically transfers shares and debits/credits rupees. In the event of insufficient balance or shares, the transaction fails and state is unchanged.
  - **Consistency**: Invariant balance and share equations are preserved at all times (`balance >= 0`, `shares >= 0`).
  - **Isolation**: FIFO Price-Time priority matching via a dedicated single-threaded matching worker eliminates concurrency race conditions.
  - **Durability**: Executed trades, orders, and balances are written to disk / database.
- **Dynamic User Authentication**:
  - Zero hardcoded users.
  - Encrypted passwords (SHA-256).
  - New traders start with **₹0.00** balance.
  - Profile update API with password update capability.
- **Initial Market Shares**:
  - All listed markets (RELIANCE, TCS, INFY, HDFCBANK, TATAMOTORS, AAPL, TSLA, MSFT) have initial shares (100, 20, 200, 300, etc.) present on the order book.
  - Real-time Bid & Ask depth levels loaded via system liquidity provider.

---

## ⚡ Quick Start

### Windows:
```cmd
run.bat
```

### Linux / macOS:
```bash
chmod +x run.sh
./run.sh
```

Server starts on: **http://localhost:8080**

---

## 📡 REST API Reference

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/auth/register` | Register new user (Starts with ₹0.00 balance) |
| `POST` | `/api/auth/login` | Login user with encrypted password check |
| `GET` | `/api/auth/profile?traderId={id}` | View trader profile details |
| `POST` | `/api/auth/profile` | Update profile (name, email, password) |
| `GET` | `/api/stocks` | List stocks with live market statistics & initial shares |
| `GET` | `/api/stocks/{ticker}/book` | Bid and Ask depth ladder with quantities |
| `GET` | `/api/stocks/{ticker}/chart?timeframe={1D\|1M\|1Y\|ALL}` | Historical price points for charts |
| `GET` | `/api/stocks/{ticker}/trades` | Recent executed trades tape |
| `POST` | `/api/orders` | Submit order (`LIMIT`, `MARKET`, `STOP_ORDER`) |
| `DELETE` | `/api/orders/{id}` | Cancel resting order |
| `GET` | `/api/orders?traderId={id}` | Trader order history (Open, Filled, Cancelled) |
| `GET` | `/api/portfolio?traderId={id}` | Trader stock holdings & P&L |
| `GET` | `/api/account?traderId={id}` | Cash balance in Rupees (₹) |
| `POST` | `/api/account` | Add/Deposit balance in Rupees (₹) |
| `GET` | `/api/stream` | Server-Sent Events (SSE) live updates |
