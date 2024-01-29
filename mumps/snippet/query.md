```objectscript
Query GetStudent() As %Query(ROWSPEC = "StCode:%String:学号,StName:%String:姓名,StSexDesc:%String:性别,StDob:%String:生日")
{
}

/// Creator:陈洪亮
/// d ##class(%ResultSet).RunQuery("web.ChenhongliangYSZ","GetStudent")
ClassMethod GetStudentExecute(ByRef qHandle As %Binary) As %Status
{
	set repid=$i(^CacheTemp)
    set ind=1
    
    set id=0
    for
    {
        s id=$o(^User.StudentD(id))
        q:id=""
        s StCode=$lg(^User.StudentD(id),2)
        s StName=$lg(^User.StudentD(id),3)
        s StSexDr=$lg(^User.StudentD(id),4)
        s StSexDesc=$lg(^User.CTSexD(StSexDr),3)
        s StDob=$lg(^User.StudentD(id),"^",5)
        s StDob=$zd(StDob,3)
        d OutputRow  
    }
    set qHandle=$lb(0,repid,0)
    quit $$$OK
OutputRow
	set Data=$lb(StCode,StName,StSexDesc,StDob)
    set ^CacheTemp(repid,ind)=Data
    set ind=ind+1
    quit
}

ClassMethod GetStudentClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = GetStudentExecute ]
{
	Set repid=$LIST(qHandle,2)
	Kill ^CacheTemp(repid)
	Quit $$$OK
}

ClassMethod GetStudentFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = GetStudentExecute ]
{
	Set AtEnd=$LIST(qHandle,1)
	Set repid=$LIST(qHandle,2)
	Set ind=$LIST(qHandle,3)
	//
	Set ind=$o(^CacheTemp(repid,ind))
	If ind="" {				// if there are no more rows, finish fetching
		Set AtEnd=1
		Set Row=""
	}
	Else      {				// fetch row
		Set Row=^CacheTemp(repid,ind)
	}
	// Save QHandle
	s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

```


```objectscript
// 1st way
s query = ##class(%ResultSet).%New("web.PAAdm:QueryItem")

// 2rd way
s query = ##class(%ResultSet).%New()
s query.ClassName="web.PAAdm"
s query.QueryName="QueryItem"

if (query) {
    s rc = query.Execute(Code,Desc)
    while (query.Next()) {
        s Code = query.Data("Code")
        if Code = 2 {
            s desc = query.Data("desc")
        }
    }
}
d query.%Close()
q amount
```
