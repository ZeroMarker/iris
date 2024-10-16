$(function(){
	InitPatListTabDataGrid();
});
function InitPatListTabDataGrid(){
	var Columns=[[ 
		{field:'no',title:'登记号',width:100,align:'left'},
		{field:'name',title:'姓名',width:90,align:'left'},
		{field:'arcim',title:'医嘱名称',width:400,align:'left'},
		{field:'rowid',title:'医嘱ID',width:200},
		{field:'sttDate',title:'开始日期',width:100},   
		{field:'adm',title:'就诊号',width:90}
    ]]
    var PatListTabDataGrid=$("#OrderList").datagrid({
		fit : true,
		height:'100',
		border : false,
		striped : true,
		singleSelect : true,
		data:json,
		fitColumns : false,
		autoRowHeight : false,
		rownumbers:true,
		pagination: true,  
		pageSize: 20,
		pageList : [20,100,200],
		idField:'rowid',
		columns :Columns
	});
	var data = tkMakeServerCall("web.DHCDocMain","GetOrderGraph");
	var json = JSON.parse(data);
	PatListTabDataGrid.datagrid('loadData',json);
	return PatListTabDataGrid;
}