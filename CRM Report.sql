USE [BioAPI]
GO
/****** Object:  StoredProcedure [dbo].[CRMReport2]    Script Date: 3/5/2019 9:26:06 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: <Stuart Broach>
-- Create date: <1/25/2019>
-- Description:	<CRM Report 2.0>
-- =============================================
ALTER PROCEDURE [dbo].[CRMReport2]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
BEGIN
		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'ItApps365', 
			@recipients = 'ssb@biocomposites.com; arm@biocomposites.com; rgs@biocomposites.com; tjk@biocomposites.com; rds@biocomposites.com; cw@biocomposites.com; tan@biocomposites.com; cam@biocomposites.com; ydl@biocomposites.com; cah@biocomposites.com; elp@biocomposites.com; cbm@biocomposites.com', 
			@subject = 'Epicor Outstanding Account Tracker', 
			@body = 'The attached file is a report of outstanding accounts.',
			@importance ='HIGH',
			@query = '
SELECT DISTINCT s.Description as Region, 
       V.NAme as Distributor, 
	   c.custID as CustomerID,  
	   c.Name as Customer,  
	   h.OrderNum, 
	   h.PONum, 
       Concat(MONTH(h.OrderDate), "/",DAY(h.OrderDate),"/",YEAR(h.OrderDate)) AS OrderDate,
       CASE WHEN u.ProcDate_c IS NULL THEN NULL ELSE Concat(MONTH(u.ProcDate_c), "/",DAY(u.ProcDate_c),"/",YEAR(u.ProcDate_c)) END AS "Procedure Date",
       cc.Name as Surgeon,
       CASE WHEN ISNUMERIC(u.salesrep_C) = 1 THEN p.name ELSE u.salesrep_c end as "Sales Rep",

       CASE WHEN u.ProcDate_c IS NULL THEN CONVERT(decimal(12,0),GETDATE()) - CONVERT(decimal(12,0),CONVERT(datetime,h.OrderDate)) 
       ELSE CONVERT(decimal(12,0),GETDATE()) - CONVERT(decimal(12,0),CONVERT(datetime,u.ProcDate_c)) END AS OrderAge                     
	   into #temporarytablecrmtest1 
	     FROM epicorerp.erp.OrderHed h 
                     LEFT JOIN epicorerp.erp.OrderHed_UD u ON h.SysRowID = u.ForeignSysRowID
                     LEFT JOIN epicorerp.erp.OrderDtl d ON h.Company = d.Company AND h.OrderNum = d.OrderNum 
                     LEFT JOIN epicorerp.erp.Vendor v on u.distributor_c = v.VendorID
                     LEFT JOIN epicorerp.erp.VendorPP p on v.VendorNum = p.VendorNum and p.PurPoint = u.Salesrep_c
                     LEFT JOIN epicorerp.erp.Customer c ON h.Company = c.Company AND h.CustNum = c.CustNum 
                     LEFT JOIN epicorerp.erp.CustCnt cc on c.CustNum = cc.CustNum and u.Surgeon_c = cc.PerConID
                     LEFT JOIN epicorerp.erp.CRMCall l ON h.Company = l.Company AND h.OrderNum = l.CallOrderNum 
                     LEFT JOIN epicorerp.erp.SalesCat s on d.SalesCatID = s.SalesCatID
                     WHERE h.Company = "BIO02" and
					 CASE WHEN u.ProcDate_c IS NULL THEN CONVERT(decimal(12,0),GETDATE()) - CONVERT(decimal(12,0),CONVERT(datetime,h.OrderDate)) 
                     ELSE CONVERT(decimal(12,0),GETDATE()) - CONVERT(decimal(12,0),CONVERT(datetime,u.ProcDate_c)) END > 30
					 AND (CONVERT(decimal(12,0),GETDATE()) - CONVERT(decimal(12,0),CONVERT(datetime,l.LastDate)) > 0 OR l.LastDate IS NULL) AND PONum LIKE "NO PO%" AND POnum NOT LIKE "%NO CHARGE%"

		order by OrderNum


SELECT 
	   h.OrderNum,
	   (CASE WHEN Count(d.OrderLine) != 0 THEN  SUM(h.Orderamt) / COUNT(d.OrderLine) 
	   ELSE SUM(h.Orderamt) END) as [Order_Total], 
       MAX(d.OrderLine) as [Order_Lines],               
	   MIN(CONVERT(decimal(12,0),GETDATE()) - CONVERT(decimal(12,0),CONVERT(datetime,l.LastDate))) AS DaysSinceLastEntry,
	   CAST(DATEADD(DAY, CAST(MAX(DATEDIFF(DAY, GETDATE(), l.LastDate)) as int), GETDATE()) AS DATE)  AS  [CRMEntry],
	   CASE WHEN MAX(d.OrderLine) > 1 THEN SUM(d.OrderQty) / COUNT(d.Orderline) * COUNT(DISTINCT d.OrderLine)
	    	ELSE SUM(d.OrderQty) / COUNT(d.Orderline) END as [Quantity_Ordered],
	   COUNT(DISTINCT d.XPartNum) as Parts_Ordered
	   into #temporarytablecrmtest2                       
                     FROM epicorerp.erp.OrderHed h 
                     LEFT JOIN epicorerp.erp.OrderHed_UD u ON h.SysRowID = u.ForeignSysRowID
                     LEFT JOIN epicorerp.erp.OrderDtl d ON h.Company = d.Company AND h.OrderNum = d.OrderNum 
                     LEFT JOIN epicorerp.erp.Vendor v on u.distributor_c = v.VendorID
                     LEFT JOIN epicorerp.erp.VendorPP p on v.VendorNum = p.VendorNum and p.PurPoint = u.Salesrep_c
                     LEFT JOIN epicorerp.erp.Customer c ON h.Company = c.Company AND h.CustNum = c.CustNum 
                     LEFT JOIN epicorerp.erp.CustCnt cc on c.CustNum = cc.CustNum and u.Surgeon_c = cc.PerConID
                     LEFT JOIN epicorerp.erp.CRMCall l ON h.Company = l.Company AND h.OrderNum = l.CallOrderNum 
                     LEFT JOIN epicorerp.erp.SalesCat s on d.SalesCatID = s.SalesCatID
                     WHERE h.Company = "BIO02"and 
                                  CASE WHEN u.ProcDate_c IS NULL THEN CONVERT(decimal(12,0),GETDATE()) - CONVERT(decimal(12,0),CONVERT(datetime,h.OrderDate)) 
                                  ELSE CONVERT(decimal(12,0),GETDATE()) - CONVERT(decimal(12,0),CONVERT(datetime,u.ProcDate_c)) END > 30
                                  AND (CONVERT(decimal(12,0),GETDATE()) - CONVERT(decimal(12,0),CONVERT(datetime,l.LastDate)) > 0 OR l.LastDate IS NULL) AND PONum LIKE "NO PO%" AND POnum NOT LIKE "%NO CHARGE%"
                      group by h.OrderNum            
                     

select *
from #temporarytablecrmtest1
join #temporarytablecrmtest2 on #temporarytablecrmtest1.OrderNum = #temporarytablecrmtest2.OrderNum
order by #temporarytablecrmtest1.Region


drop table #temporarytablecrmtest1
drop table #temporarytablecrmtest2


			'
			,
			@attach_query_result_as_file = 1,
			@body_format = 'HTML',
			@query_attachment_filename = 'CRMReport.csv',
			@query_result_separator='	',
			@query_result_no_padding = 1
	END 

END
