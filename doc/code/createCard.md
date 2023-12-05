cardreg.hui.csp
cardreg.show.hui.csp

web.DHCEntity.PCA.PATMAS.cls    add property to middle store class

CardReg.hui.js
$("#NewCard").click(NewCardclick);
function GetPatDetailByPAPMINo() {
}

web.DHCBL.CARDIF.ICardRefInfo.cls
web.DHCBL.CARD.UCardPatRegBuilder.cls

web.DHCBL.CARD.UCardPaPatMasInfo.cls

User.PAPatMas.cls

web.DHCEntity.PCA.CardPatInfoReg.cls
建卡信息存储中间类
(.csp -> .show.csp -> .js -> .cls -> cls)
// 建卡信息回传
CardReg.hui.js
function GetPatDetailByPAPMINo()
ClassName: "web.DHCBL.CARD.UCardPaPatMasInfo",
MethodName: "GetPatInfoByPANo",
$o(^PAADM(5),-1)
4