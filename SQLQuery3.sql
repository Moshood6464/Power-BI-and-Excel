/****** Script for SelectTopNRows command from SSMS    ******/
SELECT TOP (1000)  [EmployeeID]
      ,[FirstName]
      ,[LastName]
      ,[Age]
      ,[Gender]
  FROM [SQL TUTORIAL].[dbo].[EmployeeDemographics]
