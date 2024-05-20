## 出院弹窗
```js
websys_showModal({
		iconCls:'icon-w-edit',
		url:"../csp/dhcdoc.stopafterlongordcondition.csp?type="+type,
		title:title,
		width:400,height:370,
		paraObj:paraObj,
		closable:false,
		CallBackFunc:function(result){
			websys_showModal("close");
			var returnObj={
				SuccessFlag:false,
				LongOrdStopDateTimeStr:""
			}
			if ((result == "") || (result == "undefined")||(result == null)) {
			    CallBackFun(returnObj);
		    } else {
			    var resultArr=result.split("^");
			    if (type == "NeedDischgCond") {
		        	GlobalObj.DischargeConditionRowId = resultArr[0].split('!')[0];
					GlobalObj.DischargeMethodID=resultArr[0].split('!')[1]||'';
		        }else if (type == "NeedDeathDate"){
			        GlobalObj.DeceasedDateTimeStr = resultArr[0];
					GlobalObj.DischargeConditionRowId="";
					GlobalObj.DischargeMethodID="";
			    }
			    $.extend(returnObj, { SuccessFlag: true,LongOrdStopDateTimeStr:resultArr[1]});
		        CallBackFun(returnObj);
		    }
		}
	})
```
CheckBeforeSaveToServer
CheckAfterCheckMethod
OpenDeathDate
OpenStopAfterLongOrder()
```objectscript
/// w ##class(web.DHCDocOrderEntry).GetDischargePayMethod()
ClassMethod GetDischargePayMethod(langid = "")
{
 	s:langid="" langid=..%LanguageID()
	// Create an array to hold JSON objects
    Set jsonArray = []
	
    // Split the input data by comma to get individual name:code pairs
    s data = ##class(DHCDoc.DHCDocConfig.LocalConfig).GetLocalConfigValue("IPDoc","DischargePayMethod",2)
    // 普通住院:ptzy,日间手术结算:rjss,单病种结算:dbz,意外伤害结算:ywsh,中医优势病种:zyysbz,按床日:acr,日间病房:rjbf
    
    Set pairs = $LISTFROMSTRING(data, ",")

    // Iterate through each name:code pair
    For i=1:1:$LISTLENGTH(pairs) {
        // Split the name:code pair by colon to extract name and code
        Set pair = $LISTFROMSTRING($LISTGET(pairs, i), ":")
		break:$d(pair)=0
		
        // Extract name and code
        Set name = $LISTGET(pair, 1)
        Set code = $LISTGET(pair, 2)

		Set obj = {}
        Do obj.%Set("Name", name)
        Do obj.%Set("Code", code)
        
        // Create a JSON object with name and code fields and push it to the array
        Do jsonArray.%Push(obj)
    }
    // Convert the array to a JSON string
    Set jsonString = jsonArray.%ToJSON()
	Q jsonString
}
```
