code: web.DHCDocInPatPortalCommon.cls
error: 退费失败！退费失败：-1^执行记录已结算或完成,不能执行该操作！^医嘱停止错误！
other: zn "dhc-lisdata"

```sql
-- :;B:Billed;TB:To Bill;I:Ignore;R:Refunded;P:Paid;
select OEORI_ItemStat_DR->ostat_desc,OE_OrdItem->arcim_desc,* from OE_OrdItem 
where OEORI_RowId in ("2||198","2||199","2||200","2||202");
SELECT TOP 1000 OEORE_billed,OEORE_Order_Status_DR,* FROM oe_ordexec 
WHERE OEORE_OEORI_ParRef in ("2||198","2||199","2||200","2||202");
SELECT * from ARC_ItmMast ;
SELECT * from SQLUser.OEC_OrderStatus;
select * from SQLUser.OEC_Order_AdminStatus;
```