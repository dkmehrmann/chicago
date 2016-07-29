library(httr)
library(reshape2)
library(ggplot2)

get_ca_name <- function(ca_num){
  url <- sprintf("http://crime.chicagotribune.com/api/1.0-beta1/datesummary/?format=json&limit=0&year=2013&community_area=%d&related=1", ca_num)
  r <- GET(url)
  return(content(r, 'parsed')[[1]]$community_area$name)
}
ca_names = c()
for (i in 1:77){
  name = get_ca_name(i)
  ca_names[name] <- i
}
saveRDS(ca_names, file='data/ca_names.RDS')



census <- read.csv('data/census.csv')
tot <- census[census$GROUP=='Total', ]
tot <- tot[ , c(2,351:367)]
tot <- rbind(tot[1, ], tot[grepl(tot$NAME, pattern="^[A-Z]{2} [0-9]{2}$"), ])
tot[ ,-1] <- tot[ ,-1]/rowSums(tot[ ,-1], na.rm=T)
tot$NAME <- c("US Avg.", names(sort(ca_names)))
tot <- melt(tot)
saveRDS(tot, file='data/totals.RDS')



