lock +^OEORD(5949):10

l +^DBLock($zn,EpisodeID):3
i '$test {
    d ##class(DHCDoc.Log.Common).General("Insert","web.DHCDocPrescript","CreatOrdNo","生成处方并发,插入医嘱失败",EpisodeID,-1)
    q ""
}