select inadm_xstring7,* from INSU_AdmInfo;
SELECT * from INSU_DicData;
```objectscript
INADMInsuType = $p(^DHCINDID($o(^DHCINDID("0","ITypeCode",'insutype00A',$p(^DHCINADM($o(^DHCINADM("0","ADM",EpisodeID,0))),"^",37),0))),"^",3)

INADMInsuType = $p(^DHCINADM($o(^DHCINADM("0","ADM",EpisodeID,0))),"^",37)

INADMCompany = $p(^DHCINADM($o(^DHCINADM("0","ADM",EpisodeID,0))),"^",6)

$p(^DHCINADM($o(^DHCINADM("0","ADM",EpisodeID,0))),"^",6)

/// desc:获取患者参保类型
/// input: EpisodeID 就诊号
/// output: InsuType 参保类型
/// debug: w ##class(web.DHCDoc.OP.AjaxInterface).GetInsuType()  
ClassMethod GetInsuType(EpisodeID As %String) As %String
{
	Q:EpisodeID="" ""
	s InsuType=""
	s InsuAdm = $o(^DHCINADM("0","ADM",EpisodeID,0))
	s InsuDic = $o(^DHCINDID("0","ITypeCode","insutype00A",$p(^DHCINADM(InsuAdm),"^",37),0))
	s InsuType = $p(^DHCINDID(InsuDic),"^",3)
    Q InsuType
}
/// desc:获取患者参保单位
/// input: EpisodeID 就诊号
/// output: InsuType 参保单位
/// debug: w ##class(web.DHCDoc.OP.AjaxInterface).GetInsuCompany()  
ClassMethod GetInsuCompany(EpisodeID As %String) As %String
{
	Q:EpisodeID="" ""
	s InsuType=""
	s InsuAdm = $o(^DHCINADM("0","ADM",EpisodeID,0))
	s InsuCompany = $p(^DHCINADM(InsuAdm),"^",6)
    Q InsuCompany
}
```