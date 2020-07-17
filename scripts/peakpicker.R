option_list = list(
  optparse::make_option(c("-f", "--file"), type="character", default=NULL, 
                        help="dataset file name", metavar="character"),
  optparse::make_option(c("-o", "--out"), type="character", default="out.txt", 
                        help="output file name [default= %default]", metavar="character"),
  optparse::make_option(c("-v", "--verbose"), type="logical", default=FALSE, 
                        help="include a pdf-figure showing the peak picking (with the same name as output file) [default= %default]", metavar="logical")
) 

opt_parser = optparse::OptionParser(option_list=option_list);
opt = optparse::parse_args(opt_parser)

# include a figure name 
opt$figure <- paste(strsplit(opt$out,'.txt')[[1]],'.pdf',sep = '')

if (is.null(opt$file)){
  print_help(opt_parser)
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
}


# ## read in arguments from the command line  
# args = commandArgs(trailingOnly=TRUE)
# 
# # test if there is at least one argument: if not, return an error
# if (length(args)==0) {
#   stop("At least one argument must be supplied (input file).n", call.=FALSE)
# } 
# 
# # get filename
# flnm <- rev(strsplit(args[1],'/')[[1]])
# flnm <- flnm[1]
# 
# if (length(args)==1) {
#   # default output file
#   peaklib <- 'peaks'
#   args[2] = paste(peaklib, '/peaklist_', flnm,sep = '')
# }
# 

# the function
findPeaks <- function(x,npt = 2*round(sqrt(dim(x)[1])/2)*2 + 1){
  # predict local smooth model
  x$ysmooth <- predict(loess(x[,c('V1','V2')],span=0.03))
  # find peaks at 1.derivative == 0
  x$yder1 <- signal::sgolayfilt(x$V1,m=1,n = npt,p = 3)
  x$id1 <- x$yder1>0
  x$id1[-1] <- (x$id1[-1] - x$id1[-length(x$id1)])==-1
  # make sure it is a peak by find peaks at 2.derivative < 0
  x$yder2 <- signal::sgolayfilt(x$V1,m=2,n = npt,p = 3)
  # get moving box-car to find local average
  x$yder0 <- signal::sgolayfilt(x$V1,m=0,n = 4*npt+1,p = 0)
  
  # get local noise level 
  x$is.peak_yhat <- x$id1==T & x$yder2<0 & x$V1>x$yder0
  
  x$inter <- rep(0,dim(x)[1])
  # for each peak - approximate by gauss and set a region around it. 
  # to find sd, use approximation and find bounds with height = 0.5*max height
  id_peak <- which(x$is.peak_yhat)
  H <- rank(x$ysmooth[id_peak])
  for (j in order(H,decreasing = T)){
    
    i <- id_peak[j]
    #print(x$ysmooth[i])
    
    idw <- which(x$ysmooth/x$ysmooth[i]>0.8 & x$ysmooth>1.005)
    # get start and endpoint of each interval 
    brkpts <- which(idw[-1] - idw[-length(idw)]>1)
    intervals <- data.frame(stspts = idw[c(1,brkpts+1)], endpts = idw[c(brkpts,length(idw))])
    intervals[,1]<-intervals[,1]-0.01 ## Make sure it works in case of peaks of length 0 and 1, like: 160 160, or 168 169
    intervals[,2]<-intervals[,2]+0.01
    #print("====interv==="); print(intervals)
    #print("====rs===");print(i); print(rowSums(sign(intervals - i)))
    int <- intervals[rowSums(sign(intervals - i))==0,]
    #print("===int===");print(int);print("=======")
    idnw <- logical(length = dim(x)[1])
    idnw[int$stspts:int$endpts] <- T
    # check how many other peaks this one overlaps with 
    if (length(unique(x$inter[idnw]))<2){
      x$inter[idnw & x$inter==0] <- H[j]
      
    } else { x$is.peak_yhat[i] <- F}
  }
  return(x)
}


######## Here the action begins
# import data
# x <- read.csv(args[1], sep=' ', header=FALSE)
x <- read.csv(opt$file, sep=' ', header=FALSE)

x <- findPeaks(x)

# translate the peaks into a data structure
uninter <- sort(unique(x$inter),decreasing = T)
uninter <- uninter[uninter>0]
thepeak <- data.frame()
for (i in uninter){
  # filename, peaknb, max,start, end
  intx <- x$V2[x$inter==i]
  thepeak <- rbind(thepeak, 
                   data.frame(filename = opt$file, 
                              peaknb = i,
                              max_xpos = intx[which.max(x$V1[x$inter==i])],
                              count_at_max = max(x$V1[x$inter==i]), 
                              peakstart = min(intx),
                              peakend = max(intx)))
}


# Export results
write.csv(thepeak,file = opt$out,row.names = F)

# include a figure
if (opt$verbose){
  q1 <- ggplot2::qplot(data = x, V2, V1, geom = 'line', color = 'red') + 
    ggplot2::geom_line(ggplot2::aes(V2,ysmooth),color = 'green') + 
    ggplot2::geom_point(data = x[x$is.peak_yhat,],ggplot2::aes(y = ysmooth), color = 'black') + 
    ggplot2::geom_point(data = x[x$inter>0,],ggplot2::aes(y = inter+1),color = 'blue') + 
    ggplot2::ggtitle(opt$file) + 
    ggplot2::xlab('Sequence length') +
    ggplot2::ylab('Number of reads') + 
    ggplot2::theme_classic() + 
    ggplot2::theme(legend.position = 'none')
  
  pdf(opt$figure)
  print(q1)
  dev.off()
}

