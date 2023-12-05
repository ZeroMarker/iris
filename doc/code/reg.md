```js
function BRegExpClickHandle(PatientNo) {
	if (typeof PatientNo == undefined) { PatientNo = ""; }
	if ((PatientNo == "undefined") || (PatientNo == undefined)) { PatientNo = ""; }
	var src = "reg.cardreg.hui.csp?PatientNoReg=" + PatientNo;
	var $code = "<iframe width='100%' height='100%' scrolling='auto' frameborder='0' src='" + src + "'></iframe>";
	createModalDialog("CardReg", "建卡", PageLogicObj.dw + 160, PageLogicObj.dh, "icon-w-edit", "", $code, "");
}
BRegExpClickHandle(PatientNo);
```