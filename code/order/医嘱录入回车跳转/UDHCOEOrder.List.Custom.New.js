function OrderFirstDayTimeskeypresshandlerJump(rowid) {
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