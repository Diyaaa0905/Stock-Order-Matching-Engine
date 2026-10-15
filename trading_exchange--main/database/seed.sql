-- =============================================================================
-- MySQL Initial Seed Data for Apex Stock Trading Engine
-- Preloads listed markets with initial shares (100, 20, 200, etc.)
-- NOTE: No regular users are hardcoded. New users start with 0 Rupees balance.
-- =============================================================================

USE trading_engine;

-- 1. Register Exchange System Liquidity Provider (SYS_MM)
-- This is NOT a regular user account; it provides initial market shares/depth.
INSERT INTO users (id, username, email, full_name, password_hash, status) VALUES
('SYS_MM', 'exchange_liquidity', 'liquidity@exchange.internal', 'Exchange Market Maker', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'ACTIVE')
ON DUPLICATE KEY UPDATE full_name = VALUES(full_name);

INSERT INTO accounts (id, user_id, currency, available_balance, locked_balance, realized_pnl) VALUES
('ACC-SYS_MM', 'SYS_MM', 'INR', 10000000.0000, 0.0000, 0.0000)
ON DUPLICATE KEY UPDATE currency = VALUES(currency);

-- 2. Register Listed Markets with Initial Shares and Prices (in Rupees ₹)
-- All listed markets have initial shares present (e.g., 100, 20, 200, 150, 300)
INSERT INTO stocks (ticker, company_name, tick_size, lot_size, initial_shares, trading_paused, circuit_breaker_threshold, circuit_breaker_tripped, last_traded_price, open_price, high_price, low_price, total_volume, is_active) VALUES
('RELIANCE', 'Reliance Industries Ltd.', 0.0500, 1, 200, FALSE, 10.00, FALSE, 2850.5000, 2850.5000, 2890.0000, 2840.0000, 200, TRUE),
('TCS', 'Tata Consultancy Services', 0.0500, 1, 100, FALSE, 10.00, FALSE, 3920.0000, 3920.0000, 3960.0000, 3905.0000, 100, TRUE),
('INFY', 'Infosys Ltd.', 0.0500, 1, 300, FALSE, 10.00, FALSE, 1520.7500, 1520.7500, 1545.0000, 1510.0000, 300, TRUE),
('HDFCBANK', 'HDFC Bank Ltd.', 0.0500, 1, 250, FALSE, 10.00, FALSE, 1680.0000, 1680.0000, 1705.0000, 1672.0000, 250, TRUE),
('TATAMOTORS', 'Tata Motors Ltd.', 0.0500, 1, 200, FALSE, 10.00, FALSE, 985.2500, 985.2500, 1010.0000, 978.0000, 200, TRUE),
('AAPL', 'Apple Inc.', 0.0100, 1, 150, FALSE, 10.00, FALSE, 185.5000, 185.5000, 188.0000, 184.2000, 150, TRUE),
('TSLA', 'Tesla Inc.', 0.0500, 1, 100, FALSE, 10.00, FALSE, 245.0000, 245.0000, 252.0000, 240.5000, 100, TRUE),
('MSFT', 'Microsoft Corporation', 0.0100, 1, 80, FALSE, 10.00, FALSE, 420.0000, 420.0000, 426.5000, 418.0000, 80, TRUE)
ON DUPLICATE KEY UPDATE company_name = VALUES(company_name), initial_shares = VALUES(initial_shares);

-- 3. Preload Initial Shares Inventory for Liquidity Provider
INSERT INTO positions (id, user_id, ticker, shares, locked_shares, avg_cost) VALUES
('POS-SYS-RELIANCE', 'SYS_MM', 'RELIANCE', 200, 0, 2850.5000),
('POS-SYS-TCS', 'SYS_MM', 'TCS', 100, 0, 3920.0000),
('POS-SYS-INFY', 'SYS_MM', 'INFY', 300, 0, 1520.7500),
('POS-SYS-HDFCBANK', 'SYS_MM', 'HDFCBANK', 250, 0, 1680.0000),
('POS-SYS-TATAMOTORS', 'SYS_MM', 'TATAMOTORS', 200, 0, 985.2500),
('POS-SYS-AAPL', 'SYS_MM', 'AAPL', 150, 0, 185.5000),
('POS-SYS-TSLA', 'SYS_MM', 'TSLA', 100, 0, 245.0000),
('POS-SYS-MSFT', 'SYS_MM', 'MSFT', 80, 0, 420.0000)
ON DUPLICATE KEY UPDATE shares = VALUES(shares), avg_cost = VALUES(avg_cost);
