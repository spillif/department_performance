select JDE_Source as Region, t1.Branch, ItemNumber, ItemDescription, Brand, OrderType, ActualShipDate, ItemFirstDateToSell,
		BranchStockingType, QtyShipped, month(ActualShipDate) as MonthShipped, year(ActualShipDate) as YearShipped,
		ProductGroup, ProductType, ItemSubGroup, Supplier,
		year(ActualShipDate) * 100 + month(ActualShipDate) as yearMonth,
		Qty_OnHand, QtyBackOrder, QtyOnReceiptPO, BackOrderStartDate, POOriginalpromisedate,
		case
			when datediff(mm, ActualShipDate, getdate()) > 24 then 24
			else datediff(mm, ActualShipDate, getdate())
		end as ItemActiveMonths,
		case
			when datediff(mm, ActualShipDate, getdate()) < 1 then null
			when datediff(mm, ActualShipDate, getdate()) > 24 then IBC.ItemBranchShippedQty / 24
			else QtyShipped / datediff(mm, ActualShipDate, getdate())
		end  as MAC
from
	(select ifc.[SOURCE] as JDE_Source, cast(dbo.JulianToGregorian(ifc.IBECOD) as date) as ItemFirstDateToSell, ifc.WARRANTY_CODE as WarrantyCode, ltrim(rtrim(ifc.ITEMNAME)) as ItemNumber,
			ifc.BRANCH as Branch, ifc.ITEM_DESCRIPTION as ItemDescription, ifc.PRODUCT_TYPE as ProductType, ifc.PRODUCT_GROUP as ProductGroup, ifc.ITEM_GROUP as ItemSubGroup,
			ifc.STOCK_TYPE_MASTER as ItemStockingType, ifc.BRAND as Brand, ifc.STOCK_TYPE_BRANCH as BranchStockingType, cast(dbo.JulianToGregorian(ifc.FIRST_RECEIPT_DATE_JDE) as date) as FirstReceiptDate,
			ifc.SUPPLIER_NUMBER, ifc.SUPPLIER_NAME as Supplier, ifc.FIRST_RECEIPT_BRANCH, /*ifc.FLASH_CODE, ifc.FLASH_DESC,*/  ifc.MinReorderQTy,
			so.SDDCTO as OrderType, sum(so.SDSOQS) as QtyShipped, cast(dbo.JuliantoGregorian(so.SDADDJ) as date) as ActualShipDate
	from
		SVP_DSX_Production.dbo.PSI_ITEMS_FOR_CONSUMPTION ifc
	left join SVP_DSX_Production.dbo.PSI_SalesOrders so 
		on
			ltrim(rtrim(ifc.ITEMNAME)) = ltrim(rtrim(so.IBLITM)) and
			ltrim(rtrim(ifc.BRANCH)) = ltrim(rtrim(so.IBMCU)) and
			ltrim(rtrim(ifc.BRANCH)) in ('18991','VP07','VP10','VP15','CA03','18498')
	where
		so.SDDCTO not in ('C1','C4','CH','CI','CJ','CO','SH','S8','S9','TV')
	group by
		ifc.[SOURCE], ifc.IBECOD, ifc.WARRANTY_CODE, ltrim(rtrim(ifc.ITEMNAME)), ifc.BRANCH, ifc.ITEM_DESCRIPTION, ifc.PRODUCT_TYPE,
		ifc.PRODUCT_GROUP, ifc.ITEM_GROUP, ifc.STOCK_TYPE_MASTER, ifc.STOCK_TYPE_BRANCH, ifc.SUPPLIER_NUMBER, ifc.BRAND, ifc.SUPPLIER_NAME,
		ifc.FIRST_RECEIPT_DATE_JDE, ifc.FIRST_RECEIPT_BRANCH, ifc.FLASH_CODE, ifc.FLASH_DESC, ifc.MinReorderQTy,
		so.SDDCTO, so.SDADDJ
	) t1
left join
		(select JDE_Source as IBSource, SDLITM, SDMCU, sum(SDSOQS) as ItemBranchShippedQty
		from SVP_DSX_Production.dbo.PSI_SalesOrders
		where SDMCU in ('18991','VP07','VP10','VP15','CA03','18498')
		group by JDE_Source, SDLITM, SDMCU
		) IBC
	on
		JDE_Source = IBC.IBSource and
		ItemNumber = IBC.SDLITM and
		Branch = IBC.SDMCU
left join
		(select ITEMNAME, BRANCH, sum(ON_HANDS) as Qty_OnHand
		from SVP_DSX_Production.dbo.PSI_INVENTORY
		group by ITEMNAME, BRANCH
		) INV
	on
		t1.ItemNumber = INV.ITEMNAME and
		t1.Branch = INV.BRANCH
left join
		(select ltrim(rtrim(ITEM)) as Item, ltrim(rtrim(BRANCH)) as Branch,
		SUM(QtyBackOrder) as QtyBackOrder, SUM(QtyOnReceiptPO) as QtyOnReceiptPO
		from SVP_DSX_Production.dbo.PSI_BackOrder_QtyOnReceipt
		where  ltrim(rtrim(BRANCH)) in ('18991','VP07','VP10','VP15','CA03','18498')
		and (QtyBackOrder <> 0 or QtyOnReceiptPO <> 0)
		group by ltrim(rtrim(ITEM)), ltrim(rtrim(BRANCH))
		) R
	on
		t1.ItemNumber = R.Item and
		t1.Branch = R.Branch
left join
		(select ltrim(rtrim(ITEMNAME)) as ItemName, ltrim(rtrim(BRANCH)) as Branch,
		min(FIRST_BO_DATE) as BackOrderStartDate, max(CLEAR_BO_DATE) as POOriginalpromisedate
		from SVP_DSX_Production.dbo.PSI_GLOBAL_BACKORDERS
		where ltrim(rtrim(BRANCH)) in ('18991','VP07','VP10','VP15','VP15','CA03','18498')
		group by ltrim(rtrim(ITEMNAME)), ltrim(rtrim(BRANCH))
		) S
	on
		t1.ItemNumber = S.ItemName and
		t1.Branch = S.Branch
left join SVP_DSX_Production.dbo.PSI_WAC_COST wc
	on
		ltrim(rtrim(t1.ItemNumber)) = ltrim(rtrim(wc.ITEMNAME)) and
		ltrim(rtrim(t1.Branch))  = ltrim(rtrim(wc.BRANCH))
left join SVP_DSX_Production.dbo.PSI_BASE_COST bc
	on
		ltrim(rtrim(t1.ItemNumber)) = ltrim(rtrim(bc.ITEMNAME)) and
		ltrim(rtrim(t1.Branch))  = ltrim(rtrim(bc.BRANCH))
left join SVP_DSX_Production.dbo.PSI_LIST_PRC lp
	on
		ltrim(rtrim(t1.ItemNumber)) = ltrim(rtrim(lp.ITEM)) and
		ltrim(rtrim(t1.Branch))  = ltrim(rtrim(lp.BRANCH))
where
	ProductGroup in ('31','46','47') and
	((BranchStockingType in ('P') or ItemStockingType in ('P'))
	or (QtyShipped <> 0 or QtyOnReceiptPO <> 0 or QtyBackOrder <> 0 or Qty_OnHand <>0)
	)
;
