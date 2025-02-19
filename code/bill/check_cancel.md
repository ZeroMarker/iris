
## 诊查费撤销控制
```objectscript
/// Desc: 判断诊查费能否撤销
/// Table: SSUser, SSUserOtherLogonLoc
/// Input: OrItemID, Arcimid, UserID
/// Returns: 1: 能撤销, 0: 不能撤销
/// Others: w ##Class(web.UDHCStopOrderLook).CheckFeeCancelFlag("2312||1","3548||1","21202")
ClassMethod CheckFeeCancelFlag(OrItemID, Arcimid, UserID)
{
	n (OrItemID, Arcimid, UserID)
	s flag = 1
	s Adm=$p(^OEORD(+OrItemID),"^",1)
	s AdmType=$P($G(^PAADM(Adm)),"^",2)
	s service = $p(^ARCIM($p(Arcimid,"||",1),$p(Arcimid,"||",2),8),"^",7)
	s defaultDept=$p(^SSU("SSUSR",UserID),"^",4)
	if (service=6)&&((AdmType="O")||(AdmType="E")) {
		if defaultDept'=52 {
			s otherlocsub = 0
			for{
				s otherlocsub = $o(^SSU("SSUSR",UserID,"OTHLL",otherlocsub))
				q:otherlocsub=""
				s dept = $p(^SSU("SSUSR",UserID,"OTHLL",otherlocsub),"^",1)
				if dept=52 {
					s flag = 1
				}
				else {
					s flag = 0	
				}
				q:flag=1
			}
		}
	}
	q flag
}
// w ##class(Nur.NIS.Service.Base.OrderHandle).IfCanUpdateOrdGroup
```
