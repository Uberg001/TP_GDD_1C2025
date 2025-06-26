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
IF OBJECT_ID('SILVER_CRIME_RELOADED.BI_borrar_fks') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.BI_borrar_fks
GO 
CREATE PROCEDURE SILVER_CRIME_RELOADED.BI_borrar_fks AS
BEGIN
    DECLARE @query nvarchar(255) 
    DECLARE query_cursor CURSOR FOR 
    SELECT 'ALTER TABLE ' 
        + object_schema_name(k.parent_object_id) 
        + '.[' + Object_name(k.parent_object_id) 
        + '] DROP CONSTRAINT ' + k.NAME query 
    FROM sys.foreign_keys k
    WHERE Object_name(k.parent_object_id) LIKE 'BI_%'
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

IF OBJECT_ID('SILVER_CRIME_RELOADED.BI_borrar_tablas') IS NOT NULL 
  DROP PROCEDURE SILVER_CRIME_RELOADED.BI_borrar_tablas
GO 
CREATE PROCEDURE SILVER_CRIME_RELOADED.BI_borrar_tablas AS
BEGIN
    DECLARE @query nvarchar(255) 
    DECLARE query_cursor CURSOR FOR  
        SELECT 'DROP TABLE SILVER_CRIME_RELOADED.' + name
        FROM  sys.tables 
        WHERE schema_id = (
			SELECT schema_id 
			FROM sys.schemas
			WHERE name = 'SILVER_CRIME_RELOADED'
		) AND name LIKE 'BI_%'
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

IF OBJECT_ID('SILVER_CRIME_RELOADED.BI_borrar_procedimientos') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.BI_borrar_procedimientos
GO 
CREATE PROCEDURE SILVER_CRIME_RELOADED.BI_borrar_procedimientos AS
BEGIN
    DECLARE @query nvarchar(255) 
    DECLARE query_cursor CURSOR FOR  
        SELECT 'DROP PROCEDURE SILVER_CRIME_RELOADED.' + name
        FROM  sys.procedures 
        WHERE schema_id = (SELECT schema_id FROM sys.schemas WHERE name = 'SILVER_CRIME_RELOADED') AND name LIKE 'bi_migrar_%'
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
EXEC SILVER_CRIME_RELOADED.BI_borrar_fks;
EXEC SILVER_CRIME_RELOADED.BI_borrar_tablas;
EXEC SILVER_CRIME_RELOADED.BI_borrar_procedimientos;
GO

-------------------------------------------------------------------------
-- CREACION DE TABLAS
-- Tabla Dimensión: Provincia
CREATE TABLE SILVER_CRIME_RELOADED.BI_Provincia (
    provincia_id INT IDENTITY(1,1),
    provincia_nombre NVARCHAR(255)
);

-- Tabla Dimensión: Localidad
CREATE TABLE SILVER_CRIME_RELOADED.BI_Localidad (
    localidad_id INT IDENTITY(1,1),
    localidad_nombre NVARCHAR(255)
);

-- Tabla Dimensión: Sucursal
CREATE TABLE SILVER_CRIME_RELOADED.BI_Sucursal (
    sucursal_id INT IDENTITY(1,1),
    sucursal_provincia_id INT,
    sucursal_localidad_id INT
);

-- Tabla Dimensión: Tiempo
CREATE TABLE SILVER_CRIME_RELOADED.BI_Tiempo (
    tiempo_id INT IDENTITY(1,1),
    tiempo_anio INT,
    tiempo_cuatrimestre INT,
    tiempo_mes INT,
    CONSTRAINT CHK_TiempoCuatrimestre CHECK (tiempo_cuatrimestre between 1 AND 4),
    CONSTRAINT CHK_TiempoMes CHECK (tiempo_mes between 1 AND 12)
);

-- Tabla Dimensión: Modelo
CREATE TABLE SILVER_CRIME_RELOADED.BI_Modelo (
    modelo_id INT IDENTITY(1,1),
    modelo_nombre NVARCHAR(255)
);

-- Tabla Dimensión: Rango_Etario
CREATE TABLE SILVER_CRIME_RELOADED.BI_Rango_Etario (
    rango_etario_id INT IDENTITY(1,1),
    rango_etario_nombre NVARCHAR(50) NOT NULL,
    CONSTRAINT CHK_RangoEtarioNombre CHECK (rango_etario_nombre IN ('JUVENTUD', 'ADULTEZ_TEMPRANA', 'ADULTEZ_MEDIA', 'ADULTEZ_AVANZADA'))
);

-- Tabla de Hechos: Hecho_factura
CREATE TABLE SILVER_CRIME_RELOADED.BI_Hecho_factura (
    hecho_factura_tiempo_id INT NOT NULL,
    hecho_factura_sucursal_id INT NOT NULL,
    hecho_factura_modelo_id INT NOT NULL,
    hecho_factura_rango_etario_id INT NOT NULL,
    hecho_factura_provincia_id INT NOT NULL,
    hecho_factura_localidad_id INT NOT NULL,
    hecho_factura_total DECIMAL(18,2)
);

-- Tabla Dimensión: Tipo_material
CREATE TABLE SILVER_CRIME_RELOADED.BI_Tipo_material (
    tipo_material_id INT IDENTITY(1,1),
    tipo_material_nombre NVARCHAR(255)
);

-- Tabla de Hechos: Hecho_compra
CREATE TABLE SILVER_CRIME_RELOADED.BI_Hecho_compra (
    hecho_compra_tiempo_id INT NOT NULL,
    hecho_compra_sucursal_id INT NOT NULL,
    hecho_compra_tipo_material_id INT NOT NULL,
    hecho_compra_importe_total DECIMAL(18,2)
);

-- Tabla Dimensión: Cliente
CREATE TABLE SILVER_CRIME_RELOADED.BI_Cliente (
    cliente_id INT IDENTITY(1,1),
    cliente_nombre NVARCHAR(255)
);

-- Tabla de Hechos: Hecho_envio
CREATE TABLE SILVER_CRIME_RELOADED.BI_Hecho_envio (
    hecho_envio_tiempo_id INT NOT NULL,
    hecho_envio_localidad_id INT NOT NULL,
    hecho_envio_cliente_id INT NOT NULL,
    hecho_envio_importe_total DECIMAL(18,2), 
    hecho_envio_cantidad INT, 
    hecho_envio_cumplidos INT -- CANTIDAD DE ENVÍOS CUMPLIDOS
);

-- Tabla Dimensión: Turno
CREATE TABLE SILVER_CRIME_RELOADED.BI_Turno (
    turno_id INT IDENTITY(1,1) ,
    turno_nombre NVARCHAR(55)
);

-- Tabla Dimensión: Estado
CREATE TABLE SILVER_CRIME_RELOADED.BI_Estado (
    estado_id INT IDENTITY(1,1),
    estado_nombre NVARCHAR(255)
);

-- Tabla de Hechos: Hecho_pedido
CREATE TABLE SILVER_CRIME_RELOADED.BI_Hecho_pedido (
    hecho_pedido_tiempo_id INT NOT NULL,
    hecho_pedido_turno_id INT NOT NULL,
    hecho_pedido_estado_id INT NOT NULL,
    hecho_pedido_sucursal_id INT NOT NULL,
    hecho_pedido_cantidad INT,
    hecho_pedido_retraso INT -- DÍAS DE RETRASO ENTRE PEDIDO Y FACTURA
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
    INSERT INTO SILVER_CRIME_RELOADED.BI_Sucursal (sucursal_provincia_id, sucursal_localidad_id)
    SELECT 
        BP.provincia_id,
        BL.localidad_id
    FROM SILVER_CRIME_RELOADED.Sucursal S
        JOIN SILVER_CRIME_RELOADED.Direccion D ON S.sucursal_direccion = D.direccion_id
        JOIN SILVER_CRIME_RELOADED.Localidad L ON D.direccion_localidad_id = L.localidad_id
        JOIN SILVER_CRIME_RELOADED.Provincia P ON L.localidad_provincia_id = P.provincia_id
        JOIN SILVER_CRIME_RELOADED.BI_Provincia BP ON BP.provincia_nombre = P.provincia_nombre
        JOIN SILVER_CRIME_RELOADED.BI_Localidad BL ON BL.localidad_nombre = L.localidad_nombre
    GROUP BY BP.provincia_id, BL.localidad_id;
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
        S2.sucursal_id,
        M.modelo_id,
        SILVER_CRIME_RELOADED.BI_obtener_rango_etario(C.cliente_fechaNacimiento) as rango_etario_id,
        BP.provincia_id,
        BL.localidad_id,
        sum(F.factura_total) AS total
    FROM SILVER_CRIME_RELOADED.Factura F
        JOIN SILVER_CRIME_RELOADED.Cliente C ON F.factura_cliente_id = C.cliente_id
        JOIN SILVER_CRIME_RELOADED.Sucursal Suc ON F.factura_sucursal_nroSucursal = Suc.sucursal_nroSucursal
        JOIN SILVER_CRIME_RELOADED.Direccion D ON Suc.sucursal_direccion = D.direccion_id
        JOIN SILVER_CRIME_RELOADED.Localidad L ON D.direccion_localidad_id = L.localidad_id
        JOIN SILVER_CRIME_RELOADED.Provincia P ON L.localidad_provincia_id = P.provincia_id
        JOIN SILVER_CRIME_RELOADED.BI_Tiempo T ON T.tiempo_anio = YEAR(F.factura_fecha) AND T.tiempo_mes = MONTH(F.factura_fecha)
        JOIN SILVER_CRIME_RELOADED.Detalle_factura DF ON DF.detalle_factura_nroFactura = F.factura_numero

        JOIN SILVER_CRIME_RELOADED.BI_Localidad BL ON BL.localidad_nombre = L.localidad_nombre
        JOIN SILVER_CRIME_RELOADED.BI_Provincia BP ON BP.provincia_nombre = P.provincia_nombre
        JOIN SILVER_CRIME_RELOADED.BI_Sucursal S2 ON S2.sucursal_localidad_id = BL.localidad_id AND S2.sucursal_provincia_id = BP.provincia_id
        JOIN SILVER_CRIME_RELOADED.Pedido PD ON PD.pedido_cliente_id=F.factura_cliente_id
        JOIN SILVER_CRIME_RELOADED.Detalle_pedido DPD ON DPD.detalle_pedido_idPedido=PD.pedido_numero
        JOIN SILVER_CRIME_RELOADED.Sillon S ON S.sillon_codigo = DPD.detalle_pedido_sillon_codigo
        
        JOIN SILVER_CRIME_RELOADED.Sillon_modelo SM ON SM.sillon_modelo_codigo = S.sillon_modelo_codigo
        JOIN SILVER_CRIME_RELOADED.BI_Modelo M ON M.modelo_nombre = SM.sillon_modelo
    GROUP BY
        T.tiempo_id,
        S2.sucursal_id,
        M.modelo_id,
        SILVER_CRIME_RELOADED.BI_obtener_rango_etario(C.cliente_fechaNacimiento),
        BP.provincia_id,
        BL.localidad_id
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
        SUM(DC.detalle_compra_subtotal) AS total
    FROM SILVER_CRIME_RELOADED.Compra C
        JOIN SILVER_CRIME_RELOADED.Detalle_compra DC ON C.compra_numero = DC.detalle_compra_compraID
        JOIN SILVER_CRIME_RELOADED.Material M ON DC.detalle_compra_materialID = M.material_ID
        JOIN SILVER_CRIME_RELOADED.Tipo_material TMT ON M.material_tipo_id = TMT.tipo_ID
        JOIN SILVER_CRIME_RELOADED.BI_Tipo_material TM ON TM.tipo_material_nombre = TMT.material_tipo
        JOIN SILVER_CRIME_RELOADED.Sucursal Suc ON C.compra_nroSucursal = Suc.sucursal_nroSucursal
        JOIN SILVER_CRIME_RELOADED.Direccion D ON Suc.sucursal_direccion = D.direccion_id
        JOIN SILVER_CRIME_RELOADED.Localidad L ON D.direccion_localidad_id = L.localidad_id
        JOIN SILVER_CRIME_RELOADED.Provincia P ON L.localidad_provincia_id = P.provincia_id
        JOIN SILVER_CRIME_RELOADED.BI_Localidad BL ON BL.localidad_nombre = L.localidad_nombre
        JOIN SILVER_CRIME_RELOADED.BI_Provincia BP ON BP.provincia_nombre = P.provincia_nombre
        JOIN SILVER_CRIME_RELOADED.BI_Sucursal S ON S.sucursal_localidad_id = BL.localidad_id AND S.sucursal_provincia_id = BP.provincia_id
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
        hecho_envio_cliente_id,
        hecho_envio_importe_total,
        hecho_envio_cantidad,
        hecho_envio_cumplidos
    )
    SELECT 
        T.tiempo_id,
        L.localidad_id,
        CBI.cliente_id,
        SUM(E.envio_total) AS importe_total,
        COUNT(E.envio_fecha_programada) AS total_envios,
        sum(CASE WHEN e.envio_Fecha<=e.envio_fecha_programada THEN 1  else 0 END) AS cumplidos
    FROM SILVER_CRIME_RELOADED.Envio E
        JOIN SILVER_CRIME_RELOADED.Factura F ON E.envio_nroFactura = F.factura_numero
        JOIN SILVER_CRIME_RELOADED.Cliente C ON F.factura_cliente_id = C.cliente_id
        JOIN SILVER_CRIME_RELOADED.Direccion D ON C.cliente_direccion = D.direccion_id
        JOIN SILVER_CRIME_RELOADED.Localidad Loc ON D.direccion_localidad_id = Loc.localidad_id
        JOIN SILVER_CRIME_RELOADED.BI_Localidad L ON L.localidad_nombre = Loc.localidad_nombre
        JOIN SILVER_CRIME_RELOADED.BI_Cliente CBI ON CBI.cliente_nombre = C.cliente_nombre
        JOIN SILVER_CRIME_RELOADED.BI_Tiempo T ON T.tiempo_anio = YEAR(E.envio_fecha_programada) AND T.tiempo_mes = MONTH(E.envio_fecha_programada)
    GROUP BY
        T.tiempo_id,
        L.localidad_id,
        CBI.cliente_id
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
        hecho_pedido_sucursal_id,
        hecho_pedido_cantidad,
        hecho_pedido_retraso
    )
    SELECT 
        T.tiempo_id,
        CASE 
            WHEN DATEPART(HOUR, P.pedido_fecha) BETWEEN 8 AND 13 THEN 1
            ELSE 2
        END AS turno_id,
        EBI.estado_id,
        SBI.sucursal_id,
        COUNT(P.pedido_numero) AS cantidad,
        sum( DATEDIFF(DAY, P.pedido_fecha, F.factura_fecha)) AS retraso
    FROM SILVER_CRIME_RELOADED.Pedido P
        JOIN SILVER_CRIME_RELOADED.Factura F ON P.pedido_cliente_id = F.factura_cliente_id and f.factura_sucursal_nroSucursal = P.pedido_nro_sucursal AND F.factura_fecha IS NOT NULL
        JOIN SILVER_CRIME_RELOADED.Estado E ON P.pedido_estado_id = E.estado_id
        JOIN SILVER_CRIME_RELOADED.BI_Estado EBI ON EBI.estado_nombre = E.estado_descripcion
        JOIN SILVER_CRIME_RELOADED.Sucursal Suc ON P.pedido_nro_sucursal = Suc.sucursal_nroSucursal
        JOIN SILVER_CRIME_RELOADED.Direccion D ON Suc.sucursal_direccion = D.direccion_id
        JOIN SILVER_CRIME_RELOADED.Localidad L ON D.direccion_localidad_id = L.localidad_id
        JOIN SILVER_CRIME_RELOADED.Provincia PR ON L.localidad_provincia_id = PR.provincia_id
        JOIN SILVER_CRIME_RELOADED.BI_Localidad BL ON BL.localidad_nombre = L.localidad_nombre
        JOIN SILVER_CRIME_RELOADED.BI_Provincia BP ON BP.provincia_nombre = PR.provincia_nombre
        JOIN SILVER_CRIME_RELOADED.BI_Sucursal SBI ON SBI.sucursal_localidad_id = BL.localidad_id AND SBI.sucursal_provincia_id = BP.provincia_id
        JOIN SILVER_CRIME_RELOADED.BI_Tiempo T ON T.tiempo_anio = YEAR(P.pedido_fecha) AND T.tiempo_mes = MONTH(P.pedido_fecha)
    GROUP BY 
        T.tiempo_id, 
        CASE 
            WHEN DATEPART(HOUR, P.pedido_fecha) BETWEEN 8 AND 13 THEN 1
            ELSE 2
        END,
        EBI.estado_id,
        SBI.sucursal_id
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
GO

CREATE OR ALTER VIEW SILVER_CRIME_RELOADED.BI_ganancias AS
-- total de ingresos (facturacion) - total de egresos (compras), por cada mes y por cada sucursal
SELECT
    T.tiempo_anio,
    T.tiempo_mes,
    S.sucursal_id,
    SUM(HP.hecho_factura_total) AS total_ingresos,
    SUM(HC.hecho_compra_importe_total) AS total_egresos,
    SUM(HP.hecho_factura_total) - SUM(HC.hecho_compra_importe_total) AS ganancias
FROM SILVER_CRIME_RELOADED.BI_Hecho_factura HP
JOIN SILVER_CRIME_RELOADED.BI_Hecho_compra HC ON HP.hecho_factura_tiempo_id = HC.hecho_compra_tiempo_id
JOIN SILVER_CRIME_RELOADED.BI_Tiempo T ON HP.hecho_factura_tiempo_id = T.tiempo_id AND HC.hecho_compra_tiempo_id = T.tiempo_id
JOIN SILVER_CRIME_RELOADED.BI_Sucursal S ON HP.hecho_factura_sucursal_id = S.sucursal_id AND HC.hecho_compra_sucursal_id = S.sucursal_id
GROUP BY
    T.tiempo_anio,
    T.tiempo_mes,
    S.sucursal_id
GO

CREATE OR ALTER VIEW SILVER_CRIME_RELOADED.BI_factura_promedio_mensual AS
--valor promedio de facturas segun la provincia de la sucursal para cada cuatrimestre de cada año.
-- se calcula en funcion de la sumatoria de las facturas sobre el total de las mismas durante dicho periodo
SELECT 
    T.tiempo_anio,
    T.tiempo_cuatrimestre,
    S.sucursal_provincia_id,
    AVG(HP.hecho_factura_total) AS promedio_facturas
    FROM SILVER_CRIME_RELOADED.BI_Hecho_factura HP
    JOIN SILVER_CRIME_RELOADED.BI_Tiempo T ON HP.hecho_factura_tiempo_id = T.tiempo_id
    JOIN SILVER_CRIME_RELOADED.BI_Sucursal S ON HP.hecho_factura_sucursal_id = S.sucursal_id
    GROUP BY
    T.tiempo_anio,
    T.tiempo_cuatrimestre,
    S.sucursal_provincia_id
GO

CREATE OR ALTER VIEW SILVER_CRIME_RELOADED.BI_rendimiento_modelos AS
--los 3 modelos con mayores ventas para cada cuatrimestre de cada año segun la localidad de la sucursal y rango etario de los clientes
SELECT TOP 3
    T.tiempo_anio,
    T.tiempo_cuatrimestre,
    S.sucursal_localidad_id,
    R.rango_etario_id,
    M.modelo_nombre,
    SUM(HP.hecho_factura_total) AS total_ventas
    FROM SILVER_CRIME_RELOADED.BI_Hecho_factura HP
    JOIN SILVER_CRIME_RELOADED.BI_Tiempo T ON HP.hecho_factura_tiempo_id = T.tiempo_id
    JOIN SILVER_CRIME_RELOADED.BI_Sucursal S ON HP.hecho_factura_sucursal_id = S.sucursal_id
    JOIN SILVER_CRIME_RELOADED.BI_Modelo M ON HP.hecho_factura_modelo_id = M.modelo_id
    JOIN SILVER_CRIME_RELOADED.BI_Rango_Etario R ON HP.hecho_factura_rango_etario_id = R.rango_etario_id
    GROUP BY
    T.tiempo_anio,
    T.tiempo_cuatrimestre,
    S.sucursal_localidad_id,
    R.rango_etario_id,
    M.modelo_nombre
    ORDER BY
    T.tiempo_anio,
    T.tiempo_cuatrimestre,
    S.sucursal_localidad_id,
    R.rango_etario_id,
    SUM(HP.hecho_factura_total) DESC
GO

CREATE OR ALTER VIEW SILVER_CRIME_RELOADED.BI_volumen_pedidos AS
-- cantidad de pedidos por turno, por sucursal segun el mes de cada año
SELECT T.tiempo_anio,
    T.tiempo_mes,
    S.sucursal_id,
    Tu.turno_id,
    COUNT(HP.hecho_pedido_tiempo_id) AS cantidad_pedidos
    FROM SILVER_CRIME_RELOADED.BI_Hecho_pedido HP
    JOIN SILVER_CRIME_RELOADED.BI_Tiempo T ON HP.hecho_pedido_tiempo_id = T.tiempo_id
    JOIN SILVER_CRIME_RELOADED.BI_Turno Tu ON HP.hecho_pedido_turno_id = Tu.turno_id
    JOIN SILVER_CRIME_RELOADED.BI_Sucursal S ON HP.hecho_pedido_sucursal_id = S.sucursal_id
    GROUP BY 
    T.tiempo_anio,
    T.tiempo_mes,
    S.sucursal_id,
    Tu.turno_id
GO

CREATE OR ALTER VIEW SILVER_CRIME_RELOADED.BI_conversion_pedidos AS
--porcentaje de pedidos segun estado, por cuatrimestre y sucursal
SELECT T.tiempo_anio,
    T.tiempo_cuatrimestre,
    S.sucursal_id,
    E.estado_id,
    sum(hecho_pedido_cantidad) AS cantidad_pedidos,
    COUNT(HP.hecho_pedido_estado_id) * 100.0 / sum(hecho_pedido_cantidad) as porcentaje_conversion
    FROM SILVER_CRIME_RELOADED.BI_Hecho_pedido HP
    JOIN SILVER_CRIME_RELOADED.BI_Tiempo T ON HP.hecho_pedido_tiempo_id = T.tiempo_id
    JOIN SILVER_CRIME_RELOADED.BI_Estado E ON HP.hecho_pedido_estado_id = E.estado_id
    JOIN SILVER_CRIME_RELOADED.BI_Sucursal S ON HP.hecho_pedido_sucursal_id = S.sucursal_id
    GROUP BY
    T.tiempo_anio,
    T.tiempo_cuatrimestre,
    S.sucursal_id,
    E.estado_id
GO

CREATE OR ALTER VIEW SILVER_CRIME_RELOADED.BI_tiempo_promedio_fabricacion AS
--tiempo promedio que tarda cada sucursal entre que se registra un pedido y se registra la factura para el mismo. Por cuatrimestre y por sucursal.
SELECT T.tiempo_anio,
    T.tiempo_cuatrimestre,
    S.sucursal_id,
    AVG(
        CASE 
            WHEN HP.hecho_pedido_cantidad > 0 
                THEN CAST(HP.hecho_pedido_retraso AS FLOAT) / HP.hecho_pedido_cantidad
            ELSE NULL -- excluye del promedio si no hay cantidad
        END
    ) AS tiempo_promedio_fabricacion
    FROM SILVER_CRIME_RELOADED.BI_Hecho_pedido HP
    JOIN SILVER_CRIME_RELOADED.BI_Hecho_factura HF ON HP.hecho_pedido_sucursal_id = HF.hecho_factura_sucursal_id
    JOIN SILVER_CRIME_RELOADED.BI_Tiempo T ON HP.hecho_pedido_tiempo_id = T.tiempo_id-- AND HF.hecho_factura_tiempo_id = T.tiempo_id
    JOIN SILVER_CRIME_RELOADED.BI_Sucursal S ON HP.hecho_pedido_sucursal_id = S.sucursal_id and HF.hecho_factura_sucursal_id = S.sucursal_id
    GROUP BY 
    T.tiempo_anio,
    T.tiempo_cuatrimestre,
    S.sucursal_id
GO

CREATE OR ALTER VIEW SILVER_CRIME_RELOADED.BI_promedio_compras AS
-- importe promedio de compras por mes
SELECT tiempo_anio, tiempo_mes,
    AVG(hecho_compra_importe_total) AS promedio_compras
    FROM SILVER_CRIME_RELOADED.BI_Hecho_compra
    JOIN SILVER_CRIME_RELOADED.BI_Tiempo ON hecho_compra_tiempo_id = tiempo_id
    GROUP BY tiempo_anio, tiempo_mes
GO

CREATE OR ALTER VIEW SILVER_CRIME_RELOADED.BI_compras_por_tipo_material AS
--importe total gastado por tipo de material, sucursal y cuatrimestre
SELECT tipo_material_nombre,
    T.tiempo_anio,
    T.tiempo_cuatrimestre,
    S.sucursal_id,
    SUM(hecho_compra_importe_total) AS total_compras
    FROM SILVER_CRIME_RELOADED.BI_Hecho_compra
    JOIN SILVER_CRIME_RELOADED.BI_Tipo_material ON hecho_compra_tipo_material_id = tipo_material_id
    JOIN SILVER_CRIME_RELOADED.BI_Tiempo T ON hecho_compra_tiempo_id = tiempo_id
    JOIN SILVER_CRIME_RELOADED.BI_Sucursal S ON hecho_compra_sucursal_id = sucursal_id
    GROUP BY tipo_material_nombre,
    T.tiempo_anio,  
    T.tiempo_cuatrimestre,
    S.sucursal_id
GO

CREATE OR ALTER VIEW SILVER_CRIME_RELOADED.BI_cumplimiento_envios AS
-- porcentaje de cumplimento de envios en los tiempos programados por mes.
-- se calcula teniendo en cuenta los envios cumplidos en fecha sobre el total de envios para el periodo
SELECT
    T.tiempo_anio,
    T.tiempo_mes,
    CASE 
        WHEN SUM(HE.hecho_envio_cantidad) > 0 
            THEN CAST(SUM(HE.hecho_envio_cumplidos) AS FLOAT) / SUM(HE.hecho_envio_cantidad) * 100
        ELSE 0
    END AS porcentaje_cumplimiento
    from SILVER_CRIME_RELOADED.BI_Hecho_envio HE
    JOIN SILVER_CRIME_RELOADED.BI_Tiempo T ON HE.hecho_envio_tiempo_id = T.tiempo_id
    GROUP BY T.tiempo_anio, T.tiempo_mes
GO

CREATE OR ALTER VIEW SILVER_CRIME_RELOADED.BI_localidades_con_mayor_costo_de_envio AS
-- las 3 (tomando la localidad del cliente) con mayor promedio de costo de envio (total)
select 
    top 3 L.localidad_nombre,
    AVG(HE.hecho_envio_importe_total) AS promedio_costo_envio
    from SILVER_CRIME_RELOADED.BI_Hecho_envio HE
    JOIN SILVER_CRIME_RELOADED.BI_Localidad L ON HE.hecho_envio_localidad_id = L.localidad_id
    GROUP BY L.localidad_nombre
    ORDER BY promedio_costo_envio DESC
GO