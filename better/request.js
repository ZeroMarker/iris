runClassMethod("web.DHCADVCOMMONPART","GetRecordId",{'LinkRecordId':recordId,'FormCode':"DrugHeaNurEvaluate"},
function(data){ 
			HeadNurEvaRecId=data
},"text",false)

var ret=cspRunServerMethod(GlobalObj.AddAuditItemToListMethod,'AddCopyItemToList','',EpisodeID,AnditAARowidArr);

var jsonData=tkMakeServerCall("web.DHCEQ.Plat.LIBBusinessModify","GetOneInStockList",BussID);

var result=$.cm({
    ClassName:"web.DHCANOPArrangeHISUI",
    QueryName:"FindAnaestMethod",
    anmethod:"",
    ResultSetType:"array"
},false)
// 同步
