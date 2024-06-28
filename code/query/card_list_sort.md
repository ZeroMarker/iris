## 卡管理卡操作查询排序
```js
// Reg.CardManagement.hui.js
function RegReturnListTabDataGridLoad(){
	PageLogicObj.m_CardListTabDataGrid.datagrid("uncheckAll");
	$.cm({
	    ClassName : "web.DHCBL.CARD.CardManager",
	    QueryName : "PatientCardQuery",
	    Name:$("#Name").val(),
	    IDCardNo:"", //身份证号
	    CardNo:$("#CardNo").val(),
	    CardStatus:"N",
	    CardTypeID:$("#CardTypeRowID").val(), //GetCardTypeRowId(),
	    SupportFlag:"",
	    CredNo:$("#CredNo").val(),
	    UseStatus:"",
	    BirthDay:$("#BirthDay").val(),
	    Telphone:$("#Telphone").val(),
	    OutMedicareNo:$("#OutMedicareNo").val(),
	    InMedicareNo:$("#InMedicareNo").val(),
	    //NewOutMedicareNo:"",
	    NewInMedicareNo:"",
	    InsuranceNo:$("#InsuranceNo").val(),
	    EmMedicare:$("#EmMedicare").val(),
	    RegNo:$("#RegNo").val(),
	    Pagerows:PageLogicObj.m_CardListTabDataGrid.datagrid("options").pageSize,rows:99999
	},function(GridData){
		// 查询精准匹配
		// 查询结果按拼音字母顺序排序
		// 获取查询参数
		var specificValue = $("#Name").val();
		var records = GridData.rows;
		// 过滤精准匹配结果
		var exact = records.filter(record => record.Name == specificValue);
		// 前序模糊匹配
		var mid = records.filter(record => record.Name.startsWith(specificValue) && record.Name !== specificValue);
		// 非前序模糊匹配
		var remain = records.filter(record => !record.Name.startsWith(specificValue));

		// 根据拼音排序数组
		mid.sort((a, b) =>
		a.Name.localeCompare(b.Name, 'zh-Hans-CN', {sensitivity: 'accent'})
		);
		
		remain.sort((a, b) =>
		a.Name.localeCompare(b.Name, 'zh-Hans-CN', {sensitivity: 'accent'})
		);
		
		// 排序好的数组拼接
		GridData.rows = exact.concat(mid.concat(remain));
		
		PageLogicObj.m_CardListTabDataGrid.datagrid({loadFilter:pagerFilter}).datagrid('loadData',GridData);
	}); 
}
```