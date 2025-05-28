
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

IF OBJECT_ID('SILVER_CRIME_RELOADED.borrar_triggers') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.borrar_triggers
GO 
CREATE PROCEDURE SILVER_CRIME_RELOADED.borrar_triggers AS
BEGIN
    DECLARE @query nvarchar(255) 
    DECLARE query_cursor CURSOR FOR  
        SELECT 'DROP TRIGGER SILVER_CRIME_RELOADED.' + t.name
        FROM sys.triggers t
			INNER JOIN sys.objects o ON t.parent_id = o.object_id
			INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
        WHERE s.name = 'SILVER_CRIME_RELOADED'
    
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
EXEC SILVER_CRIME_RELOADED.borrar_triggers;
GO
-------------------------------------------------------------------------
-- CREACION DE TABLAS
CREATE TABLE SILVER_CRIME_RELOADED.Provincia (
    provincia_id BIGINT IDENTITY(1,1) NOT NULL,
    provincia_nombre NVARCHAR(255)
);

CREATE TABLE SILVER_CRIME_RELOADED.Localidad (
    localidad_id BIGINT IDENTITY(1,1) NOT NULL,
    localidad_provincia_id BIGINT,
    localidad_nombre NVARCHAR(255)
);

CREATE TABLE SILVER_CRIME_RELOADED.Direccion (
    direccion_id BIGINT IDENTITY(1,1) NOT NULL,
    direccion_localidad_id BIGINT,
    direccion_nombre NVARCHAR(255)
);

CREATE TABLE SILVER_CRIME_RELOADED.Cliente (
    cliente_id BIGINT IDENTITY(1,1) NOT NULL,
    cliente_dni BIGINT,
    cliente_nombre NVARCHAR(255),
    cliente_apellido NVARCHAR(255),
    cliente_fechaNacimiento DATETIME2(6),
    cliente_mail NVARCHAR(255),
    cliente_direccion BIGINT,
    cliente_telefono NVARCHAR(255)
);

CREATE TABLE SILVER_CRIME_RELOADED.Pedido (
    pedido_numero DECIMAL(18,0) NOT NULL,
    pedido_cliente_id BIGINT,
    pedido_nro_sucursal BIGINT,
    pedido_estado_id INT,
    pedido_fecha DATETIME2(6),
    pedido_total DECIMAL(18,2),
    pedido_cancelacion_fecha DATETIME2(6),
    pedido_cancelacion_motivo VARCHAR(255)
);

CREATE TABLE SILVER_CRIME_RELOADED.Estado (
    estado_id INT NOT NULL,
    estado_descripcion NVARCHAR(255)
);

CREATE TABLE SILVER_CRIME_RELOADED.Proveedor (
    proveedor_cuit NVARCHAR(255) NOT NULL,
    proveedor_razonSocial NVARCHAR(255),
    proveedor_direccion BIGINT,
    proveedor_telefono NVARCHAR(255),
    proveedor_mail NVARCHAR(255)
);

CREATE TABLE SILVER_CRIME_RELOADED.Sucursal (
    sucursal_nroSucursal BIGINT NOT NULL,
    sucursal_direccion BIGINT,
    sucursal_telefono NVARCHAR(255),
    sucursal_mail NVARCHAR(255)
);

CREATE TABLE SILVER_CRIME_RELOADED.Compra (
    compra_numero DECIMAL(18,0) NOT NULL,
    compra_nroSucursal BIGINT,
    compra_cuitProveedor NVARCHAR(255),
    compra_fecha DATETIME2(6),
    compra_total DECIMAL(18,2)
);

CREATE TABLE SILVER_CRIME_RELOADED.Factura (
    factura_numero BIGINT NOT NULL,
    factura_cliente_id BIGINT,
    factura_sucursal_nroSucursal BIGINT,
    factura_total DECIMAL(18,2),
    factura_fecha DATETIME2(6)
);

CREATE TABLE SILVER_CRIME_RELOADED.Detalle_factura (
    detalle_factura_idDetalle DECIMAL(18,0) NOT NULL,
    detalle_factura_nroFactura BIGINT,
    detalle_factura_precio DECIMAL(18,2),
    detalle_factura_cantidad DECIMAL(18,0),
    detalle_factura_subtotal DECIMAL(18,2)
);

CREATE TABLE SILVER_CRIME_RELOADED.Detalle_pedido (
    detalle_pedido_sillon_codigo BIGINT IDENTITY(1,1) NOT NULL,
    detalle_pedido_idPedido DECIMAL(18,0) NOT NULL,
    detalle_pedido_cantidad BIGINT,
    detalle_pedido_precio_unit DECIMAL(18,2),
    detalle_pedido_subtotal DECIMAL(18,2)
);

CREATE TABLE SILVER_CRIME_RELOADED.Sillon (
    sillon_codigo BIGINT IDENTITY(1,1) NOT NULL,
    sillon_modelo_codigo BIGINT,
    sillon_medida_codigo BIGINT
);

CREATE TABLE SILVER_CRIME_RELOADED.Sillon_modelo (
    sillon_modelo_codigo BIGINT IDENTITY(1,1) NOT NULL,
    sillon_modelo_descripcion NVARCHAR(255),
    sillon_modelo NVARCHAR(255),
    sillon_modelo_precio_base DECIMAL(18,2)
);

CREATE TABLE SILVER_CRIME_RELOADED.Sillon_medida (
    sillon_medida_codigo BIGINT IDENTITY(1,1) NOT NULL,
    sillon_medida_alto DECIMAL(18,2),
    sillon_medida_ancho DECIMAL(18,2),
    sillon_medida_profundidad DECIMAL(18,2),
    sillon_medida_precio DECIMAL(18,2)
);

CREATE TABLE SILVER_CRIME_RELOADED.Envio(
    envio_numero DECIMAL(18,0) IDENTITY(1,1) NOT NULL,
    envio_nroFactura BIGINT,         
    envio_fecha_programada DATETIME2(6),
    envio_fecha DATETIME2(6),
    envio_importeTraslado DECIMAL(18,2),
    envio_importeSubida DECIMAL(18,2),
    envio_total DECIMAL(18,2)
);

CREATE TABLE SILVER_CRIME_RELOADED.Detalle_compra (
    detalle_compra_compraID DECIMAL(18, 0) IDENTITY(1,1) NOT NULL,
    detalle_compra_materialID INT NOT NULL,
    detalle_compra_precio DECIMAL(18, 2),
    detalle_compra_cantidad DECIMAL(18, 0),
    detalle_compra_subtotal DECIMAL(18, 2)
);

CREATE TABLE SILVER_CRIME_RELOADED.Material (
    material_ID INT IDENTITY(1,1) NOT NULL,
    material_nombre NVARCHAR(256),
    material_descripcion NVARCHAR(255),
    material_tipo NVARCHAR(255),
    material_precio DECIMAL(18, 2)
);

CREATE TABLE SILVER_CRIME_RELOADED.Tipo_material (
    tipo_ID INT IDENTITY(1,1) NOT NULL
);

CREATE TABLE SILVER_CRIME_RELOADED.Material_madera (
    tipo_ID INT,
    madera_ID INT IDENTITY(1,1) NOT NULL,
    material_madera_color NVARCHAR(255),
    material_madera_dureza NVARCHAR(255)
);

CREATE TABLE SILVER_CRIME_RELOADED.Material_tela (
    tipo_ID INT,
    tela_ID INT IDENTITY(1,1) NOT NULL,
    material_tela_textura NVARCHAR(255),
    material_tela_color NVARCHAR(255)
);

CREATE TABLE SILVER_CRIME_RELOADED.Material_relleno (
    tipo_ID INT,
    relleno_ID INT IDENTITY(1,1) NOT NULL,
    material_relleno_densidad DECIMAL(18, 2)
);

CREATE TABLE SILVER_CRIME_RELOADED.Material_sillon (
    material_ID INT NOT NULL,
    sillon_ID BIGINT NOT NULL
);
------------------------------------------------------------------------
-- definicion de constraints
ALTER TABLE SILVER_CRIME_RELOADED.Provincia
ADD CONSTRAINT PK_Provincia PRIMARY KEY (provincia_id);

ALTER TABLE SILVER_CRIME_RELOADED.Localidad
ADD CONSTRAINT PK_Localidad PRIMARY KEY (localidad_id),
CONSTRAINT FK_Localidad_Provincia FOREIGN KEY (localidad_provincia_id) REFERENCES SILVER_CRIME_RELOADED.Provincia(provincia_id);

ALTER TABLE SILVER_CRIME_RELOADED.Direccion
ADD CONSTRAINT PK_Direccion PRIMARY KEY (direccion_id),
CONSTRAINT FK_Direccion_Localidad FOREIGN KEY (direccion_localidad_id) REFERENCES SILVER_CRIME_RELOADED.Localidad(localidad_id);

ALTER TABLE SILVER_CRIME_RELOADED.Cliente
ADD CONSTRAINT PK_Cliente PRIMARY KEY (cliente_id),
CONSTRAINT FK_Cliente_Localidad FOREIGN KEY (cliente_direccion) REFERENCES SILVER_CRIME_RELOADED.Direccion(direccion_id);

ALTER TABLE SILVER_CRIME_RELOADED.Estado
ADD CONSTRAINT PK_Estado PRIMARY KEY (estado_id);

ALTER TABLE SILVER_CRIME_RELOADED.Pedido
ADD CONSTRAINT PK_Pedido PRIMARY KEY (pedido_numero),
CONSTRAINT FK_Pedido_Cliente FOREIGN KEY (pedido_cliente_id) REFERENCES SILVER_CRIME_RELOADED.Cliente(cliente_id),
CONSTRAINT FK_Pedido_Estado FOREIGN KEY (pedido_estado_id) REFERENCES SILVER_CRIME_RELOADED.Estado(estado_id);

ALTER TABLE SILVER_CRIME_RELOADED.Proveedor
ADD CONSTRAINT PK_Proveedor PRIMARY KEY (proveedor_cuit),
CONSTRAINT FK_Proveedor_Direccion FOREIGN KEY (proveedor_direccion) REFERENCES SILVER_CRIME_RELOADED.Direccion(direccion_id);

ALTER TABLE SILVER_CRIME_RELOADED.Sucursal
ADD CONSTRAINT PK_Sucursal PRIMARY KEY (sucursal_nroSucursal),
CONSTRAINT FK_Sucursal_Direccion FOREIGN KEY (sucursal_direccion) REFERENCES SILVER_CRIME_RELOADED.Direccion(direccion_id);

ALTER TABLE SILVER_CRIME_RELOADED.Compra
ADD  CONSTRAINT PK_Compra PRIMARY KEY (compra_numero),
CONSTRAINT FK_Compra_Sucursal FOREIGN KEY (compra_nroSucursal) REFERENCES SILVER_CRIME_RELOADED.Sucursal(sucursal_nroSucursal),
CONSTRAINT FK_Compra_Proveedor FOREIGN KEY (compra_cuitProveedor) REFERENCES SILVER_CRIME_RELOADED.Proveedor(proveedor_cuit);

ALTER TABLE SILVER_CRIME_RELOADED.Factura
ADD CONSTRAINT PK_Factura PRIMARY KEY (factura_numero),
CONSTRAINT FK_Factura_Cliente FOREIGN KEY (factura_cliente_id) REFERENCES SILVER_CRIME_RELOADED.Cliente(cliente_id),
CONSTRAINT FK_Factura_Sucursal FOREIGN KEY (factura_sucursal_nroSucursal) REFERENCES SILVER_CRIME_RELOADED.Sucursal(sucursal_nroSucursal);

ALTER TABLE SILVER_CRIME_RELOADED.Detalle_factura
ADD CONSTRAINT PK_Detalle_factura PRIMARY KEY (detalle_factura_idDetalle),
CONSTRAINT FK_DetalleFactura_Factura FOREIGN KEY (detalle_factura_nroFactura) REFERENCES SILVER_CRIME_RELOADED.Factura(factura_numero);

ALTER TABLE SILVER_CRIME_RELOADED.Sillon_modelo
ADD CONSTRAINT PK_Sillon_modelo PRIMARY KEY (sillon_modelo_codigo);

ALTER TABLE SILVER_CRIME_RELOADED.Sillon_medida
ADD CONSTRAINT PK_Sillon_medida PRIMARY KEY (sillon_medida_codigo);

ALTER TABLE SILVER_CRIME_RELOADED.Sillon
ADD CONSTRAINT PK_Sillon PRIMARY KEY (sillon_codigo),
CONSTRAINT FK_Sillon_Modelo FOREIGN KEY (sillon_modelo_codigo) REFERENCES SILVER_CRIME_RELOADED.Sillon_modelo(sillon_modelo_codigo),
CONSTRAINT FK_Sillon_Medida FOREIGN KEY (sillon_medida_codigo) REFERENCES SILVER_CRIME_RELOADED.Sillon_medida(sillon_medida_codigo);

ALTER TABLE SILVER_CRIME_RELOADED.Detalle_pedido
ADD CONSTRAINT PK_Detalle_pedido PRIMARY KEY (detalle_pedido_sillon_codigo, detalle_pedido_idPedido),
CONSTRAINT FK_DetallePedido_Sillon FOREIGN KEY (detalle_pedido_sillon_codigo) REFERENCES SILVER_CRIME_RELOADED.Sillon(sillon_codigo),
CONSTRAINT FK_DetallePedido_Pedido FOREIGN KEY (detalle_pedido_idPedido) REFERENCES SILVER_CRIME_RELOADED.Pedido(pedido_numero);

ALTER TABLE SILVER_CRIME_RELOADED.Envio
ADD CONSTRAINT PK_Envio PRIMARY KEY (envio_numero),
CONSTRAINT FK_Envio_Factura FOREIGN KEY (envio_nroFactura) REFERENCES SILVER_CRIME_RELOADED.Factura(factura_numero);

ALTER TABLE SILVER_CRIME_RELOADED.Material
ADD CONSTRAINT PK_Material PRIMARY KEY (material_ID);

ALTER TABLE SILVER_CRIME_RELOADED.Tipo_material
ADD CONSTRAINT PK_Tipo_material PRIMARY KEY (tipo_ID);

ALTER TABLE SILVER_CRIME_RELOADED.Material_madera
ADD CONSTRAINT PK_Material_madera PRIMARY KEY (madera_ID),
CONSTRAINT FK_Material_madera_tipo FOREIGN KEY (tipo_ID) REFERENCES SILVER_CRIME_RELOADED.Tipo_material(tipo_ID);

ALTER TABLE SILVER_CRIME_RELOADED.Material_tela
ADD CONSTRAINT PK_Material_tela PRIMARY KEY (tela_ID),
CONSTRAINT FK_Material_tela_tipo FOREIGN KEY (tipo_ID) REFERENCES SILVER_CRIME_RELOADED.Tipo_material(tipo_ID);

ALTER TABLE SILVER_CRIME_RELOADED.Material_relleno
ADD CONSTRAINT PK_Material_relleno PRIMARY KEY (relleno_ID),
CONSTRAINT FK_Material_relleno_tipo FOREIGN KEY (tipo_ID) REFERENCES SILVER_CRIME_RELOADED.Tipo_material(tipo_ID);

ALTER TABLE SILVER_CRIME_RELOADED.Material_sillon
ADD CONSTRAINT FK_Material_sillon FOREIGN KEY (sillon_ID) REFERENCES SILVER_CRIME_RELOADED.Sillon(sillon_codigo),
CONSTRAINT FK_Material_sillon_material FOREIGN KEY (material_ID) REFERENCES SILVER_CRIME_RELOADED.Material(material_ID),
CONSTRAINT PK_material_sillon PRIMARY KEY (sillon_ID,material_ID);

ALTER TABLE SILVER_CRIME_RELOADED.Detalle_compra
ADD CONSTRAINT FK_detalle_compra FOREIGN KEY (detalle_compra_compraID) REFERENCES SILVER_CRIME_RELOADED.Compra(compra_numero),
CONSTRAINT FK_Detalle_compra_material FOREIGN KEY (detalle_compra_materialID) REFERENCES SILVER_CRIME_RELOADED.Material(material_ID),
CONSTRAINT PK_detalle_compra PRIMARY KEY (detalle_compra_compraID,detalle_compra_materialID);
------------------------------------------------------------------------
-- DEFINICION DE PROCEDURES PARA MIGRACION DE DATOS
IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_provincias') IS NOT NULL 
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_provincias
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_provincias AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Provincia (provincia_nombre) VALUES
        ('Buenos Aires'),
        ('Capital Federal'),
        ('Catamarca'),
        ('Chaco'),
        ('Chubut'),
        ('Cordoba'),
        ('Corrientes'),
        ('Entre Rios'),
        ('Formosa'),
        ('Jujuy'),
        ('La Pampa'),
        ('La Rioja'),
        ('Mendoza'),
        ('Misiones'),
        ('Neuquen'),
        ('Rio Negro'),
        ('Salta'),
        ('San Juan'),
        ('San Luis'),
        ('Santa Cruz'),
        ('Santa Fe'),
        ('Santiago del Estero'),
        ('Tierra del Fuego'),
        ('Tucuman');
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_localidades') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_localidades
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_localidades AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Localidad (localidad_nombre, localidad_provincia_id)
    SELECT DISTINCT L.localidad_nombre, P.provincia_id
    FROM (
        SELECT Sucursal_Localidad AS localidad_nombre, Sucursal_Provincia AS provincia_nombre FROM gd_esquema.Maestra
        UNION
        SELECT Proveedor_Localidad, Proveedor_Provincia FROM gd_esquema.Maestra
        UNION
        SELECT Cliente_Localidad, Cliente_Provincia FROM gd_esquema.Maestra
    ) L
    INNER JOIN SILVER_CRIME_RELOADED.Provincia P ON P.provincia_nombre = L.provincia_nombre;
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_direcciones') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_direcciones
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_direcciones AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Direccion (direccion_nombre, direccion_localidad_id)
        SELECT DISTINCT M.Direccion, L.localidad_id
        FROM (
            SELECT Sucursal_Direccion AS Direccion, Sucursal_Localidad AS Localidad, Sucursal_Provincia AS Provincia FROM gd_esquema.Maestra
            UNION
            SELECT Proveedor_Direccion, Proveedor_Localidad, Proveedor_Provincia FROM gd_esquema.Maestra
            UNION
            SELECT Cliente_Direccion, Cliente_Localidad, Cliente_Provincia FROM gd_esquema.Maestra
        ) M
        INNER JOIN SILVER_CRIME_RELOADED.Localidad L
            ON L.localidad_nombre = M.Localidad
            AND L.localidad_provincia_id = (
                SELECT provincia_id FROM SILVER_CRIME_RELOADED.Provincia WHERE provincia_nombre = M.Provincia
            )
END
GO

----------------------------------------------
--MIGRACION
EXEC SILVER_CRIME_RELOADED.migrar_provincias;
EXEC SILVER_CRIME_RELOADED.migrar_localidades;
EXEC SILVER_CRIME_RELOADED.migrar_direcciones;