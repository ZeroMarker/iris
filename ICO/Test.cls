Class ICO.Test
{

ClassMethod QueryDB() As %Status
{
    set sqlquery = "SELECT * FROM ICO.inventory ORDER BY vendor_id"
    set rs = ##class(%SQL.Statement).%ExecDirect(,sqlquery)
    while rs.%Next() 
    { 
      Write !, rs.%Get("vendor_id")
    }
}

}
