# ===== personal project01
# ===== 處理聯合報柯文哲1月至5月的文章，製作tfidf
# ------------------------------------------

# 匯入套件
library(tibble)
library(dplyr)
library(tidyr)
library(data.table)
library(NLP)
library(tm)
library(jiebaRD)
library(jiebaR)
library(magrittr)
library(RColorBrewer)
library(wordcloud)

# 資料清理 
# 匯入資料組
setwd("/Users/Weber/Documents/GitHub/NTU-CSX-DataScience--Group5/Finalproject/UDN/爬完的結果!!")
Ko_data <- read.csv("ko_Output.csv", encoding = "big5")
Ko_data2 <- read.csv("ko_Output2.csv", encoding = "big5")

# 整合需要的欄位
all <- rbind(Ko_data[,3:5], Ko_data2[,2:4])
# 清除NA
all <- all %>% na.omit()
# 切開時間
all <- all %>% separate(V2, c("year","month","day"),"-")
all <- all %>% separate(day, c("date","time"), " ")
all <- all[with(all, order(year, month, date)), ]
# 移除重複資料
all <- all[!duplicated(all$bindtext), ]
row.names(all) = c(1:3112) # 由資料數重新編排號碼
Ko <- subset(all, select = c(month, date, V1, bindtext))

# -----------------------------
# 匯出清理完資料
# Media <- c()
# text <- c("UDN")
# for( i in 1:length(Ko$bindtext)){
  # Media <- rbind(Media, text)
# }
# Ko <- cbind(Media, Ko)
# write.table(Ko , file = "C:/Users/Weber/Documents/GitHub/NTU-CSX-DataScience--Group5/Finalproject/NewsCleaning/Ko_udn.csv", sep = ",")
# -----------------------------

# 分割為各月份資料
ko1<- subset(all, all$month == "01", select = bindtext)
ko2<- subset(all, all$month == "02", select = bindtext)
ko3<- subset(all, all$month == "03", select = bindtext)
ko4<- subset(all, all$month == "04", select = bindtext)
ko5<- subset(all, all$month == "05", select = bindtext)


# ==== 切詞
cor_word <- function(data){
  docs <- Corpus(VectorSource(data))
  toSpace <- content_transformer(function(x,pattern){
    return(gsub(pattern," ",x))
  })
  # 刪去單詞贅字、英文字母、標點符號、數字與空格
  docs <- tm_map(docs,toSpace,"\n")
  docs <- tm_map(docs,toSpace, "[A-Za-z0-9]")
  clean_doc <- function(docs){
    clean_words <- c("[A-Za-z0-9]","、","《","『","』","【","】","／","，","。","！","「","（","」","）","\n","；",">","<","＜","＞")
    for(i in 1:length(clean_words)){
      docs <- tm_map(docs,toSpace, clean_words[i])
    }
    return(docs)
  }
  docs <- clean_doc(docs)
  clean_word_doc <- function(docs){
    clean_words <- c("分享","記者","攝影","提及","表示","報導","我們","他們","的","也","都","就","與","但","是","在","和","及","為","或","且","有","含")
    for(i in 1:length(clean_words)){
      docs <- tm_map(docs,toSpace, clean_words[i])
    }
    return(docs)
  }
  docs <- clean_word_doc(docs)
  docs <- tm_map(docs, removeNumbers)
  docs <- tm_map(docs, toSpace, "[a-zA-Z]")
  docs <- tm_map(docs, stripWhitespace)
  docs <- tm_map(docs, removePunctuation)
  # 匯入自定義字典
  mixseg = worker()
  segment <- c("柯文哲","姚文智","丁守中","台北市長","選舉","候選人","台灣","選票","柯市長","民進黨","國民黨","台北市民","市民")
  new_user_word(mixseg,segment)
  
  # 有詞頻之後就可以去畫文字雲
  jieba_tokenizer=function(d){
    unlist(segment(d[[1]],mixseg))
  }
  
  seg = lapply(docs, jieba_tokenizer)
  freqFrame = as.data.frame(table(unlist(seg)))
  # 清除單字
  for(i in c(1:length(freqFrame$Var1))){
    if((freqFrame$Var1[i] %>% as.character %>% nchar) == 1){
      freqFrame[i,] <- NA
    }
  }
  freqFrame <- na.omit(freqFrame)
  
  return(freqFrame)
}

Freq1 <- lapply(ko1, cor_word)





d.corpus <- Corpus(VectorSource(seg))
tdm <- TermDocumentMatrix(d.corpus)
print( tf <- as.matrix(tdm) )
DF <- tidy(tf)

# tf-idf computation
N = tdm$ncol
tf <- apply(tdm, 2, sum)
idfCal <- function(word_doc)
{ 
  log2( N / nnzero(word_doc) ) 
}
idf <- apply(tdm, 1, idfCal)

doc.tfidf <- as.matrix(tdm)
for(x in 1:nrow(tdm))
{
  for(y in 1:ncol(tdm))
  {
    doc.tfidf[x,y] <- (doc.tfidf[x,y] / tf[y]) * idf[x]
  }
}

findZeroId = as.matrix(apply(doc.tfidf, 1, sum))
tfidfnn = doc.tfidf[-which(findZeroId == 0),]