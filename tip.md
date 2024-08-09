## innerText vs textContent
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

## Refer Object Value
```objectscript
s ItmObj = ##class(User.DHCTarItem).%OpenId(Itm)
s SubObj = ##class(User.DHCTarSubCate).%OpenId(ItmObj.TARISubCate.%Id())
s CatObj = ##class(User.DHCTarCate).%OpenId(SubObj.TARSCTARCDR.%Id())
s Cat = SubObj.TARSCTARCDR.%Id()
```



## tabs
```js
// 获取选中的标签页（tab）的文本
var selectedTabText = $('#tabs').tabs('getSelected').panel('options').title;
```


## XML 类 数据传输
```objectscript
s obj.name = name
s:obj.name="" obj.name = " "
// 转 xml 只传输非空值
```

## url para
```js
// Define the base URL
const baseUrl = 'https://example.com/api';

// Define the parameters as an object
const params = {
  page: 1,
  limit: 10,
  search: 'example'
};

// Convert the parameters object to URLSearchParams
const searchParams = new URLSearchParams(params);

// Join the base URL with the parameters
const urlWithParams = `${baseUrl}?${searchParams}`;

console.log(urlWithParams);
```

## css
```js
$("#DeptList").css('height',$(window).height()-395);
```

```
s BillFlag1=$P($G(^MRC("ID",+ICDRowid)),"^",13)
s BillFlag3=$P($G(^MRC("ID",+ICDRowid)),"^",15)
s DiagObj.DiagnosisClass=$SELECT((BillFlag1="Y")&&(BillFlag3="Y"):"证型",BillFlag3="Y":"中医",1:"西医")
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
```
var result=$.cm({
        ClassName:"web.DHCANOPArrangeHISUI",
        QueryName:"FindAnaestMethod",
        anmethod:"",
        ResultSetType:"array"
    },false)
```

## 下拉框text取value
```
$("#mySelect option:contains('" + text + "'):selected").val();
```





