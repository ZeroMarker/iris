## *.csp
serverobj

grid => table

## Function
$(function() {

})

// ahead of window load
$(window).load(function() {

})
## session
%session.Data("CTLOCID")

<server>

%request.Get("StCode")

## Form 
<Form action="web.study.csp"><input name="code"><lable>
<server>%request.Get("code")
do something

show.csp    html

后台数据    ServerObj

<Server>
s EpisodeID=%request.Get("EpisodeID")
s ArcimDr=%request.Get("ArcimDr")
s AimDr=%request.Get("AimDr")
s ApplyDr=%request.Get("ApplyDr")
s Cqmxid=%request.Get("Cqmxid")
s CQMXBJEntity=##class(DHCAnt.Util.Common).GetClassPropertyList("DHCAnt.Base.Dto.CQMXBJ")
;s sysDateFormat=##class("websys.Conversions").DateFormat()
</Server>
<body>
	<csp:Include Page="dhcant.cqmx.bj.detail.show.csp">
	<SCRIPT language = 'javascript' >
		var ServerObj={
			EpisodeID:"#(EpisodeID)#",
			CQMXBJEntity:"#(CQMXBJEntity)#",
			ArcimDr:"#(ArcimDr)#",
			ApplyDr:"#(ApplyDr)#",
			AimDr:"#(AimDr)#",
			Cqmxid:"#(Cqmxid)#"
		};
	</SCRIPT>
	<script type="text/javascript" src="../scripts/DHCCPM_DOMComm.JS"></script>
	<script type="text/javascript" src="../scripts/dhcdocant/kss_hui/extend/cqmx.bj.detail.js"></script>
	
</body>