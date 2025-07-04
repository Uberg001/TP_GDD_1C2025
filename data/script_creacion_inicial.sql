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
    pedido_cliente_id BIGINT NOT NULL,
    pedido_nro_sucursal BIGINT NOT NULL,
    pedido_estado_id INT NOT NULL,
    pedido_fecha DATETIME2(6),
    pedido_total DECIMAL(18,2),
    pedido_cancelacion_fecha DATETIME2(6),
    pedido_cancelacion_motivo VARCHAR(255)
);

CREATE TABLE SILVER_CRIME_RELOADED.Estado (
    estado_id INT IDENTITY(1,1) NOT NULL,
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
    detalle_factura_idDetalle DECIMAL(18,0) IDENTITY(1,1) NOT NULL,
    detalle_factura_nroFactura BIGINT,
    detalle_factura_precio DECIMAL(18,2),
    detalle_factura_cantidad DECIMAL(18,0),
    detalle_factura_subtotal DECIMAL(18,2)
);

CREATE TABLE SILVER_CRIME_RELOADED.Sillon (
    sillon_codigo BIGINT NOT NULL,
    sillon_modelo_codigo BIGINT,
    sillon_medida_codigo BIGINT
);

CREATE TABLE SILVER_CRIME_RELOADED.Sillon_modelo (
    sillon_modelo_codigo BIGINT NOT NULL,
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

CREATE TABLE SILVER_CRIME_RELOADED.Detalle_pedido (
    detalle_pedido_sillon_codigo BIGINT NOT NULL,
    detalle_pedido_idPedido DECIMAL(18,0) NOT NULL,
    detalle_pedido_cantidad BIGINT,
    detalle_pedido_precio_unit DECIMAL(18,2),
    detalle_pedido_subtotal DECIMAL(18,2),
    detalle_pedido_cliente_id BIGINT NOT NULL,
    detalle_pedido_nro_sucursal BIGINT NOT NULL
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
    detalle_compra_compraID DECIMAL(18, 0)  NOT NULL,
    detalle_compra_materialID INT NOT NULL,
    detalle_compra_precio DECIMAL(18, 2),
    detalle_compra_cantidad DECIMAL(18, 0),
    detalle_compra_subtotal DECIMAL(18, 2)
);

CREATE TABLE SILVER_CRIME_RELOADED.Material (
    material_ID INT IDENTITY(1,1) NOT NULL,
    material_nombre NVARCHAR(256),
    material_descripcion NVARCHAR(255),
    material_tipo_id INT,
    material_precio DECIMAL(18, 2)
);

CREATE TABLE SILVER_CRIME_RELOADED.Tipo_material (
    tipo_ID INT IDENTITY(1,1) NOT NULL,
    material_tipo NVARCHAR(255) 
);

CREATE TABLE SILVER_CRIME_RELOADED.Material_madera (
    madera_ID INT NOT NULL,
    material_madera_color NVARCHAR(255),
    material_madera_dureza NVARCHAR(255)
);

CREATE TABLE SILVER_CRIME_RELOADED.Material_tela (
    tela_ID INT NOT NULL,
    material_tela_textura NVARCHAR(255),
    material_tela_color NVARCHAR(255)
);

CREATE TABLE SILVER_CRIME_RELOADED.Material_relleno (
    relleno_ID INT NOT NULL,
    material_relleno_densidad DECIMAL(18, 2)
);

CREATE TABLE SILVER_CRIME_RELOADED.Material_sillon (
    sillon_material_ID INT NOT NULL,
    sillon_ID BIGINT NOT NULL
);
------------------------------------------------------------------------
-- Definicion de constraints
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

ALTER TABLE SILVER_CRIME_RELOADED.Sucursal
ADD CONSTRAINT PK_Sucursal PRIMARY KEY (sucursal_nroSucursal),
CONSTRAINT FK_Sucursal_Direccion FOREIGN KEY (sucursal_direccion) REFERENCES SILVER_CRIME_RELOADED.Direccion(direccion_id);

ALTER TABLE SILVER_CRIME_RELOADED.Pedido
ADD CONSTRAINT FK_Pedido_Cliente FOREIGN KEY (pedido_cliente_id) REFERENCES SILVER_CRIME_RELOADED.Cliente(cliente_id),
CONSTRAINT FK_Pedido_Estado FOREIGN KEY (pedido_estado_id) REFERENCES SILVER_CRIME_RELOADED.Estado(estado_id),
CONSTRAINT FK_Pedido_Sucursal FOREIGN KEY (pedido_nro_Sucursal) REFERENCES SILVER_CRIME_RELOADED.Sucursal(sucursal_nroSucursal),
CONSTRAINT PK_Pedido PRIMARY KEY (pedido_numero,pedido_cliente_id,pedido_nro_Sucursal);

ALTER TABLE SILVER_CRIME_RELOADED.Proveedor
ADD CONSTRAINT PK_Proveedor PRIMARY KEY (proveedor_cuit),
CONSTRAINT FK_Proveedor_Direccion FOREIGN KEY (proveedor_direccion) REFERENCES SILVER_CRIME_RELOADED.Direccion(direccion_id);

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
ADD CONSTRAINT FK_DetallePedido_Sillon FOREIGN KEY (detalle_pedido_sillon_codigo) REFERENCES SILVER_CRIME_RELOADED.Sillon(sillon_codigo),
CONSTRAINT FK_DetallePedido_Pedido FOREIGN KEY (detalle_pedido_idPedido, detalle_pedido_cliente_id, detalle_pedido_nro_sucursal) REFERENCES SILVER_CRIME_RELOADED.Pedido(pedido_numero, pedido_cliente_id, pedido_nro_Sucursal),
CONSTRAINT PK_Detalle_pedido PRIMARY KEY (detalle_pedido_sillon_codigo, detalle_pedido_idPedido, detalle_pedido_cliente_id, detalle_pedido_nro_sucursal);

ALTER TABLE SILVER_CRIME_RELOADED.Envio
ADD CONSTRAINT PK_Envio PRIMARY KEY (envio_numero),
CONSTRAINT FK_Envio_Factura FOREIGN KEY (envio_nroFactura) REFERENCES SILVER_CRIME_RELOADED.Factura(factura_numero);

ALTER TABLE SILVER_CRIME_RELOADED.Tipo_material
ADD CONSTRAINT PK_Tipo_material PRIMARY KEY (tipo_ID);

ALTER TABLE SILVER_CRIME_RELOADED.Material
ADD CONSTRAINT PK_Material PRIMARY KEY (material_ID),
CONSTRAINT FK_material_tipo FOREIGN KEY (material_tipo_id) REFERENCES SILVER_CRIME_RELOADED.Tipo_material(tipo_ID);

ALTER TABLE SILVER_CRIME_RELOADED.Material_madera
ADD CONSTRAINT FK_Material_madera_tipo FOREIGN KEY (madera_ID) REFERENCES SILVER_CRIME_RELOADED.Material(material_ID),
CONSTRAINT PK_Material_madera PRIMARY KEY (madera_ID);

ALTER TABLE SILVER_CRIME_RELOADED.Material_tela
ADD CONSTRAINT FK_Material_tela_tipo FOREIGN KEY (tela_ID) REFERENCES SILVER_CRIME_RELOADED.Material(material_ID),
CONSTRAINT PK_Material_tela PRIMARY KEY (tela_ID);

ALTER TABLE SILVER_CRIME_RELOADED.Material_relleno
ADD CONSTRAINT FK_Material_relleno_tipo FOREIGN KEY (relleno_ID) REFERENCES SILVER_CRIME_RELOADED.Material(material_ID),
CONSTRAINT PK_Material_relleno PRIMARY KEY (relleno_ID);

ALTER TABLE SILVER_CRIME_RELOADED.Material_sillon
ADD CONSTRAINT FK_Material_sillon FOREIGN KEY (sillon_ID) REFERENCES SILVER_CRIME_RELOADED.Sillon(sillon_codigo),
CONSTRAINT FK_Material_sillon_material FOREIGN KEY (sillon_material_ID) REFERENCES SILVER_CRIME_RELOADED.Material(material_ID),
CONSTRAINT PK_material_sillon PRIMARY KEY (sillon_ID,sillon_material_ID);

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
    INSERT INTO SILVER_CRIME_RELOADED.Provincia (provincia_nombre)
    -- Seleccionar provincias únicas de la tabla Maestra, usando union para combinar las diferentes columnas de provincia
    SELECT DISTINCT Sucursal_Provincia AS provincia_nombre 
    FROM gd_esquema.Maestra 
    WHERE Sucursal_Provincia IS NOT NULL
    UNION
    SELECT DISTINCT Cliente_Provincia 
    FROM gd_esquema.Maestra 
    WHERE Cliente_Provincia IS NOT NULL
    UNION
    SELECT DISTINCT Proveedor_Provincia 
    FROM gd_esquema.Maestra 
    WHERE Proveedor_Provincia IS NOT NULL;
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_localidades') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_localidades
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_localidades AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Localidad (localidad_nombre, localidad_provincia_id)
    -- Seleccionar localidades únicas de la tabla Maestra, uniendo con la tabla Provincia para obtener el ID de provincia
    SELECT DISTINCT 
        Sucursal_Localidad AS localidad_nombre, 
        P.provincia_id
    FROM gd_esquema.Maestra M
    JOIN SILVER_CRIME_RELOADED.Provincia P 
        ON P.provincia_nombre = M.Sucursal_Provincia
    WHERE Sucursal_Localidad IS NOT NULL AND Sucursal_Provincia IS NOT NULL
    UNION
    SELECT DISTINCT 
        Proveedor_Localidad, 
        P.provincia_id
    FROM gd_esquema.Maestra M
    JOIN SILVER_CRIME_RELOADED.Provincia P 
        ON P.provincia_nombre = M.Proveedor_Provincia
    WHERE Proveedor_Localidad IS NOT NULL AND Proveedor_Provincia IS NOT NULL
    UNION
    SELECT DISTINCT 
        Cliente_Localidad, 
        P.provincia_id
    FROM gd_esquema.Maestra M
    JOIN SILVER_CRIME_RELOADED.Provincia P 
        ON P.provincia_nombre = M.Cliente_Provincia
    WHERE Cliente_Localidad IS NOT NULL AND Cliente_Provincia IS NOT NULL;
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_direcciones') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_direcciones
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_direcciones AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Direccion (direccion_nombre, direccion_localidad_id)
    -- Seleccionar direcciones únicas de la tabla Maestra, uniendo con las tablas Localidad y Provincia para obtener el ID de localidad
        SELECT DISTINCT 
            M.Sucursal_Direccion AS Direccion,
            L.localidad_id
        FROM gd_esquema.Maestra M
        JOIN SILVER_CRIME_RELOADED.Localidad L 
            ON L.localidad_nombre = M.Sucursal_Localidad
        JOIN SILVER_CRIME_RELOADED.Provincia P
            ON P.provincia_nombre = M.Sucursal_Provincia
            AND L.localidad_provincia_id = P.provincia_id
        WHERE M.Sucursal_Direccion IS NOT NULL 
          AND M.Sucursal_Localidad IS NOT NULL 
          AND M.Sucursal_Provincia IS NOT NULL
        UNION
        SELECT DISTINCT 
            M.Proveedor_Direccion,
            L.localidad_id
        FROM gd_esquema.Maestra M
        JOIN SILVER_CRIME_RELOADED.Localidad L 
            ON L.localidad_nombre = M.Proveedor_Localidad
        JOIN SILVER_CRIME_RELOADED.Provincia P
            ON P.provincia_nombre = M.Proveedor_Provincia
            AND L.localidad_provincia_id = P.provincia_id
        WHERE M.Proveedor_Direccion IS NOT NULL 
          AND M.Proveedor_Localidad IS NOT NULL 
          AND M.Proveedor_Provincia IS NOT NULL
        UNION
        SELECT DISTINCT 
            M.Cliente_Direccion,
            L.localidad_id
        FROM gd_esquema.Maestra M
        JOIN SILVER_CRIME_RELOADED.Localidad L 
            ON L.localidad_nombre = M.Cliente_Localidad
        JOIN SILVER_CRIME_RELOADED.Provincia P
            ON P.provincia_nombre = M.Cliente_Provincia
            AND L.localidad_provincia_id = P.provincia_id
        WHERE M.Cliente_Direccion IS NOT NULL 
          AND M.Cliente_Localidad IS NOT NULL 
          AND M.Cliente_Provincia IS NOT NULL;
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_clientes') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_clientes
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_clientes AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Cliente (
        cliente_dni,
        cliente_nombre,
        cliente_apellido,
        cliente_fechaNacimiento,
        cliente_mail,
        cliente_direccion,
        cliente_telefono
    )
    -- Seleccionar clientes únicos de la tabla Maestra, uniendo con las tablas Localidad y Provincia para obtener el ID de dirección
    SELECT DISTINCT
        m.Cliente_DNI,
        m.Cliente_Nombre,
        m.Cliente_Apellido,
        m.Cliente_FechaNacimiento,
        m.Cliente_Mail,
        d.direccion_id,
        m.Cliente_Telefono
    FROM gd_esquema.Maestra m
    INNER JOIN SILVER_CRIME_RELOADED.Provincia p
        ON p.provincia_nombre = m.Cliente_Provincia
    INNER JOIN SILVER_CRIME_RELOADED.Localidad l
        ON l.localidad_nombre = m.Cliente_Localidad
        AND l.localidad_provincia_id = p.provincia_id
    INNER JOIN SILVER_CRIME_RELOADED.Direccion d
        ON d.direccion_nombre = m.Cliente_Direccion
        AND d.direccion_localidad_id = l.localidad_id
    WHERE m.Cliente_DNI IS NOT NULL
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_estados') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_estados
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_estados AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Estado (estado_descripcion)
    -- Seleccionar estados únicos de la tabla Maestra
    SELECT DISTINCT Pedido_Estado as estado_descripcion FROM gd_esquema.Maestra 
    WHERE Pedido_Estado IS NOT NULL
    -- Agregar el estado 'PENDIENTE' si no existe
    IF NOT EXISTS (
        SELECT 1 
        FROM SILVER_CRIME_RELOADED.Estado
        WHERE estado_descripcion = 'PENDIENTE'
    )
    BEGIN
        INSERT INTO SILVER_CRIME_RELOADED.Estado (estado_descripcion)
        VALUES ('PENDIENTE')
    END
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_sucursales') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_sucursales
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_sucursales AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Sucursal (
        sucursal_nroSucursal,
        sucursal_direccion,
        sucursal_telefono,
        sucursal_mail
    )
    -- Seleccionar sucursales únicas de la tabla Maestra, uniendo con las tablas Localidad y Provincia para obtener el ID de dirección
    SELECT DISTINCT
        m.Sucursal_NroSucursal,
        d.direccion_id,
        m.Sucursal_Telefono,
        m.Sucursal_Mail
    FROM gd_esquema.Maestra m
    INNER JOIN SILVER_CRIME_RELOADED.Provincia p
        ON p.provincia_nombre = m.Sucursal_Provincia
    INNER JOIN SILVER_CRIME_RELOADED.Localidad l
        ON l.localidad_nombre = m.Sucursal_Localidad
        AND l.localidad_provincia_id = p.provincia_id
    INNER JOIN SILVER_CRIME_RELOADED.Direccion d
        ON d.direccion_nombre = m.Sucursal_Direccion
        AND d.direccion_localidad_id = l.localidad_id
    WHERE m.Sucursal_NroSucursal IS NOT NULL
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_pedidos') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_pedidos
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_pedidos AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Pedido (
        pedido_numero,
        pedido_cliente_id,
        pedido_nro_sucursal,
        pedido_estado_id,
        pedido_fecha,
        pedido_total,
        pedido_cancelacion_fecha,
        pedido_cancelacion_motivo
    )
    -- Seleccionar pedidos únicos de la tabla Maestra, uniendo con las tablas Cliente y Estado para obtener los IDs correspondientes
    SELECT 
        m.Pedido_Numero,
        c.cliente_id,
        m.Sucursal_NroSucursal,
        MIN(e.estado_id),
        MIN(m.Pedido_Fecha),
        MIN(m.Pedido_Total),
        MIN(m.Pedido_Cancelacion_Fecha),
        MIN(m.Pedido_Cancelacion_Motivo)
    FROM gd_esquema.Maestra m
    JOIN SILVER_CRIME_RELOADED.Cliente c
        ON c.cliente_dni = m.Cliente_DNI
    JOIN SILVER_CRIME_RELOADED.Estado e
        ON e.estado_descripcion = m.Pedido_Estado
    WHERE m.Pedido_Numero IS NOT NULL
      AND m.Cliente_DNI IS NOT NULL
      AND m.Pedido_Estado IS NOT NULL
      AND m.Sucursal_NroSucursal IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 
          FROM SILVER_CRIME_RELOADED.Pedido p
          WHERE p.pedido_numero = m.Pedido_Numero
            AND p.pedido_cliente_id = c.cliente_id
            AND p.pedido_nro_sucursal = m.Sucursal_NroSucursal
      )
    GROUP BY 
        m.Pedido_Numero,
        c.cliente_id,
        m.Sucursal_NroSucursal;
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_proveedores') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_proveedores
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_proveedores AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Proveedor (
        proveedor_cuit,
        proveedor_razonSocial,
        proveedor_direccion,
        proveedor_telefono,
        proveedor_mail
    )
    -- Seleccionar proveedores únicos de la tabla Maestra, uniendo con las tablas Localidad y Provincia para obtener el ID de dirección
    SELECT DISTINCT
        m.Proveedor_CUIT,
        m.Proveedor_RazonSocial,
        d.direccion_id,
        m.Proveedor_Telefono,
        m.Proveedor_Mail
    FROM gd_esquema.Maestra m
    INNER JOIN SILVER_CRIME_RELOADED.Provincia p
        ON p.provincia_nombre = m.Proveedor_Provincia
    INNER JOIN SILVER_CRIME_RELOADED.Localidad l
        ON l.localidad_nombre = m.Proveedor_Localidad
        AND l.localidad_provincia_id = p.provincia_id
    INNER JOIN SILVER_CRIME_RELOADED.Direccion d
        ON d.direccion_nombre = m.Proveedor_Direccion
        AND d.direccion_localidad_id = l.localidad_id
    WHERE m.Proveedor_CUIT IS NOT NULL
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_compras') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_compras
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_compras AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Compra (
        compra_numero,
        compra_nroSucursal,
        compra_cuitProveedor,
        compra_fecha,
        compra_total
    )
    -- Seleccionar compras únicas de la tabla Maestra, uniendo con las tablas Proveedor y Sucursal para obtener los IDs correspondientes
    SELECT DISTINCT
        m.Compra_Numero,
        m.Sucursal_NroSucursal,
        m.Proveedor_CUIT,
        m.Compra_Fecha,
        m.Compra_Total
    FROM gd_esquema.Maestra m
    WHERE m.Compra_Numero IS NOT NULL
      AND m.Sucursal_NroSucursal IS NOT NULL
      AND m.Proveedor_CUIT IS NOT NULL;
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_facturas') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_facturas
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_facturas AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Factura (
        factura_numero,
        factura_cliente_id,
        factura_sucursal_nroSucursal,
        factura_total,
        factura_fecha
    )
    -- Seleccionar facturas únicas de la tabla Maestra, uniendo con la tabla Cliente para obtener el ID de cliente
    SELECT DISTINCT
        m.Factura_Numero,
        c.cliente_id,
        m.Sucursal_NroSucursal,
        m.Factura_Total,
        m.Factura_Fecha
    FROM gd_esquema.Maestra m
    INNER JOIN SILVER_CRIME_RELOADED.Cliente c
        ON c.cliente_dni = m.Cliente_DNI
    WHERE m.Factura_Numero IS NOT NULL
      AND m.Cliente_DNI IS NOT NULL
      AND m.Sucursal_NroSucursal IS NOT NULL
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_detalle_factura') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_detalle_factura
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_detalle_factura AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Detalle_factura (
        detalle_factura_nroFactura,
        detalle_factura_precio,
        detalle_factura_cantidad,
        detalle_factura_subtotal
    )
    -- Seleccionar detalles de factura únicos de la tabla Maestra
    SELECT DISTINCT
        m.Factura_Numero,
        m.Detalle_Factura_Precio,
        m.Detalle_Factura_Cantidad,
        m.Detalle_Factura_Subtotal
    FROM gd_esquema.Maestra m
    WHERE m.Factura_Numero IS NOT NULL
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_envio') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_envio
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_envio AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Envio (
        envio_nroFactura,
        envio_fecha_programada,
        envio_fecha,
        envio_importeTraslado,
        envio_importeSubida,
        envio_total
    )
    -- Seleccionar envíos únicos de la tabla Maestra
    SELECT DISTINCT
        m.Factura_Numero,
        m.Envio_Fecha_Programada,
        m.Envio_Fecha,
        m.Envio_ImporteTraslado,
        m.Envio_ImporteSubida,
        m.Envio_Total
    FROM gd_esquema.Maestra m
    WHERE m.Factura_Numero IS NOT NULL
      AND (m.Envio_Fecha_Programada IS NOT NULL OR m.Envio_Fecha IS NOT NULL OR m.Envio_ImporteTraslado IS NOT NULL OR m.Envio_ImporteSubida IS NOT NULL OR m.Envio_Total IS NOT NULL)
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_sillon_modelo') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_sillon_modelo
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_sillon_modelo AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Sillon_modelo (
        sillon_modelo_codigo,
        sillon_modelo_descripcion,
        sillon_modelo,
        sillon_modelo_precio_base
    )
    -- Seleccionar modelos de sillón únicos de la tabla Maestra, agrupando por código y descripción
    SELECT 
        m.Sillon_Modelo_Codigo,
        MIN(m.Sillon_Modelo_Descripcion),
        MIN(m.Sillon_Modelo),
        MIN(m.Sillon_Modelo_Precio)
    FROM gd_esquema.Maestra m
    WHERE m.Sillon_Modelo_Codigo IS NOT NULL
    group by 
        m.Sillon_Modelo_Codigo,
        m.Sillon_Modelo_Descripcion,
        m.Sillon_Modelo,
        m.Sillon_Modelo_Precio
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_sillon_medida') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_sillon_medida
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_sillon_medida AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Sillon_medida (
        sillon_medida_alto,
        sillon_medida_ancho,
        sillon_medida_profundidad,
        sillon_medida_precio
    )
    -- Seleccionar medidas de sillón únicas de la tabla Maestra, agrupando por alto, ancho, profundidad y precio
    SELECT 
        m.Sillon_Medida_Alto,
        m.Sillon_Medida_Ancho,
        m.Sillon_Medida_Profundidad,
        m.Sillon_Medida_Precio
    FROM gd_esquema.Maestra m
    WHERE m.Sillon_Medida_Alto IS NOT NULL
      AND m.Sillon_Medida_Ancho IS NOT NULL
      AND m.Sillon_Medida_Profundidad IS NOT NULL
      AND m.Sillon_Medida_Precio IS NOT NULL
    group by 
        m.Sillon_Medida_Alto,
        m.Sillon_Medida_Ancho,
        m.Sillon_Medida_Profundidad,
        m.Sillon_Medida_Precio
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_sillon') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_sillon
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_sillon AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Sillon (
        sillon_codigo,
        sillon_modelo_codigo,
        sillon_medida_codigo
    )
    -- Seleccionar sillones únicos de la tabla Maestra, uniendo con la tabla Sillon_medida para obtener el código de medida
    SELECT 
        m.Sillon_Codigo,
        m.Sillon_Modelo_Codigo,
        smd.Sillon_Medida_Codigo
    FROM gd_esquema.Maestra m
    JOIN SILVER_CRIME_RELOADED.Sillon_medida smd ON smd.sillon_medida_alto = m.Sillon_Medida_Alto
        AND smd.sillon_medida_ancho = m.Sillon_Medida_Ancho
        AND smd.sillon_medida_profundidad = m.Sillon_Medida_Profundidad
    WHERE m.Sillon_Modelo_Codigo IS NOT NULL
      AND smd.Sillon_Medida_Codigo IS NOT NULL
    GROUP BY 
        m.Sillon_Codigo,
        m.Sillon_Modelo_Codigo,
        smd.Sillon_Medida_Codigo;
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_detalle_pedido') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_detalle_pedido
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_detalle_pedido AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Detalle_pedido (
        detalle_pedido_sillon_codigo,
        detalle_pedido_idPedido,
        detalle_pedido_cantidad,
        detalle_pedido_precio_unit,
        detalle_pedido_subtotal,
        detalle_pedido_cliente_id,
        detalle_pedido_nro_sucursal
    )
    -- Seleccionar detalles de pedido únicos de la tabla Maestra, uniendo con las tablas Cliente y Sillon para obtener los IDs correspondientes
    SELECT 
        m.Sillon_Codigo,
        m.Pedido_Numero,
        m.Detalle_Pedido_Cantidad,
        m.Detalle_Pedido_Precio,
        m.Detalle_Pedido_Subtotal,
        c.cliente_id,
        m.Sucursal_NroSucursal
    FROM gd_esquema.Maestra m
    JOIN SILVER_CRIME_RELOADED.Cliente c ON c.cliente_dni = m.Cliente_DNI
    JOIN SILVER_CRIME_RELOADED.Sillon s ON s.sillon_codigo = m.Sillon_Codigo
    WHERE m.Sillon_Codigo IS NOT NULL
      AND m.Pedido_Numero IS NOT NULL
      AND c.cliente_id IS NOT NULL
      AND m.Sucursal_NroSucursal IS NOT NULL
    GROUP BY 
        m.Sillon_Codigo,
        m.Pedido_Numero,
        m.Detalle_Pedido_Cantidad,
        m.Detalle_Pedido_Precio,
        m.Detalle_Pedido_Subtotal,
        c.cliente_id,
        m.Sucursal_NroSucursal;
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_tipo_material') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_tipo_material
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_tipo_material AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Tipo_material (
        material_tipo
    )
    -- Seleccionar tipos de material únicos de la tabla Maestra
    SELECT DISTINCT
        m.Material_Tipo
    FROM gd_esquema.Maestra m
    WHERE m.Material_Tipo IS NOT NULL
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_material') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_material
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_material AS
BEGIN    
    -- Crear tabla temporal con columnas extra de la tabla maestra
    IF OBJECT_ID('tempdb..#tmpMaterial') IS NOT NULL DROP TABLE #tmpMaterial;
    -- Crear tabla temporal para almacenar los materiales con sus atributos
    SELECT DISTINCT
        IDENTITY(INT, 1, 1) AS material_id,
        m.Material_Nombre AS material_nombre,
        m.Material_Descripcion AS material_descripcion,
        tm.tipo_ID AS material_tipo_id,
        m.Material_Precio AS material_precio,
        m.Madera_Color,
        m.Madera_Dureza,
        m.Tela_Color,
        m.Tela_Textura,
        m.Relleno_Densidad,
        tm.material_tipo
        INTO #tmpMaterial
        FROM gd_esquema.Maestra m
        JOIN SILVER_CRIME_RELOADED.Tipo_material tm 
        ON tm.material_tipo = m.Material_Tipo
        WHERE m.Material_Nombre IS NOT NULL;

    -- Insertar en tabla Material
    INSERT INTO SILVER_CRIME_RELOADED.Material (
        material_nombre,
        material_descripcion,
        material_tipo_id,
        material_precio
    )
    SELECT
        material_nombre,
        material_descripcion,
        material_tipo_id,
        material_precio
    FROM #tmpMaterial;

    -- Insertar en Material_madera
    INSERT INTO SILVER_CRIME_RELOADED.Material_madera (
        madera_ID,
        material_madera_color,
        material_madera_dureza
    )
    -- Seleccionar materiales de madera únicos de la tabla Maestra, uniendo con las tablas Tipo_material y Material
    SELECT 
        m.material_ID,
        t.Madera_Color,
        t.Madera_Dureza
    FROM SILVER_CRIME_RELOADED.Material m
    JOIN #tmpMaterial t ON t.material_id = m.material_id
    JOIN SILVER_CRIME_RELOADED.Tipo_material tm ON tm.tipo_ID = m.material_tipo_id
    WHERE tm.material_tipo = 'Madera'
      AND t.Madera_Color IS NOT NULL
      AND t.Madera_Dureza IS NOT NULL;

    -- Insertar en Material_tela
    INSERT INTO SILVER_CRIME_RELOADED.Material_tela (
        tela_ID,
        material_tela_color,
        material_tela_textura
    )
    -- Seleccionar materiales de tela únicos de la tabla Maestra, uniendo con las tablas Tipo_material y Material
    SELECT 
        m.material_ID,
        t.Tela_Color,
        t.Tela_Textura
    FROM SILVER_CRIME_RELOADED.Material m
    JOIN #tmpMaterial t ON t.material_id = m.material_id
    JOIN SILVER_CRIME_RELOADED.Tipo_material tm ON tm.tipo_ID = m.material_tipo_id
    WHERE tm.material_tipo = 'Tela'
      AND t.Tela_Color IS NOT NULL
      AND t.Tela_Textura IS NOT NULL;

    -- Insertar en Material_relleno
    INSERT INTO SILVER_CRIME_RELOADED.Material_relleno (
        relleno_ID,
        material_relleno_densidad
    )
    -- Seleccionar materiales de relleno únicos de la tabla Maestra, uniendo con las tablas Tipo_material y Material
    SELECT 
        m.material_ID,
        t.Relleno_Densidad
    FROM SILVER_CRIME_RELOADED.Material m
    JOIN #tmpMaterial t ON t.material_id = m.material_id
    JOIN SILVER_CRIME_RELOADED.Tipo_material tm ON tm.tipo_ID = m.material_tipo_id
    WHERE tm.material_tipo = 'Relleno'
      AND t.Relleno_Densidad IS NOT NULL;
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_material_sillon') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_material_sillon
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_material_sillon AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Material_sillon (
        sillon_material_ID,
        sillon_ID
    )
    -- Seleccionar materiales de sillón únicos de la tabla Maestra, uniendo con las tablas Sillon y Material
    SELECT DISTINCT
        m.material_id,
        s.sillon_codigo
    FROM gd_esquema.Maestra maestra
    JOIN SILVER_CRIME_RELOADED.Sillon s ON s.sillon_codigo = maestra.Sillon_Codigo
    JOIN SILVER_CRIME_RELOADED.Material m ON m.material_nombre = maestra.Material_Nombre
    WHERE maestra.Sillon_Codigo IS NOT NULL
      AND maestra.Material_Nombre IS NOT NULL;
END
GO

IF OBJECT_ID('SILVER_CRIME_RELOADED.migrar_detalle_compra') IS NOT NULL
    DROP PROCEDURE SILVER_CRIME_RELOADED.migrar_detalle_compra
GO
CREATE PROCEDURE SILVER_CRIME_RELOADED.migrar_detalle_compra AS
BEGIN
    INSERT INTO SILVER_CRIME_RELOADED.Detalle_compra (
        detalle_compra_compraID,
        detalle_compra_materialID,
        detalle_compra_precio,
        detalle_compra_cantidad,
        detalle_compra_subtotal
    )
    -- Seleccionar detalles de compra únicos de la tabla Maestra, uniendo con la tabla Material para obtener el ID de material
    SELECT 
        m.Compra_Numero,
        mat.material_id,
        m.Detalle_Compra_Precio,
        m.Detalle_Compra_Cantidad,
        m.Detalle_Compra_Subtotal
    FROM gd_esquema.Maestra m
    JOIN SILVER_CRIME_RELOADED.Material mat ON mat.material_nombre = m.Material_Nombre
    WHERE m.Compra_Numero IS NOT NULL
      AND mat.material_id IS NOT NULL;
END
GO

----------------------------------
EXEC SILVER_CRIME_RELOADED.migrar_provincias;
EXEC SILVER_CRIME_RELOADED.migrar_localidades;
EXEC SILVER_CRIME_RELOADED.migrar_direcciones;
EXEC SILVER_CRIME_RELOADED.migrar_clientes;
EXEC SILVER_CRIME_RELOADED.migrar_estados;
EXEC SILVER_CRIME_RELOADED.migrar_sucursales;
EXEC SILVER_CRIME_RELOADED.migrar_pedidos;
EXEC SILVER_CRIME_RELOADED.migrar_proveedores;
EXEC SILVER_CRIME_RELOADED.migrar_compras;
EXEC SILVER_CRIME_RELOADED.migrar_facturas;
EXEC SILVER_CRIME_RELOADED.migrar_detalle_factura;
EXEC SILVER_CRIME_RELOADED.migrar_envio;
EXEC SILVER_CRIME_RELOADED.migrar_sillon_modelo;
EXEC SILVER_CRIME_RELOADED.migrar_sillon_medida;
EXEC SILVER_CRIME_RELOADED.migrar_sillon;
EXEC SILVER_CRIME_RELOADED.migrar_detalle_pedido;
EXEC SILVER_CRIME_RELOADED.migrar_tipo_material;
EXEC SILVER_CRIME_RELOADED.migrar_material; -- Incluye la insercion a los subtipos
EXEC SILVER_CRIME_RELOADED.migrar_detalle_compra;
EXEC SILVER_CRIME_RELOADED.migrar_material_sillon;