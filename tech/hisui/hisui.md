<HISUI />

$URL
Global AJAX Variable

//异步调用类方法，推荐
$cm({
	ClassName:"dhc.Test",
	MethodName:"getPatInfo",
	UserName:"张三"
},function(jsonData){
	console.dir(jsonData);  //{"name":"张三"}
});

$("#Address").combobox("getText");
$("#Birth").val();
$("#Birth").val(brith);

datagrid
toolbar
pageSize:20
pageList:[20,40]
singleSelect:true


combobox

ResultSetType	{ String }	可选	配置ResultSetType后，运行Query返回的数据格式
值为array时返回值格式为:[{},{},{}]
不配置时返回格式为:{"rows":[{},{},{}],"total":3}
值为Excel时返回下载cvs链接，具体参考导出Excel菜单说明
值为ExcelPlugin时会导出Excel到本地，具体参考导出Excel菜单说明

hisui-layout

region:east

setValue()