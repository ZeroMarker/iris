SELECT * from OE_OrdExec 
where OEORE_RowId in ("513||22||6","513||22||7")
or OEORE_OEORI_ParRef = "513||22";

"513||22||6^513||22||7"
SELECT * from dhc_patbillorder
where PBO_OEORI_DR  = "513||22"

/// d ##class(%ResultSet).RunQuery("web.DHCDocMain","FindOrderFee","513||22||6^513||22||7")
ClassMethod FindOrderFeeExecute(ByRef qHandle As %Binary, orderId) As %Status
{
		set repid = $I(^CacheTemp)
		if $g(ind) = "" set ind = 0
		Set langid=..%LanguageID()
		s i = 1
		s orderList = orderId
		// 多部位检查医嘱可能传入多条执行记录 "513||22||6^513||22||7"
		// 遍历执行记录
		f {
			s orderId = $p(orderList, "^", i)
			s i = i + 1
			b ;;
			q:orderId=""
			d OutputRow
		}
		set qHandle = $lb(0,repid,0)
		Q $$$OK
OutputRow
		/*			
		i orderId="" set qHandle = $lb(0,repid,0) Q $$$OK
		;s ^Temp("wanghc","orderfee")=orderId
		s flag = $l(orderId,"||")
		i flag'=3 set qHandle = $lb(0,repid,0) Q $$$OK
		*/
		s flag = $l(orderId,"||")
		s (pb,pbo,pbd)=0
		//医嘱表 写法有问题
		i flag=2 d	//医嘱orditemrowid
		.s pb = $o(^DHCPBi(0,"OEORI",orderId,""),-1)
		.q:+pb'>0
		.s pbo = $o(^DHCPBi(0,"OEORI",orderId,pb,""),-1)
		.q:+pbo'>0
		e  i flag=3 d	//执行医嘱ordexecrowid
		.s pb = $O(^DHCPB(0,"OEEXC",orderId,""),-1)
		.q:+pb'>0
		.s pbo = $O(^DHCPB(0,"OEEXC",orderId,pb,""),-1)
		.q:+pbo'>0
		
		;i pbo'>0 set qHandle = $lb(0,repid,0) Q $$$OK
		q:pbo'>0
		s TPBOrderBillStatus = $p(^DHCPB(pb,"O",pbo),"^",16)
		f  s pbd = $o(^DHCPB(pb,"O",pbo,"D",pbd)) q:pbd=""  d
		.s (TTarDesc,TTarCode,TQty,TPrice,TAmount,TDate)=""
		.s str = ^DHCPB(pb,"O",pbo,"D",pbd)
		.s tar = $p(str,"^",3)
		.q:+tar'>0
		.s TTarDesc = $p(^DHCTARI(tar),"^",2)
		.s TTarDesc=##class(User.DHCTarItem).GetTranByDesc("TARIDesc",TTarDesc,langid)
		.s TTarCode = $p(^DHCTARI(tar),"^",1)
		.s TQty = $fn($p(str,"^",5),"",2)
		.s TPBDBillStatus="B"
		.i TPBOrderBillStatus="R" s TPBDBillStatus="R"
		.i TPBOrderBillStatus="P" s TPBDBillStatus="R"
		.s TPBDOriginalDR = $p(str,"^",23)
		.i +TPBDOriginalDR>0 s TPBDBillStatus="R"
		.e  i $d(^DHCPB(0,"OriginalDR",pb_"||"_pbo_"||"_pbd))=10 s TPBDBillStatus="R"
		.;e  s TPBDBillStatus="B"
		.s TExtralComment=$p(str,"^",24)
		.;s TPrice = $p(str,"^",4)
		.;s TAmount = $p(str,"^",7)
		.s TPrice = $fn($p(str,"^",4),"-")
		.s TAmount = $fn($p(str,"^",7),"-")
		.if (TQty<0) s TAmount="-"_TAmount
		.s TDate = $p(str,"^",11)
		.s:TDate'="" TDate=..%ZD(TDate)
		.s ind = ind+1
		.s ^CacheTemp(repid,ind) = $lb(pb_"||"_pbo_"||"_pbd,TPBDBillStatus,TTarDesc,TTarCode,TQty,TPrice,TAmount,TDate,TExtralComment)
		quit
}