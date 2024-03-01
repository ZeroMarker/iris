```objectscript
// web.UDHCStopOrderLook.cls

s LLabEpisodeNoStr=$P($G(^OEORD(Ord,"I",Sub,"DHC")),"^",22)
s LLabEpisodeNo=$P($G(^OEORD(Ord,"I",Sub,3)),"^",20)

for i=1:1:$length(LLabEpisodeNoStr,$C(1)){
    s LLabEpisodeNo=$P(LLabEpisodeNoStr,$C(1),i)
    continue:LLLLabEpisodeNo=""
    if $D(LLabEpisodeNoArr(LLabEpisodeNo)){
        //如果关联的检验还有存在有效医嘱
        //则这条材料不需要停止
        s FindSameLabNo=1
    }
}
```