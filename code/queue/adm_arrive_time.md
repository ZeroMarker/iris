## 就诊号到达时间

tables
- DHCQueue
- DHCQueueStatus
- PerState

global
- ^PAADMi("No",$$ALPHAUP({PAADM_ADMNo}),{PAADM_RowID})
- ^User.DHCQueueI("QuePaadmDrIndex",QuePaadmDr)
```objectscript
/// w ##class().GetArriveTimeByAdmNo(AdmNo)
ClassMethod GetArriveTimeByAdmNo(AdmNo) As %String
{
	s RowId = 0
    s AdmRowId = $o(^PAADMi("No",AdmNo,RowId))
    s RowId = 0
    s QueDr = $o(^User.DHCQueueI("QuePaadmDrIndex", AdmRowId, RowId))

    ;s QueArriveDate=$P($G(^DHCQueueStatus(QueDr,QueChangeSub)),"^",1)
    ;s QueArriveTime=$P($G(^DHCQueueStatus(QueDr,QueChangeSub)),"^",2)
    s QueArriveTime = ""
    s QueChangeSub = ""
    f  {
        s QueChangeSub=$O(^DHCQueueStatus(QueDr,QueChangeSub),-1)
        Q:(QueChangeSub="")||(QueArriveTime'="")
        s QueChangeStatuDr=$P($G(^DHCQueueStatus(QueDr,QueChangeSub)),"^",4)
        continue:QueChangeStatuDr=""
        s QueChangeBeforeStatuDr=""
        //上条变化是报道且本次状态是等候
        s QueChangeBeforeSub=$O(^DHCQueueStatus(QueDr,QueChangeSub),-1)
        s QueChangeBeforeStatuDesc=""
        if (QueChangeBeforeSub'=""){
            s QueChangeBeforeStatuDr=$P($G(^DHCQueueStatus(QueDr,QueChangeBeforeSub)),"^",4)
            continue:QueChangeBeforeStatuDr=""
            s QueChangeBeforeStatuDesc=$list(^User.DHCPerStateD(QueChangeBeforeStatuDr),4)
        }
        //continue:QueChangeBeforeStatuDesc=""
        s QueChangeStatuDesc=$list(^User.DHCPerStateD(QueChangeStatuDr),4)
        //*if (QueChangeStatuDesc="等候")&&(QueChangeBeforeStatuDesc="报到"){
            s QueArriveDate=$P($G(^DHCQueueStatus(QueDr,QueChangeSub)),"^",1)
            s QueArriveTime=$P($G(^DHCQueueStatus(QueDr,QueChangeSub)),"^",2)
            s QueArriveTime = ..%ZD(QueArriveDate)_" "_..%ZT(QueArriveTime)
        //}
    }
 	q QueArriveTime
}
```