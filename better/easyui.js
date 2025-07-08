// 获取选中的标签页（tab）的文本
var selectedTabText = $('#tabs').tabs('getSelected').panel('options').title;

// css样式
$("#DeptList").css('height',$(window).height()-395);

// reload datagrid
$('#allergytb').datagrid('load', {   
    PatientID:PatientID
});

// 下拉框text取value
$("#mySelect option:contains('" + text + "'):selected").val();

/// 表格列排序
// datagrid:
// remoteSort:false

$('#Combo_Arcim').combogrid({
    panelWidth:500,
    panelHeight:400,
    delay: 500,    
    mode: 'remote',    
    // request.csp
    // websys.Broker.cls
    url:$URL+"?ClassName=DHCDoc.DHCDocConfig.ItemOrderQtyLimit&QueryName=FindItem",
    //url:$URL+"?ClassName=DHCDoc.DHCDocConfig.ArcItemConfig&QueryName=FindAllItem",
    fitColumns: true,   
    striped: true,   
    editable:true,   
    pagination : true,//是否分页   
    rownumbers:true,//序号   
    collapsible:false,//是否可折叠的   
    fit: true,//自动大小   
    pageSize: 10,//每页显示的记录条数，默认为10   
    pageList: [10],//可以设置每页记录条数的列表   
    method:'post', 
    idField: 'ArcimRowID',    
    textField: 'ArcimDesc',    
    columns: [[    
        {field:'ArcimDesc',title:'名称',width:400,sortable:true},
        {field:'ArcimRowID',title:'ID',width:120,sortable:true},
        {field:'selected',title:'ID',width:120,sortable:true,hidden:true}
    ]],
    onSelect: function (){
        var selected = $('#Combo_Arcim').combogrid('grid').datagrid('getSelected');  
        if (selected) { 
          $('#Combo_Arcim').combogrid("options").value=selected.ArcimRowID;
        }
     },
     onBeforeLoad:function(param){
         var desc=param['q'];
         var HospId=$HUI.combogrid('#_HospList').getValue();
         param = $.extend(param,{Alias:param["q"],HospId:HospId});
     }
});

// 弹窗
window.open(url, "newwindow", "height=850, width=1750, toolbar =no,top=100,left=100,menubar=no, scrollbars=yes, resizable=yes, location=no,status=no");

// ie打开
var Path = '"C:\\Program Files (x86)\\Internet Explorer\\iexplore.exe" "'+url+'"';
exec(Path);