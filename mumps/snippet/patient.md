```objectscript
Set PatientID = $ORDER(^PAPERi("PAPMI_PatNo",PatNo,0))
Set EpisodeID = 0
For {
	Set EpisodeID = $o(^PAPERdr(PatientID,"ADM","O",EpisodeID))
	Quit:EpisodeID=""
	Set ord = 0
	For {
		Set ord = $o(^OEORD(0,"Adm",EpisodeID,ord))
		Quit:ord=""
		Set item = 0
		For {
			Set item = $o(^OEORD(ord,"I",item))
            Quit:item=""
            Set exe = 0
            For {
                Set exe = $o(^OEORD(ord,"I",item,"X",exe))
                Quit:exe=""
            }
		}
	}
}
```