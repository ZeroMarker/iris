

// 获取选中的标签页（tab）的文本
var selectedTabText = $('#tabs').tabs('getSelected').panel('options').title;




$("#DeptList").css('height',$(window).height()-395);

// reload datagrid
$('#allergytb').datagrid('load', {   
    PatientID:PatientID
});


// 下拉框text取value

$("#mySelect option:contains('" + text + "'):selected").val();




// datagrid:
// remoteSort:false