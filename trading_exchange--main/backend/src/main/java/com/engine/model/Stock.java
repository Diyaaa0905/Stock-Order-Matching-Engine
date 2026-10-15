package com.engine.model;

import com.engine.core.CircuitBreaker;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class Stock {
    public final String ticker;
    public final String companyName;
    public final double tickSize;
    public final int initialShares;
    public volatile boolean tradingPaused;

    public double lastTradedPrice = 0.0;
    public double openPrice = 0.0;
    public double highPrice = 0.0;
    public double lowPrice = Double.MAX_VALUE;
    public int volume = 0;

    public final CircuitBreaker circuitBreaker;

    public Stock(String ticker, double tickSize) {
        this(ticker, ticker, tickSize, 100, 100.0);
    }

    public Stock(String ticker, String companyName, double tickSize, int initialShares, double initialPrice) {
        this.ticker = ticker;
        this.companyName = companyName != null ? companyName : ticker;
        this.tickSize = tickSize;
        this.initialShares = initialShares;
        this.tradingPaused = false;
        this.circuitBreaker = new CircuitBreaker(10.0);
        this.openPrice = initialPrice;
        this.lastTradedPrice = initialPrice;
        this.highPrice = initialPrice;
        this.lowPrice = initialPrice;
        this.volume = initialShares;
    }

    public synchronized void updateMarketStats(double price, int qty) {
        if (openPrice == 0.0) openPrice = price;

        lastTradedPrice = price;
        highPrice = Math.max(highPrice, price);
        lowPrice = Math.min(lowPrice, price);
        volume += qty;
    }

    public void pauseTrading() {
        tradingPaused = true;
    }

    public void resumeTrading() {
        tradingPaused = false;
        circuitBreaker.reset();
    }

    public double getGrowthPercentage() {
        if (openPrice <= 0.0) return 0.0;
        return ((lastTradedPrice - openPrice) / openPrice) * 100.0;
    }

    /**
     * Generates realistic historical chart data points for specified timeframe.
     * Timeframes: 1D, 1M, 1Y, ALL
     */
    public List<ChartPoint> generateChartData(String timeframe) {
        List<ChartPoint> points = new ArrayList<>();
        int count = 24;
        long stepMillis = 60 * 60 * 1000L; // 1 hour for 1D
        double volatility = 0.008;

        if ("1M".equalsIgnoreCase(timeframe)) {
            count = 30;
            stepMillis = 24L * 60 * 60 * 1000L; // 1 day
            volatility = 0.015;
        } else if ("1Y".equalsIgnoreCase(timeframe)) {
            count = 52;
            stepMillis = 7L * 24 * 60 * 60 * 1000L; // 1 week
            volatility = 0.025;
        } else if ("ALL".equalsIgnoreCase(timeframe)) {
            count = 60;
            stepMillis = 30L * 24 * 60 * 60 * 1000L; // 1 month
            volatility = 0.035;
        }

        long now = System.currentTimeMillis();
        long startTime = now - (count * stepMillis);
        Random rng = new Random(ticker.hashCode() + timeframe.hashCode());

        double price = openPrice > 0 ? openPrice : 100.0;
        // Start back in time with some variance
        double basePrice = price * (1.0 - (rng.nextDouble() * 0.1 - 0.05));

        for (int i = 0; i < count; i++) {
            long t = startTime + (i * stepMillis);
            double delta = (rng.nextDouble() - 0.48) * volatility * basePrice;
            basePrice = Math.max(basePrice * 0.5, basePrice + delta);
            if (i == count - 1) {
                basePrice = lastTradedPrice; // latest point is current price
            }
            int vol = 10 + rng.nextInt(500);
            points.add(new ChartPoint(t, Math.round(basePrice * 100.0) / 100.0, vol));
        }
        return points;
    }

    public static class ChartPoint {
        public final long timestamp;
        public final double price;
        public final int volume;

        public ChartPoint(long timestamp, double price, int volume) {
            this.timestamp = timestamp;
            this.price = price;
            this.volume = volume;
        }
    }
}
