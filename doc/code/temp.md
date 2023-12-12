```objectscript
ClassName: web.DHCIPBillPATCostInquriy
QueryName: FindBillCateFee
billId: 
stDate: 
endDate: 
ordDeptId: 191
episodeId: 37
userDeptId: 
recDeptId: 

/// desc: 获取总费用
/// input: DeptId 科室 EpisodeId 就诊号
/// output: CateAmt	总费用
/// w ##class(web.DHCDocMain).GetBillFee(191,37)
ClassMethod GetBillFee(DeptId, EpisodeId)
{
    s query = ##class(%ResultSet).%New("web.DHCIPBillPATCostInquriy:FindBillCateFee")

    s DeptId
    if (query) {
        s rc = query.Execute("","","",DeptId,EpisodeId,"","","")
        while (query.Next()) {
            // {TCateDesc: "合计", TCateAmt: "33200.87", TCateId: ""}
            s desc = query.Data("TCateDesc")
            if desc="合计" {
                s amount = query.Data("TCateAmt")
            }
        }
    }
    d query.%Close()
    q amount
}

```