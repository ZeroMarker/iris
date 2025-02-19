## 挂号成功后菜单跳转
/// creator:郭荣勇
/// date:2012-08-11
/// desc:根据安全组得到开始菜单
/// input:StartTMENU 开始菜单
/// w ##class(web.DHCDocOrderEntry).GetStartTMENU(239)
ClassMethod GetStartTMENU(GroupID As %String) As %String
{
	n (GroupID)
	s StartTMENU=""
	s StartWFRowid=##class(epr.GroupSettings).GetStartPage(GroupID)
    s MainMenuRowid=##class(epr.GroupSettings).GetMainMenu(GroupID)
    ;b ;chl 000
    if (StartWFRowid'="")&(MainMenuRowid'="") {
	    s Obj=##class(websys.WorkFlow).%OpenId(StartWFRowid)
	    ;s FirstItemDesc=$p(Obj.NamesGet(),"|")
	    s WorkFlowItemID=Obj.WorkFlowItems.GetAt(1).ItemGetObjectId()
	    b ; chl 001
	    d Obj.%Close()
	    if WorkFlowItemID'="" {
		    s WFIObj=##class(websys.WorkFlowItemDefinition).%OpenId(WorkFlowItemID)
		    s ComponentID=WFIObj.ComponentGetObjectId()
		    s Url=WFIObj.Url
		    d WFIObj.%Close()
		    if ComponentID'="" {
			    s LoopMenu=0
			    for {
				    s LoopMenu=$O(^websys.MenuI("SubMenuOf1",MainMenuRowid,LoopMenu))
				    q:LoopMenu=""
				    s LMObj=##class(websys.Menu).%OpenId(LoopMenu)
				    s LinkComponentID=LMObj.LinkComponentGetObjectId()
				    s LinkUrl=LMObj.LinkUrl
				    s WorkFlowID=LMObj.WorkFlowGetObjectId()
				    d LMObj.%Close()
				    ;1.按菜单关联的组件找
				    if ComponentID=LinkComponentID s StartTMENU=LoopMenu Q
				    ;2.如菜单未关联组件,按配置的工作流下的组件找
				    if (WorkFlowID'="") {
					    s SubWFObj=##class(websys.WorkFlow).%OpenId(WorkFlowID)
					    s SubFirstWFI=SubWFObj.WorkFlowItems.GetAt(1)
					    if $IsObject(SubFirstWFI) {
					    	if ComponentID=SubFirstWFI.Item.ComponentGetObjectId() s StartTMENU=LoopMenu Q
					    }
				    }
			    }
		    }
		    ;b ;001
		    ;w ",StartTMENU1="_StartTMENU_",Url="_Url_",ComponentID="_ComponentID_",MainMenuRowid="_MainMenuRowid
		    if (StartTMENU="")&&(Url'="") {
			    s LoopMenu=0
			    for {
				    s LoopMenu=$O(^websys.MenuI("SubMenuOf1",MainMenuRowid,LoopMenu))
				    q:LoopMenu=""
				    s LMObj=##class(websys.Menu).%OpenId(LoopMenu)
				    s LinkComponentID=LMObj.LinkComponentGetObjectId()
				    s LinkUrl=LMObj.LinkUrl
				    d LMObj.%Close()
				    ;b ;001
				    if (Url[LinkUrl)&&(LinkUrl'="") s StartTMENU=LoopMenu Q
                    // if Url=LinkUrl s StartTMENU=LoopMenu Q
			    }
			    b ;002
		    }
	    }
    }
    
    Q StartTMENU
}

SELECT *
FROM websys.menu
--where ID = 57618;
where caption like "挂号";

select *
from websys.WorkFlowItemDefinition
--where Url like "%&%";
WHERE ID = 50001;
