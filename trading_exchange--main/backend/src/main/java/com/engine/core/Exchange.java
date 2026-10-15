package com.engine.core;

import com.engine.model.Stock;
import java.util.Collection;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class Exchange {
    private final Map<String, Stock> stocks = new ConcurrentHashMap<>();

    public double totalRevenue = 0.0;
    public final double FEE_RATE = 0.001; // 0.1%

    public void registerStock(String ticker, double tickSize) {
        stocks.put(ticker, new Stock(ticker, tickSize));
    }

    public void registerStock(String ticker, String companyName, double tickSize, int initialShares, double initialPrice) {
        stocks.put(ticker, new Stock(ticker, companyName, tickSize, initialShares, initialPrice));
    }

    public boolean isValidTicker(String ticker) {
        return ticker != null && stocks.containsKey(ticker.toUpperCase());
    }

    public Stock getStock(String ticker) {
        if (ticker == null) return null;
        return stocks.get(ticker.toUpperCase());
    }

    public Collection<Stock> getAllStocks() {
        return stocks.values();
    }

    public synchronized void collectFee(double feeAmount) {
        totalRevenue += feeAmount;
    }
}
