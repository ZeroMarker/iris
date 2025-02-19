/// Function:学生
/// Creator: sunfengchao

var init = function(){  
    ///性别下拉框
    var StSexDRCombo=$('#StSexDR').combobox({  
        url:$URL+"?ClassName=web.Study.NewDayNTwo&QueryName=GetSexCmb&ResultSetType=array",
        valueField:'CTSEXRowId',
        textField:'CTSEXDesc' 
    }); 
    
    var columns =[[  
                  {field:'StCode',title:'学号',width:180,sortable:true},
                  {field:'StName',title:'姓名',width:180,sortable:true},  
                  {field:'StSexDR',title:'性别',width:180,sortable:true},
                  {field:'StDob',title:'出生日期',width:180,sortable:true},  
                  {field:'StRowId',title:'StRowId',hidden:true}
           ]];
    var mygrid = $HUI.datagrid("#mygrid",{
        url: $URL,
        queryParams:{
            ClassName:"web.Study.NewDayNTwo",
            QueryName:"GetList"
        }, 
        columns: columns,  
        pagination: true,   //pagination    boolean 设置为 true，则在数据网格（datagrid）底部显示分页工具栏。
        pageSize:20,
        pageList:[20,40,60,80,100,200], 
        singleSelect:true, 
        rownumbers:true,    //设置为 true，则显示带有行号的列。
        fitColumns:true, //设置为 true，则会自动扩大或缩小列的尺寸以适应网格的宽度并且防止水平滚动 
        onDblClickRow:function(rowIndex,rowData){
             UpdateData();
        }
    });
  
   //搜索回车事件
    $('#TextDesc,#TextCode').keyup(function(event){
        if(event.keyCode == 13) {
          SearchFunLib();
        }
    });  
    //查询按钮
    $("#btnSearch").click(function(e) { 
         SearchFunLib();
     })  
     
    //重置按钮
    $("#btnRefresh").click(function (e) { 
         ClearFunLib();
     })  
    
    //点击添加按钮
    $("#btnAdd").click(function(e){
        AddData();
    });
    //点击修改按钮
    $("#btnUpdate").click(function(e){
        UpdateData();
    });
    //点击删除按钮
    $("#btnDel").click(function (e) { 
        DelData();
    }); 
    
     //查询方法
    function SearchFunLib(){
        var code=$("#TextCode").val();
        var name=$('#TextDesc').val();
        $('#mygrid').datagrid('load',  { 
            ClassName:"web.Study.NewDayNTwo",
            QueryName:"GetList" ,  
            'Code':code,   
            'Name':name
        });
        $('#mygrid').datagrid('unselectAll');
    }
    
    //重置方法
    function ClearFunLib()
    {
        $("#TextCode").val("");
        $("#TextDesc").val("");
        $('#mygrid').datagrid('load',  { 
            ClassName:"web.Study.NewDayNTwo",
            QueryName:"GetList"
        });
        $('#mygrid').datagrid('unselectAll');
    }
    
     //点击新增按钮
    function AddData() { 
        $("#myWin").show(); 
        $("#StCode").val("");
        $("#StName").val(""); 
        $("#StSexDR").combobox("setValue","");
        $("#StDob").datebox("setValue","");
        var myWin = $HUI.dialog("#myWin",{
            iconCls:'icon-w-add',
            resizable:true,
            title:'新增',
            modal:true,
            buttonAlign : 'center',
            buttons:[{
                text:'保存', 
                id:'save_btn',
                handler:function(){
                    SaveFunLib("")
                }
            },{
                text:'关闭', 
                handler:function(){
                    myWin.close();
                }
            }]
        }); 
    }
 

    //点击修改按钮
    function UpdateData() {
        var record = mygrid.getSelected(); 
        if (record){           
            var id = record.StRowId; 
            $.cm({
                ClassName:"web.Study.NewDayFourN",
                MethodName:"OpenData",
                StRowId:id
            },function(jsonData){ 
                $('#form-save').form("load",jsonData); 
            });     
            $("#myWin").show(); 
            var myWin = $HUI.dialog("#myWin",{
                iconCls:'icon-w-edit',
                resizable:true,
                title:'修改',
                modal:true,
                buttons:[{
                    text:'保存', 
                    id:'save_btn',
                    handler:function(){
                        SaveFunLib(id)
                    }
                },{
                    text:'关闭', 
                    handler:function(){
                        myWin.close();
                    }
                }]
            });             
        }else{
            $.messager.alert('错误提示','请先选择一条记录!',"error");
        }
    }
    
    ///新增、更新
    function SaveFunLib(id)
    {            
        var StCode=$("#StCode").val();
        var StName=$("#StName").val();
        //var StSexDR=$("#StSexDR").combobox("getValue"); 
        //var StDob=$("#StDob").datebox("getValue");
        if (StCode=="")
        {
            $.messager.alert('错误提示','学号不能为空!',"error");
            return;
        }
        if (StName=="")
        {
            $.messager.alert('错误提示','姓名不能为空!',"error");
            return;
        }
        $.m({
            ClassName:"web.Study.NewDayFourN",
            MethodName:"SaveData",
            StRowId:id,
            StCode:StCode,
            StName:StName,
            StSexDR:StSexDR,
            StDob:StDob 
        },function(data){ 
              if (data.indexOf("成功")>0) {
                    $.messager.popover({msg: '提交成功！',type:'success',timeout: 1000}); 
                    $('#mygrid').datagrid('reload');  // 重新载入当前页面数据 
                    $('#mygrid').datagrid('unselectAll');
                    $('#myWin').dialog('close'); // close a dialog
              } 
              else { 
                var errorMsg ="保存失败！" 
                $.messager.alert('操作提示',errorMsg,"error");
            }  
        });
    }  

    ///删除
    function DelData()
    {    
        var row = $("#mygrid").datagrid("getSelected"); 
        if (!row)
        {   
            $.messager.alert('错误提示','请先选择一条记录!',"error");
            return;
        } 
        $.messager.confirm('提示', '确定要删除所选的数据吗?', function(r){
            if (r){ 
                var StRowId=row.StRowId; 
                $.m({
                    ClassName:"web.Study.NewDayFourN",
                    MethodName:"DeleteData",
                    StRowId:StRowId 
                },function(data){  
                             if (data.indexOf("成功")>0) {
                                $.messager.popover({msg: '删除成功！',type:'success',timeout: 1000}); 
                                $('#mygrid').datagrid('reload');  // 重新载入当前页面数据  
                                $('#mygrid').datagrid('unselectAll');
                              } 
                              else { 
                                var errorMsg ="删除失败！" 
                                $.messager.alert('操作提示',errorMsg,"error"); 
                            }  
                }) 
            }               
        });
    }  
 
};
$(init);

// sort
$(function(){
    $('#mygrid').datagrid({
        onSortColumn: function(sort, order){
            $('#mygrid').datagrid('reload',{
                sort: sort,
                order: order
            });
        }
    });
})  
