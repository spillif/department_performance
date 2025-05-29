select SerialNumber, Model_SKU, Model_Description, Brand,
		case
			when left(Model_SKU, 3) = '850' or left(Model_SKU, 3) = '957' or left(Model_SKU, 3) = '230' then left(Model_SKU, 6)
			when len(Model_SKU) = 4 then left(Model_SKU,4)
			when left(Model_SKU,3) = 'S14' and right(Model_SKU,1) <> '-' then substring(Model_SKU,4,6)
			when left(Model_SKU,1) = 'S' then substring(Model_SKU,2,4)
			when len(Model_SKU) = 5 and isnumeric(left(Model_SKU,5)) = 1 then right(Model_SKU,4)
			when isnumeric(left(Model_SKU,4)) = 1 then left(Model_SKU,4)
			when len(Model_SKU) = 4 and isnumeric(left(Model_SKU,4)) = 1 then left(Model_SKU,4)
			when left(Model_SKU,3) = '14T' then substring(Model_SKU,3,6)
			when left(Model_SKU, 2) = '14' then substring(Model_SKU,3,5)
			else Model_SKU
		end as SKU
from
	(select m.SerialNumber as SerialNumber , m2.SourceTag as Model_SKU, m2.Name as Model_Description, replace(replace(replace(replace(b.Name, 'Husqvarna Viking', 'HV'), 'Pfaff', 'PF'), 'Singer', 'SINGER'), 'White', 'WHITE') as Brand
	from VSM_WarrantyRegistration.dbo.Machines m
	join VSM_WarrantyRegistration.dbo.Models m2 
	on m.ModelId = m2.Id
	join VSM_WarrantyRegistration.dbo.Brands b
	on m.BrandId = b.Id
	) as t
where SerialNumber = '76331105'
;

select *
from
	(select trim(replace(replace(m.SourceTag, 'xxx', ''), ' ', '')) as SKU, m.Name, b.Name as Brand
	from VSM_WarrantyRegistration.dbo.Models m
	join VSM_WarrantyRegistration.dbo.Brands b
		on m.BrandId = b.Id
	) as t
;
