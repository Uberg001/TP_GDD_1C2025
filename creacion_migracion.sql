
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

CREATE TABLE SILVER_CRIME_RELOADED.Detalle_pedido (
    detalle_pedido_sillon_codigo BIGINT IDENTITY(1,1) NOT NULL,
    detalle_pedido_idPedido DECIMAL(18,0) NOT NULL,
    detalle_pedido_cantidad BIGINT,
    detalle_pedido_precio_unit DECIMAL(18,2),
    detalle_pedido_subtotal DECIMAL(18,2),
    detalle_pedido_cliente_id BIGINT NOT NULL,
    detalle_pedido_nro_sucursal BIGINT NOT NULL
);

CREATE TABLE SILVER_CRIME_RELOADED.Sillon (
    sillon_codigo BIGINT IDENTITY(1,1) NOT NULL,
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
    INSERT INTO SILVER_CRIME_RELOADED.Provincia (provincia_nombre)
    SELECT DISTINCT P.provincia_nombre
    FROM (
        SELECT DISTINCT Sucursal_Provincia as provincia_nombre FROM gd_esquema.Maestra
        WHERE Sucursal_Provincia IS NOT NULL
        UNION
        SELECT DISTINCT Cliente_Provincia as provincia_nombre FROM gd_esquema.Maestra
        WHERE Cliente_Provincia IS NOT NULL
        UNION
        SELECT DISTINCT Proveedor_Provincia as provincia_nombre FROM gd_esquema.Maestra
        WHERE Proveedor_Provincia IS NOT NULL
    ) P
    WHERE P.provincia_nombre IS NOT NULL;
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
    SELECT DISTINCT Pedido_Estado as estado_descripcion FROM gd_esquema.Maestra 
    WHERE Pedido_Estado IS NOT NULL
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
    SELECT 
        m.Sillon_Modelo_Codigo,
        m.Sillon_Modelo_Descripcion,
        m.Sillon_Modelo,
        m.Sillon_Modelo_Precio
    FROM gd_esquema.Maestra m
    WHERE m.Sillon_Modelo_Codigo IS NOT NULL -- hay nulls en la tabla original...
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
    SELECT 
        m.Sillon_Medida_Alto,
        m.Sillon_Medida_Ancho,
        m.Sillon_Medida_Profundidad,
        m.Sillon_Medida_Precio
    FROM gd_esquema.Maestra m
    WHERE m.Sillon_Medida_Alto IS NOT NULL --nulls en la tabla original....
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
        sillon_modelo_codigo,
        sillon_medida_codigo
    )
    SELECT 
        m.Sillon_Modelo_Codigo,
        smd.Sillon_Medida_Codigo
    FROM gd_esquema.Maestra m
    JOIN SILVER_CRIME_RELOADED.Sillon_medida smd ON smd.sillon_medida_alto = m.Sillon_Medida_Alto
        AND smd.sillon_medida_ancho = m.Sillon_Medida_Ancho
        AND smd.sillon_medida_profundidad = m.Sillon_Medida_Profundidad
    WHERE m.Sillon_Modelo_Codigo IS NOT NULL
      AND smd.Sillon_Medida_Codigo IS NOT NULL
    GROUP BY 
        m.Sillon_Modelo_Codigo,
        smd.Sillon_Medida_Codigo;
END
GO

----------------------------------------------
--MIGRACION
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