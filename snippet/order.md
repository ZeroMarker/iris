```objectscript
/// desc:		通过医嘱ID获取处方号
/// input:		orditem
/// output:		prescNo
/// w ##class(web.DHCDocMain).GetPrescNoByOrdItem("182||5")
ClassMethod GetPrescNoByOrdItem(OrdItem)
{
	q:OrdItem="" ""
	s PrescNo = $p($g(^OEORD(+OrdItem,"I",$p($g(OrdItem),"||",2),1)),"^",14)
	q PrescNo
}

/// 获取医嘱项代码
/// w ##class(web.DHCDocMain).GetArcimCode("1||1")
ClassMethod GetArcimCode(OrdItem)
{
	q:OrdItem="" ""
	s Arcim = $p($g(^OEORD(+OrdItem,"I",$p(OrdItem,"||",2),1)),"^",2)
	s code = $p($g(^ARCIM(+Arcim,1,1)),"^",1)
	q code
}
/// 获取检验号
/// w ##class(web.DHCDocMain).GetLabNoByOrdItem("1244||5")
ClassMethod GetLabNoByOrdItem(OrdItem)
{
	q:OrdItem="" ""
	s PrescNo = $p($g(^OEORD(+OrdItem,"I",$p($g(OrdItem),"||",2),3)),"^",20)
	q PrescNo
}

/// 获取检验主遗嘱
/// w ##class(web.DHCDocMain).GetLabMainOrd("1||1")
ClassMethod GetLabMainOrd(OrdItem)
{
	q:OrdItem="" ""
	s LabNoStr = $p($g(^OEORD(+OrdItem,"I",$p(OrdItem,"||",2),"DHC")),"^",22)
	s LabNo = $p($g(LabNoStr),$c(1))
	s MainOrd = ""
	&sql(select OEORI_RowId into:MainOrd from SQLUser.oe_ordItem where OEORI_LabEpisodeNo = :LabNo)
	q MainOrd
}
```