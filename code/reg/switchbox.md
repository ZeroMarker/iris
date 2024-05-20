## 号别列表悬浮弹窗切换可用
var str = `$('#${LinkID}').popover('hide'); }\">`;
	// 创建 switchbox
	if (Title != "") {
		Title = "<span>" + Title + "</span>"
		// Title += "<a href=\"#\" style=\"float:right;\" class=\"hisui-linkbutton\" data-options=\"iconImg:'update.png'\">测试按钮</a>"
		Title += "<div id=\"switch-btn\" class=\"hisui-switchbox hisui-tooltip\""
		Title += 		"style=\"float:right;margin-left:5px;margin-right:5px;padding:0.5px 0px;\""
		Title += 		"title=\"可用不显示无号时段\""
		Title += 		"data-options=\"onText:'全部',offText:'可用',size:'mini',animated:true,"
		if (PageLogicObj.m_TrShowFlag == 1) {
			Title += "checked:true,"
		} else {
			Title += "checked:false,"
		}
		Title += 			"onClass:'primary',offClass:'success',position:'bottom',"
		Title +=			"onSwitchChange:function(event,obj){ if (obj.value) { PageLogicObj.m_TrShowFlag = 1  } else { PageLogicObj.m_TrShowFlag = 0 } LoadMarkList(); "+str
		Title += "</div>"
		Title += "<div style=\"clear:both;\"></div>"
	}


Title +=			"onSwitchChange:(function(param){"
Title +=			"	return function(event,obj){"
Title +=			"		if (obj.value) {"
Title +=			"			PageLogicObj.m_TrShowFlag = 1;"
Title +=			"		} else {"
Title +=			"			PageLogicObj.m_TrShowFlag = 0;"
Title +=			"		}"
Title +=			"		DestoryPannelPopover();"
Title +=			"		InitMarkListRowPopover(param);"
Title +=			"	}"
Title +=			"})({rowIndex:'"+RowIndex+"',markCardID:'"+markCardID+"',Show:true})"
Title +=			"\">"

var rowIndex=param.rowIndex;
	var markCardID=param.markCardID;
	var Show=param.Show;