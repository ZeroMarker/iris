/// Creator:      周志强
/// CreatDate:    2012.03.06
/// Description:  用于发药记录处理的公共服务类
Class appcom.OEDispensing Extends DHCDoc.Util.RegisteredObject [ ClassType = "", ProcedureBlock ]
{

ClassMethod Insert(oeore As %String, seqno As %String) As %String
{
	
	s oeitm=$P(oeore,"||",1,2)
	s arcim=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),1)),"^",2)
	Q:arcim="" 0

	s AdmID=$p(^OEORD(+oeore),"^",1)
	s AdmType=$p($g(^PAADM(AdmID)),"^",2)
	
	;不发药的医嘱类型不用产生配药记录
	;s PriorityDR=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),1)),"^",8)
	;if ##class(appcom.OEOrdItem).ISUnDspOrderPrior(PriorityDR) Q 0
	
	s INCIrow=..GetINCI(+arcim)
	Q:INCIrow="" 0

	s DateAdd=..%SysDate()
	s TimeAdd=..%SysTime()
	s DateExe=$P(^OEORD(+oeore,"I",$P(oeore,"||",2),"X",$P(oeore,"||",3)),"^",1)
	s TimeExe=$P(^OEORD(+oeore,"I",$P(oeore,"||",2),"X",$P(oeore,"||",3)),"^",2)
	
	s drgform=$p($g(^ARCIM(+arcim,+$p(arcim,"||",2),1)),"^",12)
	s arcgrp=$p(^ARCIM(+arcim,$p(arcim,"||",2),1),"^",10)
	s cattype=$p(^ARC("IC",arcgrp),"^",7)
	s priorid=$p($g(^OEORD(+oeitm,"I",$P(oeitm,"||",2),1)),"^",8)
	s PackQty=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),9)),"^",4)
	s OEORIUserDepDR=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),7)),"^",2)
	s OEORIUserHospDr=$p($g(^CTLOC(OEORIUserDepDR)),"^",22)
	;协议单位
	s ProtocolPackUOMDR=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),"DHC")),"^",13)
	s phqtyord=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),1)),"^",12)
	s doseqty=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),2)),"^",1)
	s OEOREPhQtyOrd=$p($g(^OEORD(+oeore,"I",+$p(oeore,"||",2),"X",+$p(oeore,"||",3))),"^",4)
	if (+OEOREPhQtyOrd'=0) s doseqty=OEOREPhQtyOrd
	s uom=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),2)),"^",3)
	s recloc=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),3)),"^",6)
	s baseuom=$$baseuom^DHCDocOrderCommonNew(arcim)
	s CheckCHNFlag=##class(web.DHCSTINTERFACE).GetStruModeFlag(arcim)
	if CheckCHNFlag="Y" {
		S Phcdf=$P($g(^ARCIM(+arcim,$P(arcim,"||",2),1)),"^",12)
	    if (Phcdf'="") s baseuom=$p(^PHCD(+Phcdf,"DF",$p(Phcdf,"||",2),2),"^",4)
	}
	s FirstDayTimes=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),1)),"^",18)
	s:'doseqty doseqty=1 ;Dose Qty
	s OrdStartDate=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),1)),"^",9)
	s OrdStartTime=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),1)),"^",10)
	s OrderInsertDate=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),1)),"^",19)
	s OrderInsertTime=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),1)),"^",20)

	s PriorityDR=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),1)),"^",8)
 	s PriorityCode=$p(^OECPR(PriorityDR),"^",1)
	s FreqFactor=1
 	s Freq=$P($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),2)),"^",4)
 	i Freq'="" s FreqFactor=$P($g(^PHCFR(Freq)),"^",2)
 	s DurFactor=1
	s Dur=$P($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),2)),"^",6)
 	i Dur'="" s DurFactor=$p($g(^PHCDU(Dur)),"^",2)
 	s OrderFreqWeek=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),"DHC")),"^",55)
	i cattype="R"{
		i PackQty="" {
			/*
			//pb by tanjishan 2020.05.11
			//出院带药和取药医嘱的执行记录数量（OEORE_PhQtyOrd）都是按照OEORI_PhQtyOrd插入的，OEORI_PhQtyOrd即DoseSum，不需要再乘以Nums
			if (PriorityCode="OUT")||(PriorityCode="ONE") {
				//s Nums=$$CalcuQty^DHCDocOrderCommon(Freq,Dur,OrdStartDate)
				s Nums=$$CalcuQty^DHCDocOrderCommonNew(Freq,Dur,OrdStartDate,FirstDayTimes,OrderFreqWeek)
				//s doseqty=doseqty*FreqFactor*DurFactor
				s doseqty=doseqty*Nums
			}
			*/
			s dispqty=$$calcqty^DHCOEOrdItem(drgform,uom,doseqty,AdmType)
			s TotalQty=dispqty
		}else{
			s convFac=##class(appcom.OEDispensing).convFac(arcim,ProtocolPackUOMDR)
			s dispqty=PackQty*convFac
			s TotalQty=dispqty
		}
	}else{
		i phqtyord="" s phqtyord=1
		s freqid=$p($g(^OEORD(+oeitm,"I",$P(oeitm,"||",2),2)),"^",4)
		s doseqty=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),2)),"^",1)
		i ##class(appcom.OEOrdItem).ISShortOrderPrior(priorid)||(freqid="")||(+doseqty=0) {
			;基本单位和计价单位不一致需要将数量从计价单位换算为基本单位
			s convFac=##class(appcom.OEDispensing).convFac(arcim,ProtocolPackUOMDR)
			i convFac="" s convFac=1
			s dispqty=phqtyord*convFac
			s TotalQty=phqtyord*convFac
		}else{
			s dispqty=doseqty
			s TotalQty=doseqty
		}
	}
	if (dispqty[".") s dispqty=$fn(dispqty,"",4)
	if (TotalQty[".") s TotalQty=$fn(TotalQty,"",4)
	
	s Adm=$P(^OEORD(+oeore),"^",1)
	s admloc=$p(^PAADM(Adm),"^",4)
	s HospitalId=$p($G(^CTLOC(admloc)),"^",22)
	s EpLoc=admloc
	s admType=$P($g(^PAADM(Adm)),"^",2)
	if admType="I" s EpLoc=$P(^PAWARD($P($g(^PAADM(Adm)),"^",70)),"^",5)
	k OEDISP 
	s OEDISP(2)=oeitm,OEDISP(4)=oeore
	s OEDISP(5)=seqno
	s OEDISP(6)=+dispqty,OEDISP(7)=baseuom,OEDISP(8)="TC",OEDISP(12)=+dispqty
	s OEDISP(16)=DateAdd,OEDISP(17)=TimeAdd
	S OEDISP(3)=+TotalQty
	s OEDISP(21)=TimeExe,OEDISP(22)=DateExe
	s OEDISP(23)=EpLoc,OEDISP(24)=admloc
	s OEDISP(25)=recloc
	s PYFlag=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),"DHC")),"^",16) ;静脉配液标志
	s:PYFlag="" PYFlag="N"
	;长期医嘱判断首日输液配置
	if ##class(DHCDoc.Order.Common).IsLongOrdItem(oeitm){
		s GetFirstDayRecLoc=..GetFirstDaySetting(Adm,arcim,recloc,DateExe,TimeExe,.PYFlag,..%ZD(OrderInsertDate),..%ZT(OrderInsertTime))
		i GetFirstDayRecLoc'="" s OEDISP(25)=GetFirstDayRecLoc
	}
	s OEDISP(27)=Adm
	s OEDISP(28)=##class(web.DHCSTCOMMONSRV).GetDspCatId(oeitm,PYFlag,OEDISP(25))
	s INICPackComb=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),"DHC")),"^",56)
	s ImportINCI=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),"DHC")),"^",64)
	i INICPackComb="" {
		;现在西药没有在OE_OrdItem上存储库存id与数量的组合,按医嘱项与库存项目一对一处理
		if (ImportINCI'=""){
			s INICRow=ImportINCI
		}else{
			s INICRow=..GetINCI(+arcim)
		}
		s INICPackComb=INICRow_"!"_(+TotalQty)
	}
	s OEDISP(31)=INICPackComb
	;判断是否为基数药
	s InUseDep=""
	s ordDept = $p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),7)),"^",2)
	s instrDr = $p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),2)),"^",7)
	s InUseDep=##class(PHA.FACE.OUT.Com).GetBaseMedUseLoc(admType,ordDept,arcim,instrDr,recloc)
	s OEDISP(26)=InUseDep
	s OrdInsertDate=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),1)),"^",19)
	;药房长嘱单独记录标识
	if (OrdInsertDate=+$H)&&##class(DHCDoc.Order.Common).IsLongOrdItem(oeitm){
		s FirstDayOrdSplit=##class(web.DHCDocConfig).GetConfigNode("FirstDayOrdSplit",HospitalId)
		s SplitDateTime=##class(PHA.FACE.OUT.Com).GetLongFirstDayDate(arcim,OEDISP(25))
		if (SplitDateTime'="")&&(FirstDayOrdSplit'="Split"){
			s SplitDate=..%ZDH($p(SplitDateTime,"^",1))
			s SplitTime=..%ZTH($p(SplitDateTime,"^",2))
			if (DateExe<SplitDate)||((DateExe=SplitDate)&&(TimeExe<SplitTime)){
				s OEDISP(34)="Y"
			}
		}
	}
    &SQL(Insert into SQLUser.DHC_OEDispensing values :OEDISP())
    
    s DspRowId=""
    i 'SQLCODE s DspRowId=$p(%ROWID,$C(1))
    
	/*-------------------------------------------------------------------
	1.处理批次和在途,统一到##class(web.DHCOEDispensing).PortForDurg方法中
	2.材料减库存
	以上两点处理都在InsOEORE^DHCOEOrdExec.mac中调用,放到事务外,做统一错误记录
	*/
	Q SQLCODE_"^"_DspRowId
}

/// 获取长期当日配液接收科室
/// w ##Class(appcom.OEDispensing).GetFirstDaySetting("1593","1067||1","186","66375","5505","Y","2022-09-22","09:31:45")
ClassMethod GetFirstDaySetting(AdmId, ArcimId, RecLoc, ExcuteDate, ExcuteTime, PYFlag, OrderInsertDate As %String = "", OrderInsertTime = "")
{
	
	s FirstDayRecLoc=""
	Q:(AdmId="")||(ArcimId="") FirstDayRecLoc
	Q:"R"'=##class(web.DHCDocOrderCommon).GetOrderType(ArcimId) FirstDayRecLoc

	s HospDr=##class(DHCDoc.Common.Hospital).GetLocHospitalId(RecLoc)
	s IPDosingRecLoc=##Class(DHCDoc.DHCDocConfig.DocConfig).GetDosingRecLocStr(HospDr)
	Q:("^"_IPDosingRecLoc_"^")'[("^"_RecLoc_"^") FirstDayRecLoc
	s ExcuteDate=..%ZDH(ExcuteDate),ExcuteTime=..%ZTH(ExcuteTime)
	if (OrderInsertDate=""){
		s OrderInsertDate=..%SysDate()
	}else{
		s OrderInsertDate=..%ZDH(OrderInsertDate)
	}
	if (OrderInsertTime=""){
		s OrderInsertTime=..%SysTime()
	}else{
		s OrderInsertTime=..%ZTH(OrderInsertTime)
	}
	
	//插入日期第三日的执行记录，肯定要接受到原接受科室
	if (ExcuteDate>(OrderInsertDate+1)){
		q FirstDayRecLoc
	}
	;配液开始时间点
	s DosingStartTime=..%ZTH(##Class(web.DHCDocConfig).GetConfigNode3("IPDosingRecLoc",RecLoc,"DosingStartTime",HospDr))
	;配液结束时间点
	s DosingEndTime=..%ZTH(##Class(web.DHCDocConfig).GetConfigNode3("IPDosingRecLoc",RecLoc,"DosingEndTime",HospDr))
	;隔日配液
    s IPDosingNextDay=##Class(web.DHCDocConfig).GetConfigNode3("IPDosingRecLoc",RecLoc,"IPDosingNextDay",HospDr)
	;按上下班时间修改静配接受科室
	s IPDosingTodayRecLoc=##Class(web.DHCDocConfig).GetConfigNode3("IPDosingRecLoc",RecLoc,"IPDosingTodayRecLoc",HospDr)
	
	if IPDosingTodayRecLoc=1{
		;跨日补开到静配的医嘱一律接收到默认药房
		if (OrderInsertDate>ExcuteDate){
			d GetDefRecLoc
		}
		;当日配液医嘱开立时间在静配工作周期内，则静配上班之前的配液执行记录都由静配接收，即静配上班之前的配液有默认接受科室发放
		if ((OrderInsertDate=ExcuteDate)&&(OrderInsertTime<=DosingEndTime)&&(ExcuteTime<DosingStartTime)){
			d GetDefRecLoc
		}
		;当日配液医嘱开立时间在静配下班之后，则静配次日上班之前的配液执行记录都由默认接受科室接收，即静配次日上班之后才会配置要求执行时间在上班之后的液体
		if (OrderInsertTime>DosingEndTime)&&
			(((OrderInsertDate=ExcuteDate))
			||(((OrderInsertDate+1)=ExcuteDate)&&(ExcuteTime<DosingStartTime))){
			d GetDefRecLoc
		}
	}elseif (IPDosingNextDay=1){
		//在下一个配液开始时间点前的执行记录需要拆分到默认接收科室
		if (OrderInsertDate>=ExcuteDate)
			||(((OrderInsertDate+1)=ExcuteDate)&&(ExcuteTime<DosingStartTime)){
			d GetDefRecLoc
		}
	}
	Q FirstDayRecLoc
GetDefRecLoc
	s FirstDayRecLoc=$$GetRecloc^DHCDocOrderCommonNew(AdmId,ArcimId)
	s PYFlag="N"
	Q
}

ClassMethod Return(oeore As %String) As %String
{
	s DSPRowId=$O(^DHCOEDISQTY(0,"OEORE",oeore,0))
	While (DSPRowId'="") {
		s DSPStatus=$P(^DHCOEDISQTY(DSPRowId),"^",7)
		if DSPStatus="TC" {
			s DSPQty=$P(^DHCOEDISQTY(DSPRowId),"^",5)
			s DSPQty=-DSPQty
			;处理批次和在途
  			s Rtn=##class(web.DHCOEDispensing).PortForDurg("I","",oeore,2,"")
			//d ..reserve(oeore,DSPQty)
		}
		s DSPRowId=$O(^DHCOEDISQTY(0,"OEORE",oeore,DSPRowId))
	}
	//材料反库存调用
	d ##class(appcom.OEOrdItem).ReturnMaterial(oeore)
}

/// w ##class(appcom.OEDispensing).Pack("77073||1||2")
ClassMethod Pack(oeore As %String) As %String
{
	s DSPRowId=$O(^DHCOEDISQTY(0,"OEORE",oeore,0))
	While (DSPRowId'="") {
		s DSPStatus=$P(^DHCOEDISQTY(DSPRowId),"^",7)
		if DSPStatus="TC" {
			s DSPQty=$P(^DHCOEDISQTY(DSPRowId),"^",5)
			s DSPQty=DSPQty
			;处理批次和在途
  			s Rtn=##class(web.DHCOEDispensing).PortForDurg("I","",oeore,1,"")
			//d ..reserve(oeore,DSPQty)
		}
		s DSPRowId=$O(^DHCOEDISQTY(0,"OEORE",oeore,DSPRowId))
	}
	q 0
}

ClassMethod reserve(oeore As %String, qty As %String)
{
	s arcim=$P(^OEORD(+oeore,"I",$P(oeore,"||",2),1),"^",2)
	s recloc=$P(^OEORD(+oeore,"I",$P(oeore,"||",2),3),"^",6)
	q:recloc=""
	s arcim1=$p(arcim,"||")
	s inci=..GetINCI(arcim1) 
	q:inci=""
	;s incil=..GetINCIL(inci,recloc) 
	;q:incil=""
	Q:(qty="")||(qty=0)
	d ##class(web.DHCST01).UPDINVRESQTY(inci,recloc,qty)
	;s err=..UpdRes(incil,qty)
	;材料减库存
	d ##class(appcom.OEOrdItem).DispMaterial(oeore)
}

ClassMethod GetINCI(ARCIMsub) As %String
{
	;w ##class(web.DHCOEDispensing).GetINCI(4975)
	s ARCIMsub=$p(ARCIMsub,$c(1))
	s INCIrow=$o(^INCI(0,"ARCIM_DR",ARCIMsub,""))
	q $g(INCIrow)
}

ClassMethod GetINCIL(inci As %String, stk As %String) As %String
{
	s inci=$p(inci,$c(1))
	s stk=$p(stk,$c(1))
	&SQL(Select INCIL_RowId into :INCILrow From SQLUser.INC_ItmLoc 
		Where INCIL_INCI_Parref=:inci and INCIL_CTLOC_DR=:stk)
	q $g(INCILrow)
}

ClassMethod Collected(oeore As %String) As %Boolean
{
	;仅限药品需要判断
	s ARCIMrow=$p(^OEORD(+oeore,"I",$p(oeore,"||",2),1),"^",2)
	s arcgrp=$p(^ARCIM(+ARCIMrow,$p(ARCIMrow,"||",2),1),"^",10)
	s cattype=$p(^ARC("IC",arcgrp),"^",7)
	Q:cattype'="R" 0
	/*s DSPRowId=$O(^DHCOEDISQTY(0,"OEORE",oeore,0))
	if (DSPRowId'="") {
		s DSPStatus=$P(^DHCOEDISQTY(DSPRowId),"^",7)
		if DSPStatus="C" Q 1
	}*/
	;改用药房接口 减去已退数量
	s DspData=##class(PHA.FACE.OUT.Com).GetOeoreQtyData(oeore)
	s DspQty=$P(DspData,"^",2)-$P(DspData,"^",3)
	Q DspQty>0
}

ClassMethod convFac(ArcimRowid As %String, ProtocolPackUOMDR As %String)
{
	;s baseuom=$$baseuom^CHB02(ArcimRowid)
	Set inci=$o(^INCI(0,"ARCIM_DR",+ArcimRowid,""))
	Quit:inci="" 1
	s CheckCHNFlag=##class(web.DHCSTINTERFACE).GetStruModeFlag(ArcimRowid)
	Quit:CheckCHNFlag="Y" 1
	Set baseuom=$p(^INCI(inci,1),"^",10)
	i ProtocolPackUOMDR'="" s billuom=ProtocolPackUOMDR
	e  s billuom=$p(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),8),"^",14)
	s convqty=$$ConvFac^ST02(billuom,baseuom),convqty=$p(convqty,$c(1),1)
	Q convqty
}

}
