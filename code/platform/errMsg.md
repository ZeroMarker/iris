SELECT * FROM DHCDoc_ErrCodeRegister;
```objectscript
s str1 = ^OEORD(+oeorirowid,"I",$p(oeorirowid,"||",2),1)
s ItmMastDR=$p(str1,"^",2)
s ARCIMDesc=$p(^ARCIM(+ItmMastDR,$p(ItmMastDR,"||",2),1),"^",2)
s service = $p(^ARCIM(+ItmMastDR,$p(ItmMastDR,"||",2),8),"^",7)
if (service=6) && (AdmType="O") {
	s err = 1
}
// w ##class(web.UDHCStopOrderLook).StopOrder("""","""",""463||5&&&??"",""6"",""1"",""Y"")
//诊查费不能停止，医嘱项服务组为挂号组
	s service = $p(^ARCIM($p(Arcimid,"||",1),$p(Arcimid,"||",2),8),"^",7)
	if (service=6) && (AdmType="O") {
		;s ErrMsg=..%GetErrCodeMsg("-100010")
		s ErrMsg="诊查费不能撤销"
		s err = "-100010"
	}
```