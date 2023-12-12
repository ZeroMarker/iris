Reg.hui.js
```js
if (SrcObj.id=="CardNo"){
	CardNoKeydownHandler(e);
	$('#DeptList').focus();
	return false;
}else if(SrcObj.id=="PatientNo"){
	PatientNoKeydownHandler(e);
	$('#DeptList').focus();
	return false;
}
```