if value {
    s a=1
    if value {
        if value {
            s a=3
        }
    }
}

if value d
.s a=1
.i value d
..s a=3

```objectscript
Set OutputObj=##Class(DHCExternalService.CardInterface.Entity.FindPatientCardRp).%New()
if (UserID="") {
    d ..SetOutputCode(.OutputObj,"-100","操作用户不能为空.")
    quit OutputObj
}
```

use variable
i var '= "" s var=""

^PAPERi("PAPMI_PatNo",$$ALPHAUP({PAPMI_No}),{PAPMI_RowId})
$o(^PAPERi("PAPMI_PatNo",$ZCVT(PatientNo,"U"),""))

iris list
irissession < instancename>
irisdb

s:ind="" ind=1
/*
*/
s qHandle($i(ind))=lb(CTCode,CTDesc)

$listbuild()
$listget()

^PAADMi("No",$$ALPHAUP({PAADM_ADMNo}),{PAADM_RowID})
rowid=0
$o(^PAADMi("No",admNo,rowid))

$o(^PAADM(5),-1)
4

+number=+number
force arithmetic operation

$Extract(Code,1,$L(Target))=Target


_$C(13,10)


In ObjectScript, if you want to create a string that contains double quotes (") within it, you can use two double quotes together to escape them. Here's an example:
set myString = "This is a string with double quotes ""inside"" it."


$p($g())

loadSex
valuefield
textfield

Replacing a Substring Using SET $PIECE
   SET colorlist="Red,Green,Blue,Yellow,Orange,Black"
   WRITE colorlist,!
   SET $PIECE(colorlist,",",1)="Magenta"
   WRITE colorlist,!
   SET $PIECE(colorlist,",",*-3)="Cyan"
   WRITE colorlist,!

+value = value
judge number


// check class property
##class(web.DHCBL.UDHCCommFunLibary).GetClassPropertyList("web.DHCEntity.PCA.PATMAS")

// debug watch variable
s remark=$tr(remark," ","")
s ^Temp("u78k4",2) = remark

// , &&
if x > 1, y > 2 {
    // Code to execute if both conditions are true
} else {
    // Code to execute if the conditions are not met
}

// 保存运行时入参
set ^TMP("FindDailyDtl")=$lb(wardId, admStr, stDate, stTime, endDate, endTime, otherQryStr, langId)

// 回调
function fun(callBackFun) {
    new Promise(function(resolve,rejected){
	    if ((IsExistDISDiag==1)&&(IsExistMainDISDiag==0)){
		    $.messager.confirm('提示', "此次所开出院诊断列表中没有【主诊断】,请确认是否继续保存?", function(r){
			    if (r) {
					resolve();
				}
			});
			return;
		}
		resolve();
	}).then(function(){
		return new Promise(function(resolve,rejected){
			if ((IsExistAdmitDiag==1)&&(IsExistMainAdmitDiag==0)){
				///山一大二附院反馈不需要此控制
			    /*$.messager.confirm('提示', "此次所开入院诊断列表中没有【主诊断】,请确认是否继续保存?", function(r){
				    if (r) {
						resolve();
					}
				});
				return;
				*/
			}
			resolve();
		})
	}).then(function(){
		callBackFun();
	})
}


// force arithmetic
s x = "003020"
s y = +x
"003020" => 3020
"1I3020" => 1
"I23333" => 0

runClassMethod("web.DHCADVCOMMONPART","GetRecordId",{'LinkRecordId':recordId,'FormCode':"DrugHeaNurEvaluate"},
function(data){ 
			HeadNurEvaRecId=data
},"text",false)