## 挂号
opadm.reg.hui.csp
Reg.hui.js
web.DHCOPAdmReg.cls

## 处方
web.DHCDocPrescript.cls

## 医嘱
web.DHCDocOrderEntry.cls

## 治疗记录
User.DHCDocCureRecode.cls
DHCDoc.DHCDocCure.Record.cls
dhcdoc/dhcdoccure_hui/app.emr.cureapplist.js

## 工具类
DHCDoc.Util.Array
DHCDoc.Util.Date

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

