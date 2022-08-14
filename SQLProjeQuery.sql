
--Müşterilerin açık adreslerinin sorgusu
create view CustomerOpenAdress
as
select C.CustomerID,C.Name,r.Continent,r.Country,R.City,a.Address
from ordersc.Customer C inner join warehouse.Region R
on C.RegionID=R.RegionID inner join warehouse.Address A
on R.RegionID=A.RegionID
select *
from CustomerOpenAdress

--Depolarımızın adresini veren joinleme işlemi 
create view WareHouseOpenAdress
as
select w.WarehouseName,R.Continent,R.Country,R.City,WT.WarehouseCapacity,A.Address,w.NumberOfEmployees
from warehouse.warehouse W inner join warehouse.Region R
on W.RegionID=R.RegionID inner join warehouse.Address A
on R.RegionID=A.RegionID inner join warehouse.WarehouseType WT
on W.WarehouseTypeID=WT.WarehouseTypeID 

select * from WareHouseOpenAdress

--Maaşın olmadığı 
create view EmployeewoSalary
as
select EmployeeID,FirstName,LastName,Birthdate,MaritalStatus,Gender,WarehouseID,PositionID
from employee.Employee

-- Order tablosuyla ilgili detaylı bilgileri getirmek için join işlemi. (VIEW)
create view order_tüm_bilgiler
as
select o.OrderID,o.OrderDate,c.Name as CustomerName,p.Name as ProductName,p.Cost,r.Continent,r.Country,r.City,ca.Name as CargoName,ca.TransportType,w.WarehouseName
from ordersc.[Order] o inner join ordersc.Customer c
on o.CustomerID = c.CustomerID
inner join product.Product p
on o.ProductID = p.ProductID
inner join warehouse.Region r
on o.RegionID = r.RegionID
inner join product.Cargo ca
on o.CargoID = ca.CargoID
inner join warehouse.Warehouse w
on o.WarehouseID = w.WarehouseID


select * from order_tüm_bilgiler

-- Work Accident tablosunda Employee ID gizleyen VIEW
create view vwKazaGizle
as
select AccidentID,Date,AccidentTypeID from accident.WorkAccident

select * from vwKazaGizle

-- Employee.Contact tablosunda çalışanların adreslerini gizleyen bir VIEW.

create view vwAdresGizle
as
select EmployeeID,Phone,Mail,FamilierPhone from employee.Contact

select * from vwAdresGizle

------------------------------------------------------SP--------------------------------------------------------------
select * from employee.Employee
--Maaşa yüzdelik zam yapmak
create procedure spSalaryUpdates
(
@PersonID int,
@Percentage decimal(18,2)
)
as 
begin
	select *
	from employee.Employee
	where EmployeeID=@PersonID

	update employee.Employee
	set Salary=Salary+(Salary*@Percentage/100)
	where EmployeeID=@PersonID

	select *
	from employee.Employee
	where EmployeeID=@PersonID
end                    

exec spSalaryUpdates 1, 20.00;

--CustomerID verildiğinde sipariş bilgilerini açık bir şekilde getiren procedure
create procedure spOrderAccordingCustomer
(
@PersonID int
)
as 
begin
	select o.OrderID,o.OrderDate,c.Name as CustomerName,p.Name as ProductName,p.Cost,r.Continent,r.Country,r.City,ca.Name as CargoName,ca.TransportType,w.WarehouseName
	from ordersc.[Order] o inner join ordersc.Customer c
	on o.CustomerID = c.CustomerID
	inner join product.Product p
	on o.ProductID = p.ProductID
	inner join warehouse.Region r
	on o.RegionID = r.RegionID
	inner join product.Cargo ca
	on o.CargoID = ca.CargoID
	inner join warehouse.Warehouse w
	on o.WarehouseID = w.WarehouseID
	where o.CustomerID=@PersonID
end 

exec spOrderAccordingCustomer 1;
--Product tablosunda aynı kategorideki urunlerın toplamı 
create procedure spSameCategoryTotal1(@Category int)
as begin 
	select * from product.Product p 
	where CategoryID=@Category
	select sum(Cost) as SumofCategory from product.Product
	where CategoryID=@Category
	group by CategoryID

end
exec spSameCategoryTotal1 4



select *
from product.Product p


-- Customer tablosuna veri ekleme yapan bir sp.

CREATE procedure ekle
@Name nvarchar(100),
@RegionID smallint,
@ProductID smallint
as
INSERT INTO ordersc.Customer (Name,RegionID,ProductID)
values (@Name,@RegionID,@ProductID)

exec ekle 'HOEL','2','3'

select * from ordersc.Customer

-- ProductID verilen ürünün Quantity bilgisini getiren bir sp.

CREATE procedure quantity_getir
@ProductID smallint
as
    select Quantity
    from accident.ExtraCost
    where ProductID = @ProductID


exec quantity_getir 3


-- END Date boş ise 'Active' yazdıran bir procedure.

CREATE procedure aktif_mi
@EmployeeID int
as
    select *, CASE ISNULL(CAST(EndDate as nvarchar),'0')
                when '0' then 'Active'
                else 'Not Active'
                end as 'Active'
                from employee.WorkDate
    where EmployeeID = @EmployeeID


exec aktif_mi 3

---------------------Function-----------------------------------       
--tarih aralıklarını getiren bir fonksiyon 
create function Column_Cagirma1 
(@StartDate datetime,
@EndDate datetime)
returns table
as
return select * from ordersc.[Order] o where o.OrderDate>=@StartDate and o.OrderDate<=@StartDate 

select*
from Column_Cagirma1('2011-05-31 00:00:00.000','2011-05-31 00:00:00.000')

create function dbo.getMaxGirisCikisProduct()
returns int 
as begin 
	declare @ProductID int
	set @ProductID= ( select A.ProductID from
								(select top 1 o.ProductID,COUNT(*) most from ordersc.[Order] as o 
								group by o.ProductID order by most desc)A)
	return @ProductID
end
select dbo.getMaxCiroProduct() as EnÇokGirişÇıkışYapanUrun
----------------------------------------------------------------------------------------
create function   getContactFamilier(@Employee int)
returns nvarchar(50)
as begin 
	return (select FamilierPhone from employee.Contact
	where EmployeeID=@Employee)
end

select dbo.getContactFamilier(3) as YakınNumarası

------------------------------------------------------------Function------------------------------------------------------------------------
-- Müsterilerin toplam kac siparis verdigini gösteren fonksiyon.
create function fn_musteri_toplam_siparis(@CustomerID int)
returns int
as
Begin
Declare @adet int
select @adet = COUNT(*) from ordersc.[Order] where CustomerID = @CustomerID group by CustomerID
return @adet
end


select OrderID,OrderDate,CustomerID,dbo.fn_musteri_toplam_siparis(CustomerID) as MusteriToplamSiparis
from ordersc.[Order]


-- calısanların yaslarını hesaplayan fonksiyon
create function YasHesapla
(
@DogumTarihi date
)
returns int
as
begin
    return(select DATEDIFF(YEAR,@DogumTarihi,GETDATE()))
end


select FirstName,LastName,Birthdate, dbo.YasHesapla(Birthdate) as Age
from employee.Employee
-- ürünlerin hacmini hesaplayan fonksiyon.

create function hacim
(
@yukseklik decimal(10,2),
@genislik decimal(10,2),
@uzunluk decimal(10,2)
)
returns decimal(10,2)
as
begin
 return (@yukseklik * @genislik * @uzunluk)
end


select ProductID,Weight, dbo.hacim(Height, Width, Length) as Volume
from product.Volume
-------------------------TRIGGER---------------------------
create trigger trg_Guncelle on employee.employee
after update
as begin
--if(update(cinsiyet))
if(exists(select * from inserted,deleted where inserted.EmployeeID=deleted.EmployeeID and inserted.Birthdate!=deleted.Birthdate)) 
--Exists içindeki değerin olup olmadığına bakar.
begin
raiserror('Doğum Günü Güncellenemez.',1,1)
rollback transaction --işlemi geri al 
end
end
 
--trigger test edilmesi
select * from employee.Employee where EmployeeID = 3
update employee.Employee set Birthdate = '1970-05-21' where EmployeeID = 3

-------------------------------------------------------------
create trigger trg_CalisanSilinmez
on employee.Employee
instead of delete
as
begin
raiserror('Calisan Tablosu Uzerinde Kayit Silinemez!',1,1)
rollback transaction
end

select * from employee.Employee
delete employee.Employee where EmployeeID = 4
-----------------------------------------------------
--- Product tablosundan silinen ürünleri silinen ürünler (Deletedproduct) tablosuna aktar.
create table Deletedproduct
(
ProductID smallint,
Name varchar(50),
ProductCode nvarchar(10),
CategoryID tinyint,
Cost money,
BrandID tinyint
)

alter schema product transfer dbo.Deletedproduct


create trigger trg_SılınenUrunTablosunaAktar
on product.Product
after delete
as
begin
declare @ID smallint
declare @name_ varchar(50)
declare @Prodcode nvarchar(10)
declare @CatID tinyint
declare @cos money
declare @bID tinyint
select @ID = ProductID from deleted
select @name_ = Name from deleted
select @Prodcode = ProductCode from deleted
select @CatID = CategoryID from deleted
select @cos = Cost from deleted
select @bID = BrandID from deleted
    insert into product.Deletedproduct values(@ID,@name_,@Prodcode,@CatID,@cos,@bID)
end

delete product.Product where ProductID = 5

select * from product.Product
select * from product.Deletedproduct
------------------------------------------------------------------------
-- Sipariş tablosunda güncelleme yapıldığında modifiedDate'i otomatik olarak güncelleyen trigger.
create trigger trg_TarihGuncelle
on ordersc.[Order]
after update
as
begin
update ordersc.[Order] set ModifiedDate = GETDATE() where OrderID = (select OrderID from inserted)
end

update ordersc.[Order] set WarehouseID = 3 where OrderID = 5

select * from ordersc.[Order]

---------------------------------------------------------------------------------------
-- Sipariş tablosuna kayıt eklendikten sonra sipariş tablosunu listeleyen trigger.
create trigger trg_Listele
on ordersc.[Order]
after insert
as
begin
select * from ordersc.[Order]
end

insert into ordersc.[Order] (OrderDate,DueDate,CustomerID,ProductID,RegionID,CargoID,WarehouseID) 
values('2011-06-23 00:00:00.000','2011-06-25 00:00:00.000',3,2,4,2,1)
-----------------------------------------------------------------------------------------
Create trigger AddQuantity1 on accident.ExtraCost
after insert
as
if(exists(Select * from inserted,ExtraCost where inserted.Quantity = ExtraCost.Quantity and
extracost.Quantity<10))
begin
  raiserror('En az 10 adet kayıp olmalıdır',1,1);
  rollback transaction
End

insert into accident.ExtraCost (Date,AccidentTypeID,ProductID,Quantity,Cost) 
values('2011-06-23 00:00:00.000',3,2,4,Null)
select * from accident.ExtraCost
----------------------------------------------------------------------------------------------