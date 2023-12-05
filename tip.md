## nested structure
.
..

{
	{

	}
}
## object encapsulation
```objectscript
Set OutputObj=##Class(DHCExternalService.CardInterface.Entity.FindPatientCardRp).%New()
if (UserID="") {
    d ..SetOutputCode(.OutputObj,"-100","操作用户不能为空.")
    quit OutputObj
}
```

## variable usage
i var '= "" s var=""

## iris terminal
iris
irisdb

## arithmetic operation
+number=+number
force arithmetic operation
// force arithmetic
s x = "003020"
s y = +x
"003020" => 3020
"1I3020" => 1
"I23333" => 0

## prefix match
$Extract(Code,1,$L(Target))=Target

## concat \r\n
_$C(13,10)

## quotes escape
In ObjectScript, if you want to create a string that contains double quotes (") within it, you can use two double quotes together to escape them. Here's an example:
set myString = "This is a string with double quotes ""inside"" it."

## Replacing a Substring Using SET $PIECE
SET colorlist="Red,Green,Blue,Yellow,Orange,Black"
WRITE colorlist,!
SET $PIECE(colorlist,",",1)="Magenta"
WRITE colorlist,!
SET $PIECE(colorlist,",",*-3)="Cyan"
WRITE colorlist,!

## judge number
+value = value
judge number


## check class property
##class(web.DHCBL.UDHCCommFunLibary).GetClassPropertyList("web.DHCEntity.PCA.PATMAS")

## debug watch variable
s remark=$tr(remark," ","")
s ^Temp("u78k4",2) = remark

## bool &&
if x > 1, y > 2 {
    // Code to execute if both conditions are true
} else {
    // Code to execute if the conditions are not met
}

## record arguments
set ^TMP("FindDailyDtl")=$lb(wardId, admStr, stDate, stTime, endDate, endTime, otherQryStr, langId)

## callback function
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


## run class method

runClassMethod("web.DHCADVCOMMONPART","GetRecordId",{'LinkRecordId':recordId,'FormCode':"DrugHeaNurEvaluate"},
function(data){ 
			HeadNurEvaRecId=data
},"text",false)

## quit aka break
for {
	quit:x=1
}

## debug
b ;01
g next line
q exit

[Studio Debug](./mumps/studio/studio.md##debug)
### debug
toggle breakpoint   F9
go                  Ctrl+F5
step into
step over
step out
run to cursor