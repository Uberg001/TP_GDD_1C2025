--CREACION DE ESQUEMA SILVER_CRIME_RELOADED
USE GD1C2025
GO
IF NOT EXISTS (SELECT * FROM sys.schemas where name = 'SILVER_CRIME_RELOADED')
BEGIN
    EXEC('CREATE SCHEMA SILVER_CRIME_RELOADED')
END
GO
----------------------------------------------------------------------------------------
--DEFINICION DE PROCEDURES PARA ELIMINACION DE TABLAS, FKS, etc.
IF OBJECT_ID('SILVER_CRIME_RELOADED.borrar_fks') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.borrar_fks 
GO 
CREATE PROCEDURE SILVER_CRIME_RELOADED.borrar_fks AS
BEGIN
    DECLARE @query nvarchar(255) 
    DECLARE query_cursor CURSOR FOR 
    SELECT 'ALTER TABLE ' 
        + object_schema_name(k.parent_object_id) 
        + '.[' + Object_name(k.parent_object_id) 
        + '] DROP CONSTRAINT ' + k.NAME query 
    FROM sys.foreign_keys k

    OPEN query_cursor 
    FETCH NEXT FROM query_cursor INTO @query 
    WHILE @@FETCH_STATUS = 0 
    BEGIN 
        EXEC sp_executesql @query 
        FETCH NEXT FROM query_cursor INTO @query 
    END

    CLOSE query_cursor 
    DEALLOCATE query_cursor 
END
GO 

IF OBJECT_ID('SILVER_CRIME_RELOADED.borrar_tablas') IS NOT NULL 
  DROP PROCEDURE SILVER_CRIME_RELOADED.borrar_tablas
GO 
CREATE PROCEDURE SILVER_CRIME_RELOADED.borrar_tablas AS
BEGIN
    DECLARE @query nvarchar(255) 
    DECLARE query_cursor CURSOR FOR  
        SELECT 'DROP TABLE SILVER_CRIME_RELOADED.' + name
        FROM  sys.tables 
        WHERE schema_id = (SELECT schema_id FROM sys.schemas WHERE name = 'SILVER_CRIME_RELOADED')
    
    OPEN query_cursor 
    FETCH NEXT FROM query_cursor INTO @query 
    WHILE @@FETCH_STATUS = 0 
    BEGIN 
        EXEC sp_executesql @query 
        FETCH NEXT FROM query_cursor INTO @query 
    END 

    CLOSE query_cursor 
    DEALLOCATE query_cursor
END
GO 

IF OBJECT_ID('SILVER_CRIME_RELOADED.borrar_procedures') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.borrar_procedures
GO 
CREATE PROCEDURE SILVER_CRIME_RELOADED.borrar_procedures AS
BEGIN
    DECLARE @query nvarchar(255) 
    DECLARE query_cursor CURSOR FOR  
        SELECT 'DROP PROCEDURE SILVER_CRIME_RELOADED.' + name
        FROM  sys.procedures 
        WHERE schema_id = (SELECT schema_id FROM sys.schemas WHERE name = 'SILVER_CRIME_RELOADED') AND name LIKE 'migrar_%'
    
    OPEN query_cursor 
    FETCH NEXT FROM query_cursor INTO @query 
    WHILE @@FETCH_STATUS = 0 
    BEGIN 
        EXEC sp_executesql @query 
        FETCH NEXT FROM query_cursor INTO @query 
    END 

    CLOSE query_cursor 
    DEALLOCATE query_cursor 
END
GO 

-- ELIMINACION DE TABLAS, FKS Y PROCEDURES
EXEC SILVER_CRIME_RELOADED.borrar_fks;
EXEC SILVER_CRIME_RELOADED.borrar_tablas;
EXEC SILVER_CRIME_RELOADED.borrar_procedures;
GO

-------------------------------------------------------------------------
-- CREACION DE TABLAS
-- Tabla Dimensión: Provincia
CREATE TABLE SILVER_CRIME_RELOADED.Provincia (
    provincia_id INT,
    provincia_nombre NVARCHAR(55)
);

-- Tabla Dimensión: Localidad
CREATE TABLE SILVER_CRIME_RELOADED.Localidad (
    localidad_id INT,
    localidad_nombre NVARCHAR(55)
);

-- Tabla Dimensión: Sucursal
CREATE TABLE SILVER_CRIME_RELOADED.Sucursal (
    sucursal_id INT,
    sucursal_provincia_id INT,
    sucursal_localidad_id INT
);

-- Tabla Dimensión: Tiempo
CREATE TABLE SILVER_CRIME_RELOADED.Tiempo (
    tiempo_id INT,
    tiempo_anio INT,
    tiempo_cuatrimestre INT,
    tiempo_mes INT
);

-- Tabla Dimensión: Modelo
CREATE TABLE SILVER_CRIME_RELOADED.Modelo (
    modelo_id INT,
    modelo_nombre NVARCHAR(55)
);

-- Tabla Dimensión: Rango_Etario
CREATE TABLE SILVER_CRIME_RELOADED.Rango_Etario (
    rango_etario_id INT,
    rango_etario_nombre NVARCHAR(50)
);

-- Tabla de Hechos: Hecho_factura
CREATE TABLE SILVER_CRIME_RELOADED.Hecho_factura (
    hecho_factura_tiempo_id INT,
    hecho_factura_sucursal_id INT,
    hecho_factura_modelo_id INT,
    hecho_factura_rango_etario_id INT,
    hecho_factura_provincia_id INT,
    hecho_factura_compra DECIMAL(18,2),
    hecho_factura_venta DECIMAL(18,2),
    hecho_factura_total DECIMAL(18,2)
);

-- Tabla Dimensión: Tipo_material
CREATE TABLE SILVER_CRIME_RELOADED.Tipo_material (
    tipo_material_id INT,
    tipo_material_nombre NVARCHAR(65)
);

-- Tabla de Hechos: Hecho_compra
CREATE TABLE SILVER_CRIME_RELOADED.Hecho_compra (
    hecho_compra_tiempo_id INT,
    hecho_compra_sucursal_id INT,
    hecho_compra_tipo_material_id INT,
    hecho_compra_importe_total DECIMAL(18,2)
);

-- Tabla Dimensión: Cliente
CREATE TABLE SILVER_CRIME_RELOADED.Cliente (
    cliente_id INT,
    cliente_nombre NVARCHAR(55) 
);

-- Tabla de Hechos: Hecho_envio
CREATE TABLE SILVER_CRIME_RELOADED.Hecho_envio (
    hecho_envio_tiempo_id INT,
    hecho_envio_localidad_id INT,
    hecho_envio_cliente_id INT
);

-- Tabla Dimensión: Turno
CREATE TABLE SILVER_CRIME_RELOADED.Turno (
    turno_id INT,
    turno_nombre NVARCHAR(55)
);

-- Tabla Dimensión: Estado
CREATE TABLE SILVER_CRIME_RELOADED.Estado (
    estado_id INT,
    estado_nombre NVARCHAR(55)
);

-- Tabla de Hechos: Hecho_pedido
CREATE TABLE SILVER_CRIME_RELOADED.Hecho_pedido (
    hecho_pedido_tiempo_id INT,
    hecho_pedido_turno_id INT,
    hecho_pedido_estado_id INT,
    hecho_pedido_sucursal_id INT
);

------------------------------------------------------------------------
-- Definicion de constraints
-- PRIMARY KEYS
ALTER TABLE SILVER_CRIME_RELOADED.Provincia ADD CONSTRAINT PK_Provincia PRIMARY KEY (provincia_id);
ALTER TABLE SILVER_CRIME_RELOADED.Localidad ADD CONSTRAINT PK_Localidad PRIMARY KEY (localidad_id);
ALTER TABLE SILVER_CRIME_RELOADED.Sucursal ADD CONSTRAINT PK_Sucursal PRIMARY KEY (sucursal_id);
ALTER TABLE SILVER_CRIME_RELOADED.Tiempo ADD CONSTRAINT PK_Tiempo PRIMARY KEY (tiempo_id);
ALTER TABLE SILVER_CRIME_RELOADED.Modelo ADD CONSTRAINT PK_Modelo PRIMARY KEY (modelo_id);
ALTER TABLE SILVER_CRIME_RELOADED.Tipo_material ADD CONSTRAINT PK_Tipo_material PRIMARY KEY (tipo_material_id);
ALTER TABLE SILVER_CRIME_RELOADED.Rango_Etario ADD CONSTRAINT PK_Rango_Etario PRIMARY KEY (rango_etario_id);
ALTER TABLE SILVER_CRIME_RELOADED.Cliente ADD CONSTRAINT PK_Cliente PRIMARY KEY (cliente_id);
ALTER TABLE SILVER_CRIME_RELOADED.Turno ADD CONSTRAINT PK_Turno PRIMARY KEY (turno_id);
ALTER TABLE SILVER_CRIME_RELOADED.Estado ADD CONSTRAINT PK_Estado PRIMARY KEY (estado_id);

-- FOREIGN KEYS
-- Sucursal
ALTER TABLE SILVER_CRIME_RELOADED.Sucursal ADD 
    CONSTRAINT FK_Sucursal_Provincia FOREIGN KEY (sucursal_provincia_id) REFERENCES SILVER_CRIME_RELOADED.Provincia(provincia_id),
    CONSTRAINT FK_Sucursal_Localidad FOREIGN KEY (sucursal_localidad_id) REFERENCES SILVER_CRIME_RELOADED.Localidad(localidad_id);

-- Hecho_compra
ALTER TABLE SILVER_CRIME_RELOADED.Hecho_compra ADD 
    CONSTRAINT FK_Compra_Tiempo FOREIGN KEY (hecho_compra_tiempo_id) REFERENCES SILVER_CRIME_RELOADED.Tiempo(tiempo_id),
    CONSTRAINT FK_Compra_Sucursal FOREIGN KEY (hecho_compra_sucursal_id) REFERENCES SILVER_CRIME_RELOADED.Sucursal(sucursal_id),
    CONSTRAINT FK_Compra_TipoMat FOREIGN KEY (hecho_compra_tipo_material_id) REFERENCES SILVER_CRIME_RELOADED.Tipo_material(tipo_material_id),
    CONSTRAINT PK_Compra PRIMARY KEY (hecho_compra_tiempo_id, hecho_compra_sucursal_id, hecho_compra_tipo_material_id);
-- Hecho_envio
ALTER TABLE SILVER_CRIME_RELOADED.Hecho_envio ADD 
    CONSTRAINT FK_Envio_Tiempo FOREIGN KEY (hecho_envio_tiempo_id) REFERENCES SILVER_CRIME_RELOADED.Tiempo(tiempo_id),
    CONSTRAINT FK_Envio_Localidad FOREIGN KEY (hecho_envio_localidad_id) REFERENCES SILVER_CRIME_RELOADED.Localidad(localidad_id),
    CONSTRAINT FK_Envio_Cliente FOREIGN KEY (hecho_envio_cliente_id) REFERENCES SILVER_CRIME_RELOADED.Cliente(cliente_id),
    CONSTRAINT PK_Envio PRIMARY KEY (hecho_envio_tiempo_id, hecho_envio_localidad_id, hecho_envio_cliente_id);

-- Hecho_pedido
ALTER TABLE SILVER_CRIME_RELOADED.Hecho_pedido ADD 
    CONSTRAINT FK_Pedido_Tiempo FOREIGN KEY (hecho_pedido_tiempo_id) REFERENCES SILVER_CRIME_RELOADED.Tiempo(tiempo_id),
    CONSTRAINT FK_Pedido_Turno FOREIGN KEY (hecho_pedido_turno_id) REFERENCES SILVER_CRIME_RELOADED.Turno(turno_id),
    CONSTRAINT FK_Pedido_Estado FOREIGN KEY (hecho_pedido_estado_id) REFERENCES SILVER_CRIME_RELOADED.Estado(estado_id),
    CONSTRAINT FK_Pedido_Sucursal FOREIGN KEY (hecho_pedido_sucursal_id) REFERENCES SILVER_CRIME_RELOADED.Sucursal(sucursal_id),
    CONSTRAINT PK_Pedido PRIMARY KEY (hecho_pedido_tiempo_id, hecho_pedido_turno_id, hecho_pedido_estado_id, hecho_pedido_sucursal_id);

-- Hecho_factura
ALTER TABLE SILVER_CRIME_RELOADED.Hecho_factura ADD 
    CONSTRAINT FK_Factura_Tiempo FOREIGN KEY (hecho_factura_tiempo_id) REFERENCES SILVER_CRIME_RELOADED.Tiempo(tiempo_id),
    CONSTRAINT FK_Factura_Sucursal FOREIGN KEY (hecho_factura_sucursal_id) REFERENCES SILVER_CRIME_RELOADED.Sucursal(sucursal_id),
    CONSTRAINT FK_Factura_Modelo FOREIGN KEY (hecho_factura_modelo_id) REFERENCES SILVER_CRIME_RELOADED.Modelo(modelo_id),
    CONSTRAINT FK_Factura_RangoEtario FOREIGN KEY (hecho_factura_rango_etario_id) REFERENCES SILVER_CRIME_RELOADED.Rango_Etario(rango_etario_id),
    CONSTRAINT FK_Factura_Provincia FOREIGN KEY (hecho_factura_provincia_id) REFERENCES SILVER_CRIME_RELOADED.Provincia(provincia_id),
    CONSTRAINT PK_Factura PRIMARY KEY (hecho_factura_tiempo_id, hecho_factura_sucursal_id, hecho_factura_modelo_id, hecho_factura_rango_etario_id, hecho_factura_provincia_id);
