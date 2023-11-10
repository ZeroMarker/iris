case "NeedDischgCond":
	(function(callBackFunExec){
		new Promise(function(resolve,rejected){
			//GlobalObj.ApacheFlag, GlobalObj.CurrentWard
			/*重症医学科二病区
			儿童重症监护病区
			急诊重症监护病区
			心脏重症监护病区
			神经重症监护病区
			重症医学科一病区
			SELECT *
			FROM PAC_Ward
			WHERE
			WARD_RowID IN
			(17, 7, 9, 37, 12, 33)
			*/
			
			if ([17, 7, 9, 37, 12, 33].includes(CurrentWard) && ApacheFlag == "N") {
				//alert("未填写阿帕奇评分，不能下出院医嘱");
				$.messager.confirm('确认对话框', "未填写阿帕奇评分，不能下出院医嘱", function(r){
							ReturnObj.SuccessFlag=true;
								callBackFunExec();
						});
				return
			}

			
			OpenDeathDate(FunCodeParams,resolve);
		}).then(function(returnObj){
			//ReturnObj.SuccessFlag=SuccessFlag;
			$.extend(ReturnObj, returnObj);
			callBackFunExec();
		})
	})(resolve);
	break;
;阿帕奇评分
if EpisodeID'="" {
	s ApacheFlag = ##class(web.DHCICUQualityControlStatistic).isHasApache(EpisodeID)
 	s obj=##class(User.PAAdm).%OpenId(EpisodeID)
 	s CurrentWard = obj.PAADMCurrentWardDR
 	d obj.%Close()
}
case "NeedCareOrd":
    (function(callBackFunExec){
        var TypeCode=ParamsArr[ParamsArr.length-1];
        new Promise(function(resolve,rejected){
            $.messager.confirm('确认对话框', ParamsArr.slice(0, ParamsArr.length-1), function(r){
                ReturnObj.SuccessFlag=true;
                if (r) {
                    var url="../csp/nur.hisui.orderNeedCare.csp?EpisodeID="+GlobalObj.EpisodeID+"&defaultTypeCode="+TypeCode;
                    websys_showModal({
                        url:url,
                        title:'需关注医嘱',
                        width:'97%',height:'85%',
                        onClose:function(retval){
                            callBackFunExec();
                        }
                    })
                }else{
                    callBackFunExec();
                }
            });
        })
    })(resolve);
    break;