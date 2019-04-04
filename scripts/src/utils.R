# R utilities functions
# 2012,...,2018 Maciek Sykulski <macieksk@gmail.com>

library("hash")
library("fastmatch")
#if (require(fastmatch)) match<-fmatch


# improved list of objects
.ls.objects <- function (pos = 1, pattern, order.by,
                        decreasing=FALSE, head=FALSE, n=5) {
    napply <- function(names, fn) sapply(names, function(x)
                                         fn(get(x, pos = pos)))
    names <- ls(pos = pos, pattern = pattern)
    obj.class <- napply(names, function(x) as.character(class(x))[1])
    obj.mode <- napply(names, mode)
    obj.type <- ifelse(is.na(obj.class), obj.mode, obj.class)
    obj.size <- napply(names, object.size)
    obj.dim <- t(napply(names, function(x)
                        as.numeric(dim(x))[1:2]))
    vec <- is.na(obj.dim)[, 1] & (obj.type != "function")
    obj.dim[vec, 1] <- napply(names, length)[vec]
    out <- data.frame(obj.type, obj.size, obj.dim)
    names(out) <- c("Type", "Size", "Rows", "Columns")
    if (!missing(order.by))
        out <- out[order(out[[order.by]], decreasing=decreasing), ]
    if (head)
        out <- head(out, n)
    out
}
# shorthand
lsos <- function(..., n=10) {
    .ls.objects(..., order.by="Size", decreasing=TRUE, head=TRUE, n=n)
}

#Helper Functions
#projectPrefix<-"R_markov_fields_acgh"
plotNameOut<-function(name)paste(projDir,"/plots/",projectPrefix,"_",name,sep="")
plotName<-function(name)paste(projectPrefix,"_",name,sep="")

niceDate<-function()format(Sys.time(), "%Y-%m-%d_%H_%M_%S")#"%H-%M-%S_%m_%d_%Y")
    #gsub(":","-",gsub(" ","_",date()))
#niceDate()

save_new_image<-function(){
    #gc()
    fname<-paste(projDir,"/r_saved_images/",projectPrefix,"_",niceDate(),".Rdata",sep="")
    defname<-paste(projDir,"/r_saved_images/",projectPrefix,".Rdata",sep="")
    save.image(fname,safe=FALSE)
    system(paste("ln -sf",fname,defname,sep=" "))
    print(fname)
}

get.global.vec <- function(keyword="^global.")do.call(data.frame,lapply(sapply(grep(keyword,ls(),value=T),get,simplify=F),rbind))

################
################ Parallel helper functions for multicore library
################ Run jobs (expressions) in the background without blocking
################ 

#library(multicore) #better to be loaded last of all libraries 
library(parallel)

inpar<-function(name,expr){
#Runs named expression in parallel with main thread - non-blocking
 name<-deparse(substitute(name)) 
 vname<-paste(name,"tocollect",sep=".")
 print(paste(vname,Sys.time()))
 assign(vname, list(mcparallel(eval(expr),name)), envir=.GlobalEnv)
}


cpar<-function(name){
#Collects previously run expression if finished - non-blocking
 name<-deparse(substitute(name)) 
 vname<-paste(name,"tocollect",sep=".")
 vjob<-get(vname,envir=.GlobalEnv)[[1]]
 cres<-mccollect(vjob,wait=FALSE,timeout=1)
 print(paste("Obtained result:",!is.null(cres)))
 if (!is.null(cres)){
    while (!is.null(parallel:::readChild(vjob$pid))){}
    assign(name,cres[[1]], envir=.GlobalEnv) 
 }
 print("Children left:")
 print(parallel:::children()) 
}

kill.all.jobs<-function(){
    print(parallel:::children())
    while(!is.null(parallel:::readChildren())) TRUE;
    print("Children left:")
    print(parallel:::children())
}

ex<-expression

#inpar(testp, ex( mean(rnorm(1000)) ) )
#cpar(testp)
#testp
#inpar(testp,ex({Sys.sleep(10); 1}))
#cpar(testp)
#testp
#kill.all.jobs()


postscript.call<-function(file,height,width,
         pointtopixel=1400,
         pointsize=70,
         family="sans",
         onefile=TRUE,
         horizontal=FALSE,
         encoding="ISOLatin1.enc",paper="special",
         ...)
         postscript(file=file,onefile=onefile,family=family,encoding=encoding,
         paper=paper, horizontal=horizontal,
         pointsize=pointsize,
         height=height/pointtopixel*pointsize,width=width/pointtopixel*pointsize,
         ...)
         
pdf.call<-function(file,height,width,
         pointtopixel=1400,
         pointsize=70,
         family="sans",
         onefile=TRUE,
         encoding="ISOLatin1.enc",paper="special",
         ...)
         pdf(file=file,onefile=onefile,family=family,encoding=encoding,
         paper=paper,
         pointsize=pointsize,
         height=height/pointtopixel*pointsize,width=width/pointtopixel*pointsize,
         ...)

## Paste functions
p <- function(..., sep='') {
    paste(..., sep=sep)
}

implode <- function(..., sep='') {
     paste(..., collapse=sep)
}

#Loop over multiple loops
multiloop <- function(...,FUN=c)
{  
   # Retrieve inputs and convert to a list of character strings
   arguments <- list(...)
 
   # Get length of each input
   lengths <- sapply(arguments, length)
   l<-max(lengths)
   stopifnot(all(l==lengths))
   
   # Loop over elements
   lapply(seq_len(l),function(i){
      # Loop over inputs
      FUN(sapply(arguments,function(a)a[i]))      
   })
}

#sqldf helper functions
#Author: Maciek Sykulski 2012
if (FALSE) {
library(sqldf)                    

#Outputs info about tables in db
db.info<-function(dbname,tablename=NULL){ 
  if (is.null(tablename)){
    dbinfo<-sqldf("select * from sqlite_master where type='table'", dbname = dbname)
  } else {
    dbinfo<-sqldf(paste("select * from sqlite_master where type='table' and tbl_name='",tablename,"'",sep=""), dbname = dbname)
  }
  counts<-sapply(dbinfo$tbl_name,function(tablename)as.numeric(sqldf(paste("select count(1) from ",tablename), dbname = dbname)))
  cbind(count=counts,dbinfo)
}

## Reads table into existing sqlite database
read.table.into.db<-function(fname,dbname,tablename,
                    create.db=FALSE,
                    file.format=list(header = TRUE, sep = ";", eol = "\n"), ...){
if (exists(tablename)) warning(paste("Variable with the same name as tablename exists: ", tablename))
if (create.db) { sqldf(paste("attach '",dbname,"' as new",sep="")) }
tmpfile<-file(fname)
ret=sqldf(paste("create table ",tablename," as select * from tmpfile"),dbname=dbname,file.format=file.format,...)

list( ret=ret, info=db.info(dbname,tablename) )
}

add.records.to.table<-function(fname, dbname, tablename, file.format=list(header = TRUE, sep = ";", eol = "\n"), ...)
{
tmpfile<-file(fname)
ret=sqldf(paste("insert into ",tablename," select * from tmpfile",sep=""), dbname=dbname, file.format=file.format,...)
list( ret=ret, info=db.info(dbname,tablename) )
}

drop.table.from.db<-function(dbname,tablename)sqldf(paste("drop table ",tablename),dbname=dbname)

} # End if (FALSE) sqldf functions

modulo<-function(a,b){a%%b}



