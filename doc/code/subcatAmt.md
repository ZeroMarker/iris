医嘱子类扩展设定
<!--设置 dhcdoc.config.subcatcontral.csp 子类控制设置-->
scripts/dhcdocconfig/dhcdoc.config.subcatcontral.js
url : $URL+"?ClassName=DHCDoc.DHCDocConfig.SubCatContral&QueryName=FindSubCatConfigList"
w ^DHCDocConfig("HospDr_2","NotLimitQtyCat")
--
ClassMethod CheckPackQtyUpdate
w ##class(web.DHCOEOrdItem).GetItemNotLimitQtySubCatFlag("2119||1")
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