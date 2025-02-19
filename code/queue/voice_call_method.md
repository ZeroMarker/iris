## 叫号
```js
/// /desc:推送诊区患者信息
/// w ##class(DHCDoc.Interface.Outside.YH.DHCDocVISService.MainMethods).SendDeptScreenInfo(7)
ClassMethod SendDeptScreenInfo(QueRowId As %String = "", BorId As %String = "") As %String
{
	s $ZTrap = "SendAdmCallInfoET"
	//s ^Temp("SendAdmCallInfo")=$lb(EpisodeID, LocID, UserID, IPAddress, WaitEpisodeID,LoginFlag,GHList,$h)
	q:BorId=""
	s Exab = 0
	s Mark = 0
	s queid = 0
	s Date = +$h
	s Obj = {}
	s Obj.deptKey = $lg(^User.DHCExaBoroughD(BorId),2)
	s Obj.owner = "HIS"
	s Obj.type = 0
	s Obj.screenInfo = []
	s Obj.overPatientInfo = []

	for {
		s Mark = $o(^User.DHCQueueI("QueMarkDrIndex",Date,Mark))
		
		q:Mark=""
		/*
		1	01		复诊
		2	02	等候	等候
		3	03	 	过号
		4	04		到达
		5	05		退号
		6	06	 	未分配
		7	07	报到	报到
		*/
		// 向 screenInfo 数组中添加元素
		
		set screenInfoItem = {}
		set screenInfoItem.waitPatientInfo = []
		
		if Mark = $lg($g(^User.DHCQueueD(QueRowId)),8) {
			set waitPatientInfo = {}
			set waitPatientInfo.registerId=$lg($g(^User.DHCQueueD(QueRowId)),10)
			set waitPatientInfo.patientName=$lg($g(^User.DHCQueueD(QueRowId)),9)
			set waitPatientInfo.sort=0 ;$lg($g(^User.DHCQueueD(QueRowId)),10) - 1
			do screenInfoItem.waitPatientInfo.%Push(waitPatientInfo)
		}
	
		set Que = 0
		for {
			s Que = $o(^User.DHCQueueI("QueMarkDrIndex",Date,Mark,Que))
			q:Que=""
			continue:Que=QueRowId
			set dept = $lg($g(^User.DHCQueueD(Que)),4)

			set bor = 0
			set bor = $o(^User.DHCExaBorDepI("BordDepDrIndex",dept,bor))
			set:bor'="" bor = $lg($g(^User.DHCExaBorDepD(bor)),6)
			s flag = 0
			if bor'=BorId {
				s flag = 1
				continue
			}
			set state = $lg($g(^User.DHCQueueD(Que)),14)
			;等候
			b ;;state
			if state = 2 {
				set waitPatientInfo = {}
				set waitPatientInfo.registerId=$lg($g(^User.DHCQueueD(Que)),10)
				set waitPatientInfo.patientName=$lg($g(^User.DHCQueueD(Que)),9)
				set waitPatientInfo.sort=$lg($g(^User.DHCQueueD(Que)),10)
				do screenInfoItem.waitPatientInfo.%Push(waitPatientInfo)
			}
			
			;复诊
			if state = 1 {
				set waitPatientInfo = {}
				set waitPatientInfo.registerId=$lg($g(^User.DHCQueueD(Que)),10)
				set waitPatientInfo.patientName=$lg($g(^User.DHCQueueD(Que)),9)
				set waitPatientInfo.sort=$lg($g(^User.DHCQueueD(Que)),10)
				do screenInfoItem.waitPatientInfo.%Push(waitPatientInfo)
			}
			
			
			;过号
			if state = 3 {
				set overPatientInfo = {}
				set overPatientInfo.registerId=$lg($g(^User.DHCQueueD(Que)),10)
				set overPatientInfo.patientName=$lg($g(^User.DHCQueueD(Que)),9)
				set overPatientInfo.sort=$lg($g(^User.DHCQueueD(Que)),10)
				do Obj.overPatientInfo.%Push(overPatientInfo)	
			}
		}
		set screenInfoItem.doctorKey = $p($g(^CTPCP(Mark,1)),"^",1)
		set screenInfoItem.doctorName = $p($g(^CTPCP(Mark,1)),"^",2)
		;set dept = $lg($g(^User.DHCExaBoroughD(Mark)),5)
		set screenInfoItem.deptName = $p($g(^CTLOC(dept)),"^",2)
		set screenInfoItem.consultName = 0 ;$lg($g(^User.DHCExaBoroughD(bor)),5)
		set screenInfoItem.shiftOut = 0
		
		if flag = 0 {
			do Obj.screenInfo.%Push(screenInfoItem)
		}
	}	
	s json = Obj.%ToJSON()
	s obj=##Class(web.DHCENS.BLL.Call.Soap.PUB0004Soap).%New()
  	
  	set obj.Timeout=5
  	s className=obj.HIPMessageShow(json).Read()
	
	s json = {}.%FromJSON(className)
  	s status = json.status
	q status
SendAdmCallInfoET
    q "-1^叫号异常:"_$ze
}
/// w ##Class(web.DHCVISQueueManage).RunNextButton("1","4783","192.168.41.234)
```

```objectscript
Class web.DHCENS.BLL.Call.Soap.PUB0004Soap Extends %SOAP.WebClient [ ProcedureBlock ]
{

/// This is the URL used to access the web service.
Parameter LOCATION = "https://10.1.143.50:1443/csp/hsb/DHC.Published.PUB0004.BS.PUB0004.cls";

/// This is the namespace used by the Service
Parameter NAMESPACE = "http://www.dhcc.com.cn";

/// Use xsi:type attribute for literal types.
Parameter OUTPUTTYPEATTRIBUTE = 1;

/// Determines handling of Security header.
Parameter SECURITYIN = "ALLOW";

/// This is the name of the Service
Parameter SERVICENAME = "PUB0004";

/// This is the SOAP version supported by the service.
Parameter SOAPVERSION = 1.1;

Method HIPMessageServer(entityBody As %String) As %Stream.GlobalCharacter [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 s ..SSLCheckServerIdentity=0
 s ..SSLConfiguration="SSLECP"
 b ;;;
 Quit ..WebMethod("HIPMessageServer").Invoke($this,"http://www.dhcc.com.cn/DHC.Published.PUB0004.BS.PUB0004.call",.entityBody)
}

Method HIPMessageShow(entityBody As %String) As %Stream.GlobalCharacter [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 s ..SSLCheckServerIdentity=0
 s ..SSLConfiguration="SSLECP"
 b ;;;
 Quit ..WebMethod("HIPMessageServer").Invoke($this,"http://www.dhcc.com.cn/DHC.Published.PUB0004.BS.PUB0004.oneShow",.entityBody)
}

}

```

```js
function callPatientHandler(event){
	var row=$("#tabPatList").datagrid('getSelected');
	var QueId = "";
   	if(row) {
		WalkStatus=row["WalkStatus"];
		if(WalkStatus == "过号") {
			QueId=row["QueRowId"];
		}
	}
	var ret=tkMakeServerCall("web.DHCVISQueueManage","RunNextButton","","",GetCacheIPAddress(),"",QueId);
	return CalledAfter(ret);
}
```

```objectscript
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
    s IPAddress = "192.168.137.1"
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
	    s RoomDr = ""
	    s QueRowid = QueId
	    s:QueRowid'="" QueRoomDr=$List(^User.DHCQueueD(QueRowid),13)
		;i QueRoomDr="" s QueRoomDr=$List(^User.DHCRegistrationFeeD(RegistDr),20)
		&sql(SELECT RoomcRoomDr into :RoomDr From SQLUser.DHCRoomComp where RoomcIp=:IPAddress)
		i QueRoomDr="" s QueRoomDr=RoomDr
		q:QueRoomDr="" "诊室计算机IP未对照,请联系信息科,IP:"_IPAddress
		&sql(SELECT BorDr into :BorDr From SQLUser.DHCBorExaRoom where BorExaRoomDr=:QueRoomDr)
		q:BorDr="" "诊室诊区未作对照,请联系信息科"
		s BorName=$List(^User.DHCExaBoroughD(BorDr),5)
		s BorCode=$List(^User.DHCExaBoroughD(BorDr),2)
		s RoomName=$P(^CTLOC(QueRoomDr),"^",2)
		s RoomCode=$P(^CTLOC(QueRoomDr),"^",1)
	    s QueObj = ##class(User.DHCQueue).%OpenId(QueId)
	    d QueObj.QueRoomDrSetObjectId(RoomDr)
		s deptKey = BorCode
		s consultKey = ""
		s voiceText = "请"_QueObj.QueName_"到"_RoomName_"就诊"
		s owner = "HIS"
		s OutputObj = {}
		s OutputObj.deptKey = deptKey
		s OutputObj.consultKey = consultKey
		s OutputObj.voiceText = voiceText
		s OutputObj.owner = owner
		s json = OutputObj.%ToJSON()
		s rtn = ##class(DHCDoc.Interface.Outside.YH.DHCDocVISService.MainMethods).SendDeptScreenInfo(QueId,BorDr,UserID)
	  	s obj=##Class(web.DHCENS.BLL.Call.Soap.PUB0004Soap).%New()
	  	set obj.Timeout=5
	  	s className=obj.HIPMessageServer(json).Read()
	  	s json = {}.%FromJSON(className)
	  	s status = json.status
		q status_"^"
	}
	q:$g(calledFlag)=1 retStr
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
/// /desc:推送诊区患者信息
/// w ##class(DHCDoc.Interface.Outside.YH.DHCDocVISService.MainMethods).SendDeptScreenInfo("429",7,"21333")
ClassMethod SendDeptScreenInfo(QueRowId As %String = "", BorId As %String = "", UserID As %String = "") As %String
{
	s $ZTrap = "SendAdmCallInfoET"
	s ^Temp("SendAdmCallInfo")=$lb(QueRowId,BorId,UserID)
	q:BorId="" ""
	s Exab = 0
	s Mark = 0
	s queid = 0
	s Date = +$h
	s Obj = {}
	s Obj.deptKey = $lg(^User.DHCExaBoroughD(BorId),2)
	s Obj.owner = "HIS"
	s Obj.type = 0
	s Obj.screenInfo = []
	s Obj.overPatientInfo = []
	
	for {
		s Mark = $o(^User.DHCQueueI("QueMarkDrIndex",Date,Mark))
		q:Mark=""
		/*
		1	01		复诊
		2	02	等候	等候
		3	03	 	过号
		4	04		到达
		5	05		退号
		6	06	 	未分配
		7	07	报到	报到
		*/
		// 向 screenInfo 数组中添加元素
		
		set screenInfoItem = {}
		set screenInfoItem.waitPatientInfo = []
		
		if Mark = $lg($g(^User.DHCQueueD(QueRowId)),8) {
			set waitPatientInfo = {}
			set waitPatientInfo.registerId=$lg($g(^User.DHCQueueD(QueRowId)),10)
			set waitPatientInfo.patientName=$lg($g(^User.DHCQueueD(QueRowId)),9)
			set waitPatientInfo.sort=0 ;$lg($g(^User.DHCQueueD(QueRowId)),10) - 1
			do screenInfoItem.waitPatientInfo.%Push(waitPatientInfo)
		}
	
		set Que = 0
		for {
			s Que = $o(^User.DHCQueueI("QueMarkDrIndex",Date,Mark,Que))
			q:Que=""
			continue:Que=QueRowId
			set dept = $lg($g(^User.DHCQueueD(Que)),4)

			set bor = 0
			set bor = $o(^User.DHCExaBorDepI("BordDepDrIndex",dept,bor))
			set:bor'="" bor = $lg($g(^User.DHCExaBorDepD(bor)),6)
			s flag = 0
			if bor'=BorId {
				s flag = 1
				continue
			}
			set state = $lg($g(^User.DHCQueueD(Que)),14)
			;等候
			if ((state = 2)||(state = 1)) {
				;s opList = ##class(DHCDoc.OPDoc.PatientList).FindLocDocCurrentAdm()
				set rs=##class(%ResultSet).%New()
				set rs.ClassName="web.DHCDocOutPatientList"
				set rs.QueryName="FindLocDocCurrentAdm"
				/// w ##class(DHCDoc.OPDoc.PatientList).FindLocDocCurrentAdm(215,21333,"","","","","","","","","","","RegQue")
				s User = $o(^SSU("SSUSR",0,"CTPCP",Mark,""))
				set sc=rs.Execute(dept,User,"","","","","","","","","","","RegQue")
				s count = 0
				while rs.Next(.sc) {
					if $$$ISERR(sc) q
					s QueId = rs.Data("QueRowId")
					s count=count+1
					if Que = QueId {
						s sort = count	
					}
				}
				set waitPatientInfo = {}
				set waitPatientInfo.registerId=$lg($g(^User.DHCQueueD(Que)),10)
				if state = 1 {
					set waitPatientInfo.patientName="(复)"_$lg($g(^User.DHCQueueD(Que)),9)
				}
				else {
					set waitPatientInfo.patientName=$lg($g(^User.DHCQueueD(Que)),9)
				}
				set waitPatientInfo.sort=$g(sort)
				do screenInfoItem.waitPatientInfo.%Push(waitPatientInfo)
			}
			
			;过号
			if state = 3 {
				set overPatientInfo = {}
				set overPatientInfo.registerId=$lg($g(^User.DHCQueueD(Que)),10)
				set overPatientInfo.patientName=$lg($g(^User.DHCQueueD(Que)),9)
				set overPatientInfo.sort=$lg($g(^User.DHCQueueD(Que)),10)
				do Obj.overPatientInfo.%Push(overPatientInfo)	
			}
		}
		set screenInfoItem.doctorKey = $p($g(^CTPCP(Mark,1)),"^",1)
		set screenInfoItem.doctorName = $p($g(^CTPCP(Mark,1)),"^",2)
		;set dept = $lg($g(^User.DHCExaBoroughD(Mark)),5)
		set screenInfoItem.deptName = $p($g(^CTLOC(dept)),"^",2)
		set screenInfoItem.consultName = 0 ;$lg($g(^User.DHCExaBoroughD(bor)),5)
		set screenInfoItem.shiftOut = 0
		
		if flag = 0 {
			do Obj.screenInfo.%Push(screenInfoItem)
		}
	}	
	s json = Obj.%ToJSON()
	s obj=##Class(web.DHCENS.BLL.Call.Soap.PUB0004Soap).%New()
  	
  	set obj.Timeout=5
  	s className=obj.HIPMessageShow(json).Read()
	
	s json = {}.%FromJSON(className)
  	s status = json.status
  	q status
SendAdmCallInfoET
    q "-1^叫号异常:"_$ze
}
```