## 滚床位费
d first^CHQTASKNEW(2)
床位类型 费别 全自费
床位 费用设置 附加费

```objectscript
CHQTASKNEW	;滚医嘱、床位费
	;This program is develped to use instand of Task job on Cache.
	;At first, CHPAT13 and CHBB1 run.
	;CHBB0 have to run at last.
	q
all	;
	w !," Namepace: "_$zu(5)_".   Task Job Start."  
	;d all^CHQTASKNEW
	lock +CHQTASKNEW:20
	i $TEST {
		d ClrResQty^DHCSTSYNSTK
		s HOSPRowId=0
		for {
			s HOSPRowId=$o(^CT("HOSP",HOSPRowId)) Q:HOSPRowId=""
			d first(HOSPRowId)
			d second(HOSPRowId)
		}
		//d first
		//d second
		d last
		d forth
		d fifth
		;d six()
		;d seven 
		w !!," Namepace: "_$zu(5)_".   Task Job Finish.",!
		lock -CHQTASKNEW
	}else{
		w !!," 任务加锁失败，请核实各服务器是否存在重复的滚医嘱任务",!
	}

	q
	;
;床位费      
first(HOSPRowId)	;Daily Bed Add
	w !!,"   CHBB1 : Daily Bed. "_$zd($h,3)_" "_$zt($p($h,",",2))
	d all^CHBB1NEW(HOSPRowId)
	q
	;
;医嘱
second(HOSPRowId)	;Standing Order
	w !,"   CHPAT13 : Standing order. "_$zd($h,3)_" "_$zt($p($h,",",2))
	d all^CHPAT13NEW(HOSPRowId)
	w !,"   DHCDocEmergRollOrder : Standing order. "_$zd($h,3)_" "_$zt($p($h,",",2))
	d all^DHCDocEmergRollOrder(HOSPRowId)
	q
	; 
last	;Daily Deposit Calculatetion
	w !,"   CHBB0 : Daily Deposit calculation. "_$zd($h,3)_" "_$zt($p($h,",",2))
	d all^CHBB0NEW
	q
forth
	w !,"   CHBB0 : Daily Deposit calculation. "_$zd($h,3)_" "_$zt($p($h,",",2))
	;d AutoIns^DHCWorkLoad
	q
 
    ;yys:2006-12-19  加血库日消耗表
fifth 	
    ;w !,"  DHCCALSTOCK : Daily Deposit calculation. "_$zd($h,3)_" "_$zt($p($h,",",2))
	;zn "labdata"
	;d DHCCALSTOCK^AutoInsDayStock
	;zn "meddata"
	;q
```