## 同步医嘱疗程超量原因
ClassName: 
DHCDoc.OPDoc.MainFrame
MethodName: 
GetBtnCfgData
SELECT * FROM DocCFTreatStatusInfo
门诊框架显示信息配置
```JS
function SynchroOrdExceedReasonClickHandler(){
	var ids = $('#Order_DataGrid').jqGrid("getGridParam", "selarrrow");
    if (ids == null || ids.length == 0 || ids.length == 1) {
        $.messager.alert("警告", "请选择需要同步疗程超量原因的多行记录！");
        return;
    }
    debugger;
    var Find=0;
    //ids = ids.sort();
    // 下拉框文本
    var FirstExceedReason=GetCellData(ids[0], "ExceedReason");
    // 下拉框ID值
    var FirstExceedReasonValue= $("#" + ids[0] + "_" + "ExceedReason").val();
    debugger;
    var len = ids.length;
    for (var i = 1; i < len; i++) {
	    var OrderARCIMRowid = GetCellData(ids[i], "OrderARCIMRowid");
	    //空白行和已审核的不能同步
	    if ((OrderARCIMRowid!="")&&(CheckIsItem(ids[i]) == false)) {
		    //SetCellData(ids[i], "ExceedReason", FirstExceedReason);
		    debugger;
		    var obj = document.getElementById(ids[i] + "_" + "ExceedReason");
		    if (obj) {
				// 可编辑
				if (!FirstExceedReasonValue) {
					var FirstExceedReasonValue = $("#" + ids[i] + "_" + "ExceedReason" + " option:contains('" + FirstExceedReason + "')").val();
				}
				$("#" + ids[i] + "_" + "ExceedReason").val(FirstExceedReasonValue);
			}
			else {
				// 不可编辑
				$("#Order_DataGrid").setCell(ids[i], "ExceedReason", FirstExceedReason, "", "", true);
			}
			debugger;
		    Find=1;
		}
	}
	if (Find=="0"){
		$.messager.alert("警告", "没有需要同步的记录!");
        return;
	}
}
```