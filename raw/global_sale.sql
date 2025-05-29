select *
from
	(select Period, level1, Report, ReportingCountry, Manufacturer, SalesCountry, Category, Model, ItemDescription, UnitSold, Channel, SVPChannel, Brand, SKU2,
		trim(case
				when left(SKU2, 3) = '850' or left(SKU2, 3) = '957' or left(SKU2, 3) = '230' or left(SKU2, 3) = '430' or left(SKU2, 3) ='300' then left(SKU2, 6)
				when left(SKU2, 4) = '114G' or left(SKU2, 4) = '131C' or left(SKU2, 4) = '141G' or left(SKU2, 4) = '142G' or left(SKU2, 4) = '151G' or left(SKU2, 4) = '152G' or left(SKU2, 4) = '154K'
				or left(SKU2, 4) = '154S' or left(SKU2, 4) = '191D' or left(SKU2, 4) = '191G' or left(SKU2, 4) = '251K' or left(SKU2, 4) = '314G' or left(SKU2, 4) = '322D'
				or left(SKU2, 4) = '323D' or left(SKU2, 4) = '324G' or left(SKU2, 4) = '351D' or left(SKU2, 4) = '351G' or left(SKU2, 4) = '514G' then left(SKU2,5)
				--when left(SKU2, 3) = '20G' or left(SKU2, 3) = '20U' then left(SKU2, 5)
				when len(SKU2) = 4 then left(SKU2,4)
				when left(SKU2,3) = 'S14' and right(SKU2,1) <> '-' then substring(SKU2,4,6)
				--when left(SKU2,1) = 'S' then substring(SKU2,2,4)
				when len(SKU2) = 5 and isnumeric(left(SKU2,5)) = 1 then right(SKU2,4)
				when len (SKU2) = 5 and isnumeric(left(SKU2,4)) = 1 then left(SKU2,4)
				when len(SKU2) = 4 and isnumeric(left(SKU2,4)) = 1 then left(SKU2,4)
				when left(SKU2,3) = '14T' then substring(SKU2,3,6)
				when left(SKU2, 2) = '14' then substring(SKU2,3,5)
				when left(SKU2, 6) = '4210SH' or left(SKU2, 6) = '4228SH' then left(SKU2, 6)
				else SKU2
			end) as SKU
	from
		(select Period, level1, Report, ReportingCountry, Manufacturer, SalesCountry, Category, Model, ItemDescription, UnitSold, Channel, SVPChannel, Brand, SKU1,
		left(SKU1, len(SKU1) - charindex('/', reverse(SKU1))) as SKU2
		from
			(select Period, level1, Report, ReportingCountry, Manufacturer, SalesCountry, Category, Model, ItemDescription, UnitSold, Channel, SVPChannel, Brand,
			left(Model, len(Model) - charindex('.', reverse(Model))) as SKU1
			from
				(select
					srl.Level1 as level1, srl.Level2, srl.Level3 as SalesCountry,
					sm.EntityID, sm.Period as Period, sm.Channel as Channel,
					s.SVPChannel as SVPChannel,
					cim.Category as Category, cim.Manfacturer as Manufacturer,
					cim.TrueType, cim.Type,
					cl.Region as SaleRegion,
					crc.ReportingCountry as ReportingCountry,
					max(si.ItemDescription) as ItemDescription, sum(sm.Units) as UnitSold,
					replace(trim(sm.LocalItem), '-', '') as Model, trim(cim.Brand) as Brand, trim(cim.SVPModel) as SVPModel, sm.Report as Report,
					getdate() as  RefreshedDate
				from
					CFM.dbo.SalesMargins sm
				left join CFM.CFMAccess.SVPChannel s
					on
						sm.Channel = s.Channel
				left join CFM.dbo.CFM_Location cl
					on sm.EntityID = cl.EntityID
				left join CFM.CFMAccess.CFMReportingCountry crc
					on
						sm.ReportingCountry = crc.ReportingCountry
				left join CFM.CFMAccess.CFMItemMaster cim
					on
						rtrim(ltrim(sm.Model)) = rtrim(ltrim(cim.Model))
				left join CFM.dbo.SalesItems si
					on
						rtrim(sm.LocalItem) = rtrim(si.LocalItem) and sm.EntityID = si.EntityID
				left join CFM.dbo.SVPReportingLevels srl
					on
						sm.EntityID = srl.EntityID and sm.Channel = srl.Channel and sm.ReportingCountry = srl.ReportingCountry
				where
					sm.Report = 0
					and cim.Category in  ('Machines', 'Industrial Machines')
					and trim(cim.Brand) in ('Singer', 'Pfaff', 'Viking')
					and sm.Units <> 0
				group by
					sm.EntityID, sm.Period, sm.LocalItem, sm.Report, sm.Channel,
					srl.Level1, srl.Level2, srl.Level3,
					s.SVPChannel,
					cim.Category, cim.Manfacturer,
					cl.Region,
					crc.ReportingCountry,
					 trim(cim.Brand), cim.TrueType, cim.Type, trim(cim.SVPModel)
				having
					sm.Period between 201901 and max(sm.Period)
				)  as t1
			) as t2
		) as t3
	)as t4
