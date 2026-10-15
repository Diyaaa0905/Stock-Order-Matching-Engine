package com.engine;

import com.engine.api.TradingHttpServer;
import com.engine.core.*;
import com.engine.db.AuthManager;
import com.engine.db.DatabaseManager;
import com.engine.model.Enums.OrderSide;
import com.engine.model.Enums.OrderType;
import com.engine.model.Order;
import com.engine.model.Stock;
import com.engine.model.UserProfile;

public class Main {
    public static void main(String[] args) {
        System.out.println("=================================================");
        System.out.println(" Apex Stock Order Matching Engine & Full-Stack");
        System.out.println(" ACID Transactional Trading Architecture");
        System.out.println("=================================================");

        // 1. Setup Exchange & Registered Stocks with Initial Shares
        Exchange exchange = new Exchange();
        exchange.registerStock("RELIANCE", "Reliance Industries Ltd.", 0.05, 200, 2850.50);
        exchange.registerStock("TCS", "Tata Consultancy Services", 0.05, 100, 3920.00);
        exchange.registerStock("INFY", "Infosys Ltd.", 0.05, 300, 1520.75);
        exchange.registerStock("HDFCBANK", "HDFC Bank Ltd.", 0.05, 250, 1680.00);
        exchange.registerStock("TATAMOTORS", "Tata Motors Ltd.", 0.05, 200, 985.25);
        exchange.registerStock("AAPL", "Apple Inc.", 0.01, 150, 185.50);
        exchange.registerStock("TSLA", "Tesla Inc.", 0.05, 100, 245.00);
        exchange.registerStock("MSFT", "Microsoft Corporation", 0.01, 80, 420.00);

        // 2. Initialize UserProfileManager
        // NOTE: No regular users are hardcoded. New users start with ₹0.00 balance.
        UserProfileManager um = new UserProfileManager();

        // System Market Maker provides initial market liquidity and shares
        UserProfile systemMM = new UserProfile("SYS_MM", "Exchange Market Maker", 50000000.0);
        um.addUser(systemMM);

        // 3. Initialize Core Engine Components
        OrderBook orderBook = new OrderBook();
        StopOrderBook stopOrderBook = new StopOrderBook();
        TradeBook tradeBook = new TradeBook();
        OrderLog orderLog = new OrderLog();
        IncomingOrderQueue queue = new IncomingOrderQueue();

        MatchingEngine engine = new MatchingEngine(
                exchange,
                orderBook,
                stopOrderBook,
                tradeBook,
                orderLog,
                um
        );

        // 4. Initialize Database Layer
        DatabaseManager db = new DatabaseManager();
        engine.addListener(db);

        // 5. Start Single Matching Worker Thread (Guarantees Strict ACID Isolation)
        MatchingWorker worker = new MatchingWorker(queue, engine, exchange);
        Thread matchingThread = new Thread(worker, "MatchingEngine-Worker");
        matchingThread.setDaemon(true);
        matchingThread.start();

        // 6. Preload Initial Shares and Order Books for all Listed Markets
        // All listed markets have initial shares present like 100, 20, 200, etc.
        System.out.println("\n[ENGINE] Initializing listed markets with initial shares liquidity...");
        int orderSeq = 1;

        for (Stock stock : exchange.getAllStocks()) {
            double basePrice = stock.openPrice;
            int totalShares = stock.initialShares;
            systemMM.addShares(stock.ticker, totalShares * 3, basePrice);

            // Establish Asks (Sellers) with initial shares
            int askQty1 = totalShares / 2;
            int askQty2 = totalShares - askQty1;
            double askPrice1 = Math.round((basePrice + stock.tickSize * 2) * 100.0) / 100.0;
            double askPrice2 = Math.round((basePrice + stock.tickSize * 6) * 100.0) / 100.0;

            Order sellOrder1 = new Order("INIT-" + (orderSeq++), OrderSide.SELL, askPrice1, askQty1, OrderType.LIMIT, "SYS_MM", stock.ticker);
            Order sellOrder2 = new Order("INIT-" + (orderSeq++), OrderSide.SELL, askPrice2, askQty2, OrderType.LIMIT, "SYS_MM", stock.ticker);

            // Establish Bids (Buyers) with initial liquidity
            int bidQty1 = totalShares / 2;
            int bidQty2 = totalShares - bidQty1;
            double bidPrice1 = Math.round((basePrice - stock.tickSize * 2) * 100.0) / 100.0;
            double bidPrice2 = Math.round((basePrice - stock.tickSize * 6) * 100.0) / 100.0;

            Order buyOrder1 = new Order("INIT-" + (orderSeq++), OrderSide.BUY, bidPrice1, bidQty1, OrderType.LIMIT, "SYS_MM", stock.ticker);
            Order buyOrder2 = new Order("INIT-" + (orderSeq++), OrderSide.BUY, bidPrice2, bidQty2, OrderType.LIMIT, "SYS_MM", stock.ticker);

            engine.process(sellOrder1, stock);
            engine.process(sellOrder2, stock);
            engine.process(buyOrder1, stock);
            engine.process(buyOrder2, stock);

            System.out.println(" -> " + stock.ticker + " (" + stock.companyName + "): " + totalShares + " initial shares loaded on order book.");
        }
        System.out.println("[ENGINE] All listed markets active with initial shares.\n");

        // 7. Start REST & Mobile Backend Server on Port 8080
        int port = 8080;
        try {
            AuthManager auth = new AuthManager();
            TradingHttpServer server = new TradingHttpServer(port, engine, exchange, queue, um, db, auth);
            server.start();

            Runtime.getRuntime().addShutdownHook(new Thread(() -> {
                System.out.println("\nShutting down Trading Engine...");
                worker.stop();
                server.stop();
            }));

        } catch (Exception e) {
            System.err.println("Fatal: Could not start Trading HTTP Server: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
