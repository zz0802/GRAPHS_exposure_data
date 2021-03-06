# Process calibration data from KHRC
#stack the calibration data and plot it
#created 24 Feb 2014
# modified 28 Nov 2014
require(plyr)
require(dplyr)
require(ggplot2)
require(lubridate)
require(scales)
library(lattice)

# functions
lascar.import <- function(x){
  dt <- read.csv(x, stringsAsFactors=F, header=T)[,c(2,3,4)]
  names(dt) <- c('datetime','co','SN')
  dt$datetime <- dmy_hms(dt$datetime, tz="GMT")
  dt$SN<-dt$SN[1]
  dt
}

## Previously calculated: through Jan 11, 2015
calib_factor_all <- read.csv("/Users/ashlinn/Dropbox/Ghana_exposure_data_SHARED (1)/CO_calibration_files/calib_factor_allJan13.csv", stringsAsFactors = FALSE)

# actually at least plotted them thru Feb 9, 2015...but not validated based on this

previous <- readRDS("/Users/ashlinn/Dropbox/Ghana_exposure_data_SHARED (1)/CO_calibration_files/Calibration Factors/Datasets/calib_factors_bymonth_Jan26.rds") # merged by SN, not interpolated

# New dates to do: 
# 17Jan15 second cali
# 28Jan2015_1 THROUGH _2 
# 30Jan2015_1 through _2 
# 31Jan2015 
# 02Feb2015_1 through _4
# 09Feb2015_1 through _2
# 27Jun2015_1 through _2
# 30Jun2015
# 17Nov2015

###### 
# Original runs -------
###############################################
#enter file to examine (calibration run)
###############################################
run <- "17Nov2015"   
###############################################
###############################################

path<-paste("/Users/ashlinn/Dropbox/Ghana_exposure_data_SHARED (1)/CO_calibration_files/", run, sep="")
path
files<-list.files(path,full.names=T, recursive = FALSE, include.dirs = FALSE)
length(files) # one run is max 12*3 = 36 files?

files <- files[which(regexpr("ogsheet", files) == -1)] # get rid of logsheets
length(files) # one run is max 12*3 = 36 files?

names(files)<-basename(files)
calib <- ldply(files,lascar.import)



#create lascar variable
lascar_pattern <- "(CU_CO_...|CU_C0_...|CO_USB_...|COL_USB_...|CU-CO_...|CU-C0_...|CO-USB_...|COL-USB_...)" #note requires that lascar values be entered as three digits
lascar_match<-regexpr(lascar_pattern, calib$.id)
calib$lascar<-regmatches(calib$.id, lascar_match)


ggplot(calib,aes(x=datetime,y=co,colour=lascar))+geom_line() + ggtitle(run)

# lattice plot to check individual plots
xyplot(co ~ datetime|lascar, data=calib, type='l')


# save plot
pdf(file = paste0("Calib_plot_", run, ".pdf"))
ggplot(calib,aes(x=datetime,y=co,colour=lascar))+geom_line() + ggtitle(run)
dev.off()

#check times - some of the lasars appear to be set to the wrong time.
meantime<-calib %.% group_by(lascar) %.% dplyr::summarise(datetime=mean(datetime),mean(co)) %.% arrange(desc(datetime))
meantime[,2] <- as.POSIXct(meantime[,2], origin="1970-01-01", tz='UTC')

meantime #table for inspection

################################################
# CHECK PLOT AND MEANTIME AND PROCEED VIA EYEBALL
#################################################

p <- meantime[meantime$datetime > as.POSIXct("2015-06-27 10:11", origin = "1970-1-1", tz = "GMT"),]
p[order(p$lascar),]

# ###############################################
# # drop any problem records and replot
# ###############################################
# 
# for Jan 28_1
calib_cleaned <- calib[calib$datetime > as.POSIXct("2015-01-28 10:30:00", origin = "1970-1-1", tz = "GMT"),]

# for Jan 28_2
calib_cleaned <- calib[calib$datetime > as.POSIXct("2015-01-28 14:00:00", origin = "1970-1-1", tz = "GMT"),]

# for Jan 30_1
calib_cleaned <- calib[calib$datetime > as.POSIXct("2015-01-30 12:35:00", origin = "1970-1-1", tz = "GMT"),]

calib_cleaned <- calib %.% filter(lascar!="CU_CO_154" & lascar!= "CU_CO_152") 
# Mar 3_1: 114,  
# Mar-3_2 112, 020 (there are two called 020). 
# Mar 11: 114, 126 
# Jul 5: 114. 
# Nov 28: 114. 
# Jun272015_1: 056
# Jun272015_2: 154, 152

#repeat this row to remove additonal units from the plot

# 
ggplot(calib_cleaned,aes(x=datetime,y=co,colour=lascar))+geom_line()

xyplot(co ~ datetime|lascar, data=calib_cleaned, type='l')

### if needed, get rid of weird spikes & replot (set the > & < values by eyeball)-----
calib_cleaned <- calib_cleaned %.% filter(co > 38 & co <55)

ggplot(calib_cleaned,aes(x=datetime,y=co,colour=lascar))+geom_line()+scale_x_datetime(breaks = date_breaks("min"), labels = date_format("%H:%M"))


####################################
# if no problems
###################################

calib_cleaned <- calib

####################################
### select the "middle" 5-10 minute section of the plateau by eyeball or by referring to times on logsheets-----
###################################

calib_cleaned$datetime[1]

# Times used:
# Feb 24: "2014-02-24 16:38" / "2014-02-24 16:42"
# Feb 27: "2014-02-27 16:29"/"2014-02-27 16:39"
# Mar 03_1: "2014-03-03 09:13" / "2014-03-03 09:23"
# Mar 03_2: "2014-03-03 10:40" / "2014-03-03 10:50"
# Mar 11: "2014-03-11 12:00" / 2014-03-11 12:10" (no logsheet)
# June 17: "2014-06-17 15:20"/ "2014-06-17 15:30"
# July 5: "2014-07-05 11:25" / "2014-07-05 11:35"
# July 7: "2014-07-07 09:34" / "2014-07-07 09:44"
# July 8: "2014-07-08 09:27" / "2014-07-08 09:37"
# Dec 01_1: "2014-12-01 08:33" / "2014-12-01-08:43"
# Dec 01_2: "2014-12-01 09:03" / "2014-12-01-09:13"
# Dec 02: "2014-12-02 10:20" / "2014-12-02 10:28"
# Dec 22: this session with 4 lascars doesn't look normal (3 recorded no CO, the one that recorded is very spiky)
# Jan 11: "2015-01-11 09:17" / "2015-01-11 09:25"
# Jan 17: "2015-01-17 08:40"/ "2015-01-17 08:48"
# Jan 28_1: "2015-01-28 10:42" / "2015-01-28 10:48"
# Jan 28_2: "2015-01-28 14:15" / "2015-01-28 14:16"
# Jan 30_1: "2015-01-30 12:50"/ "2015-01-30 12:52"
# Jan 30_2: "2015-01-30 13:54"/ "2015-01-30 14:00"
# Jan 31: "2015-01-31 12:16" / "2015-01-31 12:21"
# Feb 02_1: "2015-02-02 10:41"/ "2015-02-02 10:44"
# Feb 02_2: "2015-02-02 11:08"/ "2015-02-02 11:12"
# Feb 02_3: "2015-02-02 11:33"/ "2015-02-02 11:38"
# Feb 02_4: "2015-02-02 11:59"/ "2015-02-02 12:01"
# Feb 09_1: "2015-02-09 09:47"/ "2015-02-09 09:51"
# Feb 09_2: "2015-02-09 11:19"/ "2015-02-09 11:23"
# Jun27_1: "2015-06-27 10:13" / "2015-06-27 10:18"
# Jun27_2: "2015-06-27 14:45" / "2015-06-27 14:51"
# Jun30: "2015-06-30 11:15" / "2015-06-30 11:18"
# Nov 17: "2015-11-17 10:32" / "2015-11-17 10:37"


starttime <-"2015-11-17 10:32"
stoptime <- "2015-11-17 10:37"

calib_factor<- calib_cleaned %.% filter(datetime > ymd_hm(starttime, tz = "GMT") & datetime < ymd_hm(stoptime, tz = "GMT"))

ggplot(calib_factor,aes(x=datetime,y=co,colour=lascar))+geom_line()+scale_x_datetime(breaks = date_breaks("min"), labels = date_format("%H:%M"))

pdf(file = paste0("Calib_plot_trunc_", run, ".pdf"))
ggplot(calib_factor,aes(x=datetime,y=co,colour=lascar))+geom_line()+scale_x_datetime(breaks = date_breaks("min"), labels = date_format("%H:%M"))
dev.off()

# calculate the calibration factor
calib_factor <- calib_factor %.% group_by(lascar) %.% dplyr::summarise(co = mean(co), factor = round(co/50, digits = 3))


###################################################
### choose a date
###################################################
date <-  format(dmy(run, tz = "GMT"), format = "%Y%b%d") # for any dates with only one run
# date <- "2015Feb02_3" # For eg  March 03 and Dec 01 when there were 2 runs



#name columns and create a date-stamped data frame ----



names(calib_factor) <- c("lascar", paste0("co_", date), paste0("factor_", date))
calib_factor$lascar <- gsub("CU_C0", "CU_CO", calib_factor$lascar)

assign(paste0("calib_factor_", date),calib_factor)


#####################################
# After doing each folder of calibrations separately, merge the data frames--------
####################################


########################
# If doing them for the first time, without loading a calib_factor_all file
# calib_factor_all <- join_all(list(calib_factor_Feb24, calib_factor_Feb27, calib_factor_Mar03_1, calib_factor_Mar03_2, calib_factor_Mar11, calib_factor_Jun17, calib_factor_Jul05, calib_factor_Jul07, calib_factor_Jul08, calib_factor_Nov28, calib_factor_Dec01_1, calib_factor_Dec01_2), by = "lascar", type = "full")
########################


#######################   START HERE IF ADDING TO A PREVIOUSLY ESTABLISHED FILE --------
# If adding to a previously established file
########################

calib_factor_all <- read.csv("/Users/ashlinn/Dropbox/Ghana_exposure_data_SHARED (1)/CO_calibration_files/calib_factor_allJan13.csv", stringsAsFactors = FALSE)

calib_factor_all <- join_all(list(calib_factor_all, calib_factor_2015Jan17, calib_factor_2015Jan28_1, calib_factor_2015Jan28_2, calib_factor_2015Jan30_1, calib_factor_2015Jan30_2, calib_factor_2015Jan31, calib_factor_2015Feb02_1, calib_factor_2015Feb02_2, calib_factor_2015Feb02_3, calib_factor_2015Feb02_4, calib_factor_2015Feb09_1, calib_factor_2015Feb09_2, calib_factor_2015Jun27_1, calib_factor_2015Jun27_2, calib_factor_2015Jun30), by = "lascar", type = "full")



########################

calib_factor_all$lascar <- gsub("CU_C0", "CU_CO", calib_factor_all$lascar)
calib_factor_all <- calib_factor_all[order(calib_factor_all$lascar),]


write.csv(calib_factor_all, file = paste0("calib_factor_all", format(Sys.Date(), format = "%b%d"), ".csv"), row.names = FALSE)

# stopped here Oct 6

### split out the calibration factors
calib_factor_all <- read.csv("/Users/ashlinn/Dropbox/Ghana project/BP project/Baseline BP Paper/Ghana BP R Materials/calib_factor_allOct06.csv")
factor_variables <- regmatches(names(calib_factor_all), regexpr("factor_.*", names(calib_factor_all)))

calib_factors <- calib_factor_all[,colnames(calib_factor_all) %in% c("lascar", factor_variables)]
calib_factors$mean <- NA
calib_factors$sd <- NA
calib_factors$calibrations <- NA
calib_factors$mean_excl_0 <- NA

calib_factors$mean <- rowMeans(calib_factors[,2:(ncol(calib_factors)-4)], na.rm = TRUE)
calib_factors$calibrations <- rowSums(!is.na(calib_factors[,2:(ncol(calib_factors)-4)]))

for (i in 1:nrow(calib_factors)) {
calib_factors$sd[i] <- sd(calib_factors[i,2:(ncol(calib_factors)-4)], na.rm = TRUE)
}

for (i in 1:nrow(calib_factors)) {
  tempdata <- as.numeric(calib_factors[i, 2:(ncol(calib_factors) - 4)])
  tempdata <- tempdata[!tempdata == 0]
  calib_factors$mean_excl_0[i] <- mean(tempdata, na.rm = TRUE)
  }


calib_factors_ordered <- calib_factors[order(calib_factors$lascar),]


## Add SNs to calib_factors_ordered
#### DO this if need to generate new SNs, otherwise skip
# Need to start with a  CO_stacked files file.

files <- list.files("/Users/ashlinn/Dropbox/Ghana_exposure_data_SHARED (1)/CO_files_processed/12Dec2014/CO_stacked files/")
length(files)

SN_data <- as.data.frame(files)
SN_data$SN <- regmatches(SN_data[,1], regexpr("_\\d+\\.", SN_data[,1]))
SN_data$SN <- substr(SN_data$SN, 2, nchar(SN_data$SN)-1)

lascar_pattern <- "(CO.USB....|COL.USB....|CU.CO....)"
SN_data$lascar <- regmatches(SN_data$files, regexpr(lascar_pattern, SN_data$files))
SN_data$lascar <- ifelse(substr(SN_data$lascar, start = nchar(SN_data$lascar), stop = nchar(SN_data$lascar)) == "_", substr(SN_data$lascar, 1, nchar(SN_data$lascar)-1),SN_data$lascar)

#208 files, 171 unique SNs, 206 unique lascars....
test_table <- data.frame(SN = unique(SN_data$SN))
for (i in 1:nrow(test_table)) {
  test_table$no_lascars[i] <- length(SN_data$lascar[SN_data$SN == test_table$SN[i]])
}
test_table$lascar1 <- NA
test_table$lascar2 <- NA
test_table$lascar3 <- NA
for (i in 1:nrow(test_table)) {
  test_table$lascar1[i] <- SN_data$lascar[SN_data$SN == test_table$SN[i]][1]
  test_table$lascar2[i] <- SN_data$lascar[SN_data$SN == test_table$SN[i]][2]
  test_table$lascar3[i] <- SN_data$lascar[SN_data$SN == test_table$SN[i]][3]
}

Lascar_SN_to_ID <- test_table
write.csv(Lascar_SN_to_ID, file = "Lascar_SN_to_ID.csv", row.names = FALSE)

######### skip to here

Lascar_SN_to_ID <- read.csv("/Users/ashlinn/Dropbox/Ghana_exposure_data_SHARED (1)/CO_calibration_files/Lascar_SN_to_ID.csv", stringsAsFactors = FALSE)

test <- calib_factors_ordered
test$SN <- NA
for (i in 1:nrow(test)) {
  test$SN[i] <- ifelse(test$lascar[i] %in% Lascar_SN_to_ID$lascar1, as.character(Lascar_SN_to_ID$SN[Lascar_SN_to_ID$lascar1 == test$lascar[i]]), test$SN[i])
  test$SN[i] <- ifelse(is.na(test$SN[i]) & test$lascar[i] %in% Lascar_SN_to_ID$lascar2, as.character(Lascar_SN_to_ID$SN[Lascar_SN_to_ID$lascar2 == test$lascar[i] & !is.na(Lascar_SN_to_ID$lascar2)]), test$SN[i])
  test$SN[i] <- ifelse(is.na(test$SN[i]) & test$lascar[i] %in% Lascar_SN_to_ID$lascar3, as.character(Lascar_SN_to_ID$SN[Lascar_SN_to_ID$lascar3 == test$lascar[i] & !is.na(Lascar_SN_to_ID$lascar3)]), test$SN[i])
}

names(test)[2:14] <- paste0("2014", substr(names(test)[2:14],8,12))
calib_factors_ordered <- test

write.csv(calib_factors_ordered, file = paste0("calib_factors_ordered_", format(Sys.Date(), format = "%b%d"), ".csv"), row.names = FALSE)

calib_factors_ordered <- read.csv("/Users/ashlinn/Dropbox/Ghana project/BP project/Baseline BP Paper/Ghana BP R Materials/calib_factors_ordered_Dec19.csv", stringsAsFactors = FALSE)


# Merge by SN:
calib_long <- melt(calib_factors_ordered[,c(1:14, 19)], id.vars  = c("SN", "lascar"))

######################
# Plots ----------
######################

# Plots: each lascar's calibration factors

calib_long <- arrange(calib_long, SN)
pdf(file = paste0("Lascar_Calibrations_Each_", format(Sys.Date(), format = "%b%d"), ".pdf"), width = 10, height = 7)
par(mfrow = c(3,4))
for (i in 1:length(unique(calib_long$SN))) {
  p <- plot(calib_long$variable[calib_long$SN == unique(calib_long$SN)[i]], calib_long$value[calib_long$SN == unique(calib_long$SN)[i]], ylim = c(0,2), xaxt= "n", ylab = "Calibration Factor", main = paste0("SN =", unique(calib_long$SN)[i], "\n", paste(unique(calib_long$lascar[calib_long$SN == unique(calib_long$SN)[i]]), collapse = " / ")), cex.main = 0.95)
  axis(1, at = unique(calib_long$variable), labels= substr(unique(calib_long$variable), 2,length(calib_long$variable)), las = 2, cex.axis = 0.7)
  text(x = unique(calib_long$variable), y = p$stats[1,]+0.15, labels = round(p$stats[1,],digits = 2), cex = 0.75)
}
dev.off()

# All calibration sessions: with calib_long using plot

# how many calibs per session
dates <- data.frame(session = unique(calib_long$variable))
for (i in 1:nrow(dates)) {
dates$lascars[i] <- sum(!is.na(calib_long$value[calib_long$variable == dates$session[i]]))
}

pdf(file = paste0("Lascar_Calibrations_All_", format(Sys.Date(), format = "%b%d"), ".pdf"))
plot(calib_long$variable, calib_long$value, xaxt = "n", ylab = "Calibration Factor", main = paste("Calibrations of", length(unique(calib_long$SN)), "Lascars"))
axis(1, at = unique(calib_long$variable), labels= substr(unique(calib_long$variable), 2,length(calib_long$variable)), las = 2, cex.axis = 0.7)
text(x = unique(calib_long$variable), y = 1.75, labels= paste0("n=\n",dates$lascars), cex = 0.8)
dev.off()


#############
### Calibration factors by interpolation ----------
#############


data <- calib_long
# new Jan 25

# calculate mean
mean(calib_long$value[!is.na(calib_long$value)]) # 0.76
mean(calib_long$value[calib_long$value >= 0.6 & calib_long$value <= 1.2 & !is.na(calib_long$value)]) # 0.85


# calculate monthly averages
monthlycfs <- data.frame()
for (i in 1:length(unique(calib_long$SN))) {
  data <- calib_long[calib_long$SN == unique(calib_long$SN)[i],]
  data$variable <- as.character(substr(data$variable, 2, nchar(as.character(data$variable))))
  data$variable <- gsub("\\..*", "", data$variable)
  data$monthyear <- paste(months(ymd(data$variable)), year(ymd(data$variable)), sep = "_")
  d <-dcast(data, monthyear~value, fun.aggregate = mean)
  d$cf <- NA
  if (colnames(d)[2] != "NA") d$cf <- rowMeans(d[,2:(ncol(d) - 1)], na.rm = TRUE)
  d$SN <- unique(data$SN)
  d$lascar <- data$lascar[1]
  d <- d[,c("monthyear", "SN", "lascar", "cf")]
  t <-as.data.frame(t(d[,c(1,4)]), stringsAsFactors = FALSE)
  colnames(t) <- t[1,]
  t <- t[-1,]
  t$SN <- unique(d$SN)
  t$lascar <- d$lascar[1]
  row.names(t) <- NULL
  monthlycfs <- rbind(monthlycfs, t)
}

# set up a new data frame for the monthly averaged CFs
cf <- data.frame(SN = monthlycfs$SN, lascar = monthlycfs$lascar)
cf[,3:22] <- NA
colnames(cf)[3:5] <- paste0(c("October", "November", "December"), "_2013")
colnames(cf)[6:17] <- paste0(c("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"), "_2014")
colnames(cf)[18:22] <- paste0(c("January", "February", "March", "April", "May"), "_2015")


cfs <- merge(cf, monthlycfs, all.y = TRUE)
cfs <- cfs[,c(1:2, 9:12, 3:4, 13:14, 5:6,15:17,7:8,18:22)]
saveRDS(cfs, file = paste0("calib_factors_bymonth_", format(Sys.Date(), format = "%b%d"), ".rds")) # monthly averaged CFs (not interpolated)


#### INTERPOLATE -------
cfs <- readRDS("/Users/ashlinn/Dropbox/Ghana project/BP project/Baseline BP Paper/Ghana BP R Materials/calib_factors_bymonth_Jan26.rds")
cf_new <- cfs
cf_new[,23:42] <- NA
conf_names <- paste0(names(cf_new[,3:22]), "_conf")
for (i in 23:42) { colnames(cf_new)[i] <- conf_names[i-22] }

# plot:
pdf(file = paste0("Calib_factors_bymonth_interp_", format(Sys.Date(), format = "%b%d"), ".pdf"), height = 10, width = 10)
par(mfrow = c(3,3))
for (i in 1:nrow(cfs)) {
  xax <- 1:(ncol(cfs) - 2)
  yax <- cfs[i, 3:ncol(cfs)]
 
  #### assigning initial values as the initial measured value
  yax[1] <- cfs[i,which(!is.na(cfs[i,3:22]))[1]+2]
  
  
  plot(xax,yax, pch = 16, col = "red",ylim = c(0,2), main = paste0(cfs$SN[i], " \n", cfs$lascar[i]), ylab = "Calibration Factor", xlab = "", xaxt = "n", cex.main = 0.95)
  
  #### interpolate
  values <- which(!is.na(yax))
  whichzero <- which(as.numeric(yax) < 0.2)[1] #  a "zero" CF is defined as < 0.2
 interp <- approx(xax, yax, n = length(xax), xout = xax, rule = 2) # linear interpolation (rule = 2 sets constant interpolation outside the measured range)
  interp2 <- approx(xax, yax, xout = xax, method = "constant", rule = 2) # constant interpolation
 if (!is.na(whichzero) & whichzero !=1) interp_complete <- append(interp$y[1: max(values[values< whichzero])], interp2$y[(max(values[values < whichzero])+1):length(interp2$y)]) # linearly interpolate until last measured value before a "zero", then use constant interpolation
 if (is.na(whichzero)) interp_complete <- interp$y # if no "zero", linearly interpolate across the whole range (constant interpolation after last measured point)
 if (whichzero == 1 & !is.na(whichzero)) interp_complete <- interp2$y

 # set colors according to CF confidence
 allpoints <- as.data.frame(interp_complete)
 allpoints$colors <- NA

 # generally set colors within the "good" range as green and those outside as coral
 allpoints$colors<- ifelse(allpoints$interp_complete > 1.2 | allpoints$interp_complete < 0.6, "coral", "lightgreen")
 # apply coral color and lo confidence to values after a measured value and before a zero
 if (!is.na(whichzero) & whichzero !=1) allpoints$colors[(max(values[values < whichzero])+1):whichzero] <- "coral"
     
 # apply coral color and lo confidence to entire set of data if there are no 2 adjacent valid measured CFs (including the virtual one as a measured value)
 measured <- as.numeric(yax[!is.na(yax)])
 v <- NULL
 for (j in 1:length(measured) - 1) {
   v <- append(v, measured[j] >= 0.6 & measured[j+1] >= 0.6 & measured[j] <=1.2 & measured[j+1] <=1.2)
 }
 if(sum(v) == 0) allpoints$colors <- "coral"
 
# apply grey color and no confidence to any points with CF < 0.2
 allpoints$colors <- ifelse(allpoints$interp_complete < 0.2, "grey", allpoints$colors)

 points(xax, allpoints$interp_complete, pch = 16, col = allpoints$colors)
 
 # map colors to confidence levels
 allpoints$conf <- mapvalues(allpoints$colors, from = c("lightgreen", "coral", "grey"), to = c("hi", "lo", "none"), warn_missing = FALSE)
 

 
  ### add back in the actual measured monthly averages in black
  points(xax[2:length(xax)], yax[2:length(yax)], pch = 16, col = "black")

  ### make the first (virtual) point red and add lines at 0.6 and 1.2
  points(xax[1], yax[1], pch = 16, col = "red")
  abline(h=0.6, lty = "dotted", col = "darkgrey")
  abline(h = 1.2, lty = "dotted", col = "darkgrey")
  


 ### add x axis and legend
  xlabels <-names(cfs)[3:ncol(cfs)]
  axis(side = 1, at = xax, labels = paste0(substr(xlabels, 1,3), substr(xlabels, nchar(xlabels)-4, nchar(xlabels))), las = 2, cex.axis = 0.9)

  legend("top", c("virtual", "measured", "hi conf", "lo conf", "no conf"), xpd = TRUE, horiz = TRUE, inset = c(0,0), bty = "n", pch = 16, col = c("red", "black", "lightgreen", "coral", "grey"), cex = 0.8, x.intersp = 0.5)

  ### add interpolated values to cf_new
 cf_new[i, 3:22] <- round(allpoints$interp_complete, digits = 3)
 cf_new[i, 23:42] <- allpoints$conf
}
dev.off()


## save the interpolated CF factors 
saveRDS(cf_new, file = paste0("calib_factors_bymonth_interp_", format(Sys.Date(), format = "%b%d"), ".rds"))









