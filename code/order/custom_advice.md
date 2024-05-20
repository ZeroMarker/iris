## 自定义嘱托
门诊框架显示信息配置
```js
//自定义嘱托
function CustomAdvice_Click() {
	var Selrowids = GetSelRowId();
	if (Selrowids == "") {
		createModalDialog("Custom_Advice",$g("自定义嘱托"), 600, 400,"icon-edit",$g("确定"),"","医嘱嘱托备注","CustomAdviceBtn","AddCustomAdvice()",true);
	}
	else {
		var OrderNote = GetCellData(Selrowids[0],"OrderDepProcNote")
		createModalDialog("Custom_Advice",$g("自定义嘱托"), 600, 400,"icon-edit",$g("同步备注"),OrderNote,"医嘱备注","CustomAdviceBtn","SyncOrderNote()",true);
	}
}
function AddCustomAdvice() {
	// chen
	var OrderNote = $('#Custom_Advice_textarea').val();
    if (OrderNote != "") {
	    var result=$.cm({
	        ClassName:"DHCDoc.Order.Common",
	        QueryName:"LookUpItem",
	        desc:"嘱托",
	        ResultSetType:"array"
    	},false)
    	var item = result.filter(item => item.ItemID == "7435||1")
   		var rowsobj = $('#Order_DataGrid').getDataIDs();
        var rows = rowsobj.length;
        const greatestItem = Math.max(...rowsobj.map(Number));
		if($("#"+greatestItem+"_OrderName").val() != "") {
			Add_Order_row();
			var rowid = parseInt(greatestItem) + 1;
		}
		else {
			var rowid = greatestItem;
		}
		$("#"+rowid+"_OrderName").parent().parent().removeClass('OrderCritical');
		$("#" + rowid).find("td").removeClass("SkinTest");
		SetCellData(rowid, "OrderARCIMRowid","");
		SetCellData(rowid, "OrderARCOSRowid","");
		OrderItemLookupSelect(item[0],rowid);
		PageLogicObj.OrderNote = OrderNote;
		SetCellData(rowid,"OrderDepProcNote",OrderNote);
		destroyDialog('Custom_Advice');
    }
    else {
	    $('#Custom_Advice_textarea').focus();
	}
}
function SyncOrderNote() {
	// chen
	var ids = GetSelRowId();
	var OrderNote = $('#Custom_Advice_textarea').val();
	ids.forEach(id => {
		SetCellData(id,"OrderDepProcNote",OrderNote);
	});
	destroyDialog('Custom_Advice');
}
function createModalDialog(id, _title, _width, _height, _icon,_btntext,_content,_placeholder,_btnid,_event,closable){
	// chen
	if(_btntext==""){
	   var buttons="";
   }else{
	   var buttons=[{
			text:_btntext,
			iconCls:_icon,
			handler:function(){
				if(_event!="") eval(_event);
			},
			id: _btnid
		}]
   }
   if(!$('#'+id).size()){
    	$("body").append("<div id='"+id+"' class='hisui-dialog'></div>");
   }
    if (_width == null)
        _width = 800;
    if (_height == null)
        _height = 500;

    $("#"+id).dialog({
        title: _title,
        width: _width,
        height: _height,
        cache: false,
        iconCls: _icon,
        collapsible: false,
        minimizable:false,
        maximizable: false,
        resizable: false,
        modal: true,
        closed: false,
        closable: closable,
        //content:_content,
        content:"<textarea id='" + id + "_textarea' placeholder='"+_placeholder+"' style='width:99%; height:90%;'></textarea>",
        buttons:buttons,
        onClose:function(){
	        destroyDialog(id);
	    }
    });
    if (_content != "") {
		$("#"+id+"_textarea").val(_content);
	}
}
function destroyDialog(id){
	try{
		$("#"+id).dialog('close');
	}catch(e){
	}
	return
   $("body").remove("#"+id); //移除存在的Dialog
   $("#"+id).dialog('destroy');
}
```