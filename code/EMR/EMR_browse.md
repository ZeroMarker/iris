```js
/// 病历浏览
function EMRBtnClickHandler(){
	var src="websys.chartbook.hisui.csp?ChartBookID=70&PatientListPanel=emr.browse.episodelist.csp&PatientListPage=emr.browse.patientlist.csp&SwitchSysPat=N&LayoutType=2"+"&PatientID="+PatientID+"&EpisodeID="+EpisodeID;
	src=('undefined'!==typeof websys_writeMWToken)?websys_writeMWToken(src):src;
    var dw=$(window).width()-200;
	var dh=$(window).height()-80;
	var $code ="<iframe width='100%' height='100%' scrolling='auto' frameborder='0' src='"+src+"'></iframe>" ;
	createModalDialog("Project","病历浏览", dw+160, dh+200,"icon-w-edit","",$code,"");
}
function createModalDialog(id, _title, _width, _height, _icon,_btntext,_content,_event){
    $("body").append("<div id='"+id+"' class='hisui-dialog'></div>");
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
        //href: _url,
        collapsible: false,
        minimizable:false,
        maximizable: false,
        resizable: false,
        modal: true,
        closed: false,
        closable: true,
        content:_content,
        onClose:function(){
	        destroyDialog(id);
	    }
    });
}
```