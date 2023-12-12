opdoc.patient.list.csp
dhcdoc.opdoc.patient.list.js
var ret=tkMakeServerCall("web.DHCVISQueueManage","RunNextButton","","",GetCacheIPAddress());
ClassMethod CheckCalledStatus(EpisodeID As %String, UserID As %String = "") As %String
{
	s retStr=""
	q:$g(EpisodeID)="" "9^就诊信息不存在,请重新呼叫!"
    i UserID="" s UserID=%session.Get("LOGON.USERID")
    s CareID=$P($G(^SSU("SSUSR",UserID)),"^",14)
	q:$g(CareID)="" "10^用户非医护人员不能呼叫!"
	s QueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeID,""))
	q:QueRowId="" "11^队列信息不存在不能呼叫!"
	s oref=##Class(User.DHCQueue).%OpenId(QueRowId)
	s called=oref.QueCompDr
	s DocDr=oref.QueDocDrGetObjectId()
    d oref.%Close()
    q:(called=1)&&(DocDr'=CareID)&&(DocDr'="") "12^该病人已被其他医生呼叫,请重新呼叫!"
    q 0
}