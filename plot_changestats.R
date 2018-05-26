#!/usr/bin/env Rscript

library(ggplot2)
# Generate plots from changestats tables
# Skip currencies that lack 1 cent pieces

currencies <- c('EUR','USD','JPY','GBP')

#Amt Comb Avg Bestcount_count Bestcount_number Bestcount_wt Bestwt Bestwt_count Bestwt_number Curr Greedy_count
changestats <- data.frame()
for (i in 1:length(currencies)) {
  d <- read.table(paste(c("changestats/changestats_100_",currencies[i],".tsv"),sep="",collapse=""),header=TRUE,sep="\t")
  dd <- data.frame(d,Curr=currencies[i])
  changestats <- rbind(changestats,dd)
}

png("currency_comparison_changestats_optimal_counts.png",height=600,width=1200)
ggplot(changestats,aes(x=Amt)) + geom_line(aes(y=Bestcount_count, color="fewest coins")) + facet_wrap(~Curr,nrow=2) + labs(x='Amount to change (¢)',y='Number of coins')
dev.off()

png("currency_comparison_changestats_counts.png",height=600,width=1200)
ggplot(changestats,aes(x=Amt)) + geom_line(aes(y=Bestwt_count, color="lowest weight count"))  + geom_line(aes(y=Bestcount_count, color="fewest coins")) + facet_wrap(~Curr,nrow=2) + labs(x='Amount to change (¢)',y='Number of coins')
dev.off()

png("currency_comparison_changestats_weights.png",height=600,width=1200)
ggplot(changestats,aes(x=Amt)) + geom_line(aes(y=Bestwt, color="lowest weight")) + geom_line(aes(y=Bestcount_wt, color="fewest coin weight")) + facet_wrap(~Curr,nrow=2) + labs(x='Amount to change (¢)',y='Weight (g)')
dev.off()

png("currency_comparison_changestats_greedy.png",height=600,width=1200)
ggplot(changestats,aes(x=Amt)) + geom_line(aes(y=Greedy_count, color="greedy count"))  + geom_line(aes(y=Bestcount_count, color="fewest coins")) + facet_wrap(~Curr,nrow=2) + labs(x='Amount to change (¢)',y='Number of coins')
dev.off()

# Plot greedy vs optimal for LSD
d.lsd <- read.table("changestats/changestats_100_LSD_part.tsv",header=TRUE,sep="\t")

png("currency_comparison_changestats_LSD_greedy.png",height=300,width=1200)
ggplot(d.lsd,aes(x=Amt)) + geom_line(aes(y=Greedy_count, color="greedy count"))  + geom_line(aes(y=Bestcount_count, color="fewest coins")) + labs(x='Amount to change (¢)',y='Number of coins')
dev.off()

# Plot weights of different currency denominations
d.curr <- read.table("currency_data.tsv",sep="\t",header=F)
names(d.curr) <- c("Currency","Value","Weight")
d.curr.sub <- subset(d.curr,d.curr$Currency != 'LSD_part')
png("currency_weights_comparison.png",height=400,width=1200)
ggplot(d.curr.sub,aes(x=Value,y=Weight)) + geom_line(aes(col=Currency)) + scale_x_log10() + facet_wrap(~Currency,nrow=2) + labs(x='Value',y='Weight (g)')
dev.off()
