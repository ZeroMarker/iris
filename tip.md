## Replace special symbols
&amp;
&Hat;
&#94;

## context menu
```js
// 锁定页面右键
document.oncontextmenu = function(e){
    return false;
}
```

## tabs
```js
// 获取选中的标签页（tab）的文本
var selectedTabText = $('#tabs').tabs('getSelected').panel('options').title;
```


## css
```js
$("#DeptList").css('height',$(window).height()-395);
```



## GetSessionStr()
```js
// websys.js
function GetSessionStr() {
    return websys_getSessionStr();
}
```



## reload datagrid
```js
$('#allergytb').datagrid('load', {   
    PatientID:PatientID
});
```
## run class method
```js
runClassMethod("web.DHCADVCOMMONPART","GetRecordId",{'LinkRecordId':recordId,'FormCode':"DrugHeaNurEvaluate"},
function(data){ 
			HeadNurEvaRecId=data
},"text",false)
```

## cspRunServerMethod
```js
var ret=cspRunServerMethod(GlobalObj.AddAuditItemToListMethod,'AddCopyItemToList','',EpisodeID,AnditAARowidArr);
```

## tkMakeServerCall
```js
var jsonData=tkMakeServerCall("web.DHCEQ.Plat.LIBBusinessModify","GetOneInStockList",BussID);
```

## cm
```js
var result=$.cm({
        ClassName:"web.DHCANOPArrangeHISUI",
        QueryName:"FindAnaestMethod",
        anmethod:"",
        ResultSetType:"array"
    },false)
```

## 下拉框text取value
```js
$("#mySelect option:contains('" + text + "'):selected").val();
```



datagrid:
remoteSort:false

// Create a new Error object
var err = new Error();

// Capture the stack trace
var stackTrace = err.stack;

// Print or process the stack trace as needed
//console.log(stackTrace);
const regex = /scripts\/.*\.js/g;
stackTrace = stackTrace.match(regex);
stackTrace = stackTrace.join(',');

unix timestamp

$zdt($h,-2)