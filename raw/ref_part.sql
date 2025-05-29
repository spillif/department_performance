select distinct PartNumber,
	trim(case
		when Description is null then D1
		else Description
	end) as Description,
	Brand
from
	(select distinct PartNumber, Description, p.Name as D1,
		case 
		when BrandCode = 1 then 'MYSEWNET'
		when BrandCode = 2 then 'SINGER'
		when BrandCode = 3 then 'NON-ITEM'
		when BrandCode = 4 then 'WHITE'
		when BrandCode = 5 then 'OTHER'
		when BrandCode = 6 then 'PFAFF'
		when BrandCode = 7 then 'PF/HV'
		when BrandCode = 8 then 'INSPIRA'
		when BrandCode = 9 then 'SVP'
		when BrandCode = 10 then 'HV'
		when BrandCode = 11 then 'DITTO'
		else 'Not Available'
	end as Brand
	from
		(select PartNumber, j1.IMDSC1 AS Description, j1.BRAND as BrandCode
		from
			(select
				distinct rtrim(j.IMLITM) as PartNumber
			from
				VSM_WarrantyRegistration.dbo.JDEITEMS j
			union
			select
				distinct rtrim(p.Number) as PartNumber
			from
				VSM_WarrantyRegistration.dbo.Parts p
			) as t1
		left join VSM_WarrantyRegistration.dbo.JDEITEMS j1
			on PartNumber = j1.IMLITM
		) as t2
	left join VSM_WarrantyRegistration.dbo.Parts p
		on PartNumber = p.Number
	) as t3
