library(readxl)
library(dplyr)
library(ggplot2)
library(rnaturalearth)
library(sf)
library(ggrepel)
library(patchwork)
library(grid)
library(gridExtra)
library(tidyr)
df<-read.csv("DANE1.csv")
df1<-read_xlsx("DANE2.xlsx")
options(warn = -1)

df$GroupAge <- rep(1:ceiling(nrow(df)/3), each = 3, length.out = nrow(df))
df<-df%>%
  rowwise() %>%
  mutate(Mean_Years = sum(c(X2020, X2021,X2022,X2023), na.rm = TRUE)) %>%
  ungroup()%>%
  group_by(GroupAge)%>%
  summarise(AVG=sum(Mean_Years,na.rm=TRUE))

df$GroupAge<-LETTERS[1:6]

colors <- c("#b5e0f3", "#884292", "#8c2a64", "#e62248", "#e4007e", "#ea4f7f")

p1<-ggplot(data=df,aes(x=as.factor(GroupAge),y=AVG))+
  geom_bar(stat="identity",fill="#303174")+
  labs(title="Łączna liczba adopcji w latach 2020-2023 w podziale na wiek dzieci",
       y ="Liczba dzieci",
       x="Przedziały wieku")+
  theme_void()+
  theme(axis.text.x = element_text(color = colors,size=15),
        axis.text.y=element_text(size=15),
        plot.title = element_text(size=20),
        axis.title.x = element_text(size=16),
        axis.title.y=element_text(size=16))

age_ranges <- data.frame(
  Start = seq(0, 15, by = 3),       
  End = c(seq(3, 15, by = 3), 18)    
)
age_ranges$Letters<-LETTERS[1:6]
age_ranges$Range <- paste(age_ranges$Start, age_ranges$End, sep = "-")
age_ranges<-age_ranges[,3:4,drop=FALSE]
colnames(age_ranges)<-c("Litery","Zakres wieku dzieci w latach")


my_table_theme <- ttheme_default(core=list(bg_params = list(fill = colors, col=NA)),
                                 colhead = list(bg_params = list(fill = "grey")))
rownames(age_ranges) <- NULL
table<-gridExtra::tableGrob(age_ranges, theme = my_table_theme,rows = rep(" ", 6))


combined_plot <- p1 + table+plot_layout(ncol = 2, widths = c(3, 1))
combined_plot



df1<-as.data.frame(df1)
colnames(df1)[1] <- "Voivodeship"
poland <- ne_states(country = "Poland", returnclass = "sf")
df1<-df1%>%
  pivot_longer(!Voivodeship, names_to = "Year", values_to = "count")
df1_result<-df1%>%
  group_by(Voivodeship)%>%
  summarise(Mean=mean(count,na.rm=TRUE))%>%
  mutate(Voivodeship=paste("województwo",Voivodeship))

poland<- poland %>% inner_join(df1_result,by=c("name_pl"="Voivodeship"))

p2<-ggplot(data = poland) +
  geom_sf(aes(fill = Mean), color = "black")+
  scale_fill_gradient2(name="Ilość wychowanków",
                       mid = ("#ea4f7f"),
                       
                       high = ("#315ca8"))+
  theme_minimal()+
  theme_void()+
  labs(title="Średnia liczba wychowanków pieczy rodzinnej \nw roku w podziale na województwa",
       subtitle="Lata: 2014-2023")+
  theme(plot.title = element_text(size=20),
        subplot.title=element_text(size=16),
        legend.title=element_text(size=16),
        legend.text = element_text(size=14))


p2