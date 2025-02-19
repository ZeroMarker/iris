```js
var rowid = GetEventRow(e);
OrderFirstDayTimeskeypresshandlerJump(rowid)
function OrderFirstDayTimeskeypresshandlerJump(rowid) {
	// 首日次数回车跳转下一行医嘱名称
	// 医嘱名称，不可编辑跳转用法
	// 用法，不可编辑跳转频次
	// 频次，不可编辑跳转首日次数
	// 首日次数，不可编辑递归调用跳转
	var RowNext = GetNextRowId(rowid);
	if (RowNext==rowid){
		Add_Order_row();
		RowNext=parseInt(RowNext)+1;
	}
	if ($("#"+RowNext+"_OrderName").val() == "" && !$("#"+RowNext+"_OrderName").hasClass("disabled")) {
		SetFocusCell(RowNext, "OrderName");
	}
	else{
		if ($("#"+RowNext+"_OrderInstr").val() == "" && !$("#"+RowNext+"_OrderInstr").hasClass("disabled")) {
			SetFocusCell(RowNext, "OrderInstr");
		}
		else {
			if ($("#"+RowNext+"_OrderFreq").val() == "" && !$("#"+RowNext+"_OrderFreq").hasClass("disabled")) {
				SetFocusCell(RowNext, "OrderFreq");
			}
			else {
				// 输入框不可编辑类为disable
				if (!$("#"+RowNext+"_OrderFirstDayTimes").hasClass("disable")) {
					SetFocusCell(RowNext, "OrderFirstDayTimes");
				}
				else {
					OrderFirstDayTimeskeypresshandlerJump(RowNext);
				}
			}
		}
	}
	return websys_cancel();
}
```