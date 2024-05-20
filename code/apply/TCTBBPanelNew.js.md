## 病理申请单标本信息必填

dhcdoc.dhcapp.blmapshow.js
dhcdoc.dhcapp.TCTBBPanelNew.js
```js
var TCTBBPanelNew=(function(){
	function Init(){
		InitPageDataGrid();
		//LoadOtherInfo();
	}
	var editSelRow = -1;    /// 当前编辑行
	var isPageEditFlag = 1; /// 页面是否允许编辑
	function InitPageDataGrid(){
	
		/// 编辑格
		var texteditor={
			type: 'text',//设置编辑格式
			options: {
				required: true //设置编辑规则属性
			}
		}
		
		/// 数字编辑格
		var numberboxeditor={
			type: 'numberbox',//设置编辑格式
			options: {
				//required: true //设置编辑规则属性
			}
		}
	
		///日期编辑
		var datetimeeditor1={
			type:'datetimebox',
			options:{
				onChange:function(newValue, oldValue){
					if ((newValue!="")&&(newValue!=undefined)){
						var DateTime=$.cm({
						    ClassName : "DHCDoc.DHCApp.BasicConfig",
						    MethodName : "SpecToFixTime",
						    dataType:"text",
						    "datetime":newValue,
						    "Type":"LIVSetMin"
					    },false);
						var editors = $("#PisSpecList").datagrid('getEditors', sPaneleditSelRow); 
						if (DateTime!=" ") editors[4].target.datetimebox('setValue',DateTime);
						}
					}
				}
			}
		var datetimeeditor={
			type:'datetimebox',
			options:{
					
				}
			}
		
		var TitLnk = '<a href="#" onclick="TCTBBPanelNew.insRow()"><img style="margin:6px 3px 0px 3px;" src="../scripts/dhcpha/jQuery/themes/icons/edit_add.png" border=0/></a>';
		///  定义columns
		var columns=[[
			{field:'No',title:'标本序号',width:120,align:'center'},
			//{field:'ID',title:'标本标识',width:120,editor:texteditor},
			{field:'Name',title:'标本名称',width:200,editor:texteditor,Required:true},
			
			{field:'Qty',title:'标本数量',width:100,editor:numberboxeditor,Required:true},
			{field:'Part',title:'标本部位',width:200,editor:texteditor,Required:true},
			//{field:'Remark',title:'备注',width:200,editor:texteditor},
			//{field:'SepDate',title:'离体时间',width:150,editor:datetimeeditor1},
			//{field:'Purpose',title:'送检目的',width:200,editor:texteditor,Required:true},
			//{field:'FixDate',title:'固定时间',width:150,editor:datetimeeditor},
			{field:'operation',title:TitLnk,width:40,align:'center',
				formatter:SetCellUrl}
		]];
		
		///  定义datagrid
		var option = {
			//showHeader:false,
			fitColumn:false,
			headerCls:'panel-header-gray',
			rownumbers : false,
			singleSelect : true,
			pagination: false,		
		    onDblClickRow: function (rowIndex, rowData) {
				
				if (isPageEditFlag == 0) return;
				if (ServerObj.CheckSpecEditor=="1") return;
	            if ((editSelRow != -1)||(editSelRow == 0)) { 
	                $("#TCTSpecListNew").datagrid('endEdit', editSelRow); 
	            } 
	            $("#TCTSpecListNew").datagrid('beginEdit', rowIndex); 

	            editSelRow = rowIndex; 
	        },
	        onLoadSuccess:function(data){
		        var OtherInfo=""
				if (itemReqJsonStr!=""){
					for (var i = 0; i < itemReqJsonStr.length; i++) {
						var OneReqJson=itemReqJsonStr[i]
						var ID=OneReqJson.ID
						var Val=OneReqJson.Val
						if (ID=="OtherInfo") OtherInfo=Val
					}
				}
				if (OtherInfo!=""){
					OtherObj=$.parseJSON(OtherInfo); 
					PisSpec=$.parseJSON(OtherObj["PisSpec"])
					//setTimeout(function(){
						for (var i = 0; i < PisSpec.length; i++) {
							var PisArry=PisSpec[i]
							var PisArryStr=PisArry.split("^")
								var rowObj = {"No":PisArryStr[0],"Name":PisArryStr[2],"Explain":"","Part":PisArryStr[3],"Qty":PisArryStr[4],"ID":PisArryStr[1]};
								var Index= parseFloat(PisArryStr[0])-1
								$('#TCTSpecListNew').datagrid('updateRow',{index: Index, row:rowObj});
							
						} 
					//}, 2000);
				}
		    }
		};
		/// 就诊类型
		var uniturl = LINK_CSP+"?ClassName=web.DHCAppPisMasterQuery&MethodName=JsonQryPisSpec&PisID=";;
		new ListComponent('TCTSpecListNew', columns, uniturl, option).Init();
	}
		/// 链接
	function SetCellUrl(value, rowData, rowIndex){	
		return "<a href='#' onclick='TCTBBPanelNew.delRow("+ rowIndex +")'><img src='../scripts/dhcpha/jQuery/themes/icons/edit_remove.png' border=0/></a>";
	}

	/// 删除行
	function delRow(rowIndex){
		
		if (isPageEditFlag == 0) return;
		var rows = $('#TCTSpecListNew').datagrid('getRows');
		//删除前结束所有的编辑行
		$.each(rows,function(index,data){
			 if ((editSelRow != -1)||(editSelRow == 0)) { 
	                $("#TCTSpecListNew").datagrid('endEdit', editSelRow); 
	            }
		});

		/// 当前行数大于4,则删除，否则清空
		if(rowIndex=="-1"){
			$.messager.alert("提示:","请先选择行！");
			return;
		}
			
		if(rows.length>4){
			 $('#TCTSpecListNew').datagrid('deleteRow',rowIndex);
			 rowNo -= 1;
		}else{
			$('#TCTSpecListNew').datagrid('deleteRow',rowIndex);  //小于4时,删除该行后,在新增一个空行 qunianepng 2018/1/29
			 rowNo -= 1;
			 /// 行对象
			 var rowObj = {"No":rowNo+1,"Name":"","Explain":"","Part":"","Qty":"","SliType":"","PisNo":""};
			$("#TCTSpecListNew").datagrid('appendRow',rowObj);
			//$('#PisSpecList').datagrid('updateRow',{index:rowNo, row:rowObj});		
		}
		
		// 删除后,重新排序
		//$('#PisSpecList').datagrid('sort', {sortName: 'No',sortOrder: 'asc'});
		//删除后,根据标本序号重新排序,并重新编号
		sortTable();
	}
	var rowNo=4;
	/// 插入空行
	function insRow(){
		
		if (isPageEditFlag == 0) return;
		//var rowObj={No:rowNo, ID:'', Name:'', Part:'', Qty:''};
		rowNo += 1;
		var rowObj = {"No":rowNo,"Name":"","Explain":"","Part":"","Qty":"","SliType":"","PisNo":""};
		$("#TCTSpecListNew").datagrid('appendRow',rowObj);
		if ((editSelRow != -1)||(editSelRow == 0)) { 
            $("#TCTSpecListNew").datagrid('endEdit', editSelRow); 
        }
		sortTable()
		
	}
	function sortTable(){
		var tmpNum = 1;
		var arr = [];
		var selItems = $('#TCTSpecListNew').datagrid('getRows');
		$.each(selItems, function(index, item){
			var tepObj = {"No":tmpNum ,"Name": item.Name,"Part":item.Part,"Qty":item.Qty};
			tmpNum += 1;
			arr.push(tepObj);
		});
		for (var i=0; i<arr.length; i++){	
			$('#TCTSpecListNew').datagrid('updateRow',{index:i, row:arr[i]});		
		}
		rowNo = tmpNum-1; 	//记录最大的行号
	  
	}
	function OtherInfo(){
		var PisSpecArr=[];
		var rows = $('#TCTSpecListNew').datagrid('getRows');
		//删除前结束所有的编辑行
		$.each(rows,function(index,data){
	              $("#TCTSpecListNew").datagrid('endEdit', index); 
		});
		var rowDatas = $('#TCTSpecListNew').datagrid('getRows');
		var PisReqSpec=""
		$.each(rowDatas, function(index, item){
			if(trim(item.Name) != ""){
			    var TmpData = item.No +"^"+ item.ID +"^"+ item.Name +"^"+ item.Part +"^"+ item.Qty +"^^^"+ "";
			    PisSpecArr.push(TmpData);
			    if (PisReqSpec==""){
					PisReqSpec = item.No+String.fromCharCode(1)+item.Name +String.fromCharCode(1)+ item.Part +String.fromCharCode(1)+ item.Qty +String.fromCharCode(1)+ ""+ String.fromCharCode(1)+ "";
				}else{
					PisReqSpec = PisReqSpec+String.fromCharCode(2)+item.No+String.fromCharCode(1)+item.Name +String.fromCharCode(1)+ item.Part +String.fromCharCode(1)+ item.Qty +String.fromCharCode(1)+ ""+ String.fromCharCode(1)+ "";
				}
			}
		})
		var PisSpec = JSON.stringify(PisSpecArr);
		var rtnObj = {}
		rtnObj["PisSpec"] = PisSpec;
		rtnObj["PisReqSpec"] = PisReqSpec;
		return rtnObj
		}
	function LoadOtherInfo(){
		var OtherInfo=""
		if (itemReqJsonStr!=""){
			for (var i = 0; i < itemReqJsonStr.length; i++) {
				var OneReqJson=itemReqJsonStr[i]
				var ID=OneReqJson.ID
				var Val=OneReqJson.Val
				if (ID=="OtherInfo") OtherInfo=Val
			}
		}
		if (OtherInfo!=""){
			OtherObj=$.parseJSON(OtherInfo); 
			PisSpec=$.parseJSON(OtherObj["PisSpec"])
			/*setTimeout(function(){
				for (var i = 0; i < PisSpec.length; i++) {
					var PisArry=PisSpec[i]
					var PisArryStr=PisArry.split("^")
					var rowObj = {"No":PisArryStr[0],"Name":PisArryStr[2],"Explain":"","Part":PisArryStr[3],"Qty":PisArryStr[4],"ID":PisArryStr[1],"SepDate":PisArryStr[8],"FixDate":PisArryStr[9]};
					var Index= parseFloat(PisArryStr[0])-1
					$('#PisSpecList').datagrid('updateRow',{index: Index, row:rowObj});
					
				} 
			}, 1000);*/
			}
	}
	function PrintInfo(){
		var PisSpecArr=[];
		var rows = $('#TCTSpecListNew').datagrid('getRows');
		//删除前结束所有的编辑行
		$.each(rows,function(index,data){
	        $("#TCTSpecListNew").datagrid('endEdit', index); 
		});
		var rowDatas = $('#TCTSpecListNew').datagrid('getRows');
		var PisSpec="标本序号"+ "^"+"标本名称"+ "^"+"部位"+ "^"+"数量"
		$.each(rowDatas, function(index, item){
			if(trim(item.Name) != ""){
				if (PisSpec==""){
					 PisSpec =item.No+ "^"+item.Name+ "^"+item.Part+ "^"+item.Qty;
				}else{
					PisSpec = PisSpec+"*AABCD*"+item.No+ "^"+item.Name+ "^"+item.Part+ "^"+item.Qty	
				}
			}
		})
		var rtnObj = {}
		rtnObj["List"] = PisSpec;
		return rtnObj
	}
	return {
		"Init":Init,
		"OtherInfo":OtherInfo,
		"PrintInfo":PrintInfo,
		"insRow":insRow,
		"delRow":delRow
	}
})();
```
