```js
// scripts/dhcdoc/DHCDocDiagnoEntry.V8.js
var ids = $('#tabDiagnosEntry').jqGrid("getGridParam", "selarrrow");
if (ids == null || ids.length == 0) {
    $.messager.alert("警告", "请选择需要删除的记录!");
    return;
}
var allRowIds = $('#tabDiagnosEntry').jqGrid('getDataIDs');
if (ServerObj.PAAdmType=="O"){
    var ret = tkMakeServerCall("web.DHCDocMain","CheckValidOrderExist",ServerObj.EpisodeID)
    var length = allRowIds[allRowIds.length - 1];
    var target = [];
    allRowIds.forEach(function (element,index) {
        var doctor = $("#tabDiagnosEntry").jqGrid('getCell', element, 'DiagnosDoctor');
        if (doctor!="") {
            target.push(element);
        }
    });
    
    var flag = 1;
    target.forEach(function (element) {
        if (ids.indexOf(element) == -1) {
            flag = 0;	
        } 	
    });
    
    if ((flag == 1) && (ret == 1)){
        $.messager.alert("警告", "患者存在有效医嘱，不能删除全部诊断!");
        return false;
    }
}
```

```objectscript
/// desc: 判断存在非挂号有效医嘱
/// input: EpisodeID
/// output: 1 存在 0 不存在
/// debug: w ##class(web.DHCDocMain).CheckValidOrderExist(101110313)
ClassMethod CheckValidOrderExist(EpisodeID)
{
	//cjb+ 存在非挂号有效医嘱时 不允许退费
	s mm=""
	s mm=$o(^OEORD(0,"Adm",EpisodeID,mm))
	if mm'="" d
	.s oeordcld="" f  s oeordcld=$o(^OEORD(mm,"I",oeordcld)) q:oeordcld=""  d
	..q:(oeordcld=0)
	..s paorderrow=mm_"||"_oeordcld
	..s arcimdr=$p(^OEORD(mm,"I",oeordcld,1),"^",2)
	..s subscript=$p(arcimdr,"||",1)
	..s Version=$p(arcimdr,"||",2)
	..s itemCat=$p(^ARCIM(subscript,Version,1),"^",10) 
	..s OrdCat=$p(^ARC("IC",itemCat),"^",8)
	..q:itemCat=194	;诊查类
	..;q:OrdCat="20"   //不判断挂号费医嘱
	..s oestatus=$p(^OEORD(mm,"I",oeordcld,1),"^",13)
	..q:((oestatus'="1")&&(oestatus'="6"))  //非核实或执行的医嘱不判断
	..s kid=+$g(kid)+1
	s flag = ""
	if $g(kid)'="" {
		s flag = 1	
	}
	else {
		s flag = 0	
	}
	q flag
}
```
