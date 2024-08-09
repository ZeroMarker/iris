w ##class(DHCExternalService.RegInterface.SelfRegMethods).LockOrder(^TMPSelfRegXML("Request","LockOrder"))

;是否启用分时段
s LockUseTimeRangeFlag=+(##class(DHCDoc.Interface.Outside.Config).GetConfigNode(GroupID,"LockUseTimeRange",HospitalId))
外部接口

预约方式限额，最大保留数
