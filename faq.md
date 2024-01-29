## 挂号
opadm.reg.hui.csp
OPAdm/Reg.hui.js
web.DHCOPAdmReg.cls

## 处方
web.DHCDocPrescript.cls

## 医嘱
web.DHCDocOrderEntry.cls
oeorder.oplistcustom.new.csp
web.DHCOEOrdItemView.cls
web.DHCOEOrdItem.cls
scripts/dhcdoc/UDHCOEOrder.List.Custom.New.js

## 治疗记录
User.DHCDocCureRecode.cls
DHCDoc.DHCDocCure.Record.cls
dhcdoc/dhcdoccure_hui/app.emr.cureapplist.js

## 诊断
scripts/dhcdoc/DHCDocDiagnoEntry.V8.js

## 工具类
DHCDoc.Util.Array
DHCDoc.Util.Date

## 建卡
reg.cardreg.hui.csp
Reg/CardReg.hui.js

## 检查一体化

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
## for loop
```objectscript
s id = ""
f  s id = $(^Main(id)) q:id=""  d
.s name = $lg(^Main(id),1)
.q name = ""
// two whitespace
```

## 记录Session
s ^temp = $lb(%session)

## 下拉框text取value
```
$("#mySelect option:contains('" + text + "'):selected").val();
```

## 登记号 患者ID 就诊号 医嘱 医嘱明细 医嘱执行
^PAPERi("PAPMI_PatNo",$$ALPHAUP({PAPMI_No}),{PAPMI_RowId})
^PAPERdr({PAADM_PAPMI_DR},"ADM",{PAADM_Type},{PAADM_RowID})
^OEORD(0,"Adm",admId,{OE_Order.OEORD_RowId})
^OEORD({OE_Order.OEORD_RowId},"I",{OEORI_Childsub})
^OEORD({OE_Order.OEORD_RowId},"I",{OE_OrdItem.OEORI_Childsub},"X",{OEORE_Childsub})

## return && return false
return cause restart function

## 医生站应用配置速查

## 指向字段的复制
s logObj.MRDLICDCodeDR = diagObj.MRDIAICDCodeDR

## array to json
var arr = ["apple", "banana"];
var jsonArray = [];

for (var i = 0; i < arr.length; i++) {
  var jsonObj = {
    "id": i + 1,
    "value": arr[i]
  };
  jsonArray.push(jsonObj);
}

var jsonString = JSON.stringify(jsonArray);
console.log(jsonString);
