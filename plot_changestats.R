#!/usr/bin/env Rscript

library(ggplot2)
# Generate plots from changestats tables
# Skip currencies that lack 1 cent pieces

currencies <- c('EUR','USD','JPY','GBP')

#Amt Comb Avg Bestcount_count Bestcount_number Bestcount_wt Bestwt Bestwt_count Bestwt_number Curr
changestats <- data.frame()
for (i in 1:length(currencies)) {
  d <- read.table(paste(c("changestats/changestats_100_",currencies[i],".tsv"),sep="",collapse=""),header=TRUE,sep="\t")
  dd <- data.frame(d,Curr=currencies[i])
  changestats <- rbind(changestats,dd)
}

png("currency_comparison_changestats_counts.png",height=300,width=1200)
ggplot(changestats,aes(x=Amt)) + geom_line(aes(y=Bestwt_count, color="lowest weight count"))  + geom_line(aes(y=Bestcount_count, color="fewest coins")) + facet_wrap(~Curr,nrow=1) + labs(x='Amount to change (¢)',y='Number of coins')
dev.off()

png("currency_comparison_changestats_weights.png",height=300,width=1200)
ggplot(changestats,aes(x=Amt)) + geom_line(aes(y=Bestwt, color="lowest weight")) + geom_line(aes(y=Bestcount_wt, color="fewest coin weight")) + facet_wrap(~Curr,nrow=1) + labs(x='Amount to change (¢)',y='Weight (g)')
dev.off()
