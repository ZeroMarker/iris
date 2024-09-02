ClassName: web.DHCAppPisMasterQuery
MethodName: JsonBaseItemList
dataType: json
Title: 标本类型
Name: SpceTypelist
Type: LIVN
HospID: 2
```objectscript
/// Descritp: 病理基础字典数据
/// w ##class(web.DHCAppPisMasterQuery).JsonBaseItemList("采集方式","CollectTypelist","LIVN","2")
ClassMethod JsonBaseItemList(Title, Name, Type As %String = "", HospID As %String)
{
	s ^temp("JsonBaseItemList")=$LB(Title, Name, Type, HospID)
	Set langid=..%LanguageID()
	s Stream=##class(%Stream.GlobalCharacter).%New()
	d Stream.Write("[")
	s TitleText=##class(User.DHCAppPisDicType).GetTranByDesc("APDesc",Title,langid)
	d Stream.Write(##class(web.DHCAPPJsonCommon).getJsonTreeStartSign(1,TitleText))
	d Stream.Write(",""items"":")
	d Stream.Write(##Class(web.DHCAppPisMasterQuery).JsonGetPisDicTypeNew(Title,HospID,Name,Type))
	d Stream.Write("}")
	d Stream.Write("]")
	Q Stream.Read()
}
```