## 卡管理卡操作查询排序
Reg.CardManagement.hui.js

```js
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
		// Specific value to compare against
		var specificValue = $("#Name").val();
		var records = GridData.rows;
		var exact = records.filter(record => record.Name == specificValue);
		var mid = records.filter(record => record.Name.startsWith(specificValue) && record.Name !== specificValue);
		var remain = records.filter(record => !record.Name.startsWith(specificValue));

		// Sort the array based on pinyin
		mid.sort((a, b) =>
		a.Name.localeCompare(b.Name, 'zh-Hans-CN', {sensitivity: 'accent'})
		);
		
		remain.sort((a, b) =>
		a.Name.localeCompare(b.Name, 'zh-Hans-CN', {sensitivity: 'accent'})
		);
		
		GridData.rows = exact.concat(mid.concat(remain));
		//GridData.rows.sort((a, b) => a.Name.localeCompare(b.Name));
		//console.log(GridData);
		
		PageLogicObj.m_CardListTabDataGrid.datagrid({loadFilter:pagerFilter}).datagrid('loadData',GridData);
	}); 
}
```