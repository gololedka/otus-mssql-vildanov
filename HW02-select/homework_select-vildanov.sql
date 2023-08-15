/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select StockItemID, StockItemName from Warehouse.StockItems
where StockItemName like '%urgent%' or StockItemName like 'Animal%'
order by StockItemID

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select distinct s.SupplierName, s.SupplierID from Purchasing.Suppliers s
left join Purchasing.PurchaseOrders po
on po.SupplierID = s.SupplierID
where po.SupplierID is null
order by SupplierID

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

select o.OrderID, FORMAT(o.OrderDate, 'd', 'de-de') as [OrderDate], 
datename(month, o.OrderDate) as [Месяц],
case 
		when MONTH(OrderDate) < 4  then 1
		when MONTH(OrderDate) between 3 and 7 then 2
		when MONTH(OrderDate) between 6 and 10 then 3
		else 4
end as [Квартал],
case 
		when MONTH(OrderDate) < 5  then 1
		when MONTH(OrderDate) between 4 and 9 then 2
		else 3
end as [Треть],
c.CustomerName from Sales.Orders o
join Sales.OrderLines ol on ol.OrderID = o.OrderID
join Sales.Customers c on o.CustomerID = c.CustomerID
where ol.UnitPrice > 100 or (ol.Quantity > 20 and ol.PickingCompletedWhen is not null)
order by [Квартал], [Треть], [OrderDate]
offset 1000 rows fetch next 100 rows only

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select dm.DeliveryMethodName, po.ExpectedDeliveryDate, s.SupplierName, p.PreferredName from Purchasing.PurchaseOrders po
join Application.DeliveryMethods dm on po.DeliveryMethodID = dm.DeliveryMethodID
join Purchasing.Suppliers s on s.SupplierID = po.SupplierID
join Application.People p on p.PersonID = po.ContactPersonID
where po.ExpectedDeliveryDate between '2013-01-01' and '2013-01-31'
and dm.DeliveryMethodName in ('Air Freight', 'Refrigerated Air Freight')
and po.IsOrderFinalized = 1
order by po.ExpectedDeliveryDate

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

select top (10) o.*, c.CustomerName, p.FullName from Sales.Orders o
join Application.People p on o.SalespersonPersonID = p.PersonID
join Sales.Customers c on c.CustomerID = o.CustomerID
order by o.OrderDate desc

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select distinct c.CustomerID, c.CustomerName, c.PhoneNumber from Warehouse.StockItems si
join Sales.OrderLines ol on si.StockItemID = ol.StockItemID
join Sales.Orders o on o.OrderID = ol.OrderID
join Sales.Customers c on c.CustomerID = o.CustomerID
where si.StockItemName = 'Chocolate frogs 250g'
order by c.CustomerName, c.CustomerID
