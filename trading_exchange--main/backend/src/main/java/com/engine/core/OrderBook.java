package com.engine.core;

import com.engine.model.Enums.OrderSide;
import com.engine.model.Enums.OrderType;
import com.engine.model.Order;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

public class OrderBook {
    private final Map<String, TreeMap<Double, PriceLevel>> bidsByTicker = new ConcurrentHashMap<>();
    private final Map<String, TreeMap<Double, PriceLevel>> asksByTicker = new ConcurrentHashMap<>();

    public synchronized TreeMap<Double, PriceLevel> getBids(String ticker) {
        String key = ticker != null ? ticker.toUpperCase() : "DEFAULT";
        return bidsByTicker.computeIfAbsent(key, k -> new TreeMap<>(Collections.reverseOrder()));
    }

    public synchronized TreeMap<Double, PriceLevel> getAsks(String ticker) {
        String key = ticker != null ? ticker.toUpperCase() : "DEFAULT";
        return asksByTicker.computeIfAbsent(key, k -> new TreeMap<>());
    }

    public synchronized void addOrder(Order order) {
        if (order == null || order.ticker == null) return;
        TreeMap<Double, PriceLevel> side = (order.side == OrderSide.BUY)
                ? getBids(order.ticker)
                : getAsks(order.ticker);
        side.putIfAbsent(order.price, new PriceLevel(order.price));
        side.get(order.price).addOrder(order);
        System.out.println("Added to book: " + order);
    }

    public synchronized boolean cancelOrder(String orderId) {
        for (TreeMap<Double, PriceLevel> map : bidsByTicker.values()) {
            for (PriceLevel pl : map.values()) {
                if (pl.queue.remove(orderId)) {
                    recalculateTotal(pl);
                    cleanupEmptyLevels(map);
                    return true;
                }
            }
        }
        for (TreeMap<Double, PriceLevel> map : asksByTicker.values()) {
            for (PriceLevel pl : map.values()) {
                if (pl.queue.remove(orderId)) {
                    recalculateTotal(pl);
                    cleanupEmptyLevels(map);
                    return true;
                }
            }
        }
        return false;
    }

    private void recalculateTotal(PriceLevel pl) {
        int sum = 0;
        for (Order o : pl.queue.toList()) {
            sum += o.quantity;
        }
        pl.totalQuantity = sum;
    }

    private void cleanupEmptyLevels(TreeMap<Double, PriceLevel> map) {
        map.entrySet().removeIf(e -> e.getValue().isEmpty() || e.getValue().totalQuantity <= 0);
    }

    public synchronized int availableQuantity(Order incoming) {
        if (incoming == null || incoming.ticker == null) return 0;
        TreeMap<Double, PriceLevel> opposite = (incoming.side == OrderSide.BUY)
                ? getAsks(incoming.ticker)
                : getBids(incoming.ticker);
        boolean isMarket = (incoming.type == OrderType.MARKET_FOK || incoming.type == OrderType.MARKET);
        int total = 0;

        for (Map.Entry<Double, PriceLevel> entry : opposite.entrySet()) {
            double lvlPrice = entry.getKey();
            if (!isMarket) {
                boolean ok = (incoming.side == OrderSide.BUY)
                        ? lvlPrice <= incoming.price
                        : lvlPrice >= incoming.price;
                if (!ok) break;
            }
            for (Order r : entry.getValue().queue.toList()) {
                if (!r.traderId.equals(incoming.traderId) && r.ticker.equalsIgnoreCase(incoming.ticker)) {
                    total += r.quantity;
                }
            }
            if (total >= incoming.quantity) return total;
        }
        return total;
    }

    public synchronized List<Map<String, Object>> getBidLevels(String ticker, int limit) {
        List<Map<String, Object>> list = new ArrayList<>();
        TreeMap<Double, PriceLevel> bids = getBids(ticker);
        int count = 0;
        for (Map.Entry<Double, PriceLevel> e : bids.entrySet()) {
            if (e.getValue().totalQuantity > 0) {
                Map<String, Object> m = new HashMap<>();
                m.put("price", e.getKey());
                m.put("quantity", e.getValue().totalQuantity);
                m.put("orderCount", e.getValue().queue.getSize());
                list.add(m);
                count++;
                if (count >= limit) break;
            }
        }
        return list;
    }

    public synchronized List<Map<String, Object>> getAskLevels(String ticker, int limit) {
        List<Map<String, Object>> list = new ArrayList<>();
        TreeMap<Double, PriceLevel> asks = getAsks(ticker);
        int count = 0;
        for (Map.Entry<Double, PriceLevel> e : asks.entrySet()) {
            if (e.getValue().totalQuantity > 0) {
                Map<String, Object> m = new HashMap<>();
                m.put("price", e.getKey());
                m.put("quantity", e.getValue().totalQuantity);
                m.put("orderCount", e.getValue().queue.getSize());
                list.add(m);
                count++;
                if (count >= limit) break;
            }
        }
        return list;
    }
}
