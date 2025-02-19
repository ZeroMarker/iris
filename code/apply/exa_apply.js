/**
 * * my function
 * TODO: scripts/dhcdoc/OEOrder.Common.Control.js
 * * comment
 * * 检查申请 取消自动关闭
 * ! not use
 * ? info
 * @param {string} url
 * @param {string} method
 * @param {string} data
 * @param {string} CallBackFunc
 * @param {string} CallBackFunc
 */
CallBackFunc:function(rtnStr){
    websys_showModal("close");
    if (typeof rtnStr=="undefined"){
        rtnStr="";
    }
    if (rtnStr=="") {
        $.messager.alert("提示","检查未填写申请单,请再次点击【审核医嘱】申请或删除检查医嘱.","info",function(){
            callBackFun("");
        });  
    }else{
        result=rtnStr;
        resolve();
    }
}


CallBackFunc:function(rtnStr){
    if (typeof rtnStr=="undefined"){
        rtnStr="";
    }
    if (rtnStr=="") {
        websys_showModal("close");
        $.messager.alert("提示","检查未填写申请单,请再次点击【审核医嘱】申请或删除检查医嘱.","info",function(){
            callBackFun("");
        });  
    }else{
        if (rtnStr.split("@")[1] != "" && rtnStr.split("@")[1] != undefined) {
            websys_showModal("close");
            rtnStr = rtnStr.split("@")[0];
        }
        result=rtnStr;
        resolve();
    }
}

CallBackFunc:function(rtnStr){
    if (typeof rtnStr=="undefined"){
        rtnStr="";
    }
    if (rtnStr.split("@")[1] != "" && rtnStr.split("@")[1] != undefined) {
        websys_showModal("close");
        rtnStr = rtnStr.split("@")[0];
    }
    if (rtnStr=="") {
        $.messager.alert("提示","检查未填写申请单,请再次点击【审核医嘱】申请或删除检查医嘱.","info",function(){
            //callBackFun("");
            UpdateClickHandlerFinish();
        }); 
        return websys_cancel(); 
    }else{
        
        result=rtnStr;
        resolve();
    }
