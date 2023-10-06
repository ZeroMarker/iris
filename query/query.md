%Query

websys.Query
///实现Fetch, Close

%SQLQuery

不要忘记实现Fetch&Close
Studio
New Query
Input Parameter
Output Parameter


```objectscript
    set repid=$i(^CacheTemp)
    set ind=1

    s id=0
    for
    {
        s id=$o(^User.CourseD(id))
        q:id=""
        s CrsCode=$p(^User.CourseD(id),"^",2)
        if(CrsCode[:Code)
        {
            d OutputRow
        }
    }

    s qHandle=$lb(0,repid,0)
    quit $$$OK
OutputRow
    s ^CacheTemp(repid,ind)=$lb(,,,)
    s ind=ind+1
    ////
    quit
```
## Use Query()
```objectscript
// 1st way
s rs = ##class(%ResultSet).%New("web.PAAdm:QueryItem")

// 2rd way
s rs = ##class(%ResultSet).%New()
s rs.ClassName="web.PAAdm"
s rs.QueryName="QueryItem"

if (rs) {
    s rc = rs.Execute(Code,Desc)
    while (rs.Next()) {
        s Code = rs.Data("Code")
        w
    }
}
d rs.%Close()
```
```objectscript
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
