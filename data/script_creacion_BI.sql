--CREACION DE ESQUEMA SILVER_CRIME_RELOADED
USE GD1C2025
GO
IF NOT EXISTS (SELECT *
FROM sys.schemas
where name = 'SILVER_CRIME_RELOADED')
BEGIN
    EXEC('CREATE SCHEMA SILVER_CRIME_RELOADED')
END
GO
----------------------------------------------------------------------------------------
--DEFINICION DE PROCEDURES PARA ELIMINACION DE TABLAS, FKS, etc.
/*IF OBJECT_ID('SILVER_CRIME_RELOADED.borrar_fks') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.borrar_fks 
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.borrar_fks
AS
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
CREATE PROCEDURE SILVER_CRIME_RELOADED.borrar_tablas
AS
BEGIN
    DECLARE @query nvarchar(255)
    DECLARE query_cursor CURSOR FOR  
        SELECT 'DROP TABLE SILVER_CRIME_RELOADED.' + name
    FROM sys.tables
    WHERE schema_id = (SELECT schema_id
    FROM sys.schemas
    WHERE name = 'SILVER_CRIME_RELOADED')

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
CREATE PROCEDURE SILVER_CRIME_RELOADED.borrar_procedures
AS
BEGIN
    DECLARE @query nvarchar(255)
    DECLARE query_cursor CURSOR FOR  
        SELECT 'DROP PROCEDURE SILVER_CRIME_RELOADED.' + name
    FROM sys.procedures
    WHERE schema_id = (SELECT schema_id
        FROM sys.schemas
        WHERE name = 'SILVER_CRIME_RELOADED') AND name LIKE 'BI_migrar_%'

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
*/
-------------------------------------------------------------------------
-- CREACION DE TABLAS
-- Tabla Dimensión: Provincia
CREATE TABLE SILVER_CRIME_RELOADED.BI_Provincia
(
    provincia_id INT IDENTITY(1,1),
    provincia_nombre NVARCHAR(55)
);

-- Tabla Dimensión: Localidad
CREATE TABLE SILVER_CRIME_RELOADED.BI_Localidad
(
    localidad_id INT IDENTITY(1,1),
    localidad_nombre NVARCHAR(55)
);

-- Tabla Dimensión: Sucursal
CREATE TABLE SILVER_CRIME_RELOADED.BI_Sucursal
(
    sucursal_id INT IDENTITY(1,1),
    sucursal_provincia_id INT,
    sucursal_localidad_id INT
);

-- Tabla Dimensión: Tiempo
CREATE TABLE SILVER_CRIME_RELOADED.BI_Tiempo
(
    tiempo_id INT IDENTITY(1,1),
    tiempo_anio INT,
    tiempo_cuatrimestre INT,
    tiempo_mes INT,
    CONSTRAINT CHK_TiempoCuatrimestre CHECK (tiempo_cuatrimestre between 1 AND 4),
    CONSTRAINT CHK_TiempoMes CHECK (tiempo_mes between 1 AND 12)
);

-- Tabla Dimensión: Modelo
CREATE TABLE SILVER_CRIME_RELOADED.BI_Modelo
(
    modelo_id INT IDENTITY(1,1),
    modelo_nombre NVARCHAR(55)
);

-- Tabla Dimensión: Rango_Etario
CREATE TABLE SILVER_CRIME_RELOADED.BI_Rango_Etario
(
    rango_etario_id INT IDENTITY(1,1),
    rango_etario_nombre NVARCHAR(50) NOT NULL,
    CONSTRAINT CHK_RangoEtarioNombre CHECK (rango_etario_nombre IN ('JUVENTUD', 'ADULTEZ_TEMPRANA', 'ADULTEZ_MEDIA', 'ADULTEZ_AVANZADA'))
);

-- Tabla de Hechos: Hecho_factura
CREATE TABLE SILVER_CRIME_RELOADED.BI_Hecho_factura
(
    hecho_factura_tiempo_id INT NOT NULL,
    hecho_factura_sucursal_id INT NOT NULL,
    hecho_factura_modelo_id INT NOT NULL,
    hecho_factura_rango_etario_id INT NOT NULL,
    hecho_factura_provincia_id INT NOT NULL,
    hecho_factura_localidad_id INT NOT NULL,
    hecho_factura_total DECIMAL(18,2)
);

-- Tabla Dimensión: Tipo_material
CREATE TABLE SILVER_CRIME_RELOADED.BI_Tipo_material
(
    tipo_material_id INT IDENTITY(1,1),
    tipo_material_nombre NVARCHAR(65)
);

-- Tabla de Hechos: Hecho_compra
CREATE TABLE SILVER_CRIME_RELOADED.BI_Hecho_compra
(
    hecho_compra_tiempo_id INT NOT NULL,
    hecho_compra_sucursal_id INT NOT NULL,
    hecho_compra_tipo_material_id INT NOT NULL,
    hecho_compra_importe_total DECIMAL(18,2)
);

-- Tabla Dimensión: Cliente
CREATE TABLE SILVER_CRIME_RELOADED.BI_Cliente
(
    cliente_id INT IDENTITY(1,1),
    cliente_nombre NVARCHAR(55)
);

-- Tabla de Hechos: Hecho_envio
CREATE TABLE SILVER_CRIME_RELOADED.BI_Hecho_envio
(
    hecho_envio_tiempo_id INT NOT NULL,
    hecho_envio_localidad_id INT NOT NULL,
    hecho_envio_cliente_id INT NOT NULL
);

-- Tabla Dimensión: Turno
CREATE TABLE SILVER_CRIME_RELOADED.BI_Turno
(
    turno_id INT IDENTITY(1,1) ,
    turno_nombre NVARCHAR(55)
);

-- Tabla Dimensión: Estado
CREATE TABLE SILVER_CRIME_RELOADED.BI_Estado
(
    estado_id INT IDENTITY(1,1),
    estado_nombre NVARCHAR(55)
);

-- Tabla de Hechos: Hecho_pedido
CREATE TABLE SILVER_CRIME_RELOADED.BI_Hecho_pedido
(
    hecho_pedido_tiempo_id INT NOT NULL,
    hecho_pedido_turno_id INT NOT NULL,
    hecho_pedido_estado_id INT NOT NULL,
    hecho_pedido_sucursal_id INT NOT NULL
);

------------------------------------------------------------------------
-- Definicion de constraints
-- PRIMARY KEYS
ALTER TABLE SILVER_CRIME_RELOADED.BI_Provincia ADD CONSTRAINT PK_BI_Provincia PRIMARY KEY (provincia_id);
ALTER TABLE SILVER_CRIME_RELOADED.BI_Localidad ADD CONSTRAINT PK_BI_Localidad PRIMARY KEY (localidad_id);
ALTER TABLE SILVER_CRIME_RELOADED.BI_Sucursal ADD CONSTRAINT PK_BI_Sucursal PRIMARY KEY (sucursal_id);
ALTER TABLE SILVER_CRIME_RELOADED.BI_Tiempo ADD CONSTRAINT PK_BI_Tiempo PRIMARY KEY (tiempo_id);
ALTER TABLE SILVER_CRIME_RELOADED.BI_Modelo ADD CONSTRAINT PK_BI_Modelo PRIMARY KEY (modelo_id);
ALTER TABLE SILVER_CRIME_RELOADED.BI_Tipo_material ADD CONSTRAINT PK_BI_Tipo_material PRIMARY KEY (tipo_material_id);
ALTER TABLE SILVER_CRIME_RELOADED.BI_Rango_Etario ADD CONSTRAINT PK_BI_Rango_Etario PRIMARY KEY (rango_etario_id);
ALTER TABLE SILVER_CRIME_RELOADED.BI_Cliente ADD CONSTRAINT PK_BI_Cliente PRIMARY KEY (cliente_id);
ALTER TABLE SILVER_CRIME_RELOADED.BI_Turno ADD CONSTRAINT PK_BI_Turno PRIMARY KEY (turno_id);
ALTER TABLE SILVER_CRIME_RELOADED.BI_Estado ADD CONSTRAINT PK_BI_Estado PRIMARY KEY (estado_id);
-- FOREIGN KEYS
-- Sucursal
ALTER TABLE SILVER_CRIME_RELOADED.BI_Sucursal ADD 
    CONSTRAINT FK_BI_Sucursal_Provincia FOREIGN KEY (sucursal_provincia_id) REFERENCES SILVER_CRIME_RELOADED.BI_Provincia(provincia_id),
    CONSTRAINT FK_BI_Sucursal_Localidad FOREIGN KEY (sucursal_localidad_id) REFERENCES SILVER_CRIME_RELOADED.BI_Localidad(localidad_id);

-- Hecho_compra
ALTER TABLE SILVER_CRIME_RELOADED.BI_Hecho_compra ADD 
    CONSTRAINT FK_BI_Compra_Tiempo FOREIGN KEY (hecho_compra_tiempo_id) REFERENCES SILVER_CRIME_RELOADED.BI_Tiempo(tiempo_id),
    CONSTRAINT FK_BI_Compra_Sucursal FOREIGN KEY (hecho_compra_sucursal_id) REFERENCES SILVER_CRIME_RELOADED.BI_Sucursal(sucursal_id),
    CONSTRAINT FK_BI_Compra_TipoMat FOREIGN KEY (hecho_compra_tipo_material_id) REFERENCES SILVER_CRIME_RELOADED.BI_Tipo_material(tipo_material_id),
    CONSTRAINT PK_BI_Compra PRIMARY KEY (hecho_compra_tiempo_id, hecho_compra_sucursal_id, hecho_compra_tipo_material_id);
-- Hecho_envio
ALTER TABLE SILVER_CRIME_RELOADED.BI_Hecho_envio ADD 
    CONSTRAINT FK_BI_Envio_Tiempo FOREIGN KEY (hecho_envio_tiempo_id) REFERENCES SILVER_CRIME_RELOADED.BI_Tiempo(tiempo_id),
    CONSTRAINT FK_BI_Envio_Localidad FOREIGN KEY (hecho_envio_localidad_id) REFERENCES SILVER_CRIME_RELOADED.BI_Localidad(localidad_id),
    CONSTRAINT FK_BI_Envio_Cliente FOREIGN KEY (hecho_envio_cliente_id) REFERENCES SILVER_CRIME_RELOADED.BI_Cliente(cliente_id),
    CONSTRAINT PK_BI_Envio PRIMARY KEY (hecho_envio_tiempo_id, hecho_envio_localidad_id, hecho_envio_cliente_id);

-- Hecho_pedido
ALTER TABLE SILVER_CRIME_RELOADED.BI_Hecho_pedido ADD 
    CONSTRAINT FK_BI_Pedido_Tiempo FOREIGN KEY (hecho_pedido_tiempo_id) REFERENCES SILVER_CRIME_RELOADED.BI_Tiempo(tiempo_id),
    CONSTRAINT FK_BI_Pedido_Turno FOREIGN KEY (hecho_pedido_turno_id) REFERENCES SILVER_CRIME_RELOADED.BI_Turno(turno_id),
    CONSTRAINT FK_BI_Pedido_Estado FOREIGN KEY (hecho_pedido_estado_id) REFERENCES SILVER_CRIME_RELOADED.BI_Estado(estado_id),
    CONSTRAINT FK_BI_Pedido_Sucursal FOREIGN KEY (hecho_pedido_sucursal_id) REFERENCES SILVER_CRIME_RELOADED.BI_Sucursal(sucursal_id),
    CONSTRAINT PK_BI_Pedido PRIMARY KEY (hecho_pedido_tiempo_id, hecho_pedido_turno_id, hecho_pedido_estado_id, hecho_pedido_sucursal_id);

-- Hecho_factura
ALTER TABLE SILVER_CRIME_RELOADED.BI_Hecho_factura ADD 
    CONSTRAINT FK_BI_Factura_Tiempo FOREIGN KEY (hecho_factura_tiempo_id) REFERENCES SILVER_CRIME_RELOADED.BI_Tiempo(tiempo_id),
    CONSTRAINT FK_BI_Factura_Sucursal FOREIGN KEY (hecho_factura_sucursal_id) REFERENCES SILVER_CRIME_RELOADED.BI_Sucursal(sucursal_id),
    CONSTRAINT FK_BI_Factura_Modelo FOREIGN KEY (hecho_factura_modelo_id) REFERENCES SILVER_CRIME_RELOADED.BI_Modelo(modelo_id),
    CONSTRAINT FK_BI_Factura_RangoEtario FOREIGN KEY (hecho_factura_rango_etario_id) REFERENCES SILVER_CRIME_RELOADED.BI_Rango_Etario(rango_etario_id),
    CONSTRAINT FK_BI_Factura_Provincia FOREIGN KEY (hecho_factura_provincia_id) REFERENCES SILVER_CRIME_RELOADED.BI_Provincia(provincia_id),
    CONSTRAINT FK_BI_Factura_Localidad FOREIGN KEY (hecho_factura_localidad_id) REFERENCES SILVER_CRIME_RELOADED.BI_Localidad(localidad_id),
    CONSTRAINT PK_BI_Factura PRIMARY KEY (hecho_factura_tiempo_id, hecho_factura_sucursal_id, hecho_factura_modelo_id, hecho_factura_rango_etario_id, hecho_factura_provincia_id, hecho_factura_localidad_id);

-------------------------------------------------------------------------------------------------
-- FUNCIONES AUXILIARES DE LA MIGRACION
-------------------------------------------------------------------------------------------------
IF OBJECT_ID('SILVER_CRIME_RELOADED.BI_obtener_rango_etario') IS NOT NULL 
    DROP FUNCTION SILVER_CRIME_RELOADED.BI_obtener_rango_etario;
GO
CREATE FUNCTION SILVER_CRIME_RELOADED.BI_obtener_rango_etario(@fecha DATE) 
RETURNS INT 
AS 
BEGIN
    DECLARE @id INT;
    DECLARE @edad INT;
    SET @edad = DATEDIFF(YEAR, @fecha, GETDATE()) - 
		CASE 
			WHEN MONTH(@fecha) > MONTH(GETDATE()) OR (MONTH(@fecha) = MONTH(GETDATE()) AND DAY(@fecha) > DAY(GETDATE())) 
			THEN 1 
			ELSE 0 
    END;
    SET @id = CASE 
        WHEN @edad < 25 THEN 1 
        WHEN @edad BETWEEN 25 AND 35 THEN 2  
        WHEN @edad BETWEEN 36 AND 50 THEN 3
        WHEN @edad > 50 THEN 4 
        ELSE NULL
    END;
    RETURN @id;
END;
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.BI_obtener_cuatrimestre') IS NOT NULL 
    DROP FUNCTION SILVER_CRIME_RELOADED.BI_obtener_cuatrimestre;
GO
CREATE FUNCTION SILVER_CRIME_RELOADED.BI_obtener_cuatrimestre(@fecha DATE) 
RETURNS INT 
AS 
BEGIN
    DECLARE @cuatrimestre INT;
    SET @cuatrimestre = CASE 
        WHEN MONTH(@fecha) BETWEEN 1 AND 4 THEN 1 
        WHEN MONTH(@fecha) BETWEEN 5 AND 8 THEN 2  
        WHEN MONTH(@fecha) BETWEEN 9 AND 12 THEN 3 
        ELSE NULL
    END;
    RETURN @cuatrimestre;
END;
GO

------------------------------------------------------------------------
-- DEFINICION DE PROCEDURES PARA MIGRACION DE DATOS
-------------------------------------------------------------------------
IF OBJECT_ID('SILVER_CRIME_RELOADED.BI_migrar_provincia') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.BI_migrar_provincia
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.BI_migrar_provincia
AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.BI_Provincia
        (provincia_nombre)
    SELECT DISTINCT provincia_nombre
    FROM SILVER_CRIME_RELOADED.Provincia;
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.BI_migrar_localidad') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.BI_migrar_localidad
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.BI_migrar_localidad
AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.BI_Localidad
        (localidad_nombre)
    SELECT DISTINCT localidad_nombre
    FROM SILVER_CRIME_RELOADED.Localidad;
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.BI_migrar_sucursal') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.BI_migrar_sucursal
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.BI_migrar_sucursal
AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.BI_Sucursal
        (sucursal_provincia_id, sucursal_localidad_id)
    SELECT DISTINCT provincia_id, localidad_id
    FROM SILVER_CRIME_RELOADED.Sucursal
        JOIN SILVER_CRIME_RELOADED.Direccion ON direccion_id = sucursal_direccion
        JOIN SILVER_CRIME_RELOADED.Localidad ON localidad_id = direccion_localidad_id
        JOIN SILVER_CRIME_RELOADED.Provincia ON provincia_id = localidad_provincia_id
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.BI_migrar_modelo') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.BI_migrar_modelo
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.BI_migrar_modelo
AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.BI_Modelo
        (modelo_nombre)
    SELECT DISTINCT sillon_modelo
    FROM SILVER_CRIME_RELOADED.Sillon_modelo;
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.BI_migrar_rango_etario') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.BI_migrar_rango_etario
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.BI_migrar_rango_etario
AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.BI_Rango_Etario
        (rango_etario_nombre)
    VALUES
        ('JUVENTUD'),
        ('ADULTEZ_TEMPRANA'),
        ('ADULTEZ_MEDIA'),
        ('ADULTEZ_AVANZADA');
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.BI_migrar_cliente') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.BI_migrar_cliente
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.BI_migrar_cliente
AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.BI_Cliente
        (cliente_nombre)
    SELECT DISTINCT cliente_nombre
    FROM SILVER_CRIME_RELOADED.Cliente;
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.BI_migrar_tipo_material') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.BI_migrar_tipo_material
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.BI_migrar_tipo_material
AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.BI_Tipo_material
        (tipo_material_nombre)
    SELECT DISTINCT material_tipo
    FROM SILVER_CRIME_RELOADED.Tipo_material;
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.BI_migrar_estado') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.BI_migrar_estado
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.BI_migrar_estado
AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.BI_Estado
        (estado_nombre)
    SELECT DISTINCT estado_descripcion
    FROM SILVER_CRIME_RELOADED.Estado;
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.BI_migrar_tiempo') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.BI_migrar_tiempo
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.BI_migrar_tiempo
AS
BEGIN
    --las fechas salen de compra, envio, pedido y factura
    INSERT INTO SILVER_CRIME_RELOADED.BI_Tiempo
        (tiempo_anio, tiempo_mes, tiempo_cuatrimestre)
                    SELECT DISTINCT YEAR(compra_fecha), MONTH(compra_fecha), SILVER_CRIME_RELOADED.BI_obtener_cuatrimestre(compra_fecha)
        FROM SILVER_CRIME_RELOADED.Compra
    UNION
        SELECT DISTINCT YEAR(envio_fecha_programada), MONTH(envio_fecha_programada), SILVER_CRIME_RELOADED.BI_obtener_cuatrimestre(envio_fecha_programada)
        FROM SILVER_CRIME_RELOADED.Envio
    UNION
        SELECT DISTINCT YEAR(pedido_fecha), MONTH(pedido_fecha), SILVER_CRIME_RELOADED.BI_obtener_cuatrimestre(pedido_fecha)
        FROM SILVER_CRIME_RELOADED.Pedido
    UNION
        SELECT DISTINCT YEAR(factura_fecha), MONTH(factura_fecha), SILVER_CRIME_RELOADED.BI_obtener_cuatrimestre(factura_fecha)
        FROM SILVER_CRIME_RELOADED.Factura;
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.BI_migrar_turno') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.BI_migrar_turno
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.BI_migrar_turno
AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.BI_Turno
        (turno_nombre)
    VALUES
        ('08:00-14:00'),
        ('14:00-20:00');
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_hecho_factura') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_hecho_factura;
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_hecho_factura
AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.BI_Hecho_factura (
        hecho_factura_tiempo_id,
        hecho_factura_sucursal_id,
        hecho_factura_modelo_id,
        hecho_factura_rango_etario_id,
        hecho_factura_provincia_id,
        hecho_factura_localidad_id,
        hecho_factura_total
    )
    SELECT 
        T.tiempo_id,
        Suc.sucursal_nroSucursal,
        M.modelo_id,
        SILVER_CRIME_RELOADED.BI_obtener_rango_etario(C.cliente_fechaNacimiento),
        P.provincia_id,
        L.localidad_id,
        F.factura_total
    FROM SILVER_CRIME_RELOADED.Factura F
        JOIN SILVER_CRIME_RELOADED.Cliente C ON F.factura_cliente_id = C.cliente_id
        JOIN SILVER_CRIME_RELOADED.Sucursal Suc ON F.factura_sucursal_nroSucursal = Suc.sucursal_nroSucursal
        JOIN SILVER_CRIME_RELOADED.Direccion D ON Suc.sucursal_direccion = D.direccion_id
        JOIN SILVER_CRIME_RELOADED.Localidad L ON D.direccion_localidad_id = L.localidad_id
        JOIN SILVER_CRIME_RELOADED.Provincia P ON L.localidad_provincia_id = P.provincia_id
        JOIN SILVER_CRIME_RELOADED.BI_Tiempo T ON T.tiempo_anio = YEAR(F.factura_fecha) AND T.tiempo_mes = MONTH(F.factura_fecha)
        JOIN SILVER_CRIME_RELOADED.Detalle_factura DF ON DF.detalle_factura_nroFactura = F.factura_numero
        JOIN SILVER_CRIME_RELOADED.Sillon S ON S.sillon_codigo = DF.detalle_factura_idDetalle
        JOIN SILVER_CRIME_RELOADED.Sillon_modelo SM ON SM.sillon_modelo_codigo = S.sillon_modelo_codigo
        JOIN SILVER_CRIME_RELOADED.BI_Modelo M ON M.modelo_nombre = SM.sillon_modelo;
END;
GO


IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_hecho_compra') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_hecho_compra;
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_hecho_compra
AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.BI_Hecho_compra (
        hecho_compra_tiempo_id,
        hecho_compra_sucursal_id,
        hecho_compra_tipo_material_id,
        hecho_compra_importe_total
    )
    SELECT 
        T.tiempo_id,
        S.sucursal_id,
        TM.tipo_material_id,
        SUM(DC.detalle_compra_subtotal)
    FROM SILVER_CRIME_RELOADED.Compra C
        JOIN SILVER_CRIME_RELOADED.Detalle_compra DC ON C.compra_numero = DC.detalle_compra_compraID
        JOIN SILVER_CRIME_RELOADED.Material M ON DC.detalle_compra_materialID = M.material_ID
        JOIN SILVER_CRIME_RELOADED.Tipo_material TMT ON M.material_tipo_id = TMT.tipo_ID
        JOIN SILVER_CRIME_RELOADED.BI_Tipo_material TM ON TM.tipo_material_nombre = TMT.material_tipo
        JOIN SILVER_CRIME_RELOADED.Sucursal Suc ON C.compra_nroSucursal = Suc.sucursal_nroSucursal
        JOIN SILVER_CRIME_RELOADED.Direccion D ON Suc.sucursal_direccion = D.direccion_id
        JOIN SILVER_CRIME_RELOADED.Localidad L ON D.direccion_localidad_id = L.localidad_id
        JOIN SILVER_CRIME_RELOADED.Provincia P ON L.localidad_provincia_id = P.provincia_id
        JOIN SILVER_CRIME_RELOADED.BI_Sucursal S ON S.sucursal_provincia_id = P.provincia_id AND S.sucursal_localidad_id = L.localidad_id
        JOIN SILVER_CRIME_RELOADED.BI_Tiempo T ON T.tiempo_anio = YEAR(C.compra_fecha) AND T.tiempo_mes = MONTH(C.compra_fecha)
    GROUP BY T.tiempo_id, S.sucursal_id, TM.tipo_material_id;
END;
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_hecho_envio') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_hecho_envio;
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_hecho_envio
AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.BI_Hecho_envio (
        hecho_envio_tiempo_id,
        hecho_envio_localidad_id,
        hecho_envio_cliente_id
    )
    SELECT 
        T.tiempo_id,
        L.localidad_id,
        CBI.cliente_id
    FROM SILVER_CRIME_RELOADED.Envio E
        JOIN SILVER_CRIME_RELOADED.Factura F ON E.envio_nroFactura = F.factura_numero
        JOIN SILVER_CRIME_RELOADED.Cliente C ON F.factura_cliente_id = C.cliente_id
        JOIN SILVER_CRIME_RELOADED.Direccion D ON C.cliente_direccion = D.direccion_id
        JOIN SILVER_CRIME_RELOADED.Localidad Loc ON D.direccion_localidad_id = Loc.localidad_id
        JOIN SILVER_CRIME_RELOADED.BI_Localidad L ON L.localidad_nombre = Loc.localidad_nombre
        JOIN SILVER_CRIME_RELOADED.BI_Cliente CBI ON CBI.cliente_nombre = C.cliente_nombre
        JOIN SILVER_CRIME_RELOADED.BI_Tiempo T ON T.tiempo_anio = YEAR(E.envio_fecha_programada) AND T.tiempo_mes = MONTH(E.envio_fecha_programada);
END;
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_hecho_pedido') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_hecho_pedido;
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_hecho_pedido
AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.BI_Hecho_pedido (
        hecho_pedido_tiempo_id,
        hecho_pedido_turno_id,
        hecho_pedido_estado_id,
        hecho_pedido_sucursal_id
    )
    SELECT 
        T.tiempo_id,
        CASE 
            WHEN DATEPART(HOUR, P.pedido_fecha) BETWEEN 8 AND 13 THEN 1
            ELSE 2
        END,
        EBI.estado_id,
        SBI.sucursal_id
    FROM SILVER_CRIME_RELOADED.Pedido P
        JOIN SILVER_CRIME_RELOADED.Estado E ON P.pedido_estado_id = E.estado_id
        JOIN SILVER_CRIME_RELOADED.BI_Estado EBI ON EBI.estado_nombre = E.estado_descripcion
        JOIN SILVER_CRIME_RELOADED.Sucursal Suc ON P.pedido_nro_sucursal = Suc.sucursal_nroSucursal
        JOIN SILVER_CRIME_RELOADED.Direccion D ON Suc.sucursal_direccion = D.direccion_id
        JOIN SILVER_CRIME_RELOADED.Localidad L ON D.direccion_localidad_id = L.localidad_id
        JOIN SILVER_CRIME_RELOADED.Provincia PR ON L.localidad_provincia_id = PR.provincia_id
        JOIN SILVER_CRIME_RELOADED.BI_Sucursal SBI ON SBI.sucursal_localidad_id = L.localidad_id AND SBI.sucursal_provincia_id = PR.provincia_id
        JOIN SILVER_CRIME_RELOADED.BI_Tiempo T ON T.tiempo_anio = YEAR(P.pedido_fecha) AND T.tiempo_mes = MONTH(P.pedido_fecha);
END;
GO


-- Ejecutar las migraciones
EXEC SILVER_CRIME_RELOADED.BI_migrar_provincia;
EXEC SILVER_CRIME_RELOADED.BI_migrar_localidad;
EXEC SILVER_CRIME_RELOADED.BI_migrar_sucursal;
EXEC SILVER_CRIME_RELOADED.BI_migrar_modelo;
EXEC SILVER_CRIME_RELOADED.BI_migrar_rango_etario;
EXEC SILVER_CRIME_RELOADED.BI_migrar_cliente;
EXEC SILVER_CRIME_RELOADED.BI_migrar_tipo_material;
EXEC SILVER_CRIME_RELOADED.BI_migrar_estado;
EXEC SILVER_CRIME_RELOADED.BI_migrar_tiempo;
EXEC SILVER_CRIME_RELOADED.BI_migrar_turno;
EXEC SILVER_CRIME_RELOADED.migrar_hecho_factura;
EXEC SILVER_CRIME_RELOADED.migrar_hecho_compra;
EXEC SILVER_CRIME_RELOADED.migrar_hecho_envio;
EXEC SILVER_CRIME_RELOADED.migrar_hecho_pedido;



-- Vistas