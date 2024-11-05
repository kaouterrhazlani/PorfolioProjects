/*
Projet : LogementNashville 
Cleaning Data in SQL Queries
Nettoyage des Données dans les Requêtes SQL

*/
	
	use Sql_Project 
	exec sp_rename 'Sheet1$','NashvilleHousing'

	select * from Sql_Project.dbo.NashvilleHousing
--------------------------------------------------------------------------------------------------------------------------
-- Standardize Date Format
-- Standardiser le Format de Date
-- This section adjusts the date format in the dataset if necessary to make it consistent.
-- Cette section ajuste le format de la date dans le jeu de données si nécessaire pour le rendre cohérent.
--------------------------------------------------------------------------------------------------------------------------

	select SaleDate, convert(date,SaleDate )
	from Sql_Project.dbo.NashvilleHousing
	-- cette requete ne change rien dans la colonne SaleDate
	update Sql_Project.dbo.NashvilleHousing
	set SaleDate = convert(date,SaleDate ) 
	-- Donc j'ai changer le type du colonne directement 
	alter table Sql_Project.dbo.NashvilleHousing
	alter column SaleDate Date;
	select SaleDate from Sql_Project..NashvilleHousing
 

--------------------------------------------------------------------------------------------------------------------------
-- Populate Property Address data
-- Compléter les Données d'Adresse de la Propriété
-- Ensures that all properties have a complete and consistent address.
-- Assure que toutes les propriétés ont une adresse complète et cohérente.(pas de valeur null)
--------------------------------------------------------------------------------------------------------------------------
select a.ParcelID,a.PropertyAddress, b.ParcelID,b.PropertyAddress , 
isnull(a.PropertyAddress , b.PropertyAddress )
from Sql_Project.dbo.NashvilleHousing a
inner join Sql_Project.dbo.NashvilleHousing b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null
	
update a
set a.PropertyAddress = isnull(a.PropertyAddress , b.PropertyAddress )
from Sql_Project.dbo.NashvilleHousing a
inner join Sql_Project.dbo.NashvilleHousing b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null
	
select * from Sql_Project.dbo.NashvilleHousing
where PropertyAddress is null
--------------------------------------------------------------------------------------------------------------------------
-- Breaking out Address into Individual Columns (Address, City, State)
-- Diviser l'Adresse en Colonnes Individuelles (Adresse, Ville, État)
-- Allows the full address to be split into separate fields for more detailed analysis.
-- Permet de séparer l'adresse complète en plusieurs champs pour une analyse plus détaillée.
--------------------------------------------------------------------------------------------------------------------------
	/* Traitement de l'adresse : PropertyAddress*/
select PropertyAddress , SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1),
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress ))
from Sql_Project.dbo.NashvilleHousing

alter table Sql_Project.dbo.NashvilleHousing
add PropertySplitAddress nvarchar(255)

update Sql_Project.dbo.NashvilleHousing
set PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

alter table Sql_Project.dbo.NashvilleHousing
add PropertySplitCity nvarchar(255)

update Sql_Project.dbo.NashvilleHousing
set PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress ))

select PropertyAddress,PropertySplitAddress,PropertySplitCity from Sql_Project.dbo.NashvilleHousing
	
	/* Traitement de l'adresse : OwnerAddress*/
select OwnerAddress , PARSENAME(REPLACE(OwnerAddress,',','.'),3) ,
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1) 
from Sql_Project.dbo.NashvilleHousing

Alter table Sql_Project.dbo.NashvilleHousing
add OwnerSplitAddress nvarchar(255)
Alter table Sql_Project.dbo.NashvilleHousing
add OwnerSplitCity nvarchar(255)
Alter table Sql_Project.dbo.NashvilleHousing
add OwnerSplitState nvarchar(255)

update Sql_Project.dbo.NashvilleHousing
set OwnerSplitAddress=PARSENAME(REPLACE(OwnerAddress,',','.'),3),
	OwnerSplitCity=PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	OwnerSplitState=PARSENAME(REPLACE(OwnerAddress,',','.'),1)

select OwnerSplitAddress,OwnerSplitCity,OwnerSplitState
from Sql_Project.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" field
-- Changer Y et N en Oui et Non dans le champ "Vendu comme Terrain Vacant"
-- Transforms "Y" and "N" into "Yes" and "No" for better readability.
-- Transforme "Y" et "N" en "Oui" et "Non" pour une meilleure lisibilité.
--------------------------------------------------------------------------------------------------------------------------
select distinct SoldAsVacant, count (SoldAsVacant)  SoldAsVacant from Sql_Project.dbo.NashvilleHousing
group by  SoldAsVacant

select SoldAsVacant ,
case 
	when SoldAsVacant = 'N' then 'No'
	when SoldAsVacant = 'Y' then 'Yes'
	else SoldAsVacant
end
from Sql_Project.dbo.NashvilleHousing

update Sql_Project.dbo.NashvilleHousing
set SoldAsVacant = case 
	when SoldAsVacant = 'N' then 'No'
	when SoldAsVacant = 'Y' then 'Yes'
	else SoldAsVacant
end
from Sql_Project.dbo.NashvilleHousing

select distinct SoldAsVacant from Sql_Project.dbo.NashvilleHousing


--------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates
-- Supprimer les Duplicatas
-- Removes duplicate records to prevent redundancy in the analysis.
-- Supprime les enregistrements dupliqués pour éviter les doublons dans l'analyse.
--------------------------------------------------------------------------------------------------------------------------
with CTE_Duplicate as(
select * ,ROW_NUMBER()
 OVER(partition by ParcelID,
				   PropertyAddress,
				   SaleDate,
				   SalePrice,
				   LegalReference,
				   OwnerName,
				   OwnerAddress 
	  order by UniqueID ) row_num
from Sql_Project.dbo.NashvilleHousing)
--select row_num,* 
delete
from CTE_Duplicate
where row_num > 1
--order by 1 desc 
---------------------------------------------------------------------------------------------------------
-- Delete Unused Columns
-- Supprimer les Colonnes Inutilisées
-- Removes columns that are not relevant to this project.
-- Enlève les colonnes non pertinentes pour ce projet.
---------------------------------------------------------------------------------------------------------
select * from Sql_Project.dbo.NashvilleHousing

 alter table  Sql_Project.dbo.NashvilleHousing
 drop column OwnerAddress,PropertyAddress,TaxDistrict

-----------------------------------------------------------------------------------------------
-- Importing Data using OPENROWSET and BULK INSERT
-- Importer des Données avec OPENROWSET et BULK INSERT
-- More advanced and visually appealing, but requires appropriate server configuration to work correctly.
-- Utilisation de BULK INSERT et OPENROWSET pour un import avancé. Nécessite des configurations avancées du serveur pour fonctionner correctement.
-----------------------------------------------------------------------------------------------

-- To enable OPENROWSET, run these commands:
-- Pour activer OPENROWSET, exécutez ces commandes :


-- Example for BULK INSERT
-- Exemple pour BULK INSERT


-- Example for OPENROWSET
-- Exemple pour OPENROWSET

