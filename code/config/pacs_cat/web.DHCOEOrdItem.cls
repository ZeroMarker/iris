Class web.DHCOEOrdItem Extends %RegisteredObject
{
ClassMethod CheckPackQtyUpdate(Adm As %String, OrdItem As %String, CheckExpStr As %String, ByRef CallBackFunStr As %String) As %String
{
	n (Adm,OrdItem,CheckExpStr,CallBackFunStr)
	s IPNeedBillQtyFlag=$P(CheckExpStr,"^",1)
	s CurLogonDep=$P(CheckExpStr,"^",2)
	s CurLogonHosp =$p(^CTLOC(CurLogonDep),"^",22)
	s PAADMType=$p($g(^PAADM(Adm)),"^",2)
	s PAADMInsType=$P(^PAADM(Adm,1),"^",7)
	s VisitStatus=$p($g(^PAADM(Adm)),"^",20)
	s ARCIMRowid=$P(OrdItem,"^",1)
	s OrderType=$P(OrdItem,"^",2)
	s PriorRowid=$p(OrdItem,"^",3)
	Set PackQty=$p(OrdItem,"^",6)
	Set RecDepRowid=$p(OrdItem,"^",8)
	Set DoseQtySum=$p(OrdItem,"^",14)
	Set OrderNeedPIVAFlag=$p(OrdItem,"^",48)
	if (OrderType'="R"){
		s PackQty=DoseQtySum
	}
	s OrderVirtualtLong=$p(OrdItem,"^",79)
	s ItemCatRowid=$p($g(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1)),"^",10)
	s OrderName=$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",2)
	s PriorCode=$p($g(^OECPR(PriorRowid)),"^",1)
	s AdmDepDr=$p($g(^PAADM(Adm)),"^",4)
	s AdmDepHospId=$p(^CTLOC(AdmDepDr),"^",22)
	
	;出院带药必须录入整包装
 	s OutOrderNeedPackQty=..%GetConfig("OutOrderNeedPackQty",CurLogonHosp)
 	;住院是否需要录入整包装数量 
	s IPNeedBillQty=##Class(web.DHCDocOrderCommon).GetARCIMIPNeedBillQty(ARCIMRowid)
	if (OrderNeedPIVAFlag="Y"){
		s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"EmptyPackQty","")
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
			s OutInfo="-1^" _OrderName _"的数量不是有效数字,请检查"
			s $P(OutInfo,"^",4)="OrderPackQty"
			q OutInfo
		}
		if (OrderType'="R"){
			//医嘱项扩展设定->检查检验不控制数量
			
			s NotLimitQty=..GetItemNotLimitQtyFlag(ARCIMRowid)
			
			//检查检验不控制数量子类
			s NotLimitQtySubCat=..GetItemNotLimitQtySubCatFlag(ARCIMRowid)
			if (NotLimitQtySubCat="Y") {
				s NotLimitQty=NotLimitQtySubCat
			}
			
			if ((OrderType = "L") && (PackQty'= 1)&&(NotLimitQty'="Y")) {
				s OutInfo="-1^" _OrderName _" 检验医嘱数量只能为1,请确认."
				s $P(OutInfo,"^",4)="OrderPackQty"
				q OutInfo
			}
			; 得到是否是或者有检查医嘱标识
 			s ItemServiceFlag=##Class(web.DHCDocOrderCommon).GetItemServiceFlag(ARCIMRowid)
 			if (ItemServiceFlag=1)&&(PackQty'=1)&&(NotLimitQty'="Y"){
	 			s OutInfo="-1^" _OrderName _" 检查医嘱数量只能为1,请确认."
				s $P(OutInfo,"^",4)="OrderPackQty"
				q OutInfo
	 		}
		}
	}
	if (PackQty'="")&&((+PackQty<=0)||('$MATCH(PackQty,CheckValue))){
		s OutInfo="-1^" _OrderName _"的数量不是有效数字,请检查"
		s $P(OutInfo,"^",4)="OrderPackQty"
		q OutInfo
	}
	if (PAADMType="I"){
		if (+PackQty=0)&&(PriorCode="OUT")&&(OutOrderNeedPackQty="1"){
			s OutInfo="-1^" _OrderName _"没有录入整数量"
			s $P(OutInfo,"^",4)="OrderPackQty"
			q OutInfo
		}
		if (+PackQty=0)&&((IPNeedBillQty="Y")|| (IPNeedBillQtyFlag = "1"))&&(PriorCode'["OM")&&('##class(appcom.OEOrdItem).ISLongOrderPrior(PriorRowid)){
			s OutInfo="-1^" _OrderName _"没有录入整数量"
			s $P(OutInfo,"^",4)="OrderPackQty"
			q OutInfo
		}
		if (VisitStatus="P")&&(+PackQty=0){
			s OutInfo="-1^" _OrderName _"没有录入整数量"
			s $P(OutInfo,"^",4)="OrderPackQty"
			q OutInfo
		}
	}else{
		 if (+PackQty = 0)&&(NormSplitPackQty'=1)&&(PriorCode'["OM")&&(OrderVirtualtLong'="Y") {
            s OutInfo="-1^" _OrderName _"没有录入整数量"
			s $P(OutInfo,"^",4)="OrderPackQty"
			q OutInfo
        }
	}
	//控制医嘱数量不能超过1000,避免录入错误导致不能账单的问题
	s NotLimitQty=..GetItemNotLimitQtyFlag(ARCIMRowid)
    if (PackQty > 9999)&&(NotLimitQty'="Y") {
        s OutInfo="-1^" _OrderName _"医嘱数量不能超过9999。请修改！"
		s $P(OutInfo,"^",4)="OrderPackQty"
		q OutInfo
    }
    Set OrderPrice=$p(OrdItem,"^",7)
	if (PackQty*OrderPrice)>50000{
		 s CallBackFunParams=OrderName_" 总价格大于50000元,是否确定继续开立?"
		 s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
		
		}
	
	
	q "0^^^"
}
/// w ##class(web.DHCOEOrdItem).GetItemNotLimitQtySubCatFlag("2119||1")
ClassMethod GetItemNotLimitQtySubCatFlag(ARCIMRowid)
{
	n (ARCIMRowid)
	s SubCat = $p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",10)
	s SubCatStr = ^DHCDocConfig("HospDr_2","NotLimitQtyCat")
	if (SubCatStr[SubCat) {
		q "Y"	
	}
	else {
		q "N"
	}
}
}