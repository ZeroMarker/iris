## 医保电子凭证

```objectscript
// d ##class(DHCDoc.OPDoc.PatientList).CheckCardValue("1","1")

ClassMethod CheckCardValue(cardTypeId As %String, cardNo As %String) As %String [ Private ]
{
	q:( (cardTypeId="") || ('$d(^DHCCARDTYPEDef(cardTypeId))) ) ""
	s ^tempchen("111")=cardNo
	s temp = cardNo
	s ls=^DHCCARDTYPEDef(cardTypeId)
	s len=$p(ls,"^",17)
	for i=$l(cardNo)+1:1:(+len) {
		s cardNo="0"_cardNo
	}
	if '$d(^DHCCARDi("CF",0,"CardNo",cardNo)) s cardNo=""
	if cardNo'="",'$d(^DHCCARDi("CF",0,"CardTypeNo",cardTypeId,cardNo)) s cardNo=""
	
	if ((($l(temp,":") = 5) || ($l(temp) = 101))&& (cardTypeId = 30)){
		s temp = $p(temp,":",1)	
		s rtn = ##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).GetHealthCardInfoByCardNo(temp)
		s cardNo = $p(rtn,"^",3)
	}
	
	if (($l(temp) = 28) && (cardTypeId = 30)) {
		if ($d(^temp("card",temp)) = 0) {
			s rtn = ##class(web.DHCDocMain).GetInsuInfoByCardNo(temp)
			s card = $p(rtn,"^",3)
			s:card'="" ^temp("card",temp) = card
		}
		else {
			s card = ^temp("card",temp)
			k ^temp("card",temp)
		}
		;s ^tempzt("rtn11",$zdt($h,3),$j)=temp_"^"_cardTypeId_"^"_rtn
		s cardNo = card
	}
	
	q cardNo
}
```