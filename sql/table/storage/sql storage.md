## intro

Global


```objectscript
// DataMaster

// index
(0,"Code",{CrsCode},{CrsRowId})

$i(^Course(0))
// Crs_RowId
d ##(User.Course).%BuildIndices()
```
## query
```objectscript
s id=0
for {
    s id=$o(^User.CourseD(id))
    s CrsCode=$lg($(^User.CourseD(id)), 4)
    q:id=""
}
/*
index sort
(0,"score",40,1)
(0,"score",60,4)
(0,"score",90,2)
*/
```
