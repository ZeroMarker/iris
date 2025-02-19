/// Creator:      周志强
/// CreatDate:    2012.03.06
/// Description:  用于执行记录处理的公共服务类
/// 错误代码说明
/// -303:执行记录状态没有变化, 不用改变
/// -304:执行记录已经执行,不能停止
/// -302:执行记录已经停止,不能再执行
/// -305:执行记录没有执行,不需要撤销
/// -306:执行记录保存失败
/// -307:执行记录变化表保存失败
/// -308:执行记录计费变化表保存失败
/// -310:执行记录扩展表保存失败
/// -301:停止医嘱执行记录失败
/// -310:计费状态相同,不用改变
/// -311:已经退费,不需要再免费
/// -313:已经待计费,不需要取消免费
/// -314:临时医嘱未停止或者撤销,不能停止执行
/// -315:修改执行记录医嘱状态失败
/// -316:已作废或撤销的临时医嘱的执行记录,不允许执行
/// -317:长期医嘱停止时间后的执行记录不允许再执行
/// -318:已经发药不允许停止执行(仅限门急诊)
Class appcom.OEOrdExec Extends DHCDoc.Util.RegisteredObject [ ClassType = "", ProcedureBlock ]
{

/// 得到默认的费别
ClassMethod GetDefaultBillType(OEORIRowId) As %String
{
	s EpisodeID=$P(^OEORD(+OEORIRowId),"^",1)
	Q:EpisodeID="" ""
	s AdmBillType=$p($g(^PAADM(EpisodeID,1)),"^",7)
	Q AdmBillType
}

/// 插入执行记录	
ClassMethod InsExecOEORE(OEORIRowId As %String, exDate As %String, Time, LinkOEORE As %String = "")
{
 s oeori = +OEORIRowId
 s suboeori = $p(OEORIRowId,"||",2)
 s AdmID=$p(^OEORD(+oeori),"^",1)
 s AdmType=$p($g(^PAADM(AdmID)),"^",2)
 s ARCIMrow	= $p(^OEORD(oeori,"I",suboeori,1),"^",2)
 s drgform=$p($g(^ARCIM(+ARCIMrow,+$p(ARCIMrow,"||",2),1)),"^",12)
 s arcgrp=$p(^ARCIM(+ARCIMrow,$p(ARCIMrow,"||",2),1),"^",10)
 s cattype=$p(^ARC("IC",arcgrp),"^",7)
 s uom=$p($g(^OEORD(oeori,"I",suboeori,2)),"^",3)
 s Dose=$p($g(^OEORD(oeori,"I",suboeori,2)),"^",1) s:'Dose Dose=1 ;Dose Qty 
 s ExecQty = Dose
 s PackQty=$p($g(^OEORD(oeori,"I",suboeori,9)),"^",4)
 s PackUOMRowid=##Class(web.DHCDocOrderCommon).GetOrdPackUOMDR(OEORIRowId)
 s baseuom=$$baseuom^DHCDocOrderCommonNew(ARCIMrow)
 i cattype="R"{
	i PackQty="" {
		s AdminQty=$$calcqty^DHCOEOrdItem(drgform,uom,ExecQty,AdmType)
	}else{
		s convFac=##class(appcom.OEDispensing).convFac(ARCIMrow,PackUOMRowid)
		s AdminQty=PackQty*convFac
	}
 }else{
	s AdminQty=ExecQty 
 }
 
 ;s LinkOEORIRowId=$p(^OEORD(oeori,"I",suboeori,11),"^",39)
 ;s billtype=..GetDefaultBillType(OEORIRowId)
 s hdate = ..%ZDH(exDate) //$zdh(exDate,1)
 s StartDate=$p(^OEORD(oeori,"I",suboeori,1),"^",9)
 s StartTime=$p(^OEORD(oeori,"I",suboeori,1),"^",10)
 if ((hdate<StartDate)!((StartDate=hdate)&&(..%ZTH(Time)<StartTime))){
	 Q "-15310"
 }
 s count=1
 s time="" f  s time= $o(^OEORDi(0,"Date",oeori,hdate,time)) q:time=""  d
 .s child = 0 f  s child=$o(^OEORDi(0,"Date",oeori,hdate,time,suboeori,child))  q:child=""  d
 ..s count=count+1
 if LinkOEORE="" {
 	d ..InsOEORE(OEORIRowId,hdate,..%ZTH(Time),ExecQty,0,AdminQty,count,"","")
 	s child=$O(^OEORDi(0,"OrdItem",+OEORIRowId,$p(OEORIRowId,"||",2),hdate,""),-1)
	if child'="" s LinkOEORE=OEORIRowId_"||"_child
 	s child=0  F {
		s child=$O(^OEORDi(0,"OEORI",+OEORIRowId,OEORIRowId,child))
		Q:child=""
		s SubRowId=+OEORIRowId_"||"_child
		s itemStatDr = $p(^OEORD(+OEORIRowId,"I",child,1),"^",13) 		;OEORI_ItemStat_DR ;OEC_OrderStatus
		s:+itemStatDr>0 TItemStatCode = $p(^OEC("OSTAT",itemStatDr),"^",1) 
		d ..InsExecOEORE(SubRowId,exDate,Time,LinkOEORE)
	}
 }else{
	d ..InsOEORE(OEORIRowId,hdate,..%ZTH(Time),ExecQty,0,AdminQty,count,LinkOEORE,"")
 }
 q 0
}

ClassMethod InsOEORE(OEORIRowId, Date, Time, ExecQty, QtyOver, AdminQty, SeqNo, LinkOEORE, XTime)
{
	q $$InsOEORE^DHCOEOrdExec(OEORIRowId,Date,Time,ExecQty,QtyOver,AdminQty,SeqNo,LinkOEORE,XTime)
	q 0
}

ClassMethod UpdateOneStatus(OEORERowId As %String, NewStatusCode As %String, UserRowId As %String, ExeDate As %Date = "", ExeTime As %Time = "", ChangeReasonRowId As %String = "", StopAllExecFlag As %String = "", Reasoncomment As %String = "", ExecCTLocDr As %String = "", IsBillN As %String = "Y", ExpStr As %String = "", ByRef ErrMsg As %String = "")
{
	s EpisodeID=$p(^OEORD(+OEORERowId),"^",1)
	s EpisodeType=$p(^PAADM(EpisodeID),"^",2)
	s ChangeBillStatus=""
	s CureAppFlag="",CureAARowId=""
	s ExtStr=""
	s err=..CheckUpdateStatus(OEORERowId,NewStatusCode , UserRowId , StopAllExecFlag,.ExtStr)
  	if (+err'=0){
	  	s ErrMsg=..%GetErrCodeMsg(err)
		Q err  
	}
	s ChangeBillStatus=$P(ExtStr,"^",1)
	s CureAppFlag=$P(ExtStr,"^",2)
	s CureAARowId=$P(ExtStr,"^",3)
	s CPRowId=##class(web.SSUser).GetDefaultCareProvider(UserRowId)
	s NewStatusRowId=$O(^OEC("STAT",0,"Code",NewStatusCode,0))
	
	if ExeDate="" s ExeDate=..%SysDate()
	if ExeTime="" s ExeTime=..%SysTime()
	Ts
	if ((CureAppFlag="I")&&(CureAARowId'="")){
		;预约未治疗的取消预约并停止执行
		d ##class(DHCDoc.DHCDocCure.Service).AppCancelHUI(CureAARowId,UserRowId,"1")
	}
	s OrdItmRowId=$P(OEORERowId,"||",1,2)
	//留观押金模式下的停止执行，需要将医嘱的计费状态改为需退费
	if (NewStatusCode="D"){
		s UseStayPayMode=##Class(DHCDoc.Interface.Inside.Service).CheckUseStayPayMode(EpisodeID)
		if (UseStayPayMode="1"){
			s BillFlag=$p($g(^OEORD(+OrdItmRowId,"I",+$p(OrdItmRowId,"||",2),3)),"^",5)
			i " B TB "[(" "_BillFlag_" ") s BillFlag="I"
			&SQL(Update SQLUser.OE_OrdItem set OEORI_Billed=:BillFlag where OEORI_rowid=:OrdItmRowId)
			if SQLCODE{
				s ErrMsg=..%GetErrCodeMsg("-100016")
				Quit "-100016" //-306
			}
		}
	}
    s obj=##class(User.OEOrdExec).%OpenId(OEORERowId)
	if '$ISObject(obj){
		 s ErrMsg=..%GetErrCodeMsg("-100016")
		Quit "-100016" //-306
	}
	d obj.OEOREOrderStatusDRSetObjectId(NewStatusRowId)
	i (ChangeBillStatus'="") s obj.OEOREBilled=ChangeBillStatus
	i (CPRowId'="") d obj.OEORECTPCPDRSetObjectId(CPRowId)
	s obj.OEOREDateExecuted=ExeDate
	s obj.OEORETimeExecuted=ExeTime
	/*
	if NewStatusCode="F" {
		i (ExeDate'="") s obj.OEOREDateExecuted=ExeDate
		i (ExeTime'="") s obj.OEORETimeExecuted=ExeTime
	}
	*/
	if NewStatusCode="D" {
		s obj.OEOREXDate=ExeDate
		s obj.OEOREXTime=ExeTime
	}
	s sc=obj.%Save()
	If $$$ISERR(sc) {
		Tro  
		s ErrMsg=..%GetErrCodeMsg("-100016")
		Quit "-100016" //-306
	}
	d obj.%Close()
	s obj=""
	
	if NewStatusCode="D" {
		s objext=##class(User.OEOrdExecExt).%OpenId(OEORERowId)
		if $ISObject(objext) {
			s DCOrderStatusRowId=$O(^OEC("OSTAT",0,"Code","D",0))
			if DCOrderStatusRowId'="" {
				d objext.OEOREOrderStatusDRSetObjectId(DCOrderStatusRowId)
				s sc=objext.%Save()
				If $$$ISERR(sc) {
					Tro  
					s ErrMsg=..%GetErrCodeMsg("-100021")
					Quit "-100021" //-312
				}
			}
			d objext.%Close()
			s objext=""
		}
	}
	if (NewStatusCode="F"){
		s objext=##class(User.OEOrdExecExt).%OpenId(OEORERowId)
		if $ISObject(objext) {
			if (ExecCTLocDr'=""){
				d objext.OEOREUserCTLOCDRSetObjectId(ExecCTLocDr)
				s WardRowID=$O(^PAWARD(0,"WARD_LocationDR",ExecCTLocDr,""))
				if (WardRowID'=""){
					d objext.OEOREUserWardDRSetObjectId(WardRowID)
				}
			}
			s sc=objext.%Save()
			If $$$ISERR(sc) {
				Tro  
				s ErrMsg=..%GetErrCodeMsg("-100021")
				Quit "-100021" //-312
			}
			d objext.%Close()
		}
		s objext=""
	}
	if NewStatusCode="C" {
		s objext=##class(User.OEOrdExecExt).%OpenId(OEORERowId)
		if $ISObject(objext) {
			d objext.OEOREUserCTLOCDRSetObjectId("")
			d objext.OEOREUserWardDRSetObjectId("")
			s sc=objext.%Save()
			If $$$ISERR(sc) {
				Tro  
				s ErrMsg=..%GetErrCodeMsg("-100021")
				Quit "-100021"
			}
			d objext.%Close()
		}
		s objext=""
	}
	;插入状态变化表
	s objstatus=##class(User.OEOrdExecStatus).%New(OEORERowId)
	d objstatus.STCHParRefSetObjectId(OEORERowId)
	d objstatus.STCHAdminStatusDRSetObjectId(NewStatusRowId)
	if ChangeReasonRowId'="" d objstatus.STCHReasonDRSetObjectId(ChangeReasonRowId)
	e  i Reasoncomment'="" s objstatus.STCHReasonComtent=Reasoncomment
	s objstatus.STCHDate=..%SysDate()
	s objstatus.STCHTime=..%SysTime()
	d objstatus.STCHUserDRSetObjectId(UserRowId)
	s sc=objstatus.%Save()
	If $$$ISERR(sc) {
		Tro  
		s ErrMsg=..%GetErrCodeMsg("-100017")
		Quit "-100017" //-307
	}
	d objstatus.%Close()
	s objstatus=""
	TC
	Q 0
}

/// Creator: 		周志强
/// CreatDate: 		2012-03-08
/// Description: 	更新执行状态
/// Table：			OE_OrdExec
/// Input：			oeoreId:医嘱执行表ID,NewStatusCode:状态代码,ChangeReasonRowId:改变原因,UserRowId:用户指针
/// Return：		0:成功返回 其他:错误代码
/// Other           w ##class(appcom.OEOrdExec).UpdateStatus("1120||57||58","F",20665,66845,48442,"","","",8,"N","")
ClassMethod UpdateStatus(OEORERowId As %String, NewStatusCode As %String, UserRowId As %String, ExeDate As %Date = "", ExeTime As %Time = "", ChangeReasonRowId As %String = "", StopAllExecFlag As %String = "", Reasoncomment As %String = "", ExecCTLocDr As %String = "", IsBillN As %String = "Y", ExpStr As %String = "", ByRef ErrMsg As %String = "") As %String
{
	s ^tempscl("UpdateStatus")=OEORERowId_","_NewStatusCode_","_UserRowId_","_ExeDate_","_ExeTime_","_ChangeReasonRowId_","_StopAllExecFlag_","_Reasoncomment_","_ExecCTLocDr_","_IsBillN_","_ExpStr
	TS
	s err=..UpdateOneStatus(OEORERowId, NewStatusCode, UserRowId, ExeDate, ExeTime, ChangeReasonRowId, StopAllExecFlag, Reasoncomment, ExecCTLocDr, IsBillN , ExpStr,.ErrMsg)
	if err{
		TRO
		Q err
	}
	s OEORERowIdStr=OEORERowId
	s OEORIRowId=$P(OEORERowId,"||",1,2)
	s Ord=+OEORERowId,ordsub=$P(OEORERowId,"||",2)
	;处理关联的执行记录的状态
	s child=0 for{
		s child=$O(^OEORDi(0,"OEORE",OEORERowId,Ord,child)) Q:child=""
		s childsub=0 for{
			s childsub=$O(^OEORDi(0,"OEORE",OEORERowId,Ord,child,childsub)) Q:childsub=""
			s OldStatusRowId=$P(^OEORD(Ord,"I",child,"X",childsub),"^",16)
			s OldStatusCode=$CASE(OldStatusRowId,"":"C",:$P($G(^OEC("STAT",OldStatusRowId)),"^",1))
			continue:(OldStatusCode="D")||(OldStatusCode=NewStatusCode)	;已经停止执行的记录不处理(护士单独作废绑定医嘱情况)
			s SubOEORE=Ord_"||"_child_"||"_childsub
			s err=..UpdateOneStatus(SubOEORE, NewStatusCode, UserRowId, ExeDate, ExeTime, ChangeReasonRowId, StopAllExecFlag, Reasoncomment, ExecCTLocDr, IsBillN , ExpStr,.ErrMsg)
			Q:err
			s OEORERowIdStr=OEORERowIdStr_"^"_SubOEORE
		}
	}
	if err{
		TRO
		Q err
	}
	;处理检查申请单关联
	s AppReportDR=$p($g(^OEORD(Ord,"I",ordsub,"DHC")),"^",42)
	if AppReportDR'=""{
		s ExpectDate=$p($g(^OEORD(Ord,"I",ordsub,"X",$p(OEORERowId,"||",3))),"^",1)
		s child=0  for {
			s child=$O(^OEORDi(0,"OEORI",Ord,OEORIRowId,child)) Q:child=""
			s childsub=0  for {
				s childsub=$O(^OEORDi(0,"OrdItem",Ord,child,ExpectDate,childsub))
				Q:childsub=""
				s LinkOEORE=$P($G(^OEORD(Ord,"I",child,"X",childsub,"BILL")),"^",3)
				continue:LinkOEORE'=""	;直接关联执行记录上方已处理
				s OldStatusRowId=$P(^OEORD(Ord,"I",child,"X",childsub),"^",16)
				s OldStatusCode=$CASE(OldStatusRowId,"":"C",:$P($G(^OEC("STAT",OldStatusRowId)),"^",1))
				continue:(OldStatusCode="D")||(OldStatusCode=NewStatusCode)	;已经停止执行的记录不处理(护士单独作废绑定医嘱情况)
				if (NewStatusCode'="F") {
					if (..GetOEORIExecValidFlag(OEORIRowId)) continue
				}
				s SubOEORE=Ord_"||"_child_"||"_childsub
				s err=..UpdateOneStatus(SubOEORE, NewStatusCode, UserRowId, ExeDate, ExeTime, ChangeReasonRowId, StopAllExecFlag, Reasoncomment, ExecCTLocDr, IsBillN , ExpStr,.ErrMsg)
				Q:err
				s OEORERowIdStr=OEORERowIdStr_"^"_SubOEORE
			}
			Q:err
		}
	}
	if err{
		TRO
		Q err
	}
    Tc
	//这里比较难以处理，用job会产生license问题，用do的话，一些不应该影响主体逻辑的事务回归，比如账单回滚又会影响主体逻辑；
	// V1 :TODO：维护系统周期1分钟任务，使用系统任务轮训中间表进行后续执行动作
	//job ..UpdateStatusInterface(OEORERowId, UserRowId, ExecCTLocDr,IsBillN)
	// V2 tanjishan 2023年6月19日, 调用公共的异步管理方法
    do ##class(DHCDoc.Util.Process).RunJobMethod("appcom.OEOrdExec","UpdateStatusInterface",OEORERowIdStr, UserRowId, ExecCTLocDr,IsBillN)
	q 0
}

/// 获取成组执行记录ID串
ClassMethod GetGroupExecIDStr(OEORERowId)
{
	s OEORERowIdStr=OEORERowId
	s OEORIRowId=$P(OEORERowId,"||",1,2)
	s ExpectDate=$p($g(^OEORD(+OEORERowId,"I",$p(OEORERowId,"||",2),"X",$p(OEORERowId,"||",3))),"^",1)
	s AppReportDR=$p($g(^OEORD(+OEORIRowId,"I",+$p(OEORIRowId,"||",2),"DHC")),"^",42)
	s child=0  F {
		s child=$O(^OEORDi(0,"OEORI",+OEORIRowId,OEORIRowId,child)) Q:child=""
		s childsub=0  F {
			s childsub=$O(^OEORDi(0,"OrdItem",+OEORIRowId,child,ExpectDate,childsub)) Q:childsub=""
			s LinkOEORE=$P($G(^OEORD(+OEORIRowId,"I",child,"X",childsub,"BILL")),"^",3)
			s SubOEORE=+OEORIRowId_"||"_child_"||"_childsub
			if OEORERowId=LinkOEORE {
				d ..UpdateStatus(SubOEORE,NewStatusCode,UserRowId,ExeDate,ExeTime,ChangeReasonRowId,StopAllExecFlag,Reasoncomment,ExecCTLocDr,IsBillN,ExpStr,.ErrMsg)
			}elseif (AppReportDR'="") {
				/*
					处理检查申请单关联的子医嘱执行记录
					主医嘱有执行记录已执行则子医嘱执行,主医嘱执行记录全部撤销时则子医嘱执行记录才能自动撤销
				*/
				if (NewStatusCode'="F") {
					if (..GetOEORIExecValidFlag(OEORIRowId)) continue
				}
				d ..UpdateStatus(SubOEORE,NewStatusCode,UserRowId,ExeDate,ExeTime,ChangeReasonRowId,StopAllExecFlag,Reasoncomment,ExecCTLocDr,IsBillN,ExpStr,.ErrMsg)
			}
		}
	}
	Q OEORERowIdStr
}

/// Creator:      周志强
/// CreatDate:    2012.03.06
/// Description:  将医嘱停止时间后的所有未执行记录变为"停止执行"状态
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OrdItmRowId:医嘱指针,UserRowId:用户指针
/// 			  XExecDateStr:以传入的时间为节点，若传空则默认以医嘱停止时间为节点；处理某个时间节点之后的所有执行记录
/// Return: 
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdExec).DiscontinueExec("531546||1",590) 
ClassMethod DiscontinueByXTime(OrdItmRowId As %String, UserRowId As %String, StopAllExecFlag As %String = "", IsBillN As %String = "Y", XExecDateStr = "") As %String
{
	s err=0
	s CurrDate=..%SysDate()
	s CurrTime=..%SysTime()
	s (XDate,XTime)=""
	if (XExecDateStr'="")&&($Length(XExecDateStr," ")=2){
		s XDate=..%ZDH($P(XExecDateStr," "))
		s XTime=..%ZTH($P(XExecDateStr," ",2))
	}else{
		s XDate=$p($g(^OEORD(+OrdItmRowId,"I",+$p(OrdItmRowId,"||",2),3)),"^",34)
		s XTime=$p($g(^OEORD(+OrdItmRowId,"I",+$p(OrdItmRowId,"||",2),2)),"^",15)
		if XTime="" s XTime=CurrTime
	}
	s SttDate=$p($g(^OEORD(+OrdItmRowId,"I",+$p(OrdItmRowId,"||",2),1)),"^",9)
	s SttTime=$p($g(^OEORD(+OrdItmRowId,"I",+$p(OrdItmRowId,"||",2),1)),"^",10)
	;如果停止时间等于医嘱开始时间,则全部停止
	if (SttDate=XDate)&&(SttTime=XTime){
		s StopAllExecFlag=1
	}
	s arcim=$p($g(^OEORD(+OrdItmRowId,"I",+$p(OrdItmRowId,"||",2),1)),"^",2)
	if arcim="" Q 0
	s OEORIUserDepDR=$p($g(^OEORD(+OrdItmRowId,"I",+$p(OrdItmRowId,"||",2),7)),"^",2)
	s OEORIUserHospDr=$p($g(^CTLOC(OEORIUserDepDR)),"^",22)
	s AutoDCFlag=..%GetConfig("StopExecByDCOrder",OEORIUserHospDr) //$g(^DHCDocConfig("StopExecByDCOrder"))
	if AutoDCFlag'=1 {
		s ItemCatRowId=+$p($g(^ARCIM(+$g(arcim),1,1)),"^",10)
		s UserDepartmentRowId=$p($g(^OEORD(+OrdItmRowId,"I",+$p(OrdItmRowId,"||",2),7)),"^",2)
		if UserDepartmentRowId'="" {
			s AutoDCFlag=$P($g(^CTLOC(UserDepartmentRowId,"DHC")),"^",8)
			if AutoDCFlag'=1 {
				if ItemCatRowId'="" {
					s AutoDCFlag=$$GetDHCARCItemCatFieldValue^DHCDocConfig(ItemCatRowId,4)
				}
			}
		}
	}
	s DCStatusRowId=$O(^OEC("STAT",0,"Code","D",0))
	s OEORERowIdStr=""
	TS
	s Sub=0  f {
		s Sub=$O(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),"X",Sub))
		Q:Sub=""
		
		s ExeDate=$P(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),"X",Sub),"^",1)
		s ExeTime=$P(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),"X",Sub),"^",2)
		if XDate>ExeDate Continue	;CurrDate换XDate
		
		;已经结算了,不能停止
		s BillStatus=$P(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),"X",Sub),"^",6)
		if BillStatus="P" Continue  
		s rowid=OrdItmRowId_"||"_Sub
		;处理小时医嘱的执行记录,置上停止时间
		if ##class(appcom.OEOrdItem).IsHourOrderItem(OrdItmRowId) {
			;小时医嘱停止提前到0点,退费会有问题;要求执行日期为当前日期则按当前时间停止,大于则停止到00:00:01
			if CurrDate'<ExeDate {
				if XTime=0 s XTime=1
			}else{
				s XTime=1
			}
			s err=##class(appcom.OEOrdExec).SetBillFlag(rowid,XTime)
			Q:err
		}
		
		s StatusRowId=$P(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),"X",Sub),"^",16)
		s StatusCode=$s(StatusRowId'="":$P($G(^OEC("STAT",StatusRowId)),"^",1),1:"")
		if (StatusCode'="")&&(StatusCode'="A")&&(StatusCode'="C")&&(StopAllExecFlag'=1) Continue
		if (StopAllExecFlag'=1)&&
			((XDate=ExeDate)&&(XTime>=ExeTime)&&(XTime'=0)) {
			//XTime如果是0，则认为当天所有的执行记录都需要停止，包括要求执行时间为0的；等同于||((XDate>ExeDate)&&(XTime=0))
			Continue	;CurrDate换XDate
		}
		&SQL(Update SQLUser.OE_OrdExecExt Set OEORE_OrderStatus_DR=:DCStatusRowId Where OEORE_RowId=:rowid)
		s err=SQLCODE
		Q:err
		s err=##class(User.OEOrdExecOrdStatus).Save(rowid_"^"_DCStatusRowId_"^"_UserRowId_"^^^^")
		Q:err
		if (AutoDCFlag=1) {
			s err=##class(appcom.OEOrdExec).UpdateOneStatus(rowid,"D",UserRowId,"","","",StopAllExecFlag,"","",IsBillN)
			Q:err
			i OEORERowIdStr="" s OEORERowIdStr=rowid
			e  s OEORERowIdStr=OEORERowIdStr_"^"_rowid
		}
	}
	if err{
		TRO 1
		Quit "-301"
	}
	TC
	if OEORERowIdStr'=""{
		do ##class(DHCDoc.Util.Process).RunJobMethod("appcom.OEOrdExec","UpdateStatusInterface",OEORERowIdStr, UserRowId, "",IsBillN)
	}
	Quit err
}

/// Creator:      周志强
/// CreatDate:    2012.03.06
/// Description:  停止执行指定的执行记录
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OrdItmRowId:医嘱Rowid,UserRowId:用户指针
/// Return: 
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdExec).Discontinue("77071||46",127) 
ClassMethod Discontinue(OEORERowId As %String, UserRowId As %String) As %String
{
}

/// Creator:      周志强
/// CreatDate:    2012.03.06
/// Description:  在医嘱撤销和作废时,将所有执行记录都停止执行
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OrdItmRowId:医嘱Rowid,UserRowId:用户指针,StopFlag:是否停止执行记录
/// Return: 
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdExec).DiscontinueAll("4485||10",5,"1","N","Y") 
ClassMethod DiscontinueAll(OrdItmRowId As %String, UserRowId As %String, StopFlag As %String = "", IsBillN As %String = "Y", StopAllExecFlag As %String = "", ExpStr = "") As %String
{
	s err=0
	s CurrDate=..%SysDate()
	s CurrTime=..%SysTime()
	if StopAllExecFlag="Y" s StopAllExecFlag="1"
	if (StopAllExecFlag'="1"){
		s LocID=$p(ExpStr,"^",4)
		s OrderStatusCode=##class(appcom.OEOrdItem).GetStatusCode(OrdItmRowId)
		s ForceDealOrder=##class(web.DHCDocMain).ForceDealOrder(OrdItmRowId,UserRowId,LocID,OrderStatusCode)
		//已经执行的医嘱不能作废或者收费不能停止
		if (ForceDealOrder'="Y")&&##class(appcom.OEOrdItem).Executed(OrdItmRowId) Quit "-100013" //-302 
	}
	
	s DCStatusRowId=$O(^OEC("STAT",0,"Code","D",0))
	s OEORERowIdStr=""
	TS
	s Sub=0  f {
		s Sub=$O(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),"X",Sub))
		Q:Sub=""
		s ExeDate=$P(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),"X",Sub),"^",1)
		s ExeTime=$P(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),"X",Sub),"^",2)
		
		;已经结算了,不能作废
		s BillStatus=$P(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),"X",Sub),"^",6)
		if BillStatus="P" Continue  
		
		s rowid=OrdItmRowId_"||"_Sub
		;处理小时医嘱的执行记录,置上停止时间(对于作废医嘱将时间置为开始时间,保证能全部账单退费)
		s XTime=ExeTime
		if ##class(appcom.OEOrdItem).IsHourOrderItem(OrdItmRowId) {
			;小时医嘱停止提前到0点,退费会有问题;要求执行日期为当前日期则按当前时间停止,大于则停止到00:00:01
			if CurrDate'<ExeDate {
				if XTime=0 s XTime=1
			}else{
				s XTime=1
			}
			s err=##class(appcom.OEOrdExec).SetBillFlag(rowid,XTime)
			Q:err
		}
		s StatusRowId=$P(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),"X",Sub),"^",16)
		continue:DCStatusRowId=StatusRowId
		s StatusCode=""
		if StatusRowId'="" s StatusCode=$P($G(^OEC("STAT",StatusRowId)),"^",1)
		if (StatusCode'="")&&(StatusCode'="A")&&(StatusCode'="C")&&(StopAllExecFlag'="1") Continue
		
		&SQL(Update SQLUser.OE_OrdExecExt Set OEORE_OrderStatus_DR=:DCStatusRowId Where OEORE_RowId=:rowid)
		s err=SQLCODE
		Q:err
		s err=##class(User.OEOrdExecOrdStatus).Save(rowid_"^"_DCStatusRowId_"^"_UserRowId_"^^^^")
		Q:err
		;临时医嘱作废或者撤销可以直接停止执行记录
		if StopFlag{
			s err=##class(appcom.OEOrdExec).UpdateOneStatus(rowid,"D",UserRowId,"","","",StopAllExecFlag,"","",IsBillN)
			Q:err
			i OEORERowIdStr="" s OEORERowIdStr=rowid
			e  s OEORERowIdStr=OEORERowIdStr_"^"_rowid
		}
	}
	if err{
		TRO 1
		s err="-100067" //-301
		Q err
	}
	TC
	if OEORERowIdStr'=""{
		do ##class(DHCDoc.Util.Process).RunJobMethod("appcom.OEOrdExec","UpdateStatusInterface",OEORERowIdStr, UserRowId, "",IsBillN)
	}
	Quit err
}

/// Creator:      周志强
/// CreatDate:    2012.03.06
/// Description:  在医嘱执行时更新所有执行记录都的医嘱状态
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OrdItmRowId:医嘱Rowid,UserRowId:用户指针
/// Return: 
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdExec).VerifyAll("531546||1",590) 
ClassMethod VerifyAll(OrdItmRowId As %String, UserRowId As %String) As %String
{
	s err=0
		
	s StatusRowId=$O(^OEC("OSTAT",0,"Code","V",0))
	s Sub=0  f {
		s Sub=$O(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),"X",Sub))
		Q:Sub=""
		s rowid=OrdItmRowId_"||"_Sub
		&SQL(Update SQLUser.OE_OrdExecExt Set OEORE_OrderStatus_DR=:StatusRowId Where OEORE_RowId=:rowid)
		do ##class(User.OEOrdExecOrdStatus).Save(rowid_"^"_StatusRowId_"^"_UserRowId_"^^^^")
		
		if SQLCODE s err=SQLCODE Quit
	}
	if err s err="-100024" //-315
	Quit err
}

/// Creator:      周志强
/// CreatDate:    2012.03.06
/// Description:  在医嘱执行时更新所有执行记录都的医嘱状态
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OrdItmRowId:医嘱Rowid,UserRowId:用户指针
/// Return: 
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdExec).ExecuteAll("531546||1",590) 
ClassMethod ExecuteAll(OrdItmRowId As %String, UserRowId As %String) As %String
{
	s err=0
	s StatusRowId=$O(^OEC("OSTAT",0,"Code","E",0))
	s Sub=0  f {
		s Sub=$O(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),"X",Sub))
		Q:Sub=""
		s rowid=OrdItmRowId_"||"_Sub
		&SQL(Update SQLUser.OE_OrdExecExt Set OEORE_OrderStatus_DR=:StatusRowId Where OEORE_RowId=:rowid)
		do ##class(User.OEOrdExecOrdStatus).Save(rowid_"^"_StatusRowId_"^"_UserRowId_"^^^^")
		if SQLCODE s err=SQLCODE Quit
	}
	if err s err="-100024" //-315
	Quit err
}

/// Creator:      周志强
/// CreatDate:    2012.03.15
/// Description:  不考虑执行状态给执行记录置免费标志,并进行计费冲负处理
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OEORERowId:执行记录指针,UserRowId:用户指针,NewStatus: I/B,ChangeReasonRowId:原因指针
/// Return: 
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdExec).FreeCharge("77071||1||12",3,"I","1")
///  NewStatus:   I表示免费,	B表示取消免费
ClassMethod FreeCharge(OEORERowId As %String, UserRowId As %String, NewStatus As %String, ChangeReasonRowId As %String = "") As %String
{
	Q:(NewStatus'="B")&&(NewStatus'="I") 0
	
	s BillStatus=$P(^OEORD(+OEORERowId,"I",$P(OEORERowId,"||",2),"X",$P(OEORERowId,"||",3)),"^",6)
	i NewStatus=BillStatus Q "-100019" //-310
	q:(NewStatus="I")&&(BillStatus="R") "-100020" //"-311"
	q:(NewStatus="B")&&(BillStatus="TB") "-100022" //"-313"
	s Adm=$p(^OEORD(+OEORERowId),"^",1)
	s ChangeBillStatus=""
	i NewStatus="I" {
		if BillStatus="B" s ChangeBillStatus="I"
		if BillStatus="TB" s ChangeBillStatus="R"
	}
	i NewStatus="B" {
		if BillStatus="I" s ChangeBillStatus="TB"
		if BillStatus="R" s ChangeBillStatus="TB"
	}
	Ts
    s obj = ##class(User.OEOrdExec).%OpenId(OEORERowId)
    if $ISObject(obj) {
	    i (ChangeBillStatus'="") s obj.OEOREBilled=ChangeBillStatus	    
	    s sc=obj.%Save()
	    If $$$ISERR(sc) Tro  Quit "-100016" //-306
	    s obj1=##class(User.OEOrdExecExt).%OpenId(OEORERowId)
	    if $ISObject(obj1) {
		    s obj1.OEOREFreeChargeFlag=$s(NewStatus="I":"Y",1:"N")
		    s sc=obj1.%Save()
		    If $$$ISERR(sc) Tro  Quit "-100068" //-309
	    }
		d obj1.%Close()
		s obj1=""		
	    d obj.%Close()
	    s obj=""
	    ;插入状态变化表
	   	s objstatus=##class(User.OEOrdExecFreeCharge).%New(OEORERowId)
		d objstatus.FCCHParRefSetObjectId(OEORERowId)
		s objstatus.FCCHFreeChargeFlag=$s(NewStatus="I":"Y",1:"N")
		if ChangeReasonRowId'="" d objstatus.FCCHReasonDRSetObjectId(ChangeReasonRowId)
		s objstatus.FCCHDate=..%SysDate()
		s objstatus.FCCHTime=..%SysTime()
		d objstatus.FCCHUserDRSetObjectId(UserRowId)
		s sc=objstatus.%Save()
		If $$$ISERR(sc) Tro  Quit "-100018" //-308
	    d objstatus.%Close()
	    s objstatus=""
    }
    Tc
    s rtn=..InvokeBill(Adm,UserRowId,OEORERowId)
    q 0
}

/// Creator:      周志强
/// CreatDate:    2012.04.13
/// Description:  将小时类医嘱的执行记录置上可计费标志
/// Table:        OE_OrdExec
/// Input:        OEORERowId:执行记录指针
/// Return: 
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdExec).SetBillFlag("77078||44||1","Y")
ClassMethod SetBillFlag(OEORERowId As %String, ExpectEndTime As %Time) As %String
{
	s exeobj=##class(User.OEOrdExec).%OpenId(OEORERowId)
	if $ISObject(exeobj) {
		s exeobj.OEOREExEnDate=exeobj.OEOREExStDate
		s exeobj.OEOREExEnTime=ExpectEndTime
		d exeobj.%Save()
		d exeobj.%Close()
		s exeobj=""
		s exeextobj=##class(User.OEOrdExecExt).%OpenId(OEORERowId)
		if $ISObject(exeextobj) {
			s exeextobj.OEOREBlillFlag="Y"
			d exeextobj.%Save()
			d exeextobj.%Close()
			s exeextobj=""
			Q 0
		}
	}

	Q 100
}

/// Creator:      周志强
/// CreatDate:    2012.04.13
/// Description:  重新设置小时类医嘱的停止时间,重新计费
/// Table:        OE_OrdExec
/// Input:        OEORERowId:执行记录指针
/// Return: 
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdExec).ResetBillFlag(OEORERowId ,ExpectEndTime)
ClassMethod ResetBillFlag(OEORERowId As %String, ExpectEndTime As %Time, UserRowId As %String) As %String
{
    i ExpectEndTime=0 s ExpectEndTime=1
	s exeobj=##class(User.OEOrdExec).%OpenId(OEORERowId)
	if $ISObject(exeobj) {
		s exeobj.OEOREExEnDate=exeobj.OEOREExStDate
		set maxTime = ..%ZTH("23:59:59"),minTime = ..%ZTH("00:00:01")
		set exeobj.OEOREExEnTime=$s((maxTime<ExpectEndTime):maxTime,(ExpectEndTime<minTime):minTime,1:ExpectEndTime)
		if exeobj.OEOREBilled="B" {
			s exeobj.OEOREBilled="I"
		}elseif (exeobj.OEOREBilled="R") {
			s exeobj.OEOREBilled="I"
		}
			
		d exeobj.%Save()
		d exeobj.%Close()
		s exeobj=""
		s exeextobj=##class(User.OEOrdExecExt).%OpenId(OEORERowId)
		if $ISObject(exeextobj) {
			s exeextobj.OEOREBlillFlag="Y"
			d exeextobj.%Save()
			d exeextobj.%Close()
			s exeextobj=""

			s EpisodeID=$p(^OEORD(+OEORERowId),"^",1)
			if EpisodeID'="" {
                d ..InvokeBill(EpisodeID,UserRowId,OEORERowId)
			}

			Q 0
		}
	}

	Q 100
}

/// 执行记录添加备注 
/// add：2017-5-24 LX
/// w ##class(appcom.OEOrdExec).UpdateExecNotes("4||80||1","测试")
ClassMethod UpdateExecNotes(OEORERowId As %String, Notes As %String) As %String
{
	q:OEORERowId="" "-15500"
	Ts
	s obj=##class(User.OEOrdExec).%OpenId(OEORERowId)
	if $ISObject(obj) {
	 	s obj.OEORENotes=Notes
	    s sc=obj.%Save()
	    If $$$ISERR(sc) Tro  Quit "-15500"
	    d obj.%Close()
	}
    Tc
    q 0
}

/// 打开编辑执行记录备注界面 获取执行记录备注信息
ClassMethod GetOEORIExecNotes(OEORERowId As %String) As %String
{
	s Notes=""
	s obj=##class(User.OEOrdExec).%OpenId(OEORERowId)
	if $ISObject(obj) {
	 	s Notes=obj.OEORENotes
	    d obj.%Close()
	}
	q Notes
}

// 判断医嘱的执行记录是否有存在有效记录

ClassMethod GetOEORIExecValidFlag(OEORIRowId As %String) As %String
{
	s isExistValidExec=0
	s OEOREChildsub=0
	for {
		s OEOREChildsub=$o(^OEORD(+OEORIRowId,"I",$p(OEORIRowId,"||",2),"X",OEOREChildsub)) Q:(OEOREChildsub="")||(isExistValidExec=1)
		s OrderStatusCode=""
		s OrderStatusRowId=$P($g(^OEORD(+OEORIRowId,"I",$P(OEORIRowId,"||",2),"X",OEOREChildsub)),"^",16)
		s OrderStatusCode=$S(OrderStatusRowId'="":$P(^OEC("OSTAT",OrderStatusRowId),"^",1),1:"")
		if (OrderStatusCode="")||(OrderStatusCode="F") s isExistValidExec=1
	}
	Q isExistValidExec
}

/// 判断是否可以操作执行记录
ClassMethod CheckUpdateStatus(OEORERowId As %String, NewStatusCode As %String, UserRowId As %String, StopAllExecFlag As %String = "", ByRef ExtStr As %String = "") As %String
{
	s ChangeBillStatus=$P(ExtStr,"^",1)
	s CureAppFlag=$P(ExtStr,"^",2)
	s CureAARowId=$P(ExtStr,"^",3)
	
	s OldStatusCode=""
	s OldStatusRowId=$P(^OEORD(+OEORERowId,"I",$P(OEORERowId,"||",2),"X",$P(OEORERowId,"||",3)),"^",16)
	if OldStatusRowId'="" s OldStatusCode=$P($G(^OEC("STAT",OldStatusRowId)),"^",1)
	;检查多部位医嘱的部位是否全部停止
	s AppAllStop=##class(DHCDoc.DHCApp.Filter).IsAppAllStopFlag(OEORERowId)
 	if (OldStatusCode=NewStatusCode)&&(AppAllStop'="1") Quit "-100078" //-303
	s BillStatus=$P(^OEORD(+OEORERowId,"I",$P(OEORERowId,"||",2),"X",$P(OEORERowId,"||",3)),"^",6)
	s EpisodeID=$p(^OEORD(+OEORERowId),"^",1)
	s EpisodeType=$p(^PAADM(EpisodeID),"^",2)
	s ARCIMRowId=$p(^OEORD(+OEORERowId,"I",$P(OEORERowId,"||",2),1),"^",2)
	s ItemCatRowid=$p(^ARCIM($p(ARCIMRowId,"||",1),$p(ARCIMRowId,"||",2),1),"^",10)
	s OrderType=$P(^ARC("IC",ItemCatRowid),"^",7)
	s UserEMVirtualtLong=##Class(web.DHCDocOrderVirtualLong).GetUserEMVirtualtLong(EpisodeID)
	s UseStayPayMode=##Class(DHCDoc.Interface.Inside.Service).CheckUseStayPayMode(EpisodeID)
	
  	;如果需停止的执行记录未账单并且已经发药,先做账单退费,以避免漏费
	if (EpisodeID'=""),BillStatus'="B",##class(appcom.OEDispensing).Collected(OEORERowId) {
		s Conf=$O(^DHCTarC("CF",""))
		s TotalBillFalg=$s(Conf'="":$p(^DHCTarC("CF",Conf),"^",5),1:"")
		s MotherEpisodeID=$P($g(^PAADM(EpisodeID)),"^",75)
		//如果计费设置的是包含新生儿费用,调用账单程序时需要传入母亲的就诊指针 2013.3.12 zhouzq
        //计费自己判断了母亲数据
		#; if (TotalBillFalg="Y") && (MotherEpisodeID'="") {
		#; 	d ##Class(web.UDHCJFBILL).BILLN(MotherEpisodeID,UserRowId,"")
		#; }else{
		#; 	d ##Class(web.UDHCJFBILL).BILLN(EpisodeID,UserRowId,"")
		#; }
        d ..InvokeBill(EpisodeID,UserRowId,OEORERowId)
		s BillStatus=$P(^OEORD(+OEORERowId,"I",$P(OEORERowId,"||",2),"X",$P(OEORERowId,"||",3)),"^",6)
	}
 	if NewStatusCode="D" {
	 	s PriorityDR=$p($g(^OEORD(+OEORERowId,"I",$P(OEORERowId,"||",2),1)),"^",8)
	 	s ExeOrderStatusId=$P($g(^OEORD(+OEORERowId,"I",$P(OEORERowId,"||",2),"X",$P(OEORERowId,"||",3),"BILL")),"^",1)
		s ExeStatusCode=$S(ExeOrderStatusId'="":$P($G(^OEC("OSTAT",ExeOrderStatusId)),"^",1),1:"")
		;治疗记录已经预约,不能停止执行
		;已经治疗的治疗记录不允许停止,下方事务中添加取消治疗预约'AppCancelHUI'方法调用
		s AppFlag=##class(DHCDoc.DHCDocCure.Service).GetExecCureAppStatus(OEORERowId)
		if AppFlag'=""{
			s CureAARowId=$p(AppFlag,"^",2)
			s CureAppFlag=$p(AppFlag,"^",1)
			if (CureAppFlag="A"){
				Q "-100027" //-318
			}
		}
		//已结算的执行记录不允许再停止执行
		if (BillStatus="P"){
			Q "-100028" //-319
		}
		s DCARowID=$o(^DHCDocCure(0,"OEORI",+OEORERowId_"||"_$P(OEORERowId,"||",2),""))
		if DCARowID=""{
			s DCALinkOrdItemID=$p($g(^OEORD(+OEORERowId,"I",$p(OEORERowId,"||",2),11)),"^",39)
			s:DCALinkOrdItemID'="" DCARowID=$o(^DHCDocCure(0,"OEORI",DCALinkOrdItemID,""))
		}
		//2016-06-15如果是治疗项目则不判断医嘱的状态
		//虚拟长期模式下，临时医嘱可以按照执行记录进行退费
		//if (UserEMVirtualtLong="0")||((UserEMVirtualtLong="1")&&(OrderType'="R")){
		if (UserEMVirtualtLong="0"){
			if ##class(appcom.OEOrdItem).ISShortOrderPrior(PriorityDR),ExeStatusCode'="U",ExeStatusCode'="C",ExeStatusCode'="D",DCARowID=""{
				 Q "-100023" //-314
			}
		}
		//留观押金模式，做自动退药处理
		if EpisodeType'="I",##class(appcom.OEDispensing).Collected(OEORERowId),UseStayPayMode=0 Q "-100027" //-318
		if (OldStatusCode="F")&&(StopAllExecFlag'=1) Quit "-100014" //-304
		if ##class(appcom.OEOrdItem).IsHourOrderItem(OEORERowId) {
			s Conf=$O(^DHCTarC("CF",""))
			s TotalBillFalg=$s(Conf'="":$p(^DHCTarC("CF",Conf),"^",5),1:"")
			s MotherEpisodeID=$P($g(^PAADM(EpisodeID)),"^",75)
			//如果计费设置的是包含新生儿费用,调用账单程序时需要传入母亲的就诊指针 2013.3.12 zhouzq
            d ..InvokeBill(EpisodeID,UserRowId,OEORERowId)
			s BillStatus=$P(^OEORD(+OEORERowId,"I",$P(OEORERowId,"||",2),"X",$P(OEORERowId,"||",3)),"^",6)
			if " B TB "[(" "_BillStatus_" ") s ChangeBillStatus="I"
		}else{
			if BillStatus="B" s ChangeBillStatus="I"
			if BillStatus="TB" s ChangeBillStatus="I"
		}
	}
			
 	if NewStatusCode="F" {
	 	if OldStatusCode="D" Q "-100013" //-302
	 	s OrderStatusCode=""
	 	s PriorityDR=$p($g(^OEORD(+OEORERowId,"I",+$p(OEORERowId,"||",2),1)),"^",8)
		s OrderStatusRowId=$P($g(^OEORD(+OEORERowId,"I",$P(OEORERowId,"||",2),"X",$P(OEORERowId,"||",3),"BILL")),"^",1)
		s OrderStatusCode=$S(OrderStatusRowId'="":$P(^OEC("OSTAT",OrderStatusRowId),"^",1),1:"")
		if ##class(appcom.OEOrdItem).ISShortOrderPrior(PriorityDR) {
 			if OrderStatusCode="D" Q "-100025" //-316
 			if OrderStatusCode="C" Q "-100025" //-316
 			if OrderStatusCode="U" Q "-100025"	//-316	
		}else{
 			if OrderStatusCode="D" Q "-100025" //-317
 			if OrderStatusCode="C" Q "-100025" //-317
 			if OrderStatusCode="U" Q "-100025" //-317	
		}
		;if BillStatus="B" s ChangeBillStatus="TB"
		;药品未审核,不能执行
		/*2020-07-07 以下判断会导致同一组医嘱,皮试的能执行,非皮试的不能执行bug,8.4版本取消判断药房配置【发药前需要药师审核的判断】,下一版本护理组单独开发配置*/
		;非皮试的药品医嘱判断药房是否审核
		/*s skintest=$p($g(^OEORD(+OEORERowId,"I",+$p(OEORERowId,"||",2),5)),"^",2)
		s OrdPriorityDR=$p(^OEORD(+OEORERowId,"I",+$p(OEORERowId,"||",2),1),"^",8)
		s PriorCode=$p($g(^OECPR(OrdPriorityDR)),"^")
		if (skintest'="Y")&&(PriorCode'="OM")&&(PriorCode'="OMST")&&(PriorCode'="OMCQZT")&&(PriorCode'="OMLSZT"){
			Set IPMonitorResult=##class(web.DHCSTINTERFACE).GetOrdIPMonitorResult($p(OEORERowId,"||",1,2))
			if (IPMonitorResult="N"){
				Quit "-3177"
			}
		}*/
	}

 	if NewStatusCode="C" {
		if (OldStatusCode'="F") Quit "-100015" //-305
		;撤销执行时不改变计费状态
		;if BillStatus="B" s ChangeBillStatus="I"
		;if BillStatus="TB" s ChangeBillStatus="R"
	}
	
	s $P(ExtStr,"^",1)=ChangeBillStatus
	s $P(ExtStr,"^",2)=CureAppFlag
	s $P(ExtStr,"^",3)=CureAARowId
	
	q 0
}

/// Creator:      宋春莉
/// CreatDate:    2020.07.02
/// Description:  医技科室执行/撤销执行医嘱时，根据配置是否同步更新执行医嘱数据
/// Table:        OE_OrdExec
/// Input:        OEORERowId:执行记录指针,UserRowId:用户指针
/// 			  ExpStr:执行时间^执行科室
/// Return: 
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdExec).DelaWithExecAll("531546||1",590) 
ClassMethod DelaWithExec(OEORERowId As %String, UserRowId As %String, NewStatusCode As %String, ExpStr As %String = "") As %String
{
	s Err=0
	s OldStatusCode=""
	s OldStatusRowId=$P(^OEORD(+OEORERowId,"I",$P(OEORERowId,"||",2),"X",$P(OEORERowId,"||",3)),"^",16)
	if OldStatusRowId'="" s OldStatusCode=$P($G(^OEC("STAT",OldStatusRowId)),"^",1)
	Q:(NewStatusCode="C")&&(OldStatusCode'="F") Err
	Q:(NewStatusCode="F")&&(OldStatusCode="D") Err
	Q:(NewStatusCode=OldStatusCode) Err

	s ExecuteDateStr=$P(ExpStr,"^",1)
	s (ExeDate,ExeTime)=""
	if (ExecuteDateStr'=""){
		s ExeDate=$P(ExecuteDateStr," "), ExeTime=$P(ExecuteDateStr," ",2)
		s ExeDate=..%ZDH(ExeDate),ExeTime=..%ZTH(ExeTime)
	}
	//执行科室
	s ExecCTLocDr=$P(ExpStr,"^",2)
	s Err=##class(appcom.OEOrdExec).UpdateStatus(OEORERowId,NewStatusCode,UserRowId,ExeDate,ExeTime,"","","",ExecCTLocDr,"N")
	Q Err
}

/// Creator:      宋春莉
/// CreatDate:    2020.07.02
/// Description:  医技科室执行/撤销执行医嘱时，根据配置是否同步更新执行医嘱数据
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OrdItmRowId:医嘱指针,UserRowId:用户指针
/// 			  ExpStr:执行时间^执行科室
/// Return: 	  
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdExec).DelaWithExecAll("531546||1",590) 
ClassMethod DelaWithExecAll(OrdItmRowId As %String, UserRowId As %String, NewStatusCode As %String, ExpStr As %String = "") As %String
{
	s Err=0
	s Sub=0  f {
		s Sub=$O(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),"X",Sub))
		Q:Sub=""
		s OEORERowId=$p(OrdItmRowId,"||",1,2)_"||"_Sub
		s Err=..DelaWithExec(OEORERowId,UserRowId,NewStatusCode,ExpStr)
		if Err Q
	}
	Q Err
}

ClassMethod UpdateStatusInterface(OEORERowIdStr As %String, UserRowId As %String, ExecCTLocDr As %String, IsBillN As %String) As %String
{
	for i=1:1:$L(OEORERowIdStr,"^"){
		s OEORERowId=$P(OEORERowIdStr,"^",i)
		continue:OEORERowId=""
		d ..UpdateOneStatusInterface(OEORERowId, UserRowId, ExecCTLocDr, IsBillN)
	}
	Q 0
}

/// 更新执行记录状态的后处理程序，该方法不校验处理结果
/// 防止其他产品组内部对事务或者变量作用域处理有问题，故封装在一起
ClassMethod UpdateOneStatusInterface(OEORERowId As %String, UserRowId As %String, ExecCTLocDr As %String, IsBillN As %String) As %String
{
	s $ZT="UpdateOneStatusInterfaceErr"
	q:(OEORERowId="") ""
	s EpisodeID=$P($G(^OEORD(+OEORERowId)),"^",1)
	q:(EpisodeID="") ""
	;为了防止以下方法内部未处理内部并发逻辑，这里加锁处理下
	Lock +^OEORDUpdateStatus(+OEORERowId):30
	if $TEST {
		s NewStatusCode=""
		s NewStatusRowId=$P(^OEORD(+OEORERowId,"I",$P(OEORERowId,"||",2),"X",$P(OEORERowId,"||",3)),"^",16)
		if NewStatusRowId'="" s NewStatusCode=$P($G(^OEC("STAT",NewStatusRowId)),"^",1)
		s LinkOEORIRowId=$p(^OEORD(+OEORERowId,"I",$P(OEORERowId,"||",2),11),"^",39)
	    	;加逻辑库存
	    	if '##class(appcom.OEDispensing).Collected(OEORERowId) {
			if (NewStatusCode="D") {
		    		d ##Class(appcom.OEDispensing).Return(OEORERowId)
	    		}
		}
		;产生退药单
		if NewStatusCode="D" d ##Class(web.DHCSTRETREQUEST).CreateDrugReqByXtime(OEORERowId,UserRowId,ExecCTLocDr)
		if NewStatusCode="D" d ##class(BILL.PKG.SRV.Interface).IDeductCancel(OEORERowId,UserRowId)
		;if LinkOEORIRowId="" 
		//d ##class(Nur.DHCInstrAttOrdByWard).ExcuteInstrAttOrdNew(OEORERowId,NewStatusCode,ExecCTLocDr,UserRowId)
		d ##class(Nur.NIS.Service.OrderExcute.ExecuteBindOrder).ExcuteBindOrd(OEORERowId,NewStatusCode,ExecCTLocDr,UserRowId)
		if IsBillN'="N" {
			#; d ##Class(web.UDHCJFBILL).BILLN(EpisodeID, UserRowId, OEORERowId, 1)
			#; s MotherAdm=$p($g(^PAADM(EpisodeID)),"^",75)
			#; if MotherAdm'="" d ##Class(web.UDHCJFBILL).BILLN(MotherAdm, UserRowId, OEORERowId, 1)
            d ..InvokeBill(EpisodeID, UserRowId, OEORERowId)
		}
		///处方跟踪  bobo
		s FindCTLOCID=$p($g(^OEORD(+OEORERowId,"I",$p(OEORERowId,"||",2),7)),"^",2)
		s prescNo=$p($g(^OEORD(+OEORERowId,"I",+$p(OEORERowId,"||",2),1)),"^",14)   //处方号
		s FindOrdItem=$g(^OEORD("XJZY","FindS",+OEORERowId_"||"_+$p(OEORERowId,"||",2)))
		if $d(^PHAPRESTRACKi("MOEORI",+OEORERowId_"||"_+$p(OEORERowId,"||",2))) d
		.i (NewStatusCode="F") d ##class(web.DHCINPHA.HMPresTrack.SqlDbPresTrack).HandlePresTrackDB("^"_OEORERowId_"^"_prescNo_"^B2^"_FindCTLOCID_"^"_UserRowId)
		.i (NewStatusCode="D") d ##class(web.DHCINPHA.HMPresTrack.SqlDbPresTrack).HandlePresTrackDB("^"_OEORERowId_"^"_prescNo_"^B5^"_FindCTLOCID_"^"_UserRowId)
		.i (NewStatusCode="C") d ##class(web.DHCINPHA.HMPresTrack.SqlDbPresTrack).HandlePresTrackDB("^"_OEORERowId_"^"_prescNo_"^B3^"_FindCTLOCID_"^"_UserRowId)
		
		//执行和停止执行，需要调用药房增减基数药库存
		if (NewStatusCode="F"){
			d ##class(PHA.FACE.OUT.Com).ExeDisp(+OEORERowId_"||"_+$p(OEORERowId,"||",2),$p(OEORERowId,"||",3), ExecCTLocDr, UserRowId)
		}elseif(NewStatusCode="D"){
			d ##class(PHA.FACE.OUT.Com).ExeReturn(+OEORERowId_"||"_+$p(OEORERowId,"||",2),$p(OEORERowId,"||",3), ExecCTLocDr, UserRowId)	
		}
		//调用护士站接口,根据体征关联医嘱项配置插入或删除体征
		/*if (NewStatusCode="F"){
			d ##class(Nur.NIS.Service.VitalSign.MRCObservationItem).AddOrDelObsByRelateItmMast(OEORERowId,1)
		}else{
			d ##class(Nur.NIS.Service.VitalSign.MRCObservationItem).AddOrDelObsByRelateItmMast(OEORERowId,0)
		}*/
		s SynStatusCode=$CASE(NewStatusCode,"F":"EXEC","D":"SEXEC","C":"REXEC",:"")
		if SynStatusCode'=""{
			d ##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.ord.exec.NurSynStatus", OEORERowId,SynStatusCode, "",UserRowId,ExecCTLocDr)
		}
		;HRP入库
		if (NewStatusCode="D") d ##class(DHCDoc.Interface.Outside.HRPService).ReturnMaterialStock("",OEORERowId)
	}
	Lock -^OEORDUpdateStatus(+OEORERowId)
	;集成平台接口,执行和停止执行时发送消息
	if NewStatusCode="F" {
		;d ##class(web.DHCENS.EnsHISService).DHCHisInterface("SENDNURORDITEMINFO",OEORERowId)
	}
	if NewStatusCode="D" {
		;同步执行记录给平台
		d ##class(web.DHCENS.EnsHISService).DHCHisInterface("STOPORDEREXECINFO",OEORERowId)	
	}
	q ""
UpdateOneStatusInterfaceErr
	s $ZT=""
	if (+$G(OEORERowId)'=0){
		s LogDesc="处理执行记录状态变更失败"
		s LogDesc=LogDesc_",错误消息:"_$G(%msg)_":"_$ZERROR
		d ##class(DHCDoc.Log.Common).General("Update","appcom.OEOrdExec","UpdateOneStatusInterface",LogDesc,OEORERowId,OEORERowId_","_UserRowId_","_ExecCTLocDr_","_$G(NewStatusCode))
		Lock -^OEORDUpdateStatus(+OEORERowId)
	}
	q ""
}

/// Creator:      lixu
/// CreatDate:    2024.06.05
/// Description:  调用计费组账单方法(住院按照执行记录，门诊按照医嘱)
/// Note:         如果传入的是小孩的就诊ID、不需再调用母亲的传入(计费组自己已处理)
/// Input:        OrdExecStr:执行记录ID串(^)、OrderStr:医嘱ID串(^)
/// Return: 
/// Others:       w ##class(appcom.OEOrdExec).InvokeBill("4||80||1","测试")
ClassMethod InvokeBill(AdmID As %String, UserID As %String, OrdExecStr As %String = "", OrderStr As %String = "") As %String
{
    s ^templx("InvokeBill")=$lb(AdmID,UserID,OrdExecStr,OrderStr)
    s needBillOrdStr=""
	s PAADMType=$p($g(^PAADM(AdmID)),"^",2)
    if PAADMType="I" {
        if ((OrdExecStr="")&&(OrderStr'="")){
            for len=1:1:$l(OrderStr,"^"){
                s OrderID=$p(OrderStr,"^",len)
                Continue:OrderID'["||"
                s ExecSub=0 
                for {
                    s ExecSub=$o(^OEORD(+OrderID,"I",$p(OrderID,"||",2),"X",ExecSub))
                    Q:ExecSub=""
                    if (OrdExecStr="") s OrdExecStr=OrderID_"||"_ExecSub
                    else  s OrdExecStr=OrdExecStr_"^"_OrderID_"||"_ExecSub
                }
            }
        }
        s needBillOrdStr=OrdExecStr
    }else{
        if ((OrdExecStr'="")&&(OrderStr="")){
            for len=1:1:$l(OrdExecStr,"^"){
                s OrdExecID=$p(OrdExecStr,"^",len)
                Continue:OrdExecID'["||"
                if (OrderStr="") s OrderStr=$p(OrdExecID,"||",1,2)
                else  s OrderStr=OrderStr_"^"_$p(OrdExecID,"||",1,2)
            }
        }
        s needBillOrdStr=OrderStr
    }
    s BillNFlag=$s(needBillOrdStr'="":1,1:0)
    s rtn= ##Class(web.UDHCJFBILL).BILLN(AdmID,UserID,needBillOrdStr,BillNFlag)
	Q rtn
}

}
