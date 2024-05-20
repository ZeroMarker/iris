## 诊断 诊断备注
```objectscript
;头痛(头痛);风湿(风湿)
s DiagStr = ""
f i=1:1:$l(Diagnosis,";"){
	s diag = $p($g(Diagnosis),";",i)
	set start = $FIND(diag, "(")  // Find the position of the opening parenthesis
	set end = $FIND(diag, ")", start)  // Find the position of the closing parenthesis starting from the position of the opening parenthesis

	if (start > 0) && (end > start) {  // Ensure both the opening and closing parentheses are found
		set Diag = $EXTRACT(diag, start, end-2)  // Extract the content between the parentheses
	}
	s:($g(Diag)'="")&&(DiagStr'="") DiagStr = DiagStr_";"_$g(Diag)
	s:($g(Diag)'="")&&(DiagStr="") DiagStr = $g(Diag)
}
s Diagnosis = DiagStr
	;chenhongliang
```