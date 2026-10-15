# 🗄️ Database Architecture & Persistence

This directory contains the database schemas, seed configurations, and transaction integrity models for the Apex Trading Exchange.

---

## 📁 Files

- `schema.sql`: Complete MySQL schema with tables for users, accounts, stocks, positions, orders, trades, and exchange revenues.
- `seed.sql`: Seed data initializing listed stock markets with initial shares (e.g., 100, 20, 200, 300) and market maker liquidity pool. No regular user accounts are hardcoded.

---

## 🔒 Security & ACID Properties

1. **User Security**:
   - Passwords are encrypted with SHA-256 cryptographic hashing prior to storage.
   - Zero hardcoded users. All traders sign up dynamically with an initial cash balance of ₹0.00.

2. **ACID Transaction Guarantees**:
   - **Atomicity**: Trade execution deducts funds and transfers shares atomically. If buyer funds or seller shares are insufficient, the order fails without partial state changes.
   - **Consistency**: Invariant balance and share equations are strictly preserved at all times (`balance >= 0`, `shares >= 0`).
   - **Isolation**: Order matching executes through a single serial worker thread ensuring FIFO price-time priority without race conditions.
   - **Durability**: Executed orders, trades, and account balances are committed to MySQL using InnoDB storage engine with write-behind logging.

---

## 🚀 Setup & Execution

### Windows (PowerShell):
PowerShell does not support the `<` input redirection operator. Use either of these commands:

```powershell
# Method 1 (Pipe input - Recommended for PowerShell):
Get-Content schema.sql | mysql -u root -p
Get-Content seed.sql | mysql -u root -p

# Method 2 (Using MySQL source flag):
mysql -u root -p -e "source schema.sql"
mysql -u root -p -e "source seed.sql"

# Method 3 (Run via Command Prompt):
cmd /c "mysql -u root -p < schema.sql"
cmd /c "mysql -u root -p < seed.sql"
```

### Windows (Command Prompt - cmd.exe) / Linux / macOS:
```bash
mysql -u root -p < schema.sql
mysql -u root -p < seed.sql
```
*(If MySQL is offline, the backend automatically operates in high-speed in-memory mode).*
