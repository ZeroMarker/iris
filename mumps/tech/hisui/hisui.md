## intro
<HISUI />

\$URL
Global AJAX Variable


```js
//异步调用类方法，推荐
$cm({
	ClassName:"dhc.Test",
	MethodName:"getPatInfo",
	UserName:"张三"
},function(jsonData){
	console.dir(jsonData);  //{"name":"张三"}
});
```

## component
```js
$("#Address").combobox("getText");
$("#Address").combobox("getValue");
$("#Address").combobox("setValue"，1);
$("#ALGItem").lookup("setText","");
$("#ALGItem").lookup("setValue","");
$("#Birth").val();
$("#Birth").val(brith);
```

## datagrid
```js
$('#allergytb').datagrid('load', {   
    PatientID:PatientID
});
```

## layout
hisui-layout

region:east

