```objectscript
/// 获取诊室
/// w ##class(web.DHCDocMain).GetRoomByEpisodeID(9127)
ClassMethod GetRoomByEpisodeID(EpisodeID)
{
	q:EpisodeID="" ""
	s regfee = $o(^User.DHCRegistrationFeeI("ADM"," "_EpisodeID,0))
	s rbas = $lg(^User.DHCRegistrationFeeD(regfee),18)
	q:rbas="" ""
	s room = $p(^RBAS(+rbas,$p(rbas,"||",2),"DHC"),"^",5)
	s eff = $p(^RBAS(+rbas,$p(rbas,"||",2)),"^",12)
	b ;;;;
	s:((eff'="")&&($g(room)="")) room = $p($g(^RB("RES",+eff,"DATE",$p(eff,"||",2),"SESS",$p(eff,"||",3))),"^",19)
	q:room="" ""
	s desc = $p($g(^CTLOC(room)),"^",2)
	q desc
}
```

```objectscript
/// 批量更新坐诊信息
/// w ##class(web.DHCDocMain).UpdateSess()
ClassMethod UpdateSess()
{
	s res = 0
	for {
		s res = $o(^RB("RES",res))
		q:res=""
		s date = 0
		for {
			s date = $o(^RB("RES",res,"DATE",date))
			q:date=""
			s sess = 0
			for {
				s sess = $o(^RB("RES",res,"DATE",date,"SESS",sess))
				q:sess=""
				;[{"AQRowid":"260||1||16||1","AppMethodID":"1","AppMethod":"窗口预约","MaxQty":"30","ReserveQty":"","StartNo":""}]
				s aq = $o(^RB("RES",res,"Date",date,"SESS",sess,"AQ",0))
				s json = []
				s item = {}
				if (aq = "") {
					s item.AQRowid = ""
				}
				else {
					s item.AQRowid = res_"||"_date_"||"_sess_"||"_aq	
				}
				s appNum=$p($g(^RB("RES",res,"DATE",date,"SESS",sess)),"^",1)
				s item.AppMethodID = 1
				s item.AppMethod = "窗口预约"
				s item.MaxQty = appNum
				s item.ReserveQty = ""
				s item.StartNo = ""
				
				d json.%Push(item)
				s json = json.%ToJSON()
				s rtn = ##class(DHCDoc.OPAdm.ScheduleTemp).SaveTempAppMethodNew(res_"||"_date_"||"_sess,json)
			}	
		}	
	}
	q 0
	;^RB("RES",{RB_Resource.RES_RowId},"DATE",{RB_ResEffDate.DATE_Childsub},"SESS",{SESS_Childsub})
}
```