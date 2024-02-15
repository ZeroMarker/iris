/// 名称:     web.DHCOEOrdItem
/// 描述:     医嘱录入的控制类
/// 编写者:   周志强
/// 编写日期: 2009.02.20
/// 适用医院?深圳中医院;沈阳医科大医院;地坛医院;北京妇产医院;衢州人民医院;
/// 珠海人民医院;潍坊人民医院
Class web.DHCOEOrdItem Extends DHCDoc.Util.RegisteredObject [ ClassType = "", Not ProcedureBlock ]
{

/// modify:郭荣勇
/// date:2015-07-08
/// Desc:护士批量输入医嘱保存
ClassMethod InsertContinuousOrder(AdmStr As %String, UserAddRowid As %String, CTLOCRowid As %String, Orditmstr As %String)
{
	n (AdmStr,UserAddRowid,CTLOCRowid,Orditmstr)
	Set Config=##Class(websys.Configuration).%OpenId(1)
	Set MEDDATA=Config.DataNamespace
	Set LABDATA=Config.LabDataNamespace
	Set CurrentNS=$ZNSPACE
	Set Ret=100
	
	Set Doc=$p($g(^SSU("SSUSR",UserAddRowid)),"^",14)
	Set OrderPriorRowid=$O(^OECPR(0,"Code","NORM",0))
	
	
	;插入过程如果出现错误,全部回滚
	s TroFlag=0
	TS
	s Admcount=$L(AdmStr,$C(1))
	For iAdm=1:1:Admcount {
		s AdmTmp=$p(AdmStr,$C(1),iAdm)
		s Adm=$p(AdmTmp,$C(2),1)
		s PackQty=$p(AdmTmp,$C(2),2)
		s ContinuousOrdQty=PackQty
		
		Set OrdItemStr="",SeqNo=0
		Set Orditmcount=$L(Orditmstr,$C(1))
		For i=1:1:Orditmcount {
			s OrditmTmp=$p(Orditmstr,$C(1),i)
			Set ARCIMRowid=$p(OrditmTmp,$C(2),1)
			i ContinuousOrdQty=""{
				;取每个医嘱限制的数量
				s PackQty=$p(OrditmTmp,$C(2),2)    
			}
			i (ARCIMRowid="")||(PackQty="") {continue}
			Set SeqNo=SeqNo+1
			Set OrderStartDate=$zd(+$h,4)
			Set OrderStartTime=..%ZT(..%SysTime(),2)
			Set ItemCatDR=$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",10)
			Set OrderType=$P(^ARC("IC",ItemCatDR),"^",7)
			Set OrderRecDepRowid=$$GetRecloc^DHCDocOrderCommonNew(Adm,ARCIMRowid)
			Set BillTypeRowid=$P(^PAADM(Adm,1),"^",7)
			Set FreqRowid=""
			Set InstrRowid=""
			Set DurRowid=""
			s DrgFormRowid=##class(web.DHCDocOrderEntry).GetDrgForm(ARCIMRowid)
			i DrgFormRowid'="" {
				s PHCDRowid=$P(DrgFormRowid,"||",1)
		    	s ChildSub=$P(DrgFormRowid,"||",2)
		    	s FreqRowid=$p($g(^PHCD(PHCDRowid,"DF",ChildSub,1)),"^",4)
		    	s InstrRowid=$p($g(^PHCD(PHCDRowid,"DF",ChildSub,1)),"^",5)
		    	s DurRowid=$p($g(^PHCD(PHCDRowid,"DF",ChildSub,1)),"^",8)
			}
			Set DoseQtySum=PackQty
			i OrdItemStr="" {
				Set OrdItemStr=ARCIMRowid_"^"_OrderType_"^"_OrderPriorRowid_"^"_OrderStartDate_"^"_OrderStartTime_"^"_PackQty_"^"_""_"^"_OrderRecDepRowid_"^"_BillTypeRowid_"^"_DrgFormRowid_"^"_"" 
				Set OrdItemStr=OrdItemStr_"^"_""_"^"_""_"^"_DoseQtySum_"^"_FreqRowid_"^"_DurRowid_"^"_InstrRowid
				Set OrdItemStr=OrdItemStr_"^"_""_"^"_""_"^"_SeqNo
			}else{
				Set OneOrderItemStr=ARCIMRowid_"^"_OrderType_"^"_OrderPriorRowid_"^"_OrderStartDate_"^"_OrderStartTime_"^"_PackQty_"^"_""_"^"_OrderRecDepRowid_"^"_BillTypeRowid_"^"_DrgFormRowid_"^"_"" 
				Set OneOrderItemStr=OneOrderItemStr_"^"_""_"^"_""_"^"_DoseQtySum_"^"_FreqRowid_"^"_DurRowid_"^"_InstrRowid
				Set OneOrderItemStr=OneOrderItemStr_"^"_""_"^"_""_"^"_SeqNo
				Set OrdItemStr=OrdItemStr_$C(1)_OneOrderItemStr
			}
		}
		continue:OrdItemStr=""
		Set Ret=..InsertOrderItem(Adm,OrdItemStr,UserAddRowid,CTLOCRowid,Doc,"1")
		if (Ret=0)!(Ret=100) {
			s TroFlag=1
			Quit
		}else{
			d ..UpdateOrderStatus(Ret,Adm,UserAddRowid,CTLOCRowid)
		}
	}
	i TroFlag=0 {
		TC
	}else{
		TRO
	}
	
	Q:Ret["*" "0"
	QUIT Ret
}

/// 取消执行医嘱
ClassMethod CancelExcute(OrdItmRowId As %String, UserRowId As %String, CancelReason As %String) As %String
{
	s StatusRowId=$O(^OEC("OSTAT",0,"Code","V",0))
	s CancelReason=$LISTBUILD(CancelReason)
	&SQL(Update SQLUser.OE_OrdItem Set OEORI_DepProcNotes=:CancelReason Where OEORI_RowId=:OrdItmRowId)
	if SQLCODE Q SQLCODE
	Q ..UpdateStatus(OrdItmRowId,UserRowId,StatusRowId)
}

/// 方法已经停用，停用版本8.3,8.3后走新的实习医生录入，不再走医嘱表
/// Creator:      徐鹏
/// CreatDate:    2009.03.27
/// Description:  删除未激活的医嘱
/// Table:        OE_OrdItem,OEC_OrderStatus
/// Input:        OrdItemStr:医嘱Rowid串,以"^"作为分隔符
/// Return: 
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:        
ClassMethod DeleteUnActiveOrderItems(OrdItemStr As %String, UserID As %String = "") As %Status
{
	// w ##class(web.DHCOEOrdItem).DeleteUnActiveOrderItems("129842||527")
	s ^tempqujian("DeleteUnActiveOrderItems")=OrdItemStr_","_ UserID
	TStart
	s Err=0
	s Len=$l(OrdItemStr,"^")
	f i=1:1:Len q:Err'=0  d
	.s OeoriRowid=$p(OrdItemStr,"^",i)
	.s OrderRowid=$p(OeoriRowid,"||",1)
	.s SubChild=$p(OeoriRowid,"||",2)
	.q:'$d(^OEORD(OrderRowid,"I",SubChild))
	.s PracticeConfirmStopStatus=$P($G(^OEORD(OrderRowid,"I",SubChild,"DHC")),"^",51)
	.b ;092323
	.if PracticeConfirmStopStatus'="" d
	..s rtnn= ##class(appcom.OEOrdItem).CancleExtIfPractice(OeoriRowid,UserID)
	.q:PracticeConfirmStopStatus'=""
	.s OeoriStatusDR=$p($g(^OEORD(OrderRowid,"I",SubChild,1)),"^",13)
	.s OeoriStatusCode=$p($g(^OEC("OSTAT",OeoriStatusDR)),"^",1)
	.i OeoriStatusCode'="I" s Err=10001 q
	.//处理在途数
	.s OEOREChildsub=0
	.f  s OEOREChildsub=$o(^OEORD(OrderRowid,"I",SubChild,"X",OEOREChildsub)) q:OEOREChildsub=""  d
	..d ##Class(appcom.OEDispensing).Return(OeoriRowid_"||"_OEOREChildsub)
	.&sql(delete from SQLUser.OE_OrdItem where OEORI_Rowid=:OeoriRowid)
	.i SQLCODE s Err=SQLCODE q
	.//医生审核拒绝时给平台推送信息
	.s Adm=$p(^OEORD(OrderRowid),"^",1)
	.d ##class(web.DOC.PortalService).TaskNeedAuditOEItem("S00000028",OeoriRowid,3,Adm)
	.s LinkSub=0
	.f  s LinkSub=$o(^OEORDi(0,"OEORI",OrderRowid,OeoriRowid,LinkSub)) q:((LinkSub="")||(Err'=0))  d
	..s OeoriStatusDR=$p($g(^OEORD(OrderRowid,"I",LinkSub,1)),"^",13)
	..s OeoriStatusCode=$p($g(^OEC("OSTAT",OeoriStatusDR)),"^",1)
	..i OeoriStatusCode'="I" s Err=10001 q
	..s LinkOeoriRowid=OrderRowid_"||"_LinkSub
	..//处理在途数
	..s OEOREChildsub=0
	..f  s OEOREChildsub=$o(^OEORD(OrderRowid,"I",LinkSub,"X",OEOREChildsub)) q:OEOREChildsub=""  d
	...d ##Class(appcom.OEDispensing).Return(LinkOeoriRowid_"||"_OEOREChildsub)
	..&sql(delete from SQLUser.OE_OrdItem where OEORI_Rowid=:LinkOeoriRowid)
	..i SQLCODE s Err=SQLCODE q
	..//医生审核拒绝时给平台推送信息
	..s Adm=$p(^OEORD(+LinkOeoriRowid),"^",1)
	..d ##class(web.DOC.PortalService).TaskNeedAuditOEItem("S00000028",LinkOeoriRowid,3,Adm)
	i Err'=0  TrollBack
	TC
	;删除存储的虚拟长期医嘱
	d ##class(web.DHCDocOrderVirtualLong).DeleteVirtualtLong(OrdItemStr)

	q Err
}

/// 执行医嘱
ClassMethod Excute(OrdItmRowId As %String, UserRowId As %String) As %String
{
	s ^zyb2 = "ssssss"
	s StatusRowId=$O(^OEC("OSTAT",0,"Code","E",0))
	Q ..UpdateStatus(OrdItmRowId,UserRowId,StatusRowId)
}

/// 判断是否绑定产生的医嘱
/// w ##class(web.DHCOEOrdItem).IsLinkOrderItemInstr(LinkOrderItem,ARCIMRowid)
ClassMethod IsLinkOrderItemInstr(LinkOrderItem, ARCIMRowid)
{
	 n (LinkOrderItem,ARCIMRowid,%session)
	 Quit:LinkOrderItem="" 0
	 s MasterInstrDr=$p($g(^OEORD(+LinkOrderItem,"I",$p(LinkOrderItem,"||",2),2)),"^",7)
	 if MasterInstrDr'="" {
		Set HosId=""
		if $d(%session){
			Set HosId=%session.Get("LOGON.HOSPID")	
		}
		if HosId'="" Set MasterInstrDr=MasterInstrDr_"||"_HosId
		s MasterInstrLinkStr=$g(^DHCDocConfig("InstrArcim",MasterInstrDr))
	 	if (MasterInstrLinkStr[ARCIMRowid) Quit 1
	 	
	 	s MasterInstrLinkStr=$g(^DHCDocConfig("InstrIPArcim",MasterInstrDr))
	 	if (MasterInstrLinkStr[ARCIMRowid) Quit 1
	 }
	 
	 Quit 0
}

ClassMethod FindAdmOrderItemsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = FindAdmOrderItemsExecute ]
{
	Set repid=$LIST(qHandle,2)
	Kill ^CacheTemp(repid)
	Quit $$$OK
}

ClassMethod FindAdmOrderItemsExecute(ByRef qHandle As %Binary, EpisodeID As %String, SttDate As %String, EndDate As %String, PriorID As %String, CTLOCRowId As %String, GOrderName As %String, DocNameID As %String, Adm As %String, Drug As %String, Lab As %String, Exam As %String, Cure As %String, GOrderNameID As %String = "", CurLogonHosp As %String = "") As %Status
{
 ;d ##class(%ResultSet).RunQuery("web.DHCOEOrdItem","FindAdmOrderItems","205974","","","")
 Set repid=$I(^CacheTemp)
 If $g(ind)="" Set ind=1
 s ^zhou("prior")=EpisodeID_"^"_SttDate_"^"_EndDate_"^"_PriorID_"^"_CTLOCRowId_"^"_GOrderName_"^"_DocNameID_"^"_Adm_"^"_Drug_"^"_Lab_"^"_Exam_"^"_Cure_"^"_GOrderNameID
 
 set PatType="", InsType="", PriorRowid="", InstrRowid="", LinkTo="", OEPrice="",LabEpisodeNo=""
 set UseCNMedEntry=..%GetConfig("UseCNMedEntry",CurLogonHosp)
 set PAADMType=$p($g(^PAADM(EpisodeID)),"^",2)
 s PatType=$P(^PAADM(EpisodeID,1),"^",6)  //PAADM_Epissubtype_DR
 s SelAdmId=Adm
 i (SelAdmId'=""){
	 ;门急诊如果选择就诊则其他条件无效,显示所有就诊下的医嘱
	 i (PAADMType'="I") {
		 s SttDate="",EndDate="",DocUserDep="",GOrderName="",DocName=""
	 }
	 s AdmStr=SelAdmId
 }else{
	 s AdmStr=""
	 if (PAADMType'="I")&(SttDate'=""){
		s PatientID=$P(^PAADM(EpisodeID),"^",1)
		s Adm=0  f  s Adm=$O(^PAPERdr(PatientID,"ADM",PAADMType,Adm)) Q:(Adm="")  d
		.s AdmDate=$P(^PAADM(Adm),"^",6)
		.Q:(SttDate'="")&(AdmDate<SttDate)
		.Q:(EndDate'="")&(AdmDate>EndDate)
		.if AdmStr="" s AdmStr=Adm
		.e  s AdmStr=AdmStr_"^"_Adm
	 }else{
		 s AdmStr=EpisodeID
	 }
 }
 i AdmStr="" s AdmStr=EpisodeID
 s len=$LENGTH(AdmStr,"^")
 set NoDisplayItemCat=..%GetConfig("NoDisplayItemCat",CurLogonHosp)

 ;w PatientID_"^"_AdmStr_"^"_len,!
 do ResetVariables6
 For i = 1:1:len {
	 
 s CurrEpisodeID=$P(AdmStr,"^",i)
 ;w "Episode:"_CurrEpisodeID,!
 &SQL(DECLARE OrdCur0 CURSOR FOR
 SELECT OEORI_Rowid,OEORI_ItmMast_DR,OEORI_ItmMast_DR->ARCIM_Desc,
	OEORI_SttDat,OEORI_SttTim,Todate(OEORI_SttDat,'yyyy-mm-dd'),
	OEORI_DoseQty,OEORI_Unit_DR,OEORI_Unit_DR->CTUOM_Desc,
	OEORI_QtyPackUOM,
	OEORI_Priority_dr,OEORI_Priority_dr->OECPR_Desc,
	OEORI_Itemstat_dr,OEORI_Itemstat_dr->OSTAT_Desc,
	OEORI_PHFreq_DR,OEORI_PHFreq_DR->PHCFR_Desc1,
	OEORI_Instr_DR,OEORI_Instr_DR->PHCIN_Desc1,
	OEORI_Durat_DR,OEORI_Durat_DR->PHCDU_Desc1,
	OEORI_RecDep_DR,OEORI_RecDep_DR->CTLOC_Desc,
	OEORI_UserDepartment_DR,OEORI_UserDepartment_DR->CTLOC_Desc,
	OEORI_Doctor_DR,OEORI_Doctor_DR->CTPCP_Desc,OEORI_UserAdd,OEORI_UserAdd->SSUSR_Name,
	OEORI_Billed,OEORI_AdministerSkinTest,OEORI_BBExtCode,
	OEORI_ItmMast_DR->ARCIM_ItemCat_DR->ARCIC_OrderType,
	OEORI_SeqNo,OEORI_LinkNo,OEORI_LinkToOrder,OEORI_PrescNo,OEORI_LabEpisodeNo,
	OEORI_ARCOS_DR,OEORI_BBExtCode,OEORI_OEORI_DR,Todate(OEORI_Date,'yyyy-mm-dd'),
	OEORI_OrdDept_DR,OEORI_OrdDept_DR->CTLOC_Desc
 INTO :OrderItemRowid,:ARCIMRowid,:OrderName,:OrderSttDate,:OrderSttTime,:StartDate,
	:OrderDoseQty,:OrderDoseUOMRowid,:OrderDoseUOM,:OrderPackQty,
	:OrderPriorRowid,:OrderPrior,:OrderStatusRowid,:OrderStatus,:OrderFreqRowid,:OrderFreq,
	:OrderInstrRowid,:OrderInstr,:OrderDurRowid,:OrderDur,
	:OrderRecDepRowid,:OrderRecDep,:OrderUserDepRowid,:OrderUserDep,
	:OrderDocRowid,:OrderDoc,:OrderUserAddRowid,:OrderUserAdd,
	:OrderBilled,:OrderSkinTest,:OrderBillTypeRowid,:OrderType,
	:OrderSeqNo,:OrderMasterSeqNo,:OrderLinkTo,:OrderPrescNo,:OrderLabEpisodeNo,
	:OrderARCOSRowid,:OrderBillTypeRowid,:LinkOrderItem,:OrderDate,
	:OrderOrdDepRowid,:OrderOrdDep
 From SQLUser.OE_OrdItem 
 WHERE OEORI_OEORD_PARREF->OEORD_ADM_DR=:CurrEpisodeID and (OEORI_ItemStat_DR->OSTAT_Code<>'I')
 Order By OEORI_SttDat desc)
 &SQL(OPEN OrdCur0)
 For  &SQL(FETCH OrdCur0) QUIT:SQLCODE  do
	. Q:((PriorID'="")&(PriorID'=OrderPriorRowid))
	. Q:((SttDate'="")&(OrderSttDate<SttDate)&(PAADMType="I"))
	. Q:((EndDate'="")&(OrderSttDate>EndDate)&(PAADMType="I"))
	. Q:(CTLOCRowId'="")&&(OrderUserDepRowid'=CTLOCRowId)
	. Q:(DocNameID'="")&&(DocNameID'=OrderDocRowid)
	. Q:((GOrderName'="")&&(OrderName'[GOrderName))&&(GOrderNameID="")
	. Q:(GOrderNameID'=ARCIMRowid)&&(GOrderNameID'="")
	. ;非医生录入的医嘱退出
    . s CarPrvTpDR=$p($g(^CTPCP(+$g(OrderDocRowid),1)),"^",4)
    . s DoctorType=$p($g(^CT("CPT",+$g(CarPrvTpDR))),"^",4)
    . Q:(PAADMType'="I")&&(DoctorType'="DOCTOR")
	. Q:(..IsLinkOrderItemInstr($g(LinkOrderItem),ARCIMRowid)=1)
	. ;检验自动绑定上的医嘱不显示
	. s LinkLabNo=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DHC")),"^",22)
	. Q:LinkLabNo'=""
	. ;OrderDepProcNote,Spec,OrderBaseUOMRowid,OrderMaxDurRowid
	. s subcat=$p($g(^ARCIM(+ARCIMRowid,1,1)),"^",10)
	. Q:(NoDisplayItemCat'="")&(subcat'="")&(("^"_NoDisplayItemCat_"^")[("^"_subcat_"^"))
	. s PHPrescType=##class(web.DHCDocOrderCommon).GetPHPrescType(subcat,CurLogonHosp,ARCIMRowid)
	. ;使用草药录入程序
	. Q:(PHPrescType="3")&(UseCNMedEntry="1")
	. s orcat=$p($g(^ARC("IC",+subcat)),"^",8)
	. s orcatdesc=""
	. i orcat'="" s orcatdesc=$p($g(^OEC("ORCAT",orcat)),"^",2)
	. s RecDepDesc=$p(OrderRecDep,"-",2)
	. i RecDepDesc'="" s OrderRecDep=RecDepDesc
	. ;s retPrice=##class(web.DHCDocOrderEntry).GetOrderPrice(PatType, InsType, ARCIMRowid, OrderSttDate, PriorRowid, InstrRowid, LinkTo, OEPrice)
	. s retPrice=##class(web.DHCDocOrderCommon).GetOrderPrice(PatType, InsType, ARCIMRowid, OrderSttDate, PriorRowid, InstrRowid, LinkTo, OEPrice,OrderRecDepRowid)
	. s OrderPrice=$P(retPrice,"^",1)
	. s DiscPrice=$P(retPrice,"^",2)
	. s InsPrice=$P(retPrice,"^",3)
	. s PatPrice=$P(retPrice,"^",4)
	. s OrderPrice=$fn($P(retPrice,"^",1),"",4)
	. s OrderSum=OrderPackQty*OrderPrice
	. i OrderBillTypeRowid="" s OrderBillType="自费"
	. e  s OrderBillType=$P(^PAC("ADMREA",OrderBillTypeRowid),"^",2)
	. s OrderDoseQty=$TR(OrderDoseQty," ","")
	. i OrderType'="R" d
	. . s DoseqtySum=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),1)),"^",12)
	. . s OrderPackQty=DoseqtySum
	. s OrderPackUOMRowid=##Class(web.DHCDocOrderCommon).GetOrdPackUOMDR(OrderItemRowid)
	. s OrderPackUOM=##class(web.DHCDocOrderCommon).GetUOMDesc(OrderPackUOMRowid)
	. s OrderPackUOM=$p(OrderPackUOM,"(",1)
	. s OrderSum=OrderPackQty*OrderPrice
	. s OrderDepProcNote=$g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DEP",1))
	. ;s Spec=..GetLabSpec(Rowid)
	. s OrderDrugFormRowid=##class(web.DHCDocOrderEntry).GetDrgForm(ARCIMRowid)
	. ;do OutputRow5
	. s OrderFreqFactor="1",OrderFreqInterval="",OrderDurFactor="1"
	. if OrderFreqRowid'="" d
	..s OrderFreqFactor=$P($g(^PHCFR(OrderFreqRowid)),"^",2)
	..s OrderFreqInterval=$P($g(^PHCFR(OrderFreqRowid)),"^",5)
	.i OrderDurRowid'="" s OrderDurFactor=$P($g(^PHCDU(OrderDurRowid)),"^",2)
	.s OrderItemInValid=##Class(web.DHCDocOrderEntry).ValARCItem(ARCIMRowid)
	.if OrderItemInValid=0  d
	..s GroupRowId=%session.Get("LOGON.GROUPID")
	..s OrderItemInValid=##Class(web.DHCDocOrderEntry).ValOrdcat(GroupRowId,orcat)
	. s Data1=$lb(OrderName,OrderStatus,OrderPrior,OrderSttDate,OrderSttTime,OrderDoseQty,OrderDoseUOM,OrderFreq,OrderInstr,OrderDur,OrderPrice,OrderPackQty,OrderPackUOM,OrderSkinTest,OrderRecDep,OrderUserDep,OrderOrdDep,OrderSum,OrderPrescNo,OrderDepProcNote,OrderDoc,OrderUserAdd,OrderDate,OrderSeqNo,OrderMasterSeqNo,OrderLinkTo,OrderLabEpisodeNo,OrderItemRowid,ARCIMRowid,OrderSttDate,OrderDoseUOMRowid,OrderFreqRowid,OrderPriorRowid,OrderInstrRowid,OrderDurRowid,OrderPackUOMRowid,OrderRecDepRowid,OrderUserDepRowid,OrderOrdDepRowid,OrderStatusRowid,OrderBaseUOMRowid,OrderDocRowid,OrderUserAddRowid,OrderARCOSRowid,OrderDrugFormRowid,OrderMaxDurRowid,OrderType,OrderBillTypeRowid,OrderMaxDurRowid,OrderBillType,OrderFreqFactor,OrderFreqInterval,OrderDurFactor,LinkOrderItem,CurrEpisodeID,OrderBillTypeRowid,OrderItemInValid)
	.;
	. s OrderItemRowidchild=$P(OrderItemRowid,"||",2)
	. s LinkOrderItemchild=$P(LinkOrderItem,"||",2)
	. i LinkOrderItem="" s ^CacheTemp("DHCAdmOrdItem",$j,"adm",CurrEpisodeID,"master",OrderItemRowidchild)=Data1
	. e  d
	. .if '$D(^CacheTemp("DHCAdmOrdItem",$j,"adm",CurrEpisodeID,"master",LinkOrderItemchild)) d
	. . .s ^CacheTemp("DHCAdmOrdItem",$j,"adm",CurrEpisodeID,"master",LinkOrderItemchild)=""
	. .s ^CacheTemp("DHCAdmOrdItem",$j,"adm",CurrEpisodeID,"master",LinkOrderItemchild,"sub",OrderItemRowidchild)=Data1
	&SQL(CLOSE OrdCur0)
 }
 	
 	;如果没有选择类别条件则都查出
 	s CheckFlag=1
 	i (Drug'="on")&&(Lab'="on")&&(Exam'="on")&&(Cure'="on") s CheckFlag=0
	;
	s SeqNo=0
	s adm=0 for  s adm=$O(^CacheTemp("DHCAdmOrdItem",$j,"adm",adm)) q:adm=""  d
	.s mas=0 for  s mas=$O(^CacheTemp("DHCAdmOrdItem",$j,"adm",adm,"master",mas)) q:mas=""  d
	.. s s1=^CacheTemp("DHCAdmOrdItem",$j,"adm",adm,"master",mas)
	.. q:s1=""
	.. q:((Drug'="on")&&($List(s1,47)="R")&&(CheckFlag=1))
	.. q:((Lab'="on")&&($List(s1,47)="L")&&(CheckFlag=1))
	.. q:((Exam'="on")&&($List(s1,47)="E")&&(CheckFlag=1))
	.. q:((Cure'="on")&&($List(s1,47)="N")&&(CheckFlag=1))
	.. i s1'="" d 
	.. .s SeqNo=SeqNo+1
	.. .s $List(s1,24)=SeqNo
	.. .s Data=s1
	.. .d OutputRow6
	.. s SubSeqCount=0
	.. s sub=0  for  s sub=$O(^CacheTemp("DHCAdmOrdItem",$j,"adm",adm,"master",mas,"sub",sub)) q:sub=""  d
	.. . s s2=^CacheTemp("DHCAdmOrdItem",$j,"adm",adm,"master",mas,"sub",sub)
	.. . i s1="" d
	.. . . s SeqNo= SeqNo+1
	.. . . s $List(s2,24)=SeqNo
	.. . . s Data=s2
	.. . . d OutputRow6
	.. . e  d
	.. . . s SubSeqCount=SubSeqCount+1
	.. . . s SubSeqNo=SeqNo_"."_SubSeqCount
	.. . . s $List(s2,24)=SubSeqNo
	.. . . s Data=s2
	.. . . d OutputRow6
 K ^CacheTemp("DHCAdmOrdItem",$j,"adm")
 Set qHandle=$lb(0,repid,0)
 Quit $$$OK
OutputRow6
 ;set Data=$lb(OrderName,OrderStatus,OrderPrior,OrderSttDate,OrderSttTime,OrderDoseQty,OrderDoseUOM,OrderFreq,OrderInstr,OrderDur,OrderPrice,OrderPackQty,OrderPackQtyUOM,OrderSkinTest,OrderRecDep,OrderUserDep,OrderOrdDep,OrderSum,OrderPrescNo,OrderDepProcNote,OrderDoc,OrderUserAdd,OrderDate,OrderSeqNo,OrderMasterSeqNo,OrderLinkTo,OrderLabEpisodeNo,OrderItemRowid,ARCIMRowid,OrderSttDate,OrderDoseUOMRowid,OrderFreqRowid,OrderPriorRowid,OrderInstrRowid,OrderDurRowid,OrderPackUOMRowid,OrderRecDepRowid,OrderUserDepRowid,OrderOrdDepRowid,OrderStatusRowid,OrderBaseUOMRowid,OrderDocRowid,OrderUserAddRowid,OrderLinkto,OrderARCOSRowid,OrderDrugFormRowid,OrderMaxDurRowid,OrderType,OrderBillTypeRowid,OrderMaxDurRowid,OrderBillType,DepProcNotes)
 Set ^CacheTemp(repid,ind)=Data
 Set ind=ind+1
 quit
ResetVariables6
 set (OrderName,OrderStatus,OrderPrior,OrderSttDate,OrderSttTime,OrderDoseQty,OrderDoseUOM,OrderFreq,OrderInstr,OrderDur,OrderPrice,OrderPackQty,OrderPackUOM,OrderSkinTest,OrderRecDep,OrderUserDep,OrderOrdDep,OrderSum,OrderPrescNo,OrderDepProcNote,OrderDoc,OrderUserAdd,OrderDate,OrderSeqNo,OrderMasterSeqNo,OrderLinkTo,OrderLabEpisodeNo,OrderItemRowid,ARCIMRowid,OrderSttDate,OrderDoseUOMRowid,OrderFreqRowid,OrderPriorRowid,OrderInstrRowid,OrderDurRowid,OrderPackUOMRowid,OrderRecDepRowid,OrderUserDepRowid,OrderOrdDepRowid,OrderStatusRowid,OrderBaseUOMRowid,OrderDocRowid,OrderUserAddRowid,OrderARCOSRowid,OrderDrugFormRowid,OrderMaxDurRowid,OrderType,OrderBillTypeRowid,OrderMaxDurRowid,OrderBillType,OrderFreqFactor,OrderFreqInterval,OrderDurFactor,LinkOrderItem)=""
 Quit
}

ClassMethod FindAdmOrderItemsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = FindAdmOrderItemsExecute ]
{
	Set AtEnd=$LIST(qHandle,1)
	Set repid=$LIST(qHandle,2)
	Set ind=$LIST(qHandle,3)
	//
	Set ind=$o(^CacheTemp(repid,ind))
	If ind="" {				// if there are no more rows, finish fetching
	Set AtEnd=1
	Set Row=""
	}
	Else      {				// fetch row
	Set Row=^CacheTemp(repid,ind)
	}
	// Save QHandle
	s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

ClassMethod FindOrderItemsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = FindOrderItemsExecute ]
{
 Set repid=$LIST(qHandle,2)
 Kill ^CacheTemp(repid)
 Quit $$$OK
}

/// Creator:      周志强
/// CreatDate:    2009.02.20
/// Description:  查找门诊病人状态为"审核"的医嘱,返回给界面
/// Table:        INC_ItmLoc
/// Input:        EpisodeID:就诊RowId   TYPE:录入类型(L:检验医嘱录入) 
/// Return:       医嘱信息(待补充)
/// Others:d ##class(%ResultSet).RunQuery("web.DHCOEOrdItem","FindOrderItems",4613,"",4634)
ClassMethod FindOrderItemsExecute(ByRef qHandle As %Binary, EpisodeID As %String, TYPE As %String = "", USERID As %String = "", QueryMasterOrder As %String = "", NotDisplayNoPayOrd As %String = "", CurLogonHosp As %String = "") As %Status
{
	
 Set repid=$I(^CacheTemp)
 If $g(ind)="" Set ind=1
 s ^tempscl("FindOrderItemsExecute")=EpisodeID_","_TYPE_","_USERID
 do ResetVariables7
 set PatType="", InsType="", PriorRowid="", InstrRowid="", LinkTo="", OEPrice="",LabEpisodeNo=""
 if (NotDisplayNoPayOrd="1"){ //门诊不显示未交费医嘱
	 Set qHandle=$lb(0,repid,0)
 	Quit $$$OK
 }
 Set langid=..%LanguageID()
 if EpisodeID'="" {
 set PAADMType=$p($g(^PAADM(EpisodeID)),"^",2)
 set NoDisplayItemCat=..%GetConfig("NoDisplayItemCat",CurLogonHosp)
 set ShowPaidOrder=..%GetConfig("ShowPaidOrder",CurLogonHosp)
 set UseCNMedEntry=..%GetConfig("UseCNMedEntry",CurLogonHosp)
 //set CFEntryOrdBillPad=##class(web.PilotProject.DHCDocPPGroupSeting).GetConfigNode("EntryOrdBillPad")
 s OPOrdAutoBilled=$g(^DHCDocPilotSeting(CurLogonHosp,"OPOrdAutoBilled"))
 s PAADMRegConDisDR=$P($G(^PAADM(EpisodeID,"DHC")),"^",25)
 s PatType=$P(^PAADM(EpisodeID,1),"^",6)  //PAADM_Epissubtype_DR
 s StayStatus=0
 s PatCurStat=##class(web.DHCADMVisitStat).GetStayStatus(EpisodeID)
 i " 1 2 "[(" "_PatCurStat_" ") s StayStatus=1
 if $D(%session){
 	s LogonCTLocId=%session.Get("LOGON.CTLOCID")
 }else{
	s LogonCTLocId=""
 }
 s OPAdmLOCRowId=$o(^PAC("ADMLOC",0,"AdmType","O",LogonCTLocId,""))
 s EPAdmLOCRowId=$o(^PAC("ADMLOC",0,"AdmType","E",LogonCTLocId,""))
 //if (PAADMType'="I"){
 if ((PAADMType="O")||((PAADMType="E")&&(StayStatus="0"))||(PAADMType="H")||((PAADMType="I")&&(QueryMasterOrder'=""))){
 &SQL(DECLARE OrdCursor CURSOR FOR
 SELECT OEORI_Rowid,OEORI_ItmMast_DR,OEORI_ItmMast_DR->ARCIM_Desc,
		OEORI_SttDat,OEORI_SttTim,Todate(OEORI_SttDat,'yyyy-mm-dd'),
		OEORI_DoseQty,OEORI_Unit_DR,OEORI_Unit_DR->CTUOM_Desc,
		OEORI_QtyPackUOM,
	    OEORI_Priority_dr,OEORI_Priority_dr->OECPR_Desc,
	    OEORI_Itemstat_dr,OEORI_Itemstat_dr->OSTAT_Desc,
	    OEORI_PHFreq_DR,OEORI_PHFreq_DR->PHCFR_Desc1,
	    OEORI_Instr_DR,OEORI_Instr_DR->PHCIN_Desc1,
	    OEORI_Durat_DR,OEORI_Durat_DR->PHCDU_Desc1,
	    OEORI_RecDep_DR,OEORI_RecDep_DR->CTLOC_Desc,
	    OEORI_UserDepartment_DR,OEORI_UserDepartment_DR->CTLOC_Desc,
	    OEORI_Doctor_DR,OEORI_Doctor_DR->CTPCP_Desc,OEORI_UserAdd,OEORI_UserAdd->SSUSR_Name,
	    OEORI_Billed,OEORI_AdministerSkinTest,OEORI_BBExtCode,
	    OEORI_ItmMast_DR->ARCIM_ItemCat_DR->ARCIC_OrderType,
	    OEORI_SeqNo,OEORI_LinkNo,OEORI_LinkToOrder,OEORI_PrescNo,OEORI_LabEpisodeNo,
	    OEORI_ARCOS_DR,OEORI_BBExtCode,OEORI_OEORI_DR,OEORI_PhSpecInstr,OEORI_Price,
	    OEORI_CoverMainIns,OEORI_Action_DR,OEORI_Action_DR->ACT_Desc,OEORI_NotifyClinician,
	    OEORI_DRGOrder,OEORI_BBExtCode,OEORI_SpeedFlowRate,OEORI_LabEpisodeNo,
		OEORI_FlowRateUnit_DR,OEORI_FlowRateUnit_DR->SFR_Desc,OEORI_Qty
 INTO :OrderItemRowid,:ARCIMRowid,:OrderName,:OrderSttDate,:OrderSttTime,:StartDate,
		:OrderDoseQty,:OrderDoseUOMRowid,:OrderDoseUOM,:OrderPackQty,
		:OrderPriorRowid,:OrderPrior,:OrderStatusRowid,:OrderStatus,:OrderFreqRowid,:OrderFreq,
		:OrderInstrRowid,:OrderInstr,:OrderDurRowid,:OrderDur,
		:OrderRecDepRowid,:OrderRecDep,:OrderUserDepRowid,:OrderUserDep,
		:OrderDocRowid,:OrderDoc,:OrderUserAddRowid,:OrderUserAdd,
		:OrderBilled,:OrderSkinTest,:OrderBillTypeRowid,:OrderType,
		:OrderSeqNo,:OrderMasterSeqNo,:OrderLinkTo,:OrderPrescNo,:OrderLabEpisodeNo,
		:OrderARCOSRowid,:OrderBillTypeRowid,:LinkOrderItem,:OrderPhSpecInstr,:OrderPrice,
		:OrderCoverMainIns,:OrderActionRowid,:OrderAction,:OrderNotifyClinician,
		:OrderDIACatRowId,:InsType,:OrderSpeedFlowRate,:OrderLabEpisodeNo,
		:OEORIFlowRateUnitDR,:OrderFlowRateUnit,:OrderFirstDayTimes
 From SQLUser.OE_OrdItem 
 WHERE OEORI_OEORD_PARREF->OEORD_ADM_DR=:EpisodeID and 
 (OEORI_ItemStat_DR->OSTAT_Code='V' or OEORI_ItemStat_DR->OSTAT_Code='E')
 Order By OEORI_SttDat desc)
 &SQL(OPEN OrdCursor)
 For   {
	&SQL(FETCH OrdCursor)
	QUIT:SQLCODE
	s OrderName=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",OrderName,langid)
	s OrderDoseUOM=##class(User.CTUOM).GetTranByDesc("CTUOMDesc",OrderDoseUOM,langid)
	s OrderPrior=##class(User.OECPriority).GetTranByDesc("OECPRDesc",OrderPrior,langid)
	s OrderStatus=##class(User.OECOrderStatus).GetTranByDesc("OSTATDesc",OrderStatus,langid)
	s OrderFreq=##class(User.PHCFreq).GetTranByDesc("PHCFRDesc1",OrderFreq,langid)
	s OrderInstr=##class(User.PHCInstruc).GetTranByDesc("PHCINDesc1",OrderInstr,langid)
	s OrderDur=##class(User.PHCDuration).GetTranByDesc("PHCDUDesc1",OrderDur,langid)
	s OrderRecDep=##class(User.CTLoc).GetTranByDesc("CTLOCDesc",OrderRecDep,langid)
	s OrderUserDep=##class(User.CTLoc).GetTranByDesc("CTLOCDesc",OrderUserDep,langid)
	Set OrderDoc= ##class(User.CTCareProv).GetTranByDesc("CTPCPDesc",OrderDoc,langid)
	Set OrderUserAdd= ##class(User.CTCareProv).GetTranByDesc("CTPCPDesc",OrderUserAdd,langid)
	s OrderFlowRateUnit=##class(User.OECSpeedFlowRate).GetTranByDesc("SFRDesc",OrderFlowRateUnit,langid)
	s OrderAction=##class(User.OECAction).GetTranByDesc("ACTDesc",OrderAction,langid)
    s OrderPriorCode=$p($g(^OECPR(OrderPriorRowid)),"^",1)
	if (OrderSpeedFlowRate'="")&&($p(OrderSpeedFlowRate,".",1)="") s OrderSpeedFlowRate=0_OrderSpeedFlowRate
	Set OrderName=##class(web.DHCDocOrderCommon).GetFormateOrderName(ARCIMRowid,CurLogonHosp,langid)
	Set OrdDeptId = $p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),7)),"^",2)	;开单科室
	//对于访问类型位置不是门诊或急诊的科室只显示本科室开立的未收费的医嘱
	continue:(OPAdmLOCRowId="")&&(EPAdmLOCRowId="")&&(OrdDeptId'=LogonCTLocId)
	s CareProvDR=0,LogDoctorType=""
	i USERID'="" d
	.s CareProvDR = $p(^SSU("SSUSR",USERID),"^",14)
	.s CarPrvTpDR=$p($g(^CTPCP(+$g(CareProvDR),1)),"^",4)
	.s LogDoctorType=$p($g(^CT("CPT",+$g(CarPrvTpDR))),"^",4)
	Set RBFlag=1
	i OrdDeptId>0,CareProvDR>0 d
	. Set OnlyThisDepStop=$P($g(^CTLOC(OrdDeptId,"DHC")),"^",14) //医嘱只能本科室停止标志
	. if ('$d(^RB("RES",0,"CTPCP",CareProvDR,OrdDeptId)))&&(OnlyThisDepStop=1) s RBFlag=0
	continue:RBFlag=0
	;非医生录入的医嘱退出
	s CarPrvTpDR=$p($g(^CTPCP(+$g(OrderDocRowid),1)),"^",4)
	s DoctorType=$p($g(^CT("CPT",+$g(CarPrvTpDR))),"^",4)
	continue:(PAADMType'="I")&&(DoctorType'="DOCTOR")&&(LogDoctorType="DOCTOR")
	;OrderDepProcNote,Spec,OrderBaseUOMRowid,OrderMaxDurRowid
	;continue:$d(^DHCOPIPADMCON("OPADMORDER","OPAdm",EpisodeID,OrderItemRowid))   ;门急诊费用转住院后不允许停止及修改
	continue:(##class(web.DHCBillInterface).IOrdIsOPToIPByOEORI(OrderItemRowid)=1)
	s billed=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),3)),"^",5)
	;药理项目
	s OrderPilotPro=""
	s OrderPilotProRowId=+$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DHC")),"^",10)
	s:OrderPilotProRowId=0 OrderPilotProRowId=""
	if OrderPilotProRowId'="" s OrderPilotPro=$p($G(^DHCDocPP(OrderPilotProRowId)),"^",2)
	s OrderPilotPro= ##class(User.DHCDocPilotProject).GetTranByDesc("PPDesc",OrderPilotPro,langid)
	continue:(billed="P")&(ShowPaidOrder'="1")&&(OrderPilotProRowId="")
	continue:(billed="P")&(OrderPilotProRowId'="")&(OPOrdAutoBilled'="Y") //(CFEntryOrdBillPad'="1")
	s subcat=$p($g(^ARCIM(+ARCIMRowid,1,1)),"^",10)
	continue:(NoDisplayItemCat'="")&(subcat'="")&(("^"_NoDisplayItemCat_"^")[("^"_subcat_"^"))
	s PHPrescType=##class(web.DHCDocOrderCommon).GetPHPrescType(subcat,CurLogonHosp,ARCIMRowid)
	;使用草药录入程序
	continue:(PHPrescType="3")&(UseCNMedEntry="1")
	s OrdMasterPrescNo=""
	//若是草药绑定的医嘱 不显示
	i (OrderType'="R")&(LinkOrderItem'="") d
	. s OrdMasterPrescNo=$p($g(^OEORD(+LinkOrderItem,"I",$p(LinkOrderItem,"||",2),1)),"^",14)
	continue:(OrdMasterPrescNo'="")&(##Class(web.DHCDocPrescript).IsPrescType(OrdMasterPrescNo)=1)
	continue:(TYPE'="")&(TYPE'=OrderType)
	continue:(QueryMasterOrder'="")&&(QueryMasterOrder'=LinkOrderItem)

	s orcat=$p($g(^ARC("IC",+subcat)),"^",8)
	s orcatdesc=""
	i orcat'="" s orcatdesc=$p($g(^OEC("ORCAT",orcat)),"^",2)
	s RecDepDesc=$p(OrderRecDep,"-",2)
	i RecDepDesc'="" s OrderRecDep=RecDepDesc
	s UserDep=$p(OrderUserDep,"-",2)
	i UserDep'="" s OrderUserDep=UserDep
	
	s OrderPackUOMRowid=##Class(web.DHCDocOrderCommon).GetOrdPackUOMDR(OrderItemRowid)
	s OrderPackUOM=##class(web.DHCDocOrderCommon).GetUOMDesc(OrderPackUOMRowid)
	
	;批次价入参
	i OrderType'="P" d
	. s OrderExecRowId=""
	. s OrderExecSub=$o(^OEORD(+OrderItemRowid,"I",$P(OrderItemRowid,"||",2),"X",0))
	. s OrderExecRowId=OrderItemRowid_"||"_OrderExecSub
	. //s ExpStr=OrderItemRowid_"^"_OrderExecRowId_"^"_EpisodeID_"^"_OrderRecDepRowid_"^^"
	. s ExpStr=OrderItemRowid_"^"_""_"^"_EpisodeID_"^"_OrderRecDepRowid_"^^"
	. ;s retPrice=##class(web.DHCDocOrderEntry).GetOrderPrice(PatType, InsType, ARCIMRowid, OrderSttDate, PriorRowid, InstrRowid, LinkTo, OEPrice)
	. s retPrice=##class(web.DHCDocOrderCommon).GetOrderPrice(PatType, InsType, ARCIMRowid, OrderSttDate, PriorRowid, InstrRowid, LinkTo, OEPrice,OrderRecDepRowid,PAADMRegConDisDR,OrderPackUOMRowid,ExpStr)
	. s OrderPrice=$P(retPrice,"^",1)
	. s DiscPrice=$P(retPrice,"^",2)
	. s InsPrice=$P(retPrice,"^",3)
	. s PatPrice=$P(retPrice,"^",4)
	. s OrderPrice=$fn($P(retPrice,"^",1),"",4)
	i OrderBillTypeRowid="" s OrderBillType="自费"
	e  s OrderBillType=$P($G(^PAC("ADMREA",OrderBillTypeRowid)),"^",2)
	s OrderBillType=##class(User.PACAdmReason).GetTranByDesc("READesc",OrderBillType,langid)
	s OrderDoseQty=$TR(OrderDoseQty," ","")
	i OrderDoseQty'="" d
	. i OrderDoseQty<1 s OrderDoseQty="0"_$number(OrderDoseQty)
	i OrderType'="R" d
	.s DoseqtySum=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),1)),"^",12)
	.s OrderPackQty=DoseqtySum
	s OrderSum=OrderPackQty*OrderPrice
	i OrderDurRowid'="" s DuraFactor=$P(^PHCDU(OrderDurRowid),"^",2)
	e  s DuraFactor=1
	s OrderFreqDispTimeStr="",FreqFactor=1
	i OrderFreqRowid'="" {
		s OrdFreqInfo=##class(DHCDoc.Interface.Inside.ServiceOrd).GetOrdFreqInfo(OrderItemRowid," ")
		s OrderFreq=$List(OrdFreqInfo,2)
		s FreqFactor=$List(OrdFreqInfo,3)
		s OrderFreqDispTimeStr=$List(OrdFreqInfo,4)
	}
	;如果没有填数量则自动计算基本单位数量
	s BaseUOMDesc=""
	s INCIRowid=##class(web.DHCDocOrderEntry).GetINCI(+ARCIMRowid)
	i INCIRowid'="" d
	.s BaseUOMRowid=$p($g(^INCI(INCIRowid,1)),"^",10)
	.s BaseUOMDesc=##class(web.DHCDocOrderCommon).GetUOMDesc(BaseUOMRowid)
	s drgformId=$P(^ARCIM(+ARCIMRowid,$P(ARCIMRowid,"||",2),1),"^",12)
	i ((+OrderPackQty=0)&&(OrderType="R")&&(OrderPriorCode'["OM"))  {
		//OrderDoseQty,:OrderDoseUOMRowid,:OrderDoseUOM,:OrderPackQty,:OrderPackUOM,:OrderPackUOMRowid
		//OrderFreqRowid
		k OrderFreqTimeDoseArr
		//同频次不同剂量
		s OrderFreqTimeDoseStr=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DHC")),"^",59)
		if (OrderFreqTimeDoseStr'=""){
			s BaseDoseQty=0
	        s Len=$l(OrderFreqTimeDoseStr,"!")
	        for i=1:1:Len{
		        s OneFreqDispTimeDose=$p(OrderFreqTimeDoseStr,"!",i)
		        s OneDoseQty=$p(OneFreqDispTimeDose,"$",2)
		        s OneBaseDoseQty = ##Class(web.DHCDocOrderEntry).CalDose(OrderDoseUOMRowid, drgformId, OneDoseQty)
		        s BaseDoseQty=BaseDoseQty+(+OneBaseDoseQty)
		        s OrderFreqTimeDoseArr(i)=OneBaseDoseQty
		    }
		}else{
			s BaseDoseQty=##Class(web.DHCDocOrderEntry).CalDose(OrderDoseUOMRowid,drgformId,OrderDoseQty)
		}
		s OrderPackQty=0
		s BaseDoseQtySum=0
		
		if OrderFreqDispTimeStr'="" {
			s NumTimes=##class(web.DHCOEOrdItemView).GetCountByFreqDispTime(OrderFreqDispTimeStr, OrderSttDate, DuraFactor,OrderFirstDayTimes)
		}else{
			//i +OrderFirstDayTimes>0 s NumTimes=FreqFactor*(DuraFactor-1)+OrderFirstDayTimes
			//e  s NumTimes=FreqFactor*DuraFactor
			
			if ($d(OrderFreqTimeDoseArr)) {
                if (OrderFirstDayTimes>0) {
	                s NumTimes=1
	                s:DuraFactor>=1 BaseDoseQtySum=BaseDoseQty*(DuraFactor-1)
	                for i=1:1:OrderFirstDayTimes {
		                s index=$o(OrderFreqTimeDoseArr(""),-1)-OrderFirstDayTimes+i
		                s BaseDoseQtySum=BaseDoseQtySum+$g(OrderFreqTimeDoseArr(index))
		            }
	            }else{
		            s NumTimes=DuraFactor
		        }
            }else{
				if (OrderFirstDayTimes>0){
					s NumTimes=FreqFactor * (DuraFactor-1)+OrderFirstDayTimes
				}else{
					s NumTimes=FreqFactor * DuraFactor
				}
			}
			
		}
		
		if (BaseDoseQtySum=0) {
        	s BaseDoseQtySum = BaseDoseQty * NumTimes
        }

		s convFac=##class(appcom.OEDispensing).convFac(ARCIMRowid,OrderPackUOMRowid)
        s OrderPackQty = BaseDoseQtySum / convFac	
		if (BaseDoseQty="") {
			s OrderPackQty=""
		}
		s OrderPackQty=+$fn(OrderPackQty,"",2)
		s ExpStr=PAADMRegConDisDR_"^"_OrderItemRowid_"^"_""_"^"_EpisodeID_"^"_OrderRecDepRowid
		s ArcPrice=##class(web.UDHCJFPRICE).GetOrderPrice(PatType,InsType,ARCIMRowid, OrderSttDate, PriorRowid, InstrRowid, LinkTo, OEPrice,"",ExpStr)
		s OrderSum=BaseDoseQtySum*ArcPrice
		s PackUOMDesc=BaseUOMDesc
	}
	s OrderPriorRemarksRowId=$CASE(OrderPriorCode,"OM":"OM","OMLSZT":"ZT",:"")
	s OrderPriorRemarks=$CASE(OrderPriorCode,"OM":"自备药","OMLSZT":"嘱托",:"")
	s OrderPriorRemarks=..%Translate("oeorder.oplistcustom.new.csp",OrderPriorRemarks)
	i OrderPriorRemarks'="" s OrderSum=0
	//s OrderPackUOM=$p(OrderPackUOM,"(",1)
	i OrderPackQty'="" d
	. i OrderPackQty<1 s OrderPackQty="0"_$number(OrderPackQty)
	s DepProcNotes=$g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DEP",1))
	s OrderLabSpec=..GetLabSpec(OrderItemRowid)
	s OrderLabExCode=""
	s OrderDrugFormRowid=##class(web.DHCDocOrderEntry).GetDrgForm(ARCIMRowid)
	s OrderNeedPIVAFlag=$p($G(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DHC")),"^",16)
	s OrderAutoCalculate=1
	s OrderFile1=$p($g(^ARCIM($p(ARCIMRowid,"||",1),1,9)),"^",5)
	s OrderFile2=$p($g(^ARCIM($p(ARCIMRowid,"||",1),1,9)),"^",19)
	s OrderFile3=$p($g(^ARCIM($p(ARCIMRowid,"||",1),1,9)),"^",20)
	s ExecuteDateDayStr=""
	i $d(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DHC")) d
	. s ExecuteDateStr=$p(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DHC"),"^",1)
	. i ExecuteDateStr'="" d
	. . f j=1:1:($l(ExecuteDateStr,$C(2))) d
	. . . s date=$P(ExecuteDateStr,$C(2),j)
	. . . s DateDay=$P($ZD(date,3),"-",3)
	. . . i ExecuteDateDayStr="" s ExecuteDateDayStr=DateDay
	. . . e  s ExecuteDateDayStr=ExecuteDateDayStr_","_DateDay
	;特病分类
	i OrderDIACatRowId'="" s OrderDIACat=$P($G(^DHCDiagnosCat(OrderDIACatRowId)),"^",1)
	e  s OrderDIACat=""
	Set OrderDIACat= ##class(User.DHCDiagnosCat).GetTranByDesc("DCDesc",OrderDIACat,langid)
	;医保适应症
	s InsurSignSymptom=""
	;
	s ExceedReasonDesc=""
	s ExceedReasonID=$p($G(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DHC")),"^",33)
	if ExceedReasonID'=""  s ExceedReasonDesc=$P($G(^DHCDocExceedReason(ExceedReasonID)),"^",2)
	s ExceedReasonDesc=##class(User.DHCDocExceedReason).GetTranByDesc("DHCExceedDesc",ExceedReasonDesc,langid)
	. s MaterialBarCode=$p($G(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DHC")),"^",14) ;高值条码
	s OrderUsableDays=""
	;实际可用天数
	if (PAADMType'="I")&(OrderType="R") s OrderUsableDays=##class(web.DHCDocOrderEntry).CalcDur(OrderItemRowid)
	s OrderLocalInfusionQty=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DHC")),"^",21)
	s AntUseReason=$p($G(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DHC")),"^",18)
	;s AntUseReason=$CASE(AntUseReason,"1":"预防","2":"治疗","3":"皮试","":"")
	s OrderStageCode=$p($G(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DHC")),"^",8)
	s OrderStage=$CASE(OrderStageCode,"SZ":"术中","SQ":"术前","SH":"术后","CZ":"产中","":"")
	s OrderStage=..%Translate("oeorder.oplistcustom.new.csp",OrderStage)
	s OrderSelfOMFlag=$p($G(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DHC")),"^",32)

	s OrderOutsourcingFlag=$p($G(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DHC")),"^",37)
	;s ReqPartDesc=##Class(web.DHCAPPInterface).GetExaReqPartDesc(OrderItemRowid)
	s ReqPartDesc=##Class(web.DHCAPPInterface).GetExaReqItemDescNoOrder(OrderItemRowid)
	s OrderName=OrderName_ReqPartDesc
	s OrderVirtualtLong=##Class(web.DHCDocOrderVirtualLong).GetVirtualtLongFlag(OrderItemRowid)
	s SignFlag=##class(web.DHCDocInPatPortalCommon).CheckOrdSign(OrderItemRowid)
	s Data1=$lb(OrderName,OrderStatus,OrderPrior,OrderSttDate,OrderSttTime,OrderDoseQty,OrderDoseUOM,OrderFreq,OrderInstr,OrderDur,OrderPrice,OrderPackQty,OrderPackUOM,OrderSkinTest,OrderRecDep,OrderUserDep,$fn(OrderSum,"",4),OrderPrescNo,OrderDepProcNote,OrderDoc,OrderUserAdd,OrderSeqNo,OrderMasterSeqNo,OrderLinkTo,OrderLabEpisodeNo,OrderItemRowid,ARCIMRowid,OrderSttDate,OrderDoseUOMRowid,OrderFreqRowid,OrderPriorRowid,OrderInstrRowid,OrderDurRowid,OrderPackUOMRowid,OrderRecDepRowid,OrderUserDepRowid,OrderStatusRowid,OrderBaseUOMRowid,OrderDocRowid,OrderUserAddRowid,OrderARCOSRowid,OrderDrugFormRowid,OrderMaxDurRowid,OrderType,OrderBillTypeRowid,OrderMaxDurRowid,OrderBillType,DepProcNotes,OrderPhSpecInstr,OrderLabSpec,OrderAutoCalculate,OrderCoverMainIns,OrderActionRowid,OrderAction,OrderFile1,OrderFile2,OrderFile3,OrderLabExCode,ExecuteDateDayStr,OrderNotifyClinician,OrderDIACat,InsurSignSymptom,OrderSpeedFlowRate,OrderLabEpisodeNo,OrderLocalInfusionQty,OrderUsableDays,ExceedReasonDesc,ExceedReasonID,OrderPilotProRowId,OrderPilotPro,OrderFlowRateUnit,OEORIFlowRateUnitDR,MaterialBarCode,OrderNeedPIVAFlag,AntUseReason,OrderStage,OrderSelfOMFlag,OrderOutsourcingFlag,OrderDIACatRowId,OrderPriorRemarks,OrderPriorRemarksRowId,OrderFirstDayTimes,OrderFreqDispTimeStr,OrderStageCode,OrderVirtualtLong,SignFlag)
	//临时护嘱绑定的长期医嘱id/所辅助的治疗医嘱  OrderServiceOrdDR
	s OEORIServiceOrdDR=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DHC")),"^",54)
	s OrderItemRowidChildsub=$P(OrderItemRowid,"||",2)
	i LinkOrderItem="",OEORIServiceOrdDR="" d
	. s ^CacheTemp("DHCFindOrdItem",$j,"master",OrderItemRowidChildsub)=Data1
	. ;s ^CacheTemp("DHCFindOrdItem",$j,"master",OrderItemRowid)=Data1
	else  if (LinkOrderItem'="")  d
	. s LinkOrderItemChildsub=$P(LinkOrderItem,"||",2)
	. if '$D(^CacheTemp("DHCFindOrdItem",$j,"master",LinkOrderItemChildsub)) d
	. . s ^CacheTemp("DHCFindOrdItem",$j,"master",LinkOrderItemChildsub)=""
	. s ^CacheTemp("DHCFindOrdItem",$j,"master",LinkOrderItemChildsub,"sub",OrderItemRowidChildsub)=Data1
	else  if (OEORIServiceOrdDR'="")  d
	. s LinkOrderItemChildsub=$P(OEORIServiceOrdDR,"||",2)
	. if '$D(^CacheTemp("DHCFindOrdItem",$j,"master",LinkOrderItemChildsub)) d
	. . s ^CacheTemp("DHCFindOrdItem",$j,"master",LinkOrderItemChildsub)=""
	. s ^CacheTemp("DHCFindOrdItem",$j,"master",LinkOrderItemChildsub,"sub",OrderItemRowidChildsub)=Data1
	}
	&SQL(CLOSE OrdCursor)
	;m ^zhou("b")=^CacheTemp("DHCFindOrdItem")
	s SeqNo=0
	s mas=0 for  s mas=$O(^CacheTemp("DHCFindOrdItem",$j,"master",mas)) q:mas=""  d
	. s s1=^CacheTemp("DHCFindOrdItem",$j,"master",mas)
	. i s1'="" d 
	. .s SeqNo=SeqNo+1
	. .s $List(s1,22)=SeqNo
	. .s Data=s1
	. .d OutputRow7
	. s SubSeqCount=0
	. s sub=0  for  s sub=$O(^CacheTemp("DHCFindOrdItem",$j,"master",mas,"sub",sub)) q:sub=""  d
	. . s s2=^CacheTemp("DHCFindOrdItem",$j,"master",mas,"sub",sub)
	. . i s1="" d
	. . . s SeqNo= SeqNo+1
	. . . s $List(s2,22)=SeqNo
	. . . s Data=s2
	. . . d OutputRow7
	. . e  d
	. . . s SubSeqCount=SubSeqCount+1
	. . . s SubSeqNo=SeqNo_"."_SubSeqCount
	. . . s $List(s2,22)=SubSeqNo
	. . . s Data=s2
	. . . d OutputRow7
	k ^CacheTemp("DHCFindOrdItem",$j,"master")
 }
 }
 i ind=1 d
 . do ResetVariables7
 . set Data=$lb(OrderName,OrderStatus,OrderPrior,OrderSttDate,OrderSttTime,OrderDoseQty,OrderDoseUOM,OrderFreq,OrderInstr,OrderDur,OrderPrice,OrderPackQty,OrderPackQtyUOM,OrderSkinTest,OrderRecDep,OrderUserDep,OrderSum,OrderPrescNo,OrderDepProcNote,OrderDoc,OrderUserAdd,OrderSeqNo,OrderMasterSeqNo,OrderLinkTo,OrderLabEpisodeNo,OrderItemRowid,ARCIMRowid,OrderSttDate,OrderDoseUOMRowid,OrderFreqRowid,OrderPriorRowid,OrderInstrRowid,OrderDurRowid,OrderPackUOMRowid,OrderRecDepRowid,OrderUserDepRowid,OrderStatusRowid,OrderBaseUOMRowid,OrderDocRowid,OrderUserAddRowid,OrderLinkto,OrderARCOSRowid,OrderDrugFormRowid,OrderMaxDurRowid,OrderType,OrderBillTypeRowid,OrderMaxDurRowid,OrderBillType,DepProcNotes,OrderPhSpecInstr,OrderLabSpec,OrderAutoCalculate,OrderCoverMainIns,OrderActionRowid,OrderAction,OrderFile1,OrderFile2,OrderFile3,OrderLabExCode,OrderLocalInfusionQty,OrderUsableDays,ExceedReasonDesc,ExceedReasonID,OrderFlowRateUnit,OEORIFlowRateUnitDR,MaterialBarCode,OrderNeedPIVAFlag,AntUseReason,OrderStage,OrderSelfOMFlag,OrderOutsourcingFlag,OrderDIACatRowId,OrderFirstDayTimes,OrderFreqDispTimeStr,OrderStageCode,OrderVirtualtLong)
 . Do OutputRow7	
 Set qHandle=$lb(0,repid,0)
 Quit $$$OK
OutputRow7
 Set ^CacheTemp(repid,ind)=Data
 Set ind=ind+1
 quit
ResetVariables7
 set (OrderName,OrderStatus,OrderPrior,OrderSttDate,OrderSttTime,OrderDoseQty,OrderDoseUOM,OrderFreq,OrderInstr,OrderDur,OrderPrice,OrderPackQty,OrderPackQtyUOM,OrderSkinTest,OrderRecDep,OrderUserDep,OrderSum,OrderPrescNo,OrderDepProcNote,OrderDoc,OrderUserAdd,OrderSeqNo,OrderMasterSeqNo,OrderLinkTo,OrderLabEpisodeNo,OrderItemRowid,ARCIMRowid,OrderSttDate,OrderDoseUOMRowid,OrderFreqRowid,OrderPriorRowid,OrderInstrRowid,OrderDurRowid,OrderPackUOMRowid,OrderRecDepRowid,OrderUserDepRowid,OrderStatusRowid,OrderBaseUOMRowid,OrderDocRowid,OrderUserAddRowid,OrderLinkto,OrderARCOSRowid,OrderDrugFormRowid,OrderMaxDurRowid,OrderType,OrderBillTypeRowid,OrderMaxDurRowid,OrderBillType,DepProcNotes,OrderPhSpecInstr,OrderLabSpec,OrderAutoCalculate,OrderCoverMainIns,OrderActionRowid,OrderAction,OrderFile1,OrderFile2,OrderFile3,OrderLabExCode,OrderLocalInfusionQty,OrderUsableDays,ExceedReasonDesc,ExceedReasonID,OrderFlowRateUnit,OEORIFlowRateUnitDR,MaterialBarCode,OrderNeedPIVAFlag,AntUseReason,OrderStage,OrderSelfOMFlag,OrderOutsourcingFlag,OrderDIACatRowId,OrderFirstDayTimes,OrderFreqDispTimeStr,OrderStageCode,OrderVirtualtLong)=""
 Quit
}

ClassMethod FindOrderItemsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = FindOrderItemsExecute ]
{
	Set AtEnd=$LIST(qHandle,1)
	Set repid=$LIST(qHandle,2)
	Set ind=$LIST(qHandle,3)
	//
	Set ind=$o(^CacheTemp(repid,ind))
	If ind="" {				// if there are no more rows, finish fetching
	Set AtEnd=1
	Set Row=""
	}
	Else      {				// fetch row
	Set Row=^CacheTemp(repid,ind)
	}
	// Save QHandle
	s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

ClassMethod FindOrderLabEpisodeClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = FindOrderLabEpisodeExecute ]
{
 Set repid=$LIST(qHandle,2)
 Kill ^CacheTemp(repid)
 Quit $$$OK
}

ClassMethod FindOrderLabEpisodeExecute(ByRef qHandle As %Binary, EpisodeID As %String) As %Status
{
	;;d ##class(%ResultSet).RunQuery("web.DHCOEOrdItem","FindOrderLabEpisode",531660)
	n Temp
	Set repid=$I(^CacheTemp)
	If $g(ind)="" Set ind=1
	s ret=""
	s OrderRowid=##Class(web.DHCDocOrderEntry).GetPAADMOrderRowid(EpisodeID)
	s child=0  f  s child=$O(^OEORD(OrderRowid,"I",child)) Q:child=""  d
	.s LabEpisodeNo=$p($g(^OEORD(OrderRowid,"I",child,3)),"^",20)
	.s ArcimRowId=$p($g(^OEORD(OrderRowid,"I",child,1)),"^",2)
	.s ArcimDesc=$P(^ARCIM(+ArcimRowId,$P(ArcimRowId,"||",2),1),"^",2)
	.s itemstat=$p($g(^OEORD(OrderRowid,"I",child,1)),"^",13)
	.s statcode=""
	.i itemstat'="" s statcode=$p($g(^OEC("OSTAT",itemstat)),"^",1)
	.Q:((statcode'="V")&&(statcode'="E"))
	.s billed=$p($g(^OEORD(OrderRowid,"I",child,3)),"^",5)
	.Q:(billed="P")
	.s LabEpisodeNo=$tr(LabEpisodeNo," ","")
	.if LabEpisodeNo'="" d
	..i '$d(Temp($j,LabEpisodeNo)) s Temp($j,LabEpisodeNo)=ArcimDesc
	..e  s Temp($j,LabEpisodeNo)=$g(Temp($j,LabEpisodeNo))_","_ArcimDesc

	s LabEpisodeNo=0  f  s LabEpisodeNo=$O(Temp($j,LabEpisodeNo)) Q:LabEpisodeNo=""  d
	.set Data=$lb(LabEpisodeNo,Temp($j,LabEpisodeNo))
	.Set ^CacheTemp(repid,ind)=Data
	.Set ind=ind+1
	Set qHandle=$lb(0,repid,0)
	Quit $$$OK
}

ClassMethod FindOrderLabEpisodeFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = FindOrderLabEpisodeExecute ]
{
 Set AtEnd=$LIST(qHandle,1)
 Set repid=$LIST(qHandle,2)
 Set ind=$LIST(qHandle,3)
	//
 Set ind=$o(^CacheTemp(repid,ind))
 If ind="" {				// if there are no more rows, finish fetching
 Set AtEnd=1
 Set Row=""
 }
 Else      {				// fetch row
 Set Row=^CacheTemp(repid,ind)
 }
 // Save QHandle
 s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

ClassMethod FindUnActiveOrderItemsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = FindUnActiveOrderItemsExecute ]
{
	n (%session,qHandle,%request)
	 Set repid=$LIST(qHandle,2)
	 Kill ^CacheTemp(repid)
	 Quit $$$OK
}

ClassMethod FindUnActiveOrderItemsExecute(ByRef qHandle As %Binary, EpisodeID As %String, CurLogonHosp As %String = "") As %Status
{
 ;OrderName,OrderStatus,OrderPrior,OrderDoseQty,OrderDoseUOM,OrderFreq,OrderInstr,OrderDur,OrderPrice,OrderPackQty,OrderPackQtyUOM,OrderSkinTest,OrderRecDep,OrderSum,OrderPrescNo,OrderDepProcNote,OrderDoc,OrderUserAdd,OrderMasterSeqNo,Spec,OrderLabEpisodeNo
 ;OrderItemRowid,OrderARCIMRowid,OrderSttDate,OrderDoseUOMRowid,OrderFreqRowid,OrderPriorRowid,OrderInstrRowid,OrderDurRowid,OrderPackUOMRowid,OrderRecDepRowid,OrderStatusRowid,OrderBaseUOMRowid,OrderDocRowid,OrderUserAddRowid,OrderLinkto,OrderARCOSRowid,OrderDrugForRowid,OrderMaxDurRowid,OrderType,OrderBillTypeRowid
 n (%session,%request,qHandle,EpisodeID,CurLogonHosp)
 Set repid=$I(^CacheTemp)
 If $g(ind)="" Set ind=1
 ;
 Set langid=..%LanguageID()
 do ResetVariables5
 set PatType="", InsType="", PriorRowid="", InstrRowid="", LinkTo="", OEPrice="",LabEpisodeNo=""
 set PAADMType=$p($g(^PAADM(EpisodeID)),"^",2)
 set NoDisplayItemCat=..%GetConfig("NoDisplayItemCat",CurLogonHosp)
 set ShowPaidOrder=..%GetConfig("ShowPaidOrder",CurLogonHosp)
 s AdmHospitalId=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(EpisodeID)
 s PAADMRegConDisDR=$P($G(^PAADM(EpisodeID,"DHC")),"^",25)
 s Today=..%SysDate(),CurrDateTime=..%SysDate()_..%SysTime()
 s PatType=$P(^PAADM(EpisodeID,1),"^",6)  //PAADM_Epissubtype_DR
 &SQL(DECLARE OrdCur1 CURSOR FOR
 SELECT OEORI_Rowid,OEORI_ItmMast_DR,OEORI_ItmMast_DR->ARCIM_Desc,
 OEORI_SttDat,OEORI_SttTim,Todate(OEORI_SttDat,'yyyy-mm-dd'),
 OEORI_DoseQty,OEORI_Unit_DR,OEORI_Unit_DR->CTUOM_Desc,
 OEORI_QtyPackUOM,
	    OEORI_Priority_dr,OEORI_Priority_dr->OECPR_Desc,
	    OEORI_Itemstat_dr,OEORI_Itemstat_dr->OSTAT_Desc,
	    OEORI_PHFreq_DR,OEORI_PHFreq_DR->PHCFR_Desc1,
	    OEORI_Instr_DR,OEORI_Instr_DR->PHCIN_Desc1,
	    OEORI_Durat_DR,OEORI_Durat_DR->PHCDU_Desc1,
	    OEORI_RecDep_DR,OEORI_RecDep_DR->CTLOC_Desc,
	    OEORI_UserDepartment_DR,OEORI_UserDepartment_DR->CTLOC_Desc,
	    OEORI_Doctor_DR,OEORI_Doctor_DR->CTPCP_Desc,OEORI_UserAdd,OEORI_UserAdd->SSUSR_Name,
	    OEORI_Billed,OEORI_AdministerSkinTest,OEORI_BBExtCode,
	    OEORI_ItmMast_DR->ARCIM_ItemCat_DR->ARCIC_OrderType,
	    OEORI_SeqNo,OEORI_LinkNo,OEORI_LinkToOrder,OEORI_PrescNo,OEORI_LabEpisodeNo,
	    OEORI_ARCOS_DR,OEORI_BBExtCode,OEORI_OEORI_DR,OEORI_PhSpecInstr,OEORI_Price,
	    OEORI_CoverMainIns,OEORI_Action_DR,OEORI_Action_DR->ACT_Desc,OEORI_FillerNo,OEORI_Date,
	    OEORI_TimeOrd,OEORI_Itemstat_dr->OSTAT_Code
 INTO :OrderItemRowid,:ARCIMRowid,:OrderName,:OrderSttDate,:OrderSttTime,:StartDate,
:OrderDoseQty,:OrderDoseUOMRowid,:OrderDoseUOM,:OrderPackQty,
:OrderPriorRowid,:OrderPrior,:OrderStatusRowid,:OrderStatus,:OrderFreqRowid,:OrderFreq,
:OrderInstrRowid,:OrderInstr,:OrderDurRowid,:OrderDur,
:OrderRecDepRowid,:OrderRecDep,:OrderUserDepRowid,:OrderUserDep,
:OrderDocRowid,:OrderDoc,:OrderUserAddRowid,:OrderUserAdd,
:OrderBilled,:OrderSkinTest,:OrderBillTypeRowid,:OrderType,
:OrderSeqNo,:OrderMasterSeqNo,:OrderLinkTo,:OrderPrescNo,:OrderLabEpisodeNo,
:OrderARCOSRowid,:OrderBillTypeRowid,:LinkOrderItem,:OrderPhSpecInstr,:OrderPrice,
:OrderCoverMainIns,:OrderActionRowid,:OrderAction,:FillerNo,:DateAdd,:TimeAdd,:OrderStatusCode
 From SQLUser.OE_OrdItem 
 WHERE OEORI_OEORD_PARREF->OEORD_ADM_DR=:EpisodeID  and
 ((OEORI_ItemStat_DR->OSTAT_Code ='I') or (OEORI_ItemStat_DR->OSTAT_Code ='V'))Order By OEORI_SttDat desc)
 &SQL(OPEN OrdCur1) //and OEORI_SttDat>=:Today
 For  &SQL(FETCH OrdCur1) QUIT:SQLCODE  do
 	.s OrderName=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",OrderName,langid)
 	.s OrderDoseUOM=##class(User.CTUOM).GetTranByDesc("CTUOMDesc",OrderDoseUOM,langid)
 	.s OrderPrior=##class(User.OECPriority).GetTranByDesc("OECPRDesc",OrderPrior,langid)
 	.s OrderFreq=##class(User.PHCFreq).GetTranByDesc("PHCFRDesc1",OrderFreq,langid)
 	.s OrderInstr=##class(User.PHCInstruc).GetTranByDesc("PHCINDesc1",OrderInstr,langid)
 	.s OrderDur=##class(User.PHCDuration).GetTranByDesc("PHCDUDesc1",OrderDur,langid)
 	.s OrderRecDep=##class(User.CTLoc).GetTranByDesc("CTLOCDesc",OrderRecDep,langid)
 	.s OrderUserDep=##class(User.CTLoc).GetTranByDesc("CTLOCDesc",OrderUserDep,langid)
 	.s OrderDoc=##class(User.CTCareProv).GetTranByDesc("CTPCPDesc",OrderDoc,langid)
 	.s OrderAction=##class(User.OECAction).GetTranByDesc("ACTDesc",OrderAction,langid)
	.s OrderUserAdd=##class(User.SSUser).GetTranByDesc("SSUSRName",OrderUserAdd,langid)
 	.s OrdFreqInfo=##class(DHCDoc.Interface.Inside.ServiceOrd).GetOrdFreqInfo(OrderItemRowid,"^")
	.s OrderFreq=$List(OrdFreqInfo,2)
	.s OrderFreq=$REPLACE(OrderFreq,"^","-")
 	.s OrderDoseQty=##class(DHCDoc.Interface.Inside.Service).GetOrdDoseQty(OrderItemRowid)
 	.s ReqPartDesc=##Class(web.DHCAPPInterface).GetExaReqPartDesc(OrderItemRowid)
 	.s ScrentName=##class(web.DHCARCOrdSets).CheckPresno(OrderItemRowid,"",AdmHospitalId)
	.if (ScrentName'=0){s OrderName=$P(ScrentName,"^",2)}
 	.s OrderName=OrderName_ReqPartDesc
    .s OrderSttTime=..%ZT(OrderSttTime,1)
	. ;OrderDepProcNote,Spec,OrderBaseUOMRowid,OrderMaxDurRowid
	. s billed=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),3)),"^",5)
	. q:(billed="P")&(ShowPaidOrder'="1")
	. s subcat=$p($g(^ARCIM(+ARCIMRowid,1,1)),"^",10)
	. //实习医嘱不走此判断，否则未核实医嘱无法通过审核
	. //Q:(NoDisplayItemCat'="")&(subcat'="")&(("^"_NoDisplayItemCat_"^")[("^"_subcat_"^"))
	. ;非本科室医嘱退出
	. Q:OrderUserDepRowid'=%session.Get("LOGON.CTLOCID")
	. ;非实习医生医嘱退出
	. //Q:..practice(OrderDocRowid)'=1
	. s PracticeConfirmStopStatus=$P($G(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DHC")),"^",51)  ;注意根据实际情况修改节点值
	. Q:(OrderStatusCode="V")&&(PracticeConfirmStopStatus="")
	. ;Q:OrderStatusCode="I"
	. s PracticeConfirmStopStatusCode=""
	. i PracticeConfirmStopStatus'="" s PracticeConfirmStopStatusCode=$p(^OEC("OSTAT",PracticeConfirmStopStatus),"^",1)
	. i (PracticeConfirmStopStatusCode="C") s OrderStatus="待撤销" 
	. e  i (PracticeConfirmStopStatusCode="D") s OrderStatus="待停止" 
	. e  i (PracticeConfirmStopStatusCode="U") s OrderStatus="待作废" 
	. s OrderStatus=..%Translate("doc.ordverify.hui.csp",OrderStatus)
	. ;住院非新开长嘱不显示
	. ;Q:(PAADMType="I")&(FillerNo'="")
	. s DateTimeAdd=$g(DateAdd)_$g(TimeAdd)
	. ;下医嘱时间超过半小时则不显示
	. ;Q:(CurrDateTime-DateTimeAdd)>1800
	. s orcat=$p($g(^ARC("IC",+subcat)),"^",8)
	. s orcatdesc=""
	. i orcat'="" s orcatdesc=$p($g(^OEC("ORCAT",orcat)),"^",2)
	. s RecDepDesc=$p(OrderRecDep,"-",2)
	. i RecDepDesc'="" s OrderRecDep=RecDepDesc
	. s OrderPackUOMRowid=##Class(web.DHCDocOrderCommon).GetOrdPackUOMDR(OrderItemRowid)
	. s OrderPackUOM=##class(web.DHCDocOrderCommon).GetUOMDesc(OrderPackUOMRowid)
	.s CheckCHNFlag=##class(web.DHCSTINTERFACE).GetStruModeFlag(ARCIMRowid)
	.if (CheckCHNFlag="Y") d
	..s Phcdf=$P($g(^ARCIM(+ARCIMRowid,$P(ARCIMRowid,"||",2),1)),"^",12)
	..if Phcdf'="" s OrderPackUOMRowid=$p(^PHCD(+Phcdf,"DF",$p(Phcdf,"||",2),2),"^",4),OrderPackUOM=##class(web.DHCDocOrderCommon).GetUOMDesc(OrderPackUOMRowid)
	. s UserDep=$p(OrderUserDep,"-",2)
	. i UserDep'="" s OrderUserDep=UserDep
	. ;批次价入参
	. //s ExpStr=PAADMRegConDisDR_"^"_OrderItemRowid_"^"_""_"^"_EpisodeID_"^"_OrderRecDepRowid
	. s ExpStr=OrderItemRowid_"^"_""_"^"_EpisodeID_"^"_OrderRecDepRowid
	. i OrderType'="P" d
	. . ;s retPrice=##class(web.DHCDocOrderEntry).GetOrderPrice(PatType, InsType, ARCIMRowid, OrderSttDate, PriorRowid, InstrRowid, LinkTo, OEPrice)
	. . s retPrice=##class(web.DHCDocOrderCommon).GetOrderPrice(PatType, InsType, ARCIMRowid, OrderSttDate, PriorRowid, InstrRowid, LinkTo, OEPrice,OrderRecDepRowid,PAADMRegConDisDR,OrderPackUOMRowid,ExpStr)
	. . ;w retPrice,!
	. . s OrderPrice=$P(retPrice,"^",1)
	. . s OrderPrice=$fn(OrderPrice,"",4)
	. . s DiscPrice=$P(retPrice,"^",2)
	. . s InsPrice=$P(retPrice,"^",3)
	. . s PatPrice=$P(retPrice,"^",4)
	. s OrderSum=OrderPackQty*OrderPrice
	. s OrderSum=$fn(OrderSum,"",4)
	. i OrderBillTypeRowid="" s OrderBillType="自费"
	. e  s OrderBillType=$P(^PAC("ADMREA",OrderBillTypeRowid),"^",2)
	. i OrderDoseQty'="" d
	. . i OrderDoseQty<1 s OrderDoseQty="0"_$number(OrderDoseQty)
	. i OrderType'="R" d
	. .s DoseqtySum=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),1)),"^",12)
	. .s OrderPackQty=DoseqtySum
	
	.i (OrderType="R") d
	..;如果没有填数量则自动计算数量
	..i +OrderPackQty=0  d
	...s OrdMesage=##class(web.DHCDocOrderCommon).GetOrderMesage(OrderItemRowid)
	...s ActiveQty=$P(OrdMesage,"^",12)
	...s OrderPackQty=+ActiveQty
	. //s OrderPackUOM=$p(OrderPackUOM,"(",1)
	. s OrderSum=OrderPackQty*OrderPrice
	. s OrderSum=$fn(OrderSum,"",4)
	. i OrderPackQty'="" d
	. . i OrderPackQty<1,OrderPackQty["." s OrderPackQty="0"_$number(OrderPackQty)
	. s DepProcNotes=$g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DEP",1))
	. s OrderLabSpec=..GetLabSpec(OrderItemRowid)
	. s OrderLabExCode=""
	. s OrderDrugFormRowid=##class(web.DHCDocOrderEntry).GetDrgForm(ARCIMRowid)
	. s OrderAutoCalculate=1
	. s OrderFile1=$p($g(^ARCIM($p(ARCIMRowid,"||",1),1,9)),"^",5)
	. s OrderFile2=$p($g(^ARCIM($p(ARCIMRowid,"||",1),1,9)),"^",19)
	. s OrderFile3=$p($g(^ARCIM($p(ARCIMRowid,"||",1),1,9)),"^",20)
	. ;备注
	. s OrderDepProcNote=$g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DEP",1)) 
	. if OrderDepProcNote="" s OrderDepProcNote=$P($G(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),2)),"^",8) ;草药单个药物备注
	. if OrderFreqRowid'="" d
	..s WeekFlag=$P(^PHCFR(OrderFreqRowid),"^",9)
	..i WeekFlag="Y" s OrderFreqWeek=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DHC")),"^",55),OrderFreq=OrderFreq_"-"_$TR(OrderFreqWeek,"|","")
	. if (ScrentName'=0){s (OrderDoseQty,OrderDoseUOM,OrderPackQty,OrderPackUOM)="*"}
	. s Data1=$lb(OrderName,OrderStatus,OrderPrior,..%ZD(OrderSttDate),OrderSttTime,OrderDoseQty,OrderDoseUOM,OrderFreq,OrderInstr,OrderDur,OrderPrice,OrderPackQty,OrderPackUOM,OrderSkinTest,OrderRecDep,OrderUserDep,OrderSum,OrderPrescNo,OrderDepProcNote,OrderDoc,OrderUserAdd,OrderSeqNo,OrderMasterSeqNo,OrderLinkTo,OrderLabEpisodeNo,OrderItemRowid,ARCIMRowid,OrderSttDate,OrderDoseUOMRowid,OrderFreqRowid,OrderPriorRowid,OrderInstrRowid,OrderDurRowid,OrderPackUOMRowid,OrderRecDepRowid,OrderUserDepRowid,OrderStatusRowid,OrderBaseUOMRowid,OrderDocRowid,OrderUserAddRowid,OrderARCOSRowid,OrderDrugFormRowid,OrderMaxDurRowid,OrderType,OrderBillTypeRowid,OrderMaxDurRowid,OrderBillType,DepProcNotes,OrderPhSpecInstr,OrderLabSpec,OrderAutoCalculate,OrderCoverMainIns,OrderActionRowid,OrderAction,OrderFile1,OrderFile2,OrderFile3,OrderLabExCode,LinkOrderItem,OrderStatusCode)
	. i LinkOrderItem="" s ^CacheTemp("DHCFindOrdItem",$j,"master",OrderItemRowid)=Data1
	. e  d
	. .if '$D(^CacheTemp("DHCFindOrdItem",$j,"master",LinkOrderItem)) d
	. ..s ^CacheTemp("DHCFindOrdItem",$j,"master",LinkOrderItem)=""
	. .s ^CacheTemp("DHCFindOrdItem",$j,"master",LinkOrderItem,"sub",OrderItemRowid)=Data1
	&SQL(CLOSE OrdCur1)
	;m ^zhou("b")=^CacheTemp("DHCFindOrdItem")
	s SeqNo=0
	s mas=0 for  s mas=$O(^CacheTemp("DHCFindOrdItem",$j,"master",mas)) q:mas=""  d
	. s s1=^CacheTemp("DHCFindOrdItem",$j,"master",mas)
	. i s1'="" d 
	. .s SeqNo=SeqNo+1
	. .s $List(s1,22)=SeqNo
	. .s Data=s1
	. .d OutputRow5
	. s SubSeqCount=0
	. s sub=0  for  s sub=$O(^CacheTemp("DHCFindOrdItem",$j,"master",mas,"sub",sub)) q:sub=""  d
	. . s s2=^CacheTemp("DHCFindOrdItem",$j,"master",mas,"sub",sub)
	. . i s1="" d
	. . . s SeqNo= SeqNo+1
	. . . s $List(s2,22)=SeqNo
	. . . s Data=s2
	. . . d OutputRow5
	. . e  d
	. . . s SubSeqCount=SubSeqCount+1
	. . . s SubSeqNo=SeqNo_"."_SubSeqCount
	. . . s $List(s2,22)=SubSeqNo
	. . . s Data=s2
	. . . d OutputRow5
	k ^CacheTemp("DHCFindOrdItem",$j,"master")

 /*i ind=1 d
 . do ResetVariables5
 . set Data=$lb(OrderName,OrderStatus,OrderPrior,OrderSttDate,OrderSttTime,OrderDoseQty,OrderDoseUOM,OrderFreq,OrderInstr,OrderDur,OrderPrice,OrderPackQty,OrderPackQtyUOM,OrderSkinTest,OrderRecDep,OrderUserDep,OrderSum,OrderPrescNo,OrderDepProcNote,OrderDoc,OrderUserAdd,OrderSeqNo,OrderMasterSeqNo,OrderLinkTo,OrderLabEpisodeNo,OrderItemRowid,ARCIMRowid,OrderSttDate,OrderDoseUOMRowid,OrderFreqRowid,OrderPriorRowid,OrderInstrRowid,OrderDurRowid,OrderPackUOMRowid,OrderRecDepRowid,OrderUserDepRowid,OrderStatusRowid,OrderBaseUOMRowid,OrderDocRowid,OrderUserAddRowid,OrderARCOSRowid,OrderDrugFormRowid,OrderMaxDurRowid,OrderType,OrderBillTypeRowid,OrderMaxDurRowid,OrderBillType,DepProcNotes,OrderPhSpecInstr,OrderLabSpec,OrderAutoCalculate,OrderCoverMainIns,OrderActionRowid,OrderAction,OrderFile1,OrderFile2,OrderFile3,OrderLabExCode,LinkOrderItem)
 . Do OutputRow5*/
 Set qHandle=$lb(0,repid,0)
 Quit $$$OK
OutputRow5
 ;set Data=$lb(OrderName,OrderStatus,OrderPrior,OrderSttDate,OrderSttTime,OrderDoseQty,OrderDoseUOM,OrderFreq,OrderInstr,OrderDur,OrderPrice,OrderPackQty,OrderPackQtyUOM,OrderSkinTest,OrderRecDep,OrderUserDep,OrderSum,OrderPrescNo,OrderDepProcNote,OrderDoc,OrderUserAdd,OrderSeqNo,OrderMasterSeqNo,OrderLinkTo,OrderLabEpisodeNo,OrderItemRowid,ARCIMRowid,OrderSttDate,OrderDoseUOMRowid,OrderFreqRowid,OrderPriorRowid,OrderInstrRowid,OrderDurRowid,OrderPackUOMRowid,OrderRecDepRowid,OrderUserDepRowid,OrderStatusRowid,OrderBaseUOMRowid,OrderDocRowid,OrderUserAddRowid,OrderARCOSRowid,OrderDrugFormRowid,OrderMaxDurRowid,OrderType,OrderBillTypeRowid,OrderMaxDurRowid,OrderBillType,DepProcNotes)
 Set ^CacheTemp(repid,ind)=Data
 Set ind=ind+1
 quit
ResetVariables5
 set (OrderName,OrderStatus,OrderPrior,OrderSttDate,OrderSttTime,OrderDoseQty,OrderDoseUOM,OrderFreq,OrderInstr,OrderDur,OrderPrice,OrderPackQty,OrderPackQtyUOM,OrderSkinTest,OrderRecDep,OrderUserDep,OrderSum,OrderPrescNo,OrderDepProcNote,OrderDoc,OrderUserAdd,OrderSeqNo,OrderMasterSeqNo,OrderLinkTo,OrderLabEpisodeNo,OrderItemRowid,ARCIMRowid,OrderSttDate,OrderDoseUOMRowid,OrderFreqRowid,OrderPriorRowid,OrderInstrRowid,OrderDurRowid,OrderPackUOMRowid,OrderRecDepRowid,OrderUserDepRowid,OrderStatusRowid,OrderBaseUOMRowid,OrderDocRowid,OrderUserAddRowid,OrderARCOSRowid,OrderDrugFormRowid,OrderMaxDurRowid,OrderType,OrderBillTypeRowid,OrderMaxDurRowid,OrderBillType,DepProcNotes,OrderPhSpecInstr,OrderLabSpec,OrderAutoCalculate,OrderCoverMainIns,OrderActionRowid,OrderAction,OrderFile1,OrderFile2,OrderFile3,OrderLabExCode,LinkOrderItem,OrderStatusCode)=""
 Quit
}

ClassMethod FindUnActiveOrderItemsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = FindUnActiveOrderItemsExecute ]
{
	n (qHandle,Row,AtEnd)
	Set AtEnd=$LIST(qHandle,1)
	Set repid=$LIST(qHandle,2)
	Set ind=$LIST(qHandle,3)
	//
	Set ind=$o(^CacheTemp(repid,ind))
	If ind="" {				// if there are no more rows, finish fetching
	Set AtEnd=1
	Set Row=""
	}
	Else      {				// fetch row
	Set Row=^CacheTemp(repid,ind)
	}
	// Save QHandle
	s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

ClassMethod FormatCNMedName(OrderName1 As %String) As %String
{
	 s ret=$P(OrderName1,"*",1)
	 Q:(OrderName1[("*")) ret
	 s ret=$P(OrderName1,"$",1)
	 Q:(OrderName1[("$")) ret
	 s ret=$P(OrderName1,"#",1)
	 Q:(OrderName1[("#")) ret
	 s ret=$P(OrderName1,"(",1)
	 Q:(OrderName1[("(")) ret
	 Q OrderName1
}

ClassMethod GetCNPrescItemsBroker(itmjs As %Library.String = "", EpisodeID As %String, PrescNo As %String) As %Library.String
{
	;Rowid:OrderName:,StartDate:SeqNo:DoseQty:DoseUOM:Priority:Status:Frequence:Instruction:Duration:PackQty:RecDep:Billed")
	Set rset=##class(%ResultSet).%New("web.DHCOEOrdItem:GetCNPrescItems")
	do rset.Execute(EpisodeID,PrescNo)
	Set columns = rset.GetColumnCount()
	While (rset.Next()) {
		For col = 1:1:columns {
			;Write rset.GetColumnName(col),":"
			if col=1 set value=rset.GetData(col)
			e  s value=value_"^"_rset.GetData(col)
		}
		s retval=itmjs_"('"_$ZCVT(value,"O","JS")_"');"
		&javascript<#(retval)#>
	}
	d rset.Close()
	Q 1
}

ClassMethod GetCNPrescItemsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = GetCNPrescItemsExecute ]
{
 Set repid=$LIST(qHandle,2)
 Kill ^CacheTemp(repid)
 Quit $$$OK
}

ClassMethod GetCNPrescItemsExecute(ByRef qHandle As %Binary, EpisodeID As %String, PrescNo As %String) As %Status
{
 Set repid=$I(^CacheTemp)
 If $g(ind)="" Set ind=1
 s OrderName1="", PackQty1="",DoseQty1="",DoseUOM1="", Price1="", PhSpecInstr1="", ItemID1="", OrderItemID1=""
 s OrderName2="", PackQty2="",DoseQty2="",DoseUOM2="", Price2="", PhSpecInstr2="", ItemID2="", OrderItemID2=""
 s OrderName3="", PackQty3="",DoseQty3="",DoseUOM3="", Price3="", PhSpecInstr3="", ItemID3="", OrderItemID3=""
 s OrderName4="", PackQty4="",DoseQty4="",DoseUOM4="", Price4="", PhSpecInstr4="", ItemID4="", OrderItemID4=""
 set RowCount=0
 set MultiRowCount=0
 set PatType="", InsType="", PriorRowid="", InstrRowid="", LinkTo="", OEPrice=""
 do CheckRowCount1
 if RowCount>0 d
 .s PatType=$P(^PAADM(EpisodeID,1),"^",6)  //PAADM_Epissubtype_DR
 .&sql(DECLARE PrescCursor CURSOR FOR
 SELECT OEORI_Rowid,OEORI_ItmMast_DR->ARCIM_Desc,Todate(OEORI_SttDat,'dd/mm/yyyy'),OEORI_SeqNo,
 OEORI_DoseQty,OEORI_UNIT_DR->CTUOM_Desc,
	       OEORI_Priority_dr->OECPR_Desc,OEORI_Itemstat_dr->OSTAT_Desc,oeori_PHFreq_dr->PHCFR_Desc1,
	       OEORI_instr_dr->PHCIN_Desc1,OEORI_Durat_dr->PHCDU_Desc1,
	       OEORI_QtyPackUOM,
	       OEORI_RecDep_DR->CTLOC_Desc,OEORI_Billed,OEORI_ItmMast_DR,OEORI_SttDat,OEORI_BBExtCode,
	       OEORI_UserAdd->SSUSR_Initials,OEORI_UserAdd->SSUSR_Name,OEORI_PhSpecInstr,
	       OEORI_RecDep_DR
	  INTO :OrderItemID,:OrderName,:StartDate,:SeqNo,:DoseQty,:DoseUOM,:Priority,:Status,:Frequence,:Instruction,:Duration,:PackQty,:RecDep,:Billed,:ARCIMRowid,:SttDate,:BillType,:UserAddCode,:UserAddName,:PhSpecInstr,:RecDepRowId
	  From SQLUser.OE_OrdItem 
	 WHERE OEORI_PrescNo=:PrescNo and OEORI_OEORD_PARREF->OEORD_ADM_DR=:EpisodeID and 
	       OEORI_ItemStat_DR->OSTAT_Code='V' and OEORI_ItmMast_DR->ARCIM_ItemCat_DR->ARCIC_OrderType='R')
	.&sql(OPEN PrescCursor)
 .for  &SQL(FETCH PrescCursor) QUIT:SQLCODE  do
	..s PackUOMRowid=##Class(web.DHCDocOrderCommon).GetOrdPackUOMDR(OrderItemID)
	..s PackUOM=##class(web.DHCDocOrderCommon).GetUOMDesc(PackUOMRowid)
	..;s retPrice=##class(web.DHCDocOrderEntry).GetOrderPrice(PatType, InsType, ARCIMRowid, SttDate, PriorRowid, InstrRowid, LinkTo, OEPrice)
	..s retPrice=##class(web.DHCDocOrderCommon).GetOrderPrice(PatType, InsType, ARCIMRowid, SttDate, PriorRowid, InstrRowid, LinkTo, OEPrice,RecDepRowId)
	..;w retPrice,!
	..s TOrderName=..FormatCNMedName(OrderName)
	..s OrderName=TOrderName
	..s Price=$P(retPrice,"^",1)
	..s DiscPrice=$P(retPrice,"^",2)
	..s InsPrice=$P(retPrice,"^",3)
	..s PatPrice=$P(retPrice,"^",4)
	..s Sum=PackQty*Price
	..i BillType="" s BillTypeDesc="自费"
	..e  s BillTypeDesc=$P(^PAC("ADMREA",BillType),"^",2)
	..;
	..s PackUOM=$p(PackUOM,"(",1)
	..s MultiRowCount=MultiRowCount+1
	..i MultiRowCount=1 d
 ... s OrderName1=OrderName,PackQty1=PackQty, DoseQty1=DoseQty,DoseUOM1=DoseUOM, Price1=Price, PhSpecInstr1=PhSpecInstr, ItemID1=ARCIMRowid, OrderItemID1=OrderItemID
	..i MultiRowCount=2 d
 ... s OrderName2=OrderName,PackQty2=PackQty, DoseQty2=DoseQty,DoseUOM2=DoseUOM,Price2=Price, PhSpecInstr2=PhSpecInstr, ItemID2=ARCIMRowid, OrderItemID2=OrderItemID
	..i MultiRowCount=3 d
	... s OrderName3=OrderName,PackQty3=PackQty, DoseQty3=DoseQty,DoseUOM3=DoseUOM, Price3=Price, PhSpecInstr3=PhSpecInstr, ItemID3=ARCIMRowid, OrderItemID3=OrderItemID
	..i MultiRowCount=4 d
	... s OrderName4=OrderName,PackQty4=PackQty, DoseQty4=DoseQty,DoseUOM4=DoseUOM, Price4=Price, PhSpecInstr4=PhSpecInstr, ItemID4=ARCIMRowid, OrderItemID4=OrderItemID
	...do OutputRow3
	...do ResetVariables3
	...s MultiRowCount=0
	.&sql(CLOSE PrescCursor)
	.i MultiRowCount>0 d OutputRow3
 else  Do
 .do ResetVariables3
 .Do OutputRow3 	
 Set qHandle=$lb(0,repid,0)
	Quit $$$OK
OutputRow3
	set Data=$lb(OrderName1,Price1, DoseQty1, DoseUOM1, PhSpecInstr1, PackQty1,ItemID1, OrderItemID1,OrderName2,Price2, DoseQty2, DoseUOM2, PhSpecInstr2,PackQty2, ItemID2, OrderItemID2,OrderName3, Price3, DoseQty3, DoseUOM3, PhSpecInstr3,PackQty3, ItemID3, OrderItemID3,OrderName4,Price4, DoseQty4,DoseUOM4,PhSpecInstr4,PackQty4, ItemID4, OrderItemID4)
 Set ^CacheTemp(repid,ind)=Data
 Set ind=ind+1
	Quit
ResetVariables3
	set (OrderName1,Price1, DoseQty1, DoseUOM1, PhSpecInstr1, PackQty1,ItemID1, OrderItemID1,OrderName2,Price2, DoseQty2, DoseUOM2, PhSpecInstr2,PackQty2, ItemID2, OrderItemID2,OrderName3, Price3, DoseQty3, DoseUOM3, PhSpecInstr3,PackQty3, ItemID3, OrderItemID3,OrderName4,Price4, DoseQty4,DoseUOM4,PhSpecInstr4,PackQty4, ItemID4, OrderItemID4)=""
	quit
CheckRowCount1
 if PrescNo="" s RowCount=0
 else  d
 .&sql(SELECT Count(*) INTO :RowCount From SQLUser.OE_OrdItem 
	 WHERE OEORI_PrescNo=:PrescNo and OEORI_OEORD_PARREF->OEORD_ADM_DR=:EpisodeID)
	quit
}

ClassMethod GetCNPrescItemsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = GetCNPrescItemsExecute ]
{
 Set AtEnd=$LIST(qHandle,1)
 Set repid=$LIST(qHandle,2)
 Set ind=$LIST(qHandle,3)
	//
 Set ind=$o(^CacheTemp(repid,ind))
 If ind="" {				// if there are no more rows, finish fetching
 Set AtEnd=1
 Set Row=""
 }
 Else      {				// fetch row
 Set Row=^CacheTemp(repid,ind)
 }
 // Save QHandle
 s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

ClassMethod GetCNPrescListBroker(itmjs As %Library.String = "", EpisodeID As %String) As %String
{
	 Set rset=##class(%ResultSet).%New("web.DHCOEOrdItem:GetCNPrescriptions")
	 do rset.Execute(EpisodeID)
	 While (rset.Next()) {
		s PrescNo=rset.Data("PrescNo")
		s RecDep=rset.Data("RecDep")
		s PrescDate=rset.Data("PrescDate")
		s BillType=rset.Data("BillType")
		s UserAddName=rset.Data("UserAddName")
		s DurFactor="共"_rset.Data("DurFactor")_"付"
		s PrescInstr=rset.Data("PrescInstr")
		s Desc=PrescNo_"   "_PrescDate_"   "_RecDep_"   "_BillType_"   "_UserAddName_"   "_DurFactor_"   "_PrescInstr
		;w Desc,!
		s retval=itmjs_"('"_$ZCVT(Desc,"O","JS")_"','"_$ZCVT(PrescNo,"O","JS")_"');"
		&javascript<#(retval)#>
	 }
	 d rset.Close()
	 q 0
}

ClassMethod GetCNPrescriptionsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = GetCNPrescriptionsExecute ]
{
 Set repid=$LIST(qHandle,2)
 Kill ^CacheTemp(repid)
 Quit $$$OK
}

ClassMethod GetCNPrescriptionsExecute(ByRef qHandle As %Binary, EpisodeID As %String) As %Status
{
 ;SELECT QUE1_PrescNo,to_Date(QUE1_TransDate,'YYYY-MM-DD'),cast(QUE1_TransTime AS TIMESTAMP),QUE1_DepartmentLoc_DR->CTLOC_Desc
	  ;from SQLUser.PA_Que1 
	 ;Where QUE1_PAADM_DR=:EpisodeID 
	 ;Order By QUE1_PrescNo)
 Set repid=$I(^CacheTemp)
 If $g(ind)="" Set ind=1
 s AdmHospitalId=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(EpisodeID)
 s PrescNo="", TransDate="", TransTime="", RecLoc="",DurFactor="",BillTypeDesc="",UserAddName=""
 &sql(DECLARE EmpCur1 CURSOR FOR
 SELECT distinct OEORI_PrescNo,to_Date(OEORI_Date,'YYYY-MM-DD'),cast(OEORI_Time AS TIMESTAMP),OEORI_RecDep_DR->CTLOC_Desc
	  INTO :PrescNo,:TransDate,:TransTime,:RecLoc
	  from SQLUser.OE_OrdItem 
	 Where OEORI_OEORD_Parref->OEORD_ADM_DR=:EpisodeID and OEORI_PrescNo<>""
	  Order By OEORI_PrescNo)
 &sql(OPEN EmpCur1)
 for  &SQL(FETCH EmpCur1) QUIT:SQLCODE  do
 .s Count=..GetPrescItemCount(EpisodeID,PrescNo)
 .i (Count>0) Do
 ..s OrderRowid=$o(^OEORD(0,"Adm",+EpisodeID,""))
 ..s find="N"
 ..s itemsub=$O(^OEORD(0,"PrescNo",PrescNo,OrderRowid,0))
 ..s BillType=$p($g(^OEORD(OrderRowid,"I",itemsub,11)),"^",18) 
 ..i BillType="" s BillTypeDesc="自费"
 ..e  s BillTypeDesc=$P(^PAC("ADMREA",BillType),"^",2)
 ..s UserAdd=$p($g(^OEORD(OrderRowid,"I",itemsub,7)),"^",1)
 ..i UserAdd'="" s UserAddName=$P($G(^SSU("SSUSR",UserAdd)),"^",2)
 ..e  s UserAddName=""
 ..s Dur=$P(^OEORD(OrderRowid,"I",itemsub,2),"^",6)
 ..i Dur'="" s DurFactor=$p($g(^PHCDU(Dur)),"^",2)
 ..e  s DurFactor=1
 ..;
 ..s FreqFactor=1
 ..s Freq=$P(^OEORD(OrderRowid,"I",itemsub,2),"^",4)
 ..i Freq'="" s FreqFactor=$P($g(^PHCFR(Freq)),"^",2)
 ..i FreqFactor="" s FreqFactor=1
 ..s DurFactor=DurFactor*FreqFactor
 ..;
 ..s Instr="",ItemCatDR=""
 ..s InstrRowid=$P(^OEORD(OrderRowid,"I",itemsub,2),"^",7)
 ..i InstrRowid'="" s Instr=$P($G(^PHCIN(InstrRowid)),"^",2)
 ..s ArcimRowid=$p(^OEORD(OrderRowid,"I",itemsub,1),"^",2)
 ..i ArcimRowid'="" s ItemCatDR=$p(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),1),"^",10)
 ..s ArcimDesc=$p($g(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),1)),"^",2)
 ..s PHPrescType=##class(web.DHCDocOrderCommon).GetPHPrescType(ItemCatDR,AdmHospitalId,ARCIMRowid)
 ..i PHPrescType="3" d
 ...i ArcimDesc[("药滤") d
 ....s itemsub=$O(^OEORD(0,"PrescNo",PrescNo,OrderRowid,itemsub))
 ....i itemsub'="" d
 .....s Dur=$P(^OEORD(OrderRowid,"I",itemsub,2),"^",6)
 .....i Dur'="" s DurFactor=$p($g(^PHCDU(Dur)),"^",2)
 .....e  s DurFactor=1
 .....;
 .....s FreqFactor=1
 .....s Freq=$P(^OEORD(OrderRowid,"I",itemsub,2),"^",4)
 .....i Freq'="" s FreqFactor=$P($g(^PHCFR(Freq)),"^",2)
 .....i FreqFactor="" s FreqFactor=1
 .....;
 .....s DurFactor=DurFactor*FreqFactor
 .....s InstrRowid=$P(^OEORD(OrderRowid,"I",itemsub,2),"^",7)
 .....i InstrRowid'="" s Instr=$P($G(^PHCIN(InstrRowid)),"^",2)
 .....e  s Instr=""
 ...d OutputRow1	
 &sql(CLOSE EmpCur1)
 Set qHandle=$lb(0,repid,0)
	Quit $$$OK
OutputRow1
	set Data=$lb(PrescNo,TransDate,TransTime,RecLoc,BillTypeDesc,UserAddName,DurFactor,Instr)
 Set ^CacheTemp(repid,ind)=Data
 Set ind=ind+1
	Quit
ResetVariables1
	set Data=$lb(PrescNo,TransDate,TransTime,RecLoc,BillTypeDesc,UserAddName,DurFactor,Instr)
	quit
}

ClassMethod GetCNPrescriptionsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = GetCNPrescriptionsExecute ]
{
 Set AtEnd=$LIST(qHandle,1)
 Set repid=$LIST(qHandle,2)
 Set ind=$LIST(qHandle,3)
	//
 Set ind=$o(^CacheTemp(repid,ind))
 If ind="" {				// if there are no more rows, finish fetching
 Set AtEnd=1
 Set Row=""
 }
 Else      {				// fetch row
 Set Row=^CacheTemp(repid,ind)
 }
 // Save QHandle
 s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

/// Creator:      徐鹏
/// CreatDate:    2009.03.27
/// Description:  根据登陆用户Rowid取得用户对应的医护人员类型
/// Table:        SS_User,CT_CareProv,CT_CarPrvTp
/// Input:        SSUserRowid:SS_User表Rowid
/// OutPut:		  CareProvType:用户对应的医护人员类型
/// Others:        
ClassMethod GetCarPrvTpByUserRowid(SSUserRowid As %String) As %Status
{
	s CareProvType=""
	q:SSUserRowid="" ""
	s CarPrvRowid=$p($g(^SSU("SSUSR",SSUserRowid)),"^",14)
	q:CarPrvRowid=""
	s CarPrvTypeDR=$p($g(^CTPCP(CarPrvRowid,1)),"^",4)
	q:CarPrvTypeDR=""
	s CareProvType=$p($g(^CT("CPT",CarPrvTypeDR)),"^",1)
	q CareProvType
}

ClassMethod GetDaysDTPresc(EpisodeID As %String, Days As %String, CurLogonHosp As %String = "") As %String
{
 	s PatientID=$p($g(^PAADM(EpisodeID)),"^",1)
 	s PAADMType=$p($g(^PAADM(EpisodeID)),"^",2)
 	s AdmStr=""
 	s SttDate=..%SysDate()-Days
 	s EndDate=..%SysDate()   
 	s Adm=0  f  s Adm=$O(^PAPERdr(PatientID,"ADM","O",Adm)) Q:(Adm="")  d
	.s AdmDate=$P(^PAADM(Adm),"^",6)
	.;w AdmDate_"^"_Adm,!
	.Q:(SttDate'="")&(AdmDate<SttDate)
	.Q:(EndDate'="")&(AdmDate>EndDate)
	.i AdmStr="" s AdmStr=Adm
	.e  s AdmStr=AdmStr_"^"_Adm
 	s Adm=0  f  s Adm=$O(^PAPERdr(PatientID,"ADM","E",Adm)) Q:(Adm="")  d
	.s AdmDate=$P(^PAADM(Adm),"^",6)
	.;w AdmDate_"^"_Adm,!
	.Q:(SttDate'="")&(AdmDate<SttDate)
	.Q:(EndDate'="")&(AdmDate>EndDate)
	.i AdmStr="" s AdmStr=Adm
	.e  s AdmStr=AdmStr_"^"_Adm
 	i AdmStr="" s AdmStr=EpisodeID
 	s len=$LENGTH(AdmStr,"^")
 	k ^CacheTemp("DHCDTPresc",$J)
 	For i = 1:1:len {
	    s CurrEpisodeID=$P(AdmStr,"^",i)
	    s GroupNumber=1
 		s OrderRowid=$o(^OEORD(0,"Adm",+CurrEpisodeID,""))
 		Q:OrderRowid=""
 		s sub=0 
 		f  s sub=$O(^OEORD(OrderRowid,"I",sub)) Q:sub=""  d
		.s itemstat=$p($g(^OEORD(OrderRowid,"I",sub,1)),"^",13)
		.s statcode=""
		.i itemstat'="" s statcode=$p($g(^OEC("OSTAT",itemstat)),"^",1)
		.Q:(statcode'="V")&(statcode'="E")
		.s SttDate=$p($g(^OEORD(OrderRowid,"I",sub,1)),"^",9)
		.s ItmID=$P($G(^OEORD(OrderRowid,"I",sub,1)),"^",2)
		.s ItemCatDR=$p(^ARCIM(+ItmID,$p(ItmID,"||",2),1),"^",10)
		.s OrderType=$P(^ARC("IC",ItemCatDR),"^",7)
		.Q:OrderType'="R"
		.s Durdr=$P($G(^OEORD(OrderRowid,"I",sub,2)),"^",6)    ;lgl+
		.s DurFac=0
		.i Durdr'="" s DurFac=$P($G(^PHCDU(Durdr)),"^",2)
		.Q:((SttDate+DurFac)<EndDate)    ;已过持续期
		.s PHPrescType=##class(web.DHCDocOrderCommon).GetPHPrescType(ItemCatDR,CurLogonHosp,ItmID)
		.s DTCheckCNMed=..%GetConfig("DTCheckCNMed",CurLogonHosp)
		.Q:((PHPrescType=3)&(DTCheckCNMed'=1))  //判断草药是否需要检查
		.s PrescNo=$P($G(^OEORD(OrderRowid,"I",sub,1)),"^",14)
		.i CurrEpisodeID'=EpisodeID s PrescNo="'其他科室"_PrescNo_"'"
		.s DoseQty=$P($G(^OEORD(OrderRowid,"I",sub,2)),"^",1)
		.s DoseQtyUOM=$P($G(^OEORD(OrderRowid,"I",sub,2)),"^",3)
		.s Freq=$P($G(^OEORD(OrderRowid,"I",sub,2)),"^",4)
		.i Freq'="" s FreqFac=$P($G(^PHCFR(Freq)),"^",2)
		.e  s FreqFac=1
		.s Instr=$P($G(^OEORD(OrderRowid,"I",sub,2)),"^",7)
		.i Instr'="" s InstrCode=$P($G(^PHCIN(Instr)),"^",1) 
		.e  s InstrCode=""
	 	.s DrgFrmRowid=##class(web.DHCDocOrderEntry).GetDrgForm(ItmID)
		.i DrgFrmRowid'="" d
		..s DrgCode=$p(^PHCD(+DrgFormRowid,1),"^",1)
		..s DrgDesc=$p(^PHCD(+DrgFormRowid,1),"^",2)
		..s drgform1=+DrgFormRowid
		..s drgform2=$p(DrgFormRowid,"||",2)
		..s leq=$o(^PHCD(drgform1,"DF",drgform2,"EQ",0))
		..i leq'="" d
		...s eqrec=^PHCD(drgform1,"DF",drgform2,"EQ",leq)
		...s eqUom=$p(eqrec,"^"),eqqty=$p(eqrec,"^",2)
		...i eqUom'=DoseQtyUOM s DoseQty=DoseQty*eqqty
		..s Para="<medicine suspension='false' judge='true'>"
		..s Para=Para_"<group_number>"_GroupNumber_"</group_number>"
		..s Para=Para_"<general_name>"_DrgDesc_"</general_name>"
		..s Para=Para_"<license_number>"_DrgCode_"</license_number>"
		..s Para=Para_"<medicine_name>"_DrgDesc_"</medicine_name>"
		..s Para=Para_"<single_dose coef='1'>"_DoseQty_"</single_dose>"
		..s Para=Para_"<times>"_FreqFac_"</times><days></days>"
		..s Para=Para_"<administer_drugs>"_Instr_"</administer_drugs>"
		..s Para=Para_"</medicine>"
	 	..i $d(^CacheTemp("DHCDTPresc",$J,PrescNo)) d
	 	...s ^CacheTemp("DHCDTPresc",$J,PrescNo)=^CacheTemp("DHCDTPresc",$J,PrescNo)_Para
	 	..e  d
	 	...s ^CacheTemp("DHCDTPresc",$J,PrescNo)=Para
 	}
 	s Presc=""
 	s PrescNo=0 f  s PrescNo=$O(^CacheTemp("DHCDTPresc",$J,PrescNo)) Q:PrescNo=""  d
 	.s Presc="<prescription id="_PrescNo_">"_^CacheTemp("DHCDTPresc",$J,PrescNo)_"</prescription>"_Presc
 	Q Presc
}

ClassMethod GetDrugCommonNameByArcimId(ArcimId As %String) As %String
{
	;w ##class(web.UDHCJFOther).GetDrugCommonNameByArcimId("1487||1")
	n (ArcimId)
	s HospitalCode=""
	s Hospital=..%GetConfig("CurrentHospital")
	i Hospital'="" s HospitalCode=$P(Hospital,"^",1)
	
	s DrugCommonName=""
	if HospitalCode="SDWFYY" {
		i ArcimId'="" d
		.s ItmCat=$p($g(^ARCIM($p(ArcimId,"||",1),$p(ArcimId,"||",2),1)),"^",10)
		.s OrdType=$p($g(^ARC("IC",ItmCat)),"^",7)	;ARCIC_OrderType
		.Q:OrdType'="R" 
		.s DrugCommonName =$p($g(^ARCIM($p(ArcimId,"||",1),$p(ArcimId,"||",2),8)),"^",21) ;ARCIM_GenericDesc 通用名 8 21
		.s DrugCommonName=$p(DrugCommonName,"-",2)
	}
	else
	{
		s DrugCommonName=##class(web.UDHCJFCOMMON).GetDrugCommonNameByArcimId(ArcimId)
	}
	Quit DrugCommonName
}

/// 取得医嘱对应设备排程信息
ClassMethod GetEQASInfo(OrderItemRowId As %String) As %String
{
	Q:'$d(^OEORD(+OrderItemRowId,"I",$P(OrderItemRowId,"||",2))) ""
	Q:'$d(^OEORD(+OrderItemRowId,"I",$P(OrderItemRowId,"||",2),"DHC")) ""
	s ASRowId=$P(^OEORD(+OrderItemRowId,"I",$P(OrderItemRowId,"||",2),"DHC"),"^",2)
	Q:ASRowId="" ""
	s obj=##class(User.RBApptSchedule).%OpenId(ASRowId)
	if $IsObject(obj) {
		set ASDate=obj.ASDate
		Set ASSessStartTime=obj.ASSessStartTime
		s SessionTimeName=""
		Set TRRowId=##class(web.DHCRBResSession).GetTimeRangeByTime(ASSessStartTime)
		if TRRowId'="" s TRDescd=$P(^DHCTimeRange(TRRowId),"^",2)
		s ASDateStr=$ZD(ASDate,3)
		Q ASDateStr_"^"_TRDescd
	}
	Q ""
}

ClassMethod GetLabSpec(OrderItemRowid As %String, HospitalId As %String = "") As %String
{
	
	s SpecStr=""
	s OrderRowid=$p(OrderItemRowid,"||",1)
	s Childsub=$p(OrderItemRowid,"||",2)
	if (HospitalId=""){
		s RecDr=$P($G(^OEORD(OrderRowid,"I",Childsub,3)),"^",6)
		s HospitalId=$P($G(^CTLOC(+RecDr)),"^",22)
	}
	s HospitalCode=##class(web.DHCDocOrderCommon).GetCurrentSYSHospitalCode(HospitalId)
	s spec=0 for  s spec=$o(^OEORD(OrderRowid,"I",Childsub,"SPEC",spec)) QUIT:spec=""  do
	. s SpecCode=$P($g(^OEORD(OrderRowid,"I",Childsub,"SPEC",spec)),"^",1)
	. i $d(^DHCLISBSVersion(1)) d
	.. s SpecDesc=$p(##Class(DHCLIS.DHCCommon).GetSpecimen(SpecCode,$g(HospitalCode)),$c(2),2) 
	. e  d
	.. s SpecDesc=$p($G(^TTAB("SPEC",SpecCode)),"\",1)
	. i SpecStr="" s SpecStr=SpecDesc
	. e  s SpecStr=SpecStr+","+SpecDesc
	Q SpecStr
}

/// w ##Class(web.DHCOEOrdItem).GetLabContainer("2185||30",10)
ClassMethod GetLabContainer(OrderItemRowid As %String, HospitalId As %String = "") As %String
{
	s ContainerStr=""
	s OrderRowid=$p(OrderItemRowid,"||",1)
	s Childsub=$p(OrderItemRowid,"||",2)
	if (HospitalId=""){
		s RecDr=$P($G(^OEORD(OrderRowid,"I",Childsub,3)),"^",6)
		s HospitalId=$P($G(^CTLOC(RecDr)),"^",22)
	}
	s HospitalCode=##class(web.DHCDocOrderCommon).GetCurrentSYSHospitalCode(HospitalId)
	s spec=0 for  s spec=$o(^OEORD(OrderRowid,"I",Childsub,"SPEC",spec)) QUIT:spec=""  do
	. s Container=$p(^OEORD(OrderRowid,"I",Childsub,"SPEC",spec),"^",11)
	. i $d(^DHCLISBSVersion(1)) d
	.. s ContainerDesc=$p(##Class(DHCLIS.DHCCommon).GetContainer(Container,$g(HospitalCode)),$c(2),3) 
	. e  d
	.. s ContainerDesc=""
	. i ContainerStr="" s ContainerStr=ContainerDesc
	. e  s ContainerStr=ContainerStr+","+ContainerDesc
	Q ContainerStr
}

ClassMethod GetOrderItemsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = GetOrderItemsExecute ]
{
 Set repid=$LIST(qHandle,2)
 Kill ^CacheTemp(repid)
 Quit $$$OK
}

ClassMethod GetOrderItemsExecute(ByRef qHandle As %Binary, EpisodeID As %String, IsPhamacy As %String) As %Status
{
 s Hospital=..%GetConfig("CurrentHospital")
 i Hospital'="" s HospitalCode=$P(Hospital,"^",1)
 e  s HospitalCode=""

 Set repid=$I(^CacheTemp)
 If $g(ind)="" Set ind=1
 s PatType="", InsType="", PriorRowid="", InstrRowid="", LinkTo="", OEPrice="",LabEpisodeNo=""
 set RowCount=0
 s OrderType="L"
 s IsPhamacy=0
 ;if IsPhamDepProcNotesacy="1" s OrderType="R"
 i EpisodeID'="" d
 .s PatType=$P(^PAADM(EpisodeID,1),"^",6)  //PAADM_Epissubtype_DR
 .&sql(DECLARE EmpCursor CURSOR FOR
 SELECT OEORI_Rowid,OEORI_ItmMast_DR,OEORI_ItmMast_DR->ARCIM_Desc,Todate(OEORI_SttDat,'yyyy-mm-dd'),
	    OEORI_Priority_dr->OECPR_Desc,OEORI_Itemstat_dr->OSTAT_Desc,OEORI_Itemstat_dr->OSTAT_Code,
	    OEORI_QtyPackUOM,
	    OEORI_RecDep_DR->CTLOC_Desc,$LIST(OEORI_RecDep_DR->ctloc_address,1),OEORI_Billed,OEORI_ItmMast_DR,OEORI_SttDat,
	    OEORI_BBExtCode,OEORI_ItmMast_DR->ARCIM_ItemCat_DR->ARCIC_OrderType,
	    OEORI_UserAdd->SSUSR_Name,OEORI_LabEpisodeNo,OEORI_DepProcNotes,
	    OEORI_RecDep_DR
 INTO :Rowid,:ArcimRowid,:OrderName,:StartDate,:Priority,:Status,:StatusCode,:PackQty,:RecDep,:RecDepAdress,:Billed,:ARCIMRowid,:SttDate,:BillType,:OrderType,:UserAddName,:LabEpisodeNo,:DepProcNotes,:RecDepRowId
 From SQLUser.OE_OrdItem 
 WHERE OEORI_OEORD_PARREF->OEORD_ADM_DR=:EpisodeID and (OEORI_ItemStat_DR->OSTAT_Code='V' or OEORI_ItemStat_DR->OSTAT_Code='E')
	 and ((OEORI_ItmMast_DR->ARCIM_ItemCat_DR->ARCIC_OrderType='R' and :IsPhamacy=1) or (OEORI_ItmMast_DR->ARCIM_ItemCat_DR->ARCIC_OrderType<>'R' and :IsPhamacy<>1))
 Order By OEORI_ItmMast_DR->ARCIM_ItemCat_DR->ARCIC_OrdCat_DR desc)
 .&sql(OPEN EmpCursor)
 .for  &SQL(FETCH EmpCursor) QUIT:SQLCODE  do
	..s subcat=$p($g(^ARCIM(+ARCIMRowid,1,1)),"^",10)
	..s orcat=$p($g(^ARC("IC",+subcat)),"^",8)
	..s orcatdesc=""
	..Q:((orcat'=25)&(orcat'=26)&(orcat'=27)&(orcat'=28)&(orcat'=29)&(orcat'=30)&(orcat'=31)&(orcat'=32)&(orcat'=24)&(orcat'=41)&(HospitalCode="HF"))
	..Q:(OrderType'="L")&((HospitalCode="YKYZLYY")||(HospitalCode="JST")||(HospitalCode="BJZYY"))
	..;s RecDepAdress=$List($g(RecDepAdress))   ;lgl
	..i DepProcNotes'="" s DepProcNotes=$List($G(DepProcNotes))
	..i orcat'="" s orcatdesc=$p($g(^OEC("ORCAT",orcat)),"^",2)
	..q:(orcatdesc="消耗材料")
	..q:((orcatdesc="消耗材料")||(orcatdesc="其他")||(orcatdesc="申请"))&&(HospitalCode="YKYZLYY")
	..s RecDepDesc=$p(RecDep,"-",2)
	..i RecDepDesc'="" s RecDep=RecDepDesc
	..;s retPrice=##class(web.DHCDocOrderEntry).GetOrderPrice(PatType, InsType, ARCIMRowid, SttDate, PriorRowid, InstrRowid, LinkTo, OEPrice)
	..s retPrice=##class(web.DHCDocOrderCommon).GetOrderPrice(PatType, InsType, ARCIMRowid, SttDate, PriorRowid, InstrRowid, LinkTo, OEPrice,RecDepRowId)
	..s Price=$P(retPrice,"^",1)
	..s DiscPrice=$P(retPrice,"^",2)
	..s InsPrice=$P(retPrice,"^",3)
	..s PatPrice=$P(retPrice,"^",4)
	..s Sum=PackQty*Price
	..i BillType="" s BillTypeDesc="自费"
	..e  s BillTypeDesc=$P(^PAC("ADMREA",BillType),"^",2)
	..s DoseqtySum=$p($g(^OEORD(+Rowid,"I",$p(Rowid,"||",2),1)),"^",12)
	..s PackQty=DoseqtySum
	..s PackUOMRowid=##Class(web.DHCDocOrderCommon).GetOrdPackUOMDR(Rowid)
	..s PackUOM=##class(web.DHCDocOrderCommon).GetUOMDesc(PackUOMRowid)
	
	..s PackUOM=$p(PackUOM,"(",1)
	..s Sum=PackQty*Price
	..s Spec=..GetLabSpec(Rowid)
	..s Spec=$p($g(Spec),"-",1)
	..;s ExecuteTime=$G(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),"RB",1))
	..s ExecuteTime=$P(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),9),"^",14)
	..do OutputRow4
	.&sql(CLOSE EmpCursor)
 Set qHandle=$lb(0,repid,0)
 Quit $$$OK
OutputRow4
 set Data=$lb(Rowid,OrderName,StartDate,Priority,Status,PackQty,PackUOM,Price,Sum,RecDep,Billed,BillTypeDesc,OrderType,Spec,UserAddName,LabEpisodeNo,orcat,orcatdesc,RecDepAdress,DepProcNotes,StatusCode,ExecuteTime,DIACat)
 Set ^CacheTemp(repid,ind)=Data
 Set ind=ind+1
 quit
ResetVariables4
	set (Rowid,OrderName,StartDate,Priority,Status,PackQty,PackUOM,Price,Sum,RecDep,Billed,BillTypeDesc,OrderType,Spec,UserAddName,LabEpisodeNo,orcat,orcatdesc,RecDepAdress,DepProcNotes,StatusCode,ExecuteTime,DIACat)=""
	quit
}

ClassMethod GetOrderItemsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = GetOrderItemsExecute ]
{
	Set AtEnd=$LIST(qHandle,1)
	Set repid=$LIST(qHandle,2)
	Set ind=$LIST(qHandle,3)
	//
	Set ind=$o(^CacheTemp(repid,ind))
	If ind="" {				// if there are no more rows, finish fetching
	Set AtEnd=1
	Set Row=""
	}
	Else      {				// fetch row
	Set Row=^CacheTemp(repid,ind)
	}
	// Save QHandle
	s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

ClassMethod GetPrescItemCount(EpisodeID As %String, PrescNo As %String) As %Integer
{
 &SQL(Select Count(*) Into :OrderItemCount From SQLUser.OE_OrdItem 
	 WHERE OEORI_PrescNo=:PrescNo and OEORI_OEORD_PARREF->OEORD_ADM_DR=:EpisodeID and OEORI_ItemStat_DR->OSTAT_Code='V' and OEORI_ItmMast_DR->ARCIM_ItemCat_DR->ARCIC_OrderType='R')
 Quit OrderItemCount
}

ClassMethod GetPrescItemsBroker(itmjs As %Library.String = "", EpisodeID As %String, PrescNo As %String) As %Library.String
{
	;Rowid:OrderName:,StartDate:SeqNo:DoseQty:DoseUOM:Priority:Status:Frequence:Instruction:Duration:PackQty:RecDep:Billed")
	Set rset=##class(%ResultSet).%New("web.DHCOEOrdItem:GetPrescItems")
	do rset.Execute(EpisodeID,PrescNo)
	Set columns = rset.GetColumnCount()
	While (rset.Next()) {
		For col = 1:1:columns {
			;Write rset.GetColumnName(col),":"
			if col=1 set value=rset.GetData(col)
			e  s value=value_"^"_rset.GetData(col)
		}
		s retval=itmjs_"('"_$ZCVT(value,"O","JS")_"');"
		&javascript<#(retval)#>
	}
	d rset.Close()
	Q 1
}

ClassMethod GetPrescItemsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = GetPrescItemsExecute ]
{
 Set repid=$LIST(qHandle,2)
 Kill ^CacheTemp(repid)
 Quit $$$OK
}

/// d ##class(%ResultSet).RunQuery("web.DHCOEOrdItem","GetPrescItems","20100227","328")
ClassMethod GetPrescItemsExecute(ByRef qHandle As %Binary, EpisodeID As %String, PrescNo As %String) As %Status
{
	Set repid=$I(^CacheTemp)
	If $g(ind)="" Set ind=1
	set PatType="", InsType="", PriorRowid="", InstrRowid="", LinkTo="", OEPrice=""
	set RowCount=0
	s Hospital=..%GetConfig("CurrentHospital")
	i Hospital'="" s HospitalCode=$P(Hospital,"^",1)
	e  s HospitalCode=""
 k ^CacheTemp("DHCPrescOrdItem",$j,"master")
 do CheckRowCount
 if RowCount>0 d
 .s PatType=$P(^PAADM(EpisodeID,1),"^",6)  //PAADM_Epissubtype_DR
 .&sql(DECLARE CNMedCursor CURSOR FOR
 SELECT OEORI_Rowid,OEORI_ItmMast_DR->ARCIM_Desc,Todate(OEORI_SttDat,'dd/mm/yyyy'),OEORI_SeqNo,
 OEORI_DoseQty,OEORI_UNIT_DR->CTUOM_Desc,
	       OEORI_Priority_dr->OECPR_Desc,OEORI_Itemstat_dr->OSTAT_Desc,oeori_PHFreq_dr->PHCFR_Desc1,
	       OEORI_instr_dr->PHCIN_Desc1,OEORI_Durat_dr->PHCDU_Desc1,
	       OEORI_QtyPackUOM,
	       OEORI_RecDep_DR->CTLOC_Desc,OEORI_Billed,OEORI_ItmMast_DR,OEORI_SttDat,OEORI_BBExtCode,
	       OEORI_UserAdd->SSUSR_Initials,OEORI_UserAdd->SSUSR_Name,
	       OEORI_ItmMast_DR->ARCIM_ItemCat_DR,OEORI_OEORI_DR,OEORI_Action_DR->ACT_Desc,
	       OEORI_RecDep_DR
	  INTO :Rowid,:OrderName,:StartDate,:SeqNo,:DoseQty,:DoseUOM,:Priority,:Status,:Frequence,
	       :Instruction,:Duration,:PackQty,:RecDep,:Billed,:ARCIMRowid,:SttDate,
	       :BillType,:UserAddCode,:UserAddName,:ItemCat,:LinkOrderItem,:Action,
	       :RecDepRowId
	  From SQLUser.OE_OrdItem 
	 WHERE OEORI_PrescNo=:PrescNo and OEORI_OEORD_PARREF->OEORD_ADM_DR=:EpisodeID and 
	       OEORI_ItemStat_DR->OSTAT_Code='V' and OEORI_ItmMast_DR->ARCIM_ItemCat_DR->ARCIC_OrderType='R')
	.&sql(OPEN CNMedCursor)
	.for  &SQL(FETCH CNMedCursor) QUIT:SQLCODE  do
	..;s retPrice=##class(web.DHCDocOrderEntry).GetOrderPrice(PatType, InsType, ARCIMRowid, SttDate, PriorRowid, InstrRowid, LinkTo, OEPrice)
	..s retPrice=##class(web.DHCDocOrderCommon).GetOrderPrice(PatType, InsType, ARCIMRowid, SttDate, PriorRowid, InstrRowid, LinkTo, OEPrice,RecDepRowId)
	..;w Action,!
	..s Price=$P(retPrice,"^",1)
	..s DiscPrice=$P(retPrice,"^",2)
	..s InsPrice=$P(retPrice,"^",3)
	..s PatPrice=$P(retPrice,"^",4)
	..s Sum=PackQty*Price
	..i BillType="" s BillTypeDesc="自费"
	..e  s BillTypeDesc=$P(^PAC("ADMREA",BillType),"^",2)
	..;
	..;在药学项上记录了该药品属于哪类
	..s DrgFormRowid=##class(web.DHCDocOrderEntry).GetDrgForm(ARCIMRowid)
	..s OfficialCode=""
	..s BillClassDesc=""
	..i DrgFormRowid'="" d
	...s DrgMastRowid=$p(DrgFormRowid,"||",1)
	...s OfficialCode=$p($g(^PHCD(DrgMastRowid,4)),"^",2)
	..i OfficialCode=1 s BillClassDesc="甲类"
	..i OfficialCode=2 s BillClassDesc="乙类"
	..i OfficialCode=3 s BillClassDesc="丙类"
	..s PoisonRowid=##class(web.DHCDocOrderEntry).GetDrgFormPoison(ARCIMRowid)
	..i PoisonRowid'="" d
	...s PoisonClass=$p($g(^PHCPO(PoisonRowid)),"^",2)
	...s PoisonClass=$tr(PoisonClass,$c(13,10),"")
	...i PoisonClass="二类精神" s PoisonClass="精二"
	...i PoisonClass="一类精神" s PoisonClass="精一"
	...i (PoisonClass="毒麻药")||(PoisonClass="麻醉药品") s PoisonClass="麻"
	...;e  s PoisonClass=""
	..e  s PoisonClass=""
	..s PackUOMRowid=##Class(web.DHCDocOrderCommon).GetOrdPackUOMDR(Rowid)
	..s PackUOM=##class(web.DHCDocOrderCommon).GetUOMDesc(PackUOMRowid)
	..s PackUOM=$p(PackUOM,"(",1)
	..i (DoseQty'="")&(DoseQty<1) s DoseQty="0"_$number(DoseQty)
	..;
	..s GenericName=..GetDrugCommonNameByArcimId(ARCIMRowid)
	..i GenericName'="" d
	...s OrderName=GenericName
	...//s ARCIMSub=$p(ARCIMRowid,"||",1)
	...//s InciRowid=##class(web.DHCDocOrderEntry).GetINCI(ARCIMSub)
	...//i InciRowid'="" s Spec=$P($g(^INCI(InciRowid,3)),"^",9)
	...//i Spec'="" s Spec="("_Spec_")"
	...//s OrderName=GenericName_Spec
	...i HospitalCode="SDWFYY" s OrderName=GenericName_"["_$p(OrderName,"[",2)
	..;
	..s Data1=$lb(Rowid,OrderName,StartDate,SeqNo,DoseQty,DoseUOM,Priority,Status,Frequence,Instruction,Duration,PackQty,PackUOM,Price,Sum,RecDep,Billed,BillTypeDesc,BillClassDesc,UserAddCode,UserAddName,PoisonClass,ItemCat,Action)
	..i LinkOrderItem="" s ^CacheTemp("DHCPrescOrdItem",$j,"master",Rowid)=Data1
	..e  d
	...if '$D(^CacheTemp("DHCPrescOrdItem",$j,"master",LinkOrderItem)) d
	....s ^CacheTemp("DHCPrescOrdItem",$j,"master",LinkOrderItem)=""
	...s ^CacheTemp("DHCPrescOrdItem",$j,"master",LinkOrderItem,"sub",Rowid)=Data1
	..;
	..;do OutputRow2
	.&sql(CLOSE CNMedCursor)
	s SeqNo=0
	s mas=0 for  s mas=$O(^CacheTemp("DHCPrescOrdItem",$j,"master",mas)) q:mas=""  d
	. s s1=^CacheTemp("DHCPrescOrdItem",$j,"master",mas)
	. i s1'="" d 
	. .s SeqNo=SeqNo+1
	. .s $List(s1,4)=SeqNo
	. .s Data=s1
	. .d OutputRow2
	. s SubSeqCount=0
	. s sub=0  for  s sub=$O(^CacheTemp("DHCPrescOrdItem",$j,"master",mas,"sub",sub)) q:sub=""  d
	. . s s2=^CacheTemp("DHCPrescOrdItem",$j,"master",mas,"sub",sub)
	. . i s1="" d
	. . . s SeqNo= SeqNo+1
	. . . s $List(s2,4)=SeqNo
	. . . s Data=s2
	. . . d OutputRow2
	. . e  d
	. . . s SubSeqCount=SubSeqCount+1
	. . . s SubSeqNo=SeqNo_"."_SubSeqCount
	. . . s $List(s2,4)=SubSeqNo
	. . . s Data=s2
	. . . d OutputRow2
	k ^CacheTemp("DHCPrescOrdItem",$j,"master")
 else  Do
 .do ResetVariables2
 .set Data=$lb(Rowid,OrderName,StartDate,SeqNo,DoseQty,DoseUOM,Priority,Status,Frequence,Instruction,Duration,PackQty,PackUOM,Price,Sum,RecDep,Billed,BillTypeDesc,BillClassDesc,UserAddCode,UserAddName,PoisonClass,ItemCat,Action)
 .Do OutputRow2 	
 Set qHandle=$lb(0,repid,0)
	Quit $$$OK
OutputRow2
	;set Data=$lb(Rowid,OrderName,StartDate,SeqNo,DoseQty,DoseUOM,Priority,Status,Frequence,Instruction,Duration,PackQty,PackUOM,Price,Sum,RecDep,Billed,BillTypeDesc,BillClassDesc,UserAddCode,UserAddName,PoisonClass,ItemCat)
 Set ^CacheTemp(repid,ind)=Data
 Set ind=ind+1
	Quit
ResetVariables2
	set (Rowid,OrderName,StartDate,SeqNo,DoseQty,DoseUOM,Priority,Status,Frequence,Instruction,Duration,PackQty,PackUOM,Price,Sum,RecDep,Billed,BillTypeDesc,BillClassDesc,UserAddCode,UserAddName,PoisonClass,ItemCat,Action)=""
	quit
CheckRowCount
 if PrescNo="" s RowCount=0
 else  d
 .&sql(SELECT Count(*) INTO :RowCount From SQLUser.OE_OrdItem 
	 WHERE OEORI_PrescNo=:PrescNo and OEORI_OEORD_PARREF->OEORD_ADM_DR=:EpisodeID)
	quit
}

ClassMethod GetPrescItemsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = GetPrescItemsExecute ]
{
 Set AtEnd=$LIST(qHandle,1)
 Set repid=$LIST(qHandle,2)
 Set ind=$LIST(qHandle,3)
	//
 Set ind=$o(^CacheTemp(repid,ind))
 If ind="" {				// if there are no more rows, finish fetching
 Set AtEnd=1
 Set Row=""
 }
 Else      {				// fetch row
 Set Row=^CacheTemp(repid,ind)
 }
 // Save QHandle
 s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

ClassMethod GetPrescListBroker(itmjs As %Library.String = "", EpisodeID As %String) As %String
{
	 Set rset=##class(%ResultSet).%New("web.DHCOEOrdItem:GetPrescriptions")
	 do rset.Execute(EpisodeID)
	 While (rset.Next()) {
		s PrescNo=rset.Data("PrescNo")
		s RecDep=rset.Data("RecDep")
		s PrescDate=rset.Data("PrescDate")
		s PrescTypeDesc=rset.Data("PrescTypeDesc")
		s Desc=PrescNo_"   "_PrescDate_"   "_RecDep_"   "_PrescTypeDesc
		;w Desc,!
		s retval=itmjs_"('"_$ZCVT(Desc,"O","JS")_"','"_$ZCVT(PrescNo,"O","JS")_"');"
		&javascript<#(retval)#>
	 }
	 d rset.Close()
	 q 0
}

ClassMethod GetPrescriptionsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = GetPrescriptionsExecute ]
{
 Set repid=$LIST(qHandle,2)
 Kill ^CacheTemp(repid)
 Quit $$$OK
}

ClassMethod GetPrescriptionsExecute(ByRef qHandle As %Binary, EpisodeID As %String) As %Status
{
 ;SELECT QUE1_PrescNo,to_Date(QUE1_TransDate,'YYYY-MM-DD'),cast(QUE1_TransTime AS TIMESTAMP),QUE1_DepartmentLoc_DR->CTLOC_Desc
	  ;from SQLUser.PA_Que1 
	 ;Where QUE1_PAADM_DR=:EpisodeID 
	 ;Order By QUE1_PrescNo)
 Set repid=$I(^CacheTemp)
 If $g(ind)="" Set ind=1
 s PrescNo="", TransDate="", TransTime="", RecLoc=""
 &sql(DECLARE EmpCur2 CURSOR FOR
 SELECT distinct OEORI_PrescNo,to_Date(OEORI_Date,'YYYY-MM-DD'),cast(OEORI_Time AS TIMESTAMP),OEORI_RecDep_DR->CTLOC_Desc
	  INTO :PrescNo,:TransDate,:TransTime,:RecLoc
	  from SQLUser.OE_OrdItem 
	 Where OEORI_OEORD_Parref->OEORD_ADM_DR=:EpisodeID and OEORI_PrescNo<>""
	  Order By OEORI_PrescNo)
 &sql(OPEN EmpCur2)
 for  &SQL(FETCH EmpCur2) QUIT:SQLCODE  do
 .s Count=..GetPrescItemCount(EpisodeID,PrescNo)
 .i (Count>0) Do
 ..s OrderRowid=$o(^OEORD(0,"Adm",+EpisodeID,""))
 ..s itemsub=$O(^OEORD(0,"PrescNo",PrescNo,OrderRowid,0))
 ..s ArcimRowid=$p(^OEORD(OrderRowid,"I",itemsub,1),"^",2)
 ..s SttDate=$p(^OEORD(OrderRowid,"I",itemsub,1),"^",9)
 ..s TransDate=$zd(SttDate,3)
 ..i ArcimRowid'="" s ItemCatDR=$p(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),1),"^",10)
 ..s PatientID=$P(^PAADM(EpisodeID),"^",1)
 ..s PatientDOB=$P($G(^PAPER(PatientID,"ALL")),"^",6)
 ..;
 ..;1:普通  2:毒麻  3:精二  4:小儿
 ..s PrescType="",PrescTypeDesc=""
 ..i PatientDOB'="" d
 ...i (((+$H)-PatientDOB)/365.25)<15 s PrescType=4
 ..i PrescType="" d
 ...s PoisonRowid=##class(web.DHCDocOrderEntry).GetDrgFormPoison(ArcimRowid)
 ...i PoisonRowid'="" d
 ....s PoisonCode=$p($g(^PHCPO(PoisonRowid)),"^",1)
 ....i PoisonCode="J1" s PrescType=2
 ....i PoisonCode="DX" s PrescType=2
 ....i PoisonCode="MZ" s PrescType=2
 ....i PoisonCode="J2" s PrescType=3
 ..i PrescType="" s PrescType=1
 ..i PrescType=1 s PrescTypeDesc="普通"
 ..i PrescType=2 s PrescTypeDesc="麻精一"
 ..i PrescType=3 s PrescTypeDesc="精二"
 ..i PrescType=4 s PrescTypeDesc="小儿"
 ..;
 ..i ItemCatDR'="" s ItemCatDR="^"_ItemCatDR_"^"
 ..s CNMedItemCat=##Class(web.DHCDocOrderCommon).GetCNMedItemCatStr()
 ..i CNMedItemCat'="" s CNMedItemCat="^"_CNMedItemCat_"^"
 ..i (ItemCatDR="")!(CNMedItemCat="") d OutputRow
 ..e  d
 ...i CNMedItemCat'[ItemCatDR d OutputRow	
 &sql(CLOSE EmpCur2)
 Set qHandle=$lb(0,repid,0)
	Quit $$$OK
OutputRow
	set Data=$lb(PrescNo,TransDate,TransTime,RecLoc,PrescType,PrescTypeDesc)
 Set ^CacheTemp(repid,ind)=Data
 Set ind=ind+1
	Quit
ResetVariables
	set Data=$lb(PrescNo,TransDate,TransTime,RecLoc)
	quit
}

ClassMethod GetPrescriptionsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = GetPrescriptionsExecute ]
{
 Set AtEnd=$LIST(qHandle,1)
 Set repid=$LIST(qHandle,2)
 Set ind=$LIST(qHandle,3)
	//
 Set ind=$o(^CacheTemp(repid,ind))
 If ind="" {				// if there are no more rows, finish fetching
 Set AtEnd=1
 Set Row=""
 }
 Else      {				// fetch row
 Set Row=^CacheTemp(repid,ind)
 }
 // Save QHandle
 s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

ClassMethod DischargeOrd(Adm As %String, DischargeConditionRowId As %String, OrderStr As %String, UserID As %String, DeceasedDateTimeStr As %String = "", DischargeMethodID As %String = "") As %String
{
	n (Adm,DischargeConditionRowId,OrderStr,UserID,DeceasedDateTimeStr,DischargeMethodID,%session)
	;返回标志位^错误描述 	标识位:0 处理成功或无需处理,1 处理失败
	s ret=0,ErrMsg=""
	s HospID=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(Adm)
	//Q:DischargeConditionRowId="" 0_"^"_ErrMsg
	;找出院/死亡医嘱id
	s DischargeOEORI=$$GetDischargeOEORI(OrderStr)
	i DischargeOEORI'="" {
		s Index=$I(^tmpgry("DischargeOrd",Adm))
		s ^tmpgry("DischargeOrd",Adm,+$h,Index,1)=Adm_","_DischargeConditionRowId_","_OrderStr_","_UserID
		i IsDeathFlag'="" {
			s PacDiaChangeRowid=0
			f  s PacDiaChangeRowid=$o(^PAC("DISCON",PacDiaChangeRowid)) q:(PacDiaChangeRowid="")||(DischargeConditionRowId'="")  d
			.s DISCONDeadFlag=$p(^PAC("DISCON",PacDiaChangeRowid),"^",3)
			.q:DISCONDeadFlag'="D"
			.s DischargeConditionRowId=PacDiaChangeRowid
		}
		s DeceasedDate="",DeceasedTime=""
		if (DeceasedDateTimeStr'=""){
			s DeceasedDate=$p(DeceasedDateTimeStr,"!",1)
			s DeceasedTime=$p(DeceasedDateTimeStr,"!",2)
		}
		s ret=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.doc.doctorDischarge",Adm, DischargeOEORI, UserID, DischargeConditionRowId,DeceasedDate,DeceasedTime,DischargeMethodID)
		i ret'=0 {
			s ErrMsg=ret
			s ret="-1"
		}
		if (ret=0){
			//调用护理组接口释放相应床位
			s ArcimID=$p(^OEORD(+DischargeOEORI,"I",$p(DischargeOEORI,"||",2),1),"^",2)
			d ##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.doc.orderReleaseBed",Adm, UserID, ArcimID)
			//如果患者当日入院，当日出院，需加收一天的床位费
			s AdmBedInfo=##Class(EMRservice.DAL.GetPaAdmDetail).AdmDateTimeInBed(Adm)
			if (AdmBedInfo'=""){
				s AdmBedDate=$p(AdmBedInfo,",",1)
				s EstimDischargeDate=$P(^PAADM(Adm),"^",59)
				s EstimDischargeTime=$P(^PAADM(Adm),"^",60)
				s AdmLoc=$p(^PAADM(Adm),"^",4)
 				s AdmHospDr=$p($g(^CTLOC(AdmLoc)),"^",22)
				if (EstimDischargeDate=AdmBedDate){
					s ward=$P(^PAADM(Adm),"^",70)
					d CalculateAdmFee^CHBB1NEW(Adm,+$H,ward,"Y",EstimDischargeTime,AdmHospDr)
				}
			}
		}
	}
	
	Q ret_"^"_ErrMsg
GetDischargeOEORI(OrdItemStr)	
	s DischargeOEORI="",IsDeathFlag=""
	f k=1:1:$l(OrdItemStr,"^")-1 {
		s newArcimIdDR=$p($p(OrdItemStr,"^",k),"*",1)
		s newOrdIdDR=$p($p(OrdItemStr,"^",k),"*",2)
		Q:(newOrdIdDR="")||(newArcimIdDR="")
		s DischargeOrdFlag=##class(web.DHCDocOrderEntry).IsDischargeOrd(newArcimIdDR,HospID)
		if (DischargeOrdFlag'=0){
			s DischargeOEORI=newOrdIdDR
			if (DischargeOrdFlag=2){
				s IsDeathFlag=1
			}
			quit
		}
		
	}
	Q DischargeOEORI
}

ClassMethod InsertAdmSheets(Adm As %String, OrdItemStr As %String, User As %String, Loc As %String)
{
	
	Ts
	Set object = ##class(User.DHCPAAdmSheets).%New()
	Do object.PAADMSAdmDrSetObjectId(Adm)
	set object.PAADMSType="HLD"
	set object.PAADMSDate=..%SysDate()
	set object.PAADMSTime=..%SysDate()
	Do object.PAADMSUserDrSetObjectId(User)
	Do object.PAADMSDepDrSetObjectId(Loc)
	s sc= object.%Save()
	If $$$ISERR(sc) {
		Do $System.Status.DisplayError()
		Trollback
		Quit 100
	}
	s ASRowId=object.%Id()
	d object.%Close()
	s err=0
	f k=1:1:$l(OrdItemStr,"^")-1 {
		s newOrdIdDR=$p($p(OrdItemStr,"^",k),"*",2)
		Q:newOrdIdDR=""
		Set object=##class(User.DHCPAAdmSheetsItem).%New(ASRowId)
		Do object.SISheetParRefSetObjectId(ASRowId)
		Do object.SIOEORIDRSetObjectId(newOrdIdDR)
		
		s sc=object.%Save()
		If $$$ISERR(sc) {
			Do $System.Status.DisplayError()
			Trollback
			s err=100
		}
		d object.%Close()
		Q:err=100
	}
	Q:err=100 100
	TC
	Q 0
}

ClassMethod InsertOrderItem(Adm As %String, OrdItemStr As %String, User As %String, Loc As %String, Doc As %String, ExpStr As %String = "", ByRef ErrMsg As %String = "", SessionStr As %String = "") As %Status
{
	s ^Temp("wanghc","InsertOrderItem")=$LB(Adm, OrdItemStr, User, Loc, Doc, ExpStr,  ErrMsg , SessionStr)
	Q:(Adm="")||(OrdItemStr="")||(User="")||(Loc="") 0
	;是否在插入医嘱之前调用审查方法,如果在插入医嘱之前未调用CheckBeforeSave,需传入此参数(例如以此方法作为接口调用)
	s IsCheckOrdItemStr=$p(ExpStr,"^",4)
	s PilotPRowId=$p(ExpStr,"^",5)
	s LogonDep=$p(ExpStr,"^",6)
	s OrderOpenForAllHosp=$p(ExpStr,"^",7)
	s AutoVirtualLongInsertFlag=$p(ExpStr,"^",8)	;虚拟长期自动生成标志
	s NotAdmTypeLimit=$p(ExpStr,"^",9)	;是否判断访问类型限制
	s NotBindLabFee=$p(ExpStr,"^",10)	;不绑定检验收费方案内容标志(Y|N)
	s orderrow=##Class(web.DHCDocOrderEntry).GetPAADMOrderRowid(Adm)
	s Warning=##class(web.DHCDocOrderCommon).OrderLock(orderrow, SessionStr, "User.OEOrder", "")
	s:Warning="" Warning=##Class(web.DHCDocViewDataInit).GetOrdEntryBaseWarning(Adm,SessionStr)
	if Warning'="" {
		s ErrMsg="-100"_$C(1)_Warning
		s Ret=100 QUIT Ret
	}
	if IsCheckOrdItemStr="Y" {
		s CheckExpStr=PilotPRowId_"^"_LogonDep_"^"_OrderOpenForAllHosp_"^"_NotAdmTypeLimit
		s DisplayTypeFlag=""
		s OutPutDataJson=..CheckBeforeSave(Adm,OrdItemStr,User,Loc,Doc,CheckExpStr,DisplayTypeFlag)
		d ##class(DHCDoc.Util.FromJSON).FromJSONToArr(OutPutDataJson,.OutPutDataArr)
		if $d(OutPutDataArr) {
			s ErrCode=OutPutDataArr("ErrCode")
			s ErrMsg=ErrCode_$C(1)_OutPutDataArr("ErrMsg")
			i +ErrCode'=0 s Ret=100 QUIT Ret
		}
	}
	
	Set Config=##Class(websys.Configuration).%OpenId(1)
	Set MEDDATA=Config.DataNamespace
	Set LABDATA=Config.LabDataNamespace
	s PAADMType=$p($g(^PAADM(Adm)),"^",2)
	if PAADMType="I" {
		Set Ret=$$InsertMultiple^DHCDocOrderCommonNew(Adm,OrdItemStr,User,Loc,Doc,LABDATA)
	}else{
		Set Ret=$$InsertMultiple^DHCDocOrderCommon(Adm,OrdItemStr,User,Loc,Doc,LABDATA)
	}
	
	If (Ret=0)||(Ret=100){
		d ##class(web.DHCDocOrderCommon).OrderEntryClearLock(SessionStr,"User.OEOrder")		//与orderLock对应
		s ErrMsg=Ret_$C(1)_"保存医嘱失败!"
		QUIT Ret
	}
	
	s StopConflictFlag=$p(ExpStr,"^",1)
	s DischargeConditionStr=$p(ExpStr,"^",2)
	s DischargeConditionRowId=$P(DischargeConditionStr,"!",1)
	s DischargeMethodID=$P(DischargeConditionStr,"!",2)
	s DeceasedDateTimeStr=$p(ExpStr,"^",3)
	s AdmDepHospId=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(Adm)
	;【医嘱项扩展设置】-长期自备药需要插入临时取药医嘱
	d ##Class(web.DHCOEOrdItem).AutoInsertOneOrdByOMST(Adm,.Ret)
	
	if StopConflictFlag="1" do ..StopConflict(Adm,Ret,User,Loc)
	d ..StopLongOrder(Adm,Ret,User,Loc)
	;化疗医嘱处理
	d ##class(DHCDoc.Chemo.BS.Order).Exec(Adm,Ret,User,Loc)
	;治疗医嘱自动生成申请单
	d ##class(DHCDoc.DHCDocCure.Service).SaveDHCDocCureApply(Adm,Ret,User)
	;出院/死亡医嘱处理
	d ..DischargeOrd(Adm,DischargeConditionRowId,Ret,User,DeceasedDateTimeStr,DischargeMethodID)
	//计费套餐管理
	d ..IDeductOrder(Ret,User,Doc,Loc)
	//计费帐单
	d ..InvokeBill(Adm,User,Ret)
	;非住院虚拟长期医嘱存储
	if (AutoVirtualLongInsertFlag'="Y") {
	Do ##class(web.DHCDocOrderVirtualLong).InsertVirtualtLong(Adm,.Ret,User,Loc)
	}
	;药理实验项目是否直接计费
	//s CFEntryOrdBillPad=##class(web.PilotProject.DHCDocPPGroupSeting).GetConfigNode("EntryOrdBillPad")
	//if CFEntryOrdBillPad=1 s UpdatePilotProOEItem=..UpdatePilotProOEItem(Ret,Adm,User)
	
	s UpdatePilotProOEItem=..UpdatePilotProOEItem(Ret,Adm,User,Loc)
	s NeedCreateAdmSheets=..NeedCreateAdmSheets(Ret)
	i NeedCreateAdmSheets=1 d ..InsertAdmSheets(Adm,Ret,User,Loc)
	d ..UpdateOrderStatus(Ret,Adm,User,Loc)
	;下医嘱后将病人状态置为到达
	s CFSetArriveByOrder=..%GetConfig("SetArriveByOrder",AdmDepHospId)
	if CFSetArriveByOrder=1,Doc'="" d ##class(web.DHCDocOrderEntry).SetArrivedStatus(Adm,Doc,Loc,User)
	d ##class(web.DHCDocOrderCommon).OrderEntryClearLock(SessionStr,"User.OEOrder")		//与GetOrdEntryBaseWarning中的OrderLock对应
	;保存审核医嘱相关基础代码使用次数
	d ##class(DHCDoc.Log.DHCDocCTUseCount).SaveOrdItemUseInfo(Ret,User,Loc)
	///调用RIS接口, 把医嘱信息发送给RIS  add by gongping 2010-12-28
	///s ret=##class(RISService.InvokeRISService).SendIPOrditemInfoToRIS(Ret)
	
	///调用平台接口，把医嘱信息插入平台医嘱中间表 yiwenjun 2012-02-15
	///d ##class(DHCENS.NURSE.SOAPSfInfoService).GetOrderRowId(Ret)
	//job ..DHCHisInterface(Ret,Doc,Adm,User)::5
	// V2 tanjishan 2023年6月19日, 调用公共的异步管理方法
    do ##class(DHCDoc.Util.Process).RunJobMethod("web.DHCOEOrdItem","DHCHisInterface",Ret,Doc,Adm,User,Loc)
	QUIT Ret
}

ClassMethod InvokeBill(Adm As %String, User As %String, needBillOrdStr As %String = "", ExpStr As %String = "") As %String
{
	n (Adm,User,needBillOrdStr,ExpStr)
	s rtn=0
	s AdmDepHospId=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(Adm)
	//如果设置了押金控制,需要做帐单
	s PAADMType=$p($g(^PAADM(Adm)),"^",2)
	s IsNeedBillFlag=0
	s BillAfterUpdate=..%GetConfig("CheckIPDeposit",AdmDepHospId)
	if (PAADMType="I") {
		;i BillAfterUpdate="1" s IsNeedBillFlag=1
		s IsNeedBillFlag=1
	}else{
		/*i BillAfterUpdate="1",PAADMType="E" {
			s PatCurStat=##class(web.DHCADMVisitStat).GetStayStatus(Adm)
			i " 1 2 "[(" "_PatCurStat_" ") s IsNeedBillFlag=1
		}*/
		if (PAADMType="E"){
			s PatCurStat=##class(web.DHCADMVisitStat).GetStayStatus(Adm)
			
			s StayPayMode=##class(web.DHCBillInterface).IGetStayPayMode(AdmDepHospId)
			if " 1 2 "[(" "_PatCurStat_" "){
				if (BillAfterUpdate="1"){
					s IsNeedBillFlag=1
			    }elseif(StayPayMode="1"){
				    //DHC_SOPFConfig OPFC_StayChargeMode 0 现金模式 1押金模式
				    s IsNeedBillFlag=1
				}
			}
		}
	}
	i IsNeedBillFlag=0 {
		q 0
	}
	s BillNOrdStr="",BillNFlag=0
	
	for k=1:1:$l(needBillOrdStr,"^") {
		s OneOrder=$p(needBillOrdStr,"^",k)
		continue:OneOrder=""
		if (OneOrder["*V*") {
			s OEORIRowid=$p(OneOrder,"*",2)
		}else{
			s OEORIRowid=$p(OneOrder,"!",1)
		}
		continue:OEORIRowid=""
		continue:$p(OEORIRowid,"||",2)<=0
		continue:('$D(^OEORD(+OEORIRowid,"I",$p(OEORIRowid,"||",2),1)))
		if (PAADMType="I") {
			s ExecSub=0 for {
				s ExecSub=$o(^OEORD(+OEORIRowid,"I",$p(OEORIRowid,"||",2),"X",ExecSub))
				Q:ExecSub=""
				if (BillNOrdStr="") s BillNOrdStr=OEORIRowid_"||"_ExecSub
				else  s BillNOrdStr=BillNOrdStr_"^"_OEORIRowid_"||"_ExecSub
			}
		}else{
			if (BillNOrdStr="") s BillNOrdStr=OEORIRowid
			else  s BillNOrdStr=BillNOrdStr_"^"_OEORIRowid
		}
	}
	if (BillNOrdStr'="") s BillNFlag=1
	s rtn=##Class(web.UDHCJFBILL).BILLN(Adm,User,BillNOrdStr,BillNFlag)
	
	Q rtn
}

ClassMethod IDeductOrder(OrderStr As %String, User As %String, Doc As %String, LogonDep As %String) As %String
{
	s OrderRowIDStr=""
	s practiceFlag=..practice(Doc)
	q:(practiceFlag=1)
	Q:OrderStr="" ""
	s OrderLen=$L(OrderStr,"^")
	f i=1:1:OrderLen 
	{
		S OneOrderStr=$P(OrderStr,"^",i)
		s OrderIDGet=$P(OneOrderStr,"*",2)
		Continue:OrderIDGet=""
		if OrderRowIDStr=""  s OrderRowIDStr=OrderIDGet
		else  s OrderRowIDStr=OrderRowIDStr_"^"_OrderIDGet
	}
	s hospitalId=$P(^CTLOC(LogonDep),"^",22)
	s GroupId=""
	s ExpStr=GroupId_"^"_LogonDep_"^"_hospitalId
	d ##class(BILL.PKG.SRV.Interface).IDeductOrder(OrderRowIDStr,User,ExpStr)
}

/// w ##Class(web.DHCOEOrdItem).InsertDHCCPWImp(74506,"11029||1*74366||216*V*^",208,386)
ClassMethod InsertDHCCPWImp(Adm As %String, OrderStr As %String, User As %String, Doctor As %String) As %String
{
	n (Adm,OrderStr,User,Doctor)
	
	s OrderRowId=##Class(web.DHCDocOrderEntry).GetPAADMOrderRowid(Adm)
	s MRCPWString=##class(web.DHCCPW.MR.ClinicalPathWays).GetActiveCPWByadm(Adm)
	s MRCPWRowId=$p(MRCPWString,"^",1)
	s err=0
	if MRCPWRowId="" Quit 0
	
	f k=1:1:$l(OrderStr,"^")-1 {
		s ArcimRowId=$p($p(OrderStr,"^",k),"*",1)
		i ArcimRowId="" continue
		s OrderItemRowId=$p($p(OrderStr,"^",k),"*",2)
		i OrderItemRowId="" continue
		s CPWStepItemRowId=$p($p(OrderStr,"^",k),"*",4)
		i CPWStepItemRowId="" continue
		s OrderStartDate=$p(^OEORD(+OrderItemRowId,"I",$P(OrderItemRowId,"||",2),1),"^",9)
		s OrderStartTime=$p(^OEORD(+OrderItemRowId,"I",$P(OrderItemRowId,"||",2),1),"^",10)
		if Doctor="" s Doctor=$P(^SSU("SSUSR",User),"^",14)
		
		s ImplStr="^"_MRCPWRowId_"^"
		s ImplStr=ImplStr_OrderItemRowId_"^"
		s ImplStr=ImplStr_CPWStepItemRowId_"^"
		s ImplStr=ImplStr_OrderStartDate_"^"
		s ImplStr=ImplStr_OrderStartTime_"^"
		s ImplStr=ImplStr_Doctor_"^^^"
		s ImplStr=ImplStr_User
		
		s err=##class(web.DHCCPW.MR.Implement).InsertImpl(ImplStr)
	}
	Q err
}

ClassMethod NeedCreateAdmSheets(OrdItemStr As %String) As %String
{
	s Find=0
	s ^zhou("NeedCreateAdmSheets")=OrdItemStr
	f k=1:1:$l(OrdItemStr,"^")-1 {
		s newOrdIdDR=$p($p(OrdItemStr,"^",k),"*",2)
		i newOrdIdDR="" continue
		i $G(^OEORD(+newOrdIdDR,"I",$p(newOrdIdDR,"||",2),"DHC")){
			s MultiDateStr=$p(^OEORD(+newOrdIdDR,"I",$p(newOrdIdDR,"||",2),"DHC"),"^",1)
			if MultiDateStr'="" {
				s Find=1
				break
			}
		}
	}
	Q Find
}

ClassMethod PinNumberValid(UserID, PinNumber)
{
	s cp=$p(^SSU("SSUSR",UserID),"^",14)
	q:cp="" -1         ;用户错误
	q:$g(PinNumber)="" -4
	s pin=$$ENCR^SSUTIL2(PinNumber) 
	Q:pin="" -4
	Q:pin'=$p(^SSU("SSUSR",UserID),"^",15) -4
	Q 0
}

ClassMethod PinLogNumberValid(UserID, PinNumber)
{
	Q:UserID="" "-1"
	Q:'$d(^SSU("SSUSR",UserID)) "-1"
	Set persistUserName = $p($g(^SSU("SSUSR",UserID)),"^",1)
	s IsValidUser=##class(web.SSUser).IsValidUser(persistUserName,PinNumber)
	if (IsValidUser["^") {
		q -4
		}
	//s cp=$p($g(^SSU("SSUSR",UserID)),"^",14)
	//q:cp="" -1         ;用户错误
	/*&q:$g(PinNumber)="" -4
	s pin=$$ENCR^SSUTIL2(PinNumber) 
	Q:pin="" -4
	Q:pin'=$p(^SSU("SSUSR",UserID),"^",3) -4*/
	
	Q 0
}

/// w ##Class(web.DHCOEOrdItem).GetUnExecOrdInfo(1266)
ClassMethod GetUnExecOrdInfo(EpisodeID As %String) As %String
{
	s retStr=""
	k abnormalOrd
	s ignoreStr=##class(Nur.DHCADTDischarge).getIgnoreOeoreStr(EpisodeID)
	s abnormalType="Disch"
	s ID = 0
	f  {
		s ID=$o(^DHCDishChargeSet(abnormalType,"AbnormalStat",ID)) 
		q:ID=""
		s ifAlert = $p($g(^DHCDishChargeSet(abnormalType,"AbnormalStat",ID)),"^",2)
		continue:((ifAlert="")!(ifAlert="N"))
		s alertSeq = $p($g(^DHCDishChargeSet(abnormalType,"AbnormalStat",ID)),"^",3)
		continue:alertSeq=""
		s methodName = $p($g(^DHCDishChargeSet(abnormalType,"AbnormalStat",ID)),"^",4)
		continue:methodName=""
		continue:(methodName'="getUnexecLabOrder")&&(methodName'="getUnexecExamOrder")
		s x="d ##Class(Nur.DHCADTDischarge)."_methodName_"("""_EpisodeID_""","""_ID_""","""_ignoreStr_""","""_abnormalType_""")"
		try {x x}catch{}
	}
	s abnType=""  
	f  {
		s abnType=$o(abnormalOrd(EpisodeID,abnType))
		q:abnType=""
		s alertSeq = "" 
		f{
			s alertSeq=$o(abnormalOrd(EpisodeID,abnType,alertSeq))
			q:alertSeq=""
			s abnormalID=""  
			f  {
				s abnormalID=$o(abnormalOrd(EpisodeID,abnType,alertSeq,abnormalID))
				q:abnormalID=""
				s abnormalNum= abnormalOrd(EpisodeID,abnType,alertSeq,abnormalID,0)
				continue:abnormalNum=0
				s abnormalStatDesc = $p($g(^DHCDishChargeSet(abnType,"AbnormalStat",abnormalID)),"^",1)
				i retStr="" s retStr="该病人有"_abnormalStatDesc_"医嘱"_abnormalNum_"条！请先处理！"
				e  s retStr=retStr_","_"该病人有"_abnormalStatDesc_"医嘱"_abnormalNum_"条！请先处理！"
	
			}
		}
	}
	q retStr
}

/// w ##class(web.DHCOEOrdItem).CheckBeforeSaveTest()
ClassMethod CheckBeforeSaveTest() As %String [ ProcedureBlock = 0 ]
{
	s ExeStr="rtn="_^TEMPtan("CheckBeforeSave")
	s @ExeStr
	q rtn
}

/// creator:		郭荣勇
/// date:		2015-11-25
/// desc:		对于医嘱录入非必须前端处理的判断逻辑可以在此处理
/// input:		OrdItemStr:医嘱录入需要审核的医嘱项目拼接字符串 
/// 				DisplayTypeFlag 表示输入界面类型 1 输出EasyUI匹配得换行符号<br>
/// output:		空 或 标志位^受控描述^... 标志位:0或1 1标识受控,不可以录入
/// w ##class(web.DHCOEOrdItem).CheckBeforeSave($LG(^tmpwqy("CheckBeforeSave"),1),$LG(^tmpwqy("CheckBeforeSave"),2),$LG(^tmpwqy("CheckBeforeSave"),3),$LG(^tmpwqy("CheckBeforeSave"),4),$LG(^tmpwqy("CheckBeforeSave"),5),$LG(^tmpwqy("CheckBeforeSave"),6),$LG(^tmpwqy("CheckBeforeSave"),7))
ClassMethod CheckBeforeSave(Adm As %String, OrdItemStr As %String, User As %String, Loc As %String, Doc As %String, ExpStr As %String = "", DisplayTypeFlag As %String = "") As %String
{
	n (Adm,OrdItemStr,User,Loc,Doc,ExpStr,DisplayTypeFlag,%session)
	s:Adm=3265 ^tmpwqy("CheckBeforeSave")=$LB(Adm,OrdItemStr,User,Loc,Doc,ExpStr,DisplayTypeFlag)
	
	s PatientID=$P(^PAADM(Adm),"^",1)
	s AdmType=$P($G(^PAADM(Adm)),"^",2)
	s PAADMInsType=$P(^PAADM(Adm,1),"^",7)
	s VisitStatus=$p($g(^PAADM(Adm)),"^",20)
	s BeforeSaveret=0,ErrMsg=""
	s PilotPRowId=$P(ExpStr,"^",1)
	s LogonDep=Loc //$P(ExpStr,"^",2)
	s OrderOpenForAllHosp=$P(ExpStr,"^",3)
	s NotAdmTypeLimit=$P(ExpStr,"^",4) ;是否判断访问类型限制
	s CurHospId=$p($g(^CTLOC(Loc)),"^",22)
	Set langid=..%LanguageID()
	//callbackfun^callbackfunParams(,,,)$C(1)callbackfun^callbackfunParams(,,,).....
	s CallBackFunStr=""
	Q:OrdItemStr="" ""
	//行号^焦点原始名称^回调方法代码\名称^回调方法入参(,分割)
	s CallBackFunStr=""
	k OrderSeqNoArray,OrderMaterialBarCodeArray,OrderInstrGroupArr,OrderBillTypeArray,CelerOrderSeqNoDataArr,ALLOrderSeqNoDataArr
	s ConflictItemsInfo=""
	s OutOrderList=""
	s ARCIMRowidStr=""
	s BillSum=0
	s NeedCheckDeposit=0
	s RowSeqNo=""
	s OutInfo=""
	s LastExceedReasonID=""
	;若登录用户未维护医护人员信息,也能审核医嘱成功,造成查询医嘱查询不到
	if Doc=""{
		s OutInfo="-100^请联系相关人员维护医护人员信息.^^"
		q:(+OutInfo'=0) $$CheckBeforeSaveJsonObj(OutInfo,CallBackFunStr)
	}
	s EmConsultItm=$P($p(OrdItemStr,$c(1),1),"^",81)
	s SessionStr=..%SessionStr()
	if (SessionStr=""){
		s SessionStr=User_"^"_""_"^"_LogonDep_"^"_CurHospId_"^^"_langid
	}
	s orderrow=##Class(web.DHCDocOrderEntry).GetPAADMOrderRowid(Adm)
	s warning=##class(web.DHCDocOrderCommon).OrderLock(orderrow, SessionStr, "Check", "")
	//获取医嘱录入/草药录入提示信息
	s:warning="" warning=##Class(web.DHCDocViewDataInit).GetOrdEntryWarning(Adm,"",EmConsultItm,NotAdmTypeLimit,SessionStr)
	if (warning'="") {
		s warning=##class(web.DHCDocUtil).EvalJSON(warning)
		s OutInfo="-100^"_warning_"^^"
		Q:(+OutInfo'=0) $$CheckBeforeSaveJsonObj(OutInfo,CallBackFunStr)
	}
	
	;检测成组医嘱
	k LinkPXList
	s BillTypeRowid=$p(^PAADM(Adm,1),"^",7)
	Set OrdItemCount=$L(OrdItemStr,$c(1))
	for i=1:1:OrdItemCount {
		s OrdItem=$p(OrdItemStr,$c(1),i)
		continue:OrdItem=""
		s ARCIMRowid=$p(OrdItem,"^",1)
		continue:ARCIMRowid=""
		s OrderName=$P(^ARCIM(+ARCIMRowid,$P(ARCIMRowid,"||",2),1),"^",2)
		s OrderName=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",OrderName,langid)
		d SetOrdDetails
		
		;SeqNo^FocusCol^CallBakFunCode^CallBakFunParams
		/*
		考虑到快速医嘱套的存在，传入的OrderSeqNo并不是真正的行号
		*/
		if (AdmReason=""){
			s AdmReason=BillTypeRowid
		}
		if $D(OrderSeqNoArray(OrderSeqNo)){
			s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp","医嘱序号重复,请删除重复项目!")
			s $P(OutInfo,"^",3)=OrdRowIndex
			s $P(OutInfo,"^",4)="OrderName"
			q
		}
		s OrderSeqNoArray(OrderSeqNo)=OrderSeqNo
		if (MaterialBarCode'=""){
			if $D(OrderMaterialBarCodeArray(MaterialBarCode)){
				s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp","一次录入不能存在两条相同条码的医嘱！")
				s $P(OutInfo,"^",3)=OrdRowIndex
				s $P(OutInfo,"^",4)="OrderMaterialBarcodeHiden"
				q
			}
			s OrderMaterialBarCodeArray(MaterialBarCode)=OrderSeqNo
		}
		///组织全局数据
		if (ARCIMRowidStr = ""){
        	s ARCIMRowidStr =PriorRowid_"^"_ARCIMRowid
        }else {
	        s ARCIMRowidStr = ARCIMRowidStr_"!"_PriorRowid_"^"_ARCIMRowid
	    }
	    ;计算未审核总价
	    s PriorCode=$p($g(^OECPR(PriorRowid)),"^",1)
	    s CalPackQty=$CASE(OrderType,"R":PackQty,:DoseQtySum)
	    if (+CalPackQty=0){s CalPackQty=1}
	    if ((PriorCode '["OM") && (PriorCode '["ZT")){
			s BillSum=BillSum+(oeprice*CalPackQty)
			s NeedCheckDeposit=1
		}
	    ;各费别费用总金额
		if ((PriorCode '["OM") && (PriorCode '["ZT")){
			s OrderBillTypeArray(AdmReason)=$G(OrderBillTypeArray(AdmReason))+(oeprice*CalPackQty)
		}		
		//快速医嘱套验证用法、频次、接收科室、输液流速、流速单位是否相同
		s LinkOrdNeedCheckStr=MasterSeqNo_"^"_FreqRowid_"^"_InstrRowid_"^"_OrderStageCode_"^"_SpeedFlowRate_"^"_OrderFlowRateUnit_"^"_OrderName_"^"_ARCOSRowid
	    if (CelerType="Y")&&(MasterSeqNo'=""){
			s CelerOrderSeqNoDataArr(OrderSeqNo)=LinkOrdNeedCheckStr
		}
		s ALLOrderSeqNoDataArr(OrderSeqNo)=LinkOrdNeedCheckStr
		///----
		;1.基本信息校验或通用信息审查
		s CheckExpStr=Loc_"^"_User
		s OutInfo=..CheckOrdBasicInfo(Adm,OrdItem,OrdRowIndex,.LastExceedReasonID,OrdItemStr,CheckExpStr,.CallBackFunStr)
		i (+OutInfo'=0) s $P(OutInfo,"^",3)=OrdRowIndex q
		;2.药理项目验证
		s CheckExpStr=PilotPRowId_"^"_Loc
		s OutInfo=..CheckOrdPilotInfo(Adm,OrdItem,CheckExpStr,OrdItemStr,.CallBackFunStr)
		i (+OutInfo'=0) s $P(OutInfo,"^",3)=OrdRowIndex q
		;3.高值材料信息验证--为适应厂商统一码，将该判断转移至循环外层
		//s CheckExpStr=Loc
		//s OutInfo=..CheckMaterialBarcode(Adm,OrdItem,CheckExpStr,.CallBackFunStr)
		//i (+OutInfo'=0) s $P(OutInfo,"^",3)=OrdRowIndex q
		;4.开医嘱时间\医嘱开始时间校验
		s CheckExpStr=Loc
		s OutInfo=..CheckOrderDateTime(Adm,OrdItem,OrdItemStr,CheckExpStr,.CallBackFunStr)
		i (+OutInfo'=0) s $P(OutInfo,"^",3)=OrdRowIndex q
		
		if (OrderType="R"){
			;5.药品医嘱基本审查
			s OutInfo=..CheckDrugUpdate(Adm,OrdItem,OrdItemStr,.CallBackFunStr,.OrderInstrGroupArr,OrdRowIndex,SessionStr)
			i (+OutInfo'=0) s $P(OutInfo,"^",3)=OrdRowIndex  q
			;5.1.出院带药其他审查
        	
			s CheckExpStr=ARCIMRowidStr_$C(2)_Loc
			s OutInfo=..CheckOutOrderOtherContral(Adm,OrdItem,CheckExpStr,.CallBackFunStr)
			i (+OutInfo'=0) s $P(OutInfo,"^",3)=OrdRowIndex q
			;自备药医嘱审查
			s OutInfo=..CheckOMOrderOtherContral(Adm,OrdItem,CheckExpStr,.CallBackFunStr)
			i (+OutInfo'=0) s $P(OutInfo,"^",3)=OrdRowIndex q
			
			s AllowIPBookVisitPDrugOrder=##Class(web.DHCDocIPBookNew).GetIPBookHospConfig("AllowIPBookVisitPDrugOrder",CurHospId)
			if (OrderType="R")&&(VisitStatus="P")&&('..ChkLocIsSpeciadrug(RecDepRowid,Loc))&&(AllowIPBookVisitPDrugOrder'=1) {
				s RecDepDesc=$p(^CTLOC(RecDepRowid),"^",2)
				s RecDepDesc=##class(User.CTLoc).GetTranByDesc("CTLOCDesc",RecDepDesc,langid)
				s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 接收科室【")_RecDepDesc_..%Translate("oeorder.oplistcustom.new.csp","】的特殊发药科室没有该登录科室,预住院患者不能开立!")
				q
			}
		}else{
			;6.非药品医嘱基本审查
			s OutInfo=..CheckNotDrugUpdate(Adm,OrdItem,.CallBackFunStr,OrdItemStr,OrdRowIndex)
			i (+OutInfo'=0) s $P(OutInfo,"^",3)=OrdRowIndex q
		}
		;7.库存审查
		s OutInfo=..CheckStockUpdate(Adm,Loc,OrdItem,.CallBackFunStr,OrdItemStr,OrderOpenForAllHosp)
		i (+OutInfo'=0) s $P(OutInfo,"^",3)=OrdRowIndex q
		;8.医嘱数量基本特性审查
		s CheckExpStr=Loc
		s OutInfo=..CheckPackQtyUpdate(Adm,OrdItem,CheckExpStr,OrdItemStr,.CallBackFunStr,OrdRowIndex)
		i (+OutInfo'=0) s $P(OutInfo,"^",3)=OrdRowIndex q
		;9.判断整数量是否符合限量控制和疗程控制
		s CheckExpStr=Loc
		s OutInfo=..CheckDurationPackQty(Adm,OrdItem,OrdItemStr,CheckExpStr,.CallBackFunStr)
		i (+OutInfo'=0) s $P(OutInfo,"^",3)=OrdRowIndex q
		;10.治疗项目判断  康复治疗控制
		s OutInfo=..CheckDHCDocTreatItem(Adm,OrdItem,.CallBackFunStr)
		i (+OutInfo'=0) s $P(OutInfo,"^",3)=OrdRowIndex q
		;11.检查医嘱优先级是否在允许范围内-
		s OutInfo=..CheckOrdPriorAllow(Adm,OrdItem,Loc,.CallBackFunStr)
		i (+OutInfo'=0) s $P(OutInfo,"^",3)=OrdRowIndex q
		;12.护士补录医嘱类型是否一致的控制
		s OutInfo=..CheckMasterConsistency(Adm,OrdItem,.CallBackFunStr)
		i (+OutInfo'=0) s $P(OutInfo,"^",3)=OrdRowIndex q
		;13. 出院或死亡类医嘱的处理方式
		s CheckExpStr=User_"^"_ARCIMRowid_"^"_OrderStartDate_"^"_OrderStartTime_"^"_CurHospId_"^"_OrdRowIndex
		s OutInfo=..CheckDischargeOrd(Adm,CheckExpStr,.CallBackFunStr)
		i (+OutInfo'=0) s $P(OutInfo,"^",3)=OrdRowIndex q
		;13 .转科医嘱的处理方式
		s CheckExpStr=User_"^"_ARCIMRowid_"^"_OrderStartDate_"^"_OrderStartTime_"^"_OrdRowIndex
		s OutInfo=..CheckTransOrd(Adm,CheckExpStr,.CallBackFunStr)
		i (+OutInfo'=0) s $P(OutInfo,"^",3)=OrdRowIndex q
		;15.抗生素审查
		s OutInfo=..CheckKSS(Adm,OrdItem,.CallBackFunStr)
		i (+OutInfo'=0) s $P(OutInfo,"^",3)=OrdRowIndex q
		;16.获取成组医嘱信息,供验证主子医嘱数据一致性
		if (OEORIBindSource="") {
			if MasterSeqNo'="" s LinkPXList(MasterSeqNo,OrderSeqNo)=OrdItem
			else  s LinkPXList(OrderSeqNo)=OrdItem
		}
	    ;获取互斥医嘱提示
	    s OutInfo=..CheckConflict(Adm,OrdItem,SessionStr,.CallBackFunStr)
	    i (+OutInfo'=0) s $P(OutInfo,"^",3)=OrdRowIndex q
	    s ConflictItemDesc=$P(OutInfo,"^",2)
	    if ConflictItemDesc'=""{
			i ConflictItemsInfo = "" s ConflictItemsInfo = ConflictItemDesc
	        e  s ConflictItemsInfo = ConflictItemsInfo + "  " + ConflictItemDesc
		}
	}
	q:(+OutInfo'=0) $$CheckBeforeSaveJsonObj(OutInfo,CallBackFunStr)
	s $P(OutInfo,"^",3)=""
	if '$D(OrderSeqNoArray){
		s OutInfo="-1^没有新开医嘱^^^^"
	    q $$CheckBeforeSaveJsonObj(OutInfo,CallBackFunStr)
	}
	//判断成组医嘱信息
	s errmesage=..CheckGroupMesage(.LinkPXList,LogonDep)
	if (errmesage'=""){
		s OutInfo="-1^"_errmesage_"^^^^"
	    q $$CheckBeforeSaveJsonObj(OutInfo,CallBackFunStr)
	}
	//快速医嘱套数据验证
	;不随主医嘱变化的用法
	s NotFollowInstr=..%GetConfig("NotFollowInstr",CurHospId)
	if NotFollowInstr'="" s NotFollowInstr="^"_NotFollowInstr_"^"
    //自定义流速用法
    s SpeedRateSeparateInstr=##class(DHCDoc.DHCDocConfig.InstrArcim).GetSpeedRateSeparateInstr(CurHospId)
    s:SpeedRateSeparateInstr'="" SpeedRateSeparateInstr="^"_SpeedRateSeparateInstr_"^"
	s i="0"
	for {
		s i=$O(CelerOrderSeqNoDataArr(i))
		q:i=""
		//MasterSeqNo_"^"_FreqRowid_"^"_InstrRowid_"^"_OrderStageCode_"^"_SpeedFlowRate_"^"_OrderFlowRateUnit
		s SubOrdDataStr=$g(CelerOrderSeqNoDataArr(i))
		s SubFreqRowid=$P(SubOrdDataStr,"^",2)
		s SubInstrRowid=$P(SubOrdDataStr,"^",3)
		s SubOrderStageCode=$P(SubOrdDataStr,"^",4)
		s SubSpeedFlowRate=$P(SubOrdDataStr,"^",5)
		s SubOrderFlowRateUnit=$P(SubOrdDataStr,"^",6)
		s SubOrdName=$P(SubOrdDataStr,"^",7)
		//ARCOSRowid
		s MasterSeqNo=$P(SubOrdDataStr,"^",1)
		s MasOrdDataStr=$g(ALLOrderSeqNoDataArr(MasterSeqNo))
		s MasFreqRowid=$P(MasOrdDataStr,"^",2)
		s MasInstrRowid=$P(MasOrdDataStr,"^",3)
		s MasOrderStageCode=$P(MasOrdDataStr,"^",4)
		s MasSpeedFlowRate=$P(MasOrdDataStr,"^",5)
		s MasOrderFlowRateUnit=$P(MasOrdDataStr,"^",6)
		s MasOrdName=$P(MasOrdDataStr,"^",7)
		s ErrMsg="快速医嘱套: "_$p(^ARCOS($P(SubOrdDataStr,"^",8)),"^",2)_"中的子医嘱: "_SubOrdName_"和主医嘱: "_MasOrdName
		if (SubFreqRowid'=MasFreqRowid){
			s ErrMsg=ErrMsg_"频次不一致!"
			s OutInfo="-1^"_ErrMsg_"^^^^"
	    	q 
		}
		if (SubInstrRowid'=MasInstrRowid)&&(NotFollowInstr'[("^"_SubInstrRowid_"^")){
			s ErrMsg=ErrMsg_"用法不一致!"
			s OutInfo="-1^"_ErrMsg_"^^^^"
	    	q
		}
		if (SubOrderStageCode'=SubOrderStageCode){
			s ErrMsg=ErrMsg_"医嘱阶段不一致!"
			s OutInfo="-1^"_ErrMsg_"^^^^"
	    	q
		}
        //非 流速可以自定义的用法 需判断流速
        if (SpeedRateSeparateInstr'[("^"_SubInstrRowid_"^")){
            if (SubSpeedFlowRate'=MasSpeedFlowRate){
                s ErrMsg=ErrMsg_"输液流速不一致!"
                s OutInfo="-1^"_ErrMsg_"^^^^"
                q
            }
            if (MasOrderFlowRateUnit'=MasOrderFlowRateUnit){
                s ErrMsg=ErrMsg_"流速单位不一致!"
                s OutInfo="-1^"_ErrMsg_"^^^^"
                q
            }
        }
	}
	q:(+OutInfo'=0) $$CheckBeforeSaveJsonObj(OutInfo,CallBackFunStr)	
	//开过相同的医嘱且在疗程内
	s CheckItemInDuration=..CheckItemInDuration(Adm,OrdItemStr,LogonDep)
	Q:(CheckItemInDuration'="") $$CheckBeforeSaveJsonObj(CheckItemInDuration,CallBackFunStr)
	///每天最大剂量
	s CheckMaxDoseQtyPerDay=..CheckMaxDoseQtyPerDay(OrdItemStr,Adm)
	Q:(+CheckMaxDoseQtyPerDay'=0) $$CheckBeforeSaveJsonObj(CheckMaxDoseQtyPerDay,CallBackFunStr)
	///是否存在重复的检验医嘱
	s CheckRepeatLabOrd=..CheckRepeatLabOrd(Adm,OrdItemStr)
	Q:(+CheckRepeatLabOrd'=0) $$CheckBeforeSaveJsonObj(CheckRepeatLabOrd,CallBackFunStr)
	//判断医嘱需开特定医嘱设置
	s ret=##Class(web.DHCDocOrderCommon).CheckSpecOrdLinked(Adm, ARCIMRowidStr,CurHospId,langid)
    if (+ret'=0) {
	    s OutInfo="-1^"_$P(ret,"^",2)_..%Translate("oeorder.oplistcustom.new.csp"," 需要先开条件医嘱,请修改")_"^^^^"
	    q $$CheckBeforeSaveJsonObj(OutInfo,CallBackFunStr)
    }
    //按用法分处方，处方数量校验
	/*s i="0"
	for {
		s i=$O(OrderInstrGroupArr(i))
		q:i=""
		s EachInstrGroupCount=$P(OrderInstrGroupArr(i),"!",2)
		if (EachInstrGroupCount>5){
			s ErrMsg=$P(OrderInstrGroupArr(i),"!",1)
			s OutInfo="-1^超过处方项目数量限定:5^^^^"
	    	q
		}
	}*/
	q:+OutInfo<0 $$CheckBeforeSaveJsonObj(OutInfo,CallBackFunStr)
	;判断费别和费用限制
	s CheckExpStr=Loc
	s OutInfo=..CheckBillTypeSum(Adm,CheckExpStr,.OrderBillTypeArray,.CallBackFunStr)
	Q:(+OutInfo'=0) $$CheckBeforeSaveJsonObj(OutInfo,CallBackFunStr)
	;高值材料信息验证--为适应[厂商统一码]，将该判断转移至循环外层
	s CheckExpStr=Loc
	s OutInfo=..CheckMaterialBarcode(Adm,OrdItemStr,CheckExpStr,.CallBackFunStr,SessionStr)
	Q:(+OutInfo'=0) $$CheckBeforeSaveJsonObj(OutInfo,CallBackFunStr)
	
	if (ConflictItemsInfo'=""){
		s CallBackFunParams=ConflictItemsInfo
		s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"StopConflict",CallBackFunParams)
	}
	;if PilotPRowId'=""{
		;临床药理实验 GCP禁用药设置
		s GCPBanDrugMsg=##class(DHCDoc.GCPSW.CFG.Warning).GetGCPBanDrugMsg(PilotPRowId,"","N",Adm,PatientID)
		if GCPBanDrugMsg'=""{
			s CallBackFunParams=GCPBanDrugMsg
			s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
		}
	;}
	;审核时金额统计放到前台去做
	s $P(OutInfo,"^",5)=NeedCheckDeposit
	q $$CheckBeforeSaveJsonObj(OutInfo,CallBackFunStr)
	
CheckBeforeSaveJsonObj(OutPutInfo,CallBackFunStr)
	s ErrCode=$P(OutPutInfo,"^",1)
	s ErrMsg=$P(OutPutInfo,"^",2)
	s OrdRowIndex=$P(OutPutInfo,"^",3)
	s FocusCol=$P(OutPutInfo,"^",4)
	s NeedCheckDeposit=$P(OutPutInfo,"^",5)
	s ErrMsg=##class(ext.util.String).EvalJSON(ErrMsg)
	k OutPutDataArr
	s OutPutDataArr("ErrCode")=ErrCode
	s OutPutDataArr("ErrMsg")=ErrMsg
	s OutPutDataArr("OrdRowIndex")=OrdRowIndex
	s OutPutDataArr("FocusCol")=FocusCol
	s OutPutDataArr("NeedCheckDeposit")=NeedCheckDeposit
	s SubNodeNum=0
	for i=1:1:$Length(CallBackFunStr,$C(2)){
		s SingleCallBackFun=$P(CallBackFunStr,$C(2),i)
		if (SingleCallBackFun=""){continue}
		s CallBakFunCode=$P(SingleCallBackFun,"^",1)
		s CallBakFunParams=$P(SingleCallBackFun,"^",2)
		s CallBakFunOrdRowIndex=$P(SingleCallBackFun,"^",3)
		s SubNodeNum=SubNodeNum+1
		s OutPutDataArr("CallBakFunS",SubNodeNum,"CallBakFunCode")=CallBakFunCode
		s OutPutDataArr("CallBakFunS",SubNodeNum,"CallBakFunParams")=CallBakFunParams
		s OutPutDataArr("CallBakFunS",SubNodeNum,"CallBakFunOrdRowIndex")=CallBakFunOrdRowIndex
	}
	s OutPutDataJson=##Class(DHCDoc.Util.FromJSON).GetArrJson(.OutPutDataArr)
	q OutPutDataJson
	/*
	s ErrCode=$P(OutPutInfo,"^",1)
	s ErrMsg=$P(OutPutInfo,"^",2)
	s OrdRowIndex=$P(OutPutInfo,"^",3)
	s FocusCol=$P(OutPutInfo,"^",4)
	s NeedCheckDeposit=$P(OutPutInfo,"^",5)
	s JsonObj=[]
	s JsonData={}
	do JsonData.%Set("ErrCode",ErrCode)
	do JsonData.%Set("ErrMsg",ErrMsg)
	do JsonData.%Set("OrdRowIndex",OrdRowIndex)
	do JsonData.%Set("FocusCol",FocusCol)
	do JsonData.%Set("NeedCheckDeposit",NeedCheckDeposit)
	s SubJsonObj=[]
	for i=1:1:$Length(CallBackFunStr,$C(2)){
		s SingleCallBackFun=$P(CallBackFunStr,$C(2),i)
		if (SingleCallBackFun=""){continue}
		s CallBakFunCode=$P(SingleCallBackFun,"^",1)
		s CallBakFunParams=$P(SingleCallBackFun,"^",2)
		s SingleJsonData={}
		do SingleJsonData.%Set("CallBakFunCode",CallBakFunCode)
		do SingleJsonData.%Set("CallBakFunParams",CallBakFunParams)
		do SubJsonObj.%Push(SingleJsonData,"")
	}
	d JsonData.%Set("CallBakFunS",SubJsonObj)
	
	do JsonObj.%Push(JsonData,"")
	s JsonInfo=""
	s obj=##class(%Stream.GlobalCharacter).%New()
	do JsonObj.%ToJSON(obj)
	While 'obj.AtEnd { 
		s JsonInfo=JsonInfo_obj.ReadLine(,.sc,.eol)
	}
	q JsonInfo
	*/
SetOrdDetails
	s OrderType=$p(OrdItem,"^",2)
	s PriorRowid=$p(OrdItem,"^",3)
	s OrderStartDate=$p(OrdItem,"^",4)
	s OrderStartTime=$p(OrdItem,"^",5)
	Set PackQty=$p(OrdItem,"^",6)
	Set oeprice=$p(OrdItem,"^",7)
	Set RecDepRowid=$p(OrdItem,"^",8)
	Set AdmReason=$replace($p(OrdItem,"^",9),$c(10),"")
	Set DrugFormRowid=$p(OrdItem,"^",10)
	Set DepProcNotes=$p(OrdItem,"^",11)
	Set DoseQty=$p(OrdItem,"^",12)
	Set DoseUOMRowid=$p(OrdItem,"^",13)
	Set DoseQtySum=$p(OrdItem,"^",14)
	Set FreqRowid=$p(OrdItem,"^",15)
	Set DurRowid=$p(OrdItem,"^",16)
	Set InstrRowid=$p(OrdItem,"^",17)
	Set PHPrescType=$p(OrdItem,"^",18)
	Set MasterSeqNo=$p(OrdItem,"^",19)
	s OrderSeqNo=$p(OrdItem,"^",20)
	Set SkinTest=$p(OrdItem,"^",21)
	Set PhSpecInstr=$p(OrdItem,"^",22)
	Set OrderCoverMainIns=$p(OrdItem,"^",23)
	Set ActionRowid=$p(OrdItem,"^",24)
	Set ARCOSRowid=$p(OrdItem,"^",25)
	Set EndDate=$p(OrdItem,"^",26)
	Set EndTime=$p(OrdItem,"^",27)
	Set ExecuteDateStr=$p(OrdItem,"^",29)
	Set NotifyClinician=$p(OrdItem,"^",30)
	Set DIACatRowId=$p(OrdItem,"^",31)
	Set InsurCatRowId=$p(OrdItem,"^",32)
	Set FirstDayTimes=$p(OrdItem,"^",33)
	Set InsurSignSymptomCode=$p(OrdItem,"^",34)
	Set OrderStageCode=$p(OrdItem,"^",35)
	Set SpeedFlowRate=$p(OrdItem,"^",36)
	Set AnaesthesiaID=$p(OrdItem,"^",37)
	Set LabEpisodeNo=$p(OrdItem,"^",38)
	Set VerifiedOrderMasterRowid=$p(OrdItem,"^",39)
 	Set OrderNutritionDrugFlag=$p(OrdItem,"^",40)
 	Set MaterialBarCode=$p(OrdItem,"^",41)
 	Set CPWStepItemRowId=$p(OrdItem,"^",43)
 	Set InsurApproveType=$p(OrdItem,"^",44)
 	Set OrderFlowRateUnit=$p(OrdItem,"^",45)
 	Set OrderDate=$p(OrdItem,"^",46)
 	Set OrderTime=$p(OrdItem,"^",47)
 	Set OrderNeedPIVAFlag=$p(OrdItem,"^",48)
 	Set OrderAntibApplyRowid=$p(OrdItem,"^",49)
 	Set AntUseReason=$p(OrdItem,"^",50)
 	Set UseReasonId=$p(OrdItem,"^",51)
	Set OrderLocalInfusionQty=$p(OrdItem,"^",52)
	Set OrderBySelfOMFlag=$p(OrdItem,"^",53)
	Set ExceedReasonID=$p(OrdItem,"^",54) 
	Set OrderPackUOMRowid=$p(OrdItem,"^",55)
	Set PilotProRowId=$p(OrdItem,"^",56)
	Set OrderOutsourcingFlag=$p(OrdItem,"^",57)
	Set OEORIBindSource=$p(OrdItem,"^",58) //医嘱绑定来源
	Set ApplyArcId=$p(OrdItem,"^",59)
	set OrderDHCAADr=$p(OrdItem,"^",60)
	Set OperationCode=$p(OrdItem,"^",61)
	Set ZSKMonitorLogId=$p(OrdItem,"^",62)
	
	Set OrderNurseLinkOrderRowid=$p(OrdItem,"^",63)
	Set OrderBodyPartLabel=$p(OrdItem,"^",64)
	Set CelerType=$p(OrdItem,"^",65)	//快速医嘱套标识
	Set OrdRowIndex=$p(OrdItem,"^",66)	//实际的行号
	q
}

ClassMethod CheckGroupMesage(ByRef LinkPXList, LogonDep As %String)
{
	//成组医嘱检测
	s rtnerrmesage=""
	s CurLogonHosp =$p($g(^CTLOC(LogonDep)),"^",22)
	s SkinTestInstr=..%GetConfig("SkinTestInstr",CurLogonHosp)
    if SkinTestInstr'="" s SkinTestInstr="^"_SkinTestInstr_"^"
	s NotFollowInstr=..%GetConfig("NotFollowInstr",CurLogonHosp)
	if NotFollowInstr'="" s NotFollowInstr="^"_NotFollowInstr_"^"
	;外用用法
	s WYInstr=..%GetConfig("WYInstr",CurLogonHosp)
	if (WYInstr'="") s WYInstr="^"_WYInstr_"^"
	;成组医嘱接收科室一致
 	s CFSameRecDepForGroup=..%GetConfig("SameRecDepForGroup",CurLogonHosp)
 	;自备药临时医嘱
	s OMOrderPriorRowid=$O(^OECPR(0,"Code","OM",0))
	;自备药长期医嘱
	s OMSOrderPriorRowid=$O(^OECPR(0,"Code","OMST",0))
	;长期嘱托
 	s OMCQZTOrderPriorRowid=$O(^OECPR(0,"Code","OMCQZT",0))
    ;临时嘱托
    s OMLSZTOrderPriorRowid=$O(^OECPR(0,"Code","OMLSZT",0))
    //自定义流速用法
    s SpeedRateSeparateInstr=##class(DHCDoc.DHCDocConfig.InstrArcim).GetSpeedRateSeparateInstr(CurLogonHosp)
    s:SpeedRateSeparateInstr'="" SpeedRateSeparateInstr="^"_SpeedRateSeparateInstr_"^"
	s sub1=0
	for {
		s sub1=$O(LinkPXList(sub1)) Q:((sub1="")||(rtnerrmesage'=""))  
		s ARCIMRowid=$p($G(LinkPXList(sub1)),"^",1)
		continue:ARCIMRowid=""
		s MainOrderPriorRowid=$p($G(LinkPXList(sub1)),"^",3)
		s MainRecDepRowid=$p($G(LinkPXList(sub1)),"^",8)
		s MainOrderName=$P(^ARCIM(+ARCIMRowid,$P(ARCIMRowid,"||",2),1),"^",2)
		s mainFirstDayTimes=$p($G(LinkPXList(sub1)),"^",33)
		s mainFreqRowid=$p($G(LinkPXList(sub1)),"^",15)
		s mainDurRowid=$p($G(LinkPXList(sub1)),"^",16)
		s mainInstrRowid=$p($G(LinkPXList(sub1)),"^",17)
		s mainOrderType=$p($G(LinkPXList(sub1)),"^",2)
		s mainOrderStartDate=$p($G(LinkPXList(sub1)),"^",4)
		s mainOrderStartTime=$p($G(LinkPXList(sub1)),"^",5)
		s mainOrderSeqNo=$p($G(LinkPXList(sub1)),"^",20)
		s mainOrderSkinTest=$p($G(LinkPXList(sub1)),"^",21)
		s mainOrderStageCode=$p($G(LinkPXList(sub1)),"^",35)
		s mainSpeedFlowRate=$p($G(LinkPXList(sub1)),"^",36)
		s mainOrderFlowRateUnit=$p($G(LinkPXList(sub1)),"^",45)
		s mainOrderFreqWeekStr=$p($G(LinkPXList(sub1)),"^",67)
		s GroupOrderSkinTestStr=mainOrderSkinTest
		s sub2=0
		for  {
			s sub2=$O(LinkPXList(sub1,sub2)) Q:((sub2="")||(rtnerrmesage'=""))  d
			s ARCIMRowid=$p($G(LinkPXList(sub1,sub2)),"^",1)
			continue:ARCIMRowid=""
			s SubOrderName=$P(^ARCIM(+ARCIMRowid,$P(ARCIMRowid,"||",2),1),"^",2)
			s subOrderPriorRowid=$p($G(LinkPXList(sub1,sub2)),"^",3)
			s subRecDepRowid=$p($G(LinkPXList(sub1,sub2)),"^",8)
			s subFirstDayTimes=$p($G(LinkPXList(sub1,sub2)),"^",33)
			s subOrderType=$p($G(LinkPXList(sub1,sub2)),"^",2)
			s subFreqRowid=$p($G(LinkPXList(sub1,sub2)),"^",15)
			s subDurRowid=$p($G(LinkPXList(sub1,sub2)),"^",16)
			s subInstrRowid=$p($G(LinkPXList(sub1,sub2)),"^",17)
			s subOrderStartDate=$p($G(LinkPXList(sub1,sub2)),"^",4)
			s subOrderStartTime=$p($G(LinkPXList(sub1,sub2)),"^",5)
			s subOrderSkinTest=$p($G(LinkPXList(sub1,sub2)),"^",21)
			s subOrderStageCode=$p($G(LinkPXList(sub1,sub2)),"^",35)
			s subSpeedFlowRate=$p($G(LinkPXList(sub1,sub2)),"^",36)
			s subOrderFlowRateUnit=$p($G(LinkPXList(sub1,sub2)),"^",45)
			s subOrderFreqWeekStr=$p($G(LinkPXList(sub1)),"^",67)
			s GroupOrderSkinTestStr=GroupOrderSkinTestStr_"^"_subOrderSkinTest
			if (CFSameRecDepForGroup=1) {
				if (subRecDepRowid'=MainRecDepRowid)
				&&(subOrderPriorRowid'=OMOrderPriorRowid)
				&&(subOrderPriorRowid'=OMSOrderPriorRowid)
				&&(subOrderPriorRowid'=OMCQZTOrderPriorRowid)
				&&(subOrderPriorRowid'=OMLSZTOrderPriorRowid) {
					s rtnerrmesage=..%Translate("oeorder.oplistcustom.new.csp","主医嘱:")_MainOrderName_..%Translate("oeorder.oplistcustom.new.csp","和子医嘱:")_SubOrderName_"<br/>,"_..%Translate("oeorder.oplistcustom.new.csp","接收科室不一致!")
				}
			}
			if (mainOrderType="R")&&(subOrderType="R")  {
				if (mainFirstDayTimes'=subFirstDayTimes)   {
					s rtnerrmesage=..%Translate("oeorder.oplistcustom.new.csp","主医嘱:")_MainOrderName_..%Translate("oeorder.oplistcustom.new.csp","和子医嘱:")_SubOrderName_"<br>,"_..%Translate("oeorder.oplistcustom.new.csp","首日次数不一致!")
				}
				//流速判断
	            if (SpeedRateSeparateInstr'[("^"_subInstrRowid_"^")){
	                if mainSpeedFlowRate'=subSpeedFlowRate {
	                    if rtnerrmesage=""  s rtnerrmesage=..%Translate("oeorder.oplistcustom.new.csp","主医嘱:")_MainOrderName_..%Translate("oeorder.oplistcustom.new.csp","和子医嘱:")_SubOrderName_",<br>"_..%Translate("oeorder.oplistcustom.new.csp","输液流速不一致!")
	                    else  s rtnerrmesage=rtnerrmesage_","_..%Translate("oeorder.oplistcustom.new.csp","输液流速不一致!")
	                }
	                if mainOrderFlowRateUnit'=subOrderFlowRateUnit {
	                    if rtnerrmesage=""  s rtnerrmesage=..%Translate("oeorder.oplistcustom.new.csp","主医嘱:")_MainOrderName_..%Translate("oeorder.oplistcustom.new.csp","和子医嘱:")_SubOrderName_",<br>"_..%Translate("oeorder.oplistcustom.new.csp","流速单位不一致!")
	                    else  s rtnerrmesage=rtnerrmesage_","_..%Translate("oeorder.oplistcustom.new.csp","流速单位不一致!")
	                }   
	            }
				
			}
			if mainFreqRowid'=subFreqRowid  {
				if rtnerrmesage=""  s rtnerrmesage=..%Translate("oeorder.oplistcustom.new.csp","主医嘱:")_MainOrderName_..%Translate("oeorder.oplistcustom.new.csp","和子医嘱:")_SubOrderName_",<br>"_..%Translate("oeorder.oplistcustom.new.csp","频次不一致!")
				else  s rtnerrmesage=rtnerrmesage_","_..%Translate("oeorder.oplistcustom.new.csp","频次不一致!")
			}else{
				s WeekFlag="N"
				s:subFreqRowid'="" WeekFlag=$P(^PHCFR(subFreqRowid),"^",9)
				if (WeekFlag="Y")&&(subOrderFreqWeekStr'=mainOrderFreqWeekStr) {
					if rtnerrmesage=""  s rtnerrmesage=..%Translate("oeorder.oplistcustom.new.csp","主医嘱:")_MainOrderName_..%Translate("oeorder.oplistcustom.new.csp","和子医嘱:")_SubOrderName_",<br>"_..%Translate("oeorder.oplistcustom.new.csp","周频次星期不一致!")
					else  s rtnerrmesage=rtnerrmesage_","_..%Translate("oeorder.oplistcustom.new.csp","周频次星期不一致!")
				}
			}
			if (mainDurRowid'=subDurRowid)&&(WYInstr'[("^"_subInstrRowid_"^"))  {
				if rtnerrmesage=""  s rtnerrmesage=..%Translate("oeorder.oplistcustom.new.csp","主医嘱:")_MainOrderName_..%Translate("oeorder.oplistcustom.new.csp","和子医嘱:")_SubOrderName_",<br>"_..%Translate("oeorder.oplistcustom.new.csp","疗程不一致!")
				else  s rtnerrmesage=rtnerrmesage_","_..%Translate("oeorder.oplistcustom.new.csp","疗程不一致!")
			}
			if (mainInstrRowid'=subInstrRowid)&&(NotFollowInstr'[("^"_subInstrRowid_"^"))  {
				if rtnerrmesage=""  s rtnerrmesage=..%Translate("oeorder.oplistcustom.new.csp","主医嘱:")_MainOrderName_..%Translate("oeorder.oplistcustom.new.csp","和子医嘱:")_SubOrderName_",<br>"_..%Translate("oeorder.oplistcustom.new.csp","用法不一致!")
				else  s rtnerrmesage=rtnerrmesage_","_..%Translate("oeorder.oplistcustom.new.csp","用法不一致!")
			}
			if mainOrderStartDate'=subOrderStartDate  {
				if rtnerrmesage=""  s rtnerrmesage=..%Translate("oeorder.oplistcustom.new.csp","主医嘱:")_MainOrderName_..%Translate("oeorder.oplistcustom.new.csp","和子医嘱:")_SubOrderName_",<br>"_..%Translate("oeorder.oplistcustom.new.csp","开始日期不一致!")
				else  s rtnerrmesage=rtnerrmesage_","_..%Translate("oeorder.oplistcustom.new.csp","开始日期不一致!")
			}
			if mainOrderStageCode'=subOrderStageCode {
				if rtnerrmesage=""  s rtnerrmesage=..%Translate("oeorder.oplistcustom.new.csp","主医嘱:")_MainOrderName_..%Translate("oeorder.oplistcustom.new.csp","和子医嘱:")_SubOrderName_",<br>"_..%Translate("oeorder.oplistcustom.new.csp","医嘱阶段不一致!")
				else  s rtnerrmesage=rtnerrmesage_","_..%Translate("oeorder.oplistcustom.new.csp","医嘱阶段不一致!")
			}
			
		}
		if (mainInstrRowid'="")&&(SkinTestInstr[("^"_mainInstrRowid_"^")){
			if (GroupOrderSkinTestStr'["Y"){
				s TmpMsg=..%Translate("oeorder.oplistcustom.new.csp","序号")_mainOrderSeqNo_":"_MainOrderName
				if ($O(LinkPXList(sub1,""))'=""){
					s TmpMsg=TmpMsg_..%Translate("oeorder.oplistcustom.new.csp","及其子医嘱")
				}
				s TmpMsg=TmpMsg_..%Translate("oeorder.oplistcustom.new.csp","用法为皮试，请为需要置皮试结果的医嘱勾选皮试标识.")
				if rtnerrmesage=""  s rtnerrmesage=TmpMsg
				else  s rtnerrmesage=rtnerrmesage_","_TmpMsg
			}
		}
		
	}
	q rtnerrmesage
}

ClassMethod checkNeedDiagType(EpisodeID, User As %String, Type As %String, AllDiagType As %String = "N", IsDeathFlag = "")
{
	s retStr=0
	s CallBackFunStr=""
	if IsDeathFlag=1{
		s AdmHospitalId=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(EpisodeID)
		s NeedDeathTypeDiag=..%GetConfig("NeedDeathTypeDiag",AdmHospitalId)
		if (NeedDeathTypeDiag="1")&&('(..IsExistDeathTypeDiag(EpisodeID))){
			s ErrMsg=..%Translate("oeorder.oplistcustom.new.csp","死亡医嘱需要开立死亡类型的诊断.")
			s retStr="1^"_ErrMsg
			Q retStr
		}
	}
	s ret=..GetAbnormalOrder(EpisodeID,User, Type, AllDiagType,.CallBackFunStr)
	if CallBackFunStr'=""{
		s len=$L(CallBackFunStr,$C(2))
		for i=1:1:len{
			s OneCallBackFunStr=$P(CallBackFunStr,$C(2),i)
			s CallBackFunName=$P(OneCallBackFunStr,"^",1)
			if CallBackFunName="NeedDischgDiagnos"{
				s retStr="1^"_$P(OneCallBackFunStr,"^",2)
				Q
			}
		}
	}
	Q retStr
}

ClassMethod SaveOrderItems(Adm As %String, OrdItemStr As %String, User As %String, Loc As %String, Doc As %String, LABDATA As %String = "", ExpStr As %String = "", ByRef ErrMsg As %String = "", SessionStr As %String = "") As %Status
{
	s ^tempscl("SaveOrderItems")=Adm_","_OrdItemStr_","_User_","_Loc_","_Doc_","_LABDATA_","_ExpStr_","_SessionStr
	Set Ret=..InsertOrderItem(Adm,OrdItemStr,User,Loc,Doc,ExpStr,.ErrMsg,SessionStr)
	Q:(Ret=0)!(Ret=100) 100
	QUIT Ret
}

ClassMethod SaveOrderItemsCM(Adm As %String, OrdItemStr As %String, User As %String, Loc As %String, Doc As %String, LABDATA As %String = "", ExpStr As %String = "", ByRef ErrMsg As %String = "", SessionStr As %String = "") As %Status
{
	Set Config=##Class(websys.Configuration).%OpenId(1)
	Set MEDDATA=Config.DataNamespace
	Set LABDATA=Config.LabDataNamespace
	s PAADMType=$p($g(^PAADM(Adm)),"^",2)
	s orderrow=##Class(web.DHCDocOrderEntry).GetPAADMOrderRowid(Adm)
	s warning=##class(web.DHCDocOrderCommon).OrderLock(orderrow, SessionStr, "User.OEOrder", "")
	s:warning="" Warning=##Class(web.DHCDocViewDataInit).GetOrdEntryBaseWarning(Adm,SessionStr)
	if Warning'="" {
		s ErrMsg="-100"_$C(1)_Warning
		s Ret=100 QUIT Ret
	}
	;对于草药,住院和门诊的医嘱保存统一为一套程序
	Set Ret=$$InsertCMPresc^DHCDocOrderCommonNew(Adm,OrdItemStr,User,Loc,Doc,LABDATA)
	
	if (Ret=0)!(Ret=100) {
		d ##class(web.DHCDocOrderCommon).OrderEntryClearLock(SessionStr,"User.OEOrder")		//与orderLock对应
		q 100
	}
	d ..UpdateOrderStatus(Ret,Adm,User,Loc)
	;下医嘱后将病人状态置为到达
	s CFSetArriveByOrder=..%GetConfig("SetArriveByOrder")
	if CFSetArriveByOrder=1 d ##class(web.DHCDocOrderEntry).SetArrivedStatus(Adm,Doc,Loc,User)
	d ##class(web.DHCDocOrderCommon).OrderEntryClearLock(SessionStr,"User.OEOrder")		//与orderLock对应
	;保存审核医嘱相关基础代码使用次数
	d ##class(DHCDoc.Log.DHCDocCTUseCount).SaveOrdItemUseInfo(Ret,User,Loc)
	s rtn=..DHCHisInterface(Ret,Doc,Adm,User,Loc)
	QUIT Ret
}

// 108,10209,103||574,95

ClassMethod SavePractiseDocOrderItems(Adm As %String, User As %String, OrdItemStr As %String, loc As %String) As %Status
{
	s OrdItemStrAll=""
	s OrdItemStrAllNew=""
	s SubLeng=$L(OrdItemStr,"^")
	for OrdItemSub=1:1:SubLeng  d
	.s OrdID=$P(OrdItemStr,"^",OrdItemSub)
	.Q:OrdID=""
	.s statcode=$$GetStatCode(OrdID) ;防止停留时间内撤销医嘱
	.Q:(statcode="U")||(statcode="D")||(statcode="C")
	.s ArcimID=$P($G(^OEORD(+OrdID,"I",$P(OrdID,"||",2),1)),"^",2)
	.s PracticeConfirmStopStatus=$P($G(^OEORD(+OrdID,"I",$p(OrdID,"||",2),"DHC")),"^",51)
	.s OrdPracticeStopDate=$P($G(^OEORD(+OrdID,"I",$p(OrdID,"||",2),"DHC")),"^",70)
	.s OrdPracticeStopTime=$P($G(^OEORD(+OrdID,"I",$p(OrdID,"||",2),"DHC")),"^",71)
	.s OrdPracticeStopReasonDR=$P($G(^OEORD(+OrdID,"I",$p(OrdID,"||",2),"DHC")),"^",72)
	.s OrdPracticeStopReasonComtent=$P($G(^OEORD(+OrdID,"I",$p(OrdID,"||",2),"DHC")),"^",73)
	.if PracticeConfirmStopStatus'="" d
	..s PracticeConfirmStopStatusCode=$p(^OEC("OSTAT",PracticeConfirmStopStatus),"^",1)
	..if PracticeConfirmStopStatusCode="U" d
	...s ret=##class(appcom.OEOrdItem).UnUseMulti(OrdID,User,"","N",OrdPracticeStopReasonDR,OrdPracticeStopReasonComtent,"^"_OrdPracticeStopDate_"^"_OrdPracticeStopTime) //UnUse(OrdID,User)
	..else  if PracticeConfirmStopStatusCode="D" d 
	...s OrdID=OrdID_"!"_..%ZD(OrdPracticeStopDate)_"!"_..%ZT(OrdPracticeStopTime,1)
	...s ret=##class(appcom.OEOrdItem).StopMulti(OrdID,User,"","N")
	..else  if PracticeConfirmStopStatusCode="C" d 
	...s ret=##class(appcom.OEOrdItem).CancelMulti(OrdID,User,"","N",OrdPracticeStopReasonDR,OrdPracticeStopReasonComtent,"^"_OrdPracticeStopDate_"^"_OrdPracticeStopTime)
	..d ##class(appcom.OEOrdItem).UpdateExtIfPractice(OrdID,User,"","","1")
	.if statcode="I" d
	..s DocRowid=$p($g(^SSU("SSUSR",User)),"^",14)
	..s ret=$$UpdateOEOrdItem^DHCDocOrderCommonNew(OrdID,1,DocRowid,User)
	..s PracticeConfirmStopStatus=1 
	.Q:PracticeConfirmStopStatus="" 
	.s Str=ArcimID_"*"_OrdID_"*V"
	.if OrdItemStrAll=""  s OrdItemStrAll=Str
	.else  s OrdItemStrAll=OrdItemStrAll_"^"_Str
	.i OrdItemStrAllNew="" s OrdItemStrAllNew=OrdID
	.e  s OrdItemStrAllNew=OrdItemStrAllNew_"^"_OrdID
	.s Link=0
	.f  s Link=$O(^OEORDi(0,"OEORI",+OrdID,OrdID,Link)) Q:Link=""  d
	..s LikOrdID=+OrdID_"||"_Link
	..s statcode=$$GetStatCode(LikOrdID)
	..//Q:(statcode="U")||(statcode="D")||(statcode="C")
	..s ArcimID=$P($G(^OEORD(+OrdID,"I",Link,1)),"^",2)
	..s Str=ArcimID_"*"_LikOrdID_"*V"
	..s OrdItemStrAll=OrdItemStrAll_"^"_Str
	..i OrdItemStrAllNew="" s OrdItemStrAllNew=LikOrdID
	..e  s OrdItemStrAllNew=OrdItemStrAllNew_"^"_LikOrdID
	//此方法是为了生成标本/处方号,新版流程是调用审核医嘱生成,此处不再调用
	//d verifypresno3^DHCaOET1(Adm,User,OrdItemStrAll,loc)
	if (OrdItemStrAllNew'="") d
    .for i=1:1:$L(OrdItemStrAllNew,"^")  d
    ..s OrdID1=$P(OrdItemStrAllNew,"^",i)
    ..Q:OrdID1=""
    ..///医生审核实习医生医嘱时调用平台组方法
    ..d ##class(web.DOC.PortalService).TaskNeedAuditOEItem("S00000028",OrdID1,2,Adm)
    ..s PrescNo=$p($g(^OEORD(+OrdID1,"I",$p(OrdID1,"||",2),1)),"^",14)
    ..i PrescNo'="" d //草药处方追踪
    ...s IsCMPresType = ##Class(web.DHCDocPrescript).IsPrescType(PrescNo)
    ...s LinkOrderItem=$p($g(^OEORD(+OrdID1,"I",$p(OrdID1,"||",2),11)),"^",39)
    ...i IsCMPresType="1",LinkOrderItem="" d ##class(web.DHCINPHA.HMPresTrack.SqlDbPresTrack).HandlePresTrackDB(OrdID1_"^"_""_"^"_""_"^"_"A1"_"^"_loc_"^"_User)
	;停止互斥医嘱
	do ..StopConflict(Adm,OrdItemStrAll,User,loc)
	;自动停止长期医嘱
	d ..StopLongOrder(Adm,OrdItemStrAll,User,loc)
	Q 0
GetStatCode(OrderID)
	s statcode=""
	s Stat=$P($G(^OEORD(+OrderID,"I",$P(OrderID,"||",2),1)),"^",13)
	s:Stat'="" statcode=$p($g(^OEC("OSTAT",Stat)),"^",1)
	Q statcode
}

ClassMethod SelectOrderItem(OrderItemRowid As %String) As %String
{
	s PackQty=0
	s FrequenceRowid=""
	s DurationRowid=""
	s InstructionRowid=""
	s DoseQty=""
	s DoseUOM=""
	s OrderRowid=$p(OrderItemRowid,"||",1)
	s Childsub=$p(OrderItemRowid,"||",2)
	s ArcimRowid=$p(^OEORD(OrderRowid,"I",Childsub,1),"^",2)
	s ItemCatDR=$p($g(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),1)),"^",10)
	s OrderType=$P(^ARC("IC",ItemCatDR),"^",7)
	i (OrderType="R") d
	.i '$d(^OEORD(OrderRowid,"I",Childsub,9)) s PackQty=0
	.e  d
	..s PackQty=$p(^OEORD(OrderRowid,"I",Childsub,9),"^",4)
	..if $d(^OEORD(OrderRowid,"I",Childsub,2)) d
	...s FrequenceRowid=$p($G(^OEORD(OrderRowid,"I",Childsub,2)),"^",4)
	...s DurationRowid=$p($g(^OEORD(OrderRowid,"I",Childsub,2)),"^",6)
	...s InstructionRowid=$p($g(^OEORD(OrderRowid,"I",Childsub,2)),"^",7)
	...s DoseQty=$p($g(^OEORD(OrderRowid,"I",Childsub,2)),"^",1)
	...s DoseUOM=$p($g(^OEORD(OrderRowid,"I",Childsub,2)),"^",3)
	.;s DrgformRowid=..GetDrgForm(ArcimRowid)
	.;s PackQty=..GetPackqty(ArcimRowid,DrgformRowid, FrequenceRowid , PriorRowid, DurationRowid, DoseQty, DosUOM)
	e  s PackQty=$p($g(^OEORD(OrderRowid,"I",Childsub,1)),"^",12)
	s ret=PackQty_"^"_DoseQty_"^"_DoseUOM_"^"_FrequenceRowid_"^"_DurationRowid_"^"_InstructionRowid
	Q ret
}

/// 停止医嘱
ClassMethod Stop(OrdItmRowId As %String, UserRowId As %String, IsStopChild As %String = "1", ExpStr As %String = "", ByRef ErrMsg As %String = "") As %String
{
	;w ##class(web.DHCOEOrdItem).Stop("531546||1",590)
	s SttDate=$p($g(^OEORD(+OrdItmRowId,"I",+$p(OrdItmRowId,"||",2),1)),"^",9)
	s SttTime=$p($g(^OEORD(+OrdItmRowId,"I",+$p(OrdItmRowId,"||",2),1)),"^",10)

	s CurrDate=..%SysDate()
	s CurrTime=..%SysTime()
	
	;如果将提前开始日期大于今日的医嘱停止,将停止日期置为开始日期,这样计费好处理
	if (CurrDate<SttDate) {
		s CurrDate=SttDate
	}
	s Adm=$p($g(^OEORD(+OrdItmRowId)),"^",1)
	s PAADMType=$p($g(^PAADM(Adm)),"^",2)
	s StatusRowId=$O(^OEC("OSTAT",0,"Code","D",0))
	s UserEMVirtualtLong=##Class(web.DHCDocOrderVirtualLong).GetUserEMVirtualtLong(Adm)
	s DCARowID=##class(DHCDoc.DHCDocCure.OutInterface).GetCureApplyByOrd(OrdItmRowId)
	&SQL(Select SSUSR_CareProv_DR into :DoctorRowId from SQLUser.SS_User where SSUSR_RowId=:UserRowId )
	TS
	s err=..UpdateStatus(OrdItmRowId,UserRowId,StatusRowId)
	if err {
		s ErrMsg=..%GetErrCodeMsg("-100005")
		Q "-100005" //err
	}
	
	s BillFlag=$p($g(^OEORD(+OrdItmRowId,"I",+$p(OrdItmRowId,"||",2),3)),"^",5)
	i " B TB "[(" "_BillFlag_" ") s BillFlag="I"
	;药理实验项目是否直接计费
	s CFEntryOrdBillPad=##class(web.PilotProject.DHCDocPPGroupSeting).GetConfigNode("EntryOrdBillPad")
	;药理项目已经收费停医嘱查询能作废和停医嘱
	s PilotProflag=$p($G(^OEORD(+OrdItmRowId,"I",$p(OrdItmRowId,"||",2),"DHC")),"^",10)
	i (CFEntryOrdBillPad=1)&&(PilotProflag'="") s BillFlag=$p($g(^OEORD(+OrdItmRowId,"I",+$p(OrdItmRowId,"||",2),3)),"^",5)
	
	if DoctorRowId="" { 
		&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime,OEORI_Billed=:BillFlag where OEORI_rowid=:OrdItmRowId)
	}else{
		&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime,OEORI_XCTCP_DR=:DoctorRowId,OEORI_Billed=:BillFlag where OEORI_rowid=:OrdItmRowId)
	}
	if SQLCODE TRo  Q SQLCODE
	;手工增加索引,护士站用?OE_OrdItem原有结构不存在此索引
	s ^OEORDi(0,"DHCXDate",CurrDate,+OrdItmRowId,$p(OrdItmRowId,"||",2))=""
	if DCARowID=""{
		//停止所有执行记录
		//Modify 20210401
		//治疗申请的医嘱执行记录的在DHCDoc.DHCDocCure.Apply.cls CancelCureApplyByStopOrd中处理
		s err=##Class(appcom.OEOrdExec).DiscontinueAll(OrdItmRowId,UserRowId,"1","N","Y")
		//d ##class(web.DHCOEDispensing).Return(OrdItmRowId)
	}
	if err{
		TRo  
		s ErrMsg=..%GetErrCodeMsg("-100074")_err
		Q "-100074" //err
	}
	;调用服务总线接口(调用平台组接口、调用检查申请取消接口、pacs工作站停医嘱接口、调用医政接口改变临床路径医嘱状态)
	s rtn=##class(DHCDoc.Interface.Inside.Invoke).CancelOrdInterface(OrdItmRowId,UserRowId,1)
	;撤销医嘱外部接口(撤销医疗结算、治疗申请单、会诊等申请;调用药房追踪接口;药理项目取消免费;取消划扣)
	s err=##class(appcom.OEOrdItem).CancelOrdDocInterface(OrdItmRowId,UserRowId,.ErrMsg)
	if +err'=0  Tro  Q err
	s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,0))
	While (Sub'="")&&(IsStopChild="1") {
		s SubRowId=+OrdItmRowId_"||"_Sub
		s err=..UpdateStatus(SubRowId,UserRowId,StatusRowId)
		if err {
			Quit
		}
		if DoctorRowId="" { 
			&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime,OEORI_Billed=:BillFlag where OEORI_rowid=:SubRowId)
		}else{
			&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime,OEORI_XCTCP_DR=:DoctorRowId,OEORI_Billed=:BillFlag where OEORI_rowid=:SubRowId)
		}
		if SQLCODE {
			s err=SQLCODE
			Quit
		}
		if DCARowID=""{
			//停止所有执行记录
			//Modify 20210401
			//治疗申请的医嘱执行记录的在DHCDoc.DHCDocCure.Apply.cls CancelCureApplyByStopOrd中处理
			d ##Class(appcom.OEOrdExec).DiscontinueAll(SubRowId,UserRowId,"1","N","Y")
		}
		/*
		if (UserEMVirtualtLong=1){
			d ##Class(appcom.OEOrdExec).DiscontinueAll(SubRowId,UserRowId,"1","N","Y")    
		}else{
			d ##class(web.DHCOEDispensing).Return(SubRowId)
		}
		*/
		;撤销医嘱外部接口(撤销医疗结算、治疗申请单、会诊等申请;调用药房追踪接口;药理项目取消免费;取消划扣)
		s err=##class(appcom.OEOrdItem).CancelOrdDocInterface(SubRowId,UserRowId)
		if +err'=0 Quit
		;调用服务总线接口(调用平台组接口、调用检查申请取消接口、pacs工作站停医嘱接口、调用医政接口改变临床路径医嘱状态)
		s rtn=##class(DHCDoc.Interface.Inside.Invoke).CancelOrdInterface(SubRowId,UserRowId)
		s ^OEORDi(0,"DHCXDate",CurrDate,+OrdItmRowId,Sub)=""
		s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,Sub))
	}
	i err {
		TRo  
		s ErrMsg=..%GetErrCodeMsg(err)
		Q err
	}
	//治疗医嘱的绑定医嘱
	s Sub=$o(^OEORDi(0,"SERORD",OrdItmRowId,+OrdItmRowId,0))
	While (Sub'="")&&(IsStopChild="1") {
		s SubRowId=+OrdItmRowId_"||"_Sub
		s err=..UpdateStatus(SubRowId,UserRowId,StatusRowId)
		if err {
			Quit
		}
		if DoctorRowId="" { 
			&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime,OEORI_Billed=:BillFlag where OEORI_rowid=:SubRowId)
		}else{
			&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime,OEORI_XCTCP_DR=:DoctorRowId,OEORI_Billed=:BillFlag where OEORI_rowid=:SubRowId)
		}
		if SQLCODE {
			s err=SQLCODE
			Quit
		}
		d ##class(web.DHCOEDispensing).Return(SubRowId)		
		s ^OEORDi(0,"DHCXDate",CurrDate,+OrdItmRowId,Sub)=""
		;调用服务总线接口(调用平台组接口、调用检查申请取消接口、pacs工作站停医嘱接口、调用医政接口改变临床路径医嘱状态)
		s rtn=##class(DHCDoc.Interface.Inside.Invoke).CancelOrdInterface(SubRowId,UserRowId)
		;撤销医嘱外部接口(撤销医疗结算、治疗申请单、会诊等申请;调用药房追踪接口;药理项目取消免费;取消划扣)
		s err=##class(appcom.OEOrdItem).CancelOrdDocInterface(SubRowId,UserRowId)
		if +err'=0 Quit
		s Sub=$o(^OEORDi(0,"SERORD",OrdItmRowId,+OrdItmRowId,Sub))
	}
    i err {
	    TRo  
	    s ErrMsg=..%GetErrCodeMsg(err)
	    Q err
	}
	TC
	Q 0
}

ClassMethod StopLongOrder(Adm As %String, OrderStr As %String, User As %String, Loc As %String = "")
{
	n (Adm,OrderStr,User,Loc)
	s StopAfterLongOrder=0
	s UserEMVirtualtLong=##Class(web.DHCDocOrderVirtualLong).GetUserEMVirtualtLong(Adm)
	s PAADMType=$p($g(^PAADM(Adm)),"^",2)
	s OrderRowId=##Class(web.DHCDocOrderEntry).GetPAADMOrderRowid(Adm)
	//停今日及以后长期医嘱设置
	f k=1:1:$l(OrderStr,"^") {
		s ArcimRowId=$p($p(OrderStr,"^",k),"*",1)
		s newOrdIdDR=$p($p(OrderStr,"^",k),"*",2)
		i ArcimRowId="" continue
		s statcode="V"
		s TtemStat=$P($G(^OEORD(+newOrdIdDR,"I",+$p(newOrdIdDR,"||",2),1)),"^",13)
		i TtemStat'="" d
		.s statcode=$p($g(^OEC("OSTAT",TtemStat)),"^",1)
		continue:statcode'="V"
		s ARCIMExtInfo=##class(DHCDoc.DHCDocConfig.ARCIMExt).getARCIMConfig(ArcimRowId)
		s StopAfterLongOrder=$P(ARCIMExtInfo,"^",3)
		i StopAfterLongOrder=1 Quit
	}
	s SttDate=$p($g(^OEORD(+newOrdIdDR,"I",+$p(newOrdIdDR,"||",2),1)),"^",9)
	s SttTime=$p($g(^OEORD(+newOrdIdDR,"I",+$p(newOrdIdDR,"||",2),1)),"^",10)
	if StopAfterLongOrder=1 {
		if (PAADMType="I"){
			d ##class(web.UDHCStopOrderLook).StopOrdersBySpecOrder(newOrdIdDR,User,SttDate,SttTime,Loc,"N")
		}elseif (UserEMVirtualtLong="1"){
			s SttDateHtml=..%ZD(SttDate)
			s SttTimeHtml=..%ZT(SttTime,1)
			d ##Class(web.DHCDocOrderVirtualLong).StopAllVirtualtLong(Adm,User,SttDateHtml,SttTimeHtml)
		}
		d ##Class(web.UDHCJFBILL).BILLN(Adm,User,"")
	}
	/*	此设置已经不用
	s StopPreLongOrder=0
	f k=1:1:$l(OrderStr,"^")-1 {
		s ArcimRowId=$p($p(OrderStr,"^",k),"*",1)
		i ArcimRowId="" continue
		s StopPreLongOrder=$P($G(^ARCIM(+ArcimRowId,$P(ArcimRowId,"||",2),"DHC")),"^",1)
		i StopPreLongOrder=1 Quit
	}
	if StopPreLongOrder=1 {
		s StartDate=..%SysDate()
		s EndDate=..%SysDate()
		s inter=##class(web.UDHCStopOrderLook).GetInterOfFreqOrd(Adm)
		i inter'="1" s EndDate=EndDate+inter
		f OrderStartDate=StartDate:1:EndDate {
			s child=0  f  s child=$O(^OEORDi(0,"StDt",OrderStartDate,OrderRowId,child)) Q:child=""  d
			.s arcim=$P(^OEORD(OrderRowId,"I",child,1),"^",2)
			.s prior=$P(^OEORD(OrderRowId,"I",child,1),"^",8)
			.s priorcode=$P($G(^OECPR(prior)),"^",1)
			.Q:(priorcode'="S")&&(priorcode'="OMST")
			.s OrderStatus=$p(^OEC("OSTAT",$p(^OEORD(OrderRowId,"I",child,1),"^",13)),"^",1)
			.Q:OrderStatus'="V"
			.s arcimnotstop=$P($G(^ARCIM(+arcim,$P(arcim,"||",2),"DHC")),"^",2)
			.s oeitem=OrderRowId_"||"_child
			.i arcimnotstop'=1 d ..Stop(oeitem,User)
		}
	}
	*/
}

ClassMethod StopOrderItem(OrdList, UserID, PinNumber)
{
	s ret=..PinNumberValid(UserID, PinNumber)
	Q:ret'=0 ret
	s oldnamespace=$ZNSPACE
	s datanamespace=$LIST(^websys.ConfigurationD(1),12)
	zn datanamespace
	s len=$l(OrdList,"^")
	s err=0
	for i=1:1:len  {  
		s oeitm=$p(OrdList,"^",i)
		s err=$$discon^SMLPrescLook(oeitm, UserID, PinNumber)
		i err'=0 quit  
		s err=$$Collect^SMLPrescLook(oeitm)
	}
	zn oldnamespace
	Q err
}

/// 更新设备的计数,已经不用
ClassMethod UpdateEQASByOrderItem(OrderItemRowId As %String, Type As %String) As %String
{
	Q 0
	;Type=0 收费  Type=1 退费
	/*
	s ArcimRowId=$P(^OEORD(+OrderItemRowId,"I",$P(OrderItemRowId,"||",2),1),"^",2)
	s RecLocRowId=$P(^OEORD(+OrderItemRowId,"I",$P(OrderItemRowId,"||",2),3),"^",6)
	Q:RecLocRowId="" 0
	if (Type'=1){
		s FindASRowId=##Class(web.DHCRBApptSchedule).FindEQAvailAS(ArcimRowId,RecLocRowId)
		Q:FindASRowId=0 0
		Q:FindASRowId="" 100
		if FindASRowId'=""	{
			s err=##Class(web.DHCRBApptSchedule).UpdatePatIn(FindASRowId,1)
			s $P(^OEORD(+OrderItemRowId,"I",$P(OrderItemRowId,"||",2),"DHC"),"^",2)=FindASRowId
		}
	}else{
		Q:'$d(^OEORD(+OrderItemRowId,"I",$P(OrderItemRowId,"||",2))) 0
		s FindASRowId=$P(^OEORD(+OrderItemRowId,"I",$P(OrderItemRowId,"||",2),"DHC"),"^",2)
		Q:FindASRowId="" 0
		s err=##Class(web.DHCRBApptSchedule).UpdatePatIn(FindASRowId,-1)
	}
	Q err
	*/
}

/// 更新医嘱执行表
ClassMethod UpdateExec(ID As %String, UserRowId As %String) As %String
{
	;w ##class(web.DHCOEOrdItem).UpdateExec("205935||5||1")
	s CurrDate=..%SysDate()
	s CurrTime=..%SysTime()
	s STATRowId=$O(^OEC("STAT",0,"Code","E",0))
	
	&SQL(Select SSUSR_CareProv_DR into :DocRowId From SQLUser.SS_User Where SSUSR_RowId=:UserRowId)
	&SQL(Update SQLUser.OE_OrdExec 
	set OEORE_DateExecuted=:CurrDate,
		OEORE_TimeExecuted=:CurrTime,
		OEORE_Order_Status_DR=:STATRowId,
		OEORE_CTPCP_DR=:DocRowId
	Where OEORE_RowId=:ID)
	Q SQLCODE
}

ClassMethod UpdateOrderItem(OrderItemRowid As %String, PackQty As %String, DoseQty As %String, DoseUOMDR As %String, FrequenceDR As %String, DurationDR As %String, InstructionDR As %String) As %String
{
	s OrderRowid=$P(OrderItemRowid,"||",1)
	s Childsub=$P(OrderItemRowid,"||",2)
	s ArcimRowid=$p(^OEORD(OrderRowid,"I",Childsub,1),"^",2)
	s ItemCatDR=$p(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),1),"^",10)
	s OrderType=$P(^ARC("IC",ItemCatDR),"^",7)
	i (OrderType="R") d
	.if PackQty'="" s $P(^OEORD(OrderRowid,"I",Childsub,9),"^",4)=PackQty
	.if DoseQty'="" d
	..s $P(^OEORD(OrderRowid,"I",Childsub,2),"^",1)=DoseQty
	..s $P(^OEORD(OrderRowid,"I",Childsub,2),"^",3)=DoseUOMDR
	.if FrequenceDR'="" s $P(^OEORD(OrderRowid,"I",Childsub,2),"^",4)=FrequenceDR
	.if DurationDR'="" s $P(^OEORD(OrderRowid,"I",Childsub,2),"^",6)=DurationDR
	.if InstructionDR'="" s $P(^OEORD(OrderRowid,"I",Childsub,2),"^",7)=InstructionDR
	e  d
	.if PackQty'="" s $P(^OEORD(OrderRowid,"I",Childsub,1),"^",12)=PackQty
}

/// called from order summary screen
ClassMethod UpdateOrderStatus(OEOrdItemIDs As %String, EpisodeID As %String = "", UserID As %String, Loc As %String = "")
{
	n (OEOrdItemIDs,EpisodeID,UserID,Loc,%session)
	s CurLogonHosp =$p($g(^CTLOC(Loc)),"^",22)
	;Set %request= ##class(%CSP.Request).%New()
	;d ..printRequestData()
	s Hospital=..%GetConfig("CurrentHospital",CurLogonHosp)
	i Hospital'="" s HospitalCode=$P(Hospital,"^",1)
	e  s HospitalCode=""
	Q:EpisodeID=""
	s PAADMType=$p($g(^PAADM(EpisodeID)),"^",2)
	Set Admloc=$P($g(^PAADM(EpisodeID)),"^",4)
	s PracticeDocOrderNeedVerify=..%GetConfig("PracticeDocOrderNeedVerify",CurLogonHosp)
	;如果是实习医生医嘱不能审核?
	s CTPCPRowId=$P($G(^SSU("SSUSR",UserID)),"^",14)
	s CarPrvTypeCode=""
	i CTPCPRowId'="" d
	.s CarPrvTypeRowid=$P($g(^CTPCP(CTPCPRowId,1)),"^",4)
	.s CarPrvTypeCode=$P($g(^CT("CPT",+CarPrvTypeRowid)),"^",1)
	Q:(PracticeDocOrderNeedVerify=1)&(PAADMType="I")&(CarPrvTypeCode="PRACTICE")
	;s ^zhou("Para")=OEOrdItemIDs_"^"_EpisodeID
	;s ^zhou("code")=PracticeDocOrderNeedVerify_"^"_PAADMType_"^"_CarPrvTypeCode_"^"
	s NewOrderUpdate=..%GetConfig("NewOrderUpdate",CurLogonHosp)
	i NewOrderUpdate'=1 d ##class(web.OEOrder).UpdateOrderStatus(OEOrdItemIDs,EpisodeID,UserID,Loc)
	s BillAfterUpdate=..%GetConfig("CheckIPDeposit",CurLogonHosp)
	if PAADMType="I",BillAfterUpdate="1" d
	.s OrdIdDRStr=""
	.f k=1:1:$l(OEOrdItemIDs,"^")-1 d
	. . s newOrdIdDR=$p($p(OEOrdItemIDs,"^",k),"*",2)
	. . i OrdIdDRStr="" s OrdIdDRStr=newOrdIdDR
	. . e  s OrdIdDRStr=OrdIdDRStr_"^"_newOrdIdDR
	. //s rtn=##Class(web.UDHCJFBILL).BILLN(EpisodeID,UserID,"")
	. s rtn=##Class(web.UDHCJFBILL).BILLN(EpisodeID,UserID,"")

	Q:(HospitalCode="NB")!(HospitalCode="BJZYY")!(HospitalCode="")
	s OrderRowid=$o(^OEORD(0,"Adm",+EpisodeID,""))
	s InsTypeDR=""
	
	s findAppendItemCat="N"
	s findAppendItem="N"
	k ^CacheTemp("DHCAppendItem",$j)
	k ^CacheTemp("DHCFindAppendItemCat",$j)
	k ^CacheTemp("DHCFindAppendItem",$j)
	
	s SttDate=..%SysDate()
	s AppendItemCat=..%GetConfig("AppendItemCat",CurLogonHosp)
	s AppendItemInItemCat=..%GetConfig("AppendItemInItemCat",CurLogonHosp)
	;s itemsub=0 f  s itemsub=$o(^OEORD(OrderRowid,"I",itemsub)) q:(itemsub="")  d
	if (AppendItemCat'="" && AppendItemInItemCat'=""){
		s itemsub=0 f  s itemsub=$o(^OEORDi(0,"StDt",SttDate,OrderRowid,itemsub)) q:(itemsub="")  d
		.s itemstat=$p($g(^OEORD(OrderRowid,"I",itemsub,1)),"^",13)
		.i itemstat'="" d
		..s statcode=$p($g(^OEC("OSTAT",itemstat)),"^",1)
		.Q:($g(statcode)'="V")&($g(statcode)'="E")
		.s ArcimRowid=$p($g(^OEORD(OrderRowid,"I",itemsub,1)),"^",2)
		.s ReclocRowid=$p($g(^OEORD(OrderRowid,"I",itemsub,3)),"^",6)
		.s ItemCat=$p(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),1),"^",10)
		.s BillTypeRowid=$p($g(^OEORD(OrderRowid,"I",itemsub,11)),"^",18)
		.;
		.i (AppendItemCat'="")&(("^"_AppendItemCat_"^")[("^"_ItemCat_"^")) d
		.. s ^CacheTemp("DHCFindAppendItemCat",$j,"RecLoc",ReclocRowid)=BillTypeRowid
		. i (AppendItemInItemCat'="")&(("^"_AppendItemInItemCat_"^")[("^"_ArcimRowid_"^")) d
		.. s ^CacheTemp("DHCFindAppendItem",$j,"RecLoc",ReclocRowid)=""
	
		s AppendItemCount=0
		s ReclocRowid="" f  s ReclocRowid=$o(^CacheTemp("DHCFindAppendItemCat",$j,"RecLoc",ReclocRowid)) Q:ReclocRowid=""  d
		.s BillTypeRowid=^CacheTemp("DHCFindAppendItemCat",$j,"RecLoc",ReclocRowid)
		.i ('$d(^CacheTemp("DHCFindAppendItem",$j,"RecLoc",ReclocRowid)))&(AppendItemInItemCat'="") d
		..s AppendItemCount=$LENGTH(AppendItemInItemCat,"^")
		..f i=1:1:AppendItemCount d
		...s AppendItemRowid=$P(AppendItemInItemCat,"^",i)
		...s OrdItemStr=AppendItemRowid_"^1"_"^"_ReclocRowid_"^^^"_BillTypeRowid
		...s User=UserID
		...s DocUserId=UserID
		...s OSRID=""	;ARC_OrdSets
		...s rtnvalue=##class(web.DHCOPCashier).CashierInsertOrdItem(EpisodeID,OrdItemStr,User,Loc,DocUserId,OSRID)
		...s rtn=$p(rtnvalue,"^",1)
		i AppendItemCount>0 s rtn=##class(web.DHCOPCashier).CreatePrescNo(EpisodeID,UserID,Admloc)
	}
	;取血费Rowid
	Q:HospitalCode'="HF"
	quit
}

/// 更新医嘱状态
ClassMethod UpdateStatus(OrdItmRowId As %String, UserRowId As %String, StatusRowId As %String) As %String
{
	n (OrdItmRowId,UserRowId,StatusRowId)
 	;医嘱RowId,用户RowId
	s CurrDate=..%SysDate()
	s CurrTime=..%SysTime()
	TS
	&sql(Update SQLUser.OE_OrdItem set OEORI_ItemStat_DR=:StatusRowId where OEORI_RowId=:OrdItmRowId)
	if SQLCODE TRollback  q SQLCODE
	&sql(insert into SQLUser.OE_OrdStatus (ST_ParRef,ST_Date,ST_Time,ST_Status_DR,ST_User_DR )
	values (:OrdItmRowId,:CurrDate,:CurrTime,:StatusRowId,:UserRowId))
	if SQLCODE TRollback  q SQLCODE
	TC
	Q SQLCODE
}

/// 此方法已经作废,调用d verifypresno3^DHCaOET1处理
/// Notes by guorongyong 2017.6.15
ClassMethod VerifyOrderItem(Adm As %String, User As %String, OrdItemStr As %String, loc As %String) As %Status
{
	Set Config=##Class(websys.Configuration).%OpenId(1)
	Set MEDDATA=Config.DataNamespace
	Set LABDATA=Config.LabDataNamespace
	Set CurrentNS=$ZNSPACE
	ZN MEDDATA		
	do verifypresno3^aOET1(Adm,User,OrdItemStr,loc)
	ZN CurrentNS
	QUIT 0
}

ClassMethod printRequestData()
{
	s rName="",rIndex="",rValue=""
	s rData=""
	for  s rName=$o(%request.Data(rName))  q:rName=""  d 
	. s rIndex=""
	. for  s rIndex=$o(%request.Data(rName,rIndex))  q:rIndex=""  d
	. . s rValue=%request.Data(rName,rIndex)
	. . s rData=rData _ $c(10,13)_ "(" _rName_","_rIndex_")="_rValue
	s ^zhou("temp",$zn)=rData
}

/// w ##class(web.DHCOEOrdItem).websysSaveOETabsOne("600^63^28^1^3^1038||1^W50008")
ClassMethod websysSaveOETabsOne(other As %Library.String)
{
	s ^tmpgry("websysSaveOETabsOne")=other
	//模版中的某一页,单独追加模板到模一个列表中
	s flag=1,i=0,j=0,grouponenew="",comprefnew="",firstitem=""
	s userid=$p(other,"^",1)  ;
	s ctlocid=$p(other,"^",2)  ;"OEOrder.PrefTabs.EditList" ;
	s groupid=$p(other,"^",3)
	s currTab=$p(other,"^",4)
	s lstidx=$p(other,"^",5)
	s lstidx=lstidx+1
	s arcimdr=$p(other,"^",6)
	s CONTEXT=$p(other,"^",7)
	
	s p1="ORDER"
	s p2="OEOrder.PrefTabs.EditList"
	s p3="User.SSUser"
	s p4="User.CTLoc"
	s p5="User.SSGroup"
	s compref=""
	
	;1.按有工作流上下文查
	s PrefType=##class(epr.PreferencesQuery).GetPrefTypeByLoc(ctlocid)
	s appKey="ORDER"_CONTEXT
	s appKeyUser=appKey_PrefType 
	s id=$$GetPreferencesId()
	if id="" {
		;2.按无工作流上下文查
		s CONTEXT=""
		s appKey="ORDER"_CONTEXT
		s appKeyUser=appKey_PrefType
		s id=$$GetPreferencesId()
	}
	
	q:(id="") flag
	if id'="" d
 	.Set pref =##class(websys.Preferences).%OpenId(id)
 	.Set compref = pref.Data
 	.b ;1
	.s comprefall=$LIST(compref,3)   //去除lb
	.s groupll=$LL(comprefall)
	.f i=1:1:groupll  d
	..s groupone=$LIST(comprefall,i)
	..i i=currTab d
	...s listll=$L(groupone,$C(1))
	...b ;2
	...f j=1:1:listll d
	....s listone=$p(groupone,$C(1),j)
	....b ;3
	....i j=lstidx d
	.....s firstitem=$p(listone,$C(28),2)  //可用$LL判断
	.....if firstitem="" d   //对插入原本空模板列表的判断
	......s listone=listone_"ARCIM"_$C(4)_arcimdr
	.....e  d
	......s listone=listone_$C(28)_"ARCIM"_$C(4)_arcimdr
	....i grouponenew="" d
	.....s grouponenew=listone
	....e  d
	.....s grouponenew=grouponenew_$C(1)_listone
	...s groupone=grouponenew
	..b ;4
	..i comprefnew="" d
	...s comprefnew=$LB(groupone)
	..e  d
	...s comprefnew=comprefnew_$LB(groupone)
	.b ;5
	.s compref=comprefnew
	.s compref=$LB(,,compref)
	.s pref.Data=compref
	.Do pref.%Save()
 .s flag=0
 Quit flag
GetPreferencesId()
	s id=""
	//个人
	&sql(select ID into:id from websys.Preferences where AppSubKey=:p2 and ObjectType=:p3 and ObjectReference=:userid and AppKey=:appKeyUser)
	//科室
	if id="" d  
	.&sql(select ID into:id from websys.Preferences where AppSubKey=:p2 and ObjectType=:p4 and ObjectReference=:ctlocid and AppKey=:appKey)
	//安全组
	if id="" d 
	.&sql(select ID into:id from websys.Preferences where AppSubKey=:p2 and ObjectType=:p5 and ObjectReference=:groupid and AppKey=:appKey)
	Q id
}

Query FindAdmOrderItems(EpisodeID As %String, SttDate As %String, EndDate As %String, PriorID As %String, CTLOCRowId As %String, GOrderName As %String, DocNameID As %String, Adm As %String, Drug As %String, Lab As %String, Exam As %String, Cure As %String, GOrderNameID As %String = "") As %Library.Query(CONTAINID = "", ROWSPEC = "OrderName:%String,OrderStatus:%String,OrderPrior:%String,OrderStartDate:%String,OrderStartTime:%String,OrderDoseQty:%String,OrderDoseUOM:%String,OrderFreq:%String,OrderInstr:%String,OrderDur:%String,OrderPrice:%String,OrderPackQty:%String,OrderPackUOM:%String,OrderSkinTest:%String,OrderRecDep:%String,OrderUserDep:%String,OrderOrdDep:%String,OrderSum:%String,OrderPrescNo:%String,OrderDepProcNote:%String,OrderDoc:%String,OrderUserAdd:%String,OrderDate:%String,OrderSeqNo:%String,OrderMasterSeqNo:%String,OrderLinkTo:%String,OrderLabEpisodeNo:%String,OrderItemRowid:%String,OrderARCIMRowid:%String,OrderSttDate:%String,OrderDoseUOMRowid:%String,OrderFreqRowid:%String,OrderPriorRowid:%String,OrderInstrRowid:%String,OrderDurRowid:%String,OrderPackUOMRowid:%String,OrderRecDepRowid:%String,OrderUserDepRowid:%String,OrderOrdDepRowid:%String,OrderStatusRowid:%String,OrderBaseUOMRowid:%String,OrderDocRowid:%String,OrderUserAddRowid:%String,OrderARCOSRowid:%String,OrderDrugFormRowid:%String,OrderMaxDurRowid:%String,OrderType:%String,OrderBillTypeRowid:%String,OrderMaxDurRowid:%String,OrderBillType:%String,OrderFreqFactor:%String,OrderFreqInterval:%String,OrderDurFactor:%String,LinkOrderItem:%String,EpisodeID:%String,OrderBillTypeRowId:%String,OrderItemInValid:%String")
{
}

Query FindExec(orditem As %String) As %SQLQuery(CONTAINID = 1, ROWSPEC = "ID,OEOREOrderStatusDR:%String,OEOREOrderStatusDesc:%String,OEOREDateExecuted:%Date,OEORETimeExecuted:%Time,OEOREQtyAdmin:%Float,CTUOMDesc:%String,OEORECTPCPDR:%String,OEORECTPCPDesc:%String")
{
	SELECT OEORE_RowID, OEORE_Order_Status_DR,OEORE_Order_Status_DR->STAT_Desc,OEORE_DateExecuted, OEORE_TimeExecuted, OEORE_QtyAdmin, OEORE_CTUOM_DR->CTUOM_Desc, OEORE_CTPCP_DR,OEORE_CTPCP_DR->CTPCP_Desc
	FROM SQLUser.OE_OrdExec
	WHERE (OEORE_OEORI_ParRef = :orditem)
}

Query FindOrderItems(EpisodeID As %String, TYPE As %String = "", USERID As %String = "", QueryMasterOrder As %String = "", NotDisplayNoPayOrd As %String = "") As %Library.Query(CONTAINID = "", ROWSPEC = "OrderName:%String,OrderStatus:%String,OrderPrior:%String,OrderStartDate:%String,OrderStartTime:%String,OrderDoseQty:%String,OrderDoseUOM:%String,OrderFreq:%String,OrderInstr:%String,OrderDur:%String,OrderPrice:%String,OrderPackQty:%String,OrderPackUOM:%String,OrderSkinTest:%String,OrderRecDep:%String,OrderUserDep:%String,OrderSum:%String,OrderPrescNo:%String,OrderDepProcNote:%String,OrderDoc:%String,OrderUserAdd:%String,OrderSeqNo:%String,OrderMasterSeqNo:%String,OrderLinkTo:%String,OrderLabEpisodeNo:%String,OrderItemRowid:%String,OrderARCIMRowid:%String,OrderSttDate:%String,OrderDoseUOMRowid:%String,OrderFreqRowid:%String,OrderPriorRowid:%String,OrderInstrRowid:%String,OrderDurRowid:%String,OrderPackUOMRowid:%String,OrderRecDepRowid:%String,OrderUserDepRowid:%String,OrderStatusRowid:%String,OrderBaseUOMRowid:%String,OrderDocRowid:%String,OrderUserAddRowid:%String,OrderARCOSRowid:%String,OrderDrugFormRowid:%String,OrderMaxDurRowid:%String,OrderType:%String,OrderBillTypeRowid:%String,OrderMaxDurRowid:%String,OrderBillType:%String,DepProcNotes:%String,OrderPhSpecInstr:%String,OrderLabSpec:%String,OrderAutoCalculate:%String,OrderCoverMainIns:%String,OrderActionRowid:%String,OrderAction:%String,OrderFile1:%String,OrderFile2:%String,OrderFile3:%String,OrderLabExCode:%String,OrderMultiDate:%String,OrderNotifyClinician:%String,OrderDIACat:%String,OrderInsurSignSymptom:%String,OrderSpeedFlowRate:%String,OrderLabEpisodeNo:%String,OrderLocalInfusionQty:%String,OrderUsableDays:%String,ExceedReasonDesc:%String,ExceedReasonID:%String,OrderPilotProRowId:%String,OrderPilotPro:%String,OrderFlowRateUnit:%String,OEORIFlowRateUnitDR:%String,MaterialBarCode:%String,OrderNeedPIVAFlag:%String,AntUseReason:%String,OrderStage:%String,OrderSelfOMFlag:%String,OrderOutsourcingFlag:%String,OrderDIACatRowId:%String,OrderPriorRemarks:%String,OrderPriorRemarksRowId:%String,OrderFirstDayTimes:%String,OrderFreqDispTimeStr:%String,OrderStageCode:%String,OrderVirtualtLongFlag:%String,SignFlag:%String")
{
}

Query FindOrderLabEpisode(EpisodeID As %String) As %Library.Query(CONTAINID = "", ROWSPEC = "OrderLabEpisodeNo:%String,OrderLabOrders:%String")
{
}

Query FindUnActiveOrderItems(EpisodeID As %String, CurLogonHosp As %String = "") As %Library.Query(CONTAINID = "", ROWSPEC = "OrderName:%String,OrderStatus:%String,OrderPrior:%String,OrderStartDate:%String,OrderStartTime:%String,OrderDoseQty:%String,OrderDoseUOM:%String,OrderFreq:%String,OrderInstr:%String,OrderDur:%String,OrderPrice:%String,OrderPackQty:%String,OrderPackUOM:%String,OrderSkinTest:%String,OrderRecDep:%String,OrderUserDep:%String,OrderSum:%String,OrderPrescNo:%String,OrderDepProcNote:%String,OrderDoc:%String,OrderUserAdd:%String,OrderSeqNo:%String,OrderMasterSeqNo:%String,OrderLinkTo:%String,OrderLabEpisodeNo:%String,OrderItemRowid:%String,OrderARCIMRowid:%String,OrderSttDate:%String,OrderDoseUOMRowid:%String,OrderFreqRowid:%String,OrderPriorRowid:%String,OrderInstrRowid:%String,OrderDurRowid:%String,OrderPackUOMRowid:%String,OrderRecDepRowid:%String,OrderUserDepRowid:%String,OrderStatusRowid:%String,OrderBaseUOMRowid:%String,OrderDocRowid:%String,OrderUserAddRowid:%String,OrderARCOSRowid:%String,OrderDrugFormRowid:%String,OrderMaxDurRowid:%String,OrderType:%String,OrderBillTypeRowid:%String,OrderMaxDurRowid:%String,OrderBillType:%String,DepProcNotes:%String,OrderPhSpecInstr:%String,OrderLabSpec:%String,OrderAutoCalculate:%String,OrderCoverMainIns:%String,OrderActionRowid:%String,OrderAction:%String,OrderFile1:%String,OrderFile2:%String,OrderFile3:%String,OrderLabExCode:%String,LinkOrderItem:%String,OrderStatusCode:%String")
{
}

Query GetCNPrescItems(EpisodeID As %String, PrescNo As %String) As %Library.Query(CONTAINID = "", ROWSPEC = "Description1:%String,Price1:%String,OrderQty1:%String,DoseUOM1:%String,PhSpecInstr1:%String,PackQty1:%String,ItemID1:%String,OrderItemID1:%String,Description2:%String,Price2:%String,OrderQty2:%String,DoseUOM2:%String,PhSpecInstr2:%String,PackQty2:%String,ItemID2:%String,OrderItemID2:%String,Description3:%String,Price3:%String,OrderQty3:%String,DoseUOM3:%String,PhSpecInstr3:%String,PackQty3:%String,ItemID3:%String,OrderItemID3:%String,Description4:%String,Price4:%String,OrderQty4:%String,DoseUOM4:%String,PhSpecInstr4:%String,PackQty4:%String,ItemID4:%String,OrderItemID4:%String")
{
}

Query GetCNPrescriptions(EpisodeID As %String) As %Library.Query(CONTAINID = 1, ROWSPEC = "PrescNo:%String,PrescDate:%String,PrescTime:%String,RecDep:%String,BillType:%String,UserAddName:%String,DurFactor:%String,PrescInstr:%String")
{
}

Query GetOrderItems(EpisodeID As %String, IsPhamacy As %String) As %Library.Query(CONTAINID = "", ROWSPEC = "Rowid:%String,OrderName:%String,StartDate:%String,Priority:%String,Status:%String,PackQty:%String,PackUOM:%String,Price:%String,Sum:%String,RecDep:%String,Billed:%String,BillType:%String,OrderType:%String,Spec:%String,UserAddName:%String,LabEpisodeNo:%String,orcat:%String,orcatdesc:%String,RecDepAdress,DepProcNotes:%String,StatusCode:%String,ExecuteTime:%String")
{
}

Query GetPrescItems(EpisodeID As %String, PrescNo As %String) As %Library.Query(CONTAINID = "", ROWSPEC = "Rowid:%String,OrderName:%String,StartDate:%String,SeqNo:%String,DoseQty:%String,DoseUOM:%String,Priority:%String,Status:%String,Frequence:%String,Instruction:%String,Duration:%String,PackQty:%String,PackUOM:%String,Price:%String,Sum:%String,RecDep:%String,Billed:%String,BillType:%String,BillClass:%String,UserAddCode:%String,UserAddName:%String,PoisonClass:%String,ItemCat:%String,Action:%String")
{
}

Query GetPrescriptions(EpisodeID As %String) As %Library.Query(CONTAINID = "", ROWSPEC = "PrescNo:%String,PrescDate:%String,PrescTime:%String,RecDep:%String,PrescType:%String,PrescTypeDesc:%String")
{
}

Query LookUpItm(Item As %String, GroupID As %String, Category As %String, SubCategory As %String, TYPE As %String, LUCategoryDesc As %Library.String, LUSubCategoryDesc As %Library.String, EpisodeID As %Library.String, BillingGrp As %Library.String, BillingSubGrp As %Library.String, DateRestriction As %Library.String, OrdCatGrp As %Library.String, Pharm As %Library.String, Param As %Library.String, Hospital As %Library.String) As %Query(CONTAINID = 0, ROWSPEC = "ARCIMDesc:%String,HIDDEN:%String,HIDDEN:%String,HIDDEN:%String,HIDDEN:%String,HIDDEN:%String,HIDDEN:%String,HIDDEN:%String,HIDDEN:%String,HIDDEN:%String,HIDDEN:%String,HIDDEN:%String,HIDDEN:%String,HIDDEN:%String,HIDDEN:%String,HIDDEN:%String,HIDDEN:%String,HIDDEN:%String,HIDDEN:%String,HIDDEN:%String,HIDDEN:%String")
{
}

ClassMethod LookUpItmClose(QHandle As %Library.Binary) As %Library.Status [ PlaceAfter = LookUpItmFetch ]
{
	Set repid=$LIST(QHandle,2)
	Kill ^CacheTemp(repid)
	Quit $$$OK
}

/// Creator:      周志强
/// CreatDate:    2010.03.21
/// Description:  替换医嘱模板维护的医嘱项查询Query,因为字符集的问题造成参数错误无法翻页
/// Table:        OE_OrdItem,OEC_OrderStatus
ClassMethod LookUpItmExecute(ByRef QHandle As %Library.Binary, Order As %String = "", GroupID As %Library.String = "", Category As %Library.String = "", SubCategory As %Library.String = "", TYPE As %Library.String = "", LUCategoryDesc As %Library.String = "", LUSubCategoryDesc As %Library.String = "", EpisodeID As %Library.String = "", BillingGrp As %Library.String = "", BillingSubGrp As %Library.String = "", DateRestriction As %Library.String = "", OrdCatGrp As %Library.String = "", Pharm As %Library.String = "", Param As %Library.String = "", Hospital As %Library.String = "") As %Library.Status
{
	Set repid=$I(^CacheTemp)
	If $g(index)="" Set index=1
	Set rset=##class(%ResultSet).%New("web.OEOrdItem.LookUpItm")
	Set Order=##class(web.DHCDocUtil).UnEscape(Order)
	Set Category=##class(web.DHCDocUtil).UnEscape(Category)
	Set SubCategory=##class(web.DHCDocUtil).UnEscape(SubCategory)
	Set TYPE=##class(web.DHCDocUtil).UnEscape(TYPE)
	Set LUCategoryDesc=##class(web.DHCDocUtil).UnEscape(LUCategoryDesc)
	Set LUSubCategoryDesc=##class(web.DHCDocUtil).UnEscape(LUSubCategoryDesc)
	d rset.Execute(Order, GroupID, Category, SubCategory, TYPE, LUCategoryDesc, LUSubCategoryDesc, EpisodeID, BillingGrp, BillingSubGrp, DateRestriction, OrdCatGrp, Pharm, Param, Hospital)
	Set columns = rset.GetColumnCount()
	While (rset.Next()) {
		s Data=""
		for i=1:1:columns {
			s $List(Data,i)=rset.GetData(i)
		}
		Set ^CacheTemp(repid,index)=Data
		Set index=index+1
	 }
	d rset.Close()
	
	Set QHandle=$lb(0,repid,0)
	Quit $$$OK
}

ClassMethod LookUpItmFetch(ByRef QHandle As %Library.Binary, ByRef Row As %Library.List, ByRef AtEnd As %Library.Integer = 0) As %Library.Status [ PlaceAfter = LookUpItmExecute ]
{
	Set AtEnd=$LIST(QHandle,1)
	Set repid=$LIST(QHandle,2)
	Set ind=$LIST(QHandle,3)
	//
	Set ind=$o(^CacheTemp(repid,ind))
	If ind="" {				// if there are no more rows, finish fetching
	Set AtEnd=1
	Set Row=""
	}
	Else      {				// fetch row
	Set Row=^CacheTemp(repid,ind)
	}
	// Save QHandle
	s QHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

/// Creator:      周志强
/// CreatDate:    2010.03.21
/// Description:  检查是否有未填写的检查申请单医嘱
/// Table:        OE_OrdItem,OEC_OrderStatus
/// Input:        AdmRowId:就诊指针
/// Return: 	  1:是    0:否	
/// OutPut:		  
/// Others:       w ##class(web.DHCOEOrdItem).CheckCompleteAppBill(518) 
ClassMethod CheckCompleteAppBill(AdmRowId As %String)
{
	s Find=0
	s OrderRowId=##Class(web.DHCDocOrderEntry).GetPAADMOrderRowid(AdmRowId)
	s StartDate=..%SysDate()
	s EndDate=..%SysDate()
	;s child=0 f  s child=$o(^OEORD(OrderRowId,"I",child)) q:(child="")  d
	f OrderStartDate=StartDate:1:EndDate {
		s child=0 f  s child=$O(^OEORDi(0,"StDt",OrderStartDate,OrderRowId,child)) Q:(child="")||(Find=1)  d
		.s ordInfo=##class(web.DHCRisCommFunctionEx).GetOeorditminfo(OrderRowId, child)
		.s GetstrOrderName=$p(ordInfo,"^",1)
		.s SubCatDesc=$p(ordInfo,"^",7)
		.q:SubCatDesc="门诊诊疗费"
		.q:SubCatDesc="挂号费"
		.s GetItemStatusCode=$p(ordInfo,"^",14)
		.s GetServerMaterial=$p(ordInfo,"^",18)
		.s RecLocDesc=$p(ordInfo,"^",21)
		.s RecLocDR=$p(ordInfo,"^",19)
		.s ItmCatDR=$p(ordInfo,"^",23)
		.q:(GetServerMaterial'="Service")&(GetServerMaterial'="S")
		.q:(GetItemStatusCode'="V")&(GetItemStatusCode'="E")
		.s OrderItemRowId=OrderRowId_"||"_child
		.s AppRowid=$o(^DHCRBAppi("OrdRowid",OrderItemRowId,0))
		.i AppRowid="" s Find=1
	}
	Q Find
}

Query LookUpByCategory(SubCategory As %Library.String, Category As %Library.String, SSGroupID As %Library.String) As %Library.Query(CONTAINID = 0, ROWSPEC = "desc:%String,HIDDEN:%String,code:%String")
{
}

ClassMethod LookUpByCategoryClose(QHandle As %Library.Binary) As %Library.Status [ PlaceAfter = LookUpByCategoryFetch ]
{
	Set repid=$LIST(QHandle,2)
	Kill ^CacheTemp(repid)
	Quit $$$OK
}

/// Creator:      周志强
/// CreatDate:    2010.05.05
/// Description:  替换医嘱模板维护的医嘱子类查询Query,因为字符集的问题造成参数错误无法翻页
/// Table:        OE_OrdItem,OEC_OrderStatus
ClassMethod LookUpByCategoryExecute(ByRef QHandle As %Library.Binary, SubCategory As %String = "", Category As %Library.String = "", SSGroupID As %Library.String = "") As %Library.Status
{
	Set repid=$I(^CacheTemp)
	If $g(index)="" Set index=1
	Set rset=##class(%ResultSet).%New("web.ARCItemCat.LookUpByCategory")
	Set Category=##class(web.DHCDocOrderCommon).UnEscape(Category)
	Set SubCategory=##class(web.DHCDocOrderCommon).UnEscape(SubCategory)
	d rset.Execute(SubCategory, Category, SSGroupID)
	Set columns = rset.GetColumnCount()
	While (rset.Next()) {
		s Data=""
		for i=1:1:columns {
			s $List(Data,i)=rset.GetData(i)
		}
		Set ^CacheTemp(repid,index)=Data
		Set index=index+1
	 }
	d rset.Close()
	
	Set QHandle=$lb(0,repid,0)
	Quit $$$OK
}

ClassMethod LookUpByCategoryFetch(ByRef QHandle As %Library.Binary, ByRef Row As %Library.List, ByRef AtEnd As %Library.Integer = 0) As %Library.Status [ PlaceAfter = LookUpByCategoryExecute ]
{
	Set AtEnd=$LIST(QHandle,1)
	Set repid=$LIST(QHandle,2)
	Set ind=$LIST(QHandle,3)
	//
	Set ind=$o(^CacheTemp(repid,ind))
	If ind="" {				// if there are no more rows, finish fetching
	Set AtEnd=1
	Set Row=""
	}
	Else      {				// fetch row
	Set Row=^CacheTemp(repid,ind)
	}
	// Save QHandle
	s QHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

// 加入历次就诊取值

Query HistoryAdm(EpisodeID As %String) As %Query(ROWSPEC = "Adm:%String,res:%String")
{
}

ClassMethod HistoryAdmClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = HistoryAdmExecute ]
{
	Set repid=$LIST(qHandle,2)
	Kill ^CacheTemp(repid)
	Quit $$$OK
}

ClassMethod HistoryAdmExecute(ByRef qHandle As %Binary, EpisodeID As %String) As %Status
{
	
	Set repid=$I(^CacheTemp)
	s ind=1
	s ret=0
   s Adm="",res="		"
   s HistoryAdmList=""
   ;Do OutputRowWSCTObj
   if EpisodeID'=""{
   s PAADMType=$p($g(^PAADM(EpisodeID)),"^",2)
   s PatType=$P(^PAADM(EpisodeID,1),"^",6)  //PAADM_Epissubtype_DR
   s PatientID=$P(^PAADM(EpisodeID),"^",1)
   s Adm=0  f  s Adm=$O(^PAPERdr(PatientID,"ADM",PAADMType,Adm)) Q:(Adm="")  d
    .Q:Adm=""
	.s AdmDate=$P(^PAADM(Adm),"^",6)
	.s DepCodeDR=$P(^PAADM(Adm),"^",4)  //ctloc
	.s AdmDocCodeDR=$P(^PAADM(Adm),"^",9) //ctpcp
	.s AdmLoc=$p(^CTLOC(DepCodeDR),"^",2)
	.s AdmDoc=""
	.i AdmDocCodeDR'="" s AdmDoc=$P($G(^CTPCP(AdmDocCodeDR,1)),"^",2) //CT_CareProv医护人员表
	.s AdmDate=$Zd(AdmDate,3)  
	.s res=AdmLoc_"    "_AdmDoc_"    "_AdmDate
	.s HistoryAdm=Adm_"@"_res
	.s HistoryAdmList=HistoryAdmList_"^"_HistoryAdm
   	}
	s length=$l(HistoryAdmList,"^")
	for{
		s HistoryAdm=$p(HistoryAdmList,"^",length)
		s Adm=$p(HistoryAdm,"@",1)
		s res=$p(HistoryAdm,"@",2)
		Do OutputRowWSCTObj
		s length=length-1
		q:length=0
		
	}
	
	
	Set qHandle=$lb(0,repid,0)
	Quit $$$OK
OutputRowWSCTObj
	set Data=$lb(Adm,res)
	Set ^CacheTemp(repid,ind)=Data
 Set ind=ind+1
	quit
}

ClassMethod HistoryAdmFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = HistoryAdmExecute ]
{
	Set AtEnd=$LIST(qHandle,1)
	Set repid=$LIST(qHandle,2)
	Set ind=$LIST(qHandle,3)
	Set ind=$o(^CacheTemp(repid,ind))
	If ind="" {				// if there are no more rows, finish fetching
		Set AtEnd=1
		Set Row=""
	}
	Else      {			
		Set Row=^CacheTemp(repid,ind)
	}
	s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

/// Creator:	郭宝平
/// CreatDate:	2010.06.19
/// Description:查询医嘱退药数
/// Table:		OE_OrdItem 
/// Input:		医嘱指针
/// Output:    
/// Return:		医嘱的退药数数量(按基本单位折算)
/// Others:		w ##class(web.UDHCStopOrderLook).GetOrdItmAllReturnQty("5||10")
ClassMethod GetReturnQty(OrdItmRowId As %String) As %String
{
  	s retqty=0
  	q:OrdItmRowId="" retqty
  	q:'$d(^DHCPHRTIi(OrdItmRowId,"ORDI")) retqty
  	s retrow="" f  s retrow=$o(^DHCPHRTIi(OrdItmRowId,"ORDI",retrow)) q:retrow=""  d
	.s retsub=0 f  s retsub=$o(^DHCPHRTIi(OrdItmRowId,"ORDI",retrow,retsub)) q:retsub=""  d
	..s curretqty=0
	..s curretqty=+$p($g(^DHCPHRTI(retrow,"RTI",retsub)),"^",3)
	..s retqty=retqty+curretqty
	q retqty
}

/// Creator:	郭荣勇
/// CreatDate:	2015.03.27
/// Description:查询医嘱应发总发药数(住院传执行记录Rowid,门诊传医嘱Rowid)
/// Table:		OE_OrdItem,DHC_OEDispensing
/// Input:		医嘱指针,执行记录指针
/// Output:    
/// Return:		医嘱的应发总发药数(基本单位)
/// Others:		w ##class(web.DHCOEOrdItem).GetDspTotleQty("5||10")
ClassMethod GetDspTotleQty(OrdItmRowId As %String, OEORERowId As %String = "") As %String
{
  	n (OrdItmRowId,OEORERowId)
  	s DspTotleQty=0
  	i OEORERowId'="" {
		s dis=0 for {
			s dis=$O(^DHCOEDISQTY(0,"OEORE",OEORERowId,dis)) q:dis=""
			s dstatus=""
			if $g(dis)'="" s dstatus=$p(^DHCOEDISQTY(dis),"^",7)
			s DspTotleQty=$p(^DHCOEDISQTY(dis),"^",2)
			q:DspTotleQty'=""
		}
  	}elseif OrdItmRowId'="" {
	  	s DoseUnitID=$p($g(^OEORD(+OrdItmRowId,"I",$p(OrdItmRowId,"||",2),2)),"^",3)
	  	s ArcimId=$p($g(^OEORD(+OrdItmRowId,"I",$p(OrdItmRowId,"||",2),1)),"^",2)
	  	s drgformId=$P(^ARCIM(+ArcimId,$P(ArcimId,"||",2),1),"^",12)
	  	s DoseQty=$p(^OEORD(+OrdItmRowId,"I",$p(OrdItmRowId,"||",2),2),"^",1)
	  	//同频次不同剂量
		s OrderFreqTimeDoseStr=$p($g(^OEORD(+OrdItmRowId,"I",$p(OrdItmRowId,"||",2),"DHC")),"^",59)
		if (OrderFreqTimeDoseStr'=""){
			s DspTotleQty=0
	        s Len=$l(OrderFreqTimeDoseStr,"!")
	        for i=1:1:Len{
		        s OneFreqDispTimeDose=$p(OrderFreqTimeDoseStr,"!",i)
		        s OneDoseQty=$p(OneFreqDispTimeDose,"$",2)
		        s OneBaseDoseQty = ##Class(web.DHCDocOrderEntry).CalDose(DoseUnitID, drgformId, OneDoseQty)
		        s DspTotleQty=DspTotleQty+(+OneBaseDoseQty)
		    }
		}else{
			s DspTotleQty=##Class(web.DHCDocOrderEntry).CalDose(DoseUnitID,drgformId,DoseQty)
		}
		/*s dis=0 for {
			s dis=$O(^DHCOEDISQTY(0,"OEORI",OrdItmRowId,dis)) q:dis=""
			s dstatus=""
			if $g(dis)'="" s dstatus=$p(^DHCOEDISQTY(dis),"^",7)
			s DspTotleQty=$p(^DHCOEDISQTY(dis),"^",2)
			Q:DspTotleQty'=""
		}*/
  	}
	
	q DspTotleQty
}

/// 是否实习医生
/// 1 需审核实习,0 非实习审核
ClassMethod practice(CTPCPRowId As %String) As %String
{
	n (CTPCPRowId,%session)
	s PracticeDocOrderNeedVerify=..%GetConfig("PracticeDocOrderNeedVerify")
	;如果是实习医生医嘱不能审核?
	s CarPrvTypeCode=""
	i CTPCPRowId'="" d
	.s CarPrvTypeRowid=$P($g(^CTPCP(CTPCPRowId,1)),"^",4)
	.i CarPrvTypeRowid'="" s CarPrvTypeCode=$P($g(^CT("CPT",CarPrvTypeRowid)),"^",1)
	Q:(PracticeDocOrderNeedVerify=1)&(CarPrvTypeCode="PRACTICE") 1
	Q 0
}

/// 停止互斥医嘱
/// w ##class(web.DHCOEOrdItem).StopConflict(56,"1314||1*58||72*V*^",6,82)
/// w ##class(appcom.OEOrdItem).Stop("58||58",6,+$h,0)
/// w ##class(web.DHCOEOrdItem).StopConflict("70","13102||1*71||199*V*^",153,15)
ClassMethod StopConflict(EpisodeID As %String, OrdStr As %String, User As %String, Loc As %String) As %String
{
	n (EpisodeID,OrdStr,User, Loc,%session)
	s CurLogonHosp =$p(^CTLOC(Loc),"^",22)
	s StopAllExecItemCat="^"_..%GetConfig("StopAllExecItemCat",CurLogonHosp)_"^"
	for i=1:1:$L(OrdStr,"^") {
  		s OneOrdItem=$P(OrdStr,"^",i)
  		s ArcimRowid=$P(OneOrdItem,"*",1),OrdItemID=$P(OneOrdItem,"*",2)
  		continue:ArcimRowid=""
  		continue:'##class(DHCDoc.Order.Common).IsValidOrd(OrdItemID)
		d ##class(DHCDoc.DHCDocConfig.ARCIMExt).GetConflict(ArcimRowid,CurLogonHosp,.ConflictItemList)
		continue:'$D(ConflictItemList)
		s Ord=+OrdItemID
	   	s OrdSttDate=$p($g(^OEORD(Ord,"I",$p(OrdItemID,"||",2),1)),"^",9)
	   	s OrdSttTime=$p($g(^OEORD(Ord,"I",$p(OrdItemID,"||",2),1)),"^",10)
	   	s ItmMastID="" for{
			s ItmMastID=$O(ConflictItemList(ItmMastID)) Q:ItmMastID=""
			s ConflictItemObj=ConflictItemList(ItmMastID)
			s ConflictType=ConflictItemObj.Long.Type
			continue:ConflictType'="S"
			s ItemCatRowId=$p($g(^ARCIM(+$g(ItmMastID),1,1)),"^",10)
			s StopAllExecFlag=(StopAllExecItemCat[("^"_ItemCatRowId_"^"))
			s SttDate="" for{
				s SttDate=$O(^OEORDi(0,"ARCIM",Ord,ItmMastID,SttDate)) Q:SttDate=""
				s Sub=0 for{
					s Sub=$O(^OEORDi(0,"ARCIM",Ord,ItmMastID,SttDate,Sub)) Q:Sub=""
					d OneOrdItem
				}
			}
		}
  	}
	Q 0
OneOrdItem
	s OrdItemRowid=Ord_"||"_Sub
	Q:'##class(DHCDoc.Order.Common).IsLongOrdItem(OrdItemRowid)
	Q:'##class(DHCDoc.Order.Common).IsValidOrd(OrdItemRowid)
	Q:OrdItemRowid=OrdItemID
	s DealWithStoppedOrdFlag=0
	s OrdStatusCode=##class(DHCDoc.Order.Common).GetOrdStatusCode(OrdItemRowid)
	if OrdStatusCode="D"{
		s XDate=$p($g(^OEORD(Ord,"I",Sub,3)),"^",34)
		s XTime=$p($g(^OEORD(Ord,"I",Sub,2)),"^",15)
		//已停医嘱若停医嘱时间小于OrdSttDate,需处理.否则不处理
		Q:(OrdSttDate>XDate)||((OrdSttDate=XDate)&&(OrdSttTime>=XTime))
		s DealWithStoppedOrdFlag=1
	}
	s ExpStr=DealWithStoppedOrdFlag
	s ret=##class(appcom.OEOrdItem).Stop(OrdItemRowid,User,OrdSttDate,OrdSttTime,StopAllExecFlag,"Y",ExpStr)
	Q
}

/// 调用平台组接口
ClassMethod DHCHisInterface(OrderStr As %String, Doc As %String, Adm As %String, User As %String, Loc As %String = "") As %String
{
	s Rtn=0
	Q:OrderStr="" Rtn
	//插入医嘱时将医嘱OrderID插入临床路径执行记录表
	D ##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.doc.ExeOrderRewriteCPW",Adm,OrderStr,User,Loc)
	s OrderLen=$L(OrderStr,"^")
	S OrderRowIDStr="",ZSKLibOrdLogStr="",arreqidstr=""
	S FeedBackStr="",AuditOrdStr="",PrescNoStr=""
	s practiceFlag=..practice(Doc)
	f i=1:1:OrderLen 
	{
		S OneOrderStr=$P(OrderStr,"^",i)
		s OrderIDGet=$P(OneOrderStr,"*",2)
		Continue:OrderIDGet=""
		if OrderRowIDStr=""  s OrderRowIDStr=OrderIDGet
		else  s OrderRowIDStr=OrderRowIDStr_"^"_OrderIDGet
		//医生给病人开危重医嘱时,需调用平台组方法 20151013
		s ArcimRowId=$p($p(OrderStr,"^",i),"*",1)
		i ArcimRowId="" continue
		//s ArcimDecs=$p(^ARCIM(+ArcimRowId,$p(ArcimRowId,"||",2),1),"^",2)
		///实习医生有需要审核医嘱时，需调用平台组方法 20151013
	    if (practiceFlag=1) {
		    s Rtn=##class(web.DOC.PortalService).TaskNeedAuditOEItem("S00000028",OrderIDGet,1,Adm)
		}
		;免费药标识
		s HospID=##class(DHCDoc.Common.Hospital).GetAffiliatedHospitalId(Adm)
 		s ARCIMFreeDurgFlag=##class(web.DHCDocOrderCommon).GetARCIMFreeDurgFlag(ArcimRowId,HospID)
 		if (ARCIMFreeDurgFlag="Y"){
	 		s Rtn=##class(web.DHCBillInterface).IUpdateOeoriBilled(OrderIDGet, "P")
	 	}
		s PrescNo=$p($g(^OEORD(+OrderIDGet,"I",$p(OrderIDGet,"||",2),1)),"^",14)
		if PrescNo'=""{
			i PrescNoStr="" s PrescNoStr=PrescNo
			e  s PrescNoStr=PrescNoStr_"^"_PrescNo
		}
		/*s PHPrescType=##class(web.DHCDocPrescript).IsPrescType(PrescNo)
		;保存草药管理数据
		if (PHPrescType=1){
			s Rtn=##class(PHA.HERB.Com.Init).SaveBasicDataByOeori(OrderIDGet)
			if (+Rtn<0){
				d ##class(DHCDoc.Log.Common).General("Insert","web.DHCOEOrdItem","DHCHisInterface","保存草药管理数据失败",OrderIDGet,Rtn)
			}
		}*/
		s OEORIMonitorLogIdStr=$p($g(^OEORD(+OrderIDGet,"I",$p(OrderIDGet,"||",2),"DHC")),"^",44)
		if (OEORIMonitorLogIdStr'=""){
			;获取医嘱扩展表里存储的知识库监测ID信息：监测ID+医嘱项ID
			s OEORIMonitorLogId=$p(OEORIMonitorLogIdStr,$c(15),1)
			s ZSKLinkOrdItemStr=$p(OEORIMonitorLogIdStr,$c(15),2)
			s OEORIMonitorLogOrd=""
			s leng=$l(ZSKLinkOrdItemStr,$c(14))
			f j=1:1:leng{
				s ZSKLinkOrdItem=$p(ZSKLinkOrdItemStr,$c(14),j)
				
				s oneZSKLinkAcrim=$p(ZSKLinkOrdItemStr,$c(13),1)
				s oneZSKLinkOrdItem=$p(ZSKLinkOrdItemStr,$c(13),2)
				if (oneZSKLinkOrdItem=""){
					;获取一次审核的医嘱中和监测医嘱冲突的医嘱
					//s length=$l(Ret,"^")
					f k=1:1:OrderLen{
					s oneOrdItemStr=$p(OrderStr,"^",k)
					s ItemRowId=$p(oneOrdItemStr,"*",1)
					s OrdRowId=$p(oneOrdItemStr,"*",2)
					i oneZSKLinkAcrim=ItemRowId  d
					.i OEORIMonitorLogOrd="" s OEORIMonitorLogOrd=OrdRowId
					.e  s OEORIMonitorLogOrd=OEORIMonitorLogOrd_"^"_OrdRowId
					}	
				}else{
					i OEORIMonitorLogOrd="" s OEORIMonitorLogOrd=oneZSKLinkOrdItem
					e  s OEORIMonitorLogOrd=OEORIMonitorLogOrd_"^"_oneZSKLinkOrdItem
				}			
			}
			i ZSKLibOrdLogStr="" s ZSKLibOrdLogStr=OEORIMonitorLogId_"^"_OrderIDGet_"^"_OEORIMonitorLogOrd
			e  s ZSKLibOrdLogStr=ZSKLibOrdLogStr_"!"_OEORIMonitorLogId_"^"_OrderIDGet_"^"_OEORIMonitorLogOrd
		}
		
		s OEORIHLYYInfo=$g(^OEORD(+OrderIDGet,"I",$p(OrderIDGet,"||",2),"HLYY"))
		if (OEORIHLYYInfo'=""){
			;医嘱id^药品唯一标识^药品通过标识(Y/N), 多个用！！分割。
			s HLYYInfo=$p(OEORIHLYYInfo,$c(4),1)
			if HLYYInfo'=""{
				s OEORIUnique=$p(HLYYInfo,$c(3),1)
				s OEORIDrugPassFlag=$p(HLYYInfo,$c(3),4)
				s FeedBack=OrderIDGet_"^"_OEORIUnique_"^"_OEORIDrugPassFlag
				if FeedBackStr=""{
					s FeedBackStr=FeedBack	
				}else{
					s FeedBackStr=FeedBackStr_"!!"_FeedBack	
				}
			}
			
			s PrescAuditInfo=$p(OEORIHLYYInfo,$c(4),2)
			if PrescAuditInfo'=""{
				s OEORIUnique=$p(PrescAuditInfo,$c(3),1)
				s OEORIDrugPassFlag=$p(PrescAuditInfo,$c(3),4)
				s AsgID=$p(PrescAuditInfo,$c(3),5)
				s AuditOrd=OrderIDGet_"^"_OEORIUnique_"^"_OEORIDrugPassFlag
				if AuditOrdStr=""{
					s AuditOrdStr=AuditOrd	
				}else{
					s AuditOrdStr=AuditOrdStr_"!!"_AuditOrd	
				}
			}
		}
		//开立药品医嘱时调用平台状态统一存储接口存储状态
		s ItmCat=$p($g(^ARCIM($p(ArcimRowId,"||",1),$p(ArcimRowId,"||",2),1)),"^",10)
		s OrdType=$p($g(^ARC("IC",ItmCat)),"^",7)	;ARCIC_OrderType
		Set OrdDeptId = $p($g(^OEORD(+OrderIDGet,"I",$p(OrderIDGet,"||",2),7)),"^",2)	
		if (OrdType="R" ){
			d ##class(DHCDoc.Interface.Inside.Invoke).UpdExaReqItmStatus("ORDER","",User,OrderIDGet,OrdDeptId)
		}
	}
	i ZSKLibOrdLogStr'="" d ##class(web.DHCSTPHCMPASS).UpdateLibOrdLog(ZSKLibOrdLogStr)
	if (practiceFlag=1) {
		s linkurl="WEBSYS.TCOMPONENT=UDHCOEOrder.List.Verify"
		s OtherInfoJsons="{""linkParam"":"""_linkurl_"&EpisodeID="_Adm_"&ReportId=02"""_",""BizObjId"":"""_Adm_"""}"
		Set rtn =##class(websys.DHCMessageInterface).Send("", "1059", User, Adm, "", "", OtherInfoJsons, "", "","")
	}
	if PrescNoStr'=""{
		;调用药房接口，生成药房处方信息
		d ##class(PHA.FACE.OUT.Com).SavePrescData(PrescNoStr, "OP05", User, "^")
	}
	if OrderRowIDStr'=""  {
		s Rtn=##class(web.DHCENS.EnsHISService).DHCHisInterface("SENDDOCORDITEMINFO",OrderRowIDStr)
		;发送申请单信息到第三方
		s Rtn=##Class(web.DHCAPPInterface).AppInvokInterface(OrderRowIDStr,User)
		;自动删除过期的表单
		d ##class(DHCDoc.Diagnos.SpecLoc).AutoSpecDiagnos(OrderRowIDStr,User)
		;DTS埋点
		d ##class(DHCDoc.Log.BizLogDTS).OEOrderDts(OrderRowIDStr,User,Adm)
		;HRP插入在途
		d ##class(DHCDoc.Interface.Outside.HRPService).DispMaterialBatch(Adm,OrderRowIDStr)	
	}
	;医为合理用药医嘱信息回写
	if FeedBackStr'=""{
		s fbret=##class(web.DHCCKBService).SaveOeordFeedBack(FeedBackStr)	
	}
	;医为药师审方医嘱信息回写
	if AuditOrdStr'=""{
		s fbret=##class(web.DHCPRESCInterface).UpdAuditOrd(AuditOrdStr)	
	}
	;医保控费医嘱信息回写
	;放到前台外部接口接入管理统一处理，减少压力测试耗时
	;d ##class(DHCDoc.Order.InsuOrderRules).UpdateInsuRules(OrderStr,Adm)
	Q Rtn
}

/// 新医嘱录入部分
/// Creator:	彭春桥
/// CreatDate:	2014.04.16
/// Description:新医嘱录入 查询已审核医嘱
/// Table:		OE_OrdItem 
/// Input:		
/// Output:    
/// Return:		医嘱信息 JSON 
/// Others:	
/// D ##class(%ResultSet).RunQuery("web.DHCOEOrdItem","FindOrderItems","362","387")  
/// w ##class(web.DHCOEOrdItem).FindOrderItemsNew(18881)	
ClassMethod FindOrderItemsNew(USERID As %String, EpisodeID As %String, TYPE As %String = "", QueryMasterOrder As %String = "", NotDisplayNoPayOrd As %String = "", OrderOpenForAllHosp As %String = "") As %String
{
	s ^tmpgry("FindOrderItemsNewdcd")=USERID_","_EpisodeID_","_TYPE_","_QueryMasterOrder
	s page=1,total=0,records=0,data=""
	i (USERID="")||(EpisodeID="") {
		w "{""page"":"""_page_""",""total"":"""_total_""",""records"":"""_records_""",""data"":[]}"
		Q
	}
	s ret=..InitGridRowId("R",USERID,EpisodeID)	
	Set langid=..%LanguageID()
	s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)	
	s AdmReasonDR=$p(^PAADM(EpisodeID,1),"^",7)
	s AdmHospitalId=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(EpisodeID)
	s AdmHospitalCode=##class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalCode(AdmHospitalId)
	s RecLocInputObj={"EpisodeID":(EpisodeID),"SessionStr":(..%SessionStr()),"OpenForAllHosp":(OrderOpenForAllHosp),"FindRecLocByLogonLoc":0}
	w "{""page"":"""_page_""",""total"":"""_total_""",""records"":"""_records_""",""data"":["
	Set rset=##Class(%ResultSet).%New("web.DHCOEOrdItem:FindOrderItems")
	If rset.QueryIsValid() { 
		Set Status=rset.Execute(EpisodeID,TYPE,USERID,QueryMasterOrder,NotDisplayNoPayOrd,AdmHospitalId)
		If 'Status Quit
		Set columns = rset.GetColumnCount()
		While (rset.Next()) {
			s OrderItemRowid=rset.Data("OrderItemRowid")
			i OrderItemRowid="" continue
			//continue:(##class(web.UDHCStopOrderLook).usersecurity(USERID,rset.Data("OrderARCIMRowid"))=100)  ;根据默认安全组的开医嘱权限?确定其停医嘱的权限

			//查询字段
			//OrderName,OrderStatus,OrderPrior,OrderStartDate,OrderStartTime,OrderDoseQty,
			//OrderDoseUOM,OrderFreq,OrderInstr,OrderDur,OrderPrice,OrderPackQty,OrderPackUOM,
			//OrderSkinTest,OrderRecDep,OrderUserDep,OrderSum,OrderPrescNo,OrderDepProcNote,
			//OrderDoc,OrderUserAdd,OrderDate,OrderSeqNo,OrderMasterSeqNo,OrderLinkTo,OrderLabEpisodeNo,
			//OrderItemRowid,OrderARCIMRowid,OrderSttDate,OrderDoseUOMRowid,OrderFreqRowid,
			//OrderPriorRowid,OrderInstrRowid,OrderDurRowid,OrderPackUOMRowid,OrderRecDepRowid,
			//OrderUserDepRowid,OrderStatusRowid,OrderBaseUOMRowid,OrderDocRowid,OrderUserAddRowid,
			//OrderARCOSRowid,OrderDrugFormRowid,OrderMaxDurRowid,OrderType,OrderBillTypeRowid,
			//OrderMaxDurRowid,OrderBillType,DepProcNotes,OrderPhSpecInstr,OrderLabSpec,
			//OrderAutoCalculate,OrderCoverMainIns,OrderActionRowid,OrderAction,
			//OrderFile1,OrderFile2,OrderFile3,OrderLabExCode,OrderMultiDate,
			//OrderNotifyClinician,OrderDIACat,OrderInsurSignSymptom,OrderSpeedFlowRate,OrderLabEpisodeNo
			
			//^OrderGridRowId(USERID,ADMID)  行ID 从 1  开始(每次添加行调用此方法)		
			s rowid=..InitGridRowId("N",USERID,EpisodeID)
			s OrderGridRowAry(USERID,EpisodeID,"OLD","id")=rowid
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderMasterSeqNo")=rset.Data("OrderMasterSeqNo")
			s OrderPrior="临时医嘱" //rset.Data("OrderPrior")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderPrior")=OrderPrior //rset.Data("OrderPrior")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderName")=rset.Data("OrderName")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderDoseQty")=rset.Data("OrderDoseQty")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderDoseUOM")=rset.Data("OrderDoseUOM")
			;处方类型,可以根据设置里的类别来定或者也可以根据账单单位确定
			s OrderARCIMRowid=rset.Data("OrderARCIMRowid")
			s ItemCatRowid=$p($g(^ARCIM(+OrderARCIMRowid,$p(OrderARCIMRowid,"||",2),1)),"^",10)
			i rset.Data("OrderType")="R"{
				s PHPrescType=##class(web.DHCDocOrderCommon).GetPHPrescType(ItemCatRowid,AdmHospitalId,OrderARCIMRowid)
				i PHPrescType="" s PHPrescType="1"
			}else{
				s PHPrescType=##class(web.DHCDocOrderCommon).GetPHPrescType(ItemCatRowid,AdmHospitalId,OrderARCIMRowid)
			}
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderPHPrescType")=PHPrescType
			///tanjishan 2015-09
			s PHUseEqQty=..%GetConfig("PHUseEqQty")
			s DrgformRowid=##class(web.DHCDocOrderEntry).GetDrgForm(OrderARCIMRowid)
			s OrderDoseStr=""
			i DrgformRowid'="" {
				s PHCDRowid=$P(DrgformRowid,"||",1)
				s ChildSub=$P(DrgformRowid,"||",2)
				s FormDoseQty=$p($g(^PHCD(PHCDRowid,"DF",ChildSub,2)),"^",5) ;Pharmacy base UOM
				s FormDoseUOMRowid=$p($g(^PHCD(PHCDRowid,"DF",ChildSub,2)),"^",4)
				s FormDoseUOMDesc=##Class(web.DHCDocOrderCommon).GetUOMDesc(FormDoseUOMRowid)
				s OrderDoseStr=FormDoseQty_$C(1)_FormDoseUOMDesc_$C(1)_FormDoseUOMRowid
				s leq=0
				for {
					s leq=$o(^PHCD(PHCDRowid,"DF",ChildSub,"EQ",leq))
					q:leq=""
					s eqrec=^PHCD(PHCDRowid,"DF",ChildSub,"EQ",leq)
					s FormDoseUOMRowid=$p(eqrec,"^"),eqqty=$p(eqrec,"^",2),eqdefaultqty=$p(eqrec,"^",3)
					if eqdefaultqty'="" s FormDoseQty=eqdefaultqty
					else  if PHUseEqQty=1 s FormDoseQty=eqqty
					s FormDoseUOMDesc=##Class(web.DHCDocOrderCommon).GetUOMDesc(FormDoseUOMRowid)
					i (FormDoseQty'="")&(FormDoseQty<1)&(FormDoseQty'=0) s FormDoseQty="0"_FormDoseQty
					s OrderDoseStr=FormDoseQty_$C(1)_FormDoseUOMDesc_$C(1)_FormDoseUOMRowid_$C(2)_OrderDoseStr
				}
			}else{
				if (rset.Data("OrderType")'="R"){
					s OrderUnitDR=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),2)),"^",3)
				    s:OrderUnitDR'="" OrderDoseStr=rset.Data("OrderDoseQty")_$C(1)_$p($g(^CT("UOM",OrderUnitDR)),"^",2)_$C(1)_OrderUnitDR
				}	
			}
			s OEORITime=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),1)),"^",17)
			i OEORITime="" s OEORITime=..%SysTime()
			s OEORIDate=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),3)),"^",7)
			i OEORIDate="" s OEORIDate=..%SysDate()
			s RecLocInputObj.DefaultReclocRowid=rset.Data("OrderRecDepRowid")
			s RecLocInputObj.OrderARCIMRowid=OrderARCIMRowid
			s RecLocInputObj.OrderInstrRowid=rset.Data("OrderInstrRowid")
			s RecLocInputObj.OrderDateStr=..%ZD(OEORIDate)_" "_..%ZT(OEORITime,1)
			s OrderPriorRowid=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),1)),"^",8)
			s OrderPriorRemarksStr=##class(web.DHCOEOrdItemView).SplitOrderPriorRowid(OrderPriorRowid)
			s RecLocInputObj.OrderPriorRowid=$P(OrderPriorRemarksStr,"^",1)
			s RecLocInputObj.OrderPriorRemarksRowId=$P(OrderPriorRemarksStr,"^",3)
			s RecLocInputObj.NotifyClinician=rset.Data("OrderNotifyClinician")
			s RecLocJson=##class(web.DHCDocOrderCommon).GetRecLocInfo(RecLocInputObj.%ToJSON())
			s RecLocRetObj={}.%FromJSON(RecLocJson)
			s OrderGridRowAry(USERID,EpisodeID,"OLD","idoseqtystr")=OrderDoseStr
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderPackUOMStr")=##Class(web.DHCDocOrderCommon).GetBillUOMStr(rset.Data("OrderARCIMRowid"),rset.Data("OrderRecDepRowid"),"OrderEntry","",PAAdmType,..%SessionStr())
			s OrderGridRowAry(USERID,EpisodeID,"OLD","CurrentRecLocStr")=RecLocRetObj.CurrentRecLocStr
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderRecLocStr")=RecLocRetObj.OrderNormalRecLocStr
			
			///tanjishan end
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderFreq")=rset.Data("OrderFreq")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderFreqRowid")=rset.Data("OrderFreqRowid")
			if (rset.Data("OrderFreq")'=""){
				s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderFreqFactor")=$P(^PHCFR(rset.Data("OrderFreqRowid")),"^",2)
				s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderFreqInterval")=$P(^PHCFR(rset.Data("OrderFreqRowid")),"^",5)
			}
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderInstr")=rset.Data("OrderInstr")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderDur")=rset.Data("OrderDur")
			if (rset.Data("OrderDurRowid")'=""){
				s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderDurFactor")=$P(^PHCDU(rset.Data("OrderDurRowid")),"^",2)
			}
			//
			//OrderConFac
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderConFac")=1
			s INCIRowid=##class(web.DHCDocOrderEntry).GetINCI(+rset.Data("OrderARCIMRowid"))
			if (INCIRowid'=""){
				s ConFac=##class(web.DHCDocOrderEntry).GetConFac(rset.Data("OrderARCIMRowid"),INCIRowid,rset.Data("OrderPackUOMRowid")) //应考虑医嘱使用协议单位的情况
				s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderConFac")=ConFac
			}
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderPrice")=rset.Data("OrderPrice")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderPackQty")=rset.Data("OrderPackQty")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderPackUOM")=rset.Data("OrderPackUOM")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderSkinTest")=rset.Data("OrderSkinTest")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderPriorRemarks")=rset.Data("OrderPriorRemarks")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderPriorRemarksRowId")=rset.Data("OrderPriorRemarksRowId")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderRecDep")=rset.Data("OrderRecDep")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderSum")=rset.Data("OrderSum")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderPrescNo")=rset.Data("OrderPrescNo")
			s DepProcNotes=rset.Data("DepProcNotes")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderDepProcNote")=DepProcNotes
			s OrderBodyPartID=""
			if (DepProcNotes'="")&&($L(DepProcNotes)<30){
				s NotesLen=$l(DepProcNotes,",")
				s OrderBodyPart=$p(DepProcNotes,",",NotesLen)
				s OrderBodyPartID=$o(^MRC("BODP",0,"Desc",OrderBodyPart,""))
			}
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderBodyPartID")=OrderBodyPartID
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderDoc")=rset.Data("OrderDoc")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderUserAdd")=rset.Data("OrderUserAdd")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderUserDep")=##Class(web.PAAdm).getPatEpisLoc(EpisodeID)
			//rset.Data("OrderUserDep")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderLogDep")=rset.Data("OrderUserDep")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderBillType")=rset.Data("OrderBillType")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderStartDate")=..%ZD(rset.Data("OrderStartDate"))_" "_..%ZT(rset.Data("OrderStartTime"),1) //$zd(rset.Data("OrderStartDate"),4)_" "_..%ZT(rset.Data("OrderStartTime"),1)
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderFirstDayTimes")=rset.Data("OrderFirstDayTimes")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderFirstDayTimesCode")=rset.Data("OrderFirstDayTimes")
			;增加首日次数下拉框返回
			s OrdFreqInfo=##class(DHCDoc.Interface.Inside.ServiceOrd).GetOrdFreqInfo(OrderItemRowid)	
			s OrderFreqFreeTimeStr=$List(OrdFreqInfo,4)
			s FirstDayTimesRet=##class(web.DHCOEOrdItemView).GetOrderFirstDayTimes(EpisodeID,OrderARCIMRowid,rset.Data("OrderFreqRowid"),OrderPriorRowid,
				OrderGridRowAry(USERID,EpisodeID,"OLD","OrderStartDate"),"",OrderFreqFreeTimeStr,AdmHospitalId)
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderFirstDayTimesStr")=$P(FirstDayTimesRet,"^",3)
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderLabSpec")=rset.Data("OrderLabSpec")
			s OrderLabSpecRowid=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"SPEC",1)),"^",1)
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderLabSpecRowid")=OrderLabSpecRowid
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderLabSpecStr")=##class(web.DHCDocOrderCommon).GetLabSpec(rset.Data("OrderARCIMRowid"),AdmHospitalId)
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderLabEpisodeNo")=rset.Data("OrderLabEpisodeNo")
			
			s OrderLabSpecCollectionSiteStr="",OrderLabSpecCollectionSiteRowid="",OrderLabSpecCollectionSite=""
			if (OrderLabSpecRowid'="") {
				s excode=##class(web.DHCDocOrderCommon).GetExCode(rset.Data("OrderARCIMRowid"))
			    s OrderLabSpecCollectionSiteStr=##Class(DHCLIS.DHCCommon).GetTestSetSpecimenSite(excode,OrderLabSpecRowid,AdmHospitalCode)
			    s OrderLabSpecCollectionSiteRowid=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"SPEC",1,"SITE",1)),"^",1)
				s OrderLabSpecCollectionSite=##Class(DHCLIS.DHCCommon).GetAnatomicalSite(OrderLabSpecCollectionSiteRowid,AdmHospitalCode)
			}
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderLabSpecCollectionSiteRowid")=OrderLabSpecCollectionSiteRowid
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderLabSpecCollectionSite")=OrderLabSpecCollectionSite
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderLabSpecCollectionSiteStr")=OrderLabSpecCollectionSiteStr
			i rset.Data("OrderAutoCalculate")="1"{
				s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderAutoCalculate")="Y"
			}else{
				s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderAutoCalculate")="N"
			}
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderCoverMainIns")=rset.Data("OrderCoverMainIns")
			s OrderBillTypeRowid=rset.Data("OrderBillTypeRowid")
			s OrderInsurCatRowId=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DHC")),"^",3)
			s OrderInsurCat=""
			s InsurCatStr=##class(web.DHCDocOrderListCommon).GetArcimInsurCat(OrderARCIMRowid,OrderBillTypeRowid,AdmHospitalId)
            for i=1:1:$l(InsurCatStr,$C(2)) {
	            s OneInsurCatStr=$p(InsurCatStr,$C(2),i)
	            continue:OneInsurCatStr=""
	            if ($p(OneInsurCatStr,$C(1),1)=OrderInsurCatRowId) s OrderInsurCat=$p(OneInsurCatStr,$C(1),2) Q
            }
			if (OrderInsurCat="") s OrderInsurCatRowId=""
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderInsurCat")=OrderInsurCat
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderInsurCatRowId")=OrderInsurCatRowId
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderInsurCatHideen")=InsurCatStr
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderAction")=rset.Data("OrderAction")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderActionRowid")=rset.Data("OrderActionRowid")
			
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderEndDate")="" //rset.Data()
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderDIACat")= rset.Data("OrderDIACat")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderDIACatRowId")= rset.Data("OrderDIACatRowId") 
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderBodyPart")="" //rset.Data()
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderSpeedFlowRate")=rset.Data("OrderSpeedFlowRate")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderFlowRateUnit")="" //rset.Data()
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderNeedPIVAFlag")=rset.Data("OrderNeedPIVAFlag")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","AntUseReason")=rset.Data("AntUseReason")
			//s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderDate")=$zd(rset.Data("OrderSttDate"),4)_" "_..%ZT(OEORITime,1)
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderDate")=..%ZD(OEORIDate)_" "_..%ZT(OEORITime,1) //$zd(OEORIDate,4)_" "_..%ZT(OEORITime,1)
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderItemRowid")=rset.Data("OrderItemRowid")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderARCIMRowid")=rset.Data("OrderARCIMRowid")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderPriorRowid")=$o(^OECPR(0,"Code","NORM","")) //rset.Data("OrderPriorRowid")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderType")=rset.Data("OrderType")
			/// lxz 新加隐藏元素等-----------------------------------------------------------------------------------------
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderInstrRowid")=rset.Data("OrderInstrRowid")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderDurRowid")=rset.Data("OrderDurRowid")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderPackUOMRowid")=rset.Data("OrderPackUOMRowid")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderRecDepRowid")=rset.Data("OrderRecDepRowid")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderStatusRowid")=rset.Data("OrderStatusRowid")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderBaseUOMRowid")=rset.Data("OrderBaseUOMRowid")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderDocRowid")=rset.Data("OrderDocRowid")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderUserAddRowid")=rset.Data("OrderUserAddRowid")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderLinkTo")=rset.Data("OrderLinkTo")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderARCOSRowid")=rset.Data("OrderARCOSRowid")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderDrugFormRowid")=rset.Data("OrderDrugFormRowid")
			;s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderMaxDurRowid")=rset.Data("OrderMaxDurRowid")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderBillTypeRowid")=rset.Data("OrderBillTypeRowid")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderDoseUOMRowid")=rset.Data("OrderDoseUOMRowid")
			
			;s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderActionRowid")=rset.Data("OrderActionRowid")
			;s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderLabExCode")=rset.Data("OrderLabExCode")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderFlowRateUnit")=rset.Data("OrderFlowRateUnit")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderFlowRateUnitRowId")=rset.Data("OEORIFlowRateUnitDR")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","ExceedReasonID")=rset.Data("ExceedReasonID")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","ExceedReason")=rset.Data("ExceedReasonDesc")
			s OrderPilotProRowId=rset.Data("OrderPilotProRowId")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderPilotProRowid")=OrderPilotProRowId
			s OrderPilotProDesc=""
			i OrderPilotProRowId'="" s OrderPilotProDesc=$P($g(^DHCDocPP(OrderPilotProRowId)),"^",2)
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderPilotPro")=OrderPilotProDesc
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderUsableDays")=rset.Data("OrderUsableDays") ;可用天数
			s OrderGridRowAry(USERID,EpisodeID,"OLD","Urgent")=rset.Data("OrderNotifyClinician")
			//s OrderGridRowAry(USERID,EpisodeID,"OLD","id")=rset.Data("OrderSeqNo")
			//s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderMasterSeqNo")=rset.Data("OrderMasterSeqNo")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","id")=records+1
			if (rset.Data("OrderSeqNo")["."){
				s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderMasterSeqNo")=records+1-$P(rset.Data("OrderSeqNo"),".",2)
			}
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderMaterialBarcode")=rset.Data("MaterialBarCode")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderLocalInfusionQty")=rset.Data("OrderLocalInfusionQty")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderStage")=rset.Data("OrderStage")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderStageCode")=rset.Data("OrderStageCode")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderPilotPro")=rset.Data("OrderPilotPro")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderSelfOMFlag")=rset.Data("OrderSelfOMFlag")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderOutsourcingFlag")=rset.Data("OrderOutsourcingFlag")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderBindSource")=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DHC")),"^",41)
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderHiddenPara")=..GetOrderHiddenPara(EpisodeID,rset.Data("OrderARCIMRowid"),rset.Data("OrderDoseUOMRowid"),OrderItemRowid)
			s $P(OrderGridRowAry(USERID,EpisodeID,"OLD","OrderHiddenPara"),$C(1),30)=$P(FirstDayTimesRet,"^",2)
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderSignFlag")=rset.Data("SignFlag")
			//诊断类别
			s InsType=rset.Data("OrderBillTypeRowid")
			s EpisodeType=$P($G(^PAADM(EpisodeID)),"^",2)
			s PAADMInsType=$P(^PAADM(EpisodeID,1),"^",7)
			i EpisodeType="I" s InsType=PAADMInsType
			s MrAdmRowid=$p($g(^PAADM(EpisodeID)),"^",61)
			s EPDiagnosCat=##class(web.DHCDocOrderCommon).GetEPDiagnosCat(EpisodeType,InsType,MrAdmRowid,AdmHospitalId)
			s EPDiagnosCatStr=""
			for i=1:1:$l(EPDiagnosCat,"^") {
				s DiagnosCatRowid=$p(EPDiagnosCat,"^",i)
				continue:DiagnosCatRowid=""
				s DCDesc=$P(^DHCDiagnosCat(DiagnosCatRowid),"^",1)
				Set DCDesc= ##class(User.DHCDiagnosCat).GetTranByDesc("DCDesc",DCDesc,langid)
				i EPDiagnosCatStr="" s EPDiagnosCatStr=DiagnosCatRowid_$C(1)_DCDesc
				e  s EPDiagnosCatStr=EPDiagnosCatStr_$C(2)_DiagnosCatRowid_$C(1)_DCDesc
			}
			s OrderGridRowAry(USERID,EpisodeID,"OLD","idiagnoscatstr")=EPDiagnosCatStr
			//手术
			s OrderOperation=""
			s OrderOperationCode=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),4)),"^",10)
			if (OrderOperationCode'="") {
		        s curOperId=$P(^OR(EpisodeID,"ANA",$p(OrderOperationCode,"||",2),"OP",$p(OrderOperationCode,"||",3)),"^",6)       ;ANAOP_Type_DR；手术名称
		        if $D(^ORC("OPER",curOperId)) s OrderOperation=$P(^ORC("OPER",curOperId),"^",2)
			}
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderOperation")=OrderOperation
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderOperationCode")=OrderOperationCode
			
			s PoisonRowid=##class(web.DHCDocOrderEntry).GetDrgFormPoison(rset.Data("OrderARCIMRowid"))
		    s PoisonCode=""
		    i PoisonRowid'="" s PoisonCode=$P(^PHCPO(PoisonRowid),"^",1)
	  		s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderPoisonRowid")=PoisonRowid
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderPoisonCode")=PoisonCode
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderFreqDispTimeStr")=rset.Data("OrderFreqDispTimeStr")
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderBodyPartLabel")=##Class(DHCDoc.OPDoc.CopyOrderItemList).GetReqPartID(OrderItemRowid)
			s OrderFreqTimeDoseStr=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DHC")),"^",59)
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderFreqTimeDoseStr")=OrderFreqTimeDoseStr
			if (OrderFreqTimeDoseStr'=""){
				s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderDoseQty")=##class(DHCDoc.Interface.Inside.Service).GetOrdDoseQty(OrderItemRowid)
			}
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderVirtualtLong")=rset.Data("OrderVirtualtLongFlag")
			
			//获取开医嘱医生列
			s DoctorName=""
			s OEORIDoctorDR=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),1)),"^",11)
			s:OEORIDoctorDR'="" DoctorName=$p($g(^CTPCP(+OEORIDoctorDR,1)),"^",2)
			Set DoctorName= ##class(User.CTCareProv).GetTranByDesc("CTPCPDesc",DoctorName,langid)
			s AnaesthesiaID="",OrderOperationCode=""
			s OrderDocStr=##class(web.DHCOEOrdItemView).GetOPSurgeonDocStr(AnaesthesiaID,OrderOperationCode,USERID)
			s DefOrderDoc="",DefOrderDocRowid=""
			if (OrderDocStr'="") {
				for i=1:1:$L(OrderDocStr,"^"){
					s OneOrderDoc=$P(OrderDocStr,"^",i)
					s Default=$P(OneOrderDoc,$C(1),3)
					if (Default="Y") {
						s DefOrderDoc=$P(OneOrderDoc,$C(1),1)
						s DefOrderDocRowid=$P(OneOrderDoc,$C(1),2)
						Q
					}
				}
				if (DefOrderDoc="") {
					if (OEORIDoctorDR'="") {
						s DefOrderDoc=DoctorName
						s DefOrderDocRowid=OEORIDoctorDR
					}else{
						s OneOrderDoc=$P(OrderDocStr,"^",1)
						s DefOrderDoc=$P(OneOrderDoc,$C(1),1)
						s DefOrderDocRowid=$P(OneOrderDoc,$C(1),2)
					}
				}elseif (DefOrderDocRowid'=OEORIDoctorDR){
					s DefOrderDoc=DoctorName
					s DefOrderDocRowid=OEORIDoctorDR
				}
			}else{
				if (OEORIDoctorDR'="") {
					s DoctorName=$p($g(^CTPCP(+OEORIDoctorDR,1)),"^",2)
					s OrderDocStr=DoctorName_$C(1)_OEORIDoctorDR_$C(1)_"Y"
				}
			}
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderDocStr")=OrderDocStr
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderDoc")=DefOrderDoc
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderDocRowid")=DefOrderDocRowid
			s ChronicDiagCode=$p($g(^OEORD(+OrderItemRowid,"I",$p(OrderItemRowid,"||",2),"DHC")),"^",66)
			s ChronicDiagDesc=""
			if (ChronicDiagCode'=""){
				//医保组慢特病
				s ChronicInfo=##class(insuqc.service.ServicePort).GetChronicNameByCode(ChronicDiagCode,AdmReasonDR,AdmHospitalCode)
				s ChronicDiagDesc=$p(ChronicInfo,"^",2)
			}
			s OrderARCIMCode=$p($g(^ARCIM(+OrderARCIMRowid,$p(OrderARCIMRowid,"||",2),1)),"^",1)
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderChronicDiagStr")=##Class(web.DHCOEOrdItemView).GetOrderChronicDiagStr(EpisodeID,OrderARCIMCode,AdmReasonDR)
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderChronicDiag")=ChronicDiagDesc
			s OrderGridRowAry(USERID,EpisodeID,"OLD","OrderChronicDiagCode")=ChronicDiagCode
			
			
			s total=+total+1
			s records=+records+1
			s onedata=..GetOrderJSONStr(USERID,EpisodeID,.OrderGridRowAry)
			i onedata="" continue
			
			
			if (data=""){
				s data=onedata
			}else{
				s data=","_onedata
			}
			w data
			
		}	
		d rset.Close()
	}
	w "]}"
	
	q
}

/// 返回JSON格式字符串
/// w ##class(web.DHCOEOrdItem).GetJSONStr()
/// w ##class(web.DHCOEOrdItem).GetJSONStr()
ClassMethod GetOrderJSONStr(USERID As %String, EpisodeID As %String, ByRef OrderGridRowAry As %String)
{
	s ret=""
	q:(USERID="")||(EpisodeID="") ret
	s Field=""
	f  s Field=$o(OrderGridRowAry(USERID,EpisodeID,"OLD",Field)) q:Field=""  d
	.s key=Field
	.s value=OrderGridRowAry(USERID,EpisodeID,"OLD",Field)
	.i ret="" d
	..s ret=""""_key_""":"""_##class(web.DHCDocUtil).EvalJSON(value)_""""
	.else  d
	..s ret=ret_","_""""_key_""":"""_##class(web.DHCDocUtil).EvalJSON(value)_""""
	i ret'="" s ret="{"_ret_"}" 
	k OrderGridRowAry(USERID)
	q ret
}

/// w ##class(web.DHCDocOrderCommon)InitGridRowId()
/// creator:彭春桥
/// date:2014-04-02
/// desc:医嘱录入表格的行ID控制 type:N(产生ID) R(重置ID), USERID：用户ID,  ADMID:就诊ID
/// table:
ClassMethod InitGridRowId(type As %String, USERID As %String, ADMID As %String, ID As %String = "") As %String
{
	q:(type="")||(USERID="")||(ADMID="") ""
	s rowid=0
	lock +^OrderGridRowId(USERID,ADMID):2
	if $TEST {
		if (type="N"){
			i ($d(^OrderGridRowId(USERID,ADMID))) {
				s rowid=+$g(^OrderGridRowId(USERID,ADMID))+1
				s ^OrderGridRowId(USERID,ADMID)=rowid
			}else{
				s ^OrderGridRowId(USERID,ADMID)=1
				s rowid=^OrderGridRowId(USERID,ADMID)
			}			
		}elseif(type="R"){
			if (ID'=""){
				s ^OrderGridRowId(USERID,ADMID)=ID
			}else{
				s ^OrderGridRowId(USERID,ADMID)=0
			}				
		}
	}
	lock -^OrderGridRowId(USERID,ADMID)
	
	q rowid
}

/// 速度测试
ClassMethod TestTime(code As %String) As %String
{
	q:code="" 0
	s ^TempTestTime("Time",code)=$zd($p($h,",",1),3)_" "_..%ZT(..%SysTime(),1)
	q 0
}

/// 查看
/// w ##class(web.DHCOEOrdItem).FindTestTime()
ClassMethod FindTestTime() As %String
{
	s code="" 
	f  s code=$o(^TempTestTime("Time",code)) q:code=""  d
	.w code_":"_^TempTestTime("Time",code),!
	
	q 0
	//=$zd($p($h,",",1),3)_" "_..%ZT(..%SysTime(),1)
}

/// w ##class(web.DHCOEOrdItem).UpdatePilotProOEItem("114||1*9||144*V*^",2,4634)
ClassMethod UpdatePilotProOEItem(OrdItemStr As %String, Adm As %String = "", User As %String = "", Loc = "", VisitFlag = "") As %String
{
    n (OrdItemStr,Adm,User,Loc,VisitFlag)
    s ^gry("UpdatePilotProOEItem","20100518")=OrdItemStr_","_Adm_","_User
    s AdmType=$p(^PAADM(Adm),"^",2)
    s ExistPPRowid=""
    f k=1:1:$l(OrdItemStr,"^")-1 {
      s newOrdIdDR=$p($p(OrdItemStr,"^",k),"*",2)
      i newOrdIdDR="" continue
      i $D(^OEORD(+newOrdIdDR,"I",$p(newOrdIdDR,"||",2),"DHC")){
        s PPRowID=$p($G(^OEORD(+newOrdIdDR,"I",$p(newOrdIdDR,"||",2),"DHC")),"^",10)
        if (PPRowID'=""){
	        s ExistPPRowid=PPRowID
	        s PPOpenOrdEntryLimit=$p($g(^DHCDocPP(PPRowID)),"^",117)
			if (PPOpenOrdEntryLimit="Y"){ //药理项目开启医嘱录入限制
				s OrderARCIMRowid=$P(^OEORD(+newOrdIdDR,"I",$p(newOrdIdDR,"||",2),1),"^",2)
				//s FreeStr=##class(web.PilotProject.DHCDocPilotProject).CheckArcim(PPRowID,OrderARCIMRowid)
				s FreeStr=##class(web.PilotProject.CFG.FindGCP).CheckArcim(PPRowID,OrderARCIMRowid,Adm)
				s FreeFlag=$p(FreeStr,"^",1)
				if (FreeFlag="Y"){//有效的免费医嘱
					s PPPARowId=##class(web.PilotProject.DHCDocPilotProject).GetPilotProPatAdmRowId(PPRowID,OrderARCIMRowid,Adm)
					if (PPPARowId'=""){
						s StageDr=##class(web.PilotProject.Extend.PatAdd).GetStageByAdm(PPRowID,Adm,"")
						d ##class(web.PilotProject.DHCDocPilotProject).InsertPPAOrdFree(PPPARowId,newOrdIdDR,User,StageDr,VisitFlag)
					}
				}
			}
	    }
      }
    }
    s Hosp=$P($g(^CTLOC(Loc)),"^",22)
    //开启自动结算与退费(仅门诊)
    s OPOrdAutoBilled=$g(^DHCDocPilotSeting(Hosp,"OPOrdAutoBilled"))
    if (ExistPPRowid'="")&&(AdmType="O")&&(OPOrdAutoBilled="Y"){
		d ##class(web.DHCBillInterface).IsPilotOPChargeForOrder(Adm)
	}
    Q 0
}

/// creator:	郭荣勇
/// date:		2015-11-24
/// desc:		判断就诊在某日期和时间之后是否有已经执行的执行记录
/// Table:      OE_OrdItem,OE_OrdExec
/// Input:      OEORIRowId:执行记录指针
/// Return: 
/// OutPut:		所有时间外已执行的第一条执行记录情况
/// w ##class(web.DHCOEOrdItem).CheckAdmIsExecByDateT(399,"","2015-11-24","12:00")
ClassMethod CheckAdmIsExecByDateT(EpisodeID As %String, UserID As %String, CheckDate As %String, CheckTime As %String) As %String
{
	s RetStr=""
	s OrderRowid=##class(web.DHCDocOrderEntry).GetPAADMOrderRowid(EpisodeID)
	Q:OrderRowid="" RetStr
	s AdmHospDr=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(EpisodeID)
	s StopExecByExecTime=..%GetConfig("StopExecByExecTime",AdmHospDr)	;增加配置:停医嘱时按照要求执行时间判断是否可停止
	s NumExecT=0
	s Childsub=0
	for {
		s Childsub=$O(^OEORD(OrderRowid,"I",Childsub)) Q:Childsub=""
		s itemstat=$p($g(^OEORD(OrderRowid,"I",Childsub,1)),"^",13)
		s itemrowid=$p($g(^OEORD(OrderRowid,"I",Childsub,1)),"^",2)
		continue:'($d(^OEORD(OrderRowid,"I",Childsub,1)))
		s statcode=""
		i itemstat'="" s statcode=$p($g(^OEC("OSTAT",itemstat)),"^",1)
		;continue:" V E "'[(" "_statcode_" ")
		s OEORIRetStr=##class(appcom.OEOrdItem).CheckIsExistExecByDateT(OrderRowid_"||"_Childsub,CheckDate,CheckTime)
		s OEORIRet=$p(OEORIRetStr,"^",1)
		s OEORIErrMsg=$p(OEORIRetStr,"^",2)
		s firstExecId=$p(OEORIRetStr,"^",3)
		
		i OEORIRet=0 {
			s ArcimDesc=$P(^ARCIM(+itemrowid,$P(itemrowid,"||",2),1),"^",2)
			s NumExecT=NumExecT+1
			if StopExecByExecTime=1{
				s DateExecuted=$P(^OEORD(+firstExecId,"I",$p(firstExecId,"||",2),"X",$p(firstExecId,"||",3)),"^",19)
				s TimeExecuted=$P(^OEORD(+firstExecId,"I",$p(firstExecId,"||",2),"X",$p(firstExecId,"||",3)),"^",20)
				s Msg=NumExecT_"、"_ArcimDesc_"，执行时间:"_..%ZD(DateExecuted)_" "_..%ZT(TimeExecuted)
			}else{
				s ExeStDate=$P(^OEORD(+firstExecId,"I",$p(firstExecId,"||",2),"X",$p(firstExecId,"||",3)),"^",1)
				s ExeStTime=$P(^OEORD(+firstExecId,"I",$p(firstExecId,"||",2),"X",$p(firstExecId,"||",3)),"^",2)
				s Msg=NumExecT_"、"_ArcimDesc_"，执行记录："_$P($ZD(ExeStDate,3),"-",2,3)_" "_..%ZT(ExeStTime)
			}
			i RetStr="" s RetStr="<p>"_Msg_"</p>"
			e  s RetStr=RetStr_"<p>"_Msg_"</p>"
			Q:NumExecT>=3	//只输出前三条
		}
	}
	if RetStr'=""{
		if StopExecByExecTime=1{
			s RetStr="存在[执行时间]晚于出院医嘱开始时间("_..%ZD(CheckDate)_" "_..%ZT(CheckTime)_")的执行记录被执行"
					_"<p>如需继续开立,请联系护士[修改执行时间]或者[修改出院开始时间]:</p>"_RetStr
		}else{
			s RetStr="存在[要求执行时间]晚于出院医嘱开始时间("_..%ZD(CheckDate)_" "_..%ZT(CheckTime)_")的执行记录被执行"
					_"<p>如需继续开立,请联系护士[撤销执行]或者[修改出院开始时间]:</p>"_RetStr
		}
		s:NumExecT>3 RetStr=RetStr_$c(13,10)_"......"
	}
	Q RetStr
}

/// w ##class(web.DHCOEOrdItem).GetOrdList("4521||14")
ClassMethod GetOrdList(OrdList As %String) As %String
{
	s AppendOrdListStr=##Class(web.UDHCStopOrderLook).GetAppenOrdInfo($replace(OrdList,"&","!"))
	s AppendOrdListStr=$P(AppendOrdListStr,"^",$L(OrdList,"^")+1,$L(AppendOrdListStr,"^"))
	if (AppendOrdListStr'=""){
		 s AppendOrdListStr=$replace(AppendOrdListStr,"!","&")
	 	s OrdList=OrdList_"^"_AppendOrdListStr
	}
    s OrdListStr=""
	s Len=$l(OrdList,"^")
	s StopGroupOrder=..%GetConfig("StopGroupOrder")
	for i=1:1:Len
	{
		s OrderItemStr=$p(OrdList,"^",i)
		s OrItemID=$p(OrderItemStr,"&",1)    //不能改医嘱ID为第一位的位置
		continue:OrItemID=""
		s StartDate=$p(OrderItemStr,"&",2)
		s StartTime=$p(OrderItemStr,"&",3)
		;s OrdLinkRowId=$p(OrderItemStr,"&",4)
		;s OrdLinkRowId=$tr(OrdLinkRowId," ","")
		;不必从界面取的关联医嘱RowId   zhouzq 2010.07.21
		s OrdLinkRowId=$p($g(^OEORD(+OrItemID,"I",$p(OrItemID,"||",2),11)),"^",39)

		if (StopGroupOrder=1)&&(OrdLinkRowId'="")&&(OrdList'[(OrdLinkRowId)) s OrderItemStr=OrdLinkRowId_"&"_StartDate_"&"_StartTime_"&"_""
		if OrdListStr="" s OrdListStr=OrderItemStr
		else  s OrdListStr=OrdListStr_"^"_OrderItemStr
	}
	;医保处方流转-获取全部医嘱
	s InsuOrdList=##class(DHCDoc.Interface.Inside.InsuPresc.Order).GetInsuOrdListByStop(OrdListStr)
	if (InsuOrdList'="") s OrdListStr=InsuOrdList
	q OrdListStr
}

// ;检查是否在既往医嘱的疗程内

/// w ##class(web.DHCOEOrdItem).CheckItemInDuration(2422,"5543||1^R^3^16/03/2020^10:46:40^12^1.3000^243^1^2780||1^^250^19^3000^28^4^17^1^^1^N^^N^^^^^^^N^^^3^^^^^^^^^^^^1^16/03/2020^10:46:40^N^^^^^N^^3^^N^^^^^^^^N^1^^0^^^^15.6000^^^^^^1^N^",6)
ClassMethod CheckItemInDuration(Adm As %String, OrdItemStr As %String, CurLogonDep As %String = "") As %String
{
	n (Adm,OrdItemStr,CurLogonDep,%session)
	s CurLogonHosp =$p($g(^CTLOC(CurLogonDep)),"^",22)
	s PreOrdDateInfo=""
	s EpisodeType=$P($G(^PAADM(Adm)),"^",2)
	q:(EpisodeType'="O") ""
	s PAADMInsType=$P(^PAADM(Adm,1),"^",7)
	q:PAADMInsType="" ""
	s NotAllowItemInDuration=..%GetConfig1("NotAllowItemInDuration",PAADMInsType,CurLogonHosp)
	s LimitDurFactor=0
	s LimitDuratonRowid=..%GetConfig1("BillTypeDuration",PAADMInsType,CurLogonHosp)
    if LimitDuratonRowid'="" s LimitDurFactor=##class(web.DHCDocOrderEntry).GetDurationFactor(LimitDuratonRowid)
    q:LimitDurFactor=0 ""
	s SessionStr=..%SessionStr()
	s GroupID=$P(SessionStr,"^",2)
	if GroupID'=""{
		;补录模式
		s SupplementMode=##class(DHCDoc.DHCDocConfig.Group).GetGroupCfgData("SupplementMode",SessionStr)
		Q:+SupplementMode ""
	}
	s SkinTestInstr=..%GetConfig("SkinTestInstr",CurLogonHosp)

	;检查是否在既往医嘱的疗程内
	s PreStr=""
	s PreOrderDate="",PreOrderIntervalDur=""
	
	Set OrdItemCount=$L(OrdItemStr,$c(1))
	for i=1:1:OrdItemCount {
		s OrdItem=$p(OrdItemStr,$c(1),i)
		continue:OrdItem=""
		s ARCIMRowid=$p(OrdItem,"^",1)
		continue:ARCIMRowid=""
		s OrderType=$p(OrdItem,"^",2)
		continue:OrderType'="R"
		//s AdmReason=$replace($p(OrdItem,"^",9),$c(10),"")
		//continue:AdmReason=""
		Set DurRowid=$p(OrdItem,"^",16)
		continue:DurRowid=""
		Set InstrRowid=$p(OrdItem,"^",17)
		continue:((InstrRowid'="")&&(SkinTestInstr'="")&&(("^"_SkinTestInstr_"^")[("^"_InstrRowid_"^")))
        s PoisonRowid=##class(web.DHCDocOrderEntry).GetDrgFormPoison(ARCIMRowid)
		s CheckItemInDur=0
		;优先确定是否判断精神类药品
		i PoisonRowid'="" s CheckItemInDur=1
		e  i NotAllowItemInDuration'=0 s CheckItemInDur=1
		continue:CheckItemInDur'=1
		i CheckItemInDur=1 d
		.i PreStr="" s PreStr=ARCIMRowid_","_DurRowid
		.e  s PreStr=PreStr_"^"_ARCIMRowid_","_DurRowid
		
    }
    q:PreStr="" ""
    s AdmDate=$p($g(^PAADM(Adm)),"^",6)
    s today=..%SysDate()
    Set PreStrCount=$L(PreStr,"^")
	for i=1:1:PreStrCount {
		s PreOrdItem=$p(PreStr,"^",i)
		s PreArcimRowId=$p(PreOrdItem,",",1)
		s ARCIMDesc=$p(^ARCIM(+PreArcimRowId,$p(PreArcimRowId,"||",2),1),"^",2)
		for j=(i+1):1:PreStrCount{
			s NextPreOrdItem=$p(PreStr,"^",j)
			s NextArcimRowId=$p(NextPreOrdItem,",",1)
			//continue:(NextAdmReason'=PreAdmReason)
			continue:(PreArcimRowId'=NextArcimRowId)
			s NextDurRowid=$p(PreOrdItem,",",2)
			s durfactor=""
			i NextDurRowid'="" s durfactor=$p($g(^PHCDU(NextDurRowid)),"^",2)
	        i durfactor="" s durfactor="0"
			i (AdmDate+durfactor-today>0){
				s PreOrdDateInfo="-1^"_ARCIMDesc_"已经开过相同的医嘱且在疗程内,不允许再开.还剩余"_(AdmDate+durfactor-today)_"天"
			}
			Q:PreOrdDateInfo'=""
		}
		Q:PreOrdDateInfo'=""
		s TempStr=##class(web.DHCDocOrderEntry).CheckItemInDuration(Adm,PAADMInsType,PreArcimRowId)
		i TempStr'="" {
			s PreOrderDate=$P(TempStr,"^",3) s PreOrderIntervalDur=$P(TempStr,"^",4)
			if (PreOrderDate'=""){
				s PreOrdDateInfo="-1^"_PreOrderDate_ARCIMDesc_..%Translate("oeorder.oplistcustom.new.csp","已经开过相同的医嘱且在疗程内,不允许再开治疗用药.还剩余")_PreOrderIntervalDur_..%Translate("oeorder.oplistcustom.new.csp","天")
			}
		}
		Q:PreOrdDateInfo'=""
	}
	Q PreOrdDateInfo  //已经开过相同的医嘱且在疗程内,不允许再开.还剩余
}

/// w ##class(web.DHCOEOrdItem).GetCMOrderDataToEMR(1043)
ClassMethod GetCMOrderDataToEMR(EpisodeID As %String)
{
	s QUE1RowID="" ,ret=""
	f  s QUE1RowID=$o(^PAQUE1(0,"QUE1_PAADM_DR",EpisodeID,QUE1RowID)) q:QUE1RowID=""  d
	.q:'$d(^PAQUE1(QUE1RowID))
	.q:'$d(^PAQUE1(QUE1RowID,"DHC"))
	.s prestype=$p(^PAQUE1(QUE1RowID,"DHC"),"^",2)
    .q:prestype'=3
    .//非医护人员录入不显示
	.s AddUser=$P(^PAQUE1(QUE1RowID,"DHC"),"^",3)
	.s CareProvType=##class(web.DHCDocOrderCommon).GetCareProvType(AddUser)
	.s CareProvType=$zcvt(CareProvType,"U")
	.q:CareProvType'="DOCTOR"
	.s prescno=$p(^PAQUE1(QUE1RowID),"^",14)
	.s OEORDRowId="",prescOrdNum=0, Ordret="",stopflag=0
	.f  s OEORDRowId=$o(^OEORD(0,"PrescNo",prescno,OEORDRowId)) q:OEORDRowId=""  d
	..s OEORIChildsub="" 
	..f  s OEORIChildsub=$o(^OEORD(0,"PrescNo",prescno,OEORDRowId,OEORIChildsub)) q:OEORIChildsub=""  d
	...q:'$d(^OEORD(OEORDRowId,"I",OEORIChildsub))
	...s ItemStat=$p($G(^OEORD(OEORDRowId,"I",OEORIChildsub,1)),"^",13)
    ...i ItemStat="4" s stopflag="1" 
	...s ItmMastrowid=$p(^OEORD(OEORDRowId,"I",OEORIChildsub,1),"^",2)
	...s Subscript=$p(ItmMastrowid,"||",1)
	...s Version=$p(ItmMastrowid,"||",2)
	...s ARCIMDesc=$p(^ARCIM(Subscript,Version,1),"^",2)
	...s DoseQty=$p($g(^OEORD(OEORDRowId,"I",OEORIChildsub,1)),"^",12) //数量
	...s DoseUOM=$p($g(^OEORD(OEORDRowId,"I",OEORIChildsub,2)),"^",3) 
	...s CTUOMDesc=$p(^CT("UOM",DoseUOM),"^",2) //剂量单位
	...s PhSpecInstr=$p($g(^OEORD(OEORDRowId,"I",OEORIChildsub,2)),"^",8) //备注
	...s prescOrdNum=prescOrdNum+1
	...i (prescOrdNum/5)'["." d
	....s Ordret=Ordret_"@"_ARCIMDesc_" "_DoseQty_CTUOMDesc_" "_PhSpecInstr
	...e  d
	....i Ordret="" s Ordret=ARCIMDesc_" "_DoseQty_CTUOMDesc_" "_PhSpecInstr
	....e  s Ordret=Ordret_"      "_ARCIMDesc_" "_DoseQty_CTUOMDesc_" "_PhSpecInstr
	.s insdr=$p(^PAQUE1(QUE1RowID,"DHC"),"^",11)
    .s Instruc=""
    .i insdr'="" s Instruc=$p(^PHCIN(insdr),"^",1) ;用法
    .s durdr=$p(^PAQUE1(QUE1RowID,"DHC"),"^",10)
    .s facotor=""
    .i durdr'="" s facotor=$p(^PHCDU(durdr),"^",2) ;剂数
    .s orderqty=$p(^PAQUE1(QUE1RowID,"DHC"),"^",13) ;用量
    .q:stopflag=1
	.i ret="" s ret=Ordret_"@"_"共"_facotor_"剂"_"  用法:"_Instruc_"   一次用量:"_orderqty
	.e  s ret=ret_"@"_Ordret_"@"_"共"_facotor_"剂"_"  用法:"_Instruc_"   一次用量:"_orderqty
	q ret
}

/// w ##class(web.DHCOEOrdItem).GetOrderDataToEMR(16107)
ClassMethod GetOrderDataToEMR(EpisodeID As %String)
{
	s ret=""
	s AdmHospDr=##class(DHCDoc.Common.Hospital).GetAffiliatedHospitalId(EpisodeID)
	s num=0
	Set OrderId=$o(^OEORD(0,"Adm",EpisodeID,0))
	if OrderId="" Quit ""
	Set sub=0
	for  Set sub=$o(^OEORD(OrderId,"I",sub)) Quit:sub=""  do
	.s ItemStat=$p($G(^OEORD(OrderId,"I",sub,1)),"^",13)
	.Quit:ItemStat=""
 	.s ItemStatCode=$p(^OEC("OSTAT",ItemStat),"^",1)
 	.;b
 	.Quit:((ItemStatCode'="V")&&(ItemStatCode'="E"))
	.;留观医生下的医嘱不同步到病历
	.s EMStayFlag=$p($g(^OEORD(OrderId,"I",sub,"DHC")),"^",17)
	.Quit:EMStayFlag="1"
 	.s ItmMastrowid=$p(^OEORD(OrderId,"I",sub,1),"^",2)
 	.s ItmMastrowid=$p(^OEORD(OrderId,"I",sub,1),"^",2)
 	.s checkrtn=##class(web.DHCOPAdmReg).GetRegArcimBillSubType(ItmMastrowid)
 	.Quit:(checkrtn="Reg")||(checkrtn="Check")
 	.s Subscript=$p(ItmMastrowid,"||",1)
 	.s Version=$p(ItmMastrowid,"||",2)
 	.s ARCIMDesc=$p(^ARCIM(Subscript,Version,1),"^",2)
 	.s OEORIDoseQty=$p($g(^OEORD(OrderId,"I",sub,2)),"^",1)
 	.S OEORIUnit=""
 	.S OEORIPHFreq=""
 	.S OEORIDurat=""
 	.s OEORIUnitDR=$p($g(^OEORD(OrderId,"I",sub,2)),"^",3)
 	.i OEORIUnitDR'="" D
 	..s OEORIUnit=$p(^CT("UOM",OEORIUnitDR),"^",2)
 	.s OEORIPHFreqDR=$p($g(^OEORD(OrderId,"I",sub,2)),"^",4)
 	.i OEORIPHFreqDR'="" d
 	..s OEORIPHFreq=$p($g(^PHCFR(OEORIPHFreqDR)),"^",3)
 	.s OEORIDuratDR=$p($g(^OEORD(OrderId,"I",sub,2)),"^",6)
 	.i OEORIDuratDR'="" D
 	..s OEORIDurat=$p(^PHCDU(OEORIDuratDR),"^",3)
 	.s ItemCatDR=$p(^ARCIM(Subscript,Version,1),"^",10)
 	.// 过滤掉不需要的医嘱
 	.;b ;1
 	.//q:(ItemCatDR=33)||(ItemCatDR=34)||(ItemCatDR=59)||(ItemCatDR=195)||(ItemCatDR=198)||(ItemCatDR=203)||(ItemCatDR=224)  ;33、34、59,、195,198,203,224,
	.s PHPrescType=##class(web.DHCDocOrderCommon).GetPHPrescType(ItemCatDR,AdmHospDr,ItmMastrowid)
	.Q:(PHPrescType=3)
 	.s num=num+1
 	.if ret="" Set ret=num_"  "_ARCIMDesc_" "_OEORIDoseQty_"  "_OEORIUnit_" "_OEORIPHFreq_" "_OEORIDurat
 	.else  Set ret=ret_"@"_num_"  "_ARCIMDesc_" "_OEORIDoseQty_"  "_OEORIUnit_" "_OEORIPHFreq_" "_OEORIDurat
 	.s linksub=0
 	.for  s linksub=$o(^OEORDi(0,"OEORI",OrderId,OrderId_"||"_sub,linksub)) Quit:linksub=""  do
 	..s ItmMastrowid=$p($g(^OEORD(OrderId,"I",linksub,1)),"^",2)
 	..s Subscript=$p(ItmMastrowid,"||",1)
 	..s Version=$p(ItmMastrowid,"||",2)
 	..s ARCIMDesc=$p(^ARCIM(Subscript,Version,1),"^",2)
 	..s OEORIDoseQty=$p($g(^OEORD(OrderId,"I",linksub,2)),"^",1)
 	..S OEORIUnit=""
 	..S OEORIPHFreq=""
 	..S OEORIDurat=""
 	..s OEORIUnitDR=$p($g(^OEORD(OrderId,"I",linksub,2)),"^",3)
 	..i OEORIUnitDR'="" D
 	...s OEORIUnit=$p(^CT("UOM",OEORIUnitDR),"^",2)
 	..s OEORIPHFreqDR=$p($g(^OEORD(OrderId,"I",linksub,2)),"^",4)
 	..i OEORIPHFreqDR'="" d
 	...s OEORIPHFreq=$p(^PHCFR(OEORIPHFreqDR),"^",3)
 	..s OEORIDuratDR=$p($g(^OEORD(OrderId,"I",linksub,2)),"^",6)
 	..I OEORIDuratDR D
 	...s OEORIDurat=$p(^PHCDU(OEORIDuratDR),"^",3)
 	..s ret=ret_"+"_ARCIMDesc_" "_OEORIDoseQty_" "_OEORIUnit_" "_OEORIPHFreq_" "_OEORIDurat
 	q ret
}

// 判断医嘱在互斥医嘱开始日期和时间之后，是否存在未停止的执行记录

// w ##class(web.DHCOEOrdItem).CheckOrdIsExecByDateT()

ClassMethod CheckOrdIsExecByDateT(OrdItmRowId As %String, OrdSttDate As %String) As %String
{
	s FindValidExec=0
	s OEOREExStDate=OrdSttDate-1
	for {
		s OEOREExStDate=$o(^OEORDi(0,"Date",+OrdItmRowId,OEOREExStDate))
		q:OEOREExStDate=""
		i FindValidExec=1 q
		s OEOREExStTime=0
		for{
			s OEOREExStTime=$o(^OEORDi(0,"Date",+OrdItmRowId,OEOREExStDate,OEOREExStTime))
			q:OEOREExStTime=""
			i FindValidExec=1 q
			s childSub=0  F {
				s childSub=$o(^OEORDi(0,"Date",+OrdItmRowId,OEOREExStDate,OEOREExStTime,$p(OrdItmRowId,"||",2),childSub))
				Q:childSub=""
				s ExecOrdStatusCode=""
				s ExecOrdStatusRowId=$P(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),"X",childSub),"^",16)
				if ExecOrdStatusRowId'="" s ExecOrdStatusCode=$P($G(^OEC("STAT",ExecOrdStatusRowId)),"^",1)
				b //
				if (ExecOrdStatusCode'="D") s FindValidExec=1 q 
			}
		}
	}
	Q FindValidExec
}

ClassMethod GetOrderHiddenPara(EpisodeID As %String, ArcimRowid As %String, DoseUOMRowid As %String, OrderItemRowid As %String) As %String
{
	s skintestyy="",FormDoseQty="",PHCDFCQZTFlag="",PHCDFONEFlag="",PHCDFCHKOMFlag="",PHCDFCriticalFlag=""
	s DrgformRowid=##class(web.DHCDocOrderEntry).GetDrgForm(ArcimRowid)
	i DrgformRowid'="" {
	  s PHCDRowid=$P(DrgformRowid,"||",1)
	  s ChildSub=$P(DrgformRowid,"||",2)
	  s EpisodeType=$p(^PAADM(EpisodeID),"^",2)
		;皮试是否使用原液
		i EpisodeType="I" d
		.s skintestyy=$p($g(^PHCD(PHCDRowid,"DF",ChildSub,"DHC")),"^",3)
		e  d
		.s skintestyy=$p($g(^PHCD(PHCDRowid,"DF",ChildSub,"DHC")),"^",2)
		s FormDoseUOMRowid=$p($g(^PHCD(PHCDRowid,"DF",ChildSub,2)),"^",4)
		if (FormDoseUOMRowid=DoseUOMRowid){
			s FormDoseQty=$p($g(^PHCD(PHCDRowid,"DF",ChildSub,2)),"^",5) ;Pharmacy base UOM
		}else{
			s leq=0  f  s leq=$o(^PHCD(PHCDRowid,"DF",ChildSub,"EQ",leq)) q:leq=""  d
		   .s eqrec=^PHCD(PHCDRowid,"DF",ChildSub,"EQ",leq)
		   .s FormDoseUOMRowid=$p(eqrec,"^"),eqqty=$p(eqrec,"^",2),eqdefaultqty=$p(eqrec,"^",3)
		   .Q:(DoseUOMRowid'="")&&(FormDoseUOMRowid'=DoseUOMRowid)
		   .if eqdefaultqty'="" s FormDoseQty=eqdefaultqty
		   .e  d
		   ..i PHUseEqQty=1 s FormDoseQty=eqqty
		   ..e  s FormDoseQty=""
		   .i (FormDoseQty'="")&(FormDoseQty<1)&(FormDoseQty'=0) s FormDoseQty="0"_FormDoseQty
	   }
	   s PHCDFCQZTFlag=$p($g(^PHCD(PHCDRowid,"DF",ChildSub,"DHC")),"^",40) //长期默认嘱托
       s PHCDFONEFlag=$p($g(^PHCD(PHCDRowid,"DF",ChildSub,"DHC")),"^",41) //临时默认取药
       s PHCDFCHKOMFlag=$p($g(^PHCD(PHCDRowid,"DF",ChildSub,"DHC",2)),"^",2) //附加说明默认自备
       s PHCDFCriticalFlag=$p($g(^PHCD(PHCDRowid,"DF",ChildSub,"DHC")),"^",9) //危重药标志
	}
	;住院是否需要录入整包装数量 
	s IPNeedBillQty=##class(web.DHCDocOrderCommon).GetARCIMIPNeedBillQty(ArcimRowid)
	s OrderItemCatRowid=$p($g(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),1)),"^",10)
	;单次最大基本剂量	ARCIM_MaxCumDose
	s OrderMaxDoseQty=$p($g(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),9)),"^",30) 
	;一天总剂量	ARCIM_MaxQtyPerDay
	s OrderMaxDoseQtyPerDay=$p($g(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),9)),"^",37)  
	;限制疗程	ARCIM_NoOfCumDays
	s OrderLimitDays=$p($g(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),9)),"^",31) 
	s OrderMaxDoseQtyPerOrder=$p($g(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),9)),"^",38)  
	s NeedSkinTestINCI =##class(web.DHCOutPhCommon).GetSkinTestFlag(ArcimRowid)
	
	s SttIsCanCrossDay="",SameFreqDifferentDosesFlag="N",OrdDateIsCanCrossDay="",RequireNote="N"
	s DHCARCIMRowid=$O(^DHCItmMast("0","ARCIM",ArcimRowid,0))
	i DHCARCIMRowid'="" d
	.s SttIsCanCrossDay=$P(^DHCItmMast(DHCARCIMRowid),"^",11) //医嘱开始日期时间是否可以跨日
	.s OrdDateIsCanCrossDay=$P(^DHCItmMast(DHCARCIMRowid),"^",25) //开医嘱日期时间是否可以跨日
	.s SameFreqDifferentDosesFlag=$P(^DHCItmMast(DHCARCIMRowid),"^",22)
	.s RequireNote=$P(^DHCItmMast(DHCARCIMRowid),"^",5)
		
    s IncItmHighValueFlag=##class(web.DHCDocOrderCommon).GetIncItmHighValueFlag(ArcimRowid)
    s INCIRowid=##class(web.DHCDocOrderEntry).GetINCI(+ArcimRowid)
    s ArcimCode=$p(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),1),"^",1)
    s ARCIMExtInfo=##class(DHCDoc.DHCDocConfig.ARCIMExt).getARCIMConfig(ArcimRowid)
	s StopAfterLongOrderFlag=$P(ARCIMExtInfo,"^",3)
    s OrderOpenForAllHosp=0
    if (OrderItemRowid'="") {
    	s OrderOpenForAllHosp=$case($p($g(^OEORD(+OrderItemRowid,"I",$P(OrderItemRowid,"||",2),"DHC")),"^",58),"Y":1,:0)
    }
    s OrderPracticePreRowid=""
    ;医生站设置-药房设置-临时医嘱拆分整包装发药(仅在急诊留观押金的虚拟长期模式下有效),可拆分发药的接受科室串
    s NormSplitPackQtyPHRecLocList=##Class(web.DHCDocOrderVirtualLong).GetNormSplitPackQtyPHRecLocList(EpisodeID,OrderItemCatRowid)
    ;有多个可拆分发药科室串以^分割，实习医生开立审核后会和实习医嘱表DHC_PracticeDocPreOrder的系统分割符冲突
    s NormSplitPackQtyPHRecLocList=$replace(NormSplitPackQtyPHRecLocList,"^","!")
    ;是否可以使用紧急标志
	s Sensitive=$p($g(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),9)),"^",18)
	;是否默认加急
	s ARCIMDefSensitive= $p($g(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),9)),"^",41) 
    s OrderHiddenPara=skintestyy_$C(1)_IPNeedBillQty_$C(1)_OrderItemCatRowid_$C(1)_OrderMaxDoseQty_$C(1)_OrderMaxDoseQtyPerDay_$C(1)_OrderLimitDays_$C(1)_OrderMaxDoseQtyPerOrder
    s OrderHiddenPara =OrderHiddenPara_$C(1)_NeedSkinTestINCI_$C(1)_SttIsCanCrossDay_$C(1)_IncItmHighValueFlag_$C(1)_INCIRowid
    s OrderHiddenPara =OrderHiddenPara_$C(1)_ArcimCode_$C(1)_PHCDFCQZTFlag_$C(1)_PHCDFONEFlag_$C(1)_StopAfterLongOrderFlag_$C(1)_PHCDFCHKOMFlag_$c(1)_FormDoseQty
    s OrderHiddenPara =OrderHiddenPara_$C(1)_PHCDFCriticalFlag_$C(1)_OrderOpenForAllHosp_$C(1)_SameFreqDifferentDosesFlag
    s OrderHiddenPara =OrderHiddenPara_$C(1)_""_$C(1)_RequireNote_$C(1)_OrdDateIsCanCrossDay_$C(1)_OrderPracticePreRowid_$C(1)_NormSplitPackQtyPHRecLocList
    s OrderHiddenPara =OrderHiddenPara_$C(1)_Sensitive_$C(1)_ARCIMDefSensitive
    Q OrderHiddenPara
}

/// 【医嘱项扩展设置】-长期自备药需要插入临时取药医嘱
/// d ##Class(web.DHCOEOrdItem).AutoInsertOneOrdByOMST(2,"589||1*4||86*V*^")
ClassMethod AutoInsertOneOrdByOMST(EpisodeID As %String, ByRef InsertRet As %String) As %String
{
	n (EpisodeID,InsertRet)
	s ^tan("AutoInsertOneOrdByOMST")=EpisodeID_","_InsertRet
	s $ZT="AutoInsertOneOrdByOMSTErr"
	s PAADMType=$p($g(^PAADM(EpisodeID)),"^",2)
	q:(PAADMType'="I") ""
	s AdmLoc=$p(^PAADM(EpisodeID),"^",4)
	s OrderRowid=$o(^OEORD(0,"Adm",+EpisodeID,""))
	s OMSTPriorRowID=$O(^OECPR(0,"Code","OMST",0))
	s OMCQZTPriorRowID=$O(^OECPR(0,"Code","OMCQZT",0))
	s PriorIDList=OMSTPriorRowID_"^"_OMCQZTPriorRowID
	//q:(OMSTPriorRowID="") ""
	//先找到可能需要绑定取药医嘱的医嘱列表
	k OrdList
	if (InsertRet'=""){
		//下医嘱直接绑定
		For i=1:1:$L(InsertRet,"^") {
	  		Set OrdItemArry=$P(InsertRet,"^",i)
	  		Set OrdId=$P(OrdItemArry,"*",2)
	  		continue:(OrdId="")
	  		s SubChild=$P(OrdId,"||",2)
	  		s PriorRowid=$p($g(^OEORD(+OrdId,"I",SubChild,1)),"^",8)
			continue:(("^"_PriorIDList_"^")'[("^"_PriorRowid_"^"))
	  		d GetAutoOMSTOrdList
		}
	}else{
		//滚医嘱时判断绑定
		for i=1:1:$L(PriorIDList,"^"){
			s NeedPriorRowID=$P(PriorIDList,"^",i)
			continue:(NeedPriorRowID="")
			s SubChild=0
			for {
				s SubChild=$O(^OEORDi(0,"Priority",OrderRowid,NeedPriorRowID,SubChild))
				q:(SubChild="")
				d GetAutoOMSTOrdList
			}
		}
	}
	
	//判断当前取药医嘱是否满足自备药长期的用药量
	s ArcimRowid=0
	for {
		s ArcimRowid=$O(OrdList(ArcimRowid))
		q:(ArcimRowid="")
		s OrdList=$G(OrdList(ArcimRowid))
		//先获取已绑定的取药医嘱的总量
		s OneTotalQty=0
		s BindSttDat=0
		for {
			s BindSttDat=$O(^OEORDi(0,"ARCIM",OrderRowid,ArcimRowid,BindSttDat))
			q:BindSttDat=""
			s BindSubChild=0
			for {
				s BindSubChild=$O(^OEORDi(0,"ARCIM",OrderRowid,ArcimRowid,BindSttDat,BindSubChild))
				q:BindSubChild=""
				s PriorRowid=$p($g(^OEORD(OrderRowid,"I",BindSubChild,1)),"^",8)
				s PriorCode=$P(^OECPR(PriorRowid),"^",1)
				continue:(PriorCode'="ONE")
				s StatusDR=$p($g(^OEORD(OrderRowid,"I",BindSubChild,1)),"^",13)
				s StatusCode=$p($g(^OEC("OSTAT",StatusDR)),"^",1)
				continue:("VE")'[StatusCode
				//医生手工录入的取药医嘱应该也要算到计算量里面去
				//s BindSource=$P($G(^OEORD(OrderRowid,"I",BindSubChild,"DHC")),"^",41)
				//continue:(BindSource'="OMIO")
				s DSPRowId=0
				for {
					s DSPRowId=$O(^DHCOEDISQTY(0,"OEORI",OrderRowid_"||"_BindSubChild,DSPRowId))
					q:(DSPRowId="")
					s myTotalQty=$P(^DHCOEDISQTY(DSPRowId),"^",2)
					s myStatus=$p(^DHCOEDISQTY(DSPRowId),"^",7)
					s myConfirmQty=0
					if (myStatus="R"){
						s myConfirmQty=$p(^DHCOEDISQTY(DSPRowId),"^",11)
					}
					s OneTotalQty=OneTotalQty+myTotalQty-myConfirmQty
				}
			}
		}
		//在获取当前自备药长期用药的实际使用量
		s OMSTTotalQty=0
		for i=1:1:$L(OrdList,"^"){
			s OMSTOrderItemRowId=$P(OrdList,"^",i)
			continue:(OMSTOrderItemRowId="")
			//从执行记录出发，控制用药
			s xSub=0
			for {
				s xSub=$O(^OEORD(OrderRowid,"I",$P(OMSTOrderItemRowId,"||",2),"X",xSub))
				q:(xSub="")
				s XStatusDr=$P(^OEORD(OrderRowid,"I",$P(OMSTOrderItemRowId,"||",2),"X",xSub),"^",16)
				if (XStatusDr'=""){
					s XStatusCode=$P($G(^OEC("STAT",XStatusDr)),"^",1)
					continue:("D"[XStatusCode)
				}
				s DSPRowId=0
				for {
					s DSPRowId=$O(^DHCOEDISQTY(0,"OEORE",OMSTOrderItemRowId_"||"_xSub,DSPRowId))
					q:(DSPRowId="")
					s myTotalQty=$P(^DHCOEDISQTY(DSPRowId),"^",2)
					s myStatus=$p(^DHCOEDISQTY(DSPRowId),"^",7)
					s myConfirmQty=0
					if (myStatus="R"){
						s myConfirmQty=$p(^DHCOEDISQTY(DSPRowId),"^",11)
					}
					s OMSTTotalQty=OMSTTotalQty+myTotalQty-myConfirmQty
				}
			}
			
		}
		s OrdList(ArcimRowid,"QtyInfo")=OneTotalQty_"^"_OMSTTotalQty
	}
	///根据实际差距用量，补充取药医嘱
	s OnePriorRowID=$O(^OECPR(0,"Code","ONE",0))
	s MasterSeqNo=0
	Set Config=##Class(websys.Configuration).%OpenId(1)
	Set LABDATA=Config.LabDataNamespace
	s InserOrdStr=""
	s ArcimRowid=0
	for {
		s ArcimRowid=$O(OrdList(ArcimRowid))
		q:(ArcimRowid="")
		s OrderItemRowId=$P(OrdList(ArcimRowid),"^",$L(OrdList(ArcimRowid),"^"))
		continue:(OrderItemRowId="")
		s SubOrd=$P(OrderItemRowId,"||",2)
		s UserAdd=$p($g(^OEORD(OrderRowid,"I",SubOrd,7)),"^",1)
		s UserDepartId=$p($g(^OEORD(OrderRowid,"I",SubOrd,7)),"^",2)
		s DocDr=$p($g(^OEORD(OrderRowid,"I",SubOrd,1)),"^",11)
		s OneTotalQty=$P($G(OrdList(ArcimRowid,"QtyInfo")),"^",1)
		s OMSTTotalQty=$P($G(OrdList(ArcimRowid,"QtyInfo")),"^",2)
		s NeddQty=OMSTTotalQty-OneTotalQty
		continue:(NeddQty<=0)
		//s ArcimBillUOMRowid=$p($g(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),8)),"^",14)
		//s NeedPackQty=1
		s ArcimBillUOMRowid=##Class(web.DHCDocOrderCommon).GetBillUOMRowID(ArcimRowid,PAADMType)
		s convFac=##class(appcom.OEDispensing).convFac(ArcimRowid,ArcimBillUOMRowid)
		s NeedPackQty=(NeddQty\convFac)+$CASE((NeddQty#convFac),0:0,:1)	
		
			
		Set ItemCatDR=$p(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),1),"^",10)
		Set OrderType=$P(^ARC("IC",ItemCatDR),"^",7)
		Set startdate=""
		Set starttime=""
		Set oeprice=""
		Set RecDepRowid=$$GetRecloc^DHCDocOrderCommonNew(EpisodeID,ArcimRowid)
		Set AdmReason=$p($g(^OEORD(OrderRowid,"I",SubOrd,11)),"^",18)
		Set DrugFormRowid=""
		Set DepProcNotes=""
		Set DoseQty=""
		Set DoseUOMRowid=""
		Set FreqRowid=""
		Set DurRowid=""
		Set InstrRowid=""
		Set PHPrescType=""
		Set SkinTest=""
		Set PhSpecInstr=""
		Set OrderCoverMainIns=$p($g(^OEORD(OrderRowid,"I",SubOrd,3)),"^",3)
		Set ActionRowid=""
		Set ARCOSRowid=""
		Set EndDate=""
		Set EndTime=""
		Set ExecuteDateStr=""
		Set NotifyClinician=""
		Set DIACatRowId=""
		Set InsurCatRowId=""	
		;Set PackQty=1
		;Set DoseQtySum=1
		Set PackQty=NeedPackQty
		Set DoseQtySum=NeedPackQty
		Set OrderSeqNo=""
		Set MasterSeqNo=""
		Set AppendOrdItem=ArcimRowid_"^"_OrderType_"^"_OnePriorRowID_"^"_startdate_"^"_starttime_"^"_PackQty_"^"_oeprice
  		Set AppendOrdItem=AppendOrdItem_"^"_RecDepRowid_"^"_AdmReason_"^"_DrugFormRowid_"^"_DepProcNotes
  		Set AppendOrdItem=AppendOrdItem_"^"_DoseQty_"^"_DoseUOMRowid_"^"_DoseQtySum_"^"_FreqRowid_"^"_DurRowid_"^"_InstrRowid
  		Set AppendOrdItem=AppendOrdItem_"^"_PHPrescType_"^"_MasterSeqNo_"^"_OrderSeqNo_"^"_SkinTest_"^"_PhSpecInstr_"^"_OrderCoverMainIns
  		Set AppendOrdItem=AppendOrdItem_"^"_ActionRowid_"^"_ARCOSRowid
  		Set $p(AppendOrdItem,"^",55)=ArcimBillUOMRowid
  		Set $P(AppendOrdItem,"^",58)="OMIO"
		
		Set Ret=$$InsertMultiple^DHCDocOrderCommonNew(EpisodeID,AppendOrdItem,UserAdd,UserDepartId,DocDr,LABDATA)
		;-----
		If (Ret'=0)&&(Ret'=100){
			i (InserOrdStr=""){
				s InserOrdStr=Ret
			}else{
				s InserOrdStr=InserOrdStr_"^"_Ret
			}	
		}
	}
	i (InserOrdStr'=""){
		i (InsertRet'=""){
			s InsertRet=InsertRet_"^"_InserOrdStr
		}else{
			s InsertRet=InsertRet_"^"_InserOrdStr
		}	
	}
	q InserOrdStr
	
	
GetAutoOMSTOrdList
	s StatusDR=$p($g(^OEORD(OrderRowid,"I",SubChild,1)),"^",13)
	s StatusCode=$p($g(^OEC("OSTAT",StatusDR)),"^",1)
	q:("VE")'[StatusCode
	s ArcimRowid=$P($G(^OEORD(OrderRowid,"I",SubChild,1)),"^",2)
	q:(ArcimRowid="")
	s OrdDeptDR=$P($G(^OEORD(OrderRowid,"I",SubChild,1)),"^",3)
	q:(AdmLoc'=OrdDeptDR)
	s DARCIMRowid=$O(^DHCItmMast("0","ARCIM",ArcimRowid,0))
	q:(DARCIMRowid="")
	s AutoInsertONEOrd=$P(^DHCItmMast(DARCIMRowid),"^",15)
	q:(AutoInsertONEOrd'="Y")
	if ($D(OrdList(ArcimRowid))){
		s OrdList(ArcimRowid)=OrdList(ArcimRowid)_"^"_OrderRowid_"||"_SubChild
	}else{
		s OrdList(ArcimRowid)=OrderRowid_"||"_SubChild
	}
	q
AutoInsertOneOrdByOMSTErr
	s myDate=..%SysDate()
	s count=$o(^DHCSYSERROR($ZN,myDate,""),-1)+1
	s ^DHCSYSERROR($ZN,myDate, count)="100^<ERROR>"_"---"_$ZERROR_"  "_$H_","_EpisodeID_","_InsertRet
	q
}

/// 护士临时绑定长期条件判断
/// 0 条件满足  1  不满足
/// w ##class(web.DHCOEOrdItem).CheckNurseLinkFlag("9||123",3)
ClassMethod CheckNurseLinkFlag(LinkOrderRowId As %String, PriorRowId As %String) As %String
{
	s ^teml("CheckNurseLinkFlag")=LinkOrderRowId_","_PriorRowId
	s Flag=1
	s LinkPriorRowId=$p($g(^OEORD(+LinkOrderRowId,"I",$P(LinkOrderRowId,"||",2),1)),"^",8)
	s StatusCode=##class(appcom.OEOrdItem).GetStatusCode(LinkOrderRowId)
	q:StatusCode'="V" 1
	q:'##class(appcom.OEOrdItem).ISLongOrderPrior(LinkPriorRowId) "1" //非长嘱不能帮临嘱
	q:##class(appcom.OEOrdItem).ISShortOrderPrior(PriorRowId) 0
	//q:(##class(appcom.OEOrdItem).ISLongOrderPrior(LinkPriorRowId)=##class(appcom.OEOrdItem).ISLongOrderPrior(PriorRowId))||(##class(appcom.OEOrdItem).ISShortOrderPrior(LinkPriorRowId)=##class(appcom.OEOrdItem).ISShortOrderPrior(PriorRowId)) 1    ///医嘱类型不一致
	q Flag
}

/// w ##class(web.DHCOEOrdItem).GetOrderPopoverInfo("180||51")
ClassMethod GetOrderPopoverInfo(OrderRowId As %String, TOrderDescInfo As %String, langid As %String = "") As %String
{
	n (OrderRowId,TOrderDescInfo,langid)
	s OrderInfo=""
	q:+OrderRowId=0 TOrderDescInfo
	s adm=$p(^OEORD(+OrderRowId),"^",1)
	s locrep=$p(^PAADM(adm),"^",4)
	s AdmLocHospDr=$p($g(^CTLOC(locrep)),"^",22)
	s NurseLinkOrderRowId=$p($g(^OEORD(+OrderRowId,"I",$p(OrderRowId,"||",2),"DHC")),"^",54)
	i +NurseLinkOrderRowId'="0" { //临时护嘱绑定的长期医嘱id/所辅助的治疗医嘱 
		s ArcimRowId=$p($g(^OEORD(+NurseLinkOrderRowId,"I",$p(NurseLinkOrderRowId,"||",2),1)),"^",2)
		s ArcimDesc=$P(^ARCIM(+ArcimRowId,$P(ArcimRowId,"||",2),1),"^",2)
		s SubStatusCode=##class(appcom.OEOrdItem).GetStatusCode(NurseLinkOrderRowId)
		s SubStatusDesc=$case(SubStatusCode,"V":"核实","U":"作废","C":"撤销","E":"执行","D":"停止","I":"未激活")
		s TStopDate = $p($g(^OEORD(+NurseLinkOrderRowId,"I",$p(NurseLinkOrderRowId,"||",2),3)),"^",34)	
		s SubStatusDesc=##class(User.OECOrderStatus).GetTranByDesc("OSTATDesc",SubStatusDesc,langid)
		if (TStopDate>+$h) s SubStatusDesc=..%Translate("ipdoc.patinfoview.csp","预停",langid)
		
		s ArcimDesc=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",ArcimDesc,langid)
		s ArcimDesc="<font style='color:red;'>("_SubStatusDesc_")</font>"_ArcimDesc
		s OrderInfo=..%Translate("ipdoc.patinfoview.csp","主医嘱:",langid)_"<br/>"_ArcimDesc
	}else { //被补录的长期医嘱/治疗医嘱泡芙显示
	    s SubRowId=0
	    f {
		   s SubRowId=$o(^OEORDi(0,"SERORD",OrderRowId,+OrderRowId,SubRowId))
		   Q:SubRowId=""
		   ;拿下医嘱医护人员的类型 ;
			Set OrdInternalType=""
			Set OrdDoctorDr = $p(^OEORD(+OrderRowId,"I",SubRowId,1),"^",11)
			if OrdDoctorDr>0 {
				Set OrdCTPCPCarPrvTpDR = $p(^CTPCP(OrdDoctorDr,1),"^",4)
				If OrdCTPCPCarPrvTpDR>0 {
					Set OrdInternalType = $p(^CT("CPT",OrdCTPCPCarPrvTpDR),"^",4)
				}
			}
		   s ArcimRowId=$p($g(^OEORD(+OrderRowId,"I",SubRowId,1)),"^",2)
		   s ArcimDesc=$P(^ARCIM(+ArcimRowId,$P(ArcimRowId,"||",2),1),"^",2)
		   s LinkPriorRowId=$p($g(^OEORD(+OrderRowId,"I",SubRowId,1)),"^",8) //$p($g(^OEORD(+OrderRowId,"I",$P(OrderRowId,"||",2),1)),"^",8)
		   i ##class(appcom.OEOrdItem).ISShortOrderPrior(LinkPriorRowId)=1 {
			   if (OrdInternalType="NURSE"){
			   	  s Desc="临时护嘱:"
			   }else {
				   s Desc="临时医嘱:"
			   }
		    }
		   i ##class(appcom.OEOrdItem).ISLongOrderPrior(LinkPriorRowId)=1 {
			   if (OrdInternalType="NURSE"){
			   	  s Desc="长期护嘱:"
			   }else {
				   s Desc="长期医嘱:"
			   }
		   }
		   
			s SubStatusCode=##class(appcom.OEOrdItem).GetStatusCode(+OrderRowId_"||"_SubRowId)
			s SubStatusDesc=$case(SubStatusCode,"V":"核实","U":"作废","C":"撤销","D":"停止","E":"执行",:"")

			s Desc=..%Translate("ipdoc.patinfoview.csp",Desc,langid)
			s SubStatusDesc=##class(User.OECOrderStatus).GetTranByDesc("OSTATDesc",SubStatusDesc,langid)
			s ArcimDesc=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",ArcimDesc,langid)
			s ArcimDesc="<font style='color:red;'>("_SubStatusDesc_")</font>"_ArcimDesc
			i OrderInfo="" {
				s OrderInfo=Desc_"<br/>"_ArcimDesc
			}else{
				s OrderInfo=OrderInfo_"<br/>"_ArcimDesc 
			}
		}
	}
	s IsExistCNSubOrdFlag=0
	//^PAQUE1(0,"DHCPAQue","AddLongOrderID","180||31",694)
	s CMOrderRowId=OrderRowId
	d GetCMPrescInfo
	if $D(^PAQUE1(0,"DHCPAQue","AddLongOrderID",OrderRowId)){
		s PAQue1RowID=$O(^PAQUE1(0,"DHCPAQue","AddLongOrderID",OrderRowId,0))
		if (PAQue1RowID'=""){
			s CMOrderRowId=$P($G(^PAQUE1(PAQue1RowID,"DHC")),"^",34)
			d GetCMPrescInfo
		}
	}
	i (OrderInfo="") s OrderInfo= "0@"_TOrderDescInfo
	else  s OrderInfo= "1@"_OrderInfo
	q OrderInfo
GetCMPrescInfo
	q:(+CMOrderRowId="0")
	s PrescNo=$p($g(^OEORD(+CMOrderRowId,"I",$p(CMOrderRowId,"||",2),1)),"^",14)
	if PrescNo'=""{ //草药处方泡芙显示
		s IsCMPresType = ##Class(web.DHCDocPrescript).IsPrescType(PrescNo)
		if (IsCMPresType="1"){
			s num=1
            s MasterCNOrderInfo=$$GetCNOneInfo(CMOrderRowId)
            s TCNPrescInfo=$$GetCNPrescInfo(CMOrderRowId,PrescNo)
            s OrderInfo=TCNPrescInfo_"<br/>"_MasterCNOrderInfo
			s Sub=$O(^OEORDi(0,"OEORI",+CMOrderRowId,CMOrderRowId,0))
			While (Sub'="") {
				s SubRowId=+CMOrderRowId_"||"_Sub
				s SubOrdPrescNo=$p($g(^OEORD(+CMOrderRowId,"I",$p(SubRowId,"||",2),1)),"^",14)
				if (SubOrdPrescNo'=""){
					s SubCNOrderInfo=$$GetCNOneInfo(SubRowId)
	                s ARCIMDesc=ARCIMDesc_"&nbsp&nbsp"_doseQty_BillUOMDesc
	                if (num/4)=1 {
		                s OrderInfo=OrderInfo_"<br/>"_SubCNOrderInfo
		                s num=0
		            }else{
			            s OrderInfo=OrderInfo_"&nbsp&nbsp&nbsp&nbsp"_SubCNOrderInfo
			        }
	                s num=num+1
	                s IsExistCNSubOrdFlag=1
                }
				s Sub=$O(^OEORDi(0,"OEORI",+CMOrderRowId,CMOrderRowId,Sub))
			}
		}
	}
	q

GetCNOneInfo(ordId)
    s ARCIMDR= $p($g(^OEORD(+ordId,"I",$p(ordId,"||",2),1)),"^",2)
	s ARCIMDesc=$p(^ARCIM(+ARCIMDR,$p(ARCIMDR,"||",2),1),"^",2)
	s ScrentName=##class(web.DHCARCOrdSets).CheckPresno(ordId,"",AdmLocHospDr)
	if (ScrentName'=0){s ARCIMDesc=$P(ScrentName,"^",2)}
	s doseQty = $p($g(^OEORD(+ordId,"I",$p(ordId,"||",2),2)),"^",1)
	s BillUOMDesc=""
	s Phcdf=$P($g(^ARCIM(+ARCIMDR,$P(ARCIMDR,"||",2),1)),"^",12)
	if Phcdf'="" s BillUOMRowid=$p(^PHCD(+Phcdf,"DF",$p(Phcdf,"||",2),2),"^",4),BillUOMDesc=##class(web.DHCDocOrderCommon).GetUOMDesc(BillUOMRowid)
	s PhSpecInstr=$p($g(^OEORD(+ordId,"I",$p(ordId,"||",2),2)),"^",8) //草药备注

	s ARCIMDesc=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",ARCIMDesc,langid)
	s BillUOMDesc=##class(User.CTUOM).GetTranByDesc("CTUOMDesc",BillUOMDesc,langid)
	s PhSpecInstr=..%Translate("ipdoc.patinfoview.csp",PhSpecInstr,langid)

	if (PhSpecInstr'="") s ARCIMDesc=ARCIMDesc_"【"_PhSpecInstr_"】"
	if (ScrentName'=0){s (doseQty,BillUOMDesc)="*"}
	Q ARCIMDesc_"&nbsp&nbsp"_doseQty_BillUOMDesc
GetCNPrescInfo(ordId,PrescNo)
    s instrDesc1="",PHFreqDesc1="",ARCOSName="",TDuratDesc1=""
    s instrDr = $p($g(^OEORD(+ordId,"I",$p(ordId,"||",2),2)),"^",7)	;用法 OEORI_Instr_DR
	s:+instrDr'=0 instrDesc1=$p(^PHCIN(instrDr),"^",2)
	s PHFreqDr = $p($g(^OEORD(+ordId,"I",$p(ordId,"||",2),2)),"^",4)	;频次 OEORI_PHFreq_DR
	if (PHFreqDr'=""){
		s PHFreqDesc1 = $p($G(^PHCFR(PHFreqDr)),"^",3)
	}
	s ARCOSName=""
	s PrescRowid=$O(^PAQUE1(0,"PrescNo",PrescNo,""))
	i PrescRowid'="" {
		s PrescCookMode=$P($g(^PAQUE1(PrescRowid,"DHC")),"^",15)
		if (PrescCookMode'="") {
			s PrescCookMode=$P($g(^DHCDocConfig("HospDr_"_AdmLocHospDr,"CookMode",PrescCookMode)),"^",2)
			s PrescCookMode=..%Translate("ipdoc.patinfoview.csp",PrescCookMode,langid)
		}
		s PrescNotes=$P($g(^PAQUE1(PrescRowid,"DHC")),"^",21)
		s ARCOSRowId=$p($g(^PAQUE1(PrescRowid,"DHC")),"^",24)
		i ARCOSRowId'="" s ARCOSName=$P($g(^ARCOS(ARCOSRowId)),"^",2)
    }
	s TDuratDR = $p($g(^OEORD(+ordId,"I",$p(ordId,"||",2),2)),"^",6)	
	i TDuratDR'=""{
		s TDuratDesc1 = $p(^PHCDU(TDuratDR),"^",3)
	}	
	s instrDesc1=##class(User.PHCInstruc).GetTranByDesc("PHCINDesc1",instrDesc1,langid)
	s PHFreqDesc1=##class(User.PHCFreq).GetTranByDesc("PHCFRDesc1",PHFreqDesc1,langid)
	s TDuratDesc1=##class(User.PHCDuration).GetTranByDesc("PHCDUDesc1",$g(TDuratDesc1),langid) 

	Q instrDesc1_"&nbsp&nbsp"_PHFreqDesc1_"&nbsp&nbsp"_TDuratDesc1_"&nbsp&nbsp"_PrescCookMode_"&nbsp&nbsp"_PrescNotes_"&nbsp&nbsp"_ARCOSName
}

/// 根据医嘱表中存储的周数、分发时间信息，组织成分发时间串
ClassMethod GetOrderFreqDispTimeStr(OrderFreqRowid As %String, OrderFreqWeek As %String, OrderFreqFreeTimeStr As %String) As %String
{
	n (OrderFreqRowid , OrderFreqWeek, OrderFreqFreeTimeStr)
	s OrderFreqDispTimeStr=""
	s FreeTimeFreqFlag=$P(^PHCFR(OrderFreqRowid),"^",13)
	s WeekFlag=$P(^PHCFR(OrderFreqRowid),"^",9)
	if (FreeTimeFreqFlag'="Y")&&(WeekFlag'="Y"){
		q OrderFreqDispTimeStr
	}
	if (WeekFlag="Y"){
		//周频次
		i OrderFreqWeek=""{
			q OrderFreqDispTimeStr
		}
		for i=1:1:$L(OrderFreqWeek,"|"){
			s week=$P(OrderFreqWeek,"|",i)
			if ($O(^PHCFR(OrderFreqRowid,"DT",0))=""){
				s time="1"
				s OneData=..%ZT(time)_$C(2)_week
				if (OrderFreqDispTimeStr'=""){
					s OrderFreqDispTimeStr=OrderFreqDispTimeStr_$C(1)_OneData
				}else{
					s OrderFreqDispTimeStr=OneData
				}
			}else{
				Set childsub=0  
				f  {
					s childsub=$O(^PHCFR(OrderFreqRowid,"DT",childsub)) 
					Q:childsub=""
					Set time=$p(^PHCFR(OrderFreqRowid,"DT",childsub),"^",1)
					s OneData=..%ZT(time)_$C(2)_week
					if (OrderFreqDispTimeStr'=""){
						s OrderFreqDispTimeStr=OrderFreqDispTimeStr_$C(1)_OneData
					}else{
						s OrderFreqDispTimeStr=OneData
					}
				}
			}
		}
	}elseif (FreeTimeFreqFlag="Y"){
		//不规则分发时间频次
		i OrderFreqFreeTimeStr=""{
			q OrderFreqDispTimeStr
		}
		Set childsub=0  
		f  {
			s childsub=$O(^PHCFR(OrderFreqRowid,"DT",childsub)) 
			Q:childsub=""
			Set time=$p(^PHCFR(OrderFreqRowid,"DT",childsub),"^",1)
			s time=..%ZTH(..%ZT(time,2))
			if ("|"_OrderFreqFreeTimeStr_"|")'[("|"_time_"|") {
				continue
			}
			s OneData=..%ZT(time,2)_$C(2)_$C(2)_OrderFreqRowid_"_"_childsub
			if (OrderFreqDispTimeStr'=""){
				s OrderFreqDispTimeStr=OrderFreqDispTimeStr_$C(1)_OneData
			}else{
				s OrderFreqDispTimeStr=OneData
			}
		}
	}
	q OrderFreqDispTimeStr
}

/// 从频次分发时间串中拆解出周频次信息
ClassMethod GetOrderFreqWeekStr(OrderFreqDispTimeStr As %String) As %String
{
	n (OrderFreqDispTimeStr)
	s OrderFreqWeek=""
	for i=1:1:$L(OrderFreqDispTimeStr,$C(1)){
		s ArrData=$P(OrderFreqDispTimeStr,$C(1),i)
		s week=$P(ArrData,$C(2),2)
		if (OrderFreqWeek[week){
			continue
		}
		if (OrderFreqWeek=""){
			s OrderFreqWeek=week
		}else{
			s OrderFreqWeek=OrderFreqWeek_"|"_week
		}
	}
	q OrderFreqWeek
}

/// 从频次分发时间串中拆解出不规则分发时间信息
ClassMethod GetOrderFreqOtherInfo(OrderFreqRowid As %String, OrderFreqDispTimeStr As %String) As %String
{
	n (OrderFreqRowid,OrderFreqDispTimeStr,%session)
	s WeekFlag=$P(^PHCFR(OrderFreqRowid),"^",9)
	s FreeTimeFreqFlag=$P(^PHCFR(OrderFreqRowid),"^",13)
	s OrderFreqFreeTimeDesc=""
	if (FreeTimeFreqFlag="Y"){
		s OrderFreqFreeTimeInfo=##Class(web.DHCOEOrdItem).GetOrderFreqFreeTimeInfo(OrderFreqRowid,OrderFreqDispTimeStr)
		s OrderFreqFreeTimeStr=$P(OrderFreqFreeTimeInfo,"^",1)
		s OrderFreqFreeTimeDesc=$P(OrderFreqFreeTimeInfo,"^",2)
	}elseif (WeekFlag="Y"){
		s OrderFreqFreeTimeDesc=##Class(web.DHCOEOrdItem).GetOrderFreqWeekStr(OrderFreqDispTimeStr)
		s OrderFreqFreeTimeDesc=$replace(OrderFreqFreeTimeDesc,"|","")
	}
	q OrderFreqFreeTimeDesc
}

/// 从频次分发时间串中拆解出不规则分发时间信息
ClassMethod GetOrderFreqFreeTimeInfo(OrderFreqRowid As %String, OrderFreqDispTimeStr As %String) As %String
{
	n (OrderFreqRowid,OrderFreqDispTimeStr,%session)
	s OrderFreqFreeTimeStr="", OrderFreqFreeTimeDesc=""
	Set langid=..%LanguageID()
	for i=1:1:$L(OrderFreqDispTimeStr,$C(1)){
		s ArrData=$P(OrderFreqDispTimeStr,$C(1),i)
		continue:ArrData=""
		s DispTime=$P(ArrData,$C(2),1)
		s PHCDTRowID=$P(ArrData,$C(2),3)
		if PHCDTRowID'=""{
			s PHCDTDesc=$P($G(^PHCFR(+PHCDTRowID,"DT",$P(PHCDTRowID,"_",2))),"^",2)
			s PHCDTDesc=##class(User.PHCDispensingTime).GetTranByDesc("PHCDTTimeDesc",PHCDTDesc,langid)
		}else{
			s PHCDTDesc=""
		}
		if (OrderFreqFreeTimeStr=""){
			s OrderFreqFreeTimeStr=DispTime
		}else{
			s OrderFreqFreeTimeStr=OrderFreqFreeTimeStr_"|"_DispTime
		}
		if (OrderFreqFreeTimeDesc'[PHCDTDesc){
			if (OrderFreqFreeTimeDesc=""){
				s OrderFreqFreeTimeDesc=PHCDTDesc
			}else{
				s OrderFreqFreeTimeDesc=OrderFreqFreeTimeDesc_"|"_PHCDTDesc
			}
		}
	}
	q OrderFreqFreeTimeStr_"^"_OrderFreqFreeTimeDesc
}

/// 将用户选择的分发时间转换成系统
ClassMethod FormFreqFreeTimeHtmlToLogical(OrderFreqFreeTimeStr As %String) As %String [ ProcedureBlock = 1 ]
{
	s LogicalFreqFreeTimeStr=""
	for i=1:1:$L(OrderFreqFreeTimeStr,"|"){
		s Time=$p(OrderFreqFreeTimeStr,"|",i)
		if (Time)=""{
			continue
		}
		i Time[":" s Time=..%ZTH(Time)
		if (LogicalFreqFreeTimeStr=""){
			s LogicalFreqFreeTimeStr=Time
		}else{
			s LogicalFreqFreeTimeStr=LogicalFreqFreeTimeStr_"|"_Time
		}
	}
	
	q LogicalFreqFreeTimeStr
}

/// 获取医嘱的分发时间列表
ClassMethod GetOrdItemFreqDispTimeStr(OEORIRowid As %String) [ ProcedureBlock = 1 ]
{
	s OrderFreqRowid=$P($G(^OEORD(+OEORIRowid,"I",$P(OEORIRowid,"||",2),2)),"^",4)
	s OrderFreqDispTimeStr=""
	s FreeTimeFreqFlag=$P($G(^PHCFR(+OrderFreqRowid)),"^",13)
	s WeekFlag=$P($G(^PHCFR(+OrderFreqRowid)),"^",9)
	i (WeekFlag="Y")||(FreeTimeFreqFlag="Y") {
		s OrderFreqWeek=$p($g(^OEORD(+OEORIRowid,"I",$P(OEORIRowid,"||",2),"DHC")),"^",55)
		s OrderFreqFreeTimeStr=$p($g(^OEORD(+OEORIRowid,"I",$P(OEORIRowid,"||",2),"DHC")),"^",68)
		s OrderFreqDispTimeStr=##Class(web.DHCOEOrdItem).GetOrderFreqDispTimeStr(OrderFreqRowid,OrderFreqWeek,OrderFreqFreeTimeStr)
	}
	s FreqDispTimeStr=##Class(web.DHCOEOrdItemView).GetFreqFreqDispTimeStr(OrderFreqRowid,OrderFreqDispTimeStr)
	q FreqDispTimeStr
}

ClassMethod CheckTransOrd(Adm As %String, ExpStr As %String, ByRef CallBackFunStr As %String = "") As %String
{
	n (Adm,ExpStr,CallBackFunStr,%session)
	s HospID=##Class(DHCDoc.Common.Hospital).GetAdmHospitalId(Adm)
	s User=$P(ExpStr,"^",1)
	s ARCIMRowid=$P(ExpStr,"^",2)
	s rowIndex=$P(ExpStr,"^",5)
	s OutPutInfo=""
	s ErrCode=0
	s ErrMsg=""
	s TransType=##Class(DHCDoc.Interface.Inside.Invoke).GetArcimTransType(ARCIMRowid,HospID)
	if TransType'=""{
		if ##class(DHCDoc.Interface.Inside.ServiceOrd).GetValidTransOrd(Adm).%Size(){
			s ErrCode=-100
			s ErrMsg=..%Translate("oeorder.oplistcustom.new.csp","已存在未用的有效转科医嘱,不能再开")
			s OutPutInfo=ErrCode_"^"_ErrMsg
			q OutPutInfo
		}
		//调用护理组需关注 pb by tanjishan 临床路径提醒现在走护理需关注
		s ret1=..GetAbnormalOrder(Adm,User ,"T","", .CallBackFunStr)
		s ErrCode=$P(ret1,"^",1)
		s ErrMsg=$P(ret1,"^",2)
		
		if (ErrCode=0){
			s CallBackFunParams=rowIndex_","_TransType
			s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"SetTransType",CallBackFunParams)
		}
	}
	s OutPutInfo=ErrCode_"^"_ErrMsg
	q OutPutInfo
}

ClassMethod CheckDischargeOrd(Adm As %String, ExpStr As %String, ByRef CallBackFunStr As %String = "") As %String
{
	n (Adm,ExpStr,CallBackFunStr,%session)
	s User=$P(ExpStr,"^",1)
	s ARCIMRowid=$P(ExpStr,"^",2)
	s SttDat=$P(ExpStr,"^",3)
	s SttTim=$P(ExpStr,"^",4)
	s CurHospId=$P(ExpStr,"^",5)
	s OrdRowIndex=$P(ExpStr,"^",6)
	s OutPutInfo=""
	s ErrCode=0
	s ErrMsg=""
	s dischargeNeedArcimStr=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.ord.GetDisChargeNeedArcimStr","dischargeNeedArcim", CurHospId)
	s deathDischargeNeedArcimStr=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.ord.GetDisChargeNeedArcimStr","deathDischargeNeedArcim", CurHospId)
	s NeedCheckArcimStr=""
	i dischargeNeedArcimStr'="" s NeedCheckArcimStr=dischargeNeedArcimStr
	i deathDischargeNeedArcimStr'="" s NeedCheckArcimStr=NeedCheckArcimStr_"^"_deathDischargeNeedArcimStr
	s IsExistdischargeFlag=0,IsNeedDischgDiag=0,IfCanOpenDischargeFlag=1
	s IsDeathFlag=0
	i ("^"_NeedCheckArcimStr_"^")[("^"_ARCIMRowid_"^") {
		s IsExistdischargeFlag=1
		i ("^"_deathDischargeNeedArcimStr_"^")[("^"_ARCIMRowid_"^") {
			s IsDeathFlag=1
		}
		s ExistdischargeSttDat=SttDat
		s ExistdischargeSttTim=SttTim
		i $l(ExistdischargeSttDat,"/")=3 s ExistdischargeSttDat = $zdh(ExistdischargeSttDat,4)
		i $l(ExistdischargeSttDat,"-")=3 s ExistdischargeSttDat = $zdh(ExistdischargeSttDat,3)
		i ExistdischargeSttTim[":" s ExistdischargeSttTim=..%ZTH(ExistdischargeSttTim)
	}else{
		s OutPutInfo=ErrCode_"^"_ErrMsg
		q OutPutInfo
	}
	i IsExistdischargeFlag=1 {
		;开始日期时间之后是否有已经执行的执行记录
		s AdmIsExecRetStr=##class(web.DHCOEOrdItem).CheckAdmIsExecByDateT(Adm,User,ExistdischargeSttDat,ExistdischargeSttTim)
		i AdmIsExecRetStr'="" {
			s ErrCode="-201"
			s ErrMsg=AdmIsExecRetStr
			s IfCanOpenDischargeFlag=0
		}
		;判断出院医嘱的开始日期不能小于今天
		i (ExistdischargeSttDat<+$h)&&(IsDeathFlag=0) {
			s ErrCode="-202"
			s ErrMsg=..%Translate("oeorder.oplistcustom.new.csp","出院医嘱的开始日期不能小于今天.")
			s IfCanOpenDischargeFlag=0
		}
		;死亡医嘱判断是否存在死亡类型诊断
		s NeedDeathTypeDiag=..%GetConfig("NeedDeathTypeDiag",CurHospId)	//开立死亡医嘱时必须录入死亡诊断
		s AllDiagType="Y" //标识为N时"出院前医生必须开的诊断类型"不验证是否存在出院诊断类型
		s isDeathDiagFlag="N"
		if (NeedDeathTypeDiag="1")&&(IsDeathFlag=1)&&('(..IsExistDeathTypeDiag(Adm))){
			s ErrMsg=..%Translate("oeorder.oplistcustom.new.csp","死亡医嘱需要开立死亡类型的诊断.")
			s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"NeedDeathTypeDiagnos",ErrMsg)
			;s AllDiagType="N"
			s isDeathDiagFlag="Y"
		}
		#; pb by tanjishan 临床路径提醒现在走护理需关注
		#; ;判断病人是否临床路径
		#; s CPWRet=##Class(DHCMA.CPW.IO.ToDoc).GetPathStatusToDOC(Adm)
		#; if CPWRet=1{
		#; 	s ErrCode="-203"
		#; 	s ErrMsg=..%Translate("oeorder.oplistcustom.new.csp","请先完成病人临床路径.)
		#; 	s IfCanOpenDischargeFlag=0
		#; }
		if (ErrCode=0){ 
			///护理组需关注
			s ret1=..GetAbnormalOrder(Adm,User ,"D",AllDiagType, .CallBackFunStr,isDeathDiagFlag,IsDeathFlag)
			s ErrCode=$P(ret1,"^",1)
			s ErrMsg=$P(ret1,"^",2)
		}
	}
	if (ErrCode=0){ 
		s CallBackFunParams=OrdRowIndex
		i (IsDeathFlag=1) {
			s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"NeedDeathDate",CallBackFunParams)
		}else{
			s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"NeedDischgCond",CallBackFunParams)
		}
	}
	s OutPutInfo=ErrCode_"^"_ErrMsg
	q OutPutInfo
}

/// 调用护理组需关注医嘱内容
ClassMethod GetAbnormalOrder(Adm As %String, User As %String, Type As %String, AllDiagType As %String = "N", ByRef CallBackFunStr As %String = "", isDeathDiagFlag = "", IsDeathFlag = "") As %String
{
	n (Adm,User,Type,AllDiagType,CallBackFunStr,isDeathDiagFlag,IsDeathFlag,%session)
	s ErrCode=0
	s ErrMsg=""
	s DoctorType=""
	s CareProvDR = $p(^SSU("SSUSR",User),"^",14)
	if (CareProvDR'=""){
		s CarPrvTpDR=$p($g(^CTPCP(+$g(CareProvDR),1)),"^",4)
		s DoctorType=$p($g(^CT("CPT",+$g(CarPrvTpDR))),"^",4)
	}
	s ifCare="N"				//是否拦截
	if (DoctorType=""){
		q ErrCode_"^"_ErrMsg_"^"_ifCare
	}
	;调用护理组接口
	if (Type="D"){
		//判断是否满足出院条件
		s needCareStr=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.ord.GetAbnormalOrder",Adm,DoctorType,Type,AllDiagType,"N",isDeathDiagFlag)
	}elseif (Type="T"){
		//判断是否满足转科条件
		s needCareStr=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.ord.GetAbnormalOrder",Adm,DoctorType,Type,AllDiagType,"N",isDeathDiagFlag)
	}else{
		q ErrCode_"^"_ErrMsg_"^"_ifCare
	}
	if (needCareStr=""){
		q ErrCode_"^"_ErrMsg_"^"_ifCare
	}
	s IfOpenCareOrd=0,DiagErrMsg="",OtherErrMsg=""
	
	s OpenCareOrdWin="N"		//是否打开需关注界面
	s IsNeedMainDischgDiag="N"	//是否默认主诊断
	s needCare=##class(DHCDoc.Util.FromXML).Json2Arr(needCareStr)
	for i=1:1:needCare.%Size() {
		s dataObj=needCare.GetAt(i)
		s oneErrMsg=dataObj.GetAt("abnormalMsg")		//错误提醒
		continue:oneErrMsg=""
		s LoopifCare=dataObj.GetAt("ifCare")	//是否强制控制Y/N
		if (LoopifCare="Y") s ifCare="Y"
		s LoopisOtherAbnormal=dataObj.GetAt("isOtherAbnormal")	//是否和医嘱无关Y/N
		if (LoopisOtherAbnormal'="Y") s OpenCareOrdWin="Y"
		s color=$CASE(LoopifCare,"Y":"red",:"blue")
		if (oneErrMsg[("诊断")) {
			if (oneErrMsg["主诊断") s IsNeedMainDischgDiag="Y"
			s DiagErrMsg=..%Translate("oeorder.oplistcustom.new.csp",$CASE(DiagErrMsg,"":"",:(DiagErrMsg_" ")))_"<span style='color:"_color_"'>"_..%Translate("oeorder.oplistcustom.new.csp",oneErrMsg)_"</span>"
		}else{
			s OtherErrMsg=..%Translate("oeorder.oplistcustom.new.csp",$CASE(OtherErrMsg,"":"",:(OtherErrMsg_" ")))_"<span style='color:"_color_"'>"_..%Translate("oeorder.oplistcustom.new.csp",oneErrMsg)_"</span>"
		}
	}
	if (DiagErrMsg'="") s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"NeedDischgDiagnos",DiagErrMsg_","_IsNeedMainDischgDiag_","_Type_","_AllDiagType_","_IsDeathFlag)
	if (ifCare="Y")&&(OtherErrMsg'=""){		//有需关注的提示且拦截审核动作
		s ErrMsg=..%Translate("oeorder.oplistcustom.new.csp","存在")_..%Translate("oeorder.oplistcustom.new.csp",OtherErrMsg)_..%Translate("oeorder.oplistcustom.new.csp",",不能"_$CASE(Type,"D":"出院","T":"转科",:"")_"!请先处理!" )
		if (OpenCareOrdWin="N"){
			s ErrCode="-202"
			#; s IfCanOpenDischargeFlag=0
		}else{
			s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"NeedFirstDelWithCareOrd",ErrMsg_","_Type)
		}
	}elseif (OtherErrMsg'=""){ //有需关注的提示但不控制
		s CallBackFunParams=..%Translate("oeorder.oplistcustom.new.csp","存在")_..%Translate("oeorder.oplistcustom.new.csp",OtherErrMsg)_..%Translate("oeorder.oplistcustom.new.csp",",是否立即处理?")_","_Type
		if (OpenCareOrdWin="N"){
			s CallBackFunParams=..%Translate("oeorder.oplistcustom.new.csp","存在")_..%Translate("oeorder.oplistcustom.new.csp",OtherErrMsg)_..%Translate("oeorder.oplistcustom.new.csp",",是否继续审核?")
			s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
		}else{
			s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"NeedCareOrd",CallBackFunParams) //Confirm
		}
	}
	q ErrCode_"^"_ErrMsg_"^"_ifCare
}

/// w ##class(web.DHCOEOrdItem).CheckMaxDoseQtyPerDay("501||1^R^3^14/09/2018^16:34:37^1^14.2800^308^1^501||1^^1^2^1^4^1^12^1^^6^N^^N^^^^^^^N^^^^^^^^^^^^^^^^14/09/2018^16:34:37^N^^^^^N^^50^^N^^^^^^^^N^6^",4770)
ClassMethod CheckMaxDoseQtyPerDay(OrdItemStr As %String, Adm As %String) As %String
{
	n (OrdItemStr,Adm,%session)
	s ^tempscl("CheckMaxDoseQtyPerDay")=OrdItemStr_","_Adm
	s ErrCode=0
	s ErrMsg=""
	Set langid=..%LanguageID()
	k RMaxDoseQtyPerDayOrd
	Set OrdItemCount=$L(OrdItemStr,$c(1))
	for i=1:1:OrdItemCount {
		s OrdItem=$p(OrdItemStr,$c(1),i)
		continue:OrdItem=""
		s PriorRowid=$p(OrdItem,"^",3)
		s PriorCode=$P($G(^OECPR(+PriorRowid)),"^",1)
		continue:PriorCode="ONE"	;取药医嘱不判断
		s ARCIMRowid=$p(OrdItem,"^",1)
		s MaxDoseQtyPerDay=$p($g(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),9)),"^",37) //每天最大剂量
		if (+MaxDoseQtyPerDay>0){
			s OrderDrugFormRowid=$p(OrdItem,"^",10)
			q:OrderDrugFormRowid=""
			s OrderDoseQty=$p(OrdItem,"^",12)
			s OrderFreqTimeDoseStr=$p(OrdItem,"^",70)
			q:(+OrderDoseQty=0)&&(OrderFreqTimeDoseStr="")
			s OrderDoseUOMRowid=$p(OrdItem,"^",13)
			q:OrderDoseUOMRowid=0
			s OrderStartDate=$p(OrdItem,"^",4)
			s OrderStartTime=$p(OrdItem,"^",5)
			s FreqRowid=$p(OrdItem,"^",15)
			s OrderDurRowid=$p(OrdItem,"^",16)
			if (OrderFreqTimeDoseStr'="") {
				//28||1$1 ! 28||2$1 ! 28||3$3
				s StartDayDoseQtySum=0
				s FirstDayFreqTimeDoseStr=$P(OrderFreqTimeDoseStr,"@",2)
				s OrderFreqTimeDoseStr=$P(OrderFreqTimeDoseStr,"@",1)
				for myFreqTimeDoseStr=FirstDayFreqTimeDoseStr,OrderFreqTimeDoseStr{
					continue:myFreqTimeDoseStr=""
					s tmpStartDayDoseQtySum=0
					for k=1:1:$l(myFreqTimeDoseStr,"!") {
						s OneOrderDoseQtyStr=$p(myFreqTimeDoseStr,"!",k)
						s OneOrderDoseQty=$p(OneOrderDoseQtyStr,"$",2)
						s OneEqDoseQty=##class(web.DHCDocOrderEntry).CalEqDose(OrderDoseUOMRowid,OrderDrugFormRowid,OneOrderDoseQty,"BaseUom")
						s tmpStartDayDoseQtySum=tmpStartDayDoseQtySum+OneEqDoseQty
					}
					s:tmpStartDayDoseQtySum>StartDayDoseQtySum StartDayDoseQtySum=tmpStartDayDoseQtySum
				}
			}else{
				s EqDoseQty=##class(web.DHCDocOrderEntry).CalEqDose(OrderDoseUOMRowid,OrderDrugFormRowid,OrderDoseQty,"BaseUom")
				s Freqfactor=1
			    i FreqRowid'="" s Freqfactor=$p($g(^PHCFR(FreqRowid)),"^",2)
				s StartDayDoseQtySum=EqDoseQty*Freqfactor
			}
			s tmpDoseQty=+$g(RMaxDoseQtyPerDayOrd(ARCIMRowid,MaxDoseQtyPerDay))
			s RMaxDoseQtyPerDayOrd(ARCIMRowid,MaxDoseQtyPerDay)=tmpDoseQty+StartDayDoseQtySum
			s tmpDoseQty=+$g(RMaxDoseQtyPerDayOrd(ARCIMRowid,MaxDoseQtyPerDay))
			if (tmpDoseQty>MaxDoseQtyPerDay){
				s bsUOMph=$p(^PHCD(+OrderDrugFormRowid,"DF",$p(OrderDrugFormRowid,"||",2),2),"^",4)
				s bsUOMphDesc=##class(web.DHCDocOrderCommon).GetUOMDesc(bsUOMph)
				s ErrCode="-1"
				s MaxDoseQtyPerDay=$fn(MaxDoseQtyPerDay,"N")
				s ARCIMDesc=$P(^ARCIM(+ARCIMRowid,$P(ARCIMRowid,"||",2),1),"^",2)
				s ARCIMDesc=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",ARCIMDesc,langid)
				s ErrMsg=ARCIMDesc_..%Translate("oeorder.oplistcustom.new.csp","超过每天最大剂量:")_$C(13,10)_MaxDoseQtyPerDay_bsUOMphDesc
				Q 
			}
		}
	}
	s tempArcimID=0
	f  s tempArcimID=$o(RMaxDoseQtyPerDayOrd(tempArcimID)) q:(tempArcimID="")||(ErrCode="-1")  d
	.s tmpMaxDoseQtyPerDay=$o(RMaxDoseQtyPerDayOrd(tempArcimID,""))
	.s tmpDoseQtySum=+$g(RMaxDoseQtyPerDayOrd(tempArcimID,tmpMaxDoseQtyPerDay))
	.s SaveDoseQtySum=##class(web.DHCDocOrderEntry).GetSameOrdDoseQtyPerDay(Adm,tempArcimID)
	.s tmpDoseQtySum=tmpDoseQtySum+SaveDoseQtySum
	.if (tmpDoseQtySum>tmpMaxDoseQtyPerDay) d
	..s ErrCode="-1"
	..s DrgformRowid=##class(web.DHCDocOrderEntry).GetDrgForm(tempArcimID)
	..s bsUOMph=$p(^PHCD(+DrgformRowid,"DF",$p(DrgformRowid,"||",2),2),"^",4)
	..s bsUOMphDesc=##class(web.DHCDocOrderCommon).GetUOMDesc(bsUOMph)
	..s tmpMaxDoseQtyPerDay=$fn(tmpMaxDoseQtyPerDay,"N")
	..s ARCIMDesc=$P(^ARCIM(+tempArcimID,$P(tempArcimID,"||",2),1),"^",2)
	..s ARCIMDesc=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",ARCIMDesc,langid)
	..s ErrMsg=ARCIMDesc_..%Translate("oeorder.oplistcustom.new.csp","超过每天最大剂量:")_$C(13,10)_tmpMaxDoseQtyPerDay_bsUOMphDesc
	k RMaxDoseQtyPerDayOrd
	s OutPutInfo=ErrCode_"^"_ErrMsg
	q OutPutInfo
}

ClassMethod CheckOrderStartTime(Adm As %String, ExpStr As %String) As %String
{
	n (Adm,ExpStr)
	s ErrCode=0
	s ErrMsg=""
	s OutPutInfo=""
	s AdmType=$p($g(^PAADM(Adm)),"^",2)
	q:(AdmType'="I") OutPutInfo
	s ARCIMRowid=$p(ExpStr,"^",1)
	s OrderStartDate=$p(ExpStr,"^",2)
	s OrderStartTime=$p(ExpStr,"^",3)
	s ARCIMDesc=""
	i ARCIMRowid'="" s ARCIMDesc=$P(^ARCIM(+ARCIMRowid,$P(ARCIMRowid,"||",2),1),"^",2)
	S:OrderStartDate["-" OrderStartDate=$ZDH(OrderStartDate,3)
	S:OrderStartDate["/" OrderStartDate=$ZDH(OrderStartDate,4)
	s OrderStartTime=..%ZTH(OrderStartTime)
	s PatDateBed=##Class(web.DHCADMQTREC).PACInPatDateBed(Adm)
	s TRANDate=$P(PatDateBed,"^",1)
	s TRANTime=$P(PatDateBed,"^",2)
	;婴儿判断出生时间AdmDate,AdmTime
	s MotherAdmID=$p($g(^PAADM(Adm)),"^",75)
	if MotherAdmID'=""{
		s TRANDate=$p($g(^PAADM(Adm)),"^",6)
		s TRANTime=$p($g(^PAADM(Adm)),"^",7)
	}
	if (TRANDate="")&&(TRANTime=""){
		//s ErrCode="-1"
		//s ErrMsg="护士尚未分床"
		q OutPutInfo
	}
	
	if (OrderStartDate<TRANDate)||((OrderStartDate=TRANDate)&&(OrderStartTime<TRANTime)){
		s ErrCode="-1"
		s Desc=$CASE(MotherAdmID,"":"护士分床",:"出生")
		s ErrMsg=ARCIMDesc_"不能早于"_Desc_"时间:"_$C(13,10)_..%ZD(TRANDate)_" "_..%ZT(TRANTime,2)
	}
	s OutPutInfo=ErrCode_"^"_ErrMsg
	q OutPutInfo
}

ClassMethod CheckRepeatLabOrd(Adm As %String, OrdItemStr As %String) As %String
{
	n (Adm,OrdItemStr,%session)
	s ErrCode=0
	s ErrMsg=""
	s OutPutInfo=""
	s AdmType=$p($g(^PAADM(Adm)),"^",2)
	s MastOrderDr=$O(^OEORD(0,"Adm",Adm,0))
	Set langid=..%LanguageID()
	k LOrderHave
	Set OrdItemCount=$L(OrdItemStr,$c(1))
	for i=1:1:OrdItemCount {
		s OrdItem=$p(OrdItemStr,$c(1),i)
		continue:OrdItem=""
		s ARCIMRowid=$p(OrdItem,"^",1)
		continue:ARCIMRowid=""
		s ItemCatRowid=$p($g(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1)),"^",10)
		s OrderStartDate=$p(OrdItem,"^",4)
		s:OrderStartDate["-" OrderStartDate=$ZDH(OrderStartDate,3)
		s:OrderStartDate["/" OrderStartDate=$ZDH(OrderStartDate,4)
		s OrderType=$P(^ARC("IC",ItemCatRowid),"^",7)
		if (OrderType="L"){
			s Sub=$I(LOrderHave(ARCIMRowid,OrderStartDate))
		}
	}
	if (MastOrderDr'="")&&($d(LOrderHave)) {
		//循环历史医嘱
		s SubID=0
		f  s SubID=$O(^OEORD(MastOrderDr,"I",SubID)) Q:SubID=""  d
		.Q:SubID=""
		.s statcode="V"
		.s statDesc="核实"
		.s TtemStat=$P($G(^OEORD(MastOrderDr,"I",SubID,1)),"^",13) ;OEORI_Billed
		.i TtemStat'="" d
		..s statcode=$p($g(^OEC("OSTAT",TtemStat)),"^",1)
		..s statDesc=$p($g(^OEC("OSTAT",TtemStat)),"^",2)
		.Q:((statcode="D")||(statcode="C")||(statcode="U"))
		.s OrderStarDate=$p($g(^OEORD(MastOrderDr,"I",SubID,1)),"^",9)
		.s ArcimID=$P($G(^OEORD(MastOrderDr,"I",SubID,1)),"^",2)
		.Q:ArcimID=""
		.s ItemCatRowid=$p($g(^ARCIM(+ArcimID,$p(ArcimID,"||",2),1)),"^",10)
		.s OrderType=$P(^ARC("IC",ItemCatRowid),"^",7)
		.Q:(OrderType'="L")
		.Q:('$d(LOrderHave(ArcimID))) //不在本次审核范围内的检验医嘱项过滤
		.s Sub=$I(LOrderHave(ArcimID,OrderStarDate))
	}
	//判断是否存在重复的检验医嘱--
	s HaveSameLabStr=""
	if AdmType="O"  d
	.s ArcimID=0
	.f  s ArcimID=$O(LOrderHave(ArcimID)) Q:ArcimID=""  d
	..s LabOrdDayAllowRepeat="N"
	..s DHCARCIMRowid=$O(^DHCItmMast("0","ARCIM",ArcimID,0))
	..if DHCARCIMRowid'="" s LabOrdDayAllowRepeat=$p(^DHCItmMast(DHCARCIMRowid),"^",26)
	..Q:LabOrdDayAllowRepeat="Y" //医嘱项扩展设定-允许检验医嘱重复
	..s DateSub=0
	..f  s DateSub=$O(LOrderHave(ArcimID,DateSub)) Q:DateSub=""  d
	...s Num=+$G(LOrderHave(ArcimID,DateSub))
	...if Num>1  d
	....s ArcimDesc=$P(^ARCIM(+ArcimID,$P(ArcimID,"||",2),1),"^",2)
	....s ArcimDesc=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",ArcimDesc,langid)
	....if HaveSameLabStr="" s HaveSameLabStr=ArcimDesc
	....else  s HaveSameLabStr=HaveSameLabStr_$C(13,10)_ArcimDesc 
	if HaveSameLabStr'=""  d
	.s ErrCode="-1"
	.s ErrMsg=..%Translate("oeorder.oplistcustom.new.csp","不允许一天内开两条同样的检验医嘱")_$C(13,10)_HaveSameLabStr
	k LOrderHave
	
	s OutPutInfo=ErrCode_"^"_ErrMsg
	q OutPutInfo
}

ClassMethod CheckOrdBasicInfo(Adm As %String, OrdItem As %String, OrdRowIndex As %String, ByRef LastExceedReasonID As %String, OrdItemStr As %String, CheckExpStr As %String, ByRef CallBackFunStr As %String = "") As %String
{
	n (Adm,OrdItem,CallBackFunStr,LastExceedReasonID,OrdRowIndex,CheckExpStr,OrdItemStr,%session)
	s ErrCode=-1
	s ErrMsg=""
	s FocusCol=""
	s OutPutInfo=""
	Set langid=..%LanguageID()
	s PatientID=$P(^PAADM(Adm),"^",1)
	s PatientNo=$P($g(^PAPER(PatientID,"PAT",1)),"^",1)
	s AdmDepId=$P($G(^PAADM(Adm)),"^",4)
	s PAADMType=$p($g(^PAADM(Adm)),"^",2)
	s PAADMInsType=$P(^PAADM(Adm,1),"^",7)
	s OrderRowid=$o(^OEORD(0,"Adm",Adm,""))
	s CurLogonDep=$p(CheckExpStr,"^",1)
	s CurLogonHosp =$p(^CTLOC(CurLogonDep),"^",22)
	s UserRowId=$p(CheckExpStr,"^",2)
	s CareProvDR=$P(^SSU("SSUSR",UserRowId),"^",14)
	if (CareProvDR'="") s CareProvTP=$P($G(^CTPCP(+CareProvDR,1)),"^",4)
	s CareProvType=##class(web.DHCDocOrderCommon).GetCareProvType(UserRowId)
    s CareProvType=$zcvt(CareProvType,"U")
	s PAAdmFlag=0
	Set CurrentDischargeStatus = ##class(web.DHCDocMainOrderInterface).GetCurrentDischargeStatus(Adm)
	//最终结算后,调整费用,---护士可以做相关操作 
	if (##class(web.DHCDocMain).isDischg(Adm)) && (CurrentDischargeStatus="B") {
		s PAAdmFlag=2.5
	}
	s ARCIMRowid=$p(OrdItem,"^",1)
	s OrderType=$p(OrdItem,"^",2)
	s PriorRowid=$p(OrdItem,"^",3)
	s OrderStartDate=$p(OrdItem,"^",4)
	s OrderStartTime=$p(OrdItem,"^",5)
	s PackQty=$p(OrdItem,"^",6)
	s OrderPrice=$p(OrdItem,"^",7)
	s RecDepRowid=$p(OrdItem,"^",8)
	if (RecDepRowid ="") {
		s OrderName=$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",2)
		s OrderName=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",OrderName,langid)
		s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 接收科室不能为空!")
		s FocusCol="OrderRecDep"
		q ErrCode_"^"_ErrMsg_"^^"_FocusCol
	}
	s AdmReason=$replace($p(OrdItem,"^",9),$c(10),"")
	if (AdmReason="") s AdmReason=PAADMInsType
	s AdmReasonDesc=$p($g(^PAC("ADMREA",AdmReason)),"^",2)
	s DrugFormRowid=$p(OrdItem,"^",10)
	s DepProcNotes=$p(OrdItem,"^",11)
	s DoseQty=$p(OrdItem,"^",12)
	s DoseUOMRowid=$p(OrdItem,"^",13)
	s DoseQtySum=$p(OrdItem,"^",14)
	s FreqRowid=$p(OrdItem,"^",15)
	s DurRowid=$p(OrdItem,"^",16)
	s InstrRowid=$p(OrdItem,"^",17)
	s PHPrescType=$p(OrdItem,"^",18)
	s MasterSeqNo=$p(OrdItem,"^",19)
	s OrderSeqNo=$p(OrdItem,"^",20)
	s SkinTest=$p(OrdItem,"^",21)
	s PhSpecInstr=$p(OrdItem,"^",22)
	s OrderCoverMainIns=$p(OrdItem,"^",23)
	s ActionRowid=$p(OrdItem,"^",24)
	s ARCOSRowid=$p(OrdItem,"^",25)
	s EndDate=$p(OrdItem,"^",26)
	s EndTime=$p(OrdItem,"^",27)
	s ExecuteDateStr=$p(OrdItem,"^",29)
	s NotifyClinician=$p(OrdItem,"^",30)
	s DIACatRowId=$p(OrdItem,"^",31)
	s InsurCatRowId=$p(OrdItem,"^",32)
	s FirstDayTimes=$p(OrdItem,"^",33)
	s InsurSignSymptomCode=$p(OrdItem,"^",34)
	s OrderStageCode=$p(OrdItem,"^",35)
	s SpeedFlowRate=$p(OrdItem,"^",36)
	s AnaesthesiaID=$p(OrdItem,"^",37)
	s LabEpisodeNo=$p(OrdItem,"^",38)
	s VerifiedOrderMasterRowid=$p(OrdItem,"^",39)
	s OrderNutritionDrugFlag=$p(OrdItem,"^",40)
	s MaterialBarCode=$p(OrdItem,"^",41)
	s CPWStepItemRowId=$p(OrdItem,"^",43)
	s InsurApproveType=$p(OrdItem,"^",44)
	s OrderFlowRateUnit=$p(OrdItem,"^",45)
	s OrderDate=$p(OrdItem,"^",46)
	s OrderTime=$p(OrdItem,"^",47)
	s OrderNeedPIVAFlag=$p(OrdItem,"^",48)
	s OrderAntibApplyRowid=$p(OrdItem,"^",49)
	s AntUseReason=$p(OrdItem,"^",50)
	s UseReasonId=$p(OrdItem,"^",51)
	s OrderLocalInfusionQty=$p(OrdItem,"^",52)
	s OrderBySelfOMFlag=$p(OrdItem,"^",53)
	s ExceedReasonID=$p(OrdItem,"^",54) 
	s OrderPackUOMRowid=$p(OrdItem,"^",55)
	s PilotProRowId=$p(OrdItem,"^",56)
	s OrderOutsourcingFlag=$p(OrdItem,"^",57)
	s OEORIBindSource=$p(OrdItem,"^",58) //医嘱绑定来源
	s ApplyArcId=$p(OrdItem,"^",59)
	s OrderDHCAADr=$p(OrdItem,"^",60)
	s OperationCode=$p(OrdItem,"^",61)
	s ZSKMonitorLogId=$p(OrdItem,"^",62)
	s OrderNurseLinkOrderRowid=$p(OrdItem,"^",63)
	s CelerType=$p(OrdItem,"^",65)	//快速医嘱套标识
	s OrderFreqWeekStr=$p(OrdItem,"^",67)
	s OrderVirtualtLong=$p(OrdItem,"^",79)
	s ChronicDiagCode=$p(OrdItem,"^",82)
	Set OrderFreqFreeTimeStr=$p(OrdItem,"^",83)
	set OrderSerialNum=$p(OrdItem,"^",87)
	Set OrderFreqFreeTimeStr=##Class(web.DHCOEOrdItem).FormFreqFreeTimeHtmlToLogical(OrderFreqFreeTimeStr)
	s OrderItemCatRowid=$p($g(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1)),"^",10)
	s OrderCode=$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",1)
	s OrderName=..GetChckOrdItemName(OrdItem,OrdItemStr) //$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",2)
	s OrderDurFactor=1
	i DurRowid'="" s OrderDurFactor=$P($g(^PHCDU(DurRowid)),"^",2)
	s RecDepDesc=$P(^CTLOC(RecDepRowid),"^",2)
	s PACWardID=$P($g(^PAADM(Adm)),"^",70)
	s:(PACWardID'="") PACWardLocId=$P($g(^PAWARD(PACWardID)),"^",5)
	s CtrlLevelPackStr=PackQty_"^"_OrderPackUOMRowid
	if (PackQty=""){
		s CtrlLevelPackStr=1
		}
    s SessTypeID=$P(##class(DHCDoc.Interface.Inside.ServiceOPAdm).GetRegSessType(Adm),"^",1)
	s ItemAuth=##Class(PHA.FACE.OUT.Com).GetCombCtrlLevel(ARCIMRowid,CurLogonHosp,RecDepRowid,CurLogonDep,AdmDepId,$g(PACWardLocId),$g(CareProvTP),UserRowId,PAADMType,AdmReason,PatientNo,CtrlLevelPackStr,"",SessTypeID)
	;if ItemAuth'="允许" {
	if ItemAuth.CtrlLevel="BAN"{
		s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 已做用药限制，没有权限开立！")
		s FocusCol="OrderName"
		Q ErrCode_"^"_ErrMsg_"^^"_FocusCol
	}elseif (ItemAuth.CtrlLevel="PROMPT"){
		s CallBackFunParams=OrderName_..%Translate("oeorder.oplistcustom.new.csp","已做用药限制,")_ItemAuth.Remarks
		s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)	
	}
	if (PAADMType="O") {
		s MrAdmRowid=$p($g(^PAADM(Adm)),"^",61)
		s DiagnosCatArcimPass="1"
		s BillTypeDiagnosCat=##class(web.DHCDocOrderCommon).GetBillTypeDiagnosCat(PAADMType,AdmReason,CurLogonHosp)
		s EPDiagnosCat=##class(web.DHCDocOrderCommon).GetEPDiagnosCat(PAADMType,AdmReason,MrAdmRowid,CurLogonHosp)
		i EPDiagnosCat'="" {
	    	s EPHaveDiagnosCat="1"
	    	s TempStr=##class(web.DHCDocOrderCommon).GetDiagnosCatArcim(EPDiagnosCat,ARCIMRowid)
	    	s EPDurationInfo=$p(TempStr,$c(1),1)
	    	i EPDurationInfo="" { 
	    		s NotDiagnosCatArcimAllow=..%GetConfig1("DiagnosCatArcimAllow",AdmReason,CurLogonHosp)
	    		i NotDiagnosCatArcimAllow'="1" s DiagnosCatArcimPass="0"
    			i OrderType'="R" s DiagnosCatArcimPass="1"
	    	}
		}else{
	    	s NotDiagnosCatArcimAllow=..%GetConfig1("DiagnosCatArcimAllow",AdmReason,CurLogonHosp)
			i (BillTypeDiagnosCat'="")&&(OrderType="R")&&(NotDiagnosCatArcimAllow'="1") s DiagnosCatArcimPass="0"
		}
		if (DiagnosCatArcimPass = "0"){
	        s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 受病种诊断限制,不允许开 ")_AdmReasonDesc_..%Translate("oeorder.oplistcustom.new.csp"," 处方,请修改费别!")
			s FocusCol="OrderBillType"
			q ErrCode_"^"_ErrMsg_"^^"_FocusCol
	    }
	} 
	if (OEORIBindSource'="") {
		k BillTypeArr
		s PrescriptTypes=##Class(web.DHCPAADMPrescType).GetPrescTypeByPAADM(PAADMType,AdmReason,CurLogonHosp)
		for i=1:1:$L(PrescriptTypes,"||") {
			s PrescriptType=$P(PrescriptTypes,"||",i)
			continue:PrescriptType=""
			s BillTypeID2=$P(PrescriptType,"!",5)
			s SubCatIDs=$P(PrescriptType,"!",4)
			if (SubCatIDs=""){
				s BillTypeArr(BillTypeID2) = ""
			}else{
				s BillTypeArr(BillTypeID2) = "^"_SubCatIDs_"^"
			}
		}
		s SubCatIDs=$G(BillTypeArr(AdmReason))
		if (SubCatIDs'[("^"_OrderItemCatRowid_"^"))&&(SubCatIDs'=""){
			s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","此医嘱不符合 ")_AdmReasonDesc_..%Translate("oeorder.oplistcustom.new.csp"," 处方类型!")
			s FocusCol="OrderBillType"
			q ErrCode_"^"_ErrMsg_"^^"_FocusCol
		}
		;验证绑定的医嘱是否需要诊断
		if (CareProvType="DOCTOR") {
			s DiagnoseCount=##Class(web.DHCAPPExaReport).GetMRDCount(Adm,"",ARCIMRowid)
			if (DiagnoseCount=0) {
				s OrdNeedMMDiag=0
				;医嘱录入必须有西医诊断子类
			 	s OrdNeedMMDiagCat=..%GetConfig("OrdNeedMMDiagCat",CurLogonHosp)
			 	s ItemCatRowid=##class(web.DHCDocOrderCommon).GetOrderSubCat(ARCIMRowid)
			 	if ("^"_OrdNeedMMDiagCat_"^")[("^"_ItemCatRowid_"^") s OrdNeedMMDiag=1
				if (OrdNeedMMDiag=0) s AlertMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","需要诊断,请先录入！")
				else  s AlertMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","需要西医诊断,请先录入!")
				s CallBackFunParams=AlertMsg_","_OrdNeedMMDiag
				s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"NeedDiagnose",CallBackFunParams)
			}
		}
	}
	s CheckValue = "^(?!(0[0-9]{0,}$))[0-9]{1,}[.]{0,}[0-9]{0,}$"
	if (DoseQty'="")&&(('$MATCH(DoseQty,CheckValue))||(DoseQty<0)){
		s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","请输入正确的单次剂量!")
		s FocusCol="OrderDoseQty"
		q ErrCode_"^"_ErrMsg_"^^"_FocusCol
	}
	s NotLimitQty=..GetItemNotLimitQtyFlag(ARCIMRowid)
	if (DoseQty'="")&&(+DoseQty>9999)&&(NotLimitQty'="Y") {
		s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","单次剂量不能超过9999!")
		s FocusCol="OrderDoseQty"
		q ErrCode_"^"_ErrMsg_"^^"_FocusCol
	}
	if (PriorRowid = "") { 
		s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","请选择相应的医嘱类型!")
		s FocusCol="OrderPrior"
		q ErrCode_"^"_ErrMsg_"^^"_FocusCol
	}
	if (RecDepRowid = "") {
		s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","请选择相应的接收科室")
	    s FocusCol="OrderRecDep"
	    q ErrCode_"^"_ErrMsg_"^^"_FocusCol
	}
	if (DepProcNotes'="")&&((DepProcNotes["<")||(DepProcNotes[">")) {
		s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","医嘱备注中含有特殊字符<或>")
	    s FocusCol="OrderDepProcNote"
	    q ErrCode_"^"_ErrMsg_"^^"_FocusCol
	}
	if ($L(DepProcNotes)>500) {
		s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","医嘱备注不能超过500字")
	    s FocusCol="OrderDepProcNote"
	    q ErrCode_"^"_ErrMsg_"^^"_FocusCol
	}
	s OrderFreqFactor=1
	if (FreqRowid'=""){
		s OrderFreqFactor=$P($g(^PHCFR(FreqRowid)),"^",2)
		s FreeTimeFreqFlag=$P(^PHCFR(FreqRowid),"^",13)
		if (FreeTimeFreqFlag="Y"){
			s OrderFreqFactor=$L(OrderFreqFreeTimeStr,"|")
		}
		if (FirstDayTimes>OrderFreqFactor)&&(OrderFreqFactor'="") {
			s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","首日医嘱执行次数超过频次最大数")
			if (FreeTimeFreqFlag="Y"){
				s ErrMsg=ErrMsg_",特殊频次请核实选择的分发时间个数。"
			}
		    s FocusCol="OrderFirstDayTimes"
		    q ErrCode_"^"_ErrMsg_"^^"_FocusCol
		}
		
	}
	s ConFac=1
	s INCIRowid=##class(web.DHCDocOrderEntry).GetINCI(+ARCIMRowid)
	if (INCIRowid'=""){
		s ConFac=##class(web.DHCDocOrderEntry).GetConFac(ARCIMRowid,INCIRowid,OrderPackUOMRowid)
	}
	s OrderDrugFormRowid=##class(web.DHCDocOrderEntry).GetDrgForm(ARCIMRowid)
	s OrderBaseQty=##Class(web.DHCDocOrderEntry).CalDose(DoseUOMRowid,OrderDrugFormRowid,DoseQty)
	s PriorCode=$p($g(^OECPR(PriorRowid)),"^",1)
	s ISLongOrderPrior=##class(appcom.OEOrdItem).ISLongOrderPrior(PriorRowid)
	;皮试医嘱类型控制为临时
 	s CFSkinTestPriorShort=..%GetConfig("SkinTestPriorShort",CurLogonHosp)
	if (SkinTest="Y")&&(CFSkinTestPriorShort="1")&&(ISLongOrderPrior=1){
		s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","皮试医嘱医嘱类型只能是临时,请修改。")
	    s FocusCol="OrderName"
	    q ErrCode_"^"_ErrMsg_"^^"_FocusCol
	}
	s ARCIMRequireNoteFlag=##class(web.DHCDocOrderCommon).GetARCIMRequireNoteFlag(ARCIMRowid)
	if (DepProcNotes="")&&(ARCIMRequireNoteFlag="Y"){
		s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","需要备注,请填写备注!")
	    s FocusCol="OrderDepProcNote"
	    q ErrCode_"^"_ErrMsg_"^^"_FocusCol
	}
	
	if ((OrderPrice = "") || (OrderPrice < 0)) {
		s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","价格无效,不允许审核!")
	    s FocusCol="OrderPrice"
	    q ErrCode_"^"_ErrMsg_"^^"_FocusCol
    }
	if (OrderType="P"){
		if $L(OrderPrice)>10 {
			s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","自定价项目的价格数长度已经超过10位,请确认!")
		    s FocusCol="OrderPrice"
		    q ErrCode_"^"_ErrMsg_"^^"_FocusCol
		}
	}
    s IPDosingRecLocStr=##Class(DHCDoc.DHCDocConfig.DocConfig).GetDosingRecLocStr(CurLogonHosp)
    if (OrderNeedPIVAFlag="Y")&&(("^"_IPDosingRecLocStr_"^")'[("^"_RecDepRowid_"^")){
		s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","静脉配液医嘱请选择相应的静配接收科室!")
	    s FocusCol="OrderRecDep"
	    q ErrCode_"^"_ErrMsg_"^^"_FocusCol
	}
	;医生站设置-药房设置-临时医嘱拆分整包装发药(仅在急诊留观押金模式下有效)
	s ItemCatRowid=$p($g(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1)),"^",10)
	s ISLongOrderPrior=##class(appcom.OEOrdItem).ISLongOrderPrior(PriorRowid)
	s NormSplitPackQty=##Class(web.DHCDocOrderVirtualLong).GetNormSplitPackQtyFlag(Adm,RecDepRowid,ItemCatRowid)
	
	/*
	if (NormSplitPackQty=1)&&(PackQty'="")&&(ISLongOrderPrior'=1) {
		s ErrMsg=OrderName_RecDepDesc_"可拆包装发药,不允许录入整包装数量,请修改执行科室或删除数量!"
	    s FocusCol="OrderPackQty"
	    q ErrCode_"^"_ErrMsg_"^^"_FocusCol
	}
	*/
	if (OrderVirtualtLong="Y")&&(PackQty'="")&&(OrderType="R"){
		s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","虚拟长期医嘱不允许填写数量!")
	    s FocusCol="OrderPackQty"
	    q ErrCode_"^"_ErrMsg_"^^"_FocusCol
	}
	
	
	/*
	;散包装药房设置
	s CFIPDispensingRecLoc=..%GetConfig("IPDispensingRecLoc")
	if (PAADMType="I")&&(OrderType="R"){
		if (("^"_CFIPDispensingRecLoc_"^")[("^"_RecDepRowid_"^"))&&(PackQty'="") {
			s ErrMsg=OrderName_"整包装药品执行科室不能是摆药中心,请修改执行科室!"
		    s FocusCol="OrderPackQty"
		    q ErrCode_"^"_ErrMsg_"^^"_FocusCol
		}
	}
	*/
	
	if (PriorCode["ZT")&&(PAADMType="I"){
		if (OrderType'="R")&&(+OrderPrice'=0){
			s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","住院患者只有药品或0费用医嘱才能选择嘱托")
		    s FocusCol="OrderPriorRemarks"
		    q ErrCode_"^"_ErrMsg_"^^"_FocusCol
		}
	}
	if (ExceedReasonID'=""){
		s LastExceedReasonID=ExceedReasonID
	}
	s ExceedDate=##Class(web.DHCDocExceedReason).GetExceedDate(PAADMType)
	if ((ExceedReasonID="") && (OrderType="R") && (ExceedDate '= 0) && (OrderDurFactor> ExceedDate)) {
        if (PAADMType = "E") {
            s AlertErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","急诊病人处方超过")_ExceedDate_..%Translate("oeorder.oplistcustom.new.csp","天必须选择疗程超天数原因!")
        } else {
            s AlertErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","门诊病人处方超过")_ExceedDate_..%Translate("oeorder.oplistcustom.new.csp","天必须选择疗程超天数原因!")
        }
        if (LastExceedReasonID="")||(CelerType="Y"){
	        s FocusCol="ExceedReason"
	        s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"SetPageLogicFocusRow","",OrdRowIndex)
	        q ErrCode_"^"_AlertErrMsg_"^^"_FocusCol
	    }elseif (MasterSeqNo=""){
		    s ExceedReason=$p($G(^DHCDocExceedReason(LastExceedReasonID)),"^",2)
			s ExceedReason=##class(User.DHCDocExceedReason).GetTranByDesc("DHCExceedDesc",ExceedReason,langid)
		    s CallBackFunParams=AlertErrMsg_..%Translate("oeorder.oplistcustom.new.csp",",是否按【")_ExceedReason_..%Translate("oeorder.oplistcustom.new.csp","】原因保存?")_","_OrdRowIndex_","_LastExceedReasonID_","_ExceedReason
			s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"ExceedReasonConfirm",CallBackFunParams,OrdRowIndex)
		}
    }
	if (PriorCode="OUT")&&(OrderType'="R"){
		s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp",",不能将该非药品医嘱开为出院带药医嘱.")
		s FocusCol="OrderName"
        s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"SetPageLogicFocusRow","",OrdRowIndex)
        q ErrCode_"^"_ErrMsg_"^^"_FocusCol
	}
	;滴速用法
	s DrippingSpeedInstr=..%GetConfig("DrippingSpeedInstr",CurLogonHosp)
	if (OrderType="R")&&(("^"_DrippingSpeedInstr_"^")[("^"_InstrRowid_"^")) {
		s CheckValue = "^(?!(0[0-9]{0,}$))[0-9]{1,}[.]{0,}[0-9]{0,}$"
		s SpeedFlowRateLen=$l(SpeedFlowRate,"-")
		if (SpeedFlowRate="") {
			s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp",",是滴速用法,请填写输液流速!")
		}elseif (SpeedFlowRateLen>=3) {
			s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp",",请填写正确的输液流速范围,例如2-9!")
		}elseif (SpeedFlowRateLen=1) {
			if ('$MATCH(SpeedFlowRate,CheckValue)){
				s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp",",请填写正确的输液流速!")
			}
		}else {
			if ('$MATCH($p(SpeedFlowRate,"-",1),CheckValue))||('$MATCH($p(SpeedFlowRate,"-",2),CheckValue)) {
				s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp",",请填写正确的输液流速范围,例如2-9!")
			}
		}
		if (ErrMsg'="") {
			s FocusCol="OrderSpeedFlowRate"
			q ErrCode_"^"_ErrMsg_"^^"_FocusCol
		}
		/*if ('$MATCH(SpeedFlowRate,CheckValue)){
			s ErrMsg=OrderName_",是滴速用法,请填写正确的输液流速"
			s FocusCol="OrderSpeedFlowRate"
			q ErrCode_"^"_ErrMsg_"^^"_FocusCol
		}*/
		if (OrderFlowRateUnit=""){
			s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp",",是滴速用法,请选择输液流速单位")
			s FocusCol="OrderFlowRateUnit"
			q ErrCode_"^"_ErrMsg_"^^"_FocusCol
		}
	}
	//费用调整
	if (PAAdmFlag=2.5)&&(PriorCode="S"){
		s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp",",费用调整状态的患者不允许开出长期医嘱！")
		q ErrCode_"^"_ErrMsg_"^^"_FocusCol
	}
	s ARCIMExtInfo=##class(DHCDoc.DHCDocConfig.ARCIMExt).getARCIMConfig(ARCIMRowid)
	s StopAfterLongOrderFlag=$P(ARCIMExtInfo,"^",3)
	s TransType=##Class(DHCDoc.Interface.Inside.Invoke).GetArcimTransType(ARCIMRowid,CurLogonHosp)
	s DischargeOrdFlag=##class(web.DHCDocOrderEntry).IsDischargeOrd(ARCIMRowid,CurLogonHosp)
	if (StopAfterLongOrderFlag=1) {
		if (DischargeOrdFlag=0)&&(TransType="") {
			s CallBackFunParams=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 将把所有长嘱停止至")_OrderStartDate_" "_OrderStartTime_..%Translate("oeorder.oplistcustom.new.csp",",是否继续?")
			s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
		}
	}
	;出院医嘱串
	/*s dischargeNeedArcimStr=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.ord.GetDisChargeNeedArcimStr","dischargeNeedArcim", CurLogonHosp)
	s deathDischargeNeedArcimStr=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.ord.GetDisChargeNeedArcimStr","deathDischargeNeedArcim", CurLogonHosp)
	s DisChargeArcimStr=""
	i dischargeNeedArcimStr'="" s DisChargeArcimStr=dischargeNeedArcimStr
	i deathDischargeNeedArcimStr'="" s DisChargeArcimStr=DisChargeArcimStr_"^"_deathDischargeNeedArcimStr
	s ARCIMExtInfo=##class(DHCDoc.DHCDocConfig.ARCIMExt).getARCIMConfig(ARCIMRowid)
	s StopAfterLongOrderFlag=$P(ARCIMExtInfo,"^",3)
	if ("^"_DisChargeArcimStr_"^")[("^"_ARCIMRowid_"^"){
		s CallBackFunParams=OrderName_"出院医嘱将把所有长嘱停止至"_OrderStartDate_" "_OrderStartTime_",是否继续?"
		s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
	}elseif (StopAfterLongOrderFlag="1"){
		s CallBackFunParams=OrderName_" 将把所有长嘱停止至"_OrderStartDate_" "_OrderStartTime_",是否继续?"
		s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
	}*/
	
	;基本设置-》费别疗程限制,针对的是就诊费别
	s LimitDuratonRowid=..%GetConfig1("BillTypeDuration",PAADMInsType,CurLogonHosp)
	if LimitDuratonRowid'="" s MaxDurFactor=##class(web.DHCDocOrderEntry).GetDurationFactor(LimitDuratonRowid)
	e  s MaxDurFactor=0
	;诊断设置-特殊诊断分类
	if (PAADMType'="I"){
		s ret=##Class(web.DHCDocOrderCommon).CheckDiagnosCatArcimPass(Adm, AdmReason, ARCIMRowid,DIACatRowId,CurLogonHosp)
		s DiagnosCatArcimPass=$P(ret,"^",1)
		if (DiagnosCatArcimPass="0"){
			s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 受病种诊断限制,不允许开,请开自费处方!")
			s FocusCol="OrderName"
			q ErrCode_"^"_ErrMsg_"^^"_FocusCol
		}
		s DCDurationFactor=$P(ret,"^",2)
		if (DCDurationFactor>MaxDurFactor){
			s MaxDurFactor=DCDurationFactor
		}
	}
	;-
	if ((+MaxDurFactor '= 0)&&(OrderDurFactor>MaxDurFactor) && (OrderType = "R")) {
        s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 超过疗程限制,使用设置:医生站配置-诊断设置-特殊诊断分类或常规设置-费别扩展设置-疗程限制!")
		s FocusCol="OrderName"
		q ErrCode_"^"_ErrMsg_"^^"_FocusCol
    }
    if (OrderType="R")&&(PAADMType = "O")&&(+MaxDurFactor'=0)&&(+OrderBaseQty'=0){
		s CheckdurDoseQtySum = (+OrderBaseQty) * OrderFreqFactor * MaxDurFactor
		s CheckPackQty = CheckdurDoseQtySum / ConFac
		if (CheckPackQty#1>0){
			s CheckPackQty=CheckPackQty\1+1
		}else{
			s CheckPackQty=CheckPackQty\1
		}
		if (PackQty > CheckPackQty) {
			s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 整包装数量超过疗程允许的数量")
			s FocusCol="OrderPackQty"
			q ErrCode_"^"_ErrMsg_"^^"_FocusCol
	    }
	}
	//病种:
	if (ChronicDiagCode'=""){
		s ChronicOrdStartDt=..%ZDH(OrderStartDate)
		s ChronicOrdStartDt=$ZD(ChronicOrdStartDt,3)
		s ret=##class(insuqc.service.chronic.ServicePort).ISChronicOrdItm(Adm,ChronicDiagCode,OrderCode,ChronicOrdStartDt,AdmReason)
		if (ret=0){
			s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 医嘱与慢特病不匹配,无法开出!")
			s FocusCol="OrderName"
			q ErrCode_"^"_ErrMsg_"^^"_FocusCol
		}
	}
	//患者:
	//d ##class(insuqc.service.chronic.ServicePort).ISPatMatchItmOrd()
	;只需对绑定的医嘱进行验证,因为录入的医嘱在开立时已经验证过
	//if (OEORIBindSource'="") {
		;对只允许开一次的医嘱进行检测
		s PatientID=$P(^PAADM(Adm),"^",1)
		s AllowOnlyOnceRepeatFlag=##class(web.DHCDocOrderCommon).CheckARCIMAllowOnlyOnce(Adm,ARCIMRowid,.AllowOnlyOnce,.AdmAllowOnlyOnce)
		if (AllowOnlyOnceRepeatFlag>0){
			if AllowOnlyOnceRepeatFlag=1{
				s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 已设置一次就诊只允许开一次,此患者在本次就诊中已开过此医嘱,不允许在开!")
			}else{
				s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 已设置一个患者只允许开一次,此患者在历次或本次就诊中已开过此医嘱,不允许在开!")
			}
			s FocusCol="OrderName"
			Q ErrCode_"^"_ErrMsg_"^^"_FocusCol
		}
		if (AllowOnlyOnce="Y")||(AdmAllowOnlyOnce="Y") {
			for i=1:1:$length(OrdItemStr,$C(1)){
				s LoopOrdItem=$P(OrdItemStr,$C(1),i)
				continue:LoopOrdItem=OrdItem
				s LoopARCIMRowid=$P(LoopOrdItem,"^",1)
				if (LoopARCIMRowid=ARCIMRowid) {
					if AdmAllowOnlyOnce="Y"{
						s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 已设置一次就诊只允许开一次,不允许在开!")
					}else{
						s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 已设置一个患者只允许开一次,不允许在开!")
					}
					s FocusCol="OrderName"
					Q
				}
			}
		}
		if (ErrMsg'="") {
			Q ErrCode_"^"_ErrMsg_"^^"_FocusCol
		}
	//}
	//是否能正常生成执行记录监测
	;if ((PAADMType="O")||((PAADMType="E")&&(OrderVirtualtLong'="Y"))&&(OrderType="R")&&(PriorCode="NORM")) {
	if 'ISLongOrderPrior&&(OrderVirtualtLong'="Y")&&(OrderType="R"){
		s Date=..%ZDH(OrderStartDate)
		s Time=..%ZTH(OrderStartTime)
		d ##class(DHCDoc.Order.Exec).GetExecTime(.ExecList,FreqRowid,OrderDurFactor,Date,Time,FirstDayTimes,OrderFreqWeekStr,OrderFreqFreeTimeStr,CurLogonHosp,ARCIMRowid,PriorRowid)
		if '$D(ExecList){
			s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 在疗程范围内未检索到有效的用药记录，药房将无法发出该药品，请核实疗程,首日次数是否填写正确!")
			s FocusCol="OrderDur"
			Q ErrCode_"^"_ErrMsg_"^^"_FocusCol
		}
	}
	// 醉科用医技补录界面录医嘱时若该病人有手术记录，则手术列表的手术记录不能为空
	if (AnaesthesiaID'=""){
		s OperationStr=##Class(web.DHCANAdaptor).GetOperInfoByAnaId(AnaesthesiaID)
		if (OperationStr '="")&&(OperationCode ="") {
			s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 手术记录不能为空!")
			s FocusCol="OrderOperation"
			Q ErrCode_"^"_ErrMsg_"^^"_FocusCol
		}
	}
	//判断护士绑定主医嘱是否有效
	if OrderNurseLinkOrderRowid'=""{
		s StatusDR=$p($g(^OEORD(+OrderNurseLinkOrderRowid,"I",$P(OrderNurseLinkOrderRowid,"||",2),1)),"^",13)
		s StatusCode=$p($g(^OEC("OSTAT",+StatusDR)),"^",1)
		if " V E D "'[(" "_StatusCode_" "){
			s ErrMsg=OrderName_" 所绑定的主医嘱已经无效!"
			s FocusCol="OrderName"
			Q ErrCode_"^"_ErrMsg_"^^"_FocusCol
		}
	}
	if ((VerifiedOrderMasterRowid'="")&&(OrderRowid'=+VerifiedOrderMasterRowid))||
		((OrderNurseLinkOrderRowid'="")&&(OrderRowid'=+OrderNurseLinkOrderRowid))
	{
		s CallBackFunParams=OrdRowIndex
		s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"ReSetMasterSeqNo",CallBackFunParams,OrdRowIndex)
		
		s CallBackFunParams=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 护士绑定医嘱所有人与当前患者不一致,当前费用将以独立医嘱审核,请核对费用是否正确!")
	    s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
		
	}
	if VerifiedOrderMasterRowid'=""{
		s VerifiedSttDate=$P($G(^OEORD(+VerifiedOrderMasterRowid,"I",$P(VerifiedOrderMasterRowid,"||",2),1)),"^",9)
		s VerifiedFirstDayTimes=$P($G(^OEORD(+VerifiedOrderMasterRowid,"I",$P(VerifiedOrderMasterRowid,"||",2),1)),"^",18)
		if (..%ZDH(OrderStartDate)=VerifiedSttDate)&&(FirstDayTimes>VerifiedFirstDayTimes){
			s ErrMsg=OrderName_" 首日次数不能大于主绑定医嘱首日次数:"_VerifiedFirstDayTimes
			s FocusCol="OrderFirstDayTimesCode"
			Q ErrCode_"^"_ErrMsg_"^^"_FocusCol
		}
	}
	///是否需要关联录入专科表单信息
    s SpecLocDiagStr=##class(DHCDoc.Diagnos.SpecLoc).GetArcimLinkSpecLocDiag(ARCIMRowid,Adm)
    s SpecLocDiagCatID=$P(SpecLocDiagStr,"^",1)
    s SpecLocDiagCatCode=$P(SpecLocDiagStr,"^",2)
    s SpecLocDiagCatName=$P(SpecLocDiagStr,"^",3)
    if (SpecLocDiagCatID'="") {
        //s SpecLocDiagCatCode="YKMB" //眼科模板
        s OrderSerialNum="ord|"_$P(OrderSerialNum,",")
        s Count=0
        //排除一下是否有重复的专科表单
        &SQL(SELECT COUNT(ID) into :Count from SQLUser.MR_SpecLocDiag where CustomSerialNum=:OrderSerialNum and AdmDR=:Adm and Active<>'N')
        if (Count=0){
            s CallBackFunParams=OrderSerialNum_","_SpecLocDiagCatCode_","_SpecLocDiagCatName_","_OrderName
            s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"SpecDiagForm",CallBackFunParams)
        }
    }
	s ErrCode=0
	q ErrCode_"^"_ErrMsg_"^^"_FocusCol
}

/// w ##class(web.DHCOEOrdItem).CheckOrdPilotInfo()
ClassMethod CheckOrdPilotInfo(Adm As %String, OrdItem As %String, CheckExpStr As %String, OrdItemStr As %String, ByRef CallBackFunStr As %String = "") As %String
{
	n (Adm,OrdItem,CheckExpStr,OrdItemStr,CallBackFunStr,%session)
	s ^tempqujian("CheckOrdPilotInfo")=$lb(Adm,OrdItem,CheckExpStr,OrdItemStr,CallBackFunStr)
	s ErrCode=-1
	s ErrMsg=""
	s FocusCol=""
	s OutPutInfo=""
	Set langid=..%LanguageID()
	s PilotPRowId=$P(CheckExpStr,"^",1)
	s CurLogonDep=$P(CheckExpStr,"^",2)
	s CurLogonHosp =$p(^CTLOC(CurLogonDep),"^",22)
	s ARCIMRowid=$P(OrdItem,"^",1)
	s OrderType=$p(OrdItem,"^",2)
	s PilotProRowId=$p(OrdItem,"^",56)
	s OrderName=$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",2)
	s OrderName=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",OrderName,langid)
	s PilotCatFlag=##Class(web.DHCDocOrderCommon).CheckPilotCat(Adm, ARCIMRowid,PilotPRowId,CurLogonHosp)

	/*if (PilotCatFlag '= "Y") {
		b ;0934
		if (PilotPRowId= "") {
			s OutInfo="-1^"_OrderName_"此医嘱为药理项目医嘱,只能在有药理项目的情况下才可下."
			s $P(OutInfo,"^",4)="OrderName"
			q OutInfo
		} else {*/
	if (PilotProRowId=""){
		if ("Y"'=PilotCatFlag){
			s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp","此医嘱为药理项目医嘱,只能在有药理项目的情况下才可下.")
			s $P(OutInfo,"^",4)="OrderName"
			q OutInfo		}
	}else{
		    ;GCP判断规则修改：优先判断免费医嘱，后子类 2021-11-30 QP
			s PilotCatStr=$G(^DHCDocPilotSeting(CurLogonHosp,"PilotProSubCatStr"))
			s ItemCatDr=$P(^ARCIM(+ARCIMRowid,$P(ARCIMRowid,"||",2),1),"^",10) 
	        s PPOpenOrdEntryLimit=$p($g(^DHCDocPP(PilotPRowId)),"^",117)
	        if (PPOpenOrdEntryLimit="Y"){
	            ;开启医嘱录入限制
	            ;s FreeStr=##class(web.PilotProject.DHCDocPilotProject).CheckArcim(BaseParamArr("PPRowId"),OrderARCIMRowid)
	            s FreeStr=##class(web.PilotProject.CFG.FindGCP).CheckArcim(PilotPRowId,ARCIMRowid,Adm)
	            s FreeFlag=$p(FreeStr,"^",1)
	            if (FreeFlag="Y") {
	                s PPFreeNum=$p(FreeStr,"^",2) ;项目免费次数
	                s PPFLimitEntryAfterNoFreeNum=$p(FreeStr,"^",3) ;免费次数用完是否限制录入
	                ;已免费的数量
	                s PPPARowId=##class(web.PilotProject.DHCDocPilotProject).GetPilotProPatAdmRowId(PilotPRowId,ARCIMRowid,Adm)
	                s InStage=##class(web.PilotProject.Extend.PatAdd).GetStageByAdm(PilotPRowId,Adm,"")
	                s PilotProHasFreeNum=##class(web.PilotProject.DHCDocPilotProject).GetPilotProFreeSum(PPPARowId,ARCIMRowid,InStage)
	                s RepeatNum=0
	                for j=1:1:$L(OrdItemStr,$c(1)){
		                s OneOrdItemStr=$P(OrdItemStr,$c(1),j)
		                q:OneOrdItemStr=""
		                s tmpOrderItemRowid = $p(OneOrdItemStr,"^",20)
	                    s tmpOrderARCIMRowid =$P(OneOrdItemStr,"^",1)
	                    ;OrderSeqNo
	                    continue:(tmpOrderARCIMRowid'=ARCIMRowid)
	                    s RepeatNum=RepeatNum+1
		                }
	                ;m ^tmpscl("ItemOrdsArr")=ItemOrdsArr("ItemOrds")
	                s LeftFreeNum=PPFreeNum-PilotProHasFreeNum-RepeatNum
	                if (LeftFreeNum<0){
	                    if (PPFLimitEntryAfterNoFreeNum="Y"){
	                        s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp","药理项目维护的医嘱免费次数已用完!")
							s $P(OutInfo,"^",4)="OrderName"
							q OutInfo
	                    }else{
	                        //s CallBackFunParams=ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","药理项目维护的医嘱免费次数已用完!请谨慎使用!")
	                        //s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
	                    }
	                }
	            } elseif (FreeFlag="N"){
	                ;维护了该医嘱，只是过期了，再判断子类
	                if (("!"_PilotCatStr_"!")'[("!"_ItemCatDr_"!")){
	               		s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp","药理项目维护的免费医嘱已过期！")
							s $P(OutInfo,"^",4)="OrderName"
							q OutInfo
	                }else{
	                    ;在子类中，免费开具
	                }
	            } else {
	                ;没有维护该医嘱,判断子类，不在子类中的不允许开具
	                if (("!"_PilotCatStr_"!")'[("!"_ItemCatDr_"!")){
	                    ;提示的内容可以根据项目要求进行自行更改
	                    ;s OutInfo="-1^"_ArcimDesc_"此医嘱为非药理项目医嘱,不能在有药理项目的情况下开.^^^^"
	                    ;s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","在有药理项目的情况下,药理项目开启医嘱录入限制时只有项目维护免费医嘱的才可开立.")_"^^^^"	
	                	s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp","在有药理项目的情况下,药理项目开启医嘱录入")
							s $P(OutInfo,"^",4)="OrderName"
							q OutInfo
	                }else{
	                    ;在子类中，免费开具
	                }
	            }
	        }else{
	            ;没开启限制，则判断子类，并且非药理子类的非药品可无限制录入且全部免费
	            if (("!"_PilotCatStr_"!")'[("!"_ItemCatDr_"!")){
	                ;不在子类中，非药品可无限制录入且全部免费
	                if (OrderType="R"){
	               		s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp","此药品医嘱为非药理项目药品医嘱,不能在有药理项目的情况下开.")
						s $P(OutInfo,"^",4)="OrderName"
						q OutInfo
	                } 
	            }else{
	                ;在子类中，免费开具
	            }
	        }
		}

	if ((PilotPRowId= "") && (PilotProRowId '= "")) {
		s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp","选择过科研列表,请在药理患者列表中选择对应的患者后录入，或者删除该项目从新录入？")
		s $P(OutInfo,"^",4)="OrderName"
		q OutInfo
	}
	q "0^^"
}

ClassMethod CheckMaterialBarcode(Adm As %String, OrdItemStr As %String, CheckExpStr As %String, ByRef CallBackFunStr As %String = "", SessionStr As %String = "") As %String
{
	n (Adm,OrdItemStr,CheckExpStr,CallBackFunStr,%session,SessionStr)
	s ^tempscl("CheckMaterialBarcode")=Adm_","_OrdItemStr_","_CheckExpStr
	s Loc=$P(CheckExpStr,"^",1)
	Set langid=..%LanguageID()
	s OutInfo="0^^"
	;高值录入控制标志(科室扩展第13位)
	s HighValueControl=##class(web.DHCDocConfig).GetDHCCTLOCFieldValue(Loc,13)
	if (HighValueControl'=1){
		q OutInfo
	}
	K OrderMaterialBarList
	Set OrdItemCount=$L(OrdItemStr,$c(1))
	for i=1:1:OrdItemCount {
		s OrdItem=$p(OrdItemStr,$c(1),i)
		continue:OrdItem=""
		s ARCIMRowid=$p(OrdItem,"^",1)
		continue:ARCIMRowid=""
		
		s ARCIMRowid=$P(OrdItem,"^",1)
		s PriorRowid=$p(OrdItem,"^",3)
		s PackQty=$p(OrdItem,"^",14)
		s RecDepRowid=$p(OrdItem,"^",8)
		s OrderMaterialBarCode=$p(OrdItem,"^",41)
		s OrderName=$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",2)
		s OrderName=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",OrderName,langid)
		s PriorCode=$p($g(^OECPR(PriorRowid)),"^",1)
		s IncItmHighValueFlag=##Class(web.DHCDocOrderCommon).GetIncItmHighValueFlag(ARCIMRowid)
		continue:(IncItmHighValueFlag'="Y")
		s ret=##Class(DHCDoc.Interface.Outside.HRPService).GetArcimByLabel(OrderMaterialBarCode,SessionStr,RecDepRowid)
		s BarCodearcimRowid = $P(ret,"^",1)
		s OriginalStatusFlag=$P(ret,"^",10)
		if ((OriginalStatusFlag'="Y")&&(+PackQty '= 1)) {
			s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 属于唯一码高值耗材,数量只能为1!")
			s $P(OutInfo,"^",4)="OrderPackQty"
			q
		}
		if (OrderMaterialBarCode = ""){
	        s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp","属于高值耗材,只能通过扫条码下医嘱!")
	        s $P(OutInfo,"^",4)="OrderMaterialBarCode"
	        q
	    }
	    if (PriorCode '= "NORM") {
	        s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp","高值材料请开临时医嘱使用!")
	        q
		}
		s OrdInfo=RecDepRowid_"^^^"
	    s OrderMaterialBarList(OrderMaterialBarCode,OrdInfo,"Info")=ARCIMRowid
	    s OrderMaterialBarList(OrderMaterialBarCode,OrdInfo,"Qty")=$G(OrderMaterialBarList(OrderMaterialBarCode,"Qty"))+PackQty
		s OrderMaterialBarList(OrderMaterialBarCode,OrdInfo,"RecDep")=RecDepRowid
	}
	if (+OutInfo<0){
		q OutInfo
	}
	if '$D(OrderMaterialBarList){
		q OutInfo
	}
	///Why?
	s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"CheckPatCount",OrderMaterialBarCode)
	s OrderMaterialBarCode=0
	for {
		s OrderMaterialBarCode=$O(OrderMaterialBarList(OrderMaterialBarCode))
		q:(OrderMaterialBarCode="")
		s OrdInfo=""
		for {
			s OrdInfo=$O(OrderMaterialBarList(OrderMaterialBarCode,OrdInfo))
			q:(OrdInfo="")
			s RecDepRowid=$P(OrdInfo,"^",1)
			s ARCIMRowid=$P($G(OrderMaterialBarList(OrderMaterialBarCode,OrdInfo,"Info")),"^",1)
			s PackQty=$G(OrderMaterialBarList(OrderMaterialBarCode,OrdInfo,"Qty"))
			s RecDepRowid=$G(OrderMaterialBarList(OrderMaterialBarCode,OrdInfo,"RecDep"))
			s OrderName=$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",2)
			s ret=##class(DHCDoc.Interface.Outside.HRPService).GetArcimByLabel(OrderMaterialBarCode,SessionStr,RecDepRowid)
			if ($P(ret,"^",2)= "Enable") {
				s arcimRowid = $P(ret,"^",1)
	            s avaQty = $P(ret,"^",5)
	            if (avaQty < PackQty)||(avaQty<=0) {
	                s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 该条码对应的医嘱库存不足.当前可用数量:")_avaQty_"."
	                q
	            }
	            s ReLocId = $P(ret,"^",6) //材料可用接收科室
	            if (ReLocId '= RecDepRowid)&&(ReLocId'="") {
	                s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp","该条码接收科室错误!")
	                q
	            }
	            if ((ARCIMRowid '= "") && (ARCIMRowid '= arcimRowid)) {
		            s CurrectName=$p(^ARCIM(+arcimRowid,$p(arcimRowid,"||",2),1),"^",2)
					s CurrectName=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",CurrectName,langid)
	                s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp","条码和所对应的医嘱项目不符.该条码所属医嘱项为:")_CurrectName_"."
	                q
	            }
			}else{
				s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 条码:") _ OrderMaterialBarCode _ ..%Translate("oeorder.oplistcustom.new.csp","不可用或已被他人占用："_$p(ret,"^",2))
	            s $P(OutInfo,"^",4)="OrderMaterialBarcode"
	            q
			}
		}
	}
    q OutInfo
}

ClassMethod CheckMaterialBarcodebak(Adm As %String, OrdItem As %String, CheckExpStr As %String, ByRef CallBackFunStr As %String = "", SessionStr As %String = "") As %String
{
	n (Adm,OrdItem,CheckExpStr,CallBackFunStr,SessionStr)
	s ^tempscl("CheckMaterialBarcode")=Adm_","_OrdItem_","_CheckExpStr
	s Loc=$P(CheckExpStr,"^",1)
	s ARCIMRowid=$P(OrdItem,"^",1)
	s PriorRowid=$p(OrdItem,"^",3)
	s PackQty=$p(OrdItem,"^",14)
	s RecDepRowid=$p(OrdItem,"^",8)
	s OrderMaterialBarCode=$p(OrdItem,"^",41)
	
	s OrderName=$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",2)
	s PriorCode=$p($g(^OECPR(PriorRowid)),"^",1)
	;高值录入控制标志(科室扩展第13位)
	s HighValueControl=##class(web.DHCDocConfig).GetDHCCTLOCFieldValue(Loc,13)
	if (HighValueControl'=1){
		q "0^"
	}
	s IncItmHighValueFlag=##Class(web.DHCDocOrderCommon).GetIncItmHighValueFlag(ARCIMRowid)
	if (IncItmHighValueFlag'="Y"){
		q "0^"
	}else{
		s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"CheckPatCount",OrderMaterialBarCode)
	}
	if ((IncItmHighValueFlag = "Y") && (OrderMaterialBarCode = "")) {
        s OutInfo="-1^"_OrderName_"属于高值耗材,只能通过扫条码下医嘱!"
        s $P(OutInfo,"^",4)="OrderMaterialBarCode"
        q OutInfo
    }
    if ((OrderMaterialBarCode '= "") && (IncItmHighValueFlag = "Y")) {
		if (+PackQty '= 1) {
			s OutInfo="-1^"_OrderName_" 属于高值耗材,数量只能为1!"
			s $P(OutInfo,"^",4)="OrderPackQty"
			q OutInfo
		}
		s ret=##Class(DHCDoc.Interface.Outside.HRPService).GetArcimByLabel(OrderMaterialBarCode,SessionStr)
        if ($P(ret,"^",2)= "Enable") {
            s arcimRowid = $P(ret,"^",1)
            s avaQty = $P(ret,"^",5)
            if (avaQty <= 0) {
                s OutInfo="-1^"_OrderName_" 该条码对应的医嘱库存不足."
                q OutInfo
            }
            s ReLocId = $P(ret,"^",6) //材料可用接收科室
            if (ReLocId '= RecDepRowid) {
                s OutInfo="-1^"_OrderName_"该条码接收科室错误!"
                q OutInfo
            }
            if ((ARCIMRowid '= "") && (ARCIMRowid '= arcimRowid)) {
                s OutInfo="-1^"_OrderName_"条码和所对应的医嘱项目不符."
                q OutInfo
            }
        } else {
            s OutInfo="-1^"_OrderName_" 条码:" _ OrderMaterialBarCode _ "不可用或已被他人占用,请输入其它条码!"
            s $P(OutInfo,"^",4)="OrderMaterialBarcode"
            q OutInfo
        }
        if (PriorCode '= "NORM") {
	        s OutInfo="-1^"_OrderName_"高值材料请开临时医嘱使用!"
	        q OutInfo
		}
    }
    
    q "0^^"
}

ClassMethod CheckOrderDateTime(Adm As %String, OrdItem As %String, OrdItemStr As %String, CheckExpStr As %String, ByRef CallBackFunStr As %String = "") As %String
{
	n (Adm,OrdItem,OrdItemStr,CheckExpStr,CallBackFunStr,%session)
	s ^tempscl("CheckOrderDateTime")=Adm_","_OrdItem_","_CheckExpStr
	s PAADMType=$p($g(^PAADM(Adm)),"^",2)
	Set langid=..%LanguageID()
	s Loc=$P(CheckExpStr,"^",1)
	s CurLogonHosp =$p(^CTLOC(Loc),"^",22)
	s ARCIMRowid=$P(OrdItem,"^",1)
	s PriorRowid=$p(OrdItem,"^",3)
	s OrderStartDate=$p(OrdItem,"^",4)
	s OrderStartTime=$p(OrdItem,"^",5)
	s EndDate=$p(OrdItem,"^",26)
	s EndTime=$p(OrdItem,"^",27)
	s VerifiedOrderMasterRowid=$p(OrdItem,"^",39)
	s OrderDate=$p(OrdItem,"^",46)
 	s OrderTime=$p(OrdItem,"^",47)
 	s OrderNurseLinkOrderRowid=$p(OrdItem,"^",63)
 	s OrderNurseBatchAdd=$p(OrdItem,"^",71) //护士批量补录标志
 	s OrderName=$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",2)
	s OrderName=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",OrderName,langid)
 	s ISLongOrderPrior=##class(appcom.OEOrdItem).ISLongOrderPrior(PriorRowid)
 	;获取病人当前出院状态,调用护理组接口
 	s CurrentDischargeStatus=##class(web.DHCDischargeHistory).GetCurrentDischargeStatus(Adm)
	s ModifySttDateTimeAuthority=##class(web.DHCDocConfig).GetDHCCTLOCFieldValue(Loc,9) //医嘱开始日期修改权限
	s ModifySttDateTimeUpHour=+##class(web.DHCDocConfig).GetDHCCTLOCFieldValue(Loc,21) //医嘱开始时间可提前小时数
	s ModifySttDateTimeDownHour=+##class(web.DHCDocConfig).GetDHCCTLOCFieldValue(Loc,33) //医嘱开始时间可延后小时数
	s ModifyDateTimeAuthority=##class(web.DHCDocConfig).GetDHCCTLOCFieldValue(Loc,25) //开医嘱日期修改权限
	s ModifyDateTimeUpHour=+##class(web.DHCDocConfig).GetDHCCTLOCFieldValue(Loc,26) //开医嘱时间可提前小时数
	s ModifyDateTimeDownHour=+##class(web.DHCDocConfig).GetDHCCTLOCFieldValue(Loc,34) //开医嘱时间可延后小时数
	s DHCARCIMRowid=$O(^DHCItmMast("0","ARCIM",ARCIMRowid,0))
	i DHCARCIMRowid'="" {
		s SttIsCanCrossDay=$P(^DHCItmMast(DHCARCIMRowid),"^",11) //医嘱开始日期时间是否可以跨日
		s OrdDateCanCrossDay=$P(^DHCItmMast(DHCARCIMRowid),"^",25) //开医嘱日期时间是否可以跨日
	}else{
		s SttIsCanCrossDay="",OrdDateCanCrossDay=""
	}
	/*s SttDateTimeModifyFlag=..CheckDateTimeModifyFlag(ModifySttDateTimeAuthority,SttIsCanCrossDay)
	if (SttDateTimeModifyFlag="0"){
		q "0^"
	}*/
	//if (CurrentDischargeStatus= "B") {
        s DischargeDateTime=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.doc.GetDischargeDateTime",Adm)
		s DischargeDate=$p(DischargeDateTime,"^",1)
		s DischargeTime=$p(DischargeDateTime,"^",2)
		//s OrderDate=DischargeDate
		//s OrderTime=DischargeTime
    //}
    if (DischargeDate ="") {
	    for i=1:1:$length(OrdItemStr,$C(1)){
		    s LoopOrdItem=$P(OrdItemStr,$C(1),i)
		    s LoopARCIMRowid=$P(LoopOrdItem,"^",1)
		    continue:(LoopARCIMRowid =ARCIMRowid)
		    s DischargeOrdFlag=##class(web.DHCDocOrderEntry).IsDischargeOrd(LoopARCIMRowid,CurLogonHosp)
		    if (DischargeOrdFlag=0) continue
 			s DischargeDate=..%ZDH($p(LoopOrdItem,"^",4))
			s DischargeTime=..%ZTH($p(LoopOrdItem,"^",5))
			Q
		}
	}
	if (OrderDate=""){
		s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 请选择开医嘱日期!")
		s $P(OutInfo,"^",4)="OrderDate"
		q OutInfo
	}
	if (OrderStartDate=""){
		s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 请选择医嘱开始日期!")
		s $P(OutInfo,"^",4)="OrderStartDate"
		q OutInfo
	}
	if (OrderStartTime="undefined")||((OrderStartTime'[":")){
		s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 医嘱开始日期格式错误!")
		s $P(OutInfo,"^",4)="OrderStartDate"
		q OutInfo
	}
	if (OrderTime="undefined")||((OrderTime'[":")&&(CurrentDischargeStatus'="B")){
		s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 开医嘱日期格式错误!")
		s $P(OutInfo,"^",4)="OrderDate"
		q OutInfo
	}
	s OrderStartDate=..%ZDH(OrderStartDate)
	s OrderStartTime=..%ZTH(OrderStartTime)
	s OrderDate=..%ZDH(OrderDate)
	if (OrderTime[":") s OrderTime=..%ZTH(OrderTime)
	s:EndDate'="" EndDate=..%ZDH(EndDate)
	s:EndTime'="" EndTime=..%ZTH(EndTime)
	if (DischargeDate'="")&&(OrderNurseBatchAdd'="Y") {
		s DischargeDateTime=..%ZD(DischargeDate)_" "_..%ZT(DischargeTime,1)
	    if ((OrderDate=DischargeDate)&&(OrderTime>DischargeTime))||(OrderDate>DischargeDate) {
		    s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 开医嘱日期不能大于出院时间：")_DischargeDateTime
			s $P(OutInfo,"^",4)="OrderDate"
			q OutInfo
		}
		if ((OrderStartDate=DischargeDate)&&(OrderStartTime>DischargeTime))||(OrderStartDate>DischargeDate) {
		    s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 医嘱开始日期不能大于出院时间：")_DischargeDateTime
			s $P(OutInfo,"^",4)="OrderStartDate"
			q OutInfo
		}
	}
	if (ISLongOrderPrior=1)&&(OrderStartDate<+$h) {
		s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 医嘱开始日期不能小于今天!")
		s $P(OutInfo,"^",4)="OrderStartDate"
		q OutInfo
	}
	s tmpVerifiedOrderMasterRowid=VerifiedOrderMasterRowid
	if (OrderNurseLinkOrderRowid'="") s tmpVerifiedOrderMasterRowid=OrderNurseLinkOrderRowid
	if (+tmpVerifiedOrderMasterRowid>0){
		s VerifiedSttData=$P(^OEORD(+tmpVerifiedOrderMasterRowid,"I",$P(tmpVerifiedOrderMasterRowid,"||",2),1),"^",9)
		s VerifiedSttTime=$P(^OEORD(+tmpVerifiedOrderMasterRowid,"I",$P(tmpVerifiedOrderMasterRowid,"||",2),1),"^",10)
		if (OrderStartDate<VerifiedSttData)||((OrderStartDate=VerifiedSttData)&&(OrderStartTime<VerifiedSttTime)){
			s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 补录医嘱的开始日期不能小于所补录医生医嘱的开始日期!")
			s $P(OutInfo,"^",4)="OrderStartDate"
			q OutInfo
		}
		if (OrderStartDate<+$h)&&(ISLongOrderPrior=1){
			s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 补录的长期医嘱的开始日期不能小于今天!")
			s $P(OutInfo,"^",4)="OrderStartDate"
			q OutInfo
		}
	}
	//Q:CurrentDischargeStatus="B" "0^"
	if (CurrentDischargeStatus'="B"){
		//若医嘱项设置允许医嘱开始日期可跨日,不进行可提前小时数判断
	    if (+ModifySttDateTimeUpHour>0)&&(SttIsCanCrossDay'="Y")&&(ModifySttDateTimeAuthority=1){
			s DiffHour=##class(DHCDoc.Util.Date).GetDiffSecond(OrderStartDate_","_OrderStartTime,$H)
			if DiffHour>ModifySttDateTimeUpHour{
			    s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 医嘱开始日期限制只能在当前时间往前调 ")_ModifySttDateTimeUpHour_..%Translate("oeorder.oplistcustom.new.csp","小时,请修改后重试!")
		        s $P(OutInfo,"^",4)="OrderStartDate"
				q OutInfo
			}
		}
		//若医嘱项设置允许开医嘱日期可跨日,不进行可提前小时数判断
		if (+ModifyDateTimeUpHour>0)&&(OrdDateCanCrossDay'="Y")&&(ModifyDateTimeAuthority=1){
			s DiffHour=##class(DHCDoc.Util.Date).GetDiffSecond(OrderDate_","_OrderTime,$H)
		    if DiffHour>ModifyDateTimeUpHour{
			    s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 开医嘱日期限制只能在当前时间往前调 ")_ModifyDateTimeUpHour_..%Translate("oeorder.oplistcustom.new.csp","小时,请修改后重试!")
		        s $P(OutInfo,"^",4)="OrderDate"
				q OutInfo
			}
		}
	}
	if (+ModifySttDateTimeDownHour>0)&&(ModifySttDateTimeAuthority=1){
		s DiffHour=##class(DHCDoc.Util.Date).GetDiffSecond($H,OrderStartDate_","_OrderStartTime)
		if DiffHour>ModifySttDateTimeDownHour{
			s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 医嘱开始日期限制只能在当前时间往后调 ")_ModifySttDateTimeDownHour_..%Translate("oeorder.oplistcustom.new.csp","小时,请修改后重试!")
			s $P(OutInfo,"^",4)="OrderStartDate"
			q OutInfo
		}
	}
	
	if (+ModifyDateTimeDownHour>0)&&(ModifyDateTimeAuthority=1){
		s DiffHour=##class(DHCDoc.Util.Date).GetDiffSecond($H,OrderDate_","_OrderTime)
		if DiffHour>ModifyDateTimeDownHour{
			s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 开医嘱日期限制只能在当前时间往后调 ")_ModifyDateTimeDownHour_..%Translate("oeorder.oplistcustom.new.csp","小时,请修改后重试!")
			s $P(OutInfo,"^",4)="OrderDate"
			q OutInfo
		}
	}
	s CheckMessage=##Class(web.DHCDocOrderCommon).CheckOrderDate(Adm,$ZD(OrderDate,3)_" "_..%ZT(OrderTime))
	if (CheckMessage'=""){
		s OutInfo="-1^"_OrderName_" "_..%Translate("oeorder.oplistcustom.new.csp",CheckMessage)
		s $P(OutInfo,"^",4)="OrderDate"
		q OutInfo
	}
	if (PAADMType="I"){
		//判断转科时间
		s ret=##class(web.DHCDocOrderEntry).CheckOrderStartDateByZKAdm(Adm,$ZD(OrderStartDate,4)_" "_..%ZT(OrderStartTime),$ZD(OrderDate,4)_" "_..%ZT(OrderTime),Loc)
		if (ret'="0"){
			if ($p(ret,"^",1)="-1"){
				s OutInfo="-1^"_OrderName_" "_$p(ret,"^",2)
				s $P(OutInfo,"^",4)="OrderStartDate"
			}else{
				s OutInfo="-1^"_OrderName_" "_$p(ret,"^",2)
				s $P(OutInfo,"^",4)="OrderDate"
			}
			q OutInfo
		}
	}
	
	//if (OrderStartDate<OrderDate)||((OrderStartDate=OrderDate)&&(OrderStartTime<OrderTime)){
	if (OrderStartDate<OrderDate){
		s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 医嘱开始日期不能小于开医嘱日期!")
		s $P(OutInfo,"^",4)="OrderStartDate"
		q OutInfo
	}
	if (OrderStartDate=OrderDate)&&(OrderTime>OrderStartTime){
		s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 医嘱开始时间不能小于开医嘱时间!")
		s $P(OutInfo,"^",4)="OrderStartDate"
		q OutInfo
	}
	if (EndDate'="")&&((EndDate<OrderStartDate)||((EndDate=OrderStartDate)&&(EndTime<OrderStartTime))){
        s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 医嘱结束日期日期不能小于医嘱开始日期")
        s $P(OutInfo,"^",4)="OrderEndDate"
		q OutInfo
    }
    ;开医嘱时间限制
	s ExpStr=ARCIMRowid_"^"_$ZD(OrderStartDate,3)_"^"_..%ZT(OrderStartTime)
	s ret=##Class(web.DHCOEOrdItem).CheckOrderStartTime(Adm,ExpStr)
	if (+ret'=0){
		s OutInfo="-1^"_$P(ret,"^",2)
        s $P(OutInfo,"^",4)="OrderStartDate"
		q OutInfo
	}
    
	q "0^"
}

ClassMethod CheckDateTimeModifyFlag(ModifyDateTimeAuthority, IsCanCrossDay) As %String
{
	n (ModifyDateTimeAuthority,IsCanCrossDay)
	if (IsCanCrossDay="N") {
		return 0
	}elseif (IsCanCrossDay="Y") {
		return 1
	}else{
		//未进行医嘱项扩展设定,走科室权限
		if (ModifyDateTimeAuthority'="1") return 0
	}
	return 1
}

ClassMethod CheckDrugUpdate(Adm As %String, OrdItem As %String, OrdItemStr As %String, ByRef CallBackFunStr As %String, ByRef OrderInstrGroupArr As %String, OrdRowIndex As %String = "", SessionStr As %String = "") As %String
{
	n (Adm,OrdItem,OrdItemStr,CallBackFunStr,OrderInstrGroupArr,%session,OrdRowIndex,SessionStr)
	s AdmLocDr=$p($g(^PAADM(Adm)),"^",4)
	s LocHospDr=$p(^CTLOC(AdmLocDr),"^",22)
	s PAADMType=$p($g(^PAADM(Adm)),"^",2)
	s PAADMInsType=$P(^PAADM(Adm,1),"^",7)
	s ARCIMRowid=$P(OrdItem,"^",1)
	s OrderType=$P(OrdItem,"^",2)
	s PriorRowid=$p(OrdItem,"^",3)
	Set PackQty=$p(OrdItem,"^",6)
	Set AdmReason=$replace($p(OrdItem,"^",9),$c(10),"")
	Set DepProcNotes=$p(OrdItem,"^",11)
	Set DoseQty=$p(OrdItem,"^",12)
	Set DoseUOMRowid=$p(OrdItem,"^",13)
	Set FreqRowid=$p(OrdItem,"^",15)
	Set DurRowid=$p(OrdItem,"^",16)
	Set InstrRowid=$p(OrdItem,"^",17)
	Set PHPrescType=$p(OrdItem,"^",18)
	Set MasterSeqNo=$p(OrdItem,"^",19)
	Set OrderSeqNo=$p(OrdItem,"^",20)
	Set OrderPackUOMRowid=$p(OrdItem,"^",55)
	Set OEORIBindSource=$p(OrdItem,"^",58) //医嘱绑定来源
	Set CelerType=$p(OrdItem,"^",65)
	Set OrdRowIndex=$p(OrdItem,"^",66)	//实际的行号
	Set OrderFreqDispTimeStr=$p(OrdItem,"^",67)
	Set OrderFreqTimeDoseStr=$p(OrdItem,"^",70)
	Set OrderNurseBatchAdd=$p(OrdItem,"^",71) //护士批量补录标志
	Set OrderFreqFreeTimeStr=$p(OrdItem,"^",83)
	Set OrderFreqFreeTimeStr=##Class(web.DHCOEOrdItem).FormFreqFreeTimeHtmlToLogical(OrderFreqFreeTimeStr)
	//s OrderName=$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",2)
	s OrderName=..GetChckOrdItemName(OrdItem,OrdItemStr) //$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",2)
	s PriorCode=$p($g(^OECPR(PriorRowid)),"^",1)
	s ISLongOrderPrior=##class(appcom.OEOrdItem).ISLongOrderPrior(PriorRowid)
	s DrugFormRowid=##class(web.DHCDocOrderEntry).GetDrgForm(ARCIMRowid)
	s INCIRowid=##class(web.DHCDocOrderEntry).GetINCI(+ARCIMRowid)
	s OnePriorOrdControl=..%GetConfig("OnePriorOrdControl",LocHospDr)
	s OnePriorRowID=$O(^OECPR(0,"Code","ONE",0))
	s UserRowId=$p(SessionStr,"^",1)
	s CareProvType=##class(web.DHCDocOrderCommon).GetCareProvType(UserRowId)
    s CareProvType=$zcvt(CareProvType,"U")
	//Q:(PriorRowid=OnePriorRowID)&&(OnePriorOrdControl=0)&&(OrderNurseBatchAdd'="Y") "0^^^^"
	Q:(PriorRowid=OnePriorRowID)&&((OnePriorOrdControl=0)||(CareProvType'="DOCTOR")) "0^^^^"
	;外用用法
	s WYInstr=..%GetConfig("WYInstr",LocHospDr)
	if (MasterSeqNo'=""){
		if (OrderSeqNo=MasterSeqNo){
			if (CelerType="Y"){
				s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 关联号错误，不能关联自身医嘱")
				q OutInfo
			}else{
				s CallBackFunParams=OrdRowIndex
				s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"ReSetMasterSeqNo",CallBackFunParams,OrdRowIndex)
			}
		}
	}
	s CheckValue = "^(?!(0[0-9]{0,}$))[0-9]{1,}[.]{0,}[0-9]{0,}$"
	if ("^"_WYInstr_"^")'[("^"_InstrRowid_"^"){
		if (OrderFreqTimeDoseStr=""){
			if (((DoseQty = "") || (DoseQty = 0) || ('$MATCH(DoseQty,CheckValue)))) {
				s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 没有录入剂量")
				s:OEORIBindSource="" $P(OutInfo,"^",4)="OrderDoseQty"
				q OutInfo
			}
			if (DoseQty<0){
				s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 剂量不能为负数")
				s:OEORIBindSource="" $P(OutInfo,"^",4)="OrderDoseQty"
				q OutInfo
			}
		}
		if (DoseUOMRowid=""){
			s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 没有选择剂量单位")
			s $P(OutInfo,"^",4)="OrderDoseUOM"
			q OutInfo
			
		}
		if (DurRowid="")&&(ISLongOrderPrior'="1"){
			s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 没有录入疗程")
			s $P(OutInfo,"^",4)="OrderDur"
			q OutInfo
		}
	}
	if (FreqRowid=""){
		s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 没有录入频次")
		s $P(OutInfo,"^",4)="OrderFreq"
		q OutInfo
	}
	if (InstrRowid=""){
		s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 没有录入用法")
		s $P(OutInfo,"^",4)="OrderInstr"
		q OutInfo
	}
	i DurRowid'="" s FormDurFactor=$P($g(^PHCDU(DurRowid)),"^",2)
	e  s FormDurFactor=1
	s FreqFactor=$P($g(^PHCFR(FreqRowid)),"^",2)
	s FreeTimeFreqFlag=$P($g(^PHCFR(FreqRowid)),"^",13)
	if (FreeTimeFreqFlag="Y") {
		s FreqFactor=$l(OrderFreqFreeTimeStr,"|")
	}
	//判断药品剂量控制==================================
	s (BaseUOMRowid,BaseUOMDesc)=""
	i INCIRowid'="" d
	.s BaseUOMRowid=$p($g(^INCI(INCIRowid,1)),"^",10)
	.s BaseUOMDesc=##Class(web.DHCDocOrderCommon).GetUOMDesc(BaseUOMRowid)
	;取等效剂量
	if (OrderFreqTimeDoseStr="") {
 		s BaseDoseQty=##Class(web.DHCDocOrderEntry).CalEqDose(DoseUOMRowid,DrugFormRowid,DoseQty,"BaseUom")
 		s BaseDoseQtyPerDay = BaseDoseQty * FreqFactor
 	}else{
		;需考虑首日例外
	 	s MaxDoseQty=0,BaseDoseQtyPerDay=0
	 	s OneBaseDoseQty=##Class(web.DHCDocOrderEntry).CalEqDose(DoseUOMRowid,DrugFormRowid,1,"BaseUom")
		s FirstDayFreqTimeDoseStr=$P(OrderFreqTimeDoseStr,"@",2)
		s OrderFreqTimeDoseStr=$P(OrderFreqTimeDoseStr,"@",1)
		for myFreqTimeDoseStr=FirstDayFreqTimeDoseStr,OrderFreqTimeDoseStr{
			continue:myFreqTimeDoseStr=""
			s OneBaseDoseQtyPerDay=0
			s DoseQtyStrLen=$l(myFreqTimeDoseStr,"!")
			for m=1:1:DoseQtyStrLen {
				s OrderDoseQtyStr=$p(myFreqTimeDoseStr,"!",m)
				s oneOrderDoseQty=$p(OrderDoseQtyStr,"$",2)
				continue:oneOrderDoseQty=""
				s oneOrderDoseQty=OneBaseDoseQty*oneOrderDoseQty
				if (oneOrderDoseQty>MaxDoseQty) s MaxDoseQty=oneOrderDoseQty
				s OneBaseDoseQtyPerDay=OneBaseDoseQtyPerDay+oneOrderDoseQty
			}
			;取最大的单日剂量
			s:OneBaseDoseQtyPerDay>BaseDoseQtyPerDay BaseDoseQtyPerDay=OneBaseDoseQtyPerDay
		}
		s BaseDoseQty=MaxDoseQty
	}
	if (BaseDoseQty'="")&&(BaseDoseQty'=0){
		;极限用量
		s WarningUseQty=""
		s DHCARCIMRowid=$O(^DHCItmMast("0","ARCIM",ARCIMRowid,0))
		i DHCARCIMRowid'="" s WarningUseQty=$p($G(^DHCItmMast(DHCARCIMRowid)),"^",12)
		if (WarningUseQty'="")&&(WarningUseQty'=0){
			if (BaseDoseQty > WarningUseQty) {
				s WarningUseQty=$fn(WarningUseQty,"N")
                s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp","超过药品的极限用量限定:")_WarningUseQty_""_BaseUOMDesc
                s $P(OutInfo,"^",4)="OrderDoseQty"
                q OutInfo
            }
		}
		;一天总剂量	ARCIM_MaxQtyPerDay
		s MaxDoseQtyPerDay=$p($g(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),9)),"^",37)
		if (MaxDoseQtyPerDay'="")&&(MaxDoseQtyPerDay'=0) {
            if ((BaseDoseQtyPerDay > MaxDoseQtyPerDay)) {
	            s MaxDoseQtyPerDay=$fn(MaxDoseQtyPerDay,"N")
                s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp","超过药品1天内的最大剂量限定:")_MaxDoseQtyPerDay_BaseUOMDesc
                s $P(OutInfo,"^",4)="OrderFreq"
                q OutInfo
            }
        }
        
        ;最大量
		s MaxDoseQtyPerOrder=$p($g(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),9)),"^",38)
		if (MaxDoseQtyPerOrder'="")&&(MaxDoseQtyPerOrder'=0) {
            if (OrderFreqTimeDoseStr="") s BaseDoseQtyPerOrder = BaseDoseQty * FreqFactor * FormDurFactor
            else  s BaseDoseQtyPerOrder=BaseDoseQtyPerDay * FormDurFactor
            if ((BaseDoseQtyPerOrder > MaxDoseQtyPerOrder)) {
	            s MaxDoseQtyPerOrder=$fn(MaxDoseQtyPerOrder,"N")
                s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp","超过药品最大量限定")_MaxDoseQtyPerOrder_BaseUOMDesc
            	s $P(OutInfo,"^",4)="OrderDur"
                q OutInfo
            }
        }
        ;单次最大基本剂量	ARCIM_MaxCumDose
		s MaxDoseQty=$p($g(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),9)),"^",30)
		if (MaxDoseQty'="")&&(MaxDoseQty'=0){
			if (BaseDoseQty > MaxDoseQty) {
				s MaxDoseQty=$fn(MaxDoseQty,"N")
				s CallBackFunParams=OrderName_..%Translate("oeorder.oplistcustom.new.csp","超过药品的最大单次剂量限定:")_MaxDoseQty_""_BaseUOMDesc_..%Translate("oeorder.oplistcustom.new.csp",",是否继续审核")
				s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
				/*
                s OutInfo="-1^"_OrderName_"超过药品的最大单次剂量限定:"_MaxDoseQty_""_BaseUOMDesc
                s $P(OutInfo,"^",4)="OrderDoseQty"
                q OutInfo
                */
            }
		}
        ;限制疗程	ARCIM_NoOfCumDays
		s LimitDays=$p($g(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),9)),"^",31)
		if (LimitDays'="")&&(LimitDays'=0) {
            if ((FormDurFactor > LimitDays) && (DepProcNotes ="")) {
	            if (CelerType="Y"){
					s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 超过疗程限制用药，请维护备注说明！")
					q OutInfo
				}else{
					//s OutInfo="1^^^^"
                	s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"AddRemarkClickhandler",OrdRowIndex)
                	//q OutInfo
				}
            }
        }
	}
	;药品用量控制结束================
	/*if (PAADMType'="I"){
		;按用法分处方
 		s PrescByInstr=..%GetConfig("PrescByInstr")
 		if (PrescByInstr="1"){
	 		s InstrGroupCode=##Class(web.DHCDocOrderCommon).GetInstrGroupCode(InstrRowid)
	 		s PrescName = PHPrescType_"#"_AdmReason_"#"_InstrGroupCode_"#"_InstrRowid
	 		s FindPresc = 0
	 		s Index=0
	 		for {
		 		s Index=$O(OrderInstrGroupArr(Index))
		 		q:(Index="")
		 		s LoopData=$G(OrderInstrGroupArr(Index))
		 		s LoopPrescName=$P(LoopData,"!",1)
		 		if (LoopPrescName=PrescName){
			 		s $P(OrderInstrGroupArr(Index),"!",2)=$P(OrderInstrGroupArr(Index),"!",2)+1
			 		s FindPresc = 1
			 		q
			 	}
		 	}
	 		if (FindPresc = 0){
		 		s Index=$O(OrderInstrGroupArr(""),-1)+1
		 		s OrderInstrGroupArr(Index) = PrescName_"!" _1
		 	}
	 	}
	}*/
	
	s OrderFreqDispTimeStr=..GetOrderFreqDispTimeStr(FreqRowid,OrderFreqDispTimeStr,OrderFreqFreeTimeStr)
	s UsableDays =##Class(web.DHCDocOrderEntry).CalcDurByArcim(ARCIMRowid, FreqRowid, DurRowid, PackQty, DoseQty, DoseUOMRowid, OrderPackUOMRowid,OrderFreqDispTimeStr,OrderFreqTimeDoseStr)
	if (UsableDays = "") s UsableDays = 0
	;医保标识
	s InsurFlag=##Class(web.DHCDocOrderCommon).GetInsurFlag(AdmReason, PAADMType)
    if ((InsurFlag = 1) && (UsableDays > 200)) {
 		s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp","药品实际可用天数大于200天，医保不予支付，请您改开小包装或检查药品使用频次、单次用量。")
    	s $P(OutInfo,"^",4)="OrderName"
        q OutInfo
    }
	q "0^^^^"
}

ClassMethod CheckNotDrugUpdate(Adm As %String, OrdItem As %String, ByRef CallBackFunStr As %String, OrdItemStr As %String = "", OrdRowIndex As %String = "") As %String
{
	n (Adm,OrdItem,CallBackFunStr,%session,OrdItemStr,OrdRowIndex)
	s AdmHospitalId=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(Adm)
	s PAADMType=$p($g(^PAADM(Adm)),"^",2)
	s PAADMInsType=$P(^PAADM(Adm,1),"^",7)
	s ARCIMRowid=$P(OrdItem,"^",1)
	s OrderType=$P(OrdItem,"^",2)
	s PriorRowid=$p(OrdItem,"^",3)
	Set OrderPrice=$p(OrdItem,"^",7)
	Set DoseQty=$p(OrdItem,"^",12)
	Set FreqRowid=$p(OrdItem,"^",15)
	Set DurRowid=$p(OrdItem,"^",16)
	Set InstrRowid=$p(OrdItem,"^",17)
	Set OrderLabSpecRowid=$p(OrdItem,"^",28)
	Set VerifiedOrderMasterRowid=$p(OrdItem,"^",39)
	Set OEORIBindSource=$p(OrdItem,"^",58) //医嘱绑定来源
	Set OrderNurseBatchAdd=$p(OrdItem,"^",71) //护士批量补录标志
	set OrderDHCAADr=$p(OrdItem,"^",60)
	s OrderName=..GetChckOrdItemName(OrdItem,OrdItemStr) ;$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",2)
	s PriorCode=$p($g(^OECPR(PriorRowid)),"^",1)
	if (PriorCode="OM")||(PriorCode="OMST") {
        s OutInfo="-1^"_OrderName_"不允许开成自备药医嘱。"
    	s $P(OutInfo,"^",4)="OrderName"
        q OutInfo
    }
    ;外用用法
	s WYInstr=..%GetConfig("WYInstr",AdmHospitalId)
    s ISLongOrderPrior=##class(appcom.OEOrdItem).ISLongOrderPrior(PriorRowid)
    s ItemCatRowid=$p($g(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1)),"^",10)
    s IsHourItem=##Class(web.DHCDocOrderCommon).IsHourItem(ARCIMRowid)
    s FreqItemCat=..%GetConfig("FrequencedItemCat",AdmHospitalId)
    
    s findNoFreqDCAFlag="",MainDCARowID=""
    ;DCARowID:ChildDCA & MainDCA
	;		  ChildDCA ChildDCA#AssScaleID 包含当前(绑定关联的)医嘱的治疗申请ID(DCARowID)#治疗评定申请ID
	; 	      MainDCA  MainDCA#AssScaleID  被关联的治疗申请ID(MainDCARowID,绑定的医嘱可能不会生成治疗申请)#治疗评定申请ID
	if OrderDHCAADr'=""{
		s MainDCARowID=$p(OrderDHCAADr,"&",2)
		if MainDCARowID'=""{
			Set OEORIBindSource="CA"
			Set myOrdItemCount=$L(OrdItemStr,$c(1))
			for loop=1:1:myOrdItemCount {
				s aOrdItem=$p(OrdItemStr,$c(1),loop)
				continue:aOrdItem=""
				s aARCIMRowid=$p(aOrdItem,"^",1)
				continue:aARCIMRowid=""	
				set aOrderDHCAADr=$p(aOrdItem,"^",60)
				if (aOrderDHCAADr=MainDCARowID){
					s aItemCatRowid=$p($g(^ARCIM(+aARCIMRowid,$p(aARCIMRowid,"||",2),1)),"^",10)	
					if ("^"_FreqItemCat_"^"'[("^"_aItemCatRowid_"^")){
						s findNoFreqDCAFlag=1
					}
					Q
				}
			}
		}
	}
	if ("^"_FreqItemCat_"^"[("^"_ItemCatRowid_"^"))&&(IsHourItem'="1")&&(OrderNurseBatchAdd'="Y")&&(VerifiedOrderMasterRowid="")&&(OEORIBindSource=""){ //&&(FreqRowid="")		
		if findNoFreqDCAFlag=""{
			if (FreqRowid="") {
				s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 没有录入频次!")
				s $P(OutInfo,"^",4)="OrderFreq"
				q OutInfo
			}
			if (DurRowid="")&&(ISLongOrderPrior'=1)&&(("^"_WYInstr_"^")'[("^"_InstrRowid_"^")){
				s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 没有录入疗程!")
				s $P(OutInfo,"^",4)="OrderDur"
				q OutInfo
			}
		}
	}
	
	if (PAADMType'="I")&&(OEORIBindSource="")&&(DoseQty=""){
		s FreqCode=""
		s:FreqRowid'="" FreqCode=$ZCVT($P($G(^PHCFR(FreqRowid)),"^",1),"U")
		s OPGenOneExecCat="^"_..%GetConfig("OPGenOneExecCat",AdmHospitalId)_"^"
		s FreqItemCat="^"_..%GetConfig("FrequencedItemCat",AdmHospitalId)_"^"
		s OrderItemCatRowid=$p($g(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1)),"^",10)
		if (OPGenOneExecCat'[("^"_ItemCatRowid_"^"))&&((OrderType="R")||(FreqItemCat[("^"_OrderItemCatRowid_"^")))&&("   ONCE ST "'[(" "_FreqCode_" ")){
			s OutInfo="-1^" _ OrderName _ ..%Translate("oeorder.oplistcustom.new.csp"," 为多频次医嘱,需录入单次数量")
			s $P(OutInfo,"^",4)="OrderDoseQty"
			q OutInfo
		}
	}
	
    s CheckValue = "^(?!(0[0-9]{0,}$))[0-9]{1,}[.]{0,}[0-9]{0,}$"
    if (OrderType="P"){
		if (OrderPrice=""){
			s OutInfo="-1^^^"
			s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"NeedInputOrderPrice","",OrdRowIndex)
        	q OutInfo
		}elseif (('$MATCH(OrderPrice,CheckValue)) || (+OrderPrice = 0)) {
			s OutInfo="-1^自定义价格的医嘱【" _ OrderName _ "】价格不是有效数字"
			s $P(OutInfo,"^",4)="OrderPrice"
			s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"SetPageLogicFocusRow","",OrdRowIndex)
			q OutInfo
		}
	}
	 //检验医嘱
    if (OrderType = "L") {
	    if (OrderLabSpecRowid=""){
		    s OutInfo="-1^" _ OrderName _ "需要选择标本"
			s $P(OutInfo,"^",4)="OrderPrice"
			q OutInfo
	    }
    }
    
    q "0^^^^"
}

ClassMethod CheckStockUpdate(Adm As %String, LogonLoc As %String, OrdItem As %String, ByRef CallBackFunStr As %String, OrdItemStr As %String = "", OrderOpenForAllHosp As %String = 0) As %String
{
	n (Adm,LogonLoc,OrdItem,CallBackFunStr,OrdItemStr,OrderOpenForAllHosp,%session)
	s HospID=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(Adm)
	Set langid=..%LanguageID()
	s PAADMType=$p($g(^PAADM(Adm)),"^",2)
	s PAADMInsType=$P(^PAADM(Adm,1),"^",7)
	s ARCIMRowid=$P(OrdItem,"^",1)
	s OrderType=$P(OrdItem,"^",2)
	s PriorRowid=$p(OrdItem,"^",3)
	Set OrdStartDate=$p(OrdItem,"^",4)
	Set OrdStartTime=$p(OrdItem,"^",5)
	Set RecDepRowid=$p(OrdItem,"^",8)
	Set InstrRowId=$p(OrdItem,"^",17)
	Set FirstDayTimes=$p(OrdItem,"^",33)
	Set PYFlag=$p(OrdItem,"^",48)
	Set:PYFlag="" PYFlag="N"
	Set OrderPkgOrderNo=$p(OrdItem,"^",74)
	set ImportByContingences=$p(OrdItem,"^",75)
	Set OnePriorRowid=+$O(^OECPR(0,"Code","ONE",0))
	s OrderName=..GetChckOrdItemName(OrdItem,OrdItemStr) //$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",2)
	s PriorCode=$S(PriorRowid'="":$p($g(^OECPR(PriorRowid)),"^",1),1:"")
	if (PriorCode["OM")||(PriorCode["ZT") {
		q "0^^^^"
	}
	s ArcimBillUOMRowid=$p($g(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),8)),"^",14)
	s OrderItemCatRowid=$p($g(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1)),"^",10)
	s OrderRecDep=$P(^CTLOC(RecDepRowid),"^",2)
	s OrderRecDep=##class(User.CTLoc).GetTranByDesc("CTLOCDesc",OrderRecDep,langid)
	s OrderDrugFormRowid=##class(web.DHCDocOrderEntry).GetDrgForm(ARCIMRowid)
	s INCIRowid=##class(web.DHCDocOrderEntry).GetINCI(+ARCIMRowid)
	;可以录入小数的子类
    s AllowEntryDecimalItemCat=##Class(web.DHCDocOrderCommon).GetAllowEntryDecimalItemCat(Adm,HospID)
	s IsAllowEntryDecimalItemCat="N"
	if (("^"_AllowEntryDecimalItemCat_"^")[("^"_OrderItemCatRowid_"^")){
		s IsAllowEntryDecimalItemCat="Y"
	}
	k PkgOrderArr
	s QtySum=0
	for i=1:1:$length(OrdItemStr,$C(1)){
		s LoopOrdItem=$P(OrdItemStr,$C(1),i)
		s LoopOrderType=$P(LoopOrdItem,"^",2)
		s LoopPriorRowid=$p(LoopOrdItem,"^",3)
		s LoopPriorCode=$S(LoopPriorRowid'="":$p($g(^OECPR(LoopPriorRowid)),"^",1),1:"")
		if (LoopPriorCode["OM")||(LoopPriorCode["ZT") {
			continue
		}
		s LoopARCIMRowid=$P(LoopOrdItem,"^",1)
		
		/*if (LoopARCIMRowid'=ARCIMRowid)||(LoopRecDepRowid'=RecDepRowid){
			continue
		}*/
		s LoopOrderStartDate=$p(LoopOrdItem,"^",4)
		s LoopOrderStartTime=$p(LoopOrdItem,"^",5)
		Set LoopPackQty=$p(LoopOrdItem,"^",6)
		Set LoopRecDepRowid=$p(LoopOrdItem,"^",8)
		Set LoopDoseQty=$p(LoopOrdItem,"^",12)
		Set LoopDoseUOMRowid=$p(LoopOrdItem,"^",13)
		Set LoopDoseQtySum=$p(LoopOrdItem,"^",14)
		Set LoopFreqRowid=$p(LoopOrdItem,"^",15)
		
		s:LoopFreqRowid'="" LoopFreqFactor=$P($g(^PHCFR(LoopFreqRowid)),"^",2)
		Set LoopDurRowid=$p(LoopOrdItem,"^",16)
		Set LoopOrderDurFactor=1
		i LoopDurRowid'="" s LoopOrderDurFactor=$P($g(^PHCDU(LoopDurRowid)),"^",2)
		Set LoopFirstDayTimes=$p(LoopOrdItem,"^",33)
		Set LoopOrderPackUOMRowid=$p(LoopOrdItem,"^",55)
		Set LoopOrderFreqWeekStr=$p(LoopOrdItem,"^",67)
		Set LoopOrderPkgOrderNo=$p(LoopOrdItem,"^",74)
		Set LoopOrderFreqFreeTimeStr=$p(LoopOrdItem,"^",83)

		s LoopFreqFactor=1
		if (LoopFreqRowid'=""){
			s LoopFreqFactor=$P($g(^PHCFR(LoopFreqRowid)),"^",2)
			s LoopFreeTimeFreqFlag=$P(^PHCFR(LoopFreqRowid),"^",13)
			if (LoopFreeTimeFreqFlag="Y"){
				s LoopFreqFactor=$L(LoopOrderFreqFreeTimeStr,"|")
			}
		}
		s BaseDoseQty=##Class(web.DHCDocOrderEntry).CalEqDose(LoopDoseUOMRowid,OrderDrugFormRowid,LoopDoseQty,"BaseUom")
		s ConFac=1
		if (INCIRowid'="")&&(LoopOrderPackUOMRowid'="")  d
		.s ConFac=##class(web.DHCDocOrderEntry).GetConFac(ARCIMRowid,INCIRowid,LoopOrderPackUOMRowid)
        if (BaseDoseQty="") {s BaseDoseQty=1}
       
		//
		s LoopDate=..%ZDH(LoopOrderStartDate)
		s LoopTime=..%ZTH(LoopOrderStartTime)
		s LoopISLongOrderPrior=##class(appcom.OEOrdItem).ISLongOrderPrior(LoopPriorRowid)
		if (LoopISLongOrderPrior=1){
			s LoopOrderDurFactor=LoopOrderDurFactor+1
		}
		if ((LoopPackQty'="")&&(+LoopPackQty>0)){
			s QtySum=ConFac*LoopPackQty
		}else{
			s QtySum=BaseDoseQty*LoopFreqFactor
			if (QtySum<1)&&(IsAllowEntryDecimalItemCat="N") {s QtySum=1}
		}
		;修复不能录入单次剂量的非药品医嘱,库存始终按数量1判断，导致可以开超过库存数的医嘱
		if (LoopDoseQty="")&&(LoopDoseQtySum'="")&&(LoopOrderType'="R") {
			s QtySum=LoopDoseQtySum
			if (QtySum<1)&&(IsAllowEntryDecimalItemCat="N") {s QtySum=1}
		}
		if (LoopARCIMRowid=ARCIMRowid)&&(LoopRecDepRowid=RecDepRowid){
			//1.如果有静配自动切换药房的数据，则遍历两天的执行记录去分别累计两个接受科室的总数量
			//，如果没有静配切换药房，则统计满整天情况下接受科室的总数量
			k ExecList
			d ##class(DHCDoc.Order.Exec).GetExecTime(.ExecList,LoopFreqRowid,LoopOrderDurFactor,LoopDate,LoopTime,LoopFirstDayTimes,LoopOrderFreqWeekStr,LoopOrderFreqFreeTimeStr,HospID,LoopARCIMRowid,LoopPriorRowid)
			s LoopTimeRecLocId=""
			if $D(ExecList) {
				s LoopDate=$O(ExecList(""))
				s LoopTime=$O(ExecList(LoopDate,""))
				s LoopTimeRecLocId=##class(appcom.OEDispensing).GetFirstDaySetting(Adm,LoopARCIMRowid,LoopRecDepRowid,LoopDate,LoopTime,.PYFlag)
			}
			
			//1.1,判断当日第一条执行记录会不会有静配接受科室切换
			if (LoopISLongOrderPrior=1)&&(LoopTimeRecLocId'=""){
				s LoopDate=0
				for {
					s LoopDate=$O(ExecList(LoopDate))
					q:(LoopDate="")
					s LoopTime=""
					for {
						s LoopTime=$O(ExecList(LoopDate,LoopTime))
						q:(LoopTime="")
						s LoopTimeRecLocId=##class(appcom.OEDispensing).GetFirstDaySetting(Adm,LoopARCIMRowid,LoopRecDepRowid,LoopDate,LoopTime,.PYFlag)
						if (LoopTimeRecLocId=""){
							s LoopTimeRecLocId=LoopRecDepRowid
						}
						if ((LoopPackQty'="")&&(+LoopPackQty>0)){
							s Qty=ConFac*LoopPackQty
						}else{
							s Qty=BaseDoseQty
						}
						s OrdQtyArr(LoopARCIMRowid,LoopTimeRecLocId,"QtySum")=$G(OrdQtyArr(LoopARCIMRowid,LoopTimeRecLocId,"QtySum"))+Qty
					}
				}
			}else{
				//1.2,不需要做接受科室转移的直接累计一日数量去判断即可
				s OrdQtyArr(LoopARCIMRowid,LoopRecDepRowid,"QtySum")=$G(OrdQtyArr(LoopARCIMRowid,LoopRecDepRowid,"QtySum"))+QtySum
			}
		}
		if (OrderPkgOrderNo'="")&&(OrderPkgOrderNo=LoopOrderPkgOrderNo){
			s PkgOrderArr(OrderPkgOrderNo)=$G(PkgOrderArr(OrderPkgOrderNo))+QtySum
		}
	}
	s ExpStr=Adm_"^"_LogonLoc_"^0^"_InstrRowId_"^"_$case(OrderOpenForAllHosp,"on":1,"Y":1,:0)_"^"_PriorRowid_"^"_OrdStartDate_"^"_ImportByContingences
	;可以提示给用户的最小库存数量
	s OrderAlertStockQty=##Class(web.DHCDocOrderCommon).GetARCIMAlertStockQty(ARCIMRowid)
	s LoopRecDepRowid="",Msg="",FocusCol=""
	for {
		s LoopRecDepRowid=$O(OrdQtyArr(ARCIMRowid,LoopRecDepRowid))
		q:(LoopRecDepRowid="")
		s QtySum=$G(OrdQtyArr(ARCIMRowid,LoopRecDepRowid,"QtySum"))
		s ret = ##Class(web.DHCDocOrderCommon).CheckBeforeUpdate(ARCIMRowid, QtySum, LoopRecDepRowid,PAADMType,ExpStr)
		s Check = $P(ret, "^", 1)
		if (Check>0){continue}
		if (LoopRecDepRowid'=RecDepRowid){				///配液替值科室不需要校验绑定的项目
			if (Check=-2)||(Check=-3){continue}
		}
		if (Msg'="") s Msg=Msg_";"
		s RecLocdesc=$p(^CTLOC(LoopRecDepRowid),"^",2)
		s RecLocdesc=##class(User.CTLoc).GetTranByDesc("CTLOCDesc",RecLocdesc,langid)
		if (LoopRecDepRowid'=RecDepRowid){
			s Msg=Msg_OrderName _..%Translate("oeorder.oplistcustom.new.csp","配液首日接收科室")_"【"_RecLocdesc_"】"
		}else{
			s Msg=Msg_OrderName _" "_OrderRecDep 
		}
		if (Check = "0") {
			//根据设定的最小量来判断是否需要提示库存量
			if ((OrderAlertStockQty '= "") && (OrderAlertStockQty '=0) && (PAADMType = "O")) {
				s StockQtyStr = ##Class(web.DHCDocOrderCommon).GetStockQty( LoopRecDepRowid, ARCIMRowid)
				s StockQty = $P(StockQtyStr, "^", 1)
				s PackedQty = $P(StockQtyStr, "^", 2)
				s LogicQty = StockQty - PackedQty
				if (OrderAlertStockQty > LogicQty) {
					s Msg=Msg_..%Translate("oeorder.oplistcustom.new.csp","库存不足,库存量为:")_LogicQty
					s FocusCol="OrderPackQty"
					continue
				}
			}
			s Msg=Msg_..%Translate("oeorder.oplistcustom.new.csp","库存不足")
			s FocusCol="OrderPackQty"
		} elseif (Check = "-1") {
			s Msg=Msg_..%Translate("oeorder.oplistcustom.new.csp","被锁定，如需要请联系药房工作人员")
			s FocusCol="OrderRecDep"
		}elseif (Check = "-2"){
			s Msg=Msg_..%Translate("oeorder.oplistcustom.new.csp","通过医嘱或子类或用法绑定的")_$P(ret, "^", 2)_..%Translate("oeorder.oplistcustom.new.csp","被锁定，如需要请联系药房工作人员!")
			s FocusCol="OrderRecDep"
		}elseif (Check = "-3") {
			s Msg=Msg_..%Translate("oeorder.oplistcustom.new.csp","通过医嘱或子类或用法绑定的")_$P(ret, "^", 2)_..%Translate("oeorder.oplistcustom.new.csp","库存不足")
			s FocusCol="OrderRecDep"
		}	
	}
	if (Msg'=""){
		s OutInfo="-1^" _Msg
		s $P(OutInfo,"^",4)=FocusCol
		q OutInfo
    }	
	s OutInfo="0^^^"
    //s convFac=##class(appcom.OEDispensing).convFac(ARCIMRowid,ArcimBillUOMRowid)
    s OrderPkgOrderNo=""
    for {
		s OrderPkgOrderNo=$O(PkgOrderArr(OrderPkgOrderNo))
		q:(OrderPkgOrderNo="")
		s QtySum=$G(PkgOrderArr(OrderPkgOrderNo))
		//s BillQty=$FN(QtySum/convFac,"",2)
		s ret=##class(BILL.PKG.SRV.Interface).ICheckPkgOrdRemain(OrderPkgOrderNo,QtySum)
		if (+ret=0){
			s OutInfo="-1^" _OrderName _..%Translate("oeorder.oplistcustom.new.csp","患者购买套餐数量不足,当前套餐剩余")_$P(ret,"^",2)_..%Translate("oeorder.oplistcustom.new.csp",",请单独开立套餐内医嘱")_OrderPkgOrderNo_","_QtySum
			s $P(OutInfo,"^",4)="OrderPackQty"
			q
		}
		
	}	
	q OutInfo
}

ClassMethod CheckPackQtyUpdate(Adm As %String, OrdItem As %String, CheckExpStr As %String, OrdItemStr As %String, ByRef CallBackFunStr As %String, OrdRowIndex As %String) As %String
{
	n (Adm,OrdItem,CheckExpStr,CallBackFunStr,OrdItemStr,OrdRowIndex,%session)
	s CurLogonDep=$P(CheckExpStr,"^",1)
	s CurLogonHosp =$p(^CTLOC(CurLogonDep),"^",22)
	s PAADMType=$p($g(^PAADM(Adm)),"^",2)
	s PAADMInsType=$P(^PAADM(Adm,1),"^",7)
	s VisitStatus=$p($g(^PAADM(Adm)),"^",20)
	s ARCIMRowid=$P(OrdItem,"^",1)
	s OrderType=$P(OrdItem,"^",2)
	s PriorRowid=$p(OrdItem,"^",3)
	Set startdate=$p(OrdItem,"^",4)
    Set starttime=$p(OrdItem,"^",5)
	Set PackQty=$p(OrdItem,"^",6)
	Set oeprice=$p(OrdItem,"^",7)
	Set RecDepRowid=$p(OrdItem,"^",8)
	Set DoseQtySum=$p(OrdItem,"^",14)
	Set InstrRowid=$p(OrdItem,"^",17)
	Set OrderNeedPIVAFlag=$p(OrdItem,"^",48)
	Set OrderPackUOMRowid=$p(OrdItem,"^",55)
	s OrderPackUOM=##Class(web.DHCDocOrderCommon).GetUOMDesc(OrderPackUOMRowid)
	if (OrderType'="R"){
		s PackQty=DoseQtySum
	}
	Set langid=..%LanguageID()
	s AdmDepDr=$p($g(^PAADM(Adm)),"^",4)
	s AdmDepHospId=$p(^CTLOC(AdmDepDr),"^",22)

	s INCIRowid=##class(web.DHCDocOrderEntry).GetINCI(+ARCIMRowid)
	///住院发整包装
    s IPNeedBillQtyFlag=##Class(PHA.FACE.OUT.Com).GetIncilInPhUom(RecDepRowid, INCIRowid).inPhPack
    s IPNeedBillQtyFlag=$CASE(IPNeedBillQtyFlag,"Y":1,:"0")
	;取药和出院带药默认按整包装开
	s CFOutAndOneDefaultPackQty=##Class(PHA.FACE.OUT.Com).GetIncilInPhUom(RecDepRowid, INCIRowid).outPhPack	//取药、出院带药可以发基本单位
    s CFOutAndOneDefaultPackQty=$CASE(CFOutAndOneDefaultPackQty,"":..%GetConfig("OutAndOneDefaultPackQty",AdmDepHospId),"N":1,"Y":0,:1)
	
	s OrderVirtualtLong=$p(OrdItem,"^",79)
	s ItemCatRowid=$p($g(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1)),"^",10)
	s OrderName=$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",2)
	s OrderName=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",OrderName,langid)
	s PriorCode=$p($g(^OECPR(PriorRowid)),"^",1)
	s OutInfo="0^^^"
	;出院带药必须录入整包装---该配置已删除
 	//s OutOrderNeedPackQty=..%GetConfig("OutOrderNeedPackQty",CurLogonHosp)
 	;住院是否需要录入整包装数量 
	s IPNeedBillQty=##Class(web.DHCDocOrderCommon).GetARCIMIPNeedBillQty(ARCIMRowid)
	if (OrderNeedPIVAFlag="Y"){
		s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"EmptyPackQty","",OrdRowIndex)
		q "0^^^"
	}
	 ;医生站设置-药房设置-临时医嘱拆分整包装发药(仅在急诊留观押金的虚拟长期模式下有效)
    s NormSplitPackQty=##Class(web.DHCDocOrderVirtualLong).GetNormSplitPackQtyFlag(Adm,RecDepRowid,ItemCatRowid)
	s CheckValue = "^(?!(0[0-9]{0,}$))[0-9]{1,}[.]{0,}[0-9]{0,}$"
	//('$MATCH(OrderDoseQty,CheckValue)
	;可以录入小数的子类
	s AllowEntryDecimalItemCat=##Class(web.DHCDocOrderCommon).GetAllowEntryDecimalItemCat(Adm,CurLogonHosp)
	if ("^"_AllowEntryDecimalItemCat_"^")'[("^"_ItemCatRowid_"^"){
		if (PackQty'="")&&((PackQty=0)||((PackQty#1)>0)){
			s OutInfo="-1^" _OrderName _..%Translate("oeorder.oplistcustom.new.csp","的数量不是有效数字,请检查")
			s $P(OutInfo,"^",4)="OrderPackQty"
			q OutInfo
		}
		if (OrderType'="R"){
			//医嘱项扩展设定->检查检验不控制数量
			s NotLimitQty=..GetItemNotLimitQtyFlag(ARCIMRowid)
			if ((OrderType = "L") && (PackQty'= 1)&&(NotLimitQty'="Y")) {
				s OutInfo="-1^" _OrderName _..%Translate("oeorder.oplistcustom.new.csp"," 检验医嘱数量只能为1,请确认.")
				s $P(OutInfo,"^",4)="OrderPackQty"
				q OutInfo
			}
			; 得到是否是或者有检查医嘱标识
 			s ItemServiceFlag=##Class(web.DHCDocOrderCommon).GetItemServiceFlag(ARCIMRowid)
 			if (ItemServiceFlag=1)&&(PackQty'=1)&&(NotLimitQty'="Y"){
	 			s OutInfo="-1^" _OrderName _..%Translate("oeorder.oplistcustom.new.csp"," 检查医嘱数量只能为1,请确认.")
				s $P(OutInfo,"^",4)="OrderPackQty"
				q OutInfo
	 		}
		}
	}
	if (PackQty'="")&&((+PackQty<=0)||('$MATCH(PackQty,CheckValue))){
		s OutInfo="-1^" _OrderName _..%Translate("oeorder.oplistcustom.new.csp","的数量不是有效数字,请检查")
		s $P(OutInfo,"^",4)="OrderPackQty"
		q OutInfo
	}
	if (PAADMType="I"){
		if (+PackQty=0){
			if ((PriorCode="OUT")||(PriorCode="ONE")){
				if (CFOutAndOneDefaultPackQty="1")||(IPNeedBillQty="Y"){
					s OutInfo="-1^" _OrderName _..%Translate("oeorder.oplistcustom.new.csp","没有录入整数量")
					s $P(OutInfo,"^",4)="OrderPackQty"
					q OutInfo
				}
			}elseif (PriorCode'["OM"){
					if ((IPNeedBillQty="Y")||(IPNeedBillQtyFlag = "1"))
						&&('##class(appcom.OEOrdItem).ISLongOrderPrior(PriorRowid)){
					s OutInfo="-1^" _OrderName _..%Translate("oeorder.oplistcustom.new.csp","没有录入整数量")
					s $P(OutInfo,"^",4)="OrderPackQty"
					q OutInfo	
				}	
			}

			if (VisitStatus="P"){
				s OutInfo="-1^" _OrderName _..%Translate("oeorder.oplistcustom.new.csp","没有录入整数量")
				s $P(OutInfo,"^",4)="OrderPackQty"
				q OutInfo
			}
		}
	}else{
		 if (+PackQty = 0)&&(NormSplitPackQty'=1)&&(PriorCode'["OM")&&(OrderVirtualtLong'="Y") {
            s OutInfo="-1^" _OrderName _..%Translate("oeorder.oplistcustom.new.csp","没有录入整数量")
			s $P(OutInfo,"^",4)="OrderPackQty"
			q OutInfo
        }
	}
	//控制医嘱数量不能超过1000,避免录入错误导致不能账单的问题
	s NotLimitQty=..GetItemNotLimitQtyFlag(ARCIMRowid)
    if (PackQty > 9999)&&(NotLimitQty'="Y") {
        s OutInfo="-1^" _OrderName _..%Translate("oeorder.oplistcustom.new.csp","医嘱数量不能超过9999。请修改！")
		s $P(OutInfo,"^",4)="OrderPackQty"
		q OutInfo
    }
	//门急诊皮试结果阴性后提醒是否做治疗用药，点击时则整包装数量-1
    d CalTreatOrdPackQty

	q OutInfo
CalTreatOrdPackQty
	
    s OrderRowid=$o(^OEORD(0,"Adm",+Adm,""))
    ;皮试用法
    s SkinTestInstr=##Class(web.DHCDocConfig).GetConfigNode("SkinTestInstr",CurLogonHosp)
    if (PAADMType="I"){
        q
    }
    if (SkinTestInstr'="")&&(("^"_SkinTestInstr_"^")[("^"_InstrRowid_"^")){
        q
    }
	if (OrderType'="R"){
		q
	}
    s NeedCalFlag="N"
    //是否配置为需皮试医嘱
    s rs=##class(PHA.FACE.OUT.Com).GetSkinTestInfo(ARCIMRowid,CurLogonHosp)
    if (rs.Next(.sc)){
        s NeedCalFlag="Y"
    }
    //q:(NeedCalFlag="N")   除了维护的皮试药品，其他勾选的皮试  再开的治疗也要判断
	//初始化该医嘱对应的皮试医嘱项列表
    k AppendArcimList,SkinArcimList
    d ##Class(web.DHCOEOrderGuideAllergy).BuildAppendAllergyOrder(Adm,ARCIMRowid,startdate_" "_starttime,.AppendArcimList)
    s SkinArcimList(ARCIMRowid)=""
    s LinkseqNo=""
    for {
        s LinkseqNo=$O(AppendArcimList("All",LinkseqNo))
        q:(LinkseqNo="")
        s AppendItemStr=$G(AppendArcimList("All",LinkseqNo))
        s SkinArcim=$P(AppendItemStr,"^",1)
        s resultFlag=$P(AppendItemStr,"^",7)
        if (resultFlag="Y"){
            s SkinArcimList(SkinArcim)=""
        }
        s Index=0
        for {
            s Index=$O(RelatedArcimList("All",LinkseqNo,"Sub",Index))
            q:(Index="")
            s AppendItemStr=$G(RelatedArcimList("All",LinkseqNo,"Sub",Index))
            s SkinArcim=$P(AppendItemStr,"^",1)
            s resultFlag=$P(AppendItemStr,"^",8)
            if (resultFlag="Y"){
                s SkinArcimList(SkinArcim)=""
            }
        }
    }
    if '$D(SkinArcimList){
        q
    }
    s FindSkinOrd="N"
    //找待审核列表中是否存在对应的皮试医嘱
    Set OrdItemCount=$L(OrdItemStr,$c(1))
    for i=1:1:OrdItemCount {
        s LoopOrdItem=$p(OrdItemStr,$c(1),i)
        continue:LoopOrdItem=""
        s LoopARCIMRowid=$p(LoopOrdItem,"^",1)
        continue:LoopARCIMRowid=""
        continue:'$D(SkinArcimList(LoopARCIMRowid))
        Set LoopInstrRowid=$p(LoopOrdItem,"^",17)
		
        if (SkinTestInstr'="")&&(("^"_SkinTestInstr_"^")'[("^"_LoopInstrRowid_"^")){
            continue
        }
        s FindSkinOrd="Y"
        quit
        
    }
	//找已审核列表中是否存在对应的皮试医嘱
    s SkinControlInfo=##Class(web.DHCOEOrderGuideAllergy).GetArcimSkinControlInfo(ARCIMRowid,startdate,CurLogonHosp)
    Kill TableArr
    d ##Class(web.DHCOEOrderGuideAllergy).BuildSkinOrdList(Adm,ARCIMRowid,startdate_" "_starttime,SkinControlInfo,.TableArr)
    if ($D(TableArr("SkinList"))){
        s FindSkinOrd="Y"
    }
    q:(FindSkinOrd="N")
    
    k OrdParamArr
    s OrdParamArr("EpisodeID")=Adm
    s OrdParamArr("OrderPriorRowid")=PriorRowid
    s OrdParamArr("OrderARCIMRowid")=ARCIMRowid
    s OrdParamArr("OrderDoseQty")=$p(OrdItem,"^",12)
    s OrdParamArr("OrderDoseUOMRowid")=$p(OrdItem,"^",13)
    s OrdParamArr("OrderFreqRowid")=$p(OrdItem,"^",15)
    s OrdParamArr("OrderDurRowid")=$p(OrdItem,"^",16)
    
    s OrdParamArr("OrderPackQty")=PackQty
    s OrdParamArr("OrderPackUOMRowid")=OrderPackUOMRowid
    s OrdParamArr("OrderStartDate")=$p(OrdItem,"^",4)_" "_$p(OrdItem,"^",5)
    s OrdParamArr("OrderMultiDate")=""
    s OrdParamArr("OrderPrice")=""
    s OrdParamArr("LinkedMasterOrderPriorRowid")=""
    Set OrderFreqWeekStr=$p(OrdItem,"^",67)
    s OrdParamArr("OrderFreqDispTimeStr")=..GetOrderFreqDispTimeStr(OrdParamArr("OrderFreqRowid"),OrderFreqWeekStr)
    s OrdParamArr("OrderFirstDayTimes")=$p(OrdItem,"^",33)
    s OrdParamArr("IsNotChangeFirstDayTimeFlag")="Y"
    s OrdParamArr("IsNotNeedChangeFlag")=""
    s OrdParamArr("OrderFreqTimeDoseStr")=##class(web.DHCDocUtil).Replace($p(OrdItem,"^",70),"_","||")
    
    s OrdParamArr("OrderRecDepRowid")=$p(OrdItem,"^",8)
    s SessionStr="^^"_CurLogonDep_"^"_CurLogonHosp
    
    s OrdParamArr("SessionStr")=SessionStr
    s OrdParamArr("OrderMasterARCIMRowid")=""
    s OrdParamArr("OrderVirtualtLong")="N"
    s OrdParamJson=##Class(DHCDoc.Util.FromJSON).GetArrJson(.OrdParamArr)
    s CalPackQtyJson=##Class(web.DHCOEOrdItemView).CalPackQty(OrdParamJson)
    d ##Class(DHCDoc.Util.FromJSON).FromJSONToArr(CalPackQtyJson,.CalPackQtyArr)
    s CalOrderPackQty=$G(CalPackQtyArr("OrderPackQty"))
    if (CalOrderPackQty>1)&&(CalOrderPackQty=PackQty){
		s OrderPackUOM=##class(User.CTUOM).GetTranByDesc("CTUOMDesc",OrderPackUOM,langid)
        s CallBackFunParams=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," ，检索到有效的皮试记录，皮试阴性后可代替治疗用药使用一次，是否将数量修改为：")_(CalOrderPackQty-1)_OrderPackUOM
		s OrderSum=oeprice * (CalOrderPackQty-1)
		s CallBackFunParams=CallBackFunParams_","_(CalOrderPackQty-1)_","_OrderSum
        s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"ReSetPackQty",CallBackFunParams,OrdRowIndex)
    }
    q
}

ClassMethod CheckDurationPackQty(Adm As %String, OrdItem As %String, OrdItemStr As %String, ExpStr As %String, ByRef CallBackFunStr As %String) As %String
{
	n (Adm,OrdItem,OrdItemStr,ExpStr,CallBackFunStr,%session)
	s LogonLocId=$p(ExpStr,"^",1)
	s LogonHospId=$p($g(^CTLOC(LogonLocId)),"^",22)
	s PAADMType=$p($g(^PAADM(Adm)),"^",2)
	s PAADMInsType=$P(^PAADM(Adm,1),"^",7)
	Set langid=..%LanguageID()
	s ARCIMRowid=$P(OrdItem,"^",1)
	s OrderType=$P(OrdItem,"^",2)
	s PriorRowid=$p(OrdItem,"^",3)
	Set PackQty=$p(OrdItem,"^",6)
	Set RecDepRowid=$p(OrdItem,"^",8)
	Set DoseQtySum=$p(OrdItem,"^",14)
	Set DurRowid=$p(OrdItem,"^",16)
	Set OrderNeedPIVAFlag=$p(OrdItem,"^",48)
	Set OrderPackUOMRowid=$p(OrdItem,"^",55)
	if (OrderPackUOMRowid="") {
		//s OrderPackUOMRowid=$p($g(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),8)),"^",14) //取医嘱计价单位
		s OrderPackUOMRowid=##Class(web.DHCDocOrderCommon).GetBillUOMRowID(ARCIMRowid,PAADMType)
	}
	if (OrderType'="R"){
		s PackQty=DoseQtySum
	}
	s OrderPackUOM=##Class(web.DHCDocOrderCommon).GetUOMDesc(OrderPackUOMRowid)
	s ItemCatRowid=$p($g(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1)),"^",10)
	s OrderName=..GetChckOrdItemName(OrdItem,OrdItemStr) //$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",2)
	s PriorCode=$p($g(^OECPR(PriorRowid)),"^",1)
	s PatientID=$p($g(^PAADM(Adm)),"^",1)
	Set MRAdm=$P(^PAADM(Adm),"^",61)
	s PatientSocialStausDR=$p($g(^PAPER(PatientID,"PER",1)),"^",10)
	i PatientSocialStausDR="" s PatientSocialStausDR=$O(^CT("SS",0))
	s OrderDurFactor=1
	i DurRowid'="" s OrderDurFactor=$P($g(^PHCDU(DurRowid)),"^",2)
	if (OrderNeedPIVAFlag="Y"){
		//q "0^^^"
	}
	s BaseUomStr=##Class(web.DHCDocOrderCommon).GetBaseUom(ARCIMRowid)
	s BaseUomDesc=$P(BaseUomStr,"^",2)
	;剂量最大值,诊断的最大疗程参数
	s MaxQty=##Class(web.DHCDocOrderEntry).GetARCIMMaxQty(ARCIMRowid)
	s convFac = ##Class(appcom.OEDispensing).convFac(ARCIMRowid,OrderPackUOMRowid)
	if ((MaxQty > 0) && ((PackQty*convFac) > MaxQty)) {
		s OutInfo="-1^" _OrderName _..%Translate("oeorder.oplistcustom.new.csp","此药品的最大限量为")_MaxQty_BaseUomDesc
		if (BaseUomDesc'=OrderPackUOM) {
			s OutInfo=OutInfo_","_$j((MaxQty/convFac),"",2)_OrderPackUOM
		}
		s $P(OutInfo,"^",4)="OrderPackQty"
		q OutInfo
	}
	if (PAADMType'="I"){
		s MaxDurFactor=##CLass(web.DHCDocOrderEntry).GetDiagnosLimitDurFactor(PatientSocialStausDR, MRAdm,LogonHospId)
		if (OrderDurFactor>MaxDurFactor)&&(MaxDurFactor'=0){
			s OutInfo="-1^" _OrderName _..%Translate("oeorder.oplistcustom.new.csp","超过当前诊断最大疗程限制：")_MaxDurFactor
			s $P(OutInfo,"^",4)="OrderDur"
			q OutInfo
		}
	
	}
	
	q "0^^^"
}

ClassMethod CheckDHCDocTreatItem(Adm As %String, OrdItem As %String, ByRef CallBackFunStr As %String) As %String
{
	n (Adm,OrdItem,CallBackFunStr)
	s ^tempscl("CheckDHCDocTreatItem")=Adm_","_OrdItem
	s PAADMType=$p($g(^PAADM(Adm)),"^",2)
	s PAADMInsType=$P(^PAADM(Adm,1),"^",7)
	s ARCIMRowid=$P(OrdItem,"^",1)
	s OrderType=$P(OrdItem,"^",2)
	s PriorRowid=$p(OrdItem,"^",3)
	Set PackQty=$p(OrdItem,"^",6)
	Set RecDepRowid=$p(OrdItem,"^",8)
	Set DoseQty=$p(OrdItem,"^",12)
	Set DoseQtySum=$p(OrdItem,"^",14)
	s FreqRowid=$p(OrdItem,"^",15)
	s STFreqRowid=$O(^PHCFR(0,"Desc1","ST",0))
	s ONCEFreqRowid=$O(^PHCFR(0,"Code","ONCE",0))
	if (OrderType'="R"){
		s PackQty=DoseQtySum
	}
	
	s OrderName=$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",2)
	s PriorCode=$p($g(^OECPR(PriorRowid)),"^",1)
	
    s CureItemFlag=##class(DHCDoc.DHCDocCure.Apply).CheckItem(ARCIMRowid,RecDepRowid)
	if (CureItemFlag '= "1"){
		q "0^^^"  
	}
    /*if (PriorCode="S")||(PriorCode="OMST") {
		s OutInfo="-1^" _OrderName _"为治疗项目,不能开长期医嘱"
		s $P(OutInfo,"^",4)="OrderName"
		q OutInfo
	}*/
	s LongOrderPriorRowid=$O(^OECPR(0,"Code","S",0))
	s OMSOrderPriorRowid=$O(^OECPR(0,"Code","OMST",0))
	s CheckValue = "^(?!(0[0-9]{0,}$))[0-9]{1,}[.]{0,}[0-9]{0,}$"
    if ((PriorRowid '= LongOrderPriorRowid) && (PriorRowid '= OMSOrderPriorRowid)) {
	    if (DoseQty'= "") {
	        ;s OutInfo="-1^" _OrderName _"不能填写单次数量"
			;s $P(OutInfo,"^",4)="OrderDoseQty"
			;q OutInfo
	    }
	    if (PackQty= "") {
	        s OutInfo="-1^" _OrderName _"为治疗项目,数量必须填写"
			s $P(OutInfo,"^",4)="OrderPackQty"
			q OutInfo
	    }elseif (('$MATCH(PackQty,CheckValue)) || ((+PackQty) <= 0)) {
			if ((FreqRowid'="")&&(FreqRowid'=STFreqRowid)&&(FreqRowid'=ONCEFreqRowid)){
				s OutInfo="-1^" _OrderName _ "为治疗项目,数量必须是正整数"
				s $P(OutInfo,"^",4)="OrderPackQty"
				q OutInfo
			}
	    }
    }
	q "0^^^"
}

// 

ClassMethod CheckOrdPriorAllow(Adm As %String, OrdItem As %String, Loc As %String, ByRef CallBackFunStr As %String) As %String
{
	n (Adm,OrdItem,Loc,CallBackFunStr,%session)
	s PAADMType=$p($g(^PAADM(Adm)),"^",2)
	s ARCIMRowid=$P(OrdItem,"^",1)
	s OrderType=$P(OrdItem,"^",2)
	s PriorRowid=$p(OrdItem,"^",3)
	s RecDepRowid=$p(OrdItem,"^",8)
	s AdmReason=$replace($p(OrdItem,"^",9),$c(10),"")
	s FreqRowid=$p(OrdItem,"^",15)
	s DurRowid=$p(OrdItem,"^",16)
	s OrderNeedPIVAFlag=$p(OrdItem,"^",48)
	s PriorCode=""
	s:PriorRowid'="" PriorCode=$p($g(^OECPR(PriorRowid)),"^",1)
	s OrderName=$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",2)
	;管制分类与医嘱类型的限制
	s ret=..CheckPriorAllow(Adm,PriorRowid,ARCIMRowid,Loc,FreqRowid)
    if (+ret<0) {
        s OutInfo="-1^" _$P(ret,"^",2)
		q OutInfo
    }
    Set OrderVirtualtLong=$p(OrdItem,"^",79)
    if (OrderVirtualtLong="Y"){
	    ///校验虚拟长期限制
		s ret=..CheckVirtualtLongAllow(Adm,ARCIMRowid,Loc,FreqRowid)
	    if (+ret<0) {
	        s OutInfo="-1^" _$P(ret,"^",2)
			q OutInfo
	    }  
	}
	s CurLogonHosp =$p(^CTLOC(Loc),"^",22)
	s IPDosingRecLocStr=##Class(DHCDoc.DHCDocConfig.DocConfig).GetDosingRecLocStr(CurLogonHosp)
    if (PriorCode="OUT")&&((OrderNeedPIVAFlag="Y")&&(("^"_IPDosingRecLocStr_"^")[("^"_RecDepRowid_"^"))){
		s OutInfo="-1^" _OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 出院带药不能开到静配中心!")
		s $P(OutInfo,"^",4)="OrderRecDep"
		q OutInfo
	}
	q "0^^^"
}

/// 校验虚拟长期限制
ClassMethod CheckVirtualtLongAllow(Adm As %String, ARCIMRowid As %String, Loc As %String, FreqID = "") As %String
{
	s UserEMVirtualtLong=##Class(web.DHCDocOrderVirtualLong).GetUserEMVirtualtLong(Adm)
	Q:(UserEMVirtualtLong=0) "-1^仅押金模式下的留观患者可使用虚拟长期"
	s PriorRowid=$O(^OECPR(0,"Code","S",0))
	s ret=..CheckPriorAllow(Adm,PriorRowid,ARCIMRowid,Loc,FreqID)
	
	q ret
}

/// 医嘱录入js中有调用该方法
ClassMethod CheckPriorAllow(Adm As %String, OrderPriorRowid As %String, OrderARCIMRowid As %String, Loc As %String, FreqID = "", langid = "", FromLookUp As %String = "") As %String
{
	n (Adm,OrderPriorRowid,OrderARCIMRowid,Loc,FreqID,langid,FromLookUp,%session)
	s HospId=$p(^CTLOC(Loc),"^",22)
	if langid=""  Set langid=..%LanguageID()
	s OrderName=$p(^ARCIM(+OrderARCIMRowid,$p(OrderARCIMRowid,"||",2),1),"^",2)
	s OrderName=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",OrderName,langid)
    s ShortOrderPriorRowid=$O(^OECPR(0,"Code","NORM",0))
    s LongOrderPriorRowid=$O(^OECPR(0,"Code","S",0))
    ;出院带药不能下的子类和管制分类控制
 	s PriorCheckRet=##Class(web.DHCDocOrderCommon).CheckPriorAllowRange(Adm,OrderPriorRowid,OrderARCIMRowid,HospId,Loc,FreqID,.ErrMsg,langid,FromLookUp)
	if PriorCheckRet>0{
		s ret="-1^"_ErrMsg
		if " 3 4 6 7 9 "[(" "_PriorCheckRet_" "){
			s ret=ret_"^"_ShortOrderPriorRowid
		}elseif " 10 12 13 "[(" "_PriorCheckRet_" "){
			s ret=ret_"^"_LongOrderPriorRowid
		}
		Q ret
	}
    q "0^^^"
}

ClassMethod CheckOutOrderOtherContral(Adm As %String, OrdItem As %String, CheckExpStr As %String, ByRef CallBackFunStr As %String) As %String
{
	n (Adm, OrdItem, CheckExpStr,CallBackFunStr,%session)
	s PAADMType=$p($g(^PAADM(Adm)),"^",2)
	Set langid=..%LanguageID()
	s ARCIMRowidStr=$P(CheckExpStr,$C(2),1)
	s CurLogonLocId=$P(CheckExpStr,$C(2),2)
	s CurLogonHospId=$p($g(^CTLOC(CurLogonLocId)),"^",22)
	s ARCIMRowid=$P(OrdItem,"^",1)
	s OrderType=$P(OrdItem,"^",2)
	s PriorRowid=$p(OrdItem,"^",3)
	Set PackQty=$p(OrdItem,"^",6)
	Set AdmReason=$replace($p(OrdItem,"^",9),$c(10),"")
	Set DoseQty=$p(OrdItem,"^",12)
	Set DoseUOMRowid=$p(OrdItem,"^",13)
	Set FreqRowid=$p(OrdItem,"^",15)
	Set DurRowid=$p(OrdItem,"^",16)
	Set InstrRowid=$p(OrdItem,"^",17)
	Set OrderPackUOMRowid=$p(OrdItem,"^",55)
	s ItemCatRowid=$p($g(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1)),"^",10)
	s PriorCode=""
	s:PriorRowid'="" PriorCode=$p($g(^OECPR(PriorRowid)),"^",1)
	s OrderName=$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",2)
	s OrderName=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",OrderName,langid)
	if (PriorCode'="OUT")||(PAADMType'="I"){
		q "0^^^"
	}
	;出院带药根据病人的费别其他限制--医生站设置-基本设置
 	s CheckOutOrderOtherInfo=##Class(web.DHCDocOrderCommon).CheckOutOrderOtherContral(Adm, AdmReason, DurRowid, ItemCatRowid, ARCIMRowidStr, ARCIMRowid, FreqRowid, OrderPackUOMRowid, DoseQty, DoseUOMRowid, CurLogonHospId)
	if (+CheckOutOrderOtherInfo'=0){
		s OutInfo="-1^" _$P(CheckOutOrderOtherInfo,"^",2)
		s $P(OutInfo,"^",4)="OrderName"
		q OutInfo
	}
	;判断是否有相同出院带药
 	s ret=##Class(web.DHCDocOrderEntry).FindSameOutOrderItem(Adm,ARCIMRowid,ARCIMRowidStr)
	if (+ret=1){
		s CallBackFunParams=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," ,存在相同的出院带药医嘱,是否继续?")
		s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
	}
	q "0^^^"
}

ClassMethod CheckMasterConsistency(Adm As %String, OrdItem As %String, ByRef CallBackFunStr As %String) As %String
{
	n (Adm,OrdItem,CallBackFunStr,%session)
	s ARCIMRowid=$P(OrdItem,"^",1)
	s PriorRowid=$p(OrdItem,"^",3)
	Set MasterSeqNo=$p(OrdItem,"^",19)
	Set VerifiedOrderMasterRowid=$p(OrdItem,"^",39)
	s PriorCode=""
	s:PriorRowid'="" PriorCode=$p($g(^OECPR(PriorRowid)),"^",1)
	s OrderName=$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",2)
	s VerifiedFlag=0
	s MastOrderPriorRowid=""
	if (VerifiedOrderMasterRowid '= "") {
        s MastOrderPriorRowid = ##Class(web.DHCDocOrderCommon).GetNurMastOrderPriorRowid(VerifiedOrderMasterRowid)
        s VerifiedOrderStr=##class(web.DHCDocOrderCommon).GetVerifiedOrder(VerifiedOrderMasterRowid,..%SessionStr())
        s VerifiedFlag=$p(VerifiedOrderStr,"^",1)
        if (VerifiedFlag'=0) {
	        s OutInfo="-1^"_..%Translate("oeorder.oplistcustom.new.csp","主医嘱错误：")_..%Translate("oeorder.oplistcustom.new.csp",VerifiedFlag)
			s $P(OutInfo,"^",4)="OrderName"
			q OutInfo
	    }
    } elseif (MasterSeqNo '= "") {
        s MastOrderPriorRowid = PriorRowid
    }
    if (MastOrderPriorRowid '= "") {
        s MastOrderPriorFlag = ##class(appcom.OEOrdItem).ISLongOrderPrior(MastOrderPriorRowid)
        s OrderPriorFlag = ##class(appcom.OEOrdItem).ISLongOrderPrior(PriorRowid)
        if (MastOrderPriorFlag '= OrderPriorFlag) {
	        s OutInfo="-1^"_..%Translate("oeorder.oplistcustom.new.csp","关联医嘱类型不同，不给予审核！")
			s $P(OutInfo,"^",4)="OrderName"
			q OutInfo
        }
    }
	q "0^^^"
}

ClassMethod CheckBillTypeSum(EpisodeID As %String, CheckExpStr As %String, OrderBillTypeArray As %String, ByRef CallBackFunStr As %String) As %String
{
	n (EpisodeID, CheckExpStr,OrderBillTypeArray,CallBackFunStr,%session)
	s AdmReason=$P(^PAADM(EpisodeID,1),"^",7)
	s PAADMType=$p($g(^PAADM(EpisodeID)),"^",2)
	s LogonDep=$P(CheckExpStr,"^",1)
	s CurLogonHosp=$p(^CTLOC(LogonDep),"^",22)
	s DefHospId=##Class(DHCDoc.Common.Hospital).GetDefHospIdByTableName("DHC_PAADMPrescType",CurLogonHosp)
	s OutInfo="0^^^^"
	s (BillTypeSum,SaveBillTypeSum,OutOrderSum)=0
	k AdmReasonPrescTypeArr
	s rowid=0
	for  {
		s rowid=$O(^DHCPAADMPrescType(0,"PAADMType",PAADMType,rowid))
		q:rowid=""
		s BillTypeRowid=$p($g(^DHCPAADMPrescType(rowid)),"^",2)
		continue:(AdmReason'=BillTypeRowid)
		s PrescTypeHospDr=$p($g(^DHCPAADMPrescType(rowid)),"^",5)
		Q:(PrescTypeHospDr'=DefHospId)
		s PrescTypeRowid=$p($g(^DHCPAADMPrescType(rowid)),"^",3)
		s PrescBillTypeRowid=$p($g(^DHCPrescriptType(PrescTypeRowid)),"^",9)
		s PrescTypeDesc=$p($g(^DHCPrescriptType(PrescTypeRowid)),"^",2)
		s AdmReasonPrescTypeArr(PrescBillTypeRowid)=PrescTypeDesc
	}
	
	
	s SaveBillTypeSum=0
	s OrderBillTypeRowid=0
	for {
		s OrderBillTypeRowid=$O(OrderBillTypeArray(OrderBillTypeRowid))
		q:(OrderBillTypeRowid="")
		s Amount=$G(OrderBillTypeArray(OrderBillTypeRowid))
		continue:(+Amount<=0)
		s PrescTypeDesc=$G(AdmReasonPrescTypeArr(OrderBillTypeRowid))
		
		if (PAADMType="O"){
			///校验处方金额
			s PrescLimitStr=##Class(web.DHCPAADMPrescType).GetPrescLimitStr(PAADMType,PrescTypeDesc,OrderBillTypeRowid,CurLogonHosp)
			s PrescLimitSum = $P(PrescLimitStr,"!",6)
			s PTUnaveLimitSum= $P(PrescLimitStr,"!",9)
	        s PrescLimitType = $P(PrescLimitStr,"!",10)
			s retDetail=##Class(web.DHCDocOrderCommon).CheckBillTypeSum(EpisodeID,OrderBillTypeRowid, PrescLimitSum, Amount, PrescLimitType,LogonDep)
			if (retDetail="1"){
				s BillTypeSum=1
			}
			
			///限制页面未审金额
			if (Amount>PTUnaveLimitSum)&&(+PTUnaveLimitSum>0){
				s SaveBillTypeSum=1
			}
		}
		///出院带药根据费别的病人费用限制
		if (PAADMType="I"){
			s retDetail=##Class(web.DHCDocOrderCommon).CheckOutOrderSum(EpisodeID,OrderBillTypeRowid,Amount)
			if (retDetail=1){
				s OutOrderSum=1
			}
		}
	}
	if (BillTypeSum=1){
		s CallBackFunParams="本日所开医嘱费用已经超过限定,您确定通过吗?"
		s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
	}
	if (SaveBillTypeSum=1){
		s CallBackFunParams="未审核医嘱费用已经超过限定,您确定通过吗??"
		s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
	}
	if (OutOrderSum=1){
		s OutInfo="-1^已开出院带药的药品总额,超过限额200元,不能通过,请重新开!"
	}
	q OutInfo
}

ClassMethod CheckKSS(Adm As %String, OrdItem As %String, ByRef CallBackFunStr As %String = "") As %String
{
	n (Adm,OrdItem,CallBackFunStr)
	s OrderARCIMRowid=$p(OrdItem,"^",1)
	s OrderPriorRowid=$p(OrdItem,"^",3)
	s OrderAntibApplyRowid=$p(OrdItem,"^",49)
	s AntUseReason=$p(OrdItem,"^",50)
	s OrderName=$p(^ARCIM(+OrderARCIMRowid,$p(OrderARCIMRowid,"||",2),1),"^",2)
	s PoisonRowid=##class(web.DHCDocOrderEntry).GetDrgFormPoison(OrderARCIMRowid)
	s OrderPoisonCode=""
	i PoisonRowid'="" s OrderPoisonCode=$p($g(^PHCPO(PoisonRowid)),"^",1)
	s PriorCode=$p($g(^OECPR(OrderPriorRowid)),"^",1)
	
    if ((PriorCode ="NORM") && (OrderPoisonCode["KSS")) {
        //加一个条件（申请单为未审核给与提示）
        if ((OrderAntibApplyRowid '= "") && (OrderAntibApplyRowid '= "undefined")) {
            s AppStatusFlag = ##Class(web.DHCDocAntiCommon).GetAntibioSta(OrderAntibApplyRowid)
            if (AppStatusFlag = 0) {
	            s OutInfo="0^请上级医师24小时内审核"
				s $P(OutInfo,"^",4)="OrderName"
				q OutInfo
            }
        }
    }
    if ((OrderPoisonCode["KSS") && (AntUseReason = "")) {
	    /*
        s OutInfo="-1^"_OrderName+" 请选择抗生素使用原因"
		s $P(OutInfo,"^",4)="AntUseReason"
		q OutInfo
		*/
    }
    
    
    
    q "0^^^"
}

/// 根据就诊ID判断患者是否存在死亡诊断分类下的诊断
/// 1存在 0 不存在
/// w ##class(web.DHCOEOrdItem).IsExistDeathTypeDiag()
ClassMethod IsExistDeathTypeDiag(EpisodeId As %String) As %String
{
	Q:EpisodeId="" 1
	s mradm=$p(^PAADM(EpisodeId),"^",61)
	Q:mradm="" 1
	s FindDeathDiagFlag=0,Childsub=0
	for {
		s Childsub=$o(^MR(mradm,"DIA",Childsub)) Q:Childsub=""||(FindDeathDiagFlag=1)
		s ICDDr=$p(^MR(mradm,"DIA",Childsub),"^",1) 
		continue:ICDDr=""
		s Active=$p(^MR(mradm,"DIA",Childsub),"^",34) 
		continue:Active'="Y"
		s MRCIDTypeDR=$p($g(^MRC("ID",ICDDr)),"^",46)
		continue:MRCIDTypeDR=""
		i $G(^DHCDocConfig("DeathICDType",MRCIDTypeDR))=1 s FindDeathDiagFlag=1
	}
	Q FindDeathDiagFlag
}

/// w ##class(web.DHCOEOrdItem).GetToDayAdmInfo("935")
ClassMethod GetToDayAdmInfo(EpisodeID As %String) As %String
{
	n (EpisodeID)
	s AdmDate=$p($g(^PAADM(EpisodeID)),"^",6)
	s OrderInfo=""
	s PAPMI=$p(^PAADM(EpisodeID),"^",1)
	If $g(PAPMI)'="" d
	.S Adm=0 f  Set Adm=$o(^PAPERdr(PAPMI,"ADM","O",Adm)) quit:Adm=""  d
	..s VisitStatus=$p($g(^PAADM(Adm)),"^",20)
	..Q:VisitStatus'="A"
	..s OneAdmDate=$p($g(^PAADM(Adm)),"^",6)
	..q:OneAdmDate'=AdmDate
	..s OrderRowid=$o(^OEORD(0,"Adm",Adm,""))
	..Q:OrderRowid=""
	..i OrderInfo="" s OrderInfo=OrderRowid
	..e  s OrderInfo=OrderInfo_"^"_OrderRowid
	.S Adm=0 f  Set Adm=$o(^PAPERdr(PAPMI,"ADM","E",Adm)) quit:Adm=""  d
	..s VisitStatus=$p($g(^PAADM(Adm)),"^",20)
	..Q:VisitStatus'="A"
	..s OneAdmDate=$p($g(^PAADM(Adm)),"^",6)
	..q:OneAdmDate'=AdmDate
	..s OrderRowid=$o(^OEORD(0,"Adm",Adm,""))
	..Q:OrderRowid=""
	..i OrderInfo="" s OrderInfo=OrderRowid
	..e  s OrderInfo=OrderInfo_"^"_OrderRowid
	q OrderInfo
}

/// 判断本次审核医嘱中是否含有病危/病重医嘱
/// 判断配置:产品配置->护理系统配置->图标代码配置界面维护的病危/病重医嘱code
ClassMethod GetCriticalArcItemStr(OrderItemStr As %String) As %String
{
	s BVFlag="N"
	//病重
	s SeriouslyCodeStr=##class(Nur.ImageSet).GetArcCode("SERIOUSLY")
	//病危
	s CriticallyCodeStr=##class(Nur.ImageSet).GetArcCode("CRITICALLY")
	for i=1:1:$l(OrderItemStr,$C(1)) {
		s OneItemStr=$p(OrderItemStr,$C(1),i)
		s ArcimID=$p(OneItemStr,"^",1)
		s ArcCode=$p(^ARCIM(+ArcimID,$p(ArcimID,"||",2),1),"^",1)
		continue:ArcCode=""
		s ArcCode="^"_ArcCode_"^"
		if ("^"_SeriouslyCodeStr_"^")[ArcCode {
			s BVFlag="Y"
			Q
		}
		if ("^"_CriticallyCodeStr_"^")[ArcCode {
			s BVFlag="Y"
			Q
		}
	}
	Q BVFlag
}

/// creator:	宋春莉
/// date:		2019-09-18
/// desc:		对于中草药录入非必须前端处理的判断逻辑可以在此处理
/// input:		OrdItemStr:医嘱录入需要审核的医嘱项目拼接字符串 
/// 				DisplayTypeFlag 表示输入界面类型 1 输出EasyUI匹配得换行符号<br>
/// output:		空 或 标志位^受控描述^... 标志位:0或1 1标识受控,不可以录入
ClassMethod CheckCMBeforeSave(Adm As %String, OrdItemStr As %String, User As %String, Loc As %String, Doc As %String, ExpStr As %String = "", DisplayTypeFlag As %String = "") As %String
{
	n (Adm,OrdItemStr,User,Loc,Doc,ExpStr,DisplayTypeFlag,%session)
	s ^tempscl("CheckBeforeSave")="##class(web.DHCOEOrdItem).CheckCMBeforeSave("_Adm_","""_OrdItemStr_""","_User_","_Loc_","_Doc_","""_ExpStr_""","""_DisplayTypeFlag_""")"
	s CallBackFunStr=""
	//行号^焦点原始名称^回调方法代码\名称^回调方法入参(,分割)
	s CallBackFunStr=""
	s NeedCheckDeposit=0
	s OutInfo=""
	;若登录用户未维护医护人员信息,也能审核医嘱成功,造成查询医嘱查询不到
	if Doc=""{
		s OutInfo="-100^请联系相关人员维护医护人员信息.^^"
		q:(+OutInfo'=0) $$CheckCMBeforeSaveJsonObj(OutInfo,CallBackFunStr)
	}
	s AdmType=$P($G(^PAADM(Adm)),"^",2)
	s AdmLocID=$p($g(^PAADM(Adm)),"^",4)
	s AdmHospID=$p(^CTLOC(AdmLocID),"^",22)

	s PrescStr=$p(OrdItemStr,$C(2),1)
	k CMPrescArr
	d SetCMPrescDetails(PrescStr,.CMPrescArr)
	//获取医嘱录入/草药录入提示信息
	s warning=##Class(web.DHCDocViewDataInit).GetOrdEntryWarning(Adm,"Y",CMPrescArr("EmConsultItm"))
	if (warning'="") {
		s warning=##class(web.DHCDocUtil).EvalJSON(warning)
		s OutInfo="-100^"_warning_"^^"
		Q:(+OutInfo'=0) $$CheckCMBeforeSaveJsonObj(OutInfo,CallBackFunStr)
	}
	if (CMPrescArr("PrescPriorRowid")="") {
		s OutInfo="-100^请选择医嘱类型!^^"
		Q $$CheckCMBeforeSaveJsonObj(OutInfo,CallBackFunStr)
	}
	s PrescPriorDesc=$p($g(^OECPR(CMPrescArr("PrescPriorRowid"))),"^",2)
	if ((CMPrescArr("PrescPriorCode")="NORM")&&(AdmType="I")){
		s OutInfo="-100^住院患者不能选择<font style='color:red;'>临时医嘱</font>，会导致发药数量与开立数量不一致!^^"
		Q $$CheckCMBeforeSaveJsonObj(OutInfo,CallBackFunStr)
	}
	if ((CMPrescArr("PrescPriorCode")'["OM") && (CMPrescArr("PrescPriorCode")'["ZT")){
		s NeedCheckDeposit=1
	}	
	s OrdItemStr=$p(OrdItemStr,$C(2),2)
	if (OrdItemStr=""){
		s OutInfo="-100^没有新开医嘱!^^"
		Q $$CheckCMBeforeSaveJsonObj(OutInfo,CallBackFunStr)
	}
	s LongOrderArcimID=CMPrescArr("AddLongOrder")
	if (LongOrderArcimID'=""){
		//s LongOrderType=##class(web.DHCDocOrderCommon).GetOrderType(LongOrderArcimID)
		//if LongOrderType="R" {	//草药带入的非药品不判断出院带药控制，非药品会在录入前转成临嘱
			;出院带药不能下的子类和管制分类控制
		    s ret=##Class(web.DHCOEOrdItem).CheckPriorAllow(Adm,5,LongOrderArcimID,Loc,CMPrescArr("PrescFreqRowid"))
		    if (+ret<0) {
		        s ErrMsg=$P(ret,"^",2)
		       	s OutInfo="-100^"_ErrMsg_"^^"
				Q $$CheckCMBeforeSaveJsonObj(OutInfo,CallBackFunStr)
		    }
		//}
	}
	s OutInfo=$$CheckCMPrescBaseInfo(.CMPrescArr,Loc,Adm)
	Q:(+OutInfo'=0) $$CheckBeforeSaveJsonObj(OutInfo,CallBackFunStr)
	;草药库存不足一次性提示
 	s NoStockOnePrompt=..%GetConfig("CMNoStockOnePrompt",AdmHospID)
 	s (NotStcokName,NotStcokCell)=""
	s EdibleFlag="Y"
	Set OrdItemCount=$L(OrdItemStr,$c(1))
	for i=1:1:OrdItemCount {
		s OrdItem=$p(OrdItemStr,$c(1),i)
		continue:OrdItem=""
		s ARCIMRowid=$p(OrdItem,"^",1)
		continue:ARCIMRowid=""
		
		k CMPrescOrdArr
		d SetCMOrdDetails(OrdItem,.CMPrescOrdArr)
		;1.基本信息校验或通用信息审查
		s OutInfo=$$CheckCMOrdBasicInfo(Adm,Loc,.CMPrescArr,.CMPrescOrdArr,.CallBackFunStr)
		i (+OutInfo'=0) s $P(OutInfo,"^",3)=CMPrescOrdArr("cellPosi") Q		
		;2.检查库存
		s StockInfo=$$CheckCMOrdStock(Loc,.CMPrescArr,.CMPrescOrdArr,Adm)
		i NoStockOnePrompt'="1"{
			s OutInfo=StockInfo
			i (+OutInfo'=0) s $P(OutInfo,"^",3)=CMPrescOrdArr("cellPosi") Q
		}else{
			i (+StockInfo'=0){
				;一次性提示库存不足信息
				s NotStcokName=$p(StockInfo,"^",2)_"、"_NotStcokName
				if (CMPrescOrdArr("cellPosi")'=""){		//有可能是附带绑定出的医嘱库存不足
					s NotStcokCell=CMPrescOrdArr("cellPosi")_"、"_NotStcokCell
				}
			}
		}
		s OEORIBindSource=$p(OrdItem,"^",14)
		s SingleEdibleFlag=##class(PHA.FACE.OUT.Com).GetEdibleFlagByArcim(ARCIMRowid)
		if ((SingleEdibleFlag'="Y")&&(OEORIBindSource="")) s EdibleFlag="N"
	}
	i NotStcokName'="" {
		if (NotStcokCell'=""){
			s OutInfo="-1@NoStockOnePrompt^"_NotStcokName_"^"_NotStcokCell
		}else{
			s OutInfo="-1^"_NotStcokName_"^^^^"
		}
	}
	Q:(+OutInfo'=0) $$CheckCMBeforeSaveJsonObj(OutInfo,CallBackFunStr)
	b ;是否全部都为药食同源的医嘱
	if (EdibleFlag="Y"){
		s OutInfo=0_"^^^^^"
		s CallBackFunParams="整张处方都为药食同源处方,是否审核"
		s CallBackFunStr=##class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
		Q $$CheckCMBeforeSaveJsonObj(OutInfo,CallBackFunStr)
	}
	Q $$CheckCMBeforeSaveJsonObj(OutInfo,CallBackFunStr)
SetCMOrdDetails(OrdItem,CMPrescOrdArr) 
    n (OrdItem,CMPrescOrdArr,%session)
    Set langid=..%LanguageID()
	s CMPrescOrdArr("OrderARCIMRowid")=$p(OrdItem,"^",1)
	s CMPrescOrdArr("OrderDoseQty")=$p(OrdItem,"^",2)
	s CMPrescOrdArr("OrderDoseUOMRowid")=$p(OrdItem,"^",3)
	s CMPrescOrdArr("OrderPhSpecInstr")=$p(OrdItem,"^",4)
	s CMPrescOrdArr("CNMedCookModeFeeFlag")=$p(OrdItem,"^",5)
	s CMPrescOrdArr("ARCIMARCOSRowid")=$p(OrdItem,"^",6)
	s CMPrescOrdArr("INCIPackCombStr")=$p(OrdItem,"^",7)
	s CMPrescOrdArr("cellPosi")=$p(OrdItem,"^",8)
	s CMPrescOrdArr("OrderHiddenPara")=$p(OrdItem,"^",9)
	s CMPrescOrdArr("OEORIBindSource")=$p(OrdItem,"^",14)

	s BindSourceDesc=##class(web.DHCDocQryOEOrder).GetBindSourceDescByCode(CMPrescOrdArr("OEORIBindSource"))
	s ArcimDesc=$P(^ARCIM(+CMPrescOrdArr("OrderARCIMRowid"),$P(CMPrescOrdArr("OrderARCIMRowid"),"||",2),1),"^",2)
	s ArcimDesc=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",ArcimDesc,langid)
	if (BindSourceDesc=""){
		s CMPrescOrdArr("OrderName")=ArcimDesc
	}else{
		s BindSourceDesc=..%Translate("opdoc.oeorder.cmlistcustom.csp",BindSourceDesc)
		s CMPrescOrdArr("OrderName")=..%Translate("opdoc.oeorder.cmlistcustom.csp","通过 ")_BindSourceDesc_..%Translate("opdoc.oeorder.cmlistcustom.csp"," 绑定的【")_ArcimDesc_"】"
	}
	Q
SetCMPrescDetails(PrescStr,CMPrescArr)
	n (PrescStr,CMPrescArr)
	s CMPrescArr("PrescPriorRowid")=$P(PrescStr,"^",1)
	if (CMPrescArr("PrescPriorRowid")'="") s CMPrescArr("PrescPriorCode")=$p($g(^OECPR(CMPrescArr("PrescPriorRowid"))),"^",1)
	s CMPrescArr("PrescDurRowid")=$P(PrescStr,"^",2)
	s CMPrescArr("PrescInstrRowid")=$P(PrescStr,"^",3)
	s CMPrescArr("PrescFreqRowid")=$P(PrescStr,"^",4)
	s CMPrescArr("PrescCookDecoction")=$P(PrescStr,"^",5)
	s CMPrescArr("PrescOrderQty")=$P(PrescStr,"^",6)
	if (CMPrescArr("PrescOrderQty")'="")&&($D(^PHCDO(CMPrescArr("PrescOrderQty")))){
		s CMPrescArr("PrescOrderQty")=$p(^PHCDO(CMPrescArr("PrescOrderQty")),"^",3)
	}
	s CMPrescArr("PrescRecDepRowid")=$P(PrescStr,"^",7)
	s CMPrescArr("PrescAdmReason")=$P(PrescStr,"^",8)
	s CMPrescArr("PrescNotes")=$P(PrescStr,"^",9)
	s CMPrescArr("PrescEmergency")=$P(PrescStr,"^",10)
	s CMPrescArr("PrescStartDate")=$P(PrescStr,"^",11)
	s CMPrescArr("PrescStartTime")=$P(PrescStr,"^",12)
	s CMPrescArr("PrescARCOSRowId")=$P(PrescStr,"^",13)
	s CMPrescArr("PrescWeight")=$P(PrescStr,"^",14)
	s CMPrescArr("AddLongOrder")=$P(PrescStr,"^",15)
	s CMPrescArr("CMPrescTypeCode")=$P(PrescStr,"^",16)
	s CMPrescArr("PrescAppenItemQty")=$P(PrescStr,"^",18)
	s CMPrescArr("EmConsultItm")=$P(PrescStr,"^",20)
	s CMPrescArr("TakingMedicineMethod")=$P(PrescStr,"^",21)
	Q
CheckCMOrdBasicInfo(Adm,CurLogonDep,CMPrescArr,CMPrescOrdArr,CallBackFunStr)
	n (Adm,CurLogonDep,CMPrescArr,CMPrescOrdArr,CallBackFunStr,%session)
	s OutInfo=0_"^^^^^"
	s OrderARCIMRowid=CMPrescOrdArr("OrderARCIMRowid")
	s OrderName=CMPrescOrdArr("OrderName")
	s OrderDoseQty=CMPrescOrdArr("OrderDoseQty")
	s OrderHiddenPara=CMPrescOrdArr("OrderHiddenPara")
	s PrescRecDepRowid=CMPrescArr("PrescRecDepRowid")
	s OrderPriorRowid=CMPrescArr("PrescPriorRowid")
	s PrescFreqRowid=CMPrescArr("PrescFreqRowid")
	s CurLogonHosp =$p(^CTLOC(CurLogonDep),"^",22)
	s ItemCatRowId=+$p($g(^ARCIM(+$g(OrderARCIMRowid),1,1)),"^",10)
	s OrderType=$P(^ARC("IC",ItemCatRowId),"^",7)
	
	//判断医嘱项中的门急诊限制
	s CheckArcimTypeStr=##class(web.DHCDocOrderCommon).CheckArcimType(OrderARCIMRowid,Adm,"")
  	if (CheckArcimTypeStr'=""){
	  	s ErrMsg=OrderName_..%Translate("opdoc.oeorder.cmlistcustom.csp",CheckArcimTypeStr)
		s FocusCol="OrderName"
		Q "-1^"_ErrMsg_"^^"_FocusCol
	}
	;出院带药不能下的子类和管制分类控制
	if OrderType="R" {	//草药非药品不参与判断，会自动在插入表前修改为临嘱
	    s ret=##Class(web.DHCOEOrdItem).CheckPriorAllow(Adm,OrderPriorRowid,OrderARCIMRowid,CurLogonDep,PrescFreqRowid)
	    if (+ret<0) {
	        s ErrMsg=$P(ret,"^",2)
	        s FocusCol="OrderName"
	    	Q "-1^"_ErrMsg_"^^"_FocusCol
	    }
	}
	if (OrderDoseQty="") {
		s ErrMsg=OrderName_..%Translate("opdoc.oeorder.cmlistcustom.csp","没有录入数量!")
		s FocusCol="OrderDoseQty"
		Q "-1^"_ErrMsg_"^^"_FocusCol
	}
	s AllowEntryDecimalItemCat="N"
	s ITCRowID=$o(^DHCItmMast("0","ARCIM",OrderARCIMRowid,""),-1)
	if (ITCRowID'=""){
		s AllowEntryDecimalItemCat=$p($G(^DHCItmMast(ITCRowID)),"^",29)
	}
	s AllowEntryDecimalItemCat=$CASE(AllowEntryDecimalItemCat,"Y":"Y",:"N")
	//s AllowEntryDecimalItemCat=##Class(web.DHCDocOrderCommon).GetAllowEntryDecimalItemCat(Adm,CurLogonHosp)
	if (AllowEntryDecimalItemCat'="Y"){
		if (OrderDoseQty'="")&&((OrderDoseQty=0)||((OrderDoseQty#1)>0)){
			s ErrMsg=OrderName _..%Translate("opdoc.oeorder.cmlistcustom.csp","的数量不是有效数字,请检查")
	        s FocusCol="OrderDoseQty"
	    	Q "-1^"_ErrMsg_"^^"_FocusCol
		}
	}
	s CheckValue = "^(?!(0[0-9]{0,}$))[0-9]{1,}[.]{0,}[0-9]{0,}$"
	if (OrderDoseQty'="")&&(('$MATCH(OrderDoseQty,CheckValue))||(OrderDoseQty<0)){
		s ErrMsg=OrderName_..%Translate("opdoc.oeorder.cmlistcustom.csp","请输入正确的数量!")
		s FocusCol="OrderDoseQty"
		Q "-1^"_ErrMsg_"^^"_FocusCol
	}
	s NotLimitQty=..GetItemNotLimitQtyFlag(OrderARCIMRowid)
	if (OrderDoseQty'="")&&(+OrderDoseQty>9999)&&(NotLimitQty'="Y") {
		s ErrMsg=OrderName_..%Translate("opdoc.oeorder.cmlistcustom.csp","数量不能超过9999!")
		s FocusCol="OrderDoseQty"
		Q "-1^"_ErrMsg_"^^"_FocusCol
	}
    s ItemCatRowid=$p($g(^ARCIM(+OrderARCIMRowid,$p(OrderARCIMRowid,"||",2),1)),"^",10)

	if (AllowEntryDecimalItemCat'="Y"){
		if ((OrderDoseQty#1)>0){
			s ErrMsg=OrderName_..%Translate("opdoc.oeorder.cmlistcustom.csp","数量不能是小数!")
			s FocusCol="OrderDoseQty"
			Q "-1^"_ErrMsg_"^^"_FocusCol
		}
	}
	if (OrderHiddenPara'="") {
		s OrderMaxQty=$p(OrderHiddenPara,$C(3),2)
	  	s OrderMaxDurFactor=$p(OrderHiddenPara,$C(3),1)
	    s WarningUseQty=$p(OrderHiddenPara,$C(3),9)
	    if ((+WarningUseQty>0)&&((+OrderDoseQty)>(+WarningUseQty))) {
		    s ErrMsg=OrderName_..%Translate("opdoc.oeorder.cmlistcustom.csp","超过药品的极限用量限定:")_WarningUseQty
			s FocusCol="OrderDoseQty"
			Q "-1^"_ErrMsg_"^^"_FocusCol
	    }
	  	if ((+OrderMaxQty>0)&&((+OrderDoseQty)>(+OrderMaxQty))) {
		  	/*s ErrMsg=OrderName_"此药品的最大限量为:"_OrderMaxQty
			s FocusCol="OrderDoseQty"
			Q "-1^"_ErrMsg_"^^"_FocusCol*/
			s CallBackFunParams=OrderName_..%Translate("opdoc.oeorder.cmlistcustom.csp","此药品的最大限量为:")_OrderMaxQty_..%Translate("opdoc.oeorder.cmlistcustom.csp",",是否继续?")
			s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
	  	}
  	}
	//判断数量是不是由药房系数组合
	s ret=..CheckProtocolPackSum(OrderARCIMRowid, OrderDoseQty,PrescRecDepRowid)
	if (+ret'=0){
		s ErrMsg=$P(ret,"^",2)
		s FocusCol="OrderDoseQty"
		Q "-1^"_ErrMsg_"^^"_FocusCol
	}
	
    Q OutInfo
CheckCMOrdStock(Loc,CMPrescArr,CMPrescOrdArr,Adm)
	n (Loc,CMPrescArr,CMPrescOrdArr,Adm,%session)
	s OutInfo=0_"^^^^^"
	Set langid=..%LanguageID()
	s OrderName=CMPrescOrdArr("OrderName")
	s OrderARCIMRowid=CMPrescOrdArr("OrderARCIMRowid")
	s PrescRecDepRowid=CMPrescArr("PrescRecDepRowid")
	s OrderRecDep=$p(^CTLOC(PrescRecDepRowid),"^",2)
	s OrderRecDep=##class(User.CTLoc).GetTranByDesc("CTLOCDesc",OrderRecDep,langid)
	s INCIPackCombStr=CMPrescOrdArr("INCIPackCombStr")
	s CNMedCookModeFeeFlag=CMPrescOrdArr("CNMedCookModeFeeFlag")
	Q:CNMedCookModeFeeFlag'="" OutInfo
	s OEORIBindSource=CMPrescOrdArr("OEORIBindSource")
	//Q:OEORIBindSource'="" OutInfo
	s TakingMedicineMethod=CMPrescArr("TakingMedicineMethod")
	s TakingMedicine="Y" //取药方式可以不判断库存
	if (TakingMedicineMethod'=""){
		s ToStock=$P(^DHCDocConfig("TakingMedicineMethod",TakingMedicineMethod),$c(1),4)
		if ((ToStock="N")||(ToStock=""))  s TakingMedicine="N"
	}
	s AdmType=$P($G(^PAADM(Adm)),"^",2)
	s CurLogonHospDr=$p(^CTLOC(Loc),"^",22)
	s OrderPHPrescType=##class(web.DHCDocOrderCommon).GetPHPrescTypeByItem(OrderARCIMRowid,CurLogonHospDr)
	if (OrderPHPrescType'=3){
		///草药绑定出来的附加费用，进行单独的库存判断
		s myRecDepRowid=$$GetRecloc^DHCDocOrderCommonNew(Adm,OrderARCIMRowid)
		if (myRecDepRowid="") s myRecDepRowid=PrescRecDepRowid
		s myOrderRecDep=$P(^CTLOC(myRecDepRowid),"^",2)
		s myOrderRecDep=##class(User.CTLoc).GetTranByDesc("CTLOCDesc",myOrderRecDep,langid)
		s ExpStr=Adm_"^"_Loc_"^0"
        s Check =##Class(web.DHCDocOrderCommon).CheckStockEnough(OrderARCIMRowid, CMPrescOrdArr("OrderDoseQty"), myRecDepRowid,AdmType,ExpStr)
		if (Check = "0") {
			q "-1^" _OrderName _..%Translate("opdoc.oeorder.cmlistcustom.csp"," 在 ")_myOrderRecDep_..%Translate("opdoc.oeorder.cmlistcustom.csp"," 库存不足")
		} elseif (Check = "-1")||(Check = "-2") {
			q "-1^" _OrderName _..%Translate("opdoc.oeorder.cmlistcustom.csp"," 在 ")_myOrderRecDep_..%Translate("opdoc.oeorder.cmlistcustom.csp"," 被锁定，如需要请联系药房工作人员")
		}
		Q OutInfo
	}

	if (INCIPackCombStr="")&&(OEORIBindSource="")&&(TakingMedicine="Y"){
		s ErrMsg=OrderName_..%Translate("opdoc.oeorder.cmlistcustom.csp","在")_OrderRecDep_..%Translate("opdoc.oeorder.cmlistcustom.csp","没有可用库存!")
		s FocusCol="OrderName"
		Q "-1^"_ErrMsg_"^^"_FocusCol
	} 	
	s PrescDurRowid=CMPrescArr("PrescDurRowid")
	s OrderDurFactor=$P($g(^PHCDU(+PrescDurRowid)),"^",2)
	s OrderDurFactor=##class(User.PHCDuration).GetTranByDesc("PHCDUDesc1",OrderDurFactor,langid)
	s CheckforlocStr=##class(web.DHCSTINTERFACE).GetIncilQtyList(OrderARCIMRowid,PrescRecDepRowid,AdmType)
	if (CheckforlocStr="")&&(TakingMedicine="Y"){
		s ErrMsg=OrderName_..%Translate("opdoc.oeorder.cmlistcustom.csp","在")_OrderRecDep_..%Translate("opdoc.oeorder.cmlistcustom.csp","没有可用库存!")
		s FocusCol="OrderDoseQty"
		Q "-1^"_ErrMsg_"^^"_FocusCol
	}
	
	s ExpStr=CurLogonHospDr
	s Check=##class(web.DHCDocOrderCommon).CheckStockEnoughByInc(INCIPackCombStr,PrescRecDepRowid,"",ExpStr,OrderDurFactor,TakingMedicineMethod)
	if (Check=0) {
		s ErrMsg=OrderName_..%Translate("opdoc.oeorder.cmlistcustom.csp","库存不足")
		s FocusCol="OrderDoseQty"
		Q "-1^"_ErrMsg_"^^"_FocusCol
	}
	
	Q OutInfo
CheckCMPrescBaseInfo(CMPrescArr,Loc,Adm)
	n (CMPrescArr,Loc,Adm,%session)
	s LogonHospDr=$p(^CTLOC(Loc),"^",22)
	s PrescOrderQty=CMPrescArr("PrescOrderQty")
	s PrescAppenItemQty=CMPrescArr("PrescAppenItemQty")
	s PrescCookDecoction=CMPrescArr("PrescCookDecoction")
	s CMPrescTypeCode=CMPrescArr("CMPrescTypeCode")
	s PrescWeight=CMPrescArr("PrescWeight")
	s PrescRecDepRowid=CMPrescArr("PrescRecDepRowid")
	s PrescStartDate=CMPrescArr("PrescStartDate")
	s PrescStartTime=CMPrescArr("PrescStartTime")
	s PrescDurRowid=CMPrescArr("PrescDurRowid")
	i PrescDurRowid'="" s PrescDurFactor=$p($g(^PHCDU(PrescDurRowid)),"^",2)
	e  s PrescDurFactor=1
	s OutInfo=0_"^^^^^"
	s PrescPriorRowid=CMPrescArr("PrescPriorRowid")
	if (PrescPriorRowid="")||(PrescPriorRowid="undefined") {
		s ErrMsg="医嘱类型不能为空!"
		s FocusCol="PrescPrior"
		s OutInfo="-1^"_ErrMsg_"^^"_FocusCol
		Q OutInfo
	}
	s PrescDurRowid=CMPrescArr("PrescDurRowid")
	if ((PrescDurRowid="")||(PrescDurRowid="undefined"))&&'##class(appcom.OEOrdItem).ISLongOrderPrior(CMPrescArr("PrescPriorRowid")) {
		s ErrMsg="用药付数不能为空!"
		s FocusCol="PrescDuration"
		s OutInfo="-1^"_ErrMsg_"^^"_FocusCol
		Q OutInfo
	}
	s PrescInstrRowid=CMPrescArr("PrescInstrRowid")
	if (PrescInstrRowid="")||(PrescInstrRowid="undefined") {
		s ErrMsg="使用方式不能为空!"
		s FocusCol="PrescInstruction"
		s OutInfo="-1^"_ErrMsg_"^^"_FocusCol
		Q OutInfo
	}
	s PrescFreqRowid=CMPrescArr("PrescFreqRowid")
	if (PrescFreqRowid="")||(PrescFreqRowid="undefined") {
		s ErrMsg="用药频次不能为空!"
		s FocusCol="PrescInstruction"
		s OutInfo="-1^"_ErrMsg_"^^"_FocusCol
		Q OutInfo
	}
	if (PrescRecDepRowid="")||(PrescRecDepRowid="undefined") {
		s ErrMsg="接收科室不能为空!"
		s FocusCol="RecLoc"
		s OutInfo="-1^"_ErrMsg_"^^"_FocusCol
		Q OutInfo
	}
	if (PrescOrderQty=""){
		s ErrMsg="一次用量不能为空!"
		s FocusCol="PrescOrderQty"
		s OutInfo="-1^"_ErrMsg_"^^"_FocusCol
		Q OutInfo
	}
	//药箅子数
	if (PrescAppenItemQty'="")&&(PrescAppenItemQty'=0) {
		s CheckValue = "^(?!(0[0-9]{0,}$))[0-9]{1,}[.]{0,}[0-9]{0,}$"
		if (PrescAppenItemQty'="")&&(('$MATCH(PrescAppenItemQty,CheckValue))||(PrescAppenItemQty<0)){
			s ErrMsg=OrderName_"请输入正确的药箅子数!"
			s FocusCol="PrescAppenItemQty"
			Q "-1^"_ErrMsg_"^^"_FocusCol
		}
	}
	s CheckMessage=##Class(web.DHCDocOrderCommon).CheckOrderDate(Adm,PrescStartDate_" "_PrescStartTime)
	if (CheckMessage'=""){
		s PAADMDate=$p($g(^PAADM(Adm)),"^",6)
		s PAADMTime=$p($g(^PAADM(Adm)),"^",7)
		s ErrMsg=..%Translate("opdoc.oeorder.cmlistcustom.csp","开始时间不能早于就诊时间:")_..%ZD(PAADMDate)_" "_..%ZT(PAADMTime,1)
		s FocusCol="PrescStartDate"
		Q "-1^"_ErrMsg_"^^"_FocusCol
	}
	//加工方式限定规则(项目用)
	s SubNode=CMPrescTypeCode
	if (PrescCookDecoction'="") s SubNode=SubNode_"^"_PrescCookDecoction
	s CookModePrescBound=##class(web.DHCDocOrderEntryCM).GetPrescBound(SubNode,LogonHospDr)
	if (CookModePrescBound'=""){
		s OnePrescWeight=PrescWeight/PrescDurFactor //前台PrescWeight乘了疗程,此处验证的是单处方，此处方中数量之和
		s PrescCookModeDesc=$G(^DHCDocConfig("HospDr_"_LogonHospDr,"CMPrescTypeList",CMPrescTypeCode))
		s PrescCookModeDesc=..%Translate("opdoc.oeorder.cmlistcustom.csp",PrescCookModeDesc)
		s PrescCookDecoctionDesc=""
		if PrescCookDecoction'="" s PrescCookDecoctionDesc=$P($g(^DHCDocConfig("HospDr_"_LogonHospDr,"CookMode",PrescCookDecoction)),"^",2)
		s PrescCookDecoctionDesc=..%Translate("opdoc.oeorder.cmlistcustom.csp",PrescCookDecoctionDesc)
		s UomRowid=$p(CookModePrescBound,"^",1)
		s PrescQtyStt=$p(CookModePrescBound,"^",2)
		s PrescQtyEnd=$p(CookModePrescBound,"^",3)
		s LessMinQtyNotAllowOrd=$p(CookModePrescBound,"^",4)
		s MoreMaxQtyNotAllowOrd=$p(CookModePrescBound,"^",5)
		s CalUomType=##class(DHCDoc.DHCDocConfig.CookModeCharge).GetCalUomType(UomRowid)
		s UomDesc=$ZCVT($p($g(^CT("UOM",UomRowid)),"^",1),"U")
		if (CalUomType="WeightUom"){
			s BaseUomRowId=##class(DHCDoc.DHCDocConfig.CookModeCharge).GetCMBaseUomRowId("WeightUom",LogonHospDr)
			s convqty=$$ConvFac^ST02(UomRowid,BaseUomRowId),convqty=$p(convqty,$c(1),1)
			if (convqty="") s convqty=1
			s PrescQtyStt=PrescQtyStt*convqty
			s PrescQtyEnd=PrescQtyEnd*convqty
			if ((+OnePrescWeight)<(+PrescQtyStt))&&(LessMinQtyNotAllowOrd=1){
				s ErrMsg=..%Translate("opdoc.oeorder.cmlistcustom.csp","小于")_PrescQtyStt_..%Translate("opdoc.oeorder.cmlistcustom.csp","g 不能使用这种煎药方式及处方类型:")_PrescCookDecoctionDesc_","_PrescCookModeDesc
				s OutInfo="-1^"_ErrMsg_"^^^^"
				Q OutInfo
			}elseif (((+OnePrescWeight)>(+PrescQtyEnd))&&(PrescQtyEnd'=""))&&(MoreMaxQtyNotAllowOrd=1){
				s ErrMsg=..%Translate("opdoc.oeorder.cmlistcustom.csp","大于")_PrescQtyEnd_..%Translate("opdoc.oeorder.cmlistcustom.csp","g 不能使用这种煎药方式及处方类型:"  )_PrescCookDecoctionDesc_","_PrescCookModeDesc
				s OutInfo="-1^"_ErrMsg_"^^^^"
				Q OutInfo
			}
		}else{
			s BaseUomRowId=##class(DHCDoc.DHCDocConfig.CookModeCharge).GetCMBaseUomRowId("DurUom",LogonHospDr)
			s convqty=$$ConvFac^ST02(UomRowid,BaseUomRowId),convqty=$p(convqty,$c(1),1)
			if (convqty="") s convqty=1
			s PrescQtyStt=PrescQtyStt*convqty
			s PrescQtyEnd=PrescQtyEnd*convqty
			if ((+PrescDurFactor)<(+PrescQtyStt))&&(LessMinQtyNotAllowOrd=1){
				s ErrMsg=..%Translate("opdoc.oeorder.cmlistcustom.csp","小于")_PrescQtyStt_..%Translate("opdoc.oeorder.cmlistcustom.csp","付 不能使用这种煎药方式及处方类型:")_PrescCookDecoctionDesc_","_PrescCookModeDesc
				s OutInfo="-1^"_ErrMsg_"^^^^"
				Q OutInfo
			}elseif (((+PrescDurFactor)>(+PrescQtyEnd))&&(PrescQtyEnd'=""))&&(MoreMaxQtyNotAllowOrd=1){
				s ErrMsg=..%Translate("opdoc.oeorder.cmlistcustom.csp","大于")_PrescQtyEnd_..%Translate("opdoc.oeorder.cmlistcustom.csp","付 不能使用这种煎药方式及处方类型:")_PrescCookDecoctionDesc_","_PrescCookModeDesc
				s OutInfo="-1^"_ErrMsg_"^^^^"
				Q OutInfo
			}
		}
	}	
	Q OutInfo
CheckCMBeforeSaveJsonObj(OutPutInfo,CallBackFunStr)
	s ErrCode=$P(OutPutInfo,"^",1)
	s ErrMsg=$P(OutPutInfo,"^",2)
	s cellPosi=$P(OutPutInfo,"^",3)
	s FocusCol=$P(OutPutInfo,"^",4)
	s NeedCheckDeposit=$P(OutPutInfo,"^",5)
	s ErrMsg=##class(ext.util.String).EvalJSON(ErrMsg)
	k OutPutDataArr
	s OutPutDataArr("ErrCode")=ErrCode
	s OutPutDataArr("ErrMsg")=ErrMsg
	s OutPutDataArr("cellPosi")=cellPosi
	s OutPutDataArr("FocusCol")=FocusCol
	s OutPutDataArr("NeedCheckDeposit")=NeedCheckDeposit
	s SubNodeNum=0
	s ^tempqujina("CallBackFunStr")=CallBackFunStr
	for i=1:1:$Length(CallBackFunStr,$C(2)){
		s SingleCallBackFun=$P(CallBackFunStr,$C(2),i)
		if (SingleCallBackFun=""){continue}
		s CallBakFunCode=$P(SingleCallBackFun,"^",1)
		s CallBakFunParams=$P(SingleCallBackFun,"^",2)
		s SubNodeNum=SubNodeNum+1
		s OutPutDataArr("CallBakFunS",SubNodeNum,"CallBakFunCode")=CallBakFunCode
		s OutPutDataArr("CallBakFunS",SubNodeNum,"CallBakFunParams")=CallBakFunParams
	}
	s OutPutDataJson=##Class(DHCDoc.Util.FromJSON).GetArrJson(.OutPutDataArr)
	q OutPutDataJson
}

// 判断一个数是不是由几个系数组合而来 

ClassMethod CheckSums(NumStr, Sum)
{
	n (NumStr, Sum)
    k Nums1
    s flag = 0
    s Len=$l(NumStr,"^")
    for k=1:1:Len {
	    s num=$p(NumStr,"^",k)
	    if ((+num) '= 0) {
            s Nums1(k)= (+num)
        } 
	}
	if ($o(Nums1(""),-1) =1 ){
		if ((Sum # Nums1(1)) = 0) {
            s flag = 1
        }
	}else{
		s flag = ..CheckSum(Sum, .Nums1, 1, "", Sum)	
	}
    Q flag
}

ClassMethod CheckSum(Sum, ByRef Nums, j, str1, Sum1)
{
    s rtn = ""
    if ((j + 1) > $o(Nums1(""),-1)) {
        Q 0
    }
    if ((+Sum) <= 0) {
        Q -1
    }
    s num1 = +(Nums(j))
    s num2 = +(Nums(j + 1))
    s Sum = +(Sum)
    s n1 = 0
    s i = 0
    s flag = 0
    while (1) {
        if (num1 <= 0) {
	        s rtn=0
            Q
        }
        if (num2 <= 0) {
            s rtn=0
            Q
        }
        if (Sum <= 0) {
            s rtn=0
            Q
        }
        s n1 = Sum - (num1 * i)
        if (n1 < 0) {
            s rtn=0
            Q
        }
        if (n1 # num1)=0 {
	        s rtn=1
            Q
	    }
        if (n1 # num2)=0 {
	        s rtn=1
            Q
	    }
        s n2 = n1 # num2
        if (n2 = 0) {
            s rtn=1
            Q
        } else {
            s flag = ..CheckSum(n1, .Nums, j + 1, str1, Sum1)
        }
        if (flag = 1) {
            s rtn=1
            Q
        }
        s i = i + 1
    }
    Q rtn
}

/// 判断科室是否是特殊科室发药
ClassMethod ChkLocIsSpeciadrug(PhaLoc As %String, DocLoc As %String) As %String
{
	Q:$o(^CTLOC(PhaLoc,"LINK",0,"Loc",DocLoc,""))'="" 1
	Q 0
}

/// 判断草药多库存项中，协议单位的转换组合数是否正确（并不是计算一品多规的库存项基本单位组合数）
/// input:OrderARCIMRowid 医嘱项id；SumQty 单次剂量数量（草药单位统一为药学项基本单位）；RecLocDr 接收科室id
/// output:ErrCode(0:校验通过，非0:失败)^ErrMsg
/// w ##Class(web.DHCOEOrdItem).CheckProtocolPackSum("8785||1",14,212)
ClassMethod CheckProtocolPackSum(OrderARCIMRowid As %String, SumQty As %String, RecLocDr As %String) As %String
{
	s OutInfo=0_"^^^^^"
	Set langid=..%LanguageID()
	s OrderName=$p(^ARCIM(+OrderARCIMRowid,$P(OrderARCIMRowid,"||",2),1),"^",2)
	s OrderName=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",OrderName,langid)
	if (+SumQty=0) {
		s ErrMsg=OrderName_..%Translate("opdoc.oeorder.cmlistcustom.csp","的数量不是有效数字,请检查!")
		Q "-1^"_ErrMsg
	}
	//判断数量是不是由药房系数组合
	s numStr=##class(web.DHCSTINTERFACE).GetDspUomFac(OrderARCIMRowid,RecLocDr)
	if (numStr'=""){
		if ((SumQty#1)>0){
			s ErrMsg=OrderName_..%Translate("opdoc.oeorder.cmlistcustom.csp","数量请输入整数!")
			Q "-1^"_ErrMsg
		}else{
			if (SumQty>99999){
				s ErrMsg=OrderName_..%Translate("opdoc.oeorder.cmlistcustom.csp","数量不能大于999999")
				Q "-1^"_ErrMsg
			}
		}
		
		s Checkflag=..CheckSums(numStr,SumQty)
		if (Checkflag=0){
			s RecLocDesc=$p(^CTLOC(RecLocDr),"^",2)
			s RecLocDesc=##class(User.CTLoc).GetTranByDesc("CTLOCDesc",RecLocDesc,langid)
			s numStrs=""
			for m=1:1:$l(numStr,"^") {
				if (numStrs=""){
					s numStrs=$p(numStr,"^",m)_"g"	
				}else{
					s numStrs=numStrs_","_$p(numStr,"^",m)_"g"	
				}
			}
			if ($l(numStrs,",")>1){
                //找最邻近的小数值,用于建议
                s tmpSum=SumQty,minNear=0
                while (minNear=0) {
                    s tmpSum=tmpSum-1
                    if (tmpSum<0) {
                        s minNear=-1
                        continue
                    }
                    if (..CheckSums(numStr, tmpSum)'=0) s minNear=tmpSum
                }
                if (minNear=-1) s minNear=""
                //找最邻近的大数值,用于建议
                s tmpSum=SumQty,maxNear=0
                while (maxNear=0) {
                    s tmpSum=tmpSum+1
                    if (..CheckSums(numStr, tmpSum)'=0) s maxNear=tmpSum
                }
            	s ErrMsg = OrderName _ RecLocDesc _ ..%Translate("opdoc.oeorder.cmlistcustom.csp","目前只能提供") _ numStrs _ ..%Translate("opdoc.oeorder.cmlistcustom.csp","整包装,请选择小包装组合数.与所开数量最邻近的小值为【")_minNear_..%Translate("opdoc.oeorder.cmlistcustom.csp", "】,大值为【")_maxNear_"】"
            }else{
	            s ErrMsg = OrderName _ RecLocDesc _ ..%Translate("opdoc.oeorder.cmlistcustom.csp","目前只能提供") _ numStrs _ ..%Translate("opdoc.oeorder.cmlistcustom.csp","整包装,请选择小包装组合数")
	        }
			Q "-1^"_ErrMsg
	   }
	}
    Q OutInfo
}

ClassMethod GetChckOrdItemName(OrdItem As %String, OrdItemStr As %String) As %String
{
	n (OrdItem,OrdItemStr,%session)
	s ARCIMRowid=$P(OrdItem,"^",1)
	Set langid=..%LanguageID()
	s OrderName=$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",2)
	s OrderName=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",OrderName,langid)
	s OEORIBindSource=$p(OrdItem,"^",58) //医嘱绑定来源
	s OrdRowIndex=$p(OrdItem,"^",66)	//实际的行号
	if (OEORIBindSource'="") {
		s BindSourceDesc=##class(web.DHCDocQryOEOrder).GetBindSourceDescByCode(OEORIBindSource)
		for i=1:1:$length(OrdItemStr,$C(1)){
			s LoopOrdItem=$P(OrdItemStr,$C(1),i)
			continue:LoopOrdItem=""
			s LoopOrdRowIndex=$p(LoopOrdItem,"^",66)
			if (OrdRowIndex=LoopOrdRowIndex) {
				s LoopARCIMRowid=$P(LoopOrdItem,"^",1)
				s MatserOrderName=$p(^ARCIM(+LoopARCIMRowid,$p(LoopARCIMRowid,"||",2),1),"^",2)
				s MatserOrderName=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",MatserOrderName,langid)
				Q
			}
		}
		s OrderName=MatserOrderName_..%Translate("oeorder.oplistcustom.new.csp"," 通过 "_BindSourceDesc_" 的【")_OrderName_"】"
	}
	Q OrderName
}

ClassMethod CompareDateTime(CheckDate As %String, CheckTime As %String, CompareDate As %String, CompareTime As %String) As %String
{
	Q:(CheckDate="")&&(CheckTime="")&&(CompareDate="")&&(CompareTime="") 0
	i $l(CheckDate,"-")=3 s CheckDate=$zdh(CheckDate,3)
	i $l(CheckDate,"/")=3 s CheckDate=$zdh(CheckDate,4)
	i CheckTime[":" s CheckTime=..%ZTH(CheckTime)
	
	i $l(CompareDate,"-")=3 s CompareDate=$zdh(CompareDate,3)
	i $l(CompareDate,"/")=3 s CompareDate=$zdh(CompareDate,4)
	i CompareTime[":" s CompareTime=..%ZTH(CompareTime)
	
	Q:(CheckDate>CompareDate) 1
	Q:(CheckDate=CompareDate)&&(CheckTime>CompareTime) 1
	Q 0
}

ClassMethod GetItemNotLimitQtyFlag(ARCIMRowid)
{
	n (ARCIMRowid)
	s DARCIMRowid=$O(^DHCItmMast("0","ARCIM",ARCIMRowid,0))
	s NotLimitQty=$P($G(^DHCItmMast(+DARCIMRowid)),"^",30)
	Q NotLimitQty
}

ClassMethod CheckConflict(Adm As %String, OrdItem As %String, SessionStr As %String, ByRef CallBackFunStr As %String = "") As %String
{
	n (Adm,OrdItem,SessionStr,CallBackFunStr,%session)
	s CurLogonHosp=$P(SessionStr,"^",4)
	s langid=$p(SessionStr,"^",6)
	s OutInfo=0
	s ARCIMRowid=$P(OrdItem,"^",1)
	s PriorRowid=$p(OrdItem,"^",3)
	s OrderStartDate=$p(OrdItem,"^",4)
	s OrderStartTime=$p(OrdItem,"^",5)
	s ret=##class(DHCDoc.DHCDocConfig.ARCIMExt).CheckConflict(Adm,ARCIMRowid,OrderStartDate,OrderStartTime,PriorRowid,CurLogonHosp,langid)
    s ConflictFlag = $P(ret, "^", 1)
    if (ConflictFlag = "Y") {
        s CallBackFunParams = $P(ret, "^", 2)
        s ConflictType=$P(ret, "^", 3)
        s ArcimDescStr=$P(ret, "^", 4)
        if " AF DF "[(" "_ConflictType_" "){
            s OutInfo="-1^"_CallBackFunParams_"^^"_"OrderName"
        }elseif " S "[(" "_ConflictType_" "){
	        s OutInfo="0^"_ArcimDescStr
	    }else{
		    ;审核时 提示类不再弹出
        	;s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
        }
    }
	Q OutInfo
}

/// 将医嘱的自定义分发时间或周频次转成前端录入OrderFreqDispTimeStr字段
ClassMethod GetOrdFrqTimeInfoForEntry(OrdItemID)
{
	n (OrdItemID)
	s ret=""
	s Ord=+OrdItemID,Sub=$P(OrdItemID,"||",2)
	s FreqFreeTimeStr=$P($G(^OEORD(Ord,"I",Sub,"DHC")),"^",68)
	s FreqWeekStr=$P($G(^OEORD(Ord,"I",Sub,"DHC")),"^",55)
	s i=0 for{
		s i=i+1
		s DispTime=$P(FreqFreeTimeStr,"|",i)
		s FreqWeek=$P(FreqWeekStr,"|",i)
		Q:(DispTime="")&&(FreqWeek="")
		s PHCDTRowID=""
		if DispTime'=""{
			s OrderFreqRowid=$P($G(^OEORD(Ord,"I",Sub,2)),"^",4)
			&SQL(SELECT PHCDT_RowId INTO :PHCDTRowID FROM SQLUser.PHC_DispensingTime WHERE PHCDT_PHCFR_ParRef=:OrderFreqRowid AND PHCDT_Time=:DispTime)
			s PHCDTRowID=$Replace(PHCDTRowID,"||","_")
		}
		s str=DispTime_$C(2)_FreqWeek_$C(2)_PHCDTRowID
		i ret="" s ret=str
		e  s ret=ret_$C(1)_str
	}
	Q ret
}

/// /w ##Class(web.DHCOEOrdItem).CheckOMOrderContral("892||1","2","80")
ClassMethod CheckOMOrderContral(ArcimRowid As %String, HospId As %String, LocId As %String) As %String
{
	s ^tmp("CheckOMOrderContral")=$LB(ArcimRowid,HospId,LocId)
	i ($g(HospId)="")&&($d(%session)) s HospId=%session.Get("LOGON.HOSPID")
	Set langid=..%LanguageID()
	s LocIdStr="^"_LocId_"^"
	s HospCodeNode="HospDr_"_HospId
	s Value="OMLimitOrder"
	s LimitFlag=""
	s OrderName=$p($g(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),1)),"^",2)
	s OrderName=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",OrderName,langid)
	s Index=""
	for {
		s Index=$O(^DHCDocConfig(HospCodeNode,Value,"Item",Index))
		q:(Index="")
		s Item=$G(^DHCDocConfig(HospCodeNode,Value,"Item",Index))
		continue:(Item="")
		i ArcimRowid=Item s LimitFlag="Y" q
	}
	q:LimitFlag="Y" "-1^"_..%Translate("oeorder.oplistcustom.new.csp","医嘱：")_OrderName_..%Translate("oeorder.oplistcustom.new.csp","不能开立自备药！")
	s ItemCatRowid=$p($g(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),1)),"^",10)
	q:ItemCatRowid="" 0
	s ItemCatDesc=$P(^ARC("IC",ItemCatRowid),"^",2)
	Set ItemCatDesc= ##class(User.ARCItemCat).GetTranByDesc("ARCICDesc",ItemCatDesc,langid)
	s OMOrderLimitCatListStr=..%GetConfig("OMOrderNotItemCat",HospId)
	s OMOrderLimitCatListStr="^"_OMOrderLimitCatListStr_"^"
	s OMOrderLimitCatLessLocStr=##class(DHCDoc.DHCDocConfig.OrderOMPrior).GetLessLocConfig("OMOrderNotItemCat",ItemCatRowid,HospId)
	s:OMOrderLimitCatLessLocStr'="" OMOrderLimitCatLessLocStr="^"_OMOrderLimitCatLessLocStr_"^"
	if (OMOrderLimitCatListStr[("^"_ItemCatRowid_"^"))&&(ItemCatRowid'="") {
		Q:OMOrderLimitCatLessLocStr="" "-1^"_..%Translate("oeorder.oplistcustom.new.csp","医嘱：")_OrderName_..%Translate("oeorder.oplistcustom.new.csp","子类为")_"<font style='color:red;'>"_ItemCatDesc_"</font>"_..%Translate("oeorder.oplistcustom.new.csp","不允许开立自备药！")
		if (OMOrderLimitCatLessLocStr'[("^"_LocId_"^"))&&(LocId'="") q "-1^"_..%Translate("oeorder.oplistcustom.new.csp","医嘱：")_OrderName_..%Translate("oeorder.oplistcustom.new.csp","子类为")_"<font style='color:red;'>"_ItemCatDesc_"</font>"_..%Translate("oeorder.oplistcustom.new.csp","不允许开立自备药！")
	}
	b ;
	s PoisonRowid=##class(web.DHCDocOrderEntry).GetDrgFormPoison(ArcimRowid)
	q:PoisonRowid="" 0
	s PHCPODesc=$p($g(^PHCPO(DrgFormPoison)),"^",2)
	s PHCPODesc=##class(User.PHCPoison).GetTranByDesc("PHCPODesc",PHCPODesc,langid)
	s OMOrderLimitPoisonListStr=..%GetConfig("OMOrderNotPoison",HospId)
	s OMOrderLimitPoisonListStr="^"_OMOrderLimitPoisonListStr_"^"
	s OMOrderLimitPoisonLessLocStr=##class(DHCDoc.DHCDocConfig.OrderOMPrior).GetLessLocConfig("OMOrderNotPoison",PoisonRowid,HospId)
	s:OMOrderLimitPoisonLessLocStr'="" OMOrderLimitPoisonLessLocStr="^"_OMOrderLimitPoisonLessLocStr_"^"
	if (OMOrderLimitPoisonListStr[("^"_PoisonRowid_"^"))&&(PoisonRowid'="") {
		Q:OMOrderLimitPoisonLessLocStr="" "-1^"_..%Translate("oeorder.oplistcustom.new.csp","医嘱：")_OrderName_..%Translate("oeorder.oplistcustom.new.csp","管制分类为")_"<font style='color:red;'>"_PHCPODesc_"</font>"_..%Translate("oeorder.oplistcustom.new.csp","不允许开立自备药！")
		if (OMOrderLimitPoisonLessLocStr'[("^"_LocId_"^"))&&(LocId'="") Q "-1^"_..%Translate("oeorder.oplistcustom.new.csp","医嘱：")_OrderName_..%Translate("oeorder.oplistcustom.new.csp","管制分类为")_"<font style='color:red;'>"_PHCPODesc_"</font>"_..%Translate("oeorder.oplistcustom.new.csp","不允许开立自备药！")
	}
	q 0
}

ClassMethod CheckOMOrderOtherContral(Adm As %String, OrdItem As %String, CheckExpStr As %String, ByRef CallBackFunStr As %String) As %String
{
	n (Adm, OrdItem, CheckExpStr,CallBackFunStr,%session)
	s PAADMType=$p($g(^PAADM(Adm)),"^",2)
	s ARCIMRowidStr=$P(CheckExpStr,$C(2),1)
	s CurLogonLocId=$P(CheckExpStr,$C(2),2)
	s CurLogonHospId=$p($g(^CTLOC(CurLogonLocId)),"^",22)
	s ARCIMRowid=$P(OrdItem,"^",1)
	s OrderType=$P(OrdItem,"^",2)
	s PriorRowid=$p(OrdItem,"^",3)
	Set PackQty=$p(OrdItem,"^",6)
	Set AdmReason=$replace($p(OrdItem,"^",9),$c(10),"")
	Set DoseQty=$p(OrdItem,"^",12)
	Set DoseUOMRowid=$p(OrdItem,"^",13)
	Set FreqRowid=$p(OrdItem,"^",15)
	Set DurRowid=$p(OrdItem,"^",16)
	Set InstrRowid=$p(OrdItem,"^",17)
	Set OrderPackUOMRowid=$p(OrdItem,"^",55)
	s ItemCatRowid=$p($g(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1)),"^",10)
	s PriorCode=""
	s:PriorRowid'="" PriorCode=$p($g(^OECPR(PriorRowid)),"^",1)
	s OrderName=$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",2)
	q:(PriorCode'="OM")&&(PriorCode'="OMST") "0^^^"
	;医生站设置菜单->医嘱/药学项设置->自备药医嘱扩展设定
	s OutInfo=0
 	s CheckOMOrderOtherInfo=..CheckOMOrderContral(ARCIMRowid,CurLogonHospId,CurLogonLocId)
	if (+CheckOMOrderOtherInfo'=0){
		s OutInfo="-1^" _$P(CheckOMOrderOtherInfo,"^",2)
		s $P(OutInfo,"^",4)="OrderName"
		q OutInfo
	}
	
	q "0^^^"
}

/// 校验死亡医嘱的日期时间是否合理
/// w ##Class(web.DHCOEOrdItem).CheckOrderDeathDateTime("2023-02-01!19:45","8043||1","^^^^2")
ClassMethod CheckOrderDeathDateTime(DeathDateTime As %String, ArcimID As %String, SessionStr As %String) As %String
{
	n (DeathDateTime,ArcimID,SessionStr)
	s ^templx("CheckOrderDeathDateTime")=$lb(DeathDateTime,ArcimID,SessionStr)
	s ErrInfo=""
	s HospID=$p(SessionStr,"^",4)
	s langid=$p(SessionStr,"^",6)
	s DeathDate=$p(DeathDateTime,"!",1)
	s DeathTime=$p(DeathDateTime,"!",2)
	s DeathDate=..%ZDH(DeathDate)
	s DeathTime=..%ZTH(DeathTime)
	s DiffSecond=##class(DHCDoc.Util.Date).GetDiffSecond(DeathDate_","_DeathTime,$h,"S")
	if (DiffSecond<0){
		s ErrInfo=..%Translate("dhcdoc.stopafterlongordcondition.csp","死亡时间不能晚于当前时间!",langid)
	}
	Q:ErrInfo'="" "-1^"_ErrInfo
	
	;获取护士站死亡医嘱的可提前时间判断
	s LimitDays=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("DeathOrdLimitDays",ArcimID, HospID)
	if (LimitDays>0){
		s DiffDays=##class(DHCDoc.Util.Date).GetDiffSecond(DeathDate_","_DeathTime,$h,"D")
		if (DiffDays>LimitDays){
			s ErrInfo=..%Translate("dhcdoc.stopafterlongordcondition.csp","死亡日期不能早于当前时间的",langid)_LimitDays_..%Translate("dhcdoc.stopafterlongordcondition.csp","天!",langid)
		}
	}
	Q:ErrInfo'="" "-1^"_ErrInfo
	Q "0^"
}

}
