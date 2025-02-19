```objectscript
/// w ##class(web.DHCDocMain).GetRoomByEpisodeID(33)
ClassMethod GetRoomByEpisodeID(EpisodeID)
{
	q:EpisodeID="" ""
	s regfee = $o(^User.DHCRegistrationFeeI("ADM"," "_EpisodeID,0))
	s rbas = $lg(^User.DHCRegistrationFeeD(regfee),18)
	q:rbas="" ""
	s eff = $p(^RBAS(+rbas,$p(rbas,"||",2)),"^",12)
	q:eff="" ""
	s room = $p($g(^RB("RES",+eff,"DATE",$p(eff,"||",2),"SESS",$p(eff,"||",2))),"^",19)
	q:room="" ""
	s desc = $p($g(^CTLOC(room)),"^",2)
	q desc
	;^RBAS({RB_Resource.RES_RowId},{AS_ChildSub}) 12
	;^RB("RES",{RB_Resource.RES_RowId},"DATE",{RB_ResEffDate.DATE_Childsub},"SESS",{SESS_Childsub}) 19
}
```