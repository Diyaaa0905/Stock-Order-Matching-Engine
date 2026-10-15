package com.engine.api;

import com.engine.core.*;
import com.engine.db.AuthManager;
import com.engine.db.DatabaseManager;
import com.engine.model.*;
import com.engine.model.Enums.OrderSide;
import com.engine.model.Enums.OrderType;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

import java.io.*;
import java.net.InetSocketAddress;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;
import java.util.concurrent.Executors;

public class TradingHttpServer implements EngineEventListener {
    private final int port;
    private final MatchingEngine engine;
    private final Exchange exchange;
    private final IncomingOrderQueue queue;
    private final UserProfileManager um;
    private final DatabaseManager db;
    private final AuthManager auth;
    private final SseBroadcaster broadcaster;
    private HttpServer server;

    // --- Admin Metrics ---
    private final java.util.concurrent.atomic.AtomicLong totalRequests = new java.util.concurrent.atomic.AtomicLong(0);
    private final java.util.concurrent.atomic.AtomicLong totalResponses = new java.util.concurrent.atomic.AtomicLong(0);
    private final java.util.concurrent.atomic.AtomicLong totalTransactions = new java.util.concurrent.atomic.AtomicLong(0);
    private final java.util.concurrent.ConcurrentLinkedDeque<String> recentActivity = new java.util.concurrent.ConcurrentLinkedDeque<>();
    private final java.util.concurrent.atomic.AtomicLong requestsThisWindow = new java.util.concurrent.atomic.AtomicLong(0);
    private volatile long windowStart = System.currentTimeMillis();
    private volatile double reqPerSecond = 0.0;
    private final java.util.concurrent.atomic.AtomicLong pendingRequests = new java.util.concurrent.atomic.AtomicLong(0);

    public TradingHttpServer(
            int port,
            MatchingEngine engine,
            Exchange exchange,
            IncomingOrderQueue queue,
            UserProfileManager um,
            DatabaseManager db,
            AuthManager auth) {
        this.port = port;
        this.engine = engine;
        this.exchange = exchange;
        this.queue = queue;
        this.um = um;
        this.db = db;
        this.auth = (auth != null) ? auth : new AuthManager();
        this.broadcaster = new SseBroadcaster();

        // Listen for engine events
        this.engine.addListener(this);
    }

    public void start() throws IOException {
        server = HttpServer.create(new InetSocketAddress(port), 0);
        server.setExecutor(Executors.newVirtualThreadPerTaskExecutor());

        // API routes
        server.createContext("/api/auth", new AuthHandler());
        server.createContext("/api/stocks", new StocksHandler());
        server.createContext("/api/orders", new OrdersHandler());
        server.createContext("/api/portfolio", new PortfolioHandler());
        server.createContext("/api/account", new AccountHandler());
        server.createContext("/api/admin", new AdminHandler());
        server.createContext("/api/stream", exchange -> broadcaster.register(exchange));

        // Static files fallback
        server.createContext("/", new StaticFileHandler());

        server.start();
        System.out.println("========================================================");
        System.out.println(" Apex Trading Engine Server Live on Port " + port);
        System.out.println(" Base API URL: http://localhost:" + port);
        System.out.println("========================================================");
    }

    public void stop() {
        if (server != null) {
            server.stop(0);
        }
    }

    // --- SSE Event Dispatching ---
    @Override
    public void onTradeExecuted(TradeRecord t) {
        totalTransactions.incrementAndGet();
        addActivity("TRADE: " + t.ticker + " " + t.quantity + " @ ₹" + String.format(Locale.US, "%.2f", t.price));
        broadcaster.broadcast("trade", formatTradeJson(t));
        Stock s = exchange.getStock(t.ticker);
        if (s != null) {
            broadcaster.broadcast("stock_update", formatStockJson(s));
        }
    }

    @Override
    public void onOrderUpdated(Order o) {
        broadcaster.broadcast("order_update", formatOrderJson(o));
    }

    @Override
    public void onOrderBookChanged(String ticker) {
        Stock s = exchange.getStock(ticker);
        if (s != null) {
            broadcaster.broadcast("book_update", formatOrderBookJson(s));
        }
    }

    @Override
    public void onCircuitBreakerTripped(Stock s) {
        broadcaster.broadcast("circuit_breaker", "{\"ticker\":\"" + s.ticker + "\",\"paused\":true}");
    }

    // --- Handlers ---
    private class AuthHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            String method = ex.getRequestMethod();
            String path = ex.getRequestURI().getPath();

            if ("OPTIONS".equalsIgnoreCase(method)) {
                ex.sendResponseHeaders(204, -1);
                return;
            }

            // POST /api/auth/register
            if (path.endsWith("/register") && "POST".equalsIgnoreCase(method)) {
                String body = readBody(ex);
                Map<String, String> map = parseJsonSimple(body);
                String username = map.get("username");
                String email = map.get("email");
                String fullName = map.get("fullName");
                String password = map.get("password");

                try {
                    AuthManager.UserCredential cred = auth.register(username, email, fullName, password, um, db);
                    UserProfile profile = um.getUser(cred.id);
                    double balance = profile != null ? profile.balance : 0.0;
                    String json = String.format(Locale.US,
                            "{\"success\":true,\"user\":{\"id\":\"%s\",\"username\":\"%s\",\"email\":\"%s\",\"fullName\":\"%s\",\"balance\":%.2f}}",
                            cred.id, cred.username, cred.email, cred.fullName, balance
                    );
                    sendJson(ex, 200, json);
                } catch (IllegalArgumentException e) {
                    sendJson(ex, 400, "{\"success\":false,\"message\":\"" + escapeJson(e.getMessage()) + "\"}");
                }
                return;
            }

            // POST /api/auth/login
            if (path.endsWith("/login") && "POST".equalsIgnoreCase(method)) {
                String body = readBody(ex);
                Map<String, String> map = parseJsonSimple(body);
                String username = map.get("username");
                String password = map.get("password");

                AuthManager.UserCredential cred = auth.login(username, password);
                if (cred != null) {
                    UserProfile profile = um.getUser(cred.id);
                    double balance = profile != null ? profile.balance : 0.0;
                    String json = String.format(Locale.US,
                            "{\"success\":true,\"user\":{\"id\":\"%s\",\"username\":\"%s\",\"email\":\"%s\",\"fullName\":\"%s\",\"balance\":%.2f}}",
                            cred.id, cred.username, cred.email, cred.fullName, balance
                    );
                    sendJson(ex, 200, json);
                } else {
                    sendJson(ex, 401, "{\"success\":false,\"message\":\"Invalid username/email or password.\"}");
                }
                return;
            }

            // GET or POST /api/auth/profile
            if (path.endsWith("/profile")) {
                if ("GET".equalsIgnoreCase(method)) {
                    Map<String, String> q = parseQuery(ex.getRequestURI().getQuery());
                    String traderId = q.get("traderId");
                    if (traderId == null || traderId.isEmpty()) {
                        sendJson(ex, 400, "{\"error\":\"Missing traderId\"}");
                        return;
                    }
                    AuthManager.UserCredential cred = auth.getById(traderId);
                    UserProfile profile = um.getUser(traderId);
                    if (cred == null || profile == null) {
                        sendJson(ex, 404, "{\"error\":\"User not found\"}");
                        return;
                    }
                    String json = String.format(Locale.US,
                            "{\"id\":\"%s\",\"username\":\"%s\",\"email\":\"%s\",\"fullName\":\"%s\",\"balance\":%.2f,\"realizedPnL\":%.2f}",
                            cred.id, cred.username, cred.email, cred.fullName, profile.balance, profile.realizedPnL
                    );
                    sendJson(ex, 200, json);
                    return;
                }

                if ("POST".equalsIgnoreCase(method) || "PUT".equalsIgnoreCase(method)) {
                    String body = readBody(ex);
                    Map<String, String> map = parseJsonSimple(body);
                    String traderId = map.get("traderId");
                    String fullName = map.get("fullName");
                    String email = map.get("email");
                    String password = map.get("password");

                    try {
                        AuthManager.UserCredential updated = auth.updateProfile(traderId, fullName, email, password, um, db);
                        UserProfile profile = um.getUser(traderId);
                        double bal = profile != null ? profile.balance : 0.0;
                        String json = String.format(Locale.US,
                                "{\"success\":true,\"user\":{\"id\":\"%s\",\"username\":\"%s\",\"email\":\"%s\",\"fullName\":\"%s\",\"balance\":%.2f}}",
                                updated.id, updated.username, updated.email, updated.fullName, bal
                        );
                        sendJson(ex, 200, json);
                    } catch (IllegalArgumentException e) {
                        sendJson(ex, 400, "{\"success\":false,\"message\":\"" + escapeJson(e.getMessage()) + "\"}");
                    }
                    return;
                }
            }

            sendJson(ex, 404, "{\"error\":\"Unknown auth endpoint\"}");
        }
    }

    private class StocksHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            String method = ex.getRequestMethod();
            String path = ex.getRequestURI().getPath();

            if ("OPTIONS".equalsIgnoreCase(method)) {
                ex.sendResponseHeaders(204, -1);
                return;
            }

            // Route: GET /api/stocks/{ticker}/chart
            if (path.matches("^/api/stocks/[A-Za-z0-9_-]+/chart$")) {
                String[] parts = path.split("/");
                String ticker = parts[3].toUpperCase();
                Stock s = exchange.getStock(ticker);
                if (s == null) {
                    sendJson(ex, 404, "{\"error\":\"Unknown ticker: " + ticker + "\"}");
                    return;
                }
                Map<String, String> q = parseQuery(ex.getRequestURI().getQuery());
                String tf = q.getOrDefault("timeframe", "1D");
                List<Stock.ChartPoint> points = s.generateChartData(tf);

                StringBuilder sb = new StringBuilder("[");
                for (int i = 0; i < points.size(); i++) {
                    Stock.ChartPoint p = points.get(i);
                    sb.append(String.format(Locale.US, "{\"timestamp\":%d,\"price\":%.2f,\"volume\":%d}",
                            p.timestamp, p.price, p.volume));
                    if (i < points.size() - 1) sb.append(",");
                }
                sb.append("]");
                sendJson(ex, 200, sb.toString());
                return;
            }

            // Route: GET /api/stocks/{ticker}/book
            if (path.matches("^/api/stocks/[A-Za-z0-9_-]+/book$")) {
                String[] parts = path.split("/");
                String ticker = parts[3].toUpperCase();
                Stock s = exchange.getStock(ticker);
                if (s == null) {
                    sendJson(ex, 404, "{\"error\":\"Unknown ticker: " + ticker + "\"}");
                } else {
                    sendJson(ex, 200, formatOrderBookJson(s));
                }
                return;
            }

            // Route: GET /api/stocks/{ticker}/trades
            if (path.matches("^/api/stocks/[A-Za-z0-9_-]+/trades$")) {
                List<TradeRecord> recent = engine.tradeBook.getRecent(30);
                StringBuilder sb = new StringBuilder("[");
                for (int i = 0; i < recent.size(); i++) {
                    sb.append(formatTradeJson(recent.get(i)));
                    if (i < recent.size() - 1) sb.append(",");
                }
                sb.append("]");
                sendJson(ex, 200, sb.toString());
                return;
            }

            // Route: GET /api/stocks
            StringBuilder sb = new StringBuilder("[");
            int i = 0;
            Collection<Stock> all = exchange.getAllStocks();
            for (Stock s : all) {
                sb.append(formatStockJson(s));
                if (i < all.size() - 1) sb.append(",");
                i++;
            }
            sb.append("]");
            sendJson(ex, 200, sb.toString());
        }
    }

    private class OrdersHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            String method = ex.getRequestMethod();
            String path = ex.getRequestURI().getPath();

            if ("OPTIONS".equalsIgnoreCase(method)) {
                ex.sendResponseHeaders(204, -1);
                return;
            }

            // DELETE /api/orders/{id}
            if ("DELETE".equalsIgnoreCase(method)) {
                String[] parts = path.split("/");
                if (parts.length >= 4) {
                    String orderId = parts[3];
                    boolean success = engine.cancelOrder(orderId);
                    if (success) {
                        sendJson(ex, 200, "{\"success\":true,\"message\":\"Order " + orderId + " cancelled.\"}");
                    } else {
                        sendJson(ex, 400, "{\"success\":false,\"message\":\"Could not cancel order (not found or already filled/cancelled).\"}");
                    }
                    return;
                }
            }

            // POST /api/orders
            if ("POST".equalsIgnoreCase(method)) {
                String body = readBody(ex);
                Map<String, String> map = parseJsonSimple(body);

                try {
                    String traderId = map.getOrDefault("traderId", "").trim();
                    String ticker = map.getOrDefault("ticker", "").trim().toUpperCase();
                    OrderSide side = OrderSide.valueOf(map.getOrDefault("side", "BUY").trim().toUpperCase());
                    String typeStr = map.getOrDefault("type", "LIMIT").trim().toUpperCase();

                    double price = Double.parseDouble(map.getOrDefault("price", "0"));
                    int quantity = Integer.parseInt(map.getOrDefault("quantity", "0"));

                    OrderType type = OrderType.LIMIT;
                    if ("MARKET".equals(typeStr)) {
                        type = OrderType.MARKET;
                    } else if ("STOP".equals(typeStr) || "STOP_ORDER".equals(typeStr) || "STOP_LOSS".equals(typeStr)) {
                        String thresholdStr = map.get("stopThreshold");
                        if (thresholdStr != null && !thresholdStr.isEmpty()) {
                            price = Double.parseDouble(thresholdStr);
                        }
                        type = (side == OrderSide.BUY) ? OrderType.STOP_BUY : OrderType.STOP_LOSS;
                    } else if ("STOP_BUY".equals(typeStr)) {
                        type = OrderType.STOP_BUY;
                    } else if ("LIMIT".equals(typeStr)) {
                        type = OrderType.LIMIT;
                    }

                    String orderId = "ORD-" + System.currentTimeMillis() % 100000;
                    Order newOrder = new Order(orderId, side, price, quantity, type, traderId, ticker);

                    String validation = OrderValidator.validate(newOrder, um, exchange);
                    if ("VALID".equals(validation)) {
                        queue.enqueue(newOrder);
                        sendJson(ex, 200, "{\"success\":true,\"orderId\":\"" + orderId + "\",\"status\":\"ACCEPTED\"}");
                    } else {
                        sendJson(ex, 400, "{\"success\":false,\"message\":\"" + escapeJson(validation) + "\"}");
                    }
                } catch (Exception e) {
                    sendJson(ex, 400, "{\"success\":false,\"message\":\"Invalid payload: " + escapeJson(e.getMessage()) + "\"}");
                }
                return;
            }

            // GET /api/orders?traderId=...
            if ("GET".equalsIgnoreCase(method)) {
                Map<String, String> query = parseQuery(ex.getRequestURI().getQuery());
                String traderId = query.get("traderId");

                List<Order> orders = (traderId != null && !traderId.isEmpty())
                        ? engine.getOrdersByTrader(traderId)
                        : new ArrayList<>(engine.getAllOrders());

                StringBuilder sb = new StringBuilder("[");
                for (int i = 0; i < orders.size(); i++) {
                    sb.append(formatOrderJson(orders.get(i)));
                    if (i < orders.size() - 1) sb.append(",");
                }
                sb.append("]");
                sendJson(ex, 200, sb.toString());
            }
        }
    }

    private class PortfolioHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            if ("OPTIONS".equalsIgnoreCase(ex.getRequestMethod())) {
                ex.sendResponseHeaders(204, -1);
                return;
            }

            Map<String, String> query = parseQuery(ex.getRequestURI().getQuery());
            String traderId = query.get("traderId");

            if (traderId == null || traderId.isEmpty()) {
                sendJson(ex, 400, "{\"error\":\"Missing traderId parameter\"}");
                return;
            }

            UserProfile user = um.getUser(traderId);
            if (user == null) {
                sendJson(ex, 404, "{\"error\":\"User not found\"}");
                return;
            }

            StringBuilder sb = new StringBuilder("{");
            sb.append("\"traderId\":\"").append(user.traderId).append("\",");
            sb.append("\"name\":\"").append(user.name).append("\",");
            sb.append("\"positions\":[");

            Map<String, Position> portfolio = user.getPortfolio();
            int i = 0;
            for (Map.Entry<String, Position> e : portfolio.entrySet()) {
                String ticker = e.getKey();
                Position p = e.getValue();
                Stock s = exchange.getStock(ticker);
                double currentPrice = (s != null && s.lastTradedPrice > 0) ? s.lastTradedPrice : p.avgCost;
                double unrealizedPnL = (currentPrice - p.avgCost) * p.shares;

                sb.append(String.format(Locale.US,
                        "{\"ticker\":\"%s\",\"shares\":%d,\"avgCost\":%.2f,\"currentPrice\":%.2f,\"unrealizedPnL\":%.2f}",
                        ticker, p.shares, p.avgCost, currentPrice, unrealizedPnL
                ));
                if (i < portfolio.size() - 1) sb.append(",");
                i++;
            }
            sb.append("]}");
            sendJson(ex, 200, sb.toString());
        }
    }

    private class AccountHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            String method = ex.getRequestMethod();

            if ("OPTIONS".equalsIgnoreCase(method)) {
                ex.sendResponseHeaders(204, -1);
                return;
            }

            // POST /api/account (Deposit / Add Balance in Rupees)
            if ("POST".equalsIgnoreCase(method)) {
                String body = readBody(ex);
                Map<String, String> map = parseJsonSimple(body);
                String traderId = map.get("traderId");
                double amount = 0.0;
                try {
                    amount = Double.parseDouble(map.getOrDefault("amount", "0"));
                } catch (Exception ignored) {}

                UserProfile u = um.getUser(traderId);
                if (u != null && amount > 0) {
                    u.deposit(amount);
                    db.syncUserProfile(u);
                    sendJson(ex, 200, String.format(Locale.US, "{\"success\":true,\"balance\":%.2f,\"message\":\"Added ₹%.2f successfully.\"}", u.balance, amount));
                } else {
                    sendJson(ex, 400, "{\"success\":false,\"message\":\"Invalid user ID or deposit amount.\"}");
                }
                return;
            }

            // GET /api/account?traderId=...
            Map<String, String> query = parseQuery(ex.getRequestURI().getQuery());
            String traderId = query.get("traderId");

            if (traderId == null || traderId.isEmpty()) {
                sendJson(ex, 400, "{\"error\":\"Missing traderId parameter\"}");
                return;
            }

            UserProfile u = um.getUser(traderId);
            if (u == null) {
                sendJson(ex, 404, "{\"error\":\"User not found\"}");
                return;
            }

            String json = String.format(Locale.US,
                    "{\"traderId\":\"%s\",\"name\":\"%s\",\"currency\":\"INR\",\"balance\":%.2f,\"realizedPnL\":%.2f,\"exchangeRevenue\":%.2f}",
                    u.traderId, u.name, u.balance, u.realizedPnL, exchange.totalRevenue
            );
            sendJson(ex, 200, json);
        }
    }

    private void tickMetrics() {
        long now = System.currentTimeMillis();
        long elapsed = now - windowStart;
        if (elapsed >= 1000) {
            reqPerSecond = requestsThisWindow.get() * 1000.0 / Math.max(elapsed, 1);
            requestsThisWindow.set(0);
            windowStart = now;
        }
        requestsThisWindow.incrementAndGet();
        totalRequests.incrementAndGet();
        pendingRequests.incrementAndGet();
    }

    private void finishMetrics() {
        totalResponses.incrementAndGet();
        pendingRequests.decrementAndGet();
    }

    private void addActivity(String msg) {
        recentActivity.addFirst(System.currentTimeMillis() + "|" + msg);
        if (recentActivity.size() > 100) recentActivity.pollLast();
    }

    private class AdminHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            addCorsHeaders(ex);
            String method = ex.getRequestMethod();
            String path = ex.getRequestURI().getPath();

            if ("OPTIONS".equalsIgnoreCase(method)) {
                ex.sendResponseHeaders(204, -1);
                return;
            }

            tickMetrics();
            try {
                // POST /api/admin/login
                if (path.endsWith("/login") && "POST".equalsIgnoreCase(method)) {
                    String body = readBody(ex);
                    Map<String, String> map = parseJsonSimple(body);
                    String username = map.get("username");
                    String password = map.get("password");
                    if (auth.isAdmin(username, password)) {
                        sendJson(ex, 200, "{\"success\":true,\"user\":{\"id\":\"ADMIN\",\"username\":\"admin\",\"email\":\"admin@gmail.com\",\"fullName\":\"admin\",\"role\":\"ADMIN\"}}");
                        addActivity("ADMIN LOGIN by: " + (username != null ? username : "?"));
                    } else {
                        sendJson(ex, 401, "{\"success\":false,\"message\":\"Invalid admin credentials.\"}");
                    }
                    return;
                }

                // Require admin key for all other endpoints
                String adminKey = ex.getRequestHeaders().getFirst("X-Admin-Key");
                if (adminKey == null) {
                    Map<String, String> q = parseQuery(ex.getRequestURI().getQuery());
                    adminKey = q.get("adminKey");
                }
                if (!"ADMIN".equals(adminKey)) {
                    sendJson(ex, 403, "{\"error\":\"Unauthorized. Provide X-Admin-Key header.\"}");
                    return;
                }

                // GET /api/admin/dashboard
                if (path.endsWith("/dashboard") && "GET".equalsIgnoreCase(method)) {
                    int totalUsers = auth.getAllUsers().size();
                    java.util.Set<String> activeIds = new java.util.HashSet<>();
                    for (Order o : engine.getAllOrders()) activeIds.add(o.traderId);
                    int activeUsers = (int) activeIds.stream().filter(id -> auth.getById(id) != null).count();
                    int inactiveUsers = totalUsers - activeUsers;

                    long pendingOrders = engine.getAllOrders().stream()
                        .filter(o -> o.status == com.engine.model.Enums.OrderStatus.NEW
                                  || o.status == com.engine.model.Enums.OrderStatus.PARTIALLY_FILLED)
                        .count();

                    StringBuilder actArr = new StringBuilder("[");
                    int cnt = 0;
                    for (String entry : recentActivity) {
                        if (cnt >= 20) break;
                        String[] parts = entry.split("\\|", 2);
                        String ts = parts.length > 0 ? parts[0] : "0";
                        String msg = parts.length > 1 ? escapeJson(parts[1]) : "";
                        if (cnt > 0) actArr.append(",");
                        actArr.append(String.format("{\"timestamp\":%s,\"message\":\"%s\"}", ts, msg));
                        cnt++;
                    }
                    actArr.append("]");

                    String json = String.format(Locale.US,
                        "{\"reqPerSecond\":%.2f,\"totalRequests\":%d,\"totalResponses\":%d," +
                        "\"pendingRequests\":%d,\"totalTransactions\":%d," +
                        "\"totalUsers\":%d,\"activeUsers\":%d,\"inactiveUsers\":%d," +
                        "\"pendingOrders\":%d,\"recentActivity\":%s}",
                        reqPerSecond, totalRequests.get(), totalResponses.get(),
                        pendingRequests.get(), totalTransactions.get(),
                        totalUsers, activeUsers, inactiveUsers,
                        pendingOrders, actArr.toString()
                    );
                    sendJson(ex, 200, json);
                    return;
                }

                // GET /api/admin/users
                if (path.endsWith("/users") && "GET".equalsIgnoreCase(method)) {
                    java.util.Set<String> activeIds = new java.util.HashSet<>();
                    for (Order o : engine.getAllOrders()) activeIds.add(o.traderId);

                    StringBuilder arr = new StringBuilder("[");
                    boolean first = true;
                    for (AuthManager.UserCredential cred : auth.getAllUsers()) {
                        if (!first) arr.append(",");
                        first = false;
                        UserProfile profile = um.getUser(cred.id);
                        double balance = profile != null ? profile.balance : 0.0;
                        boolean active = activeIds.contains(cred.id);
                        arr.append(String.format(Locale.US,
                            "{\"id\":\"%s\",\"username\":\"%s\",\"email\":\"%s\",\"fullName\":\"%s\",\"balance\":%.2f,\"active\":%b}",
                            cred.id, escapeJson(cred.username), escapeJson(cred.email), escapeJson(cred.fullName), balance, active
                        ));
                    }
                    arr.append("]");
                    sendJson(ex, 200, arr.toString());
                    return;
                }

                // GET /api/admin/orders
                if (path.endsWith("/orders") && "GET".equalsIgnoreCase(method)) {
                    StringBuilder arr = new StringBuilder("[");
                    boolean first = true;
                    for (Order o : engine.getAllOrders()) {
                        if (!first) arr.append(",");
                        first = false;
                        arr.append(formatOrderJson(o));
                    }
                    arr.append("]");
                    sendJson(ex, 200, arr.toString());
                    return;
                }

                // POST /api/admin/resume
                if (path.endsWith("/resume")) {
                    for (Stock s : exchange.getAllStocks()) s.resumeTrading();
                    sendJson(ex, 200, "{\"success\":true,\"message\":\"Trading resumed.\"}");
                    return;
                }

                sendJson(ex, 404, "{\"error\":\"Unknown admin endpoint\"}");
            } finally {
                finishMetrics();
            }
        }
    }

    // --- Static File Handler (Fallback) ---
    private class StaticFileHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange ex) throws IOException {
            String path = ex.getRequestURI().getPath();
            if (path.equals("/")) path = "/index.html";

            Path staticDir = Paths.get("src/main/resources/static");
            Path filePath = staticDir.resolve(path.substring(1)).normalize();

            if (Files.exists(filePath) && !Files.isDirectory(filePath)) {
                String contentType = "text/html";
                if (path.endsWith(".css")) contentType = "text/css";
                else if (path.endsWith(".js")) contentType = "application/javascript";
                else if (path.endsWith(".json")) contentType = "application/json";
                else if (path.endsWith(".svg")) contentType = "image/svg+xml";

                byte[] data = Files.readAllBytes(filePath);
                ex.getResponseHeaders().set("Content-Type", contentType);
                ex.sendResponseHeaders(200, data.length);
                try (OutputStream os = ex.getResponseBody()) {
                    os.write(data);
                }
            } else {
                ex.sendResponseHeaders(404, -1);
            }
        }
    }

    // --- Helpers & JSON formatters ---
    private String formatStockJson(Stock s) {
        double change = s.lastTradedPrice - s.openPrice;
        double growth = s.getGrowthPercentage();
        return String.format(Locale.US,
                "{\"ticker\":\"%s\",\"companyName\":\"%s\",\"tickSize\":%.2f,\"initialShares\":%d,\"tradingPaused\":%b," +
                "\"lastTradedPrice\":%.2f,\"openPrice\":%.2f,\"highPrice\":%.2f,\"lowPrice\":%.2f,\"volume\":%d," +
                "\"growth\":%.2f,\"change\":%.2f}",
                s.ticker, s.companyName, s.tickSize, s.initialShares, s.tradingPaused, s.lastTradedPrice,
                s.openPrice, s.highPrice, (s.lowPrice == Double.MAX_VALUE ? s.lastTradedPrice : s.lowPrice), s.volume,
                growth, change
        );
    }

    private String formatOrderBookJson(Stock s) {
        StringBuilder sb = new StringBuilder("{");
        sb.append("\"ticker\":\"").append(s.ticker).append("\",");
        sb.append("\"companyName\":\"").append(s.companyName).append("\",");
        sb.append("\"tradingPaused\":").append(s.tradingPaused).append(",");
        sb.append("\"lastPrice\":").append(s.lastTradedPrice).append(",");

        // Bids (buyers)
        sb.append("\"bids\":[");
        List<Map<String, Object>> bids = engine.orderBook.getBidLevels(s.ticker, 8);
        for (int i = 0; i < bids.size(); i++) {
            Map<String, Object> m = bids.get(i);
            sb.append(String.format(Locale.US, "{\"price\":%.2f,\"quantity\":%d,\"count\":%d}",
                    m.get("price"), m.get("quantity"), m.get("orderCount")));
            if (i < bids.size() - 1) sb.append(",");
        }
        sb.append("],");

        // Asks (sellers)
        sb.append("\"asks\":[");
        List<Map<String, Object>> asks = engine.orderBook.getAskLevels(s.ticker, 8);
        for (int i = 0; i < asks.size(); i++) {
            Map<String, Object> m = asks.get(i);
            sb.append(String.format(Locale.US, "{\"price\":%.2f,\"quantity\":%d,\"count\":%d}",
                    m.get("price"), m.get("quantity"), m.get("orderCount")));
            if (i < asks.size() - 1) sb.append(",");
        }
        sb.append("]}");
        return sb.toString();
    }

    private String formatTradeJson(TradeRecord t) {
        return String.format(Locale.US,
                "{\"tradeId\":\"%s\",\"ticker\":\"%s\",\"price\":%.2f,\"quantity\":%d,\"totalAmount\":%.2f," +
                "\"fee\":%.2f,\"buyerId\":\"%s\",\"sellerId\":\"%s\",\"timestamp\":%d}",
                t.tradeId, t.ticker, t.price, t.quantity, t.totalAmount, t.fee, t.buyTraderId, t.sellTraderId, t.timestamp
        );
    }

    private String formatOrderJson(Order o) {
        return String.format(Locale.US,
                "{\"id\":\"%s\",\"traderId\":\"%s\",\"ticker\":\"%s\",\"side\":\"%s\",\"type\":\"%s\"," +
                "\"price\":%.2f,\"initialQuantity\":%d,\"remainingQuantity\":%d,\"filledQuantity\":%d," +
                "\"status\":\"%s\",\"timestamp\":%d}",
                o.id, o.traderId, o.ticker, o.side.name(), o.type.name(),
                o.price, o.initialQuantity, o.quantity, o.getFilledQuantity(), o.status.name(), o.timestamp
        );
    }

    private void addCorsHeaders(HttpExchange ex) {
        ex.getResponseHeaders().set("Access-Control-Allow-Origin", "*");
        ex.getResponseHeaders().set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
        ex.getResponseHeaders().set("Access-Control-Allow-Headers", "Content-Type, Authorization, Accept, X-Requested-With, X-Admin-Key");
    }

    private void sendJson(HttpExchange ex, int code, String json) throws IOException {
        byte[] bytes = json.getBytes(StandardCharsets.UTF_8);
        ex.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
        ex.sendResponseHeaders(code, bytes.length);
        try (OutputStream os = ex.getResponseBody()) {
            os.write(bytes);
        }
    }

    private String readBody(HttpExchange ex) throws IOException {
        try (InputStream is = ex.getRequestBody()) {
            return new String(is.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    private Map<String, String> parseJsonSimple(String body) {
        Map<String, String> map = new HashMap<>();
        if (body == null || body.trim().isEmpty()) return map;

        String clean = body.trim();
        if (clean.startsWith("{")) clean = clean.substring(1);
        if (clean.endsWith("}")) clean = clean.substring(0, clean.length() - 1);

        String[] pairs = clean.split(",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)");
        for (String pair : pairs) {
            String[] kv = pair.split(":(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)");
            if (kv.length == 2) {
                String k = kv[0].trim().replaceAll("^\"|\"$", "");
                String v = kv[1].trim().replaceAll("^\"|\"$", "");
                map.put(k, v);
            }
        }
        return map;
    }

    private Map<String, String> parseQuery(String query) {
        Map<String, String> map = new HashMap<>();
        if (query == null || query.isEmpty()) return map;
        String[] pairs = query.split("&");
        for (String pair : pairs) {
            String[] kv = pair.split("=");
            if (kv.length == 2) {
                try {
                    map.put(URLDecoder.decode(kv[0], StandardCharsets.UTF_8),
                            URLDecoder.decode(kv[1], StandardCharsets.UTF_8));
                } catch (Exception ignored) {}
            }
        }
        return map;
    }

    private String escapeJson(String str) {
        if (str == null) return "";
        return str.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "");
    }
}
