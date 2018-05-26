#!/usr/bin/env Rscript

# Plot histograms of real-world price data and report empirical frequencies

d.eur <- scan("rewe_data",what=numeric())
d.usd <- scan("stopnshop_data",what=numeric())

png("supermarket_change_stats_de.png",width=800,height=240)
hist(d.eur,freq=F,col='grey',border='grey',breaks=20,xlab="Amount (¢)",main="Supermarket price data (Germany)")
dev.off()

png("supermarket_change_stats_us.png",width=800,height=240)
hist(d.usd,freq=F,col='grey',border='grey',breaks=20,xlab="Amount (¢)",main="Supermarket price data (US)")
dev.off()
