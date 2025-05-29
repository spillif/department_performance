select CloseDate, CaseNumber, Country, Region, SerialNumber, ModelSKU, Model, ModelBrand,
	ReasonCode, wr.Name as ReasonDescription, RepairCode, ra.Name as RepairDescription, PartUsed
from
	(select distinct CaseNumber, ReasonCode, ModelBrand,
			RepairCode, CloseDate, Country, Region, SerialNumber, Model, ModelSKU,
		(case
			when
				substring(ReasonCode, 0, charindex(', ',ReasonCode)) = 0 then ReasonCode
				else substring(ReasonCode, 0, charindex(', ',ReasonCode))
		end) as MainCode,
		(case
			when
				substring(RepairCode, 0, charindex(', ',RepairCode)) = 0 then RepairCode
				else substring(RepairCode, 0, charindex(', ',RepairCode))
		end) as MainRepairCode,
		trim(stuff((select ', ' + convert(varchar(max),PartNumber)
				from 
					(select wcp.WarrantyCaseId, wcp.PartId as PartId, p.Number as PartNumber
						from VSM_WarrantyRegistration.dbo.WarrantyCaseParts wcp
						left join VSM_WarrantyRegistration.dbo.Parts p
							on
								wcp.PartId = p.Id
					) as t3
				where t3.WarrantyCaseId = wCaseID 
				for xml path ('')), 1, 1,'')
			) [PartUsed]
	from
		(select wc.Id as CaseID ,wc.Number as CaseNumber, wc.MachineID as MachineID, wc.DealershipID as DealershipID,
			d.CountryCode as Country, r.Name as Region, ma.SerialNumber as SerialNumber, mo.Name as Model,
			trim(replace(replace(mo.SourceTag, 'xxx', ''), ' ', '')) as ModelSKU, br.Name as ModelBrand, wcp.PartId as PartID, p.Number as PartNumber, wcp.WarrantyCaseId as wCaseID,
			cast(wc.CloseDate as date) as CloseDate,
			trim(stuff((select ', ' + convert(varchar(12),wcr.WarrantyReasonId)
							from VSM_WarrantyRegistration.dbo.WarrantyCaseReasons wcr
							where wcr.WarrantyCaseId = wc.ID
							for xml path ('')), 1, 1,'')
						) [ReasonCode],
			trim(stuff((select ', ' + convert(varchar(12),wcra.RepairActionId)
					from VSM_WarrantyRegistration.dbo.WarrantyCaseRepairActions wcra
					where wcra.WarrantyCaseId = wc.Id
					for xml path ('')), 1, 1,'')
				) [RepairCode]
		from VSM_WarrantyRegistration.dbo.WarrantyCases wc
		left join VSM_WarrantyRegistration.dbo.WarrantyCaseParts wcp
			on
				wcp.WarrantyCaseId = wc.Id
		left join VSM_WarrantyRegistration.dbo.Dealerships d
			on
				d.Id = wc.DealershipId
		left join VSM_WarrantyRegistration.dbo.Regions r
			on
				d.RegionId = r.Id
		left join VSM_WarrantyRegistration.dbo.Machines ma
			on
				ma.Id = wc.MachineID
		left join VSM_WarrantyRegistration.dbo.Models mo
			on
				mo.Id = ma.ModelId
		left join VSM_WarrantyRegistration.dbo.Brands br
			on
				br.Id = mo.BrandId
		left join VSM_WarrantyRegistration.dbo.Parts p
			on
				wcp.PartId = p.Id
		) as t1
	) as t2
left join VSM_WarrantyRegistration.dbo.WarrantyReasons wr
	on 
		MainCode = wr.Id
left join VSM_WarrantyRegistration.dbo.RepairACtions ra
	on
		MainRepairCode = ra.Id
where
	year(CloseDate) = 2025
order by
	CloseDate, CaseNumber asc
;
