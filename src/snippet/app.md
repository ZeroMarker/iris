```objectscript
/// w ##class(web.DHCDocMain).GetPardDesc("5800||25||1")
ClassMethod GetPardDesc(exec)
{
	/*
	select * from DHC_AppReport ;
	select * from DHC_AppRepArc ;
	select * from DHC_AppRepPart ;
	select * from DHC_AppRepPos ;
	*/	
	q:exec="" ""
	q:$l(exec,"||")'=3 ""
	s item = $p(exec,"||",1,2)
	s arcim = $p($g(^OEORD(+item,"I",$p(item,"||",2),1)),"^",2)
	s desc = $p($g(^ARCIM(+arcim,1,1)),"^",2)
	&sql(select AR_RowID into :rowid from SQLUser.DHC_AppRepArc WHERE AR_OrdItem = :item)
	q:$g(rowid)="" desc
	s rowid = rowid _ "||" _ $p(exec,"||",3)
	&sql(select AR_Part_Dr,AR_RowId into :Part, :PartRowid from SQLUser.DHC_AppRepPart where AR_RowID  = :rowid)
	&sql(select AR_Pos_Dr into :Pos from SQLUser.DHC_AppRepPos where AR_RepPart_Dr = :PartRowid)
	s:$g(Part)'="" Part = "["_$p($g(^DHCAPPART(Part)),"^",2)_"]"
	s:$g(Pos)'="" Pos = $p($g(^DHCAPPOS(Pos)),"^",2)
	s desc = desc_$g(Part)_$g(Pos)
	q desc
}
```