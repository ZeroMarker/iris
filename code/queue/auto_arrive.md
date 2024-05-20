var PageLogicObj={
	QueId:""
};
$(function(){
	//事件初始化
	InitEvent();
	//页面元素初始化
	PageHandle();
	$('#RegNo').focus();
});
function InitEvent(){
	$("#BUpdate").click(ArriveClickHandle);
	$("#RegNo").keydown(RegSearch);
}
function PageHandle(){
	
}
function RegSearch(e){
	var key=websys_getKey(e);
	if (key==13) {
		ClearList();
		var RegNo=$('#RegNo').val();
		var len = 10;
		if (RegNo.indexOf('Z')!=-1) {
			//GetRegNoByCard
			var RegNo = tkMakeServerCall("web.DHCDocMain","GetRegNoByCard",RegNo);
			$('#RegNo').val(RegNo)
		}
		else {
			for (var i = RegNo.length; i < len; i++) {
				RegNo = "0" + RegNo;	
			}
			$('#RegNo').val(RegNo);
		}
		
		var json = tkMakeServerCall("web.DHCDocMain","GetRegDeptJson",RegNo);
		var json = JSON.parse(json);
		var len = json.length
		if (len == 0) {
			$.messager.popover({msg: '无挂号记录',type:'alert'});
			AfterArrive();
			return false;
		}
		if (len == 1) {
			var rtn = tkMakeServerCall("web.DHCAlloc","PatArrive","","",json[0].Que);
			if (rtn = "0") {
				$.messager.popover({msg: '报道成功!',type:'success'});
				CreateList(json,len);
				AfterArrive();
				return;
			}
			else {
				$.messager.popover({msg: '报道失败!',type:'alert'});
				AfterArrive();
				return;
			}
		}
		CreateList(json,len);
	}
}
function CreateList(json,len) {
	var container = document.getElementById('DeptList');
	var checkboxes = document.querySelectorAll('.checkbox-group');
	for(var i = 0; i < len; i++) {
	    // 创建checkbox元素
	    var item = json[i];
	    var checkbox = document.createElement('input');
	    checkbox.type = 'checkbox';
	    checkbox.id = item.Que; // 设置id
	    checkbox.name = 'uniqueGroup'; // 设置name属性，使得所有checkbox属于同一组
	    checkbox.checked = false; // 默认不选中
	    // 为checkbox添加点击事件监听器
	    checkbox.addEventListener('click', function() {
		      // 如果这个checkbox被选中
		      if (this.checked) {
			        // 遍历所有同组的其他checkbox并取消它们的选中状态
			        var checkboxes = container.querySelectorAll('input[name="uniqueGroup"]');
			        for (var j = 0; j < checkboxes.length; j++) {
				        var otherCheckbox = checkboxes[j];
				        if (otherCheckbox !== this) {
			            	otherCheckbox.checked = false;
			        	}
				    }
				    PageLogicObj.QueId = this.id;
		      }
	    });
	    // 创建label元素
	    var label = document.createElement('label');
	    label.htmlFor = item.Que; // 设置label的for属性与checkbox的id对应
	    label.textContent = "已挂科室"+item.Index + ": " +item.LocDesc; // 设置label的文本内容

	    // 创建一个包含checkbox和label的div
	    var checkboxGroup = document.createElement('div');
	    checkboxGroup.className = 'checkbox-group';
	    checkboxGroup.appendChild(label);
	    checkboxGroup.appendChild(checkbox);
	    

	    // 将这个div添加到容器中
	    container.appendChild(checkboxGroup);
	 }
}
function ArriveClickHandle(){
	var Que = PageLogicObj.QueId;
	if (Que == "") {
		$.messager.popover({msg: '无挂号记录',type:'alert'});
		AfterArrive();
		return false;
	}
	var rtn = tkMakeServerCall("web.DHCAlloc","PatArrive","","",Que);
	if (rtn = "0") {
		$.messager.popover({msg: '报道成功!',type:'success'});
		AfterArrive();
		return;
	}
	else {
		$.messager.popover({msg: '报道失败!',type:'alert'});
		AfterArrive();
		return;
	}
}

function AfterArrive() {
    // 使用sleep函数创建一个200毫秒的延迟
    sleep(500, function() {
		ClearList();
        $('#RegNo').val(''); // 清空#RegNo输入框的值
        $('#RegNo').focus();  // 使#RegNo输入框获得焦点
        PageLogicObj.QueId = ""; // 重置PageLogicObj对象的QueId属性
    });
}

// sleep函数的实现，接受一个毫秒数和一个回调函数作为参数
function sleep(ms, callback) {
    setTimeout(callback, ms); // 在指定的毫秒数后执行回调函数
}

function ClearList() {
	 // 获取所有具有checkbox-group类的div元素
    var checkboxes = document.querySelectorAll('.checkbox-group');

    // 使用for循环遍历这些div元素并移除它们
    for (var i = checkboxes.length - 1; i >= 0; i--) {
        var checkbox = checkboxes[i];
        if (checkbox.parentNode) {
            checkbox.parentNode.removeChild(checkbox);
        }
    }
}
