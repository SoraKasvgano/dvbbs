query|||7200|||bbs|||select top 10  PostUserName,Title,Topicid,Boardid,Dateandtime,Topicid as Topicid2,Hits,Expression,LastPost from [dv_topic] where boardid not in(444,777) order by topicid desc|||<ul>|||<LI><A href="dispbbs.asp?boardid={$Boardid}&amp;id={$ID}">{$Topic}</A></LI>|||</ul>|||10$1$1$$1$0$0|||28|||2