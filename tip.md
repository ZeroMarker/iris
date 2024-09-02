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


## 禁用 启用
```js
//$("#i-apply-panel-emreason").removeAttr("disabled");
$("#i-apply-panel-emreason").simplecombobox('enable');
```


datagrid:
remoteSort:false

