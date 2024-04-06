Import SQLUser

Class web.DHCVISQueueManage Extends %Library.RegisteredObject [ ClassType = "", ProcedureBlock ]
{

/****************************************陈杨重新整理修改****************************************/
/// cy20190605
/// 门诊呼叫按钮
/// w ##Class(web.DHCVISQueueManage).RunNextButton("1","4783","192.168.41.234)
/// "0^正在呼叫""1^未配置客户端","2^未关联服务器","3^服务器未激活""4^请处理完绿色背景患者,再呼叫新患者!""5^更新队列状态失败!""7^超出最多呼叫人数!""8^获取呼叫队列失败""9^就诊信息不存在,请重新呼叫!""10^用户非医护人员不能呼叫!""11^队列信息不存在不能呼叫!""12^该病人已被其他医生呼叫,请重新呼叫!"
ClassMethod RunNextButton(LocID As %String = "", UserID As %String = "", IPAddress As %String = "", MarkID As %String = "", QueId As %String = "") As %String
{
	s retStr="8^获取呼叫队列失败",retValue=""
	i LocID="" s LocID=%session.Get("LOGON.CTLOCID")
    i UserID="" s UserID=%session.Get("LOGON.USERID")
    //i IPAddress="" s IPAddress=$ZUTIL(67,15,$JOB)
    ;s IPAddress = "192.168.137.1"
    i IPAddress="" s IPAddress=%session.Data("REMOTE_ADDR")
    s IPAddress=$$upper^SSUTIL4(IPAddress)
    i MarkID="" s MarkID=%session.Get("MarkSelectDr")
    s activeFlag=..GetActiveFlag(IPAddress)
    q:activeFlag'=0 activeFlag
    //d ..InsertClientInfo(IPAddress)
    s StartDate=+$H
    s EndDate=+$H
    s RegQue="on"
    s Consultation="on"
    s AllPatient="",PatientNo="",SurName="",ArrivedQue=""
    s admPersons=+$G(^DHCVISSet("DHCVISAdm"))  //呼叫的人数
    i admPersons=0 s admPersons=1
    s waitPersons=+$G(^DHCVISSet("DHCVISWaiting"))  //获取等候人数
    s patIndex=0
    s insertFlag=0
    s WaitNo=1,waitEndAdm=""
    //LocID,UserID,IPAddress,AllPatient,PatientNo,SurName,StartDate,EndDate,
    //ArrivedQue,RegQue,Consultation,MarkID,CheckName
    s WaitList="",WaitListNo="",CKScreenStr="!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",DocInfoStr="!!!!!!!!!!!"
    s LoginFlag = "", GHList=""
    if QueId '= "" {
	    s rs=##Class(%ResultSet).%New("web.DHCDocOutPatientList:FindLocDocCurrentAdm")
		i rs.QueryIsValid() {
			//s waitPersons=waitPersons-1
			Set Status=rs.Execute(LocID,UserID,IPAddress,"","","",+$h,+$h,"","on","",MarkID,"")
			Set columns = rs.GetColumnCount()
			If 'Status Quit
			While rs.Next() {
				s patIndex=patIndex+1
				//呼叫+等候
				i (patIndex>admPersons)&&(retStr="") s retStr="4^请处理完绿色背景患者,再呼叫新患者!"
				q:((patIndex>admPersons)&&((waitPersons+admPersons)-patIndex<0))
				s WalkStatus=rs.GetDataByName("WalkStatus")
				continue:(WalkStatus="到达")||(WalkStatus="退号")
	            //q:(patIndex>AdmWaitPersons) 
	            s calledFlag=rs.GetDataByName("Called")
				i calledFlag=1  s retStr="4^请处理完绿色背景患者,再呼叫新患者!"
				q:calledFlag=1
			}
		}
		q:calledFlag=1 retStr
	    s status = ##class(DHCDoc.Interface.Outside.YH.DHCDocVISService.MainMethods).ReCall(QueId,IPAddress)
	}
	q:$g(calledFlag)=1 retStr
	q:$g(status)=0 status_"^"
    /*
    i activeFlag'=0 d
    .s retValue="alert('"_$ZCVT(activeFlag,"O","JS")_"')" 
    .&javascript<#(retValue)#>
    */
    q:activeFlag'=0 activeFlag
    //d ..InsertClientInfo(IPAddress)
    s StartDate=+$H
    s EndDate=+$H
    s RegQue="on"
    s Consultation="on"
    s AllPatient="",PatientNo="",SurName="",ArrivedQue=""
    s admPersons=+$G(^DHCVISSet("DHCVISAdm"))  //呼叫的人数
    i admPersons=0 s admPersons=1
    s waitPersons=+$G(^DHCVISSet("DHCVISWaiting"))  //获取等候人数
    s patIndex=0
    s insertFlag=0
    s WaitNo=1,waitEndAdm=""
    //LocID,UserID,IPAddress,AllPatient,PatientNo,SurName,StartDate,EndDate,
    //ArrivedQue,RegQue,Consultation,MarkID,CheckName
    s WaitList="",WaitListNo="",CKScreenStr="!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",DocInfoStr="!!!!!!!!!!!"
    s LoginFlag = "", GHList=""
    s rs=##Class(%ResultSet).%New("web.DHCDocOutPatientList:FindLocDocCurrentAdm")
	i rs.QueryIsValid() {
		//s waitPersons=waitPersons-1
		Set Status=rs.Execute(LocID,UserID,IPAddress,AllPatient,PatientNo,SurName,StartDate,EndDate,ArrivedQue,RegQue,"",MarkID,"")
		Set columns = rs.GetColumnCount()
		If 'Status Quit
		While rs.Next() {
			s patIndex=patIndex+1
			//呼叫+等候
			i (patIndex>admPersons)&&(retStr="") s retStr="4^请处理完绿色背景患者,再呼叫新患者!"
			q:((patIndex>admPersons)&&((waitPersons+admPersons)-patIndex<0))
			s WalkStatus=rs.GetDataByName("WalkStatus")
			continue:(WalkStatus="到达")||(WalkStatus="退号")
            //q:(patIndex>AdmWaitPersons) 
            s calledFlag=rs.GetDataByName("Called")
			i calledFlag=1  s retStr="4^请处理完绿色背景患者,再呼叫新患者!"
			q:calledFlag=1 
			q:(insertFlag=1)
			i patIndex=admPersons d
			.s EpisodeID=rs.GetDataByName("EpisodeID")
			.s patName=rs.GetDataByName("PAPMIName")      
			.s PAAdmDepCodeDR=rs.GetDataByName("PAAdmDepCodeDR")
			.i $P(PAAdmDepCodeDR,"-",2)'="" s PAAdmDepCodeDR=$P(PAAdmDepCodeDR,"-",2)        
			.s docDr=##Class(web.SSUser).GetDefaultCareProvider(UserID)
			.s docDesc=""   //号别
			.i docDr'="" s docDesc=$P($G(^CTPCP(docDr,1)),"^",2) 
			.s DocHisID=""  //医生工号 
			.i docDr'="" s DocHisID=$P($G(^CTPCP(docDr,1)),"^",1)
			.s PAAdmRoom=..GetRoom(IPAddress)
			.i PAAdmRoom="" s retStr="1^未配置客户端"
			.q:PAAdmRoom=""
			.s PAAdmPriority=rs.GetDataByName("PAAdmPriority")
			.s Priority="平诊"
			.i PAAdmPriority="优先" s Priority="优诊"
			.i WalkStatus="复诊" s Priority="复诊"
			.i WalkStatus="到达" s Priority="复诊"
			.i $d(^RBAS("PAADM_DR",EpisodeID)) s Priority="预约"
			.s locSeqNo=rs.GetDataByName("LocSeqNo")
            .i locSeqNo'["号" s locSeqNo=locSeqNo_"号"
			.i (+locSeqNo)=0 s voiceContent="请 "_patName_" 到 "_PAAdmRoom_" 就诊"
			.e  s voiceContent="请 "_locSeqNo_" "_patName_" 到 "_PAAdmRoom_" 就诊"
			.s Note=PAAdmRoom_"   "_docDesc_"   "_locSeqNo_"-"_patName_"  "_PAAdmDepCodeDR
			.s regDocDesc=rs.GetDataByName("RegDoctor") //号别
			.i $G(regDocDesc)="" s regDocDesc=docDesc
			.s QueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeID,""))
			.q:QueRowId=""
			.s oref=##Class(User.DHCQueue).%OpenId(QueRowId)
			.s QueMarkDr=oref.QueMarkDrGetObjectId()   
			.i QueMarkDr'="" s ctpcpDesc=$P($g(^CTPCP(QueMarkDr,1)),"^",2)   //号别描述
	        .i ctpcpDesc'="" s ctpcpDesc=$P(ctpcpDesc,"(")   
	        .d oref.%Close()
			.s $P(DocInfoStr,"!",1)=$$upper^SSUTIL4(ctpcpDesc)
			.s $P(DocInfoStr,"!",2)=$$upper^SSUTIL4(DocHisID)
			.s $P(DocInfoStr,"!",3)=$$upper^SSUTIL4(UserID)
			.s $P(DocInfoStr,"!",4)=$$upper^SSUTIL4(LocID)
			.s $P(DocInfoStr,"!",5)=$$upper^SSUTIL4(MarkID)
			.s ZHScreenStr=PAAdmRoom_" "_PAAdmDepCodeDR_" "_regDocDesc_" "_locSeqNo_" "_patName_" "_Priority  //不在走FromatZHStr
			.s ZHScreenStr=QueRowId_"*"_ZHScreenStr
			.s DocTypeDesc=..GetDocTypeDesc(UserID)
			.s $P(CKScreenStr,"!",1)=$$upper^SSUTIL4(PAAdmDepCodeDR)
			.s $P(CKScreenStr,"!",2)=$$upper^SSUTIL4(PAAdmRoom)
			.s $P(CKScreenStr,"!",3)=$$upper^SSUTIL4(docDesc)
			.s $P(CKScreenStr,"!",4)=$$upper^SSUTIL4(DocTypeDesc)
			.s $P(CKScreenStr,"!",5)=$$upper^SSUTIL4(locSeqNo)
			.s $P(CKScreenStr,"!",6)=$$upper^SSUTIL4(patName)
			e  d
			.s locSeqNoT=rs.GetDataByName("LocSeqNo")
			.s EpisodeIDT=rs.GetDataByName("EpisodeID")
			.s patNameT=rs.GetDataByName("PAPMIName")  
			.s QueRowIdT=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeIDT,""))
			.q:QueRowIdT="" 
			.s QueDocDr=$List(^User.DHCQueueD(QueRowIdT),5)
			.q:(QueDocDr'="")&&(QueDocDr'=docDr)
			.S QueStateDr = $LG(^User.DHCQueueD(QueRowIdT),14)	;队列状态
		    .s PersName = $LG(^User.DHCPerStateD(QueStateDr),4)
			.s locSeqNoTS=QueRowIdT_"*"_locSeqNoT
			.;i WaitListNo="" s WaitListNo=locSeqNoTS
			.;e  s WaitListNo=WaitListNo_","_locSeqNoTS
			.s UnSplitFlag=..GetUnSplitFlag(EpisodeIDT,LocID)
			.i UnSplitFlag=0 d
			..i WaitListNo="" s WaitListNo=locSeqNoTS
			..e  s WaitListNo=WaitListNo_","_locSeqNoTS
			.i PersName="过号" d
			..s locSeqNoTS=QueRowIdT_"*"_locSeqNoT
			..i GHList="" s GHList=locSeqNoTS
			..e  s GHList=GHList_","_locSeqNoTS
			.s locSeqNoTS=QueRowIdT_"*"_locSeqNoT
			.i WaitListNo="" s WaitListNo=locSeqNoTS
			.e  s WaitListNo=WaitListNo_","_locSeqNoTS
			.s WaitIndex=$L(WaitListNo,",")
			.s $P(CKScreenStr,"!",WaitIndex+6)=$$upper^SSUTIL4(locSeqNoT_"号-"_patNameT)
			.s TwoWaiterPersons=+$G(^DHCVISSet("TwoWaiter"))
			.i (TwoWaiterPersons'=0) d
			..q:(WaitNo>TwoWaiterPersons)
			..i voiceContent'="" s voiceContent=voiceContent_",请 "_patNameT_" 等候"
			..s updateWaitStatusFlag = ##Class(web.DHCDocOutPatientList).SetCallStatus(EpisodeIDT,docDr,2,IPAddress,WaitNo)
			..//i updateWaitStatusFlag'=1 s retValue="更新队列状态失败!"
			..s WaitNo=WaitNo+1
			..s waitEndAdm=EpisodeIDT
	
		} 
    }
    i waitEndAdm'="" s ^DHCDocSetArrive(UserID,+$H,"Call")=$G(^DHCDocOutPatientList("WartInd",waitEndAdm))
	i (($G(EpisodeID)'="")&&($P($G(voiceContent),",",1)'="")) d
	.// 先改状态在插表
	.s updateCallStatusFlag = ##Class(web.DHCDocOutPatientList).SetCallStatus(EpisodeID,docDr,"",IPAddress)
	.i updateCallStatusFlag'=1 s retStr="5^更新队列状态失败!"
	.q:updateCallStatusFlag'=1
   	.i waitEndAdm="" s ^DHCDocSetArrive(UserID,+$H,"Call")=$G(^DHCDocOutPatientList("WartInd",EpisodeID))
	.s WaitList=WaitListNo
	.s insertFlag=##Class(web.DHCVISVoiceCall).InsertVoiceQueue(voiceContent,UserID,IPAddress,"A","LR","N",ZHScreenStr,CKScreenStr,WaitList,Note,DocInfoStr,EpisodeID)
    .s insertFlag=##Class(DHCDoc.Interface.Outside.YH.DHCDocVISService.MainMethods).SendAdmCallInfo(EpisodeID, LocID, UserID, IPAddress, WaitList,LoginFlag,GHList)
    .i insertFlag'=0 s retStr="6^"_insertFlag
    .q:insertFlag'=0
    .s retStr="0^正在呼叫"_" "_locSeqNo_" "_patName_"..."
    .s insertFlag=1
    /*
    i retStr'="" s retValue="alert('"_$ZCVT(retStr,"O","JS")_"');findPatientTree();"
    i retStr="" s retValue="findPatientTree();"
    &javascript<#(retValue)#>
    */
    q retStr
}

/// w ##Class(web.DHCVISQueueManage).RunNextButtonAlloc(215,"")
ClassMethod RunNextButtonAlloc(QueId, Loc, UserId)
{
	s Bor = ""
	&sql(SELECT BordBorDr into :Bor from DHCExaBorDep where BordDepDr = :Loc)
	
	b ;;
	q:Bor="" "科室诊区未对照"
	s BorObj = ##class(User.DHCExaBorough).%OpenId(Bor)
	s BorCode = BorObj.ExabCode
	s BorName = BorObj.ExabName
	s QueObj = ##class(User.DHCQueue).%OpenId(QueId)
	s QueName = QueObj.QueName
	s QueNo = QueObj.QueNo
	s MarkDesc = QueObj.QueMarkDr.CTPCPDesc
	s EpisodeId = QueObj.QuePaadmDr.%Id()
	s FeeId = $o(^User.DHCRegistrationFeeI("ADM",EpisodeId,0))
	s FeeObj = ##class(User.DHCRegistrationFee).%OpenId(FeeId)
	s:FeeObj'="" TimeRange = FeeObj.RegfeeTimeRangeDr.TRDesc
	s voiceText = "请"_MarkDesc_"("_$g(TimeRange)_")号"_QueNo_"号"_QueName_"到眼科1诊室检查"
	s deptKey = BorCode
	s consultKey = ""
	s owner = "HIS"
	
	s OutputObj = {}
	s OutputObj.deptKey = deptKey
	s OutputObj.consultKey = consultKey
	s OutputObj.voiceText = voiceText
	s OutputObj.owner = owner
	s json = OutputObj.%ToJSON()
  	b ;xml
  	s obj=##Class(web.DHCENS.BLL.Call.Soap.PUB0004Soap).%New()
  	
  	set obj.Timeout=5
  	s className=obj.call(json).Read()
  	;quit isSussess
  	s json = {}.%FromJSON(className)
  	s status = json.status
  	s rtn = ..SendDeptScreenInfo(QueId,7,UserId)
	q status
}

/// /desc:推送眼科诊区患者信息
/// w ##Class(web.DHCVISQueueManage).SendDeptScreenInfo("189",7,"22028")
ClassMethod SendDeptScreenInfo(QueRowId As %String = "", BorId As %String = "", UserId As %String = "") As %String
{
	s $ZTrap = "SendAdmCallInfoET"
	s ^Temp("SendAdmCallInfo")=$lb(QueRowId,BorId,UserId)
	q:BorId="" ""
	s UserCode = $p($g(^SSU("SSUSR",UserId)),"^",1)
	s Mark = $p($g(^SSU("SSUSR",UserId)),"^",9)
	s Obj = {}
	s Obj.deptKey = $lg(^User.DHCExaBoroughD(BorId),2)
	s Obj.owner = "HIS"
	s Obj.type = 0
	s Obj.screenInfo = []
	s Obj.overPatientInfo = []
	
	set screenInfoItem = {}
	set screenInfoItem.waitPatientInfo = []
	if QueRowId '= "" {	
		set waitPatientInfo = {}
		set waitPatientInfo.registerId=$lg($g(^User.DHCQueueD(QueRowId)),10)
		set waitPatientInfo.patientName=$lg($g(^User.DHCQueueD(QueRowId)),9)
		set waitPatientInfo.sort=0 ;$lg($g(^User.DHCQueueD(QueRowId)),10) - 1
		do screenInfoItem.waitPatientInfo.%Push(waitPatientInfo)
	}
	
	;s opList = ##class(DHCDoc.OPDoc.PatientList).FindLocDocCurrentAdm()
	set rs=##class(%ResultSet).%New()
	set rs.ClassName="web.DHCAlloc"
	set rs.QueryName="QueryFindPatQueue"
	/// d ##class(%ResultSet).RunQuery("web.DHCAlloc","QueryFindPatQueue","HS01","","未报到","","","","","7","","","","","")
	/// w ##class(DHCDoc.OPDoc.PatientList).FindLocDocCurrentAdm(215,21333,"","","","","","","","","","","RegQue")
	
	set sc=rs.Execute(UserCode,"","未报到","","","","",BorId,"","","","","")
	s count = 0
	while rs.Next(.sc) {
		if $$$ISERR(sc) q
		s Que = rs.Data("TQueID")
		b ;Que
		continue:Que=QueRowId
		s count=count+1
		s sort = count
		set waitPatientInfo = {}
		set waitPatientInfo.registerId=$lg($g(^User.DHCQueueD(Que)),10)
		set state = $lg($g(^User.DHCQueueD(Que)),14)
		if state = 1 {
			set waitPatientInfo.patientName="(复)"_$lg($g(^User.DHCQueueD(Que)),9)
		}
		else {
			set waitPatientInfo.patientName=$lg($g(^User.DHCQueueD(Que)),9)
		}
		set waitPatientInfo.sort=$g(sort)
		do screenInfoItem.waitPatientInfo.%Push(waitPatientInfo)
	}
		
	set screenInfoItem.doctorKey = "nurse" ;$p($g(^CTPCP(Mark,1)),"^",1)
	set screenInfoItem.doctorName = "眼科检查" ;$p($g(^CTPCP(Mark,1)),"^",2)
	;set dept = $lg($g(^User.DHCExaBoroughD(Mark)),5)
	set screenInfoItem.deptName = "眼科门诊" ;$p($g(^CTLOC(dept)),"^",2)
	set screenInfoItem.consultName = 0 ;$lg($g(^User.DHCExaBoroughD(bor)),5)
	set screenInfoItem.shiftOut = 0
	
	
	do Obj.screenInfo.%Push(screenInfoItem)
	

	s json = Obj.%ToJSON()
	s obj=##Class(web.DHCENS.BLL.Call.Soap.PUB0004Soap).%New()
  	
  	b ;json
  	set obj.Timeout=5
  	s className=obj.oneShow(json).Read()
	
	s json = {}.%FromJSON(className)
  	s status = json.status
  	q status
SendAdmCallInfoET
    q "-1^叫号异常:"_$ze
}

ClassMethod GetUnSplitFlag(EpisodeID As %String, LocID As %String) As %String
{
	q:EpisodeID="" 0
	s UnSplitFlag=0
			   ///未到就诊开始时间的展示在队列里面 但是不参与叫号
	Set RegRangeTime="",RegRangeTimeCode=""
	set RegfeeDr=""
	s QueRowId=##class(web.DHCDocOutPatientList).GetQueRowidByMore(EpisodeID,"")
	Set QueObj=##Class(User.DHCQueue).%OpenId(QueRowId)
	Set StatusName=QueObj.QueStateDr.PersName
	Do QueObj.%Close()
	
	////如果是过号的患者  也不参与叫号  取分诊台 重新报道后 变为等候状态方可叫号
	q:StatusName="过号" 1
	
	
	Set RegfeeDr=$O(^User.DHCRegistrationFeeI("ADM"," "_EpisodeID,""))
	if (RegfeeDr'=""){
		set RegRangeTimeDr=$LIST(^User.DHCRegistrationFeeD(RegfeeDr),21)
		i $g(RegRangeTimeDr)'="" {
			set RegRangeTime=$p(^DHCTimeRange(RegRangeTimeDr),"^",2)
			set RegRangeTimeCode=$p(^DHCTimeRange(RegRangeTimeDr),"^",1)
			s LgHospID=##class(DHCDoc.Common.Hospital).GetLocHospitalId(LocID)
			s ConfigTimeRangeStr=##class(web.DHCOPRegConfig).GetGroupConfig(LgHospID,"TimeRangeReport",RegRangeTimeDr)
			if (ConfigTimeRangeStr'="")&&("等候"[StatusName){
				s UnSplitCode=$P($P(ConfigTimeRangeStr,"^",1),"!",1)
				s UnSplitStartTime=$P($P(ConfigTimeRangeStr,"^",1),"!",2)
				s UnSplitEndTime=$P($P(ConfigTimeRangeStr,"^",2),"!",2)
				if (UnSplitStartTime'="")&&(UnSplitCode="UnSplitStartTime"){
					s UnSplitStartTime=$ZTH(UnSplitStartTime)
					///未到报道时间不显示
					//if (..%SysTime()<UnSplitStartTime) continue
					if (+$p($h,",",2)<(UnSplitStartTime))  s UnSplitFlag=1  ////未开始的时段展示再一个队列里面　显示再队列的最下面
					}
				}
			}
		}
		
		q UnSplitFlag
}

/// cy20190605
/// 门诊重复呼叫
/// w ##Class(web.DHCVISQueueManage).RecallButton("215",21334,"192.168.137.1","")
ClassMethod RecallButton(LocID As %String = "", UserID As %String = "", IPAddress As %String = "", MarkID As %String = "") As %String
{
	s retStr="8^获取呼叫队列失败",retValue=""
	i LocID="" s LocID=%session.Get("LOGON.CTLOCID")
    i UserID="" s UserID=%session.Get("LOGON.USERID")
    i MarkID="" s MarkID=%session.Get("MarkSelectDr")
    //i IPAddress="" s IPAddress=$ZUTIL(67,15,$JOB)
    i IPAddress="" s IPAddress=%session.Data("REMOTE_ADDR")
    s IPAddress=$$upper^SSUTIL4(IPAddress)
    s activeFlag=..GetActiveFlag(IPAddress)
    s ^tempchen("recall") = $lb(LocID,UserID,IPAddress,MarkID)
    /*
    i activeFlag'=0 d
    .s retValue="alert('"_$ZCVT(activeFlag,"O","JS")_"')" 
    .&javascript<#(retValue)#>
    */
    q:activeFlag'=0 activeFlag
    s admPersons=+$G(^DHCVISSet("DHCVISAdm"))
    i admPersons=0 s admPersons=1
    s waitPersons=+$G(^DHCVISSet("DHCVISWaiting"))
    s AllPatient="",PatientNo="",SurName="",ArrivedQue=""
    s DocInfoStr="!!!!!!!!!!!"
    s DHCQueRowId="",QueueId="" 
    s StartDate=+$H
    s EndDate=+$H
    s RegQue="on"
    s patIndex=0
    s insertFlag=0 
	//1:表中有数据的取数据；2.表中没数据的取Query
    s QueueId=$O(^DHCVISQueuei(0,"CreateUser",UserID,""),-1)
    s QueueId=""
	i (QueueId'="") d
	.s VoiceQueueStr=$G(^DHCVISQueue(QueueId))
	.q:VoiceQueueStr=""
	.s EpisodeIDOld=$P(VoiceQueueStr,"^",23)
	.s DHCQueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeIDOld,""))
	.q:(DHCQueRowId="")
	.s oref=##Class(User.DHCQueue).%OpenId(DHCQueRowId)
	.i (oref'="") d
	..s Status=""
	..s Status=oref.QueStateDr.PersName
	..i ((Status="到达")||(Status="退号")||(Status="")) s DHCQueRowId=""
	..s QueMarkDr=oref.QueMarkDrGetObjectId()
	..i QueMarkDr'="" s ctpcpDesc=$P($g(^CTPCP(QueMarkDr,1)),"^",2) 
	..e  s ctpcpDesc=""
	..d oref.%Close()
    ..s docDr=##Class(web.SSUser).GetDefaultCareProvider(UserID)
	..i docDr'="" s docDesc=$P($G(^CTPCP(docDr,1)),"^",2)
	..e  s docDesc=""
	..i docDr'="" s DocHisID=$P($G(^CTPCP(docDr,1)),"^",1)
    ..e  s DocHisID=""
	..i (ctpcpDesc="")||(DocHisID="")||(UserID="")||(LocID="") s DHCQueRowId=""
    ..q:(DHCQueRowId="")
    ..s $P(DocInfoStr,"!",1)=$$upper^SSUTIL4(ctpcpDesc)
    ..s $P(DocInfoStr,"!",2)=$$upper^SSUTIL4(DocHisID)
	..s $P(DocInfoStr,"!",3)=$$upper^SSUTIL4(UserID)
	..s $P(DocInfoStr,"!",4)=$$upper^SSUTIL4(LocID)  
	..s $P(DocInfoStr,"!",5)=$$upper^SSUTIL4(MarkID) 
	..s voiceContent=$P(VoiceQueueStr,"^",4)
	..s ZHScreenStr=$P(VoiceQueueStr,"^",17)
	..s CKScreenStr=$P(VoiceQueueStr,"^",18)
	..s WaitList=$P(VoiceQueueStr,"^",19)
	..s Note=$P(VoiceQueueStr,"^",20)
	..s patName=$P(CKScreenStr,"!",6)
	..s locSeqNo=$P(CKScreenStr,"!",5)
	..s EpisodeID=oref.QuePaadmDr
	..s LoginFlag=""
	..s insertFlag=##Class(web.DHCVISVoiceCall).InsertVoiceQueue(voiceContent,UserID,IPAddress,"A","LR","N",ZHScreenStr,CKScreenStr,WaitList,Note,DocInfoStr,EpisodeIDOld)
    ..;s insertFlag=##Class(DHCDoc.Interface.Outside.YH.DHCDocVISService.MainMethods).SendAdmCallInfo(EpisodeID, LocID, UserID, IPAddress, WaitList,LoginFlag,GHList)
    ..i insertFlag'=0 s retStr="6^"_insertFlag
    ..q:insertFlag'=0
    ..s retStr="0^正在呼叫"_" "_locSeqNo_" "_patName_"..."
    i ((QueueId="")||(DHCQueRowId="")) {
      s rs=##Class(%ResultSet).%New("web.DHCDocOutPatientList:FindLocDocCurrentAdm")
	  i rs.QueryIsValid() {
		Set Status=rs.Execute(LocID,UserID,IPAddress,AllPatient,PatientNo,SurName,StartDate,EndDate,ArrivedQue,RegQue,"",MarkID,"")
		Set columns = rs.GetColumnCount()
		If 'Status Quit
		While rs.Next() {
			s patIndex=patIndex+1
			i (patIndex>admPersons)&&(retStr="") s retStr="7^超出最多呼叫人数!"
			q:(patIndex>admPersons)  
			s WalkStatus=rs.GetDataByName("WalkStatus")
			//i walkStatus="过号"  s retStr="过号患者须重新报到后才能呼叫!"
			//q:walkStatus="过号"
			i ((WalkStatus'="到达")&&(WalkStatus'="退号")) d
			.s calledFlag=rs.GetDataByName("Called")
			.q:(calledFlag="")
			.q:(insertFlag=1)
			.s EpisodeID=rs.GetDataByName("EpisodeID")
			.s patName=rs.GetDataByName("PAPMIName")
			.s QueId=rs.GetDataByName("QueRowId")
			.s status = ##class(DHCDoc.Interface.Outside.YH.DHCDocVISService.MainMethods).ReCall(QueId,IPAddress)
			.s retStr = status
			.;s retStr=..FrontQueueInsert(EpisodeID,LocID,UserID,IPAddress,MarkID)
            .;i $p(retStr,"^",1)=0 s insertFlag=1
		} 
      }
    }
    /*
    i retStr'="" s retValue="alert('"_$ZCVT(retStr,"O","JS")_"');findPatientTree();"
    i retStr="" s retValue="findPatientTree();"
    &javascript<#(retValue)#>
    */
    q retStr
}

/// cy20190605 
/// 门诊点名字呼叫
ClassMethod FrontQueueInsert(EpisodeID As %String = "", LocID As %String = "", UserID As %String = "", IPAddress As %String = "", MarkID As %String = "") As %String
{
	i LocID="" s LocID=%session.Get("LOGON.CTLOCID")
    i UserID="" s UserID=%session.Get("LOGON.USERID")
    i MarkID="" s MarkID=%session.Get("MarkSelectDr")
    //i IPAddress="" s IPAddress=$ZUTIL(67,15,$JOB)
    i IPAddress="" s IPAddress=%session.Data("REMOTE_ADDR")
    s IPAddress=$$upper^SSUTIL4(IPAddress)
    s activeFlag=..GetActiveFlag(IPAddress)
    s waitEndAdm=""
    /*
    i activeFlag'=0 d
    .s retValue="alert('"_$ZCVT(activeFlag,"O","JS")_"');findPatientTree();"
    .&javascript<#(retValue)#>
    */
    q:activeFlag'=0 activeFlag
    s calledStatus=..CheckCalledStatus(EpisodeID,UserID)
    /*
    i calledStatus'="0" d
    .s retValue="alert('"_$ZCVT(calledStatus,"O","JS")_"');findPatientTree();"
    .&javascript<#(retValue)#>
    */
    q:calledStatus'="0" calledStatus
    
	s retStr="7^超出最多呼叫人数!",retValue="",WaitExsitFlag=0,DocHisID="",ctpcpDesc=""
	s CKScreenStr="!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",DocInfoStr="!!!!!!!!!!"
    s QueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeID,""))
	s oref=##Class(User.DHCQueue).%OpenId(QueRowId)
	s patName=oref.QueName
	s queNo=oref.QueNo
	s QueMarkDr=oref.QueMarkDrGetObjectId()
	i QueMarkDr'="" s ctpcpDesc=$P($g(^CTPCP(QueMarkDr,1)),"^",2)  //号别
	s docDr=##Class(web.SSUser).GetDefaultCareProvider(UserID)
	i docDr'="" s DocHisID=$P($G(^CTPCP(docDr,1)),"^",1) 
	i docDr'="" s docDesc=$P($G(^CTPCP(docDr,1)),"^",2)  //姓名
	s DocTypeDesc=..GetDocTypeDesc(UserID)  //职称
	s $P(DocInfoStr,"!",1)=$$upper^SSUTIL4(ctpcpDesc)
	s $P(DocInfoStr,"!",2)=$$upper^SSUTIL4(DocHisID)
    s $P(DocInfoStr,"!",3)=$$upper^SSUTIL4(UserID)
	s $P(DocInfoStr,"!",4)=$$upper^SSUTIL4(LocID)
	s $P(DocInfoStr,"!",5)=$$upper^SSUTIL4(MarkID)
	s PAAdmPriority=oref.QueFirstDr.FirstcName
	s walkStatus=oref.QueStateDr.PersName
	s Priority="平诊"
	i PAAdmPriority="优先" s Priority="优诊"
	i walkStatus="复诊" s Priority="复诊"
	i walkStatus="到达" s Priority="复诊"
	i $d(^RBAS("PAADM_DR",EpisodeID)) s Priority="预约"
    d oref.%Close()
	//d ..InsertClientInfo(IPAddress,"",QueMarkDr)
    s PAAdmRoom=..GetRoom(IPAddress)
    s LocDesc=$P($G(^CTLOC(LocID)),"^",2)
    i $P(LocDesc,"-",2)'="" s LocDesc=$P(LocDesc,"-",2)
    i queNo'["号"  s queNo=queNo_"号"
	s $P(CKScreenStr,"!",1)=$$upper^SSUTIL4(LocDesc)
	s $P(CKScreenStr,"!",2)=$$upper^SSUTIL4(PAAdmRoom)
	s $P(CKScreenStr,"!",3)=$$upper^SSUTIL4(docDesc)
	s $P(CKScreenStr,"!",4)=$$upper^SSUTIL4(DocTypeDesc)
	s $P(CKScreenStr,"!",5)=$$upper^SSUTIL4(queNo)
	s $P(CKScreenStr,"!",6)=$$upper^SSUTIL4(patName)
	s ZHScreenStr=PAAdmRoom_" "_LocDesc_" "_docDesc_" "_queNo_" "_patName_" "_Priority  //不在走FromatZHStr
	s ZHScreenStr=QueRowId_"*"_ZHScreenStr
	s Note=PAAdmRoom_"   "_docDesc_"   "_queNo_"-"_patName_"  "_LocDesc
    s clientId="",serverId="",serverName=""
    s clientId=$O(^DHCVISClienti(0,"ClientIP",IPAddress,""))
	q:clientId="" "1^未配置客户端"
	s serverId=$P($G(^DHCVISClient(clientId)),"^",1)
	s clientName=$P($G(^DHCVISClient(clientId)),"^",3)
	q:serverId="" "2^未关联服务器"
	s serverName=$P($G(^DHCVISServer(serverId)),"^",2)
	i (+queNo)=0 s voiceContent="请 "_patName_" 到 "_PAAdmRoom_" 就诊"
	e  s voiceContent="请 "_queNo_" "_patName_" 到 "_PAAdmRoom_" 就诊"
	//s ^cy(+$h)=EpisodeID_","_LocID_","_UserID_","_MarkID_","_IPAddress
    s WaitPerList=..GetTwoWaiter(EpisodeID,LocID,UserID,MarkID,IPAddress)
    s WaitPersons=$P(WaitPerList,"%")
    i (WaitPersons'="")&&($G(voiceContent)'="") d
    .s voiceContent=voiceContent_",请 "_WaitPersons_" 等候"
	.s EpisodeIDStr=$p($g(WaitPerList),"%",2)
	.q:EpisodeIDStr=""
	.s num=$l(EpisodeIDStr,",")
	.for j=1:1:num  d
	..s WaitEpisodeID=$p(EpisodeIDStr,",",j)
	..s updateWaitStatusFlag = ##Class(web.DHCDocOutPatientList).SetCallStatus(WaitEpisodeID,docDr,2,IPAddress,j)
	..//i updateWaitStatusFlag'=1 s retValue="更新队列状态失败!"
    ..s QueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",WaitEpisodeID,""))
	..s oref=##Class(User.DHCQueue).%OpenId(QueRowId)
	..s patNameWait=oref.QueName
	..s queNoWait=oref.QueNo
	..d oref.%Close()
	..s $P(CKScreenStr,"!",j+6)=queNoWait_"号-"_patNameWait
	..s waitEndAdm=WaitEpisodeID
	i waitEndAdm'="" s ^DHCDocSetArrive(UserID,+$H,"Call")=$G(^DHCDocOutPatientList("WartInd",waitEndAdm))

	s WaitList=$P(WaitPerList,"%",3)
	i (($G(EpisodeID)'="")&&($P($G(voiceContent),",",1)'=""))   d
	.s updateStatusFlag = ##Class(web.DHCDocOutPatientList).SetCallStatus(EpisodeID,docDr,"",IPAddress)
	.i updateStatusFlag'=1 s retStr="5^更新队列状态失败!"
	.q:updateStatusFlag'=1
    .s insertFlag=##Class(web.DHCVISVoiceCall).InsertVoiceQueue(voiceContent,UserID,IPAddress,"A","LR","N",ZHScreenStr,CKScreenStr,WaitList,Note,DocInfoStr,EpisodeID)
    .i insertFlag'=0 s retStr="6^"_insertFlag
    .q:insertFlag'=0
    .i waitEndAdm="" s ^DHCDocSetArrive(UserID,+$H,"Call")=$G(^DHCDocOutPatientList("WartInd",EpisodeID))
    .s retStr="0^正在呼叫:"_queNo_patName_"..."
    /*
    i retValue'="" s retValue="alert('"_$ZCVT(retValue,"O","JS")_"');findPatientTree();"
    i retValue="" s retValue="findPatientTree();"
    &javascript<#(retValue)#>
    */
    q retStr
}

ClassMethod GetTwoWaiter(EpisodeID As %String = "", LocID As %String = "", UserID As %String = "", MarkID As %String = "", IPAddress As %String = "") As %String
{
	/*
	普通号无等候 
	s QueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeID,""))
	s oref=##Class(User.DHCQueue).%OpenId(QueRowId)
	s QueMarkDr=oref.QueMarkDrGetObjectId()
	i QueMarkDr'="" s ctpcpDesc=$P($g(^CTPCP(QueMarkDr,1)),"^",2)
	Q:ctpcpDesc["普通号" ""
	*/
	i LocID="" s LocID=%session.Get("LOGON.CTLOCID")
    i UserID="" s UserID=%session.Get("LOGON.USERID")
    i MarkID="" s MarkID=%session.Get("MarkSelectDr")
    //i IPAddress="" s IPAddress=$ZUTIL(67,15,$JOB)
    i IPAddress="" s IPAddress=%session.Data("REMOTE_ADDR")
    s IPAddress=$$upper^SSUTIL4(IPAddress)
    s retStr="",retValue=""
	s AllPatient="",PatientNo="",SurName="",ArrivedQue=""
	s patIndex=0,i=0,WaitTwoStr="",WaitTwo="",WaitingStr="",EpisodeIDStr="",num=0,j=0
    s StartDate=+$H
    s EndDate=+$H
    s RegQue="on"
    s insertFlag=0
    s waitPersons=+$G(^DHCVISSet("DHCVISWaiting"))  //获取等候
    s TwoWaiterPersons=+$G(^DHCVISSet("TwoWaiter")) //获取呼叫等候
    s WaitList="",WaitListNo=""
    s rs=##Class(%ResultSet).%New("web.DHCDocOutPatientList:FindLocDocCurrentAdm")
	i rs.QueryIsValid() {
		Set Status=rs.Execute(LocID,UserID,IPAddress,AllPatient,PatientNo,SurName,StartDate,EndDate,ArrivedQue,RegQue,"",MarkID,"")
		Set columns = rs.GetColumnCount()
		If 'Status Quit
		While rs.Next() 
		{
			q:(num-(waitPersons-2)>0)
			s WalkStatus=rs.GetDataByName("WalkStatus")
            s calledFlag=rs.GetDataByName("Called")
			s WaitRegRangeTime=rs.GetDataByName("RegRangeTime")    
		    // 显示同一时间段的患者
			s RegRangeTimeDr=""
			s RegfeeDr=$O(^User.DHCRegistrationFeeI("ADM"," "_EpisodeID,""))
			i RegfeeDr'="" s RegRangeTimeDr=$LIST(^User.DHCRegistrationFeeD(RegfeeDr),21)
			//q:(WaitRegRangeTime'=RegRangeTimeDr)
			i (WalkStatus'="过号")&&(WalkStatus'="到达")&&(WalkStatus'="退号")&&(calledFlag'="1") d
			.s WaitEpisodeID=rs.GetDataByName("EpisodeID")
			.q:WaitEpisodeID=""
			.s WaitpatName=rs.GetDataByName("PAPMIName") 
			.s locSeqNo=rs.GetDataByName("LocSeqNo")
			.s locSeqNo=$tr(locSeqNo," ","")
			.i locSeqNo'["号" s locSeqNo=locSeqNo_"号"
			.q:EpisodeID=WaitEpisodeID
			.s QueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",WaitEpisodeID,""))
			.q:QueRowId=""
			.s QueObj=##Class(User.DHCQueue).%OpenId(QueRowId)
	        .s QueDoc=QueObj.QueDocDrGetObjectId()
			.s DocId=$p($g(^SSU("SSUSR",UserID)),"^",14)
			.q:(QueDoc'=DocId)&&(QueDoc'="")
			.// 等候队列
			.s QueRowlocSeqNo=QueRowId_"*"_locSeqNo
			.i WaitingStr=""  s WaitingStr=QueRowlocSeqNo
			.e  s WaitingStr=WaitingStr_","_QueRowlocSeqNo 
			.i (num<TwoWaiterPersons)&&(TwoWaiterPersons'=0)  d
			..//等候就诊ID
			..i EpisodeIDStr="" s EpisodeIDStr=WaitEpisodeID
			..e  s EpisodeIDStr=EpisodeIDStr_","_WaitEpisodeID
			..// 等候患者
		    ..s WaitPat=locSeqNo_"-"_WaitpatName
			..i WaitTwo=""  s WaitTwo=WaitPat
			..e  s WaitTwo=WaitTwo_" "_WaitPat
			.s num=num+1
		} 
    }
	q WaitTwo_"%"_EpisodeIDStr_"%"_WaitingStr
}

/// W ##Class(web.DHCVISQueueManage).GetDocTypeDesc(1)
ClassMethod GetDocTypeDesc(UserId As %String = "") As %String
{
	q:UserId="" ""  
	s CTPCPDR=$P($G(^SSU("SSUSR",UserId)),"^",14)
	q:CTPCPDR="" ""
    s CarPrvTpDr= $p($g(^CTPCP(CTPCPDR,"1")),"^",4)
    q:CarPrvTpDr="" ""
    s CarPrvTpDesc=$p($g(^CT("CPT",CarPrvTpDr)),"^",2)
    q CarPrvTpDesc
}

ClassMethod GetActiveFlag(clientIP As %String = "") As %String
{
	//i $G(clientIP)="" s clientIP=$ZUTIL(67,15,$JOB)
	//s ^cy(+$H)=clientIP
	i clientIP="" s clientIP=%session.Data("REMOTE_ADDR")
	s clientIP=$$upper^SSUTIL4(clientIP)
    s clientId=$O(^DHCVISClienti(0,"ClientIP",clientIP,""))
	q:clientId="" "1^未配置客户端"_clientIP
	s serverId=$P($G(^DHCVISClient(clientId)),"^",1)
	q:serverId="" "2^未关联服务器"
	s serverActive=$P($G(^DHCVISServer(serverId)),"^",3)
	q:serverActive'="Y" "3^服务器未激活"
	q 0
}

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

ClassMethod GetRoom(clientIP As %String) As %String
{
	i $G(clientIP)="" s clientIP=%session.Data("REMOTE_ADDR")
	i $G(clientIP)="" s clientIP=$ZUTIL(67,15,$JOB)
	s clientIP=$$upper^SSUTIL4(clientIP)
    s clientId=$O(^DHCVISClienti(0,"ClientIP",clientIP,""))
	q:clientId="" ""
	s clientName=$P($G(^DHCVISClient(clientId)),"^",3)
    q clientName
}

/// cy20190611
/// 顺序叫：新产品用
/// W ##Class(web.DHCVISQueueManage).RunNextButtonNewProEm("203","11841","192.168.43.43") 
ClassMethod RunNextButtonNewProEm(LocID As %String = "", UserID As %String = "", IPAddress As %String = "", QueType As %String = "Per") As %String
{
	s retStr="8^获取呼叫队列失败",retValue=""
	i LocID="" s LocID=%session.Get("LOGON.CTLOCID")
    i UserID="" s UserID=%session.Get("LOGON.USERID")
    i IPAddress="" s IPAddress=%session.Data("REMOTE_ADDR")
    s:IPAddress'="" IPAddress=$$upper^SSUTIL4(IPAddress)
    s QueType="Per"
    s activeFlag=..GetActiveFlag(IPAddress)
    /*
    i activeFlag'=0 d
    .s retValue="alert('"_$ZCVT(activeFlag,"O","JS")_"')" 
    .&javascript<#(retValue)#>
    */
    q:activeFlag'=0 activeFlag
    s admPersons=+$G(^DHCVISSet("DHCVISAdm"))
    i admPersons=0 s admPersons=1
    s waitPersons=+$G(^DHCVISSet("DHCVISWaiting"))
    s DocListStDate = +$h-1
    s DocListEndDate = +$h
    s WaitList="",WaitListNo="",DocInfoStr="!!!!!!!!!!!",WaitNo=1
    s patIndex=0
    s insertFlag=0
    s InParam="^^^"_QueType_"^^"_DocListStDate_"^"_DocListEndDate_"^N^^^^^"_LocID_"^"_UserID_"^^"
    s rs=##Class(%ResultSet).%New("web.DHCEMDocMainOutPat:QueryEmDocMainPatListA")    
	i rs.QueryIsValid() {
		//Set Status=rs.Execute("","","",QueType,"",DocListStDate,DocListEndDate,"N","","","","",LocID,UserID,"","")
		Set Status=rs.Execute(InParam)
		Set columns = rs.GetColumnCount()
		If 'Status Quit
		While rs.Next() {
			s PaAdm=$P(rs.%GetData(2),$C(13,10))
			s WalkStatus=##Class(web.DHCEMDocMainOutPat).GetPatCurStat(PaAdm)
			i WalkStatus'="" Set WalkStatus=$P(WalkStatus,"^",2)  //到达
			s PAAdmWard=$P(rs.%GetData(15),$C(13,10))  			  ///当前病区 
			s NurseLevel=$P(rs.%GetData(46),$C(13,10))
			;Continue:NurseLevel="1级"
			;Continue:NurseLevel="2级"
			Continue:(WalkStatus["到达")||(PAAdmWard'="") 
			s patIndex=patIndex+1
			i (patIndex>admPersons)&&(retStr="") s retStr="4^请处理完正在呼叫的患者,再呼叫新患者!"
			q:((patIndex>admPersons)&&((waitPersons+admPersons)-patIndex<0))
			s calledFlag=$P(rs.%GetData(37),$C(13,10))
			i calledFlag="1" s retStr="4^请处理完正在呼叫的患者,再呼叫新患者!"
			q:(calledFlag="1") 
			q:(insertFlag="1")
			i patIndex=admPersons d
			.s EpisodeID=$P(rs.%GetData(2),$C(13,10))
			.s patName=$P(rs.%GetData(5),$C(13,10))
			.i NurseLevel'="" s NurseLevel=$case(+NurseLevel,1:"Ⅰ级",2:"Ⅱ级",3:"Ⅲ级",4:"Ⅳa级",5:"Ⅳb级")
			.i NurseLevel'="" d
			..s NurseLevel=##class(web.DHCEMCommonUtil).GetTrans("dhcem.patlist.csp",NurseLevel)
			..s patName=patName_"("_NurseLevel_")"
			.s locSeqNo=$P(rs.%GetData(28),$C(13,10))
			.i locSeqNo'["号" s locSeqNo=locSeqNo_"号"
			.s patRegNo=$P(rs.%GetData(4),$C(13,10))   
			.s PAAdmDepCodeDRhz=$P(rs.%GetData(11),$C(13,10)) //科室名称  
			.i $P(PAAdmDepCodeDRhz,"-",2)'="" s PAAdmDepCodeDRhz=$P(PAAdmDepCodeDRhz,"-",2)        
			.s docDr=##Class(web.SSUser).GetDefaultCareProvider(UserID)   //rs.GetData(12)
			.i docDr'="" s docDesc=$P($G(^CTPCP(docDr,1)),"^",2),DocHisID=$P($G(^CTPCP(docDr,1)),"^",1)
			.e  s docDesc=""
			.s PAAdmRoom=..GetRoom(IPAddress)
			.i PAAdmRoom="" s retStr="1^未配置客户端!"
			.q:PAAdmRoom=""
			.s PAAdmPriority=$P(rs.%GetData(29),$C(13,10)) //优先级
			.i (+locSeqNo)=0 s voiceContent="请 "_patName_" 到 "_PAAdmRoom_" 就诊"
			.e  s voiceContent="请 "_locSeqNo_" "_patName_" 到 "_PAAdmRoom_" 就诊"
			.s Note=PAAdmRoom_"   "_docDesc_"   "_locSeqNo_"-"_patName_"  "_PAAdmDepCodeDRhz
			.s regDoc=$P(rs.%GetData(22),$C(13,10)) // 号别
			.s regDocDesc=$P(regDoc,"(")
			.s $P(DocInfoStr,"!",1)=$$upper^SSUTIL4(regDoc)
			.s $P(DocInfoStr,"!",2)=$$upper^SSUTIL4(DocHisID)
			.s $P(DocInfoStr,"!",3)=$$upper^SSUTIL4(UserID)
			.s $P(DocInfoStr,"!",4)=$$upper^SSUTIL4(LocID)
			.s ZHScreenStr=PAAdmRoom_" "_PAAdmDepCodeDRhz_" "_regDocDesc_" "_locSeqNo_" "_patName_" "_PAAdmPriority  //不在走FromatZHStr
			.//s ZHScreenStr=QueRowId_"*"_ZHScreenStr
			.s QueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeID,""))
			.q:QueRowId=""
			.s ZHScreenStr=QueRowId_"*"_ZHScreenStr
			.s CKScreenStr=""
			.s DocTypeDesc=..GetDocTypeDesc(UserID)
			.s $P(CKScreenStr,"!",1)=$$upper^SSUTIL4(PAAdmDepCodeDRhz)
			.s $P(CKScreenStr,"!",2)=$$upper^SSUTIL4(PAAdmRoom)
			.s $P(CKScreenStr,"!",3)=$$upper^SSUTIL4(docDesc)
			.s $P(CKScreenStr,"!",4)=$$upper^SSUTIL4(DocTypeDesc)
			.s $P(CKScreenStr,"!",5)=$$upper^SSUTIL4(locSeqNo)
			.s $P(CKScreenStr,"!",6)=$$upper^SSUTIL4(patName)
			e  d
			.s locSeqNoT=$P(rs.%GetData(28),$C(13,10))
			.s EpisodeIDT=$P(rs.%GetData(2),$C(13,10))
			.s patNameT=$P(rs.%GetData(5),$C(13,10))  
			.s QueRowIdT=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeIDT,""))
			.q:QueRowIdT="" 
			.s QueDocDr=$List(^User.DHCQueueD(QueRowIdT),5)
			.q:(QueDocDr'="")&&(QueDocDr'=docDr)
			.s locSeqNoTS=QueRowIdT_"*"_locSeqNoT
			.i WaitListNo="" s WaitListNo=locSeqNoTS
			.e  s WaitListNo=WaitListNo_","_locSeqNoTS
			.s WaitIndex=$L(WaitListNo,",")
			.s $P(CKScreenStr,"!",WaitIndex+6)=$$upper^SSUTIL4(locSeqNoT_"号-"_patNameT)
			.s TwoWaiterPersons=+$G(^DHCVISSet("TwoWaiter"))
			.i (TwoWaiterPersons'=0) d
			..q:(WaitNo>TwoWaiterPersons)
			..i voiceContent'="" s voiceContent=voiceContent_",请 "_patNameT_" 等候"
			..s updateWaitStatusFlag = ##Class(web.DHCDocOutPatientList).SetCallStatus(EpisodeIDT,docDr,2,IPAddress,WaitNo)
			..//i updateWaitStatusFlag'=1 s retValue="更新队列状态失败!"
			..s WaitNo=WaitNo+1
	
		} 
    }
	
	i (($G(EpisodeID)'="")&&($P($G(voiceContent),",",1)'="")) d
	.// 先改状态在插表
	.s updateCallStatusFlag = ##Class(web.DHCDocOutPatientList).SetCallStatus(EpisodeID,docDr,"",IPAddress)
	.i updateCallStatusFlag'=1 s retStr="5^更新队列状态失败!"
	.q:updateCallStatusFlag'=1
	.s WaitList=WaitListNo
	.s insertFlag=##Class(web.DHCVISVoiceCall).InsertVoiceQueue(voiceContent,UserID,IPAddress,"A","LR","N",ZHScreenStr,CKScreenStr,WaitList,Note,DocInfoStr,EpisodeID)
    .i insertFlag'=0 s retStr="6^"_insertFlag
    .q:insertFlag'=0
    .s noDesc=##class(web.DHCEMCommonUtil).GetTrans("dhcem.patlist.csp","号")
    .i locSeqNo["号" d
    ..s templocSeqNo=$p(locSeqNo,"号",1)
    ..s locSeqNo=templocSeqNo_noDesc
    .s callName=##class(web.DHCEMCommonUtil).GetTrans("dhcem.patlist.csp","正在呼叫")
    .s retStr="0^"_callName_" "_locSeqNo_" "_patName
    .s insertFlag=1
    /*
    i retStr'="" s retValue="alert('"_$ZCVT(retStr,"O","JS")_"');findPatientTree();"
    i retStr="" s retValue="findPatientTree();"
    &javascript<#(retValue)#>
    */
    q retStr
}

/// cy20190612
/// 急诊医生重复叫号
ClassMethod RecallButtonNewProEm(LocID As %String = "", UserID As %String = "", IPAddress As %String = "", QueType As %String = "Per") As %String
{
	s retStr="8^获取呼叫队列失败",retValue=""
	i LocID="" s LocID=%session.Get("LOGON.CTLOCID")
    i UserID="" s UserID=%session.Get("LOGON.USERID")
    i IPAddress="" s IPAddress=%session.Data("REMOTE_ADDR")
    s IPAddress=$$upper^SSUTIL4(IPAddress)
    s DocInfoStr="!!!!!!!!!!!"
    s activeFlag=..GetActiveFlag(IPAddress)
    /*
    i activeFlag'=0 d
    .s retValue="alert('"_$ZCVT(activeFlag,"O","JS")_"')" 
    .&javascript<#(retValue)#>
    */
    q:activeFlag'=0 activeFlag
    s admPersons=+$G(^DHCVISSet("DHCVISAdm"))
    i admPersons=0 s admPersons=1
    s waitPersons=+$G(^DHCVISSet("DHCVISWaiting"))
    s patIndex=0
    s insertFlag=0  
    s DocListStDate =+$h-1
    s DocListEndDate =+$h 
	//1:表中有数据的取数据；2.表中没数据的取Query
    s QueueId=$O(^DHCVISQueuei(0,"CreateUser",UserID,""),-1)
	i (QueueId'="") d
	.s VoiceQueueStr=$G(^DHCVISQueue(QueueId))
	.q:VoiceQueueStr=""
	.s EpisodeIDOld=$P(VoiceQueueStr,"^",23)
	.s DHCQueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeIDOld,""))
	.q:(DHCQueRowId="")
	.s WalkStatus=##Class(web.DHCEMDocMainOutPat).GetPatCurStat(EpisodeIDOld)
	.q:WalkStatus["到达"
	.s oref=##Class(User.DHCQueue).%OpenId(DHCQueRowId)
	.i (oref'="") d
	..s Status=""
	..s Status=oref.QueStateDr.PersName
	..i ((Status="到达")||(Status="退号")||(Status="过号")||(Status="")) s DHCQueRowId=""
	..s QueMarkDr=oref.QueMarkDrGetObjectId()
	..i QueMarkDr'="" s ctpcpDesc=$P($g(^CTPCP(QueMarkDr,1)),"^",2) 
	..e  s ctpcpDesc=""
	..d oref.%Close()
    ..s docDr=##Class(web.SSUser).GetDefaultCareProvider(UserID)
	..i docDr'="" s docDesc=$P($G(^CTPCP(docDr,1)),"^",2)
	..e  s docDesc=""
	..i docDr'="" s DocHisID=$P($G(^CTPCP(docDr,1)),"^",1)
    ..e  s DocHisID=""
	..i (ctpcpDesc="")||(DocHisID="")||(UserID="")||(LocID="") s DHCQueRowId=""
    ..q:(DHCQueRowId="")
    ..s $P(DocInfoStr,"!",1)=$$upper^SSUTIL4(ctpcpDesc)
    ..s $P(DocInfoStr,"!",2)=$$upper^SSUTIL4(DocHisID)
	..s $P(DocInfoStr,"!",3)=$$upper^SSUTIL4(UserID)
	..s $P(DocInfoStr,"!",4)=$$upper^SSUTIL4(LocID)  
	..s voiceContent=$P(VoiceQueueStr,"^",4)
	..s ZHScreenStr=$P(VoiceQueueStr,"^",17)
	..s CKScreenStr=$P(VoiceQueueStr,"^",18)
	..s WaitList=$P(VoiceQueueStr,"^",19)
	..s Note=$P(VoiceQueueStr,"^",20)
	..s patName=$P(CKScreenStr,"!",6)
	..s locSeqNo=$P(CKScreenStr,"!",5)
	..s insertFlag=##Class(web.DHCVISVoiceCall).InsertVoiceQueue(voiceContent,UserID,IPAddress,"A","LR","N",ZHScreenStr,CKScreenStr,WaitList,Note,DocInfoStr,EpisodeIDOld)
    ..i insertFlag'=0 s retStr="6^"_insertFlag
    ..q:insertFlag'=0
    ..s callName=##class(web.DHCEMCommonUtil).GetTrans("dhcem.patlist.csp","正在呼叫")
    ..s noDesc=##class(web.DHCEMCommonUtil).GetTrans("dhcem.patlist.csp","号")
    ..i locSeqNo["号" d
    ...s templocSeqNo=$p(locSeqNo,"号",1)
    ...s locSeqNo=templocSeqNo_noDesc
    ..i patName["(" d
    ...s tempPatName=$p(patName,"(",1)
    ...s NurseLevel=$p($p(patName,"(",2),")")
    ...s NurseLevel=##class(web.DHCEMCommonUtil).GetTrans("dhcem.patlist.csp",NurseLevel)
    ...s patName=tempPatName_"("_NurseLevel_")"
    ..s retStr="0^"_callName_" "_locSeqNo_" "_patName
    i ((QueueId="")||(DHCQueRowId="")) {
	   s InParam="^^^"_QueType_"^^"_DocListStDate_"^"_DocListEndDate_"^N^^^^^"_LocID_"^"_UserID_"^^"
       s rs=##Class(%ResultSet).%New("web.DHCEMDocMainOutPat:QueryEmDocMainPatListA")    
	   i rs.QueryIsValid() {
	   //Set Status=rs.Execute("","","",QueType,"",DocListStDate,DocListEndDate,"N","","","","",LocID,UserID,"","")
	   Set Status=rs.Execute(InParam)
	   Set columns = rs.GetColumnCount()
	   If 'Status Quit
	   While rs.Next() {
	    	s PaAdm=$P(rs.%GetData(2),$C(13,10))
			s WalkStatus=##Class(web.DHCEMDocMainOutPat).GetPatCurStat(PaAdm)
			i WalkStatus'="" Set WalkStatus=$P(WalkStatus,"^",2)  //到达
			s PAAdmWard=$P(rs.%GetData(15),$C(13,10))  			  ///当前病区 
			Continue:(WalkStatus["到达")||(PAAdmWard'="")         ///过滤未就诊
			s NurseLevel=$P(rs.%GetData(46),$C(13,10))
			Continue:((NurseLevel="1级")||(NurseLevel="2级"))
			s patIndex=patIndex+1		
			//i walkStatus="过号"  s retStr="过号患者须重新报到后才能呼叫!"
			//q:walkStatus="过号"
			i (patIndex>admPersons)&&(retStr="") s retStr="7^超出最多呼叫人数!"
			q:(patIndex>admPersons) 	
		    i ((WalkStatus'="到达")&&(WalkStatus'="退号")) d
			.s calledFlag=$P(rs.%GetData(37),$C(13,10))
			.q:(calledFlag="")
			.q:(insertFlag=1)
			.s EpisodeID=$P(rs.%GetData(2),$C(13,10))
			.s retStr=..FrontQueueInsertNewProEm(EpisodeID,LocID,UserID,IPAddress)
            .i $p(retStr,"^",1)=0 s insertFlag=1
		} 
      }
    }
    /*
    i retStr'="" s retValue="alert('"_$ZCVT(retStr,"O","JS")_"');findPatientTree();"
    i retStr="" s retValue="findPatientTree();"
    &javascript<#(retValue)#>
    */
    q retStr
}

/// cy20190612
/// 新产品点名字
ClassMethod FrontQueueInsertNewProEm(EpisodeID As %String = "", LocID As %String = "", UserID As %String = "", IPAddress As %String = "") As %String
{
    i LocID="" s LocID=%session.Get("LOGON.CTLOCID")
    i UserID="" s UserID=%session.Get("LOGON.USERID")
    //i IPAddress="" s IPAddress=$ZUTIL(67,15,$JOB)
    i IPAddress="" s IPAddress=%session.Data("REMOTE_ADDR")
    s IPAddress=$$upper^SSUTIL4(IPAddress)
    s activeFlag=..GetActiveFlag(IPAddress)
    /*
    i activeFlag'=0 d
    .s retValue="alert('"_$ZCVT(activeFlag,"O","JS")_"');findPatientTree();"
    .&javascript<#(retValue)#>
    */
    q:activeFlag'=0 activeFlag
    s calledStatus=..CheckCalledStatus(EpisodeID,UserID)
    /*
    i calledStatus'="0" d
    .s retValue="alert('"_$ZCVT(calledStatus,"O","JS")_"');findPatientTree();"
    .&javascript<#(retValue)#>
    */
    q:calledStatus'="0" calledStatus
    
	s retStr="7^超出最多呼叫人数!",retValue="",WaitExsitFlag=0,DocHisID="",ctpcpDesc=""
	s CKScreenStr="!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",DocInfoStr="!!!!!!!!!!"
    s QueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeID,""))
	s oref=##Class(User.DHCQueue).%OpenId(QueRowId)
	s patName=oref.QueName
	s queNo=oref.QueNo
	s QueMarkDr=oref.QueMarkDrGetObjectId()
	i QueMarkDr'="" s ctpcpDesc=$P($g(^CTPCP(QueMarkDr,1)),"^",2)  //号别
	s docDr=##Class(web.SSUser).GetDefaultCareProvider(UserID)
	i docDr'="" s DocHisID=$P($G(^CTPCP(docDr,1)),"^",1) 
	i docDr'="" s docDesc=$P($G(^CTPCP(docDr,1)),"^",2)  //姓名
	s DocTypeDesc=..GetDocTypeDesc(UserID)  //职称
	s $P(DocInfoStr,"!",1)=$$upper^SSUTIL4(ctpcpDesc)
	s $P(DocInfoStr,"!",2)=$$upper^SSUTIL4(DocHisID)
    s $P(DocInfoStr,"!",3)=$$upper^SSUTIL4(UserID)
	s $P(DocInfoStr,"!",4)=$$upper^SSUTIL4(LocID)
	s PAAdmPriority=oref.QueFirstDr.FirstcName
	s walkStatus=oref.QueStateDr.PersName
	s Priority="平诊"
	i PAAdmPriority="优先" s Priority="优诊"
	i walkStatus="复诊" s Priority="复诊"
	i walkStatus="到达" s Priority="复诊"
	i $d(^RBAS("PAADM_DR",EpisodeID)) s Priority="预约"
    d oref.%Close()
	//d ..InsertClientInfo(IPAddress,"",QueMarkDr)
	s EmPCLvID="",NurseLevel=""
    s EmPCLvID=$o(^DHCEMPCA(0,"AdmChkLev",+EpisodeID,""),-1) /// 分诊ID
    i EmPCLvID'="" s NurseLevel=$p(^DHCEMPCL(EmPCLvID),"^",7)
    i (NurseLevel'="")&&(NurseLevel'["级") s NurseLevel=NurseLevel_"级"
    i NurseLevel'="" s NurseLevel=$case(+NurseLevel,1:"Ⅰ级",2:"Ⅱ级",3:"Ⅲ级",4:"Ⅳa级",5:"Ⅳb级")
	i NurseLevel'="" d
	.s NurseLevel=##class(web.DHCEMCommonUtil).GetTrans("dhcem.patlist.csp",NurseLevel) 
	.s patName=patName_"("_NurseLevel_")"
	
    s PAAdmRoom=..GetRoom(IPAddress)
    s LocDesc=$P($G(^CTLOC(LocID)),"^",2)
    i $P(LocDesc,"-",2)'="" s LocDesc=$P(LocDesc,"-",2)
    i queNo'["号"  s queNo=queNo_"号"
	s $P(CKScreenStr,"!",1)=$$upper^SSUTIL4(LocDesc)
	s $P(CKScreenStr,"!",2)=$$upper^SSUTIL4(PAAdmRoom)
	s $P(CKScreenStr,"!",3)=$$upper^SSUTIL4(docDesc)
	s $P(CKScreenStr,"!",4)=$$upper^SSUTIL4(DocTypeDesc)
	s $P(CKScreenStr,"!",5)=$$upper^SSUTIL4(queNo)
	s $P(CKScreenStr,"!",6)=$$upper^SSUTIL4(patName)
	s ZHScreenStr=PAAdmRoom_" "_LocDesc_" "_docDesc_" "_queNo_" "_patName_" "_Priority  //不在走FromatZHStr
	s ZHScreenStr=QueRowId_"*"_ZHScreenStr
	s Note=PAAdmRoom_"   "_docDesc_"   "_queNo_"-"_patName_"  "_LocDesc
    s clientId="",serverId="",serverName=""
    s clientId=$O(^DHCVISClienti(0,"ClientIP",IPAddress,""))
	q:clientId="" "1^未配置客户端"
	s serverId=$P($G(^DHCVISClient(clientId)),"^",1)
	s clientName=$P($G(^DHCVISClient(clientId)),"^",3)
	q:serverId="" "2^未关联服务器"
	s serverName=$P($G(^DHCVISServer(serverId)),"^",2)
	i (+queNo)=0 s voiceContent="请 "_patName_" 到 "_PAAdmRoom_" 就诊"
	e  s voiceContent="请 "_queNo_" "_patName_" 到 "_PAAdmRoom_" 就诊"
	//s ^cy(+$h)=EpisodeID_","_LocID_","_UserID_","_MarkID_","_IPAddress
    s WaitPerList=..GetTwoWaiterNewProEm(EpisodeID,LocID,UserID,IPAddress,"Per")
    s WaitPersons=$P(WaitPerList,"%")
    i (WaitPersons'="")&&($G(voiceContent)'="") d
    .s voiceContent=voiceContent_",请 "_WaitPersons_" 等候"
	.s EpisodeIDStr=$p($g(WaitPerList),"%",2)
	.q:EpisodeIDStr=""
	.s num=$l(EpisodeIDStr,",")
	.for j=1:1:num  d
	..s WaitEpisodeID=$p(EpisodeIDStr,",",j)
	..s updateWaitStatusFlag = ##Class(web.DHCDocOutPatientList).SetCallStatus(WaitEpisodeID,docDr,2,IPAddress,j)
	..//i updateWaitStatusFlag'=1 s retValue="更新队列状态失败!"
    ..s QueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",WaitEpisodeID,""))
	..s oref=##Class(User.DHCQueue).%OpenId(QueRowId)
	..s patNameWait=oref.QueName
	..s queNoWait=oref.QueNo
	..d oref.%Close()
	..s $P(CKScreenStr,"!",j+6)=queNoWait_"号-"_patNameWait
	s WaitList=$P(WaitPerList,"%",3)
	i (($G(EpisodeID)'="")&&($P($G(voiceContent),",",1)'=""))   d
	.s updateStatusFlag = ##Class(web.DHCDocOutPatientList).SetCallStatus(EpisodeID,docDr,"",IPAddress)
	.i updateStatusFlag'=1 s retValue="5^更新队列状态失败!"
	.q:updateStatusFlag'=1
    .s insertFlag=##Class(web.DHCVISVoiceCall).InsertVoiceQueue(voiceContent,UserID,IPAddress,"A","LR","N",ZHScreenStr,CKScreenStr,WaitList,Note,DocInfoStr,EpisodeID)
    .i insertFlag'=0 s retStr="6^"_insertFlag
    .q:insertFlag'=0
    
    .s callName=##class(web.DHCEMCommonUtil).GetTrans("dhcem.patlist.csp","正在呼叫")
    .s noDesc=##class(web.DHCEMCommonUtil).GetTrans("dhcem.patlist.csp","号")
    .i queNo["号" d
    ..s templocSeqNo=$p(queNo,"号",1)
    ..s queNo=templocSeqNo_noDesc
   
    .s retStr="0^"_callName_queNo_patName
    /*
    i retValue'="" s retValue="alert('"_$ZCVT(retValue,"O","JS")_"');findPatientTree();"
    i retValue="" s retValue="findPatientTree();"
    &javascript<#(retValue)#>
    */
    q retStr
}

/// 新产品急诊叫号用:获取等候队列
/// EpisodeID,LocID,UserID,QueType
ClassMethod GetTwoWaiterNewProEm(EpisodeID As %String = "", LocID As %String = "", UserID As %String = "", IPAddress As %String = "", QueType As %String = "Per") As %String
{
	s retStr="",retValue=""
	i LocID="" s LocID=%session.Get("LOGON.CTLOCID")
    i UserID="" s UserID=%session.Get("LOGON.USERID")
    i IPAddress="" s IPAddress=%session.Data("REMOTE_ADDR")
    s IPAddress=$$upper^SSUTIL4(IPAddress)
    s patIndex=0,i=0,WaitTwoStr="",WaitTwo="",EpisodeIDStr="",num=0,j=0,WaitingStr=""
    s waitPersons=+$G(^DHCVISSet("DHCVISWaiting"))
    s TwoWaiterPersons=+$G(^DHCVISSet("TwoWaiter"))
    s insertFlag=0
    s WaitList="",WaitListNo=""
    s DocListStDate = +$h-1
    s DocListEndDate = +$h
    s InParam="^^^"_QueType_"^^"_DocListStDate_"^"_DocListEndDate_"^N^^^^^"_LocID_"^"_UserID_"^^"
    s rs=##Class(%ResultSet).%New("web.DHCEMDocMainOutPat:QueryEmDocMainPatListA")    
	i rs.QueryIsValid() {
		//Set Status=rs.Execute("","","",QueType,"",DocListStDate,DocListEndDate,"N","","","","",LocID,UserID,"","")
		Set Status=rs.Execute(InParam)
		Set columns = rs.GetColumnCount()
		If 'Status Quit
		While rs.Next() 
		{
			q:(num-(waitPersons-2)>0)
			s PaAdm=$P(rs.%GetData(2),$C(13,10))
			s WalkStatus=##Class(web.DHCEMDocMainOutPat).GetPatCurStat(PaAdm)
			//s WalkStatus=##Class(web.DHCEMDocMainOutPat).GetPatCurStat(PaAdm)
			i WalkStatus'="" Set WalkStatus=$P(WalkStatus,"^",2)  //到达
			s PAAdmWard=$P(rs.%GetData(15),$C(13,10))  			  ///当前病区 
			Continue:(WalkStatus["到达")||(PAAdmWard'="")
			s NurseLevel=$P(rs.%GetData(46),$C(13,10))
			Continue:(NurseLevel="1级")||(NurseLevel="2级") 
			s calledFlag=$P(rs.%GetData(37),$C(13,10))
			Continue:calledFlag="1"
			i (WalkStatus'="过号")&&(WalkStatus'="到达")&&(WalkStatus'="退号")&&(calledFlag'="1") d
			.s WaitEpisodeID=$P(rs.%GetData(2),$C(13,10)) 
			.q:WaitEpisodeID="" 
			.Continue:EpisodeID=WaitEpisodeID
			.s QueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",WaitEpisodeID,""))
			.q:QueRowId=""
			.s QueObj=##Class(User.DHCQueue).%OpenId(QueRowId)
	        .s QueDoc=QueObj.QueDocDrGetObjectId()
			.s DocId=$p($g(^SSU("SSUSR",UserID)),"^",14)
			.q:(QueDoc'=DocId)&&(QueDoc'="")
			.s WaitpatName=$P(rs.%GetData(5),$C(13,10))
			.s locSeqNo=$P(rs.%GetData(28),$C(13,10)) 
			.s locSeqNo=$tr(locSeqNo," ","")
			.i locSeqNo'["号" s locSeqNo=locSeqNo_"号"
			.// 等候队列
			.s QueRowlocSeqNo=QueRowId_"*"_locSeqNo
			.i WaitingStr=""  s WaitingStr=QueRowlocSeqNo
			.e  s WaitingStr=WaitingStr_","_QueRowlocSeqNo 
			.i (num<TwoWaiterPersons)&&(TwoWaiterPersons'=0)  d
			..//等候就诊ID
			..i EpisodeIDStr="" s EpisodeIDStr=WaitEpisodeID
			..e  s EpisodeIDStr=EpisodeIDStr_","_WaitEpisodeID
			..// 等候患者
		    ..s WaitPat=locSeqNo_"-"_WaitpatName
			..i WaitTwo=""  s WaitTwo=WaitPat
			..e  s WaitTwo=WaitTwo_" "_WaitPat
			.s num=num+1
	     } 
    }
	q WaitTwo_"%"_EpisodeIDStr_"%"_WaitingStr
}

/// 医生站急诊
/// cy20190612
/// w ##Class(web.DHCVISQueueManage).RunNextButton("1","4783","192.168.41.234)
ClassMethod RunNextButtonDocEm(LocID As %String = "", UserID As %String = "", IPAddress As %String = "", MarkID As %String = "") As %String
{
	s retStr="",retValue=""
	i LocID="" s LocID=%session.Get("LOGON.CTLOCID")
    i UserID="" s UserID=%session.Get("LOGON.USERID")
    //i IPAddress="" s IPAddress=$ZUTIL(67,15,$JOB)
    i IPAddress="" s IPAddress=%session.Data("REMOTE_ADDR")
    s IPAddress=$$upper^SSUTIL4(IPAddress)
    i MarkID="" s MarkID=%session.Get("MarkSelectDr")
    s activeFlag=..GetActiveFlag(IPAddress)
    i activeFlag'=0 d
    .s retValue="alert('"_$ZCVT(activeFlag,"O","JS")_"')" 
    .&javascript<#(retValue)#>
    q:activeFlag'=0 activeFlag
    //d ..InsertClientInfo(IPAddress)
    s StartDate=+$H
    s EndDate=+$H
    s RegQue="on"
    s Consultation="on"
    s AllPatient="",PatientNo="",SurName="",ArrivedQue=""
    s admPersons=+$G(^DHCVISSet("DHCVISAdm"))  //呼叫的人数
    i admPersons=0 s admPersons=1
    s waitPersons=+$G(^DHCVISSet("DHCVISWaiting"))  //获取等候人数
    s patIndex=0
    s insertFlag=0
    s WaitNo=1
    s WaitList="",WaitListNo="",CKScreenStr="!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",DocInfoStr="!!!!!!!!!!!"
    //"web.DHCDocEmergencyPatientList:FindLocDocCurrentAdm"
    s rs=##Class(%ResultSet).%New("web.DHCDocOutPatientList:FindLocDocCurrentAdmE")
	i rs.QueryIsValid() {
		//s waitPersons=waitPersons-1
		Set Status=rs.Execute(LocID,UserID,IPAddress,AllPatient,PatientNo,SurName,StartDate,EndDate,ArrivedQue,RegQue,"",MarkID,"")
		Set columns = rs.GetColumnCount()
		If 'Status Quit
		While rs.Next() {
			s patIndex=patIndex+1
			//呼叫+等候
			i (patIndex>admPersons)&&(retStr="") s retStr="请处理完绿色背景患者,再呼叫新患者!"
			q:((patIndex>admPersons)&&((waitPersons+admPersons)-patIndex<0))
			s WalkStatus=rs.GetDataByName("WalkStatus")
			continue:(WalkStatus="到达")||(WalkStatus="退号")
            //q:(patIndex>AdmWaitPersons) 
            s calledFlag=rs.GetDataByName("Called")
			i calledFlag=1  s retStr="请处理完绿色背景患者,再呼叫新患者!"
			q:calledFlag=1 
			q:(insertFlag=1)
			i patIndex=admPersons d
			.s EpisodeID=rs.GetDataByName("EpisodeID")
			.s patName=rs.GetDataByName("PAPMIName")      
			.s PAAdmDepCodeDR=rs.GetDataByName("PAAdmDepCodeDR")
			.i $P(PAAdmDepCodeDR,"-",2)'="" s PAAdmDepCodeDR=$P(PAAdmDepCodeDR,"-",2)        
			.s docDr=##Class(web.SSUser).GetDefaultCareProvider(UserID)
			.s docDesc=""   //号别
			.i docDr'="" s docDesc=$P($G(^CTPCP(docDr,1)),"^",2) 
			.s DocHisID=""  //医生工号 
			.i docDr'="" s DocHisID=$P($G(^CTPCP(docDr,1)),"^",1)
			.s PAAdmRoom=..GetRoom(IPAddress)
			.i PAAdmRoom="" s retStr="客户端未授权!"
			.q:PAAdmRoom=""
			.s PAAdmPriority=rs.GetDataByName("PAAdmPriority")
			.s Priority="平诊"
			.i PAAdmPriority="优先" s Priority="优诊"
			.i WalkStatus="复诊" s Priority="复诊"
			.i WalkStatus="到达" s Priority="复诊"
			.i $d(^RBAS("PAADM_DR",EpisodeID)) s Priority="预约"
			.s locSeqNo=rs.GetDataByName("LocSeqNo")
            .//i locSeqNo'["号" s locSeqNo=locSeqNo_"号"
			.i (+locSeqNo)=0 s voiceContent="请 "_patName_" 到 "_PAAdmRoom_" 就诊"
			.e  s voiceContent="请 "_locSeqNo_" "_patName_" 到 "_PAAdmRoom_" 就诊"
			.s Note=PAAdmRoom_"   "_docDesc_"   "_locSeqNo_"-"_patName_"  "_PAAdmDepCodeDR
			.s regDocDesc=rs.GetDataByName("RegDoctor") //号别
			.i $G(regDocDesc)="" s regDocDesc=docDesc
			.s QueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeID,""))
			.q:QueRowId=""
			.s oref=##Class(User.DHCQueue).%OpenId(QueRowId)
			.s QueMarkDr=oref.QueMarkDrGetObjectId()   
			.i QueMarkDr'="" s ctpcpDesc=$P($g(^CTPCP(QueMarkDr,1)),"^",2)   //号别描述
	        .i ctpcpDesc'="" s ctpcpDesc=$P(ctpcpDesc,"(")   
	        .d oref.%Close()
			.s $P(DocInfoStr,"!",1)=$$upper^SSUTIL4(ctpcpDesc)
			.s $P(DocInfoStr,"!",2)=$$upper^SSUTIL4(DocHisID)
			.s $P(DocInfoStr,"!",3)=$$upper^SSUTIL4(UserID)
			.s $P(DocInfoStr,"!",4)=$$upper^SSUTIL4(LocID)
			.s $P(DocInfoStr,"!",5)=$$upper^SSUTIL4(MarkID)
			.s ZHScreenStr=PAAdmRoom_" "_PAAdmDepCodeDR_" "_regDocDesc_" "_locSeqNo_" "_patName_" "_Priority  //不在走FromatZHStr
			.s ZHScreenStr=QueRowId_"*"_ZHScreenStr
			.s DocTypeDesc=..GetDocTypeDesc(UserID)
			.s $P(CKScreenStr,"!",1)=$$upper^SSUTIL4(PAAdmDepCodeDR)
			.s $P(CKScreenStr,"!",2)=$$upper^SSUTIL4(PAAdmRoom)
			.s $P(CKScreenStr,"!",3)=$$upper^SSUTIL4(docDesc)
			.s $P(CKScreenStr,"!",4)=$$upper^SSUTIL4(DocTypeDesc)
			.s $P(CKScreenStr,"!",5)=$$upper^SSUTIL4(locSeqNo)
			.s $P(CKScreenStr,"!",6)=$$upper^SSUTIL4(patName)
			e  d
			.s locSeqNoT=rs.GetDataByName("LocSeqNo")
			.s EpisodeIDT=rs.GetDataByName("EpisodeID")
			.s patNameT=rs.GetDataByName("PAPMIName")  
			.s QueRowIdT=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeIDT,""))
			.q:QueRowIdT="" 
			.s QueDocDr=$List(^User.DHCQueueD(QueRowIdT),5)
			.q:(QueDocDr'="")&&(QueDocDr'=docDr)
			.s locSeqNoTS=QueRowIdT_"*"_locSeqNoT
			.i WaitListNo="" s WaitListNo=locSeqNoTS
			.e  s WaitListNo=WaitListNo_","_locSeqNoTS
			.s WaitIndex=$L(WaitListNo,",")
			.s $P(CKScreenStr,"!",WaitIndex+6)=$$upper^SSUTIL4(locSeqNoT_"号-"_patNameT)
			.s TwoWaiterPersons=+$G(^DHCVISSet("TwoWaiter"))
			.i (TwoWaiterPersons'=0) d
			..q:(WaitNo>TwoWaiterPersons)
			..i voiceContent'="" s voiceContent=voiceContent_",请 "_patNameT_" 等候"
			..s updateWaitStatusFlag = ##Class(web.DHCDocOutPatientList).SetCallStatus(EpisodeIDT,docDr,2,IPAddress,WaitNo)
			..//i updateWaitStatusFlag'=1 s retValue="更新队列状态失败!"
			..s WaitNo=WaitNo+1
			
			
		} 
    }
	i (($G(EpisodeID)'="")&&($P($G(voiceContent),",",1)'="")) d
	.// 先改状态在插表
	.s updateCallStatusFlag = ##Class(web.DHCDocOutPatientList).SetCallStatus(EpisodeID,docDr,"",IPAddress)
	.i updateCallStatusFlag'=1 s retStr="更新队列状态失败!"
	.q:updateCallStatusFlag'=1
	.s WaitList=WaitListNo
	.s insertFlag=##Class(web.DHCVISVoiceCall).InsertVoiceQueue(voiceContent,UserID,IPAddress,"A","LR","N",ZHScreenStr,CKScreenStr,WaitList,Note,DocInfoStr,EpisodeID)
    .i insertFlag'=0 s retStr=insertFlag
    .q:insertFlag'=0
    .s retStr="正在呼叫"_" "_locSeqNo_" "_patName_"..."
    .s insertFlag=1
    i retStr'="" s retValue="alert('"_$ZCVT(retStr,"O","JS")_"');findPatientTree();"
    i retStr="" s retValue="findPatientTree();"
    &javascript<#(retValue)#>
    q ""
}

/// cy20190605
/// 门诊重复呼叫
ClassMethod RecallButtonDocEm(LocID As %String = "", UserID As %String = "", IPAddress As %String = "", MarkID As %String = "") As %String
{
	s retStr="",retValue=""
	i LocID="" s LocID=%session.Get("LOGON.CTLOCID")
    i UserID="" s UserID=%session.Get("LOGON.USERID")
    i MarkID="" s MarkID=%session.Get("MarkSelectDr")
    //i IPAddress="" s IPAddress=$ZUTIL(67,15,$JOB)
    i IPAddress="" s IPAddress=%session.Data("REMOTE_ADDR")
    s IPAddress=$$upper^SSUTIL4(IPAddress)
    s activeFlag=..GetActiveFlag(IPAddress)
    i activeFlag'=0 d
    .s retValue="alert('"_$ZCVT(activeFlag,"O","JS")_"')" 
    .&javascript<#(retValue)#>
    q:activeFlag'=0 activeFlag
    s admPersons=+$G(^DHCVISSet("DHCVISAdm"))
    i admPersons=0 s admPersons=1
    s waitPersons=+$G(^DHCVISSet("DHCVISWaiting"))
    s AllPatient="",PatientNo="",SurName="",ArrivedQue=""
    s DocInfoStr="!!!!!!!!!!!"
    s DHCQueRowId="",QueueId="" 
    s StartDate=+$H
    s EndDate=+$H
    s RegQue="on"
    s patIndex=0
    s insertFlag=0 
	//1:表中有数据的取数据；2.表中没数据的取Query
    s QueueId=$O(^DHCVISQueuei(0,"CreateUser",UserID,""),-1)
	i (QueueId'="") d
	.s VoiceQueueStr=$G(^DHCVISQueue(QueueId))
	.q:VoiceQueueStr=""
	.s EpisodeIDOld=$P(VoiceQueueStr,"^",23)
	.s DHCQueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeIDOld,""))
	.q:(DHCQueRowId="")
	.s oref=##Class(User.DHCQueue).%OpenId(DHCQueRowId)
	.i (oref'="") d
	..s Status=""
	..s Status=oref.QueStateDr.PersName
	..i ((Status="到达")||(Status="退号")||(Status="")) s DHCQueRowId=""
	..s QueMarkDr=oref.QueMarkDrGetObjectId()
	..i QueMarkDr'="" s ctpcpDesc=$P($g(^CTPCP(QueMarkDr,1)),"^",2) 
	..e  s ctpcpDesc=""
	..d oref.%Close()
    ..s docDr=##Class(web.SSUser).GetDefaultCareProvider(UserID)
	..i docDr'="" s docDesc=$P($G(^CTPCP(docDr,1)),"^",2)
	..e  s docDesc=""
	..i docDr'="" s DocHisID=$P($G(^CTPCP(docDr,1)),"^",1)
    ..e  s DocHisID=""
	..i (ctpcpDesc="")||(DocHisID="")||(UserID="")||(LocID="") s DHCQueRowId=""
    ..q:(DHCQueRowId="")
    ..s $P(DocInfoStr,"!",1)=$$upper^SSUTIL4(ctpcpDesc)
    ..s $P(DocInfoStr,"!",2)=$$upper^SSUTIL4(DocHisID)
	..s $P(DocInfoStr,"!",3)=$$upper^SSUTIL4(UserID)
	..s $P(DocInfoStr,"!",4)=$$upper^SSUTIL4(LocID) 
	..s $P(DocInfoStr,"!",5)=$$upper^SSUTIL4(MarkID)  
	..s voiceContent=$P(VoiceQueueStr,"^",4)
	..s ZHScreenStr=$P(VoiceQueueStr,"^",17)
	..s CKScreenStr=$P(VoiceQueueStr,"^",18)
	..s WaitList=$P(VoiceQueueStr,"^",19)
	..s Note=$P(VoiceQueueStr,"^",20)
	..s insertFlag=##Class(web.DHCVISVoiceCall).InsertVoiceQueue(voiceContent,UserID,IPAddress,"A","LR","N",ZHScreenStr,CKScreenStr,WaitList,Note,DocInfoStr,EpisodeIDOld)
    ..i insertFlag'=0 s retStr=insertFlag
    ..q:insertFlag'=0
	..s retStr="正在呼叫..."
    i ((QueueId="")||(DHCQueRowId="")) {
	  //"web.DHCDocEmergencyPatientList:FindLocDocCurrentAdm"
      s rs=##Class(%ResultSet).%New("web.DHCDocOutPatientList:FindLocDocCurrentAdmE")  
	  i rs.QueryIsValid() {
		Set Status=rs.Execute(LocID,UserID,IPAddress,AllPatient,PatientNo,SurName,StartDate,EndDate,ArrivedQue,RegQue,"",MarkID,"")
		Set columns = rs.GetColumnCount()
		If 'Status Quit
		While rs.Next() {
			s patIndex=patIndex+1
			i (patIndex>admPersons)&&(retStr="") s retStr="超出最多呼叫人数!"
			q:(patIndex>admPersons)  
			s WalkStatus=rs.GetDataByName("WalkStatus")
			//i walkStatus="过号"  s retStr="过号患者须重新报到后才能呼叫!"
			//q:walkStatus="过号"
			i ((WalkStatus'="到达")&&(WalkStatus'="退号")) d
			.s calledFlag=rs.GetDataByName("Called")
			.q:(calledFlag="")
			.q:(insertFlag=1)
			.s EpisodeID=rs.GetDataByName("EpisodeID")
			.s patName=rs.GetDataByName("PAPMIName")  
			.d ..FrontQueueInsert(EpisodeID,LocID,UserID,IPAddress,MarkID)
            .s insertFlag=1
            .s retStr=""
		} 
      }
    }
    i retStr'="" s retValue="alert('"_$ZCVT(retStr,"O","JS")_"');findPatientTree();"
    i retStr="" s retValue="findPatientTree();"
    &javascript<#(retValue)#>
    q ""
}

/// cy20190605 
/// 门诊点名字呼叫
ClassMethod FrontQueueInsertDocEm(EpisodeID As %String = "", LocID As %String = "", UserID As %String = "", IPAddress As %String = "", MarkID As %String = "") As %String
{
	i LocID="" s LocID=%session.Get("LOGON.CTLOCID")
    i UserID="" s UserID=%session.Get("LOGON.USERID")
    i MarkID="" s MarkID=%session.Get("MarkSelectDr")
    //i IPAddress="" s IPAddress=$ZUTIL(67,15,$JOB)
    i IPAddress="" s IPAddress=%session.Data("REMOTE_ADDR")
    s IPAddress=$$upper^SSUTIL4(IPAddress)
    s activeFlag=..GetActiveFlag(IPAddress)
    i activeFlag'=0 d
    .s retValue="alert('"_$ZCVT(activeFlag,"O","JS")_"');findPatientTree();"
    .&javascript<#(retValue)#>
    q:activeFlag'=0 activeFlag
    s calledStatus=..CheckCalledStatus(EpisodeID,UserID)
    i calledStatus'="0" d
    .s retValue="alert('"_$ZCVT(calledStatus,"O","JS")_"');findPatientTree();"
    .&javascript<#(retValue)#>
    q:calledStatus'="0" calledStatus
    
	s retStr="",retValue="",WaitExsitFlag=0,DocHisID="",ctpcpDesc=""
	s CKScreenStr="!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",DocInfoStr="!!!!!!!!!!"
    s QueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeID,""))
	s oref=##Class(User.DHCQueue).%OpenId(QueRowId)
	s patName=oref.QueName
	s queNo=oref.QueNo
	s QueMarkDr=oref.QueMarkDrGetObjectId()
	i QueMarkDr'="" s ctpcpDesc=$P($g(^CTPCP(QueMarkDr,1)),"^",2)  //号别
	s docDr=##Class(web.SSUser).GetDefaultCareProvider(UserID)
	i docDr'="" s DocHisID=$P($G(^CTPCP(docDr,1)),"^",1) 
	i docDr'="" s docDesc=$P($G(^CTPCP(docDr,1)),"^",2)  //姓名
	s DocTypeDesc=..GetDocTypeDesc(UserID)  //职称
	s $P(DocInfoStr,"!",1)=$$upper^SSUTIL4(ctpcpDesc)
	s $P(DocInfoStr,"!",2)=$$upper^SSUTIL4(DocHisID)
    s $P(DocInfoStr,"!",3)=$$upper^SSUTIL4(UserID)
	s $P(DocInfoStr,"!",4)=$$upper^SSUTIL4(LocID)
	s $P(DocInfoStr,"!",5)=$$upper^SSUTIL4(MarkID)
	s PAAdmPriority=oref.QueFirstDr.FirstcName
	s walkStatus=oref.QueStateDr.PersName
	s Priority="平诊"
	i PAAdmPriority="优先" s Priority="优诊"
	i walkStatus="复诊" s Priority="复诊"
	i walkStatus="到达" s Priority="复诊"
	i $d(^RBAS("PAADM_DR",EpisodeID)) s Priority="预约"
    d oref.%Close()
	//d ..InsertClientInfo(IPAddress,"",QueMarkDr)
    s PAAdmRoom=..GetRoom(IPAddress)
    s LocDesc=$P($G(^CTLOC(LocID)),"^",2)
    i $P(LocDesc,"-",2)'="" s LocDesc=$P(LocDesc,"-",2)
    i queNo'["号"  s queNo=queNo_"号"
	s $P(CKScreenStr,"!",1)=$$upper^SSUTIL4(LocDesc)
	s $P(CKScreenStr,"!",2)=$$upper^SSUTIL4(PAAdmRoom)
	s $P(CKScreenStr,"!",3)=$$upper^SSUTIL4(docDesc)
	s $P(CKScreenStr,"!",4)=$$upper^SSUTIL4(DocTypeDesc)
	s $P(CKScreenStr,"!",5)=$$upper^SSUTIL4(queNo)
	s $P(CKScreenStr,"!",6)=$$upper^SSUTIL4(patName)
	s ZHScreenStr=PAAdmRoom_" "_LocDesc_" "_docDesc_" "_queNo_" "_patName_" "_Priority  //不在走FromatZHStr
	s ZHScreenStr=QueRowId_"*"_ZHScreenStr
	s Note=PAAdmRoom_"   "_docDesc_"   "_queNo_"-"_patName_"  "_LocDesc
    s clientId="",serverId="",serverName=""
    s clientId=$O(^DHCVISClienti(0,"ClientIP",IPAddress,""))
	q:clientId="" "电脑没有叫号权限,请联系信息科!"
	s serverId=$P($G(^DHCVISClient(clientId)),"^",1)
	s clientName=$P($G(^DHCVISClient(clientId)),"^",3)
	q:serverId="" "叫号终端未设置叫号服务!"
	s serverName=$P($G(^DHCVISServer(serverId)),"^",2)
	i (+queNo)=0 s voiceContent="请 "_patName_" 到 "_PAAdmRoom_" 就诊"
	e  s voiceContent="请 "_queNo_" "_patName_" 到 "_PAAdmRoom_" 就诊"
	//s ^cy(+$h)=EpisodeID_","_LocID_","_UserID_","_MarkID_","_IPAddress
    s WaitPerList=..GetTwoWaiterE(EpisodeID,LocID,UserID,MarkID,IPAddress)
    s WaitPersons=$P(WaitPerList,"%")
    i (WaitPersons'="")&&($G(voiceContent)'="") d
    .s voiceContent=voiceContent_",请 "_WaitPersons_" 等候"
	.s EpisodeIDStr=$p($g(WaitPerList),"%",2)
	.q:EpisodeIDStr=""
	.s num=$l(EpisodeIDStr,",")
	.for j=1:1:num  d
	..s WaitEpisodeID=$p(EpisodeIDStr,",",j)
	..s updateWaitStatusFlag = ##Class(web.DHCDocOutPatientList).SetCallStatus(WaitEpisodeID,docDr,2,IPAddress,j)
	..//i updateWaitStatusFlag'=1 s retValue="更新队列状态失败!"
    ..s QueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",WaitEpisodeID,""))
	..s oref=##Class(User.DHCQueue).%OpenId(QueRowId)
	..s patNameWait=oref.QueName
	..s queNoWait=oref.QueNo
	..d oref.%Close()
	..s $P(CKScreenStr,"!",j+6)=queNoWait_"号-"_patNameWait
	s WaitList=$P(WaitPerList,"%",3)
	i (($G(EpisodeID)'="")&&($P($G(voiceContent),",",1)'=""))   d
	.s updateStatusFlag = ##Class(web.DHCDocOutPatientList).SetCallStatus(EpisodeID,docDr,"",IPAddress)
	.i updateStatusFlag'=1 s retValue="更新队列状态失败!"
	.q:updateStatusFlag'=1
    .s insertFlag=##Class(web.DHCVISVoiceCall).InsertVoiceQueue(voiceContent,UserID,IPAddress,"A","LR","N",ZHScreenStr,CKScreenStr,WaitList,Note,DocInfoStr,EpisodeID)
    .i insertFlag'=0 s retValue=insertFlag
    .q:insertFlag'=0
    .s retValue="正在呼叫:"_queNo_patName_"..."

    i retValue'="" s retValue="alert('"_$ZCVT(retValue,"O","JS")_"');findPatientTree();"
    i retValue="" s retValue="findPatientTree();"
    &javascript<#(retValue)#>
    q retValue
}

ClassMethod GetTwoWaiterE(EpisodeID As %String = "", LocID As %String = "", UserID As %String = "", MarkID As %String = "", IPAddress As %String = "") As %String
{
	/*
	普通号无等候 
	s QueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeID,""))
	s oref=##Class(User.DHCQueue).%OpenId(QueRowId)
	s QueMarkDr=oref.QueMarkDrGetObjectId()
	i QueMarkDr'="" s ctpcpDesc=$P($g(^CTPCP(QueMarkDr,1)),"^",2)
	Q:ctpcpDesc["普通号" ""
	*/
	i LocID="" s LocID=%session.Get("LOGON.CTLOCID")
    i UserID="" s UserID=%session.Get("LOGON.USERID")
    i MarkID="" s MarkID=%session.Get("MarkSelectDr")
    //i IPAddress="" s IPAddress=$ZUTIL(67,15,$JOB)
    i IPAddress="" s IPAddress=%session.Data("REMOTE_ADDR")
    s IPAddress=$$upper^SSUTIL4(IPAddress)
    s retStr="",retValue=""
	s AllPatient="",PatientNo="",SurName="",ArrivedQue=""
	s patIndex=0,i=0,WaitTwoStr="",WaitTwo="",WaitingStr="",EpisodeIDStr="",num=0,j=0
    s StartDate=+$H
    s EndDate=+$H
    s RegQue="on"
    s insertFlag=0
    s waitPersons=+$G(^DHCVISSet("DHCVISWaiting"))  //获取等候
    s TwoWaiterPersons=+$G(^DHCVISSet("TwoWaiter")) //获取呼叫等候
    s WaitList="",WaitListNo=""
    //"web.DHCDocEmergencyPatientList:FindLocDocCurrentAdm"
    s rs=##Class(%ResultSet).%New("web.DHCDocOutPatientList:FindLocDocCurrentAdmE")
	i rs.QueryIsValid() {
		Set Status=rs.Execute(LocID,UserID,IPAddress,AllPatient,PatientNo,SurName,StartDate,EndDate,ArrivedQue,RegQue,"",MarkID,"")
		Set columns = rs.GetColumnCount()
		If 'Status Quit
		While rs.Next() 
		{
			q:(num-(waitPersons-2)>0)
			s WalkStatus=rs.GetDataByName("WalkStatus")
            s calledFlag=rs.GetDataByName("Called")
			s WaitRegRangeTime=rs.GetDataByName("RegRangeTime")    
		    // 显示同一时间段的患者
			s RegRangeTimeDr=""
			s RegfeeDr=$O(^User.DHCRegistrationFeeI("ADM"," "_EpisodeID,""))
			i RegfeeDr'="" s RegRangeTimeDr=$LIST(^User.DHCRegistrationFeeD(RegfeeDr),21)
			//q:(WaitRegRangeTime'=RegRangeTimeDr)
			i (WalkStatus'="过号")&&(WalkStatus'="到达")&&(WalkStatus'="退号")&&(calledFlag'="1") d
			.s WaitEpisodeID=rs.GetDataByName("EpisodeID")
			.q:WaitEpisodeID=""
			.s WaitpatName=rs.GetDataByName("PAPMIName") 
			.s locSeqNo=rs.GetDataByName("LocSeqNo")
			.s locSeqNo=$tr(locSeqNo," ","")
			.i locSeqNo'["号" s locSeqNo=locSeqNo_"号"
			.q:EpisodeID=WaitEpisodeID
			.s QueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",WaitEpisodeID,""))
			.q:QueRowId=""
			.s QueObj=##Class(User.DHCQueue).%OpenId(QueRowId)
	        .s QueDoc=QueObj.QueDocDrGetObjectId()
			.s DocId=$p($g(^SSU("SSUSR",UserID)),"^",14)
			.q:(QueDoc'=DocId)&&(QueDoc'="")
			.// 等候队列
			.s QueRowlocSeqNo=QueRowId_"*"_locSeqNo
			.i WaitingStr=""  s WaitingStr=QueRowlocSeqNo
			.e  s WaitingStr=WaitingStr_","_QueRowlocSeqNo 
			.i (num<TwoWaiterPersons)&&(TwoWaiterPersons'=0)  d
			..//等候就诊ID
			..i EpisodeIDStr="" s EpisodeIDStr=WaitEpisodeID
			..e  s EpisodeIDStr=EpisodeIDStr_","_WaitEpisodeID
			..// 等候患者
		    ..s WaitPat=locSeqNo_"-"_WaitpatName
			..i WaitTwo=""  s WaitTwo=WaitPat
			..e  s WaitTwo=WaitTwo_" "_WaitPat
			.s num=num+1
		} 
    }
	q WaitTwo_"%"_EpisodeIDStr_"%"_WaitingStr
}

/// 药房20190613
/// Input : PatNo - 患者登记号 , PatName - 患者姓名 , ServerIP - 本地ip地址 , PhwId - 发药窗口号
/// w ##class(web.DHCSTInterfacePH).SendMessToVoice(":0000346554","刘继荣","192.168.82.36",55,67)
ClassMethod SendMessToVoice(PatNo, PatName, ClinetIP, PhwID, FYUserID) As %String
{
	q:(PatNo="")||(PatName="")||(ServerIP="")||(PhwID="") "-1^入参不能为空!"
	s DHCQueID=$o(^User.DHCQueueI("QuePersonIdIndex"," "_PatNo,""),-1)
	s oref=##Class(User.DHCQueue).%OpenId(DHCQueID)
	s EpisodeID=oref.QuePaadmDr
	s PhWinDesc=$p($g(^DHCPHWIN(PhwID)),"^",1)
	s VoiceContent="请"_PatName_"到"_PhWinDesc_"领药"
	s PrescNo="null"
	s UserID=$p(^DHCPHPER(FYUserID),"^",5)
	s ScreentContent=PhWinDesc_","_PatName_","_PatNo_","_PrescNo_","
	s sendret=##class(web.DHCVISVoiceCall).InsertVoiceQueue(VoiceContent,UserID,ServerIP,"D","LR","N",ScreentContent,ScreentContent,"","","",EpisodeID)
	q sendret
}

/// PDA扫码呼叫,输液室使用 cy20190613  门诊:O    急诊:E
/// W ##Class(web.DHCVISQueueManage).SendVoiceCallTreatQueueNFYY("1","妇幼","1号穿刺台","38939||18||1","C")
ClassMethod SendVoiceCallTreatQueuePDA(QueNo As %String = "", PatName As %String = "", WindowDesc As %String = "", PatientId As %String = "", ActiveFlag As %String = "") As %String
{
	s retStr=""
	q:(QueNo="")||(PatName="")||(WindowDesc="") "入参不完整"
	s Type="",IPAddress="",serverIdBak=""
	i QueNo'["号" s QueNo=QueNo_"号"
    s PatStr=QueNo_" "_PatName
    s voiceContent="请 "_PatStr_" 到 "_WindowDesc_"号输液台输液"
    s voiceContent=voiceContent_" "_voiceContent
	s userId=1
	s ServerIP=""
	f  s ServerIP=$O(^DHCVISServeri(0,"ServerIP",ServerIP)) q:ServerIP=""  d
	.s serverId=""
	.f  s serverId=$O(^DHCVISServeri(0,"ServerIP",ServerIP,serverId)) q:serverId=""  d
	..s serverType=$P($G(^DHCVISServer(serverId)),"^",9)
	..q:serverType'="PDA"
	..s clientId=""
	..f  s clientId=$O(^DHCVISClienti(0,"ServerID",serverId,clientId)) q:clientId=""  d
	...s IPAddress=$P($G(^DHCVISClient(clientId)),"^",2)
	...s serverIdBak=serverId
	q:IPAddress="" ""
	s queueNo=QueNo
	s type="T"
	s sound="LR"
	s repeat="N"
	s callState="N"
	i ActiveFlag="C" s callState="N"
	e  s callState="Y"
	s nowDate=+$H
	s nowTime=$p($H,",",2)
	s WaitList="祝君健康"
	s Note="祝君健康"
	s CKScreenStr=PatientId_"!"_ActiveFlag_"!"_QueNo_"!"_PatName_"!"_WindowDesc
	s ZHScreenStr=CKScreenStr
	// 查看数据是否已经在列表中，如果在，就更新，如果不在，就插入
	s nowDate=+$h,nowTime=$P($h,",",2),contentFlag="0"
	q:serverIdBak="" ""
	s queueId=""
	f  s queueId=$o(^DHCVISQueuei(0,"DateServerState",nowDate,serverIdBak,"Y",queueId)) q:((queueId="")||(contentFlag="1"))  d
	.s queueStr=$G(^DHCVISQueue(queueId))
	.s ckContent=$P(queueStr,"^",18)
	.s PatientIdBak=$P(ckContent,"!",1)
	.q:(PatientIdBak'=PatientId)
	.s contentFlag="1"
	.s queueIdbak=queueId
	i contentFlag="0" d
	.s retStr=##Class(web.DHCVISVoiceCall).InsertVoiceQueue(voiceContent,userId,IPAddress,type,sound,repeat,ZHScreenStr,CKScreenStr,WaitList,Note,"","",PatientId)
   	e  d
   	.&SQL(Update DHC_VIS_VoiceQueue set VIS_CKScreenStr=:CKScreenStr,VIS_State=:callState where VIS_QueueID=:queueIdbak)
	q retStr
}

/// 诊疗界面点名字下一个
ClassMethod SendVoiceCallTreatQueue(EpisodeID As %String = "", QueNo As %String = "", PatName As %String = "", UserID As %String = "", LocID As %String = "", computerIP As %String = "") As %String
{
	s retStr="8^获取呼叫队列失败"
	q:(PatName="") retStr
	i UserID="" s UserID=%session.Get("LOGON.USERID")
	i LocID=""  s LocID=%session.Get("LOGON.CTLOCID")
	i computerIP="" s computerIP=%session.Data("REMOTE_ADDR")
	s computerIP=$$upper^SSUTIL4(computerIP)
	s LocDesc=$P($G(^CTLOC(LocID)),"^",2)
    i $P(LocDesc,"-",2)'="" s LocDesc=$P(LocDesc,"-",2)
    s nurseName=$P($G(^SSU("SSUSR",UserID)),"^",2)
	s clientName=##Class(web.DHCVISQueueManage).GetRoom(computerIP)
    q:(clientName="") "1^未配置客户端"
    i (QueNo'["号")&&(QueNo'="") s QueNo=QueNo_"号"
    s voiceContent="请 "_QueNo_" "_PatName_" 到 "_clientName_" 采集"
	s $P(CKScreenStr,"!",1)=$$upper^SSUTIL4(clientName)
	s $P(CKScreenStr,"!",2)=$$upper^SSUTIL4(QueNo)  
	s $P(CKScreenStr,"!",3)=$$upper^SSUTIL4(PatName)
	s $P(CKScreenStr,"!",4)=$$upper^SSUTIL4(LocDesc)
	s $P(CKScreenStr,"!",5)=$$upper^SSUTIL4(nurseName)
	s ZHScreenStr=CKScreenStr
    s Note=CKScreenStr
	s WaitList=""
	s type="T"
	s sound="LR"
	s repeat="N"
	s retStr=##Class(web.DHCVISVoiceCall).InsertVoiceQueue(voiceContent,UserID,computerIP,type,sound,repeat,ZHScreenStr,CKScreenStr,WaitList,Note,"",EpisodeID)
    i retStr=0 s retStr="0^正在呼叫 "_QueNo_" "_PatName_"..."
    e  s retStr="6^"_retStr
    /*
    i retStr=0 d
    .d ..UpdateQueueState(EpisodeID,UserID,LocID,computerIP,"")
    .s retValue="alert('"_$ZCVT(callStr,"O","JS")_"');"
    .&javascript<#(retValue)#>
    */
	q retStr
}

ClassMethod InsertClientInfo(ClientIP As %String = "", UserID As %String = "", MarkDr As %String = "") As %String
{
	i $G(ClientIP)="" s ClientIP=%session.Data("REMOTE_ADDR")
	i $G(ClientIP)="" s ClientIP=$ZUTIL(67,15,$JOB)
    i UserID="" s UserID=%session.Get("LOGON.USERID")
    s DocDr=##Class(web.SSUser).GetDefaultCareProvider(UserID)
    i MarkDr="" s MarkDr=DocDr
    q:(ClientIP="")!(UserID="")!(MarkDr="") ""
    s nowDate=+$H
    s nowTime=+$P($H,",",2)
    s isExitID=""
    &SQL(select ID into :isExitID from  DHC_VIS_ClientInfo where ClientIP=:ClientIP and UserID=:UserID)
    i isExitID="" d
    .&SQL(insert into DHC_VIS_ClientInfo (ClientIP,UserID,DocDr,MarkDr,LastDate,LastTime) values (:ClientIP,:UserID,:DocDr,:MarkDr,:nowDate,:nowTime))
    e  d
    .&SQL(update DHC_VIS_ClientInfo set ClientIP=:ClientIP,UserID=:UserID,DocDr=:DocDr,MarkDr=:MarkDr,LastDate=:nowDate,LastTime=:nowTime where ID=:isExitID)
	q SQLCODE
}

/// w ##Class(web.DHCVISQueueManage).PatNameTran("姓名字")
ClassMethod PatNameTran(patName As %String = "") As %String
{
	s patName=$$upper^SSUTIL4(patName)
	s patName=$TR(patName,$C(0,10,13))
	s patName=$TR(patName,"0123456789")
	i $l(patName)=3 s patName=$E(patName,1)_"×"_$E(patName,3)
	i $l(patName)=2 s patName=$E(patName,1)_"×"
	q patName
}

ClassMethod GetNewCallFlag(Adm As %String = "", DocDr As %String = "") As %String
{
	s CompDr=0
	Quit:(Adm="")||(DocDr="") CompDr
	Set QueRowId=##Class(web.DHCDocOutPatientList).GetQueRowidByMore(Adm,DocDr)
	If QueRowId'="" Do
	.Set oref=##Class(User.DHCQueue).%OpenId(QueRowId)
	.Set CompDr=oref.QueCompDr
 	.Do oref.%Close()
 	Quit +CompDr
}

/// /护士按代替医生呼叫
/// w ##Class(web.DHCVISQueueManage).ReplacedCall(750)
ClassMethod ReplacedCallByZone(ZoneValue As %String = "") As %String
{
	s userIdLog="",locIdLog="",userNameLog=""
	s userIdLog=%session.Get("LOGON.USERID")
	s locIdLog=%session.Get("LOGON.CTLOCID")
	s userNameLog=%session.Get("LOGON.USERNAME")
	s ZoneID=""
	//&sql(select ID into :ZoneID from DHCExaBorough where ExabName=:ZoneValue)
	i (+ZoneValue)>0 s ZoneID=+ZoneValue
	q:(ZoneID=0) ""
	s NowDate=+$H
	s StateID=2
	s MarkID=""
	f  s MarkID=$O(^User.DHCQueueI("QueComDate",NowDate,ZoneID,MarkID)) q:MarkID=""  d
	.s QueueID=$O(^User.DHCQueueI("QueComDate",NowDate,ZoneID,MarkID,StateID,""))
	.q:QueueID=""
	.d ..ReplacedCall(QueueID)
	q 0
}

/// w ##Class(web.DHCVISQueueManage).ReplacedCall(750)
ClassMethod ReplacedCall(QueueID As %String, QueueRoomID As %String = "") As %String
{
	s RetValue=""
	s QueObj=##Class(User.DHCQueue).%OpenId(QueueID)
	s EpisodeID=QueObj.QuePaadmDrGetObjectId()
	s LocID=QueObj.QueDepDrGetObjectId()
	s QueMarkDr=QueObj.QueMarkDrGetObjectId()
	s UserID=$O(^SSU("SSUSR",0,"CTPCP",QueMarkDr,""))
	i UserID="" d
	.s QueMarkDr=QueObj.QueDocDrGetObjectId()
	.q:QueMarkDr=""
	.s UserID=$O(^SSU("SSUSR",0,"CTPCP",QueMarkDr,""))
	i UserID="" d
	.s RetValue="alert('"_$ZCVT("请先指定医生!","O","JS")_"')" 
    .&javascript<#(RetValue)#>
    .d QueObj.%Close()
    q:UserID="" ""
    i QueueRoomID="" s QueueRoomID=QueObj.QueRoomDrGetObjectId()
    i QueueRoomID="" d
	.s RetValue="alert('"_$ZCVT("请选择诊室!","O","JS")_"')" 
    .&javascript<#(RetValue)#>
    .d QueObj.%Close()
	q:QueueRoomID="" ""
	s ClientID=$O(^DHCVISClienti(0,"LinkDoc",QueueRoomID,""))
	i ClientID="" d
	.s RetValue="alert('"_$ZCVT("叫号诊室未关联!","O","JS")_"')" 
    .&javascript<#(RetValue)#>
    .d QueObj.%Close()
	q:ClientID="" ""
	d QueObj.%Close()
	s ClientIP=$P($G(^DHCVISClient(ClientID)),"^",2)
	q:ClientIP="" ""
	s RegfeeDr=$O(^User.DHCRegistrationFeeI("ADM"," "_EpisodeID,""))
	q:RegfeeDr="" ""
	s RegRangeTimeDr=$LIST(^User.DHCRegistrationFeeD(RegfeeDr),21)
	q:RegRangeTimeDr=""
	s RegRangeTime=$p(^DHCTimeRange(RegRangeTimeDr),"^",2)
	//q:($P($H,",",2)<43200)&&(RegRangeTime="下午")
	//q:($P($H,",",2)>43200)&&(RegRangeTime="上午")
	d ..ReplacedQueueInsert(EpisodeID, LocID, UserID,ClientIP)
	q ""
}

ClassMethod ReplacedQueueInsert(EpisodeID As %String = "", LocID As %String = "", UserID As %String = "", IPAddress As %String = "") As %String
{
	q:((EpisodeID="")||(LocID="")||(UserID="")||(IPAddress)) 
    s activeFlag=..GetActiveFlag(IPAddress)
    i activeFlag'=0 d
    .s retValue="alert('"_$ZCVT(activeFlag,"O","JS")_"');findPatientTree();"
    .&javascript<#(retValue)#>
    q:activeFlag'=0 activeFlag
    s calledStatus=..CheckCalledStatus(EpisodeID,UserID)
    i calledStatus'="0" d
    .s retValue="alert('"_$ZCVT(calledStatus,"O","JS")_"');findPatientTree();"
    .&javascript<#(retValue)#>
    q:calledStatus'="0" calledStatus
    
	s retStr="",retValue="",WaitExsitFlag=0,DocHisID="",ctpcpDesc=""
	s CKScreenStr="!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",DocInfoStr="!!!!!!!!!!"
    s QueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeID,""))
	s oref=##Class(User.DHCQueue).%OpenId(QueRowId)
	s patName=oref.QueName
	s queNo=oref.QueNo
	s QueMarkDr=oref.QueMarkDrGetObjectId()
	i QueMarkDr'="" s ctpcpDesc=$P($g(^CTPCP(QueMarkDr,1)),"^",2)  //号别
	s docDr=##Class(web.SSUser).GetDefaultCareProvider(UserID)
	i docDr'="" s DocHisID=$P($G(^CTPCP(docDr,1)),"^",1) 
	i docDr'="" s docDesc=$P($G(^CTPCP(docDr,1)),"^",2)  //姓名
	s DocTypeDesc=..GetDocTypeDesc(UserID)  //职称
	s $P(DocInfoStr,"!",1)=$$upper^SSUTIL4(ctpcpDesc)
	s $P(DocInfoStr,"!",2)=$$upper^SSUTIL4(DocHisID)
    s $P(DocInfoStr,"!",3)=$$upper^SSUTIL4(UserID)
	s $P(DocInfoStr,"!",4)=$$upper^SSUTIL4(LocID)
	s PAAdmPriority=oref.QueFirstDr.FirstcName
	s walkStatus=oref.QueStateDr.PersName
	s Priority="平诊"
	i PAAdmPriority="优先" s Priority="优诊"
	i walkStatus="复诊" s Priority="复诊"
	i walkStatus="到达" s Priority="复诊"
	i $d(^RBAS("PAADM_DR",EpisodeID)) s Priority="预约"
    d oref.%Close()
	//d ..InsertClientInfo(IPAddress,"",QueMarkDr)
    s PAAdmRoom=..GetRoom(IPAddress)
    s LocDesc=$P($G(^CTLOC(LocID)),"^",2)
    i $P(LocDesc,"-",2)'="" s LocDesc=$P(LocDesc,"-",2)
    i queNo'["号"  s queNo=queNo_"号"
	s $P(CKScreenStr,"!",1)=$$upper^SSUTIL4(LocDesc)
	s $P(CKScreenStr,"!",2)=$$upper^SSUTIL4(PAAdmRoom)
	s $P(CKScreenStr,"!",3)=$$upper^SSUTIL4(docDesc)
	s $P(CKScreenStr,"!",4)=$$upper^SSUTIL4(DocTypeDesc)
	s $P(CKScreenStr,"!",5)=$$upper^SSUTIL4(queNo)
	s $P(CKScreenStr,"!",6)=$$upper^SSUTIL4(patName)
	s ZHScreenStr=PAAdmRoom_" "_LocDesc_" "_docDesc_" "_queNo_" "_patName_" "_Priority  //不在走FromatZHStr
	s ZHScreenStr=QueRowId_"*"_ZHScreenStr
	s Note=PAAdmRoom_"   "_docDesc_"   "_queNo_"-"_patName_"  "_LocDesc
    s clientId="",serverId="",serverName=""
    s clientId=$O(^DHCVISClienti(0,"ClientIP",IPAddress,""))
	q:clientId="" "电脑没有叫号权限,请联系信息科!"
	s serverId=$P($G(^DHCVISClient(clientId)),"^",1)
	s clientName=$P($G(^DHCVISClient(clientId)),"^",3)
	q:serverId="" "叫号终端未设置叫号服务!"
	s serverName=$P($G(^DHCVISServer(serverId)),"^",2)
	i (+queNo)=0 s voiceContent="请 "_patName_" 到 "_PAAdmRoom_" 就诊"
	e  s voiceContent="请 "_queNo_" "_patName_" 到 "_PAAdmRoom_" 就诊"
	//s ^cy(+$h)=EpisodeID_","_LocID_","_UserID_","_MarkID_","_IPAddress
    s WaitPerList=..GetTwoWaiter(EpisodeID,LocID,UserID,MarkID,IPAddress)
    s WaitPersons=$P(WaitPerList,"%")
    i (WaitPersons'="")&&($G(voiceContent)'="") d
    .s voiceContent=voiceContent_",请 "_WaitPersons_" 等候"
	.s EpisodeIDStr=$p($g(WaitPerList),"%",2)
	.q:EpisodeIDStr=""
	.s num=$l(EpisodeIDStr,",")
	.for j=1:1:num  d
	..s WaitEpisodeID=$p(EpisodeIDStr,",",j)
	..s updateWaitStatusFlag = ##Class(web.DHCDocOutPatientList).SetCallStatus(WaitEpisodeID,docDr,2,IPAddress,j)
	..//i updateWaitStatusFlag'=1 s retValue="更新队列状态失败!"
    ..s QueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",WaitEpisodeID,""))
	..s oref=##Class(User.DHCQueue).%OpenId(QueRowId)
	..s patNameWait=oref.QueName
	..s queNoWait=oref.QueNo
	..d oref.%Close()
	..s $P(CKScreenStr,"!",j+6)=queNoWait_"号-"_patNameWait
	s WaitList=$P(WaitPerList,"%",3)
	i (($G(EpisodeID)'="")&&($P($G(voiceContent),",",1)'=""))   d
	.s updateStatusFlag = ##Class(web.DHCDocOutPatientList).SetCallStatus(EpisodeID,docDr,"",IPAddress)
	.i updateStatusFlag'=1 s retValue="更新队列状态失败!"
	.q:updateStatusFlag'=1
    .s insertFlag=##Class(web.DHCVISVoiceCall).InsertVoiceQueue(voiceContent,UserID,IPAddress,"A","LR","N",ZHScreenStr,CKScreenStr,WaitList,Note,DocInfoStr,EpisodeID)
    .i insertFlag'=0 s retValue=insertFlag
    .q:insertFlag'=0
    .s retValue="正在呼叫:"_queNo_patName_"..."

    i retValue'="" s retValue="alert('"_$ZCVT(retValue,"O","JS")_"');findPatientTree();"
    i retValue="" s retValue="findPatientTree();"
    &javascript<#(retValue)#>
    q retValue
}

/// 采血呼叫接口-20201202cy
/// w ##Class(web.DHCVISQueueManage).BloodQueueCall("186","15406","172.20.8.239")
ClassMethod BloodQueueCall(LocID As %String = "", UserID As %String = "", IPAddress As %String = "") As %String
{
	s retStr=""
	i ($G(LocID)="")&&($D(%session)) s LocID=%session.Data("LOGON.CTLOCID")
	i ($G(UserID)="")&&($D(%session)) s UserID= %session.Data("LOGON.USERID")
	i ($G(IPAddress)="")&&($D(%session)) s IPAddress=%session.Data("REMOTE_ADDR")
	s clientName=##Class(web.DHCVISQueueManage).GetRoom(IPAddress)
    q:clientName="" "6^电脑没有叫号权限,请联系信息科!"
	s clientId=$O(^DHCVISClienti(0,"ClientIP",IPAddress,""))
	q:clientId="" "6^电脑没有叫号权限,请联系信息科!"
	s serverId=$P($G(^DHCVISClient(clientId)),"^",1)
	q:serverId="" "6^电脑没有叫号权限,请联系信息科!"
	s serverIP=$P($G(^DHCVISServer(serverId)),"^")
	q:serverIP="" "6^电脑没有叫号权限,请联系信息科!"
	s LocId=""
	s:serverId'="" LocId=$p(^DHCVISServer(serverId),"^",8)
	i LocId="" s LocId="185"
	i $G(clientId)="" s clientId="91"
	s StartDate=+$H
	s CallNo=0,Max=0
	
	s rs=##Class(%ResultSet).%New("web.DHCNurTreatQueue:QueryBloodPat")    
	i rs.QueryIsValid() {
		Set Status=rs.Execute("","",IPAddress,UserID)
		If 'Status Quit
		While rs.Next() {
			Quit:(CallNo>Max)
			Set curId=rs.Data("TreatId")
			Set CallUser=$lg(^User.DHCNurTreatQueueD(curId),14)
			Continue:(CallUser'="")&&(CallUser'=UserID)
			s QueueNo=$lg(^User.DHCNurTreatQueueD(curId),5)
			Set TreatAdmDr=$lg(^User.DHCNurTreatQueueD(curId),2)
			Continue:TreatAdmDr=""
			Set Papmidr=$p($G(^PAADM(TreatAdmDr)),"^",1)
			Continue:Papmidr=""
		    Set PatName=$p($G(^PAPER(Papmidr,"ALL")),"^",1)
			Set RegNo=$p($G(^PAPER(Papmidr,"PAT",1)),"^",2)
			Set QueueState=$lg(^User.DHCNurTreatQueueD(curId),7)
			;Continue:(QueueState="Finish")||(QueueState="Skip")||(QueueState="Call")	//完成治疗的不显示
			Set CallNo=CallNo+1
			Set QueueDr=curId
		}
	}
	b ;err
	i $G(PatName)'="" d
	.i QueueNo'["号" s QueueNo=QueueNo_"号"
	.s voiceContent="请 "_QueueNo_" "_PatName_" 到 "_clientName_" 采集"
	.s LocDesc=$P($G(^CTLOC(LocID)),"^",2)
    .i $p(LocDesc,"-",2)'="" s LocDesc=$P(LocDesc,"-",2)
	.s $p(CKScreenStr,"!",1)=$$upper^SSUTIL4(LocDesc)
	.s $p(CKScreenStr,"!",2)=$$upper^SSUTIL4(clientName)
	.s $p(CKScreenStr,"!",5)=$$upper^SSUTIL4(QueueNo)
	.s $p(CKScreenStr,"!",6)=$$upper^SSUTIL4(PatName)
    .s ZHScreenStr=LocDesc_"  "_clientName_"  "_QueueNo_"  "_PatName
    .s Note=ZHScreenStr
	.s WaitList=""
	.s type="T"
	.s sound="LR"
	.s repeat="N"
	.s retStr=##Class(web.DHCVISVoiceCall).InsertVoiceQueue(voiceContent,UserID,IPAddress,type,sound,repeat,ZHScreenStr,CKScreenStr,WaitList,Note,"",TreatAdmDr)
    .i (retStr=0) d ..UpdateDHCNurTreatStatus(QueueDr,LocId,UserID,IPAddress)
    i retStr=0 s retStr="0^正在呼叫 "_QueueNo_" "_PatName_"..."
    e  s retStr="6^"_retStr
    q retStr
}

/// 更新队列状态
ClassMethod UpdateDHCNurTreatStatus(queueDr As %String = "", Loc As %String = "", UserID As %String = "", IPAddress As %String = "")
{
	s statusCode="Call"
	i queueDr'="" d
	.s queueObj=##class(User.DHCNurTreatQueue).%OpenId(queueDr)
	.s queueObj.TreatQueState=statusCode
	.s queueObj.TreatCallUser=UserID
	.s queueObj.TreatServerIP=IPAddress
	.s queueObj.TreatRecDate=+$H
	.s queueObj.TreatRecTime=$p($H,",",2)
	.d queueObj.%Save()
	.d queueObj.%Close()
	q 0
}

/// 更新队列状态
ClassMethod CancelDHCQueueCallState(EpisodeID As %String = "")
{
	q:EpisodeID="" "入参错误"
	s QueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeID,""))
	q:QueRowId="" "患者无就诊记录"
	s oref=##Class(User.DHCQueue).%OpenId(QueRowId)
	s oref.QueCompDr=""
	s oref.QueDocDr=""
	s oref.QueEverCalled=""
	s sc = oref.%Save()
 	d oref.%Close()
    q 0
}

/// 新增住院患者叫号 提供给计费组
/// 以下参数除userId可空其他均不为空
/// QueNo:队列号 PatName:患者姓名 computerIP:电脑IP或计算机名 userId:用户ID admId:就诊ID
/// callType "IPReg":"办理入院登记","IPPay":"办理出院结算","IPDep":"缴纳住院押金"
/// 返回0成功  其他失败
/// w ##Class(web.DHCVISQueueManage).SendVoiceCallInPat("1","测试","192.168.1.1",1,3,"InPatDeposit")
ClassMethod SendVoiceCallInPat(QueNo As %String = "", PatName As %String = "", computerIP As %String = "", userId As %String = "", admId As %String = "", callType As %String = "") As %String
{
	q:(QueNo="")||(PatName="")||(admId="")||(callType="") "入参不完整"
	s retStr=""
	i (computerIP="")&&($D(%session)>0) s computerIP=%session.Data("REMOTE_ADDR")
	s computerIP=$$upper^SSUTIL4(computerIP)
	s clientName=##Class(web.DHCVISQueueManage).GetRoom(computerIP)
    i clientName="" s retStr="客户端未授权!"
    q:retStr'="" retStr
    s callTypeName="就诊"
    s callTypeName=$CASE(callType,"IPReg":"办理入院登记","IPPay":"办理出院结算","IPDep":"缴纳住院押金",:"就诊")
    i QueNo'["号" s QueNo=QueNo_"号"
    s PatStr=QueNo_" "_PatName
    s voiceContent="请 "_PatStr_" 到 "_clientName_" "_callTypeName
	i userId="" s userId=%session.Get("LOGON.USERID")
	s $P(CKScreenStr,"!",2)=$$ALPHAUP^SSUTIL4(clientName)
	s $P(CKScreenStr,"!",5)=$$ALPHAUP^SSUTIL4(PatName)
	s $P(CKScreenStr,"!",6)=$$ALPHAUP^SSUTIL4(QueNo)
	s ZHScreenStr=CKScreenStr
	s WaitList=""
	s Note="1 2 3 4"
	s type="T"
	s sound="LR"
	s repeat="N"
	s retStr=##Class(web.DHCVISVoiceCall).InsertVoiceQueue(voiceContent,userId,computerIP,type,sound,repeat,ZHScreenStr,CKScreenStr,WaitList,Note,"",admId)
	q retStr
}

/// 入参：adminId
/// 出参：患者最新一次呼叫日期和时间
/// w ##class(web.DHCVISQueueManage).GetAdminNewCallDateTime(87361)
ClassMethod GetAdminNewCallDateTime(AdminId As %String = "") As %String
{
	s fcallDate=""
	s fcallTime=""
	q:AdminId="" fcallDate_" "_fcallTime
	s Num=0
	s queId=""
	f  s queId=$o(^DHCVISQueuei(0,"PatID",AdminId,queId),-1) q:(queId="")||(Num>0)  d
	.s Num=Num+1
	.s queStr=$G(^DHCVISQueue(queId))
	.q:queStr=""
	.i Num=1 d
	..;s fcallDate=$zdt($p(queStr,"^",12),3)
	..;s fcallTime=$zt($p(queStr,"^",13),1)
	..s fcallDate=$p(queStr,"^",12)
	..s fcallTime=$p(queStr,"^",13)
	q fcallDate_" "_fcallTime
}

}
