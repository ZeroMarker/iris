## paymode
```js
function GetPayModeCode(){
	if (ServerObj.ParaRegType!="APP"){
		var PayModeValue=$("#PayMode").combobox("getValue");
		if (PayModeValue!="") {
			var PayModeData=$("#PayMode").combobox('getData');
			var index=$.hisui.indexOfArray(PayModeData,"CTPMRowID",PayModeValue);
			var PayModeCode= PayModeData[index].CTPMCode;
			return PayModeCode;
		}
	}
	return "";
}
//安全组功能授权-支付方式授权
```