--
-- Name: fac_save_xml(character varying, integer, integer, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, double precision, double precision, double precision, boolean, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fac_save_xml(file_xml character varying, prefact_id integer, usr_id integer, creation_date character varying, no_id_emp character varying, serie character varying, _folio character varying, items_str character varying, traslados_str character varying, retenciones_str character varying, reg_fiscal character varying, pay_method character varying, exp_place character varying, purpose character varying, no_aprob character varying, ano_aprob character varying, rfc_custm character varying, rs_custm character varying, account_number character varying, total_tras double precision, subtotal_with_desc double precision, total double precision, refact boolean, folio_fiscal character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$

    -- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    -- >> Save xml data in DB          >>
    -- >> Version: CDGB                >>
    -- >> Date: 20/Jul/2017            >>
    -- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

DECLARE
    str_filas text[];
    --Total de elementos de arreglo
    total_filas integer;
    --Contador de filas o posiciones del arreglo
    cont_fila integer;

    valor_retorno character varying = '';
    ultimo_id integer:=0;
    ultimo_id_det integer:=0;
    id_tipo_consecutivo integer=0;
    prefijo_consecutivo character varying = '';
    nuevo_consecutivo bigint=0;
    nuevo_folio character varying = '';
    ultimo_id_proceso integer =0;
    tipo_de_documento integer =0;
    fila_fac_rem_doc record;

    app_selected integer;

    emp_id integer:=0;
    suc_id integer:=0;
    suc_id_consecutivo integer:=0; --sucursal de donde se tomara el consecutivo
    id_almacen integer;
    espacio_tiempo_ejecucion timestamp with time zone = now();
    ano_actual integer:=0;
    mes_actual integer:=0;
    factura_fila record;
    prefactura_fila record;
    prefactura_detalle record;
    factura_detalle record;
    tiene_pagos integer:=0;
    identificador_nuevo_movimiento integer;
    tipo_movimiento_id integer:=0;
    exis integer:=0;
    sql_insert text;
    sql_update text;
    sql_select text;
    sql_select2 character varying:='';
    cantidad_porcentaje double precision:=0;
    id_proceso integer;
    bandera_tipo_4 boolean;--bandera que identifica si el producto es tipo 4, true=tipo 4, false=No es tipo4
    serie_folio_fac character varying:='';
    tipo_cam double precision := 0;

    numero_dias_credito integer:=0;
    fecha_de_vencimiento timestamp with time zone;

    importe_del_descto_partida double precision := 0;
    importe_partida_con_descto double precision := 0;
    suma_descuento double precision := 0;
    suma_subtotal_con_descuento double precision := 0;

    importe_partida double precision := 0;
    importe_ieps_partida double precision := 0;
    impuesto_partida double precision := 0;
    monto_subtotal double precision := 0;
    suma_ieps double precision := 0;
    suma_total double precision := 0;
    monto_impuesto double precision := 0;
    total_retencion double precision := 0;
    retener_iva boolean := false;
    tasa_retencion double precision := 0;
    retencion_partida double precision := 0;
    suma_retencion_de_partidas double precision := 0;
    suma_retencion_de_partidas_globlal double precision:= 0;

    --Estas variables se utilizan en caso de que se facture un pedido en otra moneda
    suma_descuento_global double precision := 0;
    suma_subtotal_con_descuento_global double precision := 0;
    monto_subtotal_global double precision := 0;
    suma_ieps_global double precision := 0;
    monto_impuesto_global double precision := 0;
    total_retencion_global double precision := 0;
    suma_total_global double precision := 0;
    cant_original double precision := 0;

    total_factura double precision;
    id_moneda_factura integer:=0;
    suma_pagos double precision:=0;

    costo_promedio_actual double precision:=0;
    costo_referencia_actual double precision:=0;

    id_osal integer := 0;
    fila record;
    fila_detalle record;
    facpar record;--parametros de Facturacion

    id_df integer:=0;--id de la direccion fiscal
    result character varying:='';

    noDecUnidad integer:=0;--numero de decimales permitidos para la unidad
    exisActualPres double precision:=0;--existencia actual de la presentacion
    equivalenciaPres double precision:=0; --equivalencia de la presentacion en la unidad del producto
    cantPres double precision:=0; --Cantidad que se esta Intentando traspasar
    cantPresAsignado double precision:=0;
    cantPresReservAnterior double precision:=0;

    controlExisPres boolean; --Variable que indica  si se debe controlar Existencias por Presentacion
    partida_facturada boolean;--Variable que indica si la cantidad de la partida ya fue facturada en su totalidad
    actualizar_proceso boolean; --Indica si hay que actualizar el flujo del proceso. El proceso se debe actualizar cuando ya no quede partidas vivas
    id_pedido integer;--Id del Pedido que se esta facturando
    --Id de la unidad de medida del producto
    idUnidadMedida integer:=0;
    --Nombre de la unidad de medida del producto
    nombreUnidadMedida character varying:=0;
    --Densidad del producto
    densidadProd double precision:=0;
    --Cantidad en la unidad del producto
    cantUnidadProd double precision:=0;
    --Id de la unidad de Medida de la Venta
    idUnidadMedidaVenta integer:=0;
    --Cantidad en la unidad de Venta, esto se utiliza cuando la unidad del producto es diferente a la de venta
    cantUnidadVenta double precision:=0;
    --Cantidad de la existencia convertida a la unidad de venta, esto se utiliza cuando la unidad del producto es diferente a la de venta
    cantExisUnidadVenta double precision:=0;
    match_cadena boolean:=false;

BEGIN

    app_selected := 13;
	
    SELECT EXTRACT(YEAR FROM espacio_tiempo_ejecucion) INTO ano_actual;
    SELECT EXTRACT(MONTH FROM espacio_tiempo_ejecucion) INTO mes_actual;
	
    --obtener id de empresa, sucursal
    SELECT gral_suc.empresa_id, gral_usr_suc.gral_suc_id
    FROM gral_usr_suc 
    JOIN gral_suc ON gral_suc.id = gral_usr_suc.gral_suc_id
    WHERE gral_usr_suc.gral_usr_id = usr_id
    INTO emp_id, suc_id;
	
    --Obtener parametros para la facturacion
    SELECT * FROM fac_par WHERE gral_suc_id=suc_id INTO facpar;
	
    --tomar el id del almacen para ventas
    id_almacen := facpar.inv_alm_id;
	
    --éste consecutivo es para el folio de Remisión y folio para BackOrder(poc_ped_bo)
    suc_id_consecutivo := facpar.gral_suc_id_consecutivo;

	--query para verificar si la Empresa actual incluye Modulo de Produccion y control de Existencias por Presentacion
    SELECT control_exis_pres FROM gral_emp WHERE id=emp_id INTO controlExisPres;
	
    --Inicializar en cero
    id_pedido:=0;
			
    tipo_de_documento := 1; --Factura
			
    serie_folio_fac:= serie||_folio;
			
    --extraer datos de la Prefactura
    SELECT * FROM erp_prefacturas WHERE id=prefact_id INTO prefactura_fila;
			
    --Obtener el numero de dias de credito
    SELECT dias FROM cxc_clie_credias WHERE id=prefactura_fila.terminos_id INTO numero_dias_credito;
			
    --calcula la fecha de vencimiento a partir de la fecha de la factura
    SELECT (to_char(espacio_tiempo_ejecucion,'yyyy-mm-dd')::DATE + numero_dias_credito)::timestamp with time zone AS fecha_vencimiento INTO fecha_de_vencimiento;
			
    IF prefactura_fila.moneda_id=1 THEN 
        tipo_cam:=1;
    ELSE
        tipo_cam:=prefactura_fila.tipo_cambio;
    END IF;
			
    --Toma la fecha de la Facturación. Ésta fecha es la misma que se le asigno al xml
    espacio_tiempo_ejecucion := translate(creation_date,'T',' ')::timestamp with time zone;
			
    --crea registro en fac_cfds
    INSERT INTO fac_cfds(
        rfc_cliente,--rfc_custm,
        serie,--serie,
        folio_del_comprobante_fiscal,--folio,
        numero_de_aprobacion,--no_aprob,
        monto_de_la_operacion,--total,
        monto_del_impuesto,--total_tras,
        estado_del_comprobante,--'1',
        nombre_archivo,--file_xml,
        momento_expedicion,--creation_date,
        razon_social,--rs_custm,
        tipo_comprobante,--'I',
        proposito,--purpose,
        anoaprovacion, --ano_aprob,
        serie_folio, --serie_folio_fac,
        conceptos, --items_str,
        impuestos_trasladados, --traslados_str,
        impuestos_retenidos, --retenciones_str,
        regimen_fiscal, --reg_fiscal,
        metodo_pago, --pay_method,
        numero_cuenta, --account_number,
        lugar_expedicion,--exp_place,
        tipo_de_cambio,--tipo_cam,
        gral_mon_id,--prefactura_fila.moneda_id,
        id_user_crea,-- usr_id
        empresa_id,--emp_id,
        sucursal_id,--suc_id,
        proceso_id--prefactura_fila.proceso_id
    ) VALUES(rfc_custm, serie, _folio, no_aprob, total, total_tras, '1', file_xml, creation_date, rs_custm, 'I', purpose, ano_aprob, serie_folio_fac, items_str, traslados_str, retenciones_str, reg_fiscal, pay_method, account_number, exp_place, tipo_cam, prefactura_fila.moneda_id, usr_id, emp_id, suc_id, prefactura_fila.proceso_id);


    --crea registro en erp_h_facturas
    INSERT INTO erp_h_facturas(
        cliente_id,--prefactura_fila.cliente_id,
        cxc_agen_id,--prefactura_fila.empleado_id,
        serie_folio,--serie_folio_fac,
        monto_total,--prefactura_fila.fac_total,
        saldo_factura,--prefactura_fila.fac_total,
        moneda_id,--prefactura_fila.moneda_id,
        tipo_cambio,--tipo_cam,
        momento_facturacion,--espacio_tiempo_ejecucion,
        fecha_vencimiento,--fecha_de_vencimiento,
        subtotal,--prefactura_fila.fac_subtotal,
        monto_ieps, --prefactura_fila.fac_monto_ieps,
        impuesto,--prefactura_fila.fac_impuesto,
        retencion,--prefactura_fila.fac_monto_retencion,
        orden_compra,--prefactura_fila.orden_compra,
        id_usuario_creacion, --usr_id,
        empresa_id, --emp_id,
        sucursal_id--suc_id
    )VALUES(prefactura_fila.cliente_id, prefactura_fila.empleado_id, serie_folio_fac, total, total, prefactura_fila.moneda_id, tipo_cam, espacio_tiempo_ejecucion, fecha_de_vencimiento, prefactura_fila.fac_subtotal, prefactura_fila.fac_monto_ieps, prefactura_fila.fac_impuesto, prefactura_fila.fac_monto_retencion, prefactura_fila.orden_compra, usr_id, emp_id, suc_id);

    --Crea registros en la tabla fac_docs
    INSERT INTO fac_docs(
        serie_folio,--serie_folio_fac,
        folio_pedido,--prefactura_fila.folio_pedido,
        cxc_clie_id,--prefactura_fila.cliente_id,
        moneda_id,--prefactura_fila.moneda_id,
        subtotal,--prefactura_fila.fac_subtotal,
        monto_ieps,--prefactura_fila.fac_monto_ieps,
        impuesto,--prefactura_fila.fac_impuesto,
        monto_retencion,--prefactura_fila.fac_monto_retencion,
        total,--prefactura_fila.fac_total,
        tasa_retencion_immex,--prefactura_fila.tasa_retencion_immex,
        tipo_cambio,--tipo_cam,
        proceso_id,--prefactura_fila.proceso_id,
        cxc_agen_id,--prefactura_fila.empleado_id,
        terminos_id,--prefactura_fila.terminos_id,
        fecha_vencimiento,--fecha_de_vencimiento
        orden_compra,--prefactura_fila.orden_compra,
        observaciones, --prefactura_fila.observaciones,
        fac_metodos_pago_id, --prefactura_fila.fac_metodos_pago_id,
        no_cuenta, --prefactura_fila.no_cuenta,
        enviar_ruta,--prefactura_fila.enviar_ruta,
        inv_alm_id,--prefactura_fila.inv_alm_id
        cxc_clie_df_id,--prefactura_fila.cxc_clie_df_id,
        momento_creacion,--translate(creation_date,'T',' ')::timestamp with time zone,,
        gral_usr_id_creacion, --usr_id,
        ref_id, --no_id_emp 
        monto_descto, --prefactura_fila.fac_monto_descto
        motivo_descto, --prefactura_fila.motivo_descto,
        subtotal_sin_descto, --subtotal_with_desc 
        ctb_tmov_id --prefactura_fila.ctb_tmov_id 
    ) VALUES (serie_folio_fac, prefactura_fila.folio_pedido, prefactura_fila.cliente_id, prefactura_fila.moneda_id, prefactura_fila.fac_subtotal, prefactura_fila.fac_monto_ieps, prefactura_fila.fac_impuesto, prefactura_fila.fac_monto_retencion, prefactura_fila.fac_total, prefactura_fila.tasa_retencion_immex, tipo_cam, prefactura_fila.proceso_id, prefactura_fila.empleado_id, prefactura_fila.terminos_id, fecha_de_vencimiento, prefactura_fila.orden_compra, prefactura_fila.observaciones, prefactura_fila.fac_metodos_pago_id, prefactura_fila.no_cuenta, prefactura_fila.enviar_ruta, prefactura_fila.inv_alm_id, prefactura_fila.cxc_clie_df_id, translate(creation_date,'T',' ')::timestamp with time zone, usr_id, no_id_emp, prefactura_fila.fac_monto_descto, prefactura_fila.motivo_descto, subtotal_with_desc, prefactura_fila.ctb_tmov_id) RETURNING id INTO ultimo_id;


    --Guarda la cadena del xml timbrado
    INSERT INTO fac_cfdis(tipo, ref_id, doc, gral_emp_id, gral_suc_id, fecha_crea, gral_usr_id_crea) 
    VALUES (1,no_id_emp,folio_fiscal,emp_id,suc_id,translate(creation_date,'T',' ')::timestamp with time zone, usr_id);


    -- bandera que identifica si el producto es tipo 4
    -- si es tipo 4 no debe existir movimientos en inventario
    bandera_tipo_4=TRUE;
    tipo_movimiento_id:=5;--Salida por Venta
    id_tipo_consecutivo:=21; --Folio Orden de Salida
    id_almacen := prefactura_fila.inv_alm_id;--almacen de donde se hara la salida

    -- Bandera que indica si se debe actualizar el flujo del proceso.
    -- El proceso solo debe actualizarse cuando no quede ni una sola partida viva
    actualizar_proceso:=true;

    -- refact=false:No es refacturacion
    -- tipo_documento=1:Factura
    IF refact IS NOT true AND prefactura_fila.tipo_documento=1 THEN
        -- aqui entra para tomar el consecutivo del folio  la sucursal actual
        UPDATE gral_cons SET consecutivo=( SELECT sbt.consecutivo + 1  FROM gral_cons AS sbt WHERE sbt.id=gral_cons.id )
        WHERE gral_emp_id=emp_id AND gral_suc_id=suc_id AND gral_cons_tipo_id=id_tipo_consecutivo  RETURNING prefijo,consecutivo INTO prefijo_consecutivo,nuevo_consecutivo;

        -- concatenamos el prefijo y el nuevo consecutivo para obtener el nuevo folio 
        nuevo_folio := prefijo_consecutivo || nuevo_consecutivo::character varying;
				
        -- genera registro en tabla inv_osal(Orden de Salida)
        INSERT INTO inv_osal(folio,estatus,erp_proceso_id,inv_mov_tipo_id,tipo_documento,folio_documento,fecha_exp,gral_app_id,cxc_clie_id,inv_alm_id,subtotal,monto_iva,monto_retencion,monto_total,folio_pedido,orden_compra,moneda_id,tipo_cambio,momento_creacion,gral_usr_id_creacion, gral_emp_id, gral_suc_id, monto_ieps)
        VALUES(nuevo_folio,0,prefactura_fila.proceso_id,tipo_movimiento_id,tipo_de_documento,serie_folio_fac,espacio_tiempo_ejecucion,app_selected,prefactura_fila.cliente_id,id_almacen, prefactura_fila.fac_subtotal, prefactura_fila.fac_impuesto, prefactura_fila.fac_monto_retencion, prefactura_fila.fac_total, prefactura_fila.folio_pedido,prefactura_fila.orden_compra,prefactura_fila.moneda_id,tipo_cam,espacio_tiempo_ejecucion,usr_id, emp_id, suc_id, prefactura_fila.fac_monto_ieps) RETURNING id INTO id_osal;
				
        -- genera registro del movimiento
        INSERT INTO inv_mov(observacion,momento_creacion,gral_usr_id, gral_app_id,inv_mov_tipo_id, referencia, fecha_mov )
        VALUES (prefactura_fila.observaciones,espacio_tiempo_ejecucion,usr_id,app_selected, tipo_movimiento_id, serie_folio_fac, translate(creation_date,'T',' ')::timestamp with time zone) RETURNING id INTO identificador_nuevo_movimiento;

    END IF;

    -- obtiene lista de productos de la prefactura
    sql_select:='';
    sql_select := 'SELECT  erp_prefacturas_detalles.id AS id_det,
        erp_prefacturas_detalles.producto_id,
        erp_prefacturas_detalles.presentacion_id,
        erp_prefacturas_detalles.cantidad AS cant_pedido,
        erp_prefacturas_detalles.cant_facturado,
        erp_prefacturas_detalles.cant_facturar AS cantidad,
        erp_prefacturas_detalles.tipo_impuesto_id,
        erp_prefacturas_detalles.valor_imp,
        erp_prefacturas_detalles.precio_unitario,
        inv_prod.tipo_de_producto_id as tipo_producto,
        erp_prefacturas_detalles.costo_promedio,
        erp_prefacturas_detalles.costo_referencia, 
        erp_prefacturas_detalles.reservado,
        erp_prefacturas_detalles.reservado AS nuevo_reservado,
        (CASE WHEN inv_prod_presentaciones.id IS NULL THEN 0 ELSE inv_prod_presentaciones.cantidad END) AS cant_equiv,
        (CASE WHEN inv_prod_unidades.id IS NULL THEN 0 ELSE inv_prod_unidades.decimales END) AS no_dec,
        inv_prod.unidad_id AS id_uni_prod,
        inv_prod.densidad AS densidad_prod,
        inv_prod_unidades.titulo AS nombre_unidad,
        erp_prefacturas_detalles.inv_prod_unidad_id,
        erp_prefacturas_detalles.gral_ieps_id,
        erp_prefacturas_detalles.valor_ieps,
        (CASE WHEN erp_prefacturas_detalles.descto IS NULL THEN 0 ELSE erp_prefacturas_detalles.descto END) AS descto,
        (CASE WHEN erp_prefacturas_detalles.fac_rem_det_id IS NULL THEN 0 ELSE erp_prefacturas_detalles.fac_rem_det_id END) AS fac_rem_det_id,
        erp_prefacturas_detalles.gral_imptos_ret_id,
        erp_prefacturas_detalles.tasa_ret  
        FROM erp_prefacturas_detalles 
        JOIN inv_prod ON inv_prod.id=erp_prefacturas_detalles.producto_id
        LEFT JOIN inv_prod_unidades ON inv_prod_unidades.id=inv_prod.unidad_id
        LEFT JOIN inv_prod_presentaciones ON inv_prod_presentaciones.id=erp_prefacturas_detalles.presentacion_id 
        WHERE erp_prefacturas_detalles.cant_facturar>0 
        AND erp_prefacturas_detalles.prefacturas_id='||prefact_id||';';

    FOR prefactura_detalle IN EXECUTE(sql_select) LOOP
        -- Inicializar valores
        cantPresReservAnterior:=0;
        cantPresAsignado:=0;
        partida_facturada:=false;

        -- tipo_documento 3=Factura de remision
        IF prefactura_fila.tipo_documento::integer = 3 THEN 
            -- toma el costo promedio que viene de la prefactura
            costo_promedio_actual := prefactura_detalle.costo_promedio;
            costo_referencia_actual := prefactura_detalle.costo_referencia;
        ELSE
            -- Obtener costo promedio actual del producto. El costo promedio es en MN.
            SELECT * FROM inv_obtiene_costo_promedio_actual(prefactura_detalle.producto_id, espacio_tiempo_ejecucion) INTO costo_promedio_actual;

            -- Obtener el costo ultimo actual del producto. Este costo es convertido a pesos
            sql_select2 := 'SELECT (CASE WHEN gral_mon_id_'||mes_actual||'=1 THEN costo_ultimo_'||mes_actual||'  ELSE costo_ultimo_'||mes_actual||' * (CASE WHEN gral_mon_id_'||mes_actual||'=1 THEN 1 ELSE tipo_cambio_'||mes_actual||' END) END) AS costo_ultimo FROM inv_prod_cost_prom WHERE inv_prod_id='||prefactura_detalle.producto_id||' AND ano='||ano_actual||';';
            EXECUTE sql_select2 INTO costo_referencia_actual;
        END IF;
				
        -- Verificar que no tenga valor null
        IF costo_promedio_actual IS NULL OR costo_promedio_actual<=0 THEN costo_promedio_actual:=0; END IF;
        IF costo_referencia_actual IS NULL OR costo_referencia_actual<=0 THEN costo_referencia_actual:=0; END IF;

        cantUnidadProd:=0;
        idUnidadMedida:=prefactura_detalle.id_uni_prod;
        densidadProd:=prefactura_detalle.densidad_prod;
        nombreUnidadMedida:=prefactura_detalle.nombre_unidad;

        IF densidadProd IS NULL OR densidadProd=0 THEN densidadProd:=1; END IF;

        cantUnidadProd := prefactura_detalle.cantidad::double precision;

        IF facpar.cambiar_unidad_medida THEN
            IF idUnidadMedida::integer<>prefactura_detalle.inv_prod_unidad_id THEN
                EXECUTE 'select '''||nombreUnidadMedida||''' ~* ''KILO*'';' INTO match_cadena;

                IF match_cadena=true THEN
                    -- Convertir a kilos
                    cantUnidadProd := cantUnidadProd::double precision * densidadProd;
                ELSE
                    EXECUTE 'select '''||nombreUnidadMedida||''' ~* ''LITRO*'';' INTO match_cadena;
                    IF match_cadena=true THEN 
                        -- Convertir a Litros
                        cantUnidadProd := cantUnidadProd::double precision / densidadProd;
                    END IF;
                END IF;

            END IF;
        END IF;

        -- Redondear cantidades
        prefactura_detalle.cant_pedido := round(prefactura_detalle.cant_pedido::numeric,prefactura_detalle.no_dec)::double precision;
        prefactura_detalle.cant_facturado := round(prefactura_detalle.cant_facturado::numeric,prefactura_detalle.no_dec)::double precision;
        prefactura_detalle.cantidad := round(prefactura_detalle.cantidad::numeric,prefactura_detalle.no_dec)::double precision;
        prefactura_detalle.reservado := round(prefactura_detalle.reservado::numeric,prefactura_detalle.no_dec)::double precision;
        prefactura_detalle.nuevo_reservado := round(prefactura_detalle.nuevo_reservado::numeric,prefactura_detalle.no_dec)::double precision;

        IF (cantUnidadProd::double precision <= prefactura_detalle.reservado::double precision) THEN
            -- Asignar la cantidad para descontar de reservado
            prefactura_detalle.reservado := cantUnidadProd::double precision;
        END IF;

        -- Calcular la nueva cantidad reservada
        prefactura_detalle.nuevo_reservado := prefactura_detalle.nuevo_reservado::double precision - prefactura_detalle.reservado::double precision;

        -- Redondaer la nueva cantidad reservada
        prefactura_detalle.nuevo_reservado := round(prefactura_detalle.nuevo_reservado::numeric,prefactura_detalle.no_dec)::double precision;

        -- crea registro en fac_docs_detalles
        INSERT INTO fac_docs_detalles(fac_doc_id,inv_prod_id,inv_prod_presentacion_id,gral_imptos_id,valor_imp,cantidad,precio_unitario,costo_promedio, costo_referencia, inv_prod_unidad_id, gral_ieps_id, valor_ieps, descto, gral_imptos_ret_id, tasa_ret) 
        VALUES (ultimo_id,prefactura_detalle.producto_id,prefactura_detalle.presentacion_id,prefactura_detalle.tipo_impuesto_id,prefactura_detalle.valor_imp,prefactura_detalle.cantidad,prefactura_detalle.precio_unitario, costo_promedio_actual, costo_referencia_actual, prefactura_detalle.inv_prod_unidad_id, prefactura_detalle.gral_ieps_id, prefactura_detalle.valor_ieps, prefactura_detalle.descto, prefactura_detalle.gral_imptos_ret_id, prefactura_detalle.tasa_ret) RETURNING id INTO ultimo_id_det;

        IF refact IS NOT true  AND prefactura_fila.tipo_documento::integer=1 THEN
            -- Si el tipo de producto es diferente de 4 el hay que descontar existencias y generar Movimientos
            -- tipo=4 Servicios
            -- para el tipo servicios NO debe generar movimientos NI descontar existencias
            IF prefactura_detalle.tipo_producto::integer<>4 THEN

                bandera_tipo_4=FALSE; -- indica que por lo menos un producto es diferente de tipo4, por lo tanto debe generarse movimientos

                -- tipo=1 Normal o Terminado
                -- tipo=2 Subensable o Formulacion o Intermedio
                -- tipo=5 Refacciones
                -- tipo=6 Accesorios
                -- tipo=7 Materia Prima
                -- tipo=8 Prod. en Desarrollo

                -- tipo=3 Kit
                -- tipo=4 Servicios
                -- IF prefactura_detalle.tipo_producto=1 OR prefactura_detalle.tipo_producto=2 OR prefactura_detalle.tipo_producto=5 OR prefactura_detalle.tipo_producto=6 OR prefactura_detalle.tipo_producto=7 OR prefactura_detalle.tipo_producto=8 THEN
                IF prefactura_detalle.tipo_producto::integer<>3 AND  prefactura_detalle.tipo_producto::integer<>4 THEN
                    -- Genera registro en detalles del movimiento
                    INSERT INTO inv_mov_detalle(producto_id, alm_origen_id, alm_destino_id, cantidad, inv_mov_id, costo, inv_prod_presentacion_id)
                    VALUES (prefactura_detalle.producto_id, id_almacen,0, cantUnidadProd, identificador_nuevo_movimiento, costo_promedio_actual, prefactura_detalle.presentacion_id);

                    -- Query para descontar producto de existencias y descontar existencia reservada porque ya se Facturó
                    sql_update := 'UPDATE inv_exi SET salidas_'||mes_actual||'=(salidas_'||mes_actual||'::double precision + '||cantUnidadProd||'::double precision), 
                        reservado=(reservado::double precision - '||prefactura_detalle.reservado||'::double precision), momento_salida_'||mes_actual||'='''||espacio_tiempo_ejecucion||'''
                        WHERE inv_alm_id='||id_almacen||'::integer AND inv_prod_id='||prefactura_detalle.producto_id||'::integer AND ano='||ano_actual||'::integer;';
                        EXECUTE sql_update;

                    IF FOUND THEN
	                -- RAISE EXCEPTION '%','FOUND'||FOUND;
                    ELSE
                        RAISE EXCEPTION '%','NOT FOUND:'||FOUND||'  No se pudo actualizar inv_exi';
                    END IF;

                    -- Crear registro en orden salida detalle
                    -- La cantidad se almacena en la unidad de venta
                    INSERT INTO inv_osal_detalle(inv_osal_id,inv_prod_id,inv_prod_presentacion_id,cantidad,precio_unitario, inv_prod_unidad_id, gral_ieps_id, valor_ieps)
                    VALUES (id_osal,prefactura_detalle.producto_id,prefactura_detalle.presentacion_id,prefactura_detalle.cantidad,prefactura_detalle.precio_unitario, prefactura_detalle.inv_prod_unidad_id, prefactura_detalle.gral_ieps_id, prefactura_detalle.valor_ieps);

                    -- Verificar si se está llevando el control de existencias por Presentaciones
                    IF controlExisPres=true THEN 
                        -- Si la configuracion indica que se validan Presentaciones desde el Pedido,entonces significa que hay reservados, por lo tanto hay que descontarlos
                        IF facpar.validar_pres_pedido=true THEN 
                            -- Convertir la cantidad reservada a su equivalente en presentaciones
                            cantPresReservAnterior := prefactura_detalle.reservado::double precision / prefactura_detalle.cant_equiv::double precision;

                            -- redondear la Cantidad de la Presentacion reservada Anteriormente
                            cantPresReservAnterior := round(cantPresReservAnterior::numeric,prefactura_detalle.no_dec)::double precision; 
                        END IF;

                        -- Convertir la cantidad de la partida a su equivalente a presentaciones
                        cantPresAsignado := cantUnidadProd::double precision / prefactura_detalle.cant_equiv::double precision;

                        -- Redondear la cantidad de Presentaciones asignado en la partida
                        cantPresAsignado := round(cantPresAsignado::numeric,prefactura_detalle.no_dec)::double precision;

                        -- Sumar salidas de inv_exi_pres
                        UPDATE inv_exi_pres SET 
                            salidas=(salidas::double precision + cantPresAsignado::double precision), reservado=(reservado::double precision - cantPresReservAnterior::double precision), 
                            momento_actualizacion=translate(creation_date,'T',' ')::timestamp with time zone, gral_usr_id_actualizacion=usr_id 
                        WHERE inv_alm_id=id_almacen AND inv_prod_id=prefactura_detalle.producto_id AND inv_prod_presentacion_id=prefactura_detalle.presentacion_id;
                        -- Termina sumar salidas
                    END IF;


                    -- :::::: Aqui inica calculos para el control de facturacion por partida  ::::::

                    -- Calcular la cantidad facturada
                    prefactura_detalle.cant_facturado:=prefactura_detalle.cant_facturado::double precision + prefactura_detalle.cantidad::double precision;

                    -- Redondear la cantidad facturada
                    prefactura_detalle.cant_facturado := round(prefactura_detalle.cant_facturado::numeric,prefactura_detalle.no_dec)::double precision;

                    IF prefactura_detalle.cant_pedido <= prefactura_detalle.cant_facturado THEN 
                        partida_facturada:=true;
                    ELSE
                        -- Si entro aqui quiere decir que por lo menos una partida esta quedando pendiente de facturar por completo.
                        actualizar_proceso:=false;
                    END IF;

                    -- Actualizar el registro de la partida
                    UPDATE erp_prefacturas_detalles SET cant_facturado=prefactura_detalle.cant_facturado, facturado=partida_facturada, cant_facturar=0, reservado=prefactura_detalle.nuevo_reservado 
                    WHERE id=prefactura_detalle.id_det;

                    -- Obtener el id del pedido que se esta facturando
                    SELECT id FROM poc_pedidos WHERE _folio=prefactura_fila.folio_pedido ORDER BY id DESC LIMIT 1 INTO id_pedido;

                    IF id_pedido IS NULL THEN id_pedido:=0; END IF;

                    IF id_pedido<>0 THEN 
                        -- Actualizar el registro detalle del Pedido
                        UPDATE poc_pedidos_detalle SET reservado=prefactura_detalle.nuevo_reservado 
                        WHERE poc_pedido_id=id_pedido AND inv_prod_id=prefactura_detalle.producto_id AND presentacion_id=prefactura_detalle.presentacion_id;
                    END IF;

                END IF; -- termina tipo producto 1, 2, 7

            ELSE
                IF prefactura_detalle.tipo_producto::integer=4 THEN
                    -- :::::::::: Aqui inica calculos para el control de facturacion por partida ::::::::

                    -- Calcular la cantidad facturada
                    prefactura_detalle.cant_facturado:=prefactura_detalle.cant_facturado::double precision + prefactura_detalle.cantidad::double precision;

                    -- Redondear la cantidad facturada
                    prefactura_detalle.cant_facturado := round(prefactura_detalle.cant_facturado::numeric,prefactura_detalle.no_dec)::double precision;

                    IF prefactura_detalle.cant_pedido <= prefactura_detalle.cant_facturado THEN 
                        partida_facturada:=true;
                    END IF;

                    -- Actualizar el registro de la partida
                    UPDATE erp_prefacturas_detalles SET 
                        cant_facturado=prefactura_detalle.cant_facturado, 
                        facturado=partida_facturada, 
                        cant_facturar=0 
                    WHERE id=prefactura_detalle.id_det;

                END IF;
            END IF;
            -- Termina verificacion diferente de tipo 4

        ELSE
            -- tipo_documento 3=Factura de remision
            IF prefactura_fila.tipo_documento::integer = 3 THEN 
                -- :::::::: Aqui inica calculos para el control de facturacion por partida ::::::::
                -- Calcular la cantidad facturada
                prefactura_detalle.cant_facturado:=prefactura_detalle.cant_facturado::double precision + prefactura_detalle.cantidad::double precision;

                -- Redondear la cantidad facturada
                prefactura_detalle.cant_facturado := round(prefactura_detalle.cant_facturado::numeric,prefactura_detalle.no_dec)::double precision;

                IF prefactura_detalle.cant_pedido <= prefactura_detalle.cant_facturado THEN 
                    partida_facturada:=true;
                ELSE
                    -- Si entro aqui quiere decir que por lo menos una partida esta quedando pendiente de facturar por completo.
                    actualizar_proceso:=false;
                END IF;

                -- Actualizar el registro de la partida
                UPDATE erp_prefacturas_detalles SET cant_facturado=prefactura_detalle.cant_facturado, facturado=partida_facturada, cant_facturar=0, reservado=0 
                WHERE id=prefactura_detalle.id_det;

                -- Crear registros para relacionar las partidas de la Remision con las partidas de las facturas.
                INSERT INTO fac_rem_doc_det(fac_doc_id, fac_doc_det_id,fac_rem_det_id)
                VALUES(ultimo_id, ultimo_id_det, prefactura_detalle.fac_rem_det_id);

            END IF;
        END IF; 
        -- termina if que verifica si es refacturacion

    END LOOP;
			
    -- si bandera tipo 4=true, significa el producto que se esta facturando son servicios;
    -- por lo tanto hay que eliminar el movimiento de inventario
    IF bandera_tipo_4=TRUE THEN
        -- refact=false:No es refacturacion
        -- tipo_documento=1:Factura
        IF refact IS NOT true AND prefactura_fila.tipo_documento=1 THEN
            DELETE FROM inv_mov WHERE id=identificador_nuevo_movimiento;
        END IF;
    END IF;

    IF (SELECT count(prefact_det.id) FROM erp_prefacturas_detalles AS prefact_det JOIN inv_prod ON inv_prod.id=prefact_det.producto_id WHERE prefact_det.prefacturas_id=prefact_id AND inv_prod.tipo_de_producto_id<>4 AND prefact_det.facturado=false )>=1 THEN
        actualizar_proceso:=false;
    END IF;
			
    -- Verificar si hay que actualizar el flujo del proceso
    IF actualizar_proceso THEN
        -- Actualiza el flujo del proceso a 3=Facturado
        UPDATE erp_proceso SET proceso_flujo_id=3 WHERE id=prefactura_fila.proceso_id;
    ELSE
        -- Actualiza el flujo del proceso a 7=FACTURA PARCIAL
        UPDATE erp_proceso SET proceso_flujo_id=7 WHERE id=prefactura_fila.proceso_id;
    END IF;


    -- tipo_documento 3=Factura de remision
    IF prefactura_fila.tipo_documento=3 THEN
        -- buscar numero de remision que se incluyeron en esta factura
        sql_select:='SELECT DISTINCT fac_rem_id FROM fac_rems_docs WHERE erp_proceso_id = '||prefactura_fila.proceso_id;

        FOR fila_fac_rem_doc IN EXECUTE(sql_select) LOOP
            IF (SELECT count(fac_rems_docs.id) as exis FROM fac_rems_docs JOIN erp_prefacturas ON erp_prefacturas.proceso_id = fac_rems_docs.erp_proceso_id JOIN erp_prefacturas_detalles ON erp_prefacturas_detalles.prefacturas_id = erp_prefacturas.id WHERE (erp_prefacturas_detalles.cantidad::double precision - erp_prefacturas_detalles.cant_facturado::double precision)>0 AND fac_rems_docs.fac_rem_id = fila_fac_rem_doc.fac_rem_id)<=0 THEN

                -- Asignar facturado a cada remision
                UPDATE fac_rems SET facturado=TRUE WHERE id=fila_fac_rem_doc.fac_rem_id;
            END IF;

        END LOOP;

    END IF;
			
    -- Una vez terminado el Proceso se asignan ceros a estos campos
    UPDATE erp_prefacturas SET fac_subtotal=0, fac_impuesto=0, fac_monto_retencion=0, fac_total=0, fac_monto_ieps=0, fac_monto_descto=0 
    WHERE id=prefact_id;
			
    -- Actualiza el consecutivo del folio de la factura en la tabla fac_cfds_conf_folios. La actualización es por Empresa-sucursal
    UPDATE fac_cfds_conf_folios SET folio_actual=(folio_actual+1) WHERE id=(SELECT fac_cfds_conf_folios.id FROM fac_cfds_conf JOIN fac_cfds_conf_folios ON fac_cfds_conf_folios.fac_cfds_conf_id=fac_cfds_conf.id WHERE fac_cfds_conf_folios.proposito='FAC' AND fac_cfds_conf.empresa_id=emp_id AND fac_cfds_conf.gral_suc_id=suc_id);
			
    valor_retorno := '1:'||ultimo_id;--retorna el id de fac_docs
	
    RETURN valor_retorno; 

END;$$;


--
-- Name: fac_val_cancel(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fac_val_cancel(_fac_id integer) RETURNS record
    LANGUAGE plpgsql
    AS $$
DECLARE
    -- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    -- >> Factura Cancel Validation >>
    -- >> Version: CDGB             >>
    -- >> Date: 9/Dic/2018          >>
    -- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    rv record;

    -- dump of errors
    rmsg character varying;

    serie_folio_fac character varying;
    tiene_pagos integer;

BEGIN

    SELECT serie_folio FROM fac_docs
    WHERE id = _fac_id
    INTO serie_folio_fac;

    SELECT count(serie_folio)
    FROM erp_pagos_detalles
    WHERE cancelacion = FALSE
    AND serie_folio = serie_folio_fac
    INTO tiene_pagos;

    IF tiene_pagos = 0 THEN
        SELECT count(serie_folio_factura) FROM fac_nota_credito
        WHERE serie_folio != ''
        AND cancelado = FALSE
        AND serie_folio_factura = serie_folio_fac
        INTO tiene_pagos;

        IF tiene_pagos > 0 THEN
            rmsg := 'La factura '||serie_folio_fac||', tiene notas de credito aplicadas';
        END IF;
    ELSE
        rmsg := 'La factura '||serie_folio_fac||', tiene pagos aplicados';
    END IF;

    IF rmsg != '' THEN
        rv := ( -1::integer, rmsg::text );
    ELSE
        rv := ( 0::integer, ''::text );
    END IF;

    RETURN rv;

END;
$$;


--
-- Name: fac_exec_cancel(integer, integer, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fac_exec_cancel(_usr_id integer, _fact_id integer, _reason text, _mode integer) RETURNS record
    LANGUAGE plpgsql
    AS $$
DECLARE
    -- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    -- >> Factura Cancel Execution  >>
    -- >> Version: CDGB             >>
    -- >> Date: 9/Dic/2018          >>
    -- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    rv record;

    -- dump of errors
    rmsg character varying := '';

    espacio_tiempo_ejecucion timestamp with time zone = now();

    ano_actual integer := 0;
    mes_actual integer := 0;

    emp_id integer := 0;
    suc_id integer := 0;
    almacen_id integer := 0;
    last_prefact_id integer := 0;

    tipo_movimiento_id integer := 0;
    identificador_nuevo_movimiento integer := 0;
    identificador_nueva_odev integer;

    prefijo_consecutivo character varying;
    nuevo_consecutivo bigint;
    nuevo_folio character varying;

    --Densidad del producto
    densidadProd double precision := 0;

    cantPresAsignado double precision := 0;
    exis integer := 0;

    -- Bandera que identifica si el producto es tipo 4
    -- Si es tipo 4 no debe existir movimientos en inventario
    conjunto_servicios boolean := TRUE;

    -- Variable que indica  si se debe controlar Existencias por Presentacion
    controlExisPres boolean;

    match_cadena boolean := FALSE;

    -- Pivot variable to be used with queries
    q_pivot text;

    -- Parametros de Facturacion
    facpar record;

    factura_detalle record;
    factura_fila record;
    lote_detalle record;
    osal_fila record;

BEGIN

    SELECT EXTRACT(YEAR FROM espacio_tiempo_ejecucion) INTO ano_actual;
    SELECT EXTRACT(MONTH FROM espacio_tiempo_ejecucion) INTO mes_actual;

    -- Obtener id de empresa, sucursal
    SELECT gral_suc.empresa_id, gral_usr_suc.gral_suc_id
    FROM gral_usr_suc
    JOIN gral_suc ON gral_suc.id = gral_usr_suc.gral_suc_id
    WHERE gral_usr_suc.gral_usr_id = _usr_id
    INTO emp_id, suc_id;

    -- Obtener parametros para la facturacion
    SELECT * FROM fac_par WHERE gral_suc_id = suc_id INTO facpar;

    -- Consulta para verificar si la Empresa utiliza control de Existencias por Presentacion
    SELECT control_exis_pres FROM gral_emp WHERE id = emp_id INTO controlExisPres;

    -- Obtiene todos los datos de la factura
    SELECT fac_docs.*
    FROM fac_docs
    WHERE fac_docs.id = _fact_id LIMIT 1
    INTO factura_fila;

    -- Cancela registro en fac_docs
    UPDATE fac_docs SET cancelado = TRUE,
    fac_docs_tipo_cancelacion_id = _mode,
    motivo_cancelacion= _reason,
    ctb_tmov_id_cancelacion = 0, -- Always Zero hardcode (It was just a poor try for a contable approach)
    momento_cancelacion = espacio_tiempo_ejecucion,
    gral_usr_id_cancelacion = _usr_id
    WHERE id = factura_fila.id RETURNING inv_alm_id INTO almacen_id;

    UPDATE fac_cfdis SET cancelado = TRUE,
    fecha_cancela = espacio_tiempo_ejecucion,
    gral_usr_id_cancela = _usr_id
	WHERE ref_id = factura_fila.ref_id AND gral_emp_id = emp_id;

    -- Cambia estado del comprobante a 0
    UPDATE fac_cfds SET estado_del_comprobante = '0',
    fac_docs_tipo_cancelacion_id = _mode,
    momento_cancelacion = espacio_tiempo_ejecucion,
    motivo_cancelacion = _reason,
    id_user_cancela = _usr_id
    WHERE fac_cfds.proceso_id = factura_fila.proceso_id AND
    fac_cfds.serie_folio = factura_fila.serie_folio;

    -- Cancela registro en h_facturas
    UPDATE erp_h_facturas SET cancelacion = TRUE,
    fac_docs_tipo_cancelacion_id = _mode,
    momento_cancelacion = espacio_tiempo_ejecucion,
    id_usuario_cancelacion = _usr_id
    WHERE serie_folio ILIKE factura_fila.serie_folio;

    IF _mode = 1 THEN

        -- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
        -- INICIA DEVOLUCIONES A EL INVENTARIO
        -- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

        -- Obtiene lista de productos de la factura
        q_pivot =' SELECT fac_docs_detalles.inv_prod_id,
            (fac_docs_detalles.cantidad::double precision - cantidad_devolucion::double precision) AS cantidad,
            inv_prod.tipo_de_producto_id as tipo_producto,
            fac_docs_detalles.inv_prod_presentacion_id AS presentacion_id,
            (CASE WHEN inv_prod_presentaciones.id IS NULL THEN 0 ELSE inv_prod_presentaciones.cantidad END) AS cant_equiv,
            (CASE WHEN inv_prod_unidades.id IS NULL THEN 0 ELSE inv_prod_unidades.decimales END) AS no_dec,
            inv_prod.unidad_id AS id_uni_prod,
            inv_prod.densidad AS densidad_prod,
            inv_prod_unidades.titulo AS nombre_unidad,
            fac_docs_detalles.inv_prod_unidad_id
            FROM fac_docs_detalles
            JOIN inv_prod ON inv_prod.id=fac_docs_detalles.inv_prod_id
            LEFT JOIN inv_prod_unidades ON inv_prod_unidades.id=inv_prod.unidad_id
            LEFT JOIN inv_prod_presentaciones ON inv_prod_presentaciones.id=fac_docs_detalles.inv_prod_presentacion_id
            WHERE fac_docs_detalles.fac_doc_id = ' || _fact_id;


        -- Genera registro para el movimiento de cancelacion
        INSERT INTO inv_mov(
            observacion,
            momento_creacion,
            gral_usr_id,
            gral_app_id,
            inv_mov_tipo_id,
            referencia,
            fecha_mov
        )
        VALUES(
            _reason,
            espacio_tiempo_ejecucion,
            _usr_id,
            36,                        -- Hardcode (app id for cancel)
            2,                         -- Devolucion por cancelacion
            factura_fila.serie_folio,
            espacio_tiempo_ejecucion
        ) RETURNING id INTO identificador_nuevo_movimiento;

        FOR factura_detalle IN EXECUTE( q_pivot ) LOOP

            IF facpar.cambiar_unidad_medida THEN

                IF factura_detalle.id_uni_prod::integer <> factura_detalle.inv_prod_unidad_id THEN

                    densidadProd := factura_detalle.densidad_prod;

                    IF densidadProd IS NULL OR densidadProd = 0 THEN
                        densidadProd := 1;
                    END IF;

                    EXECUTE 'select ''' || factura_detalle.nombre_unidad || ''' ~* ''KILO*'';' INTO match_cadena;

                    IF match_cadena = true THEN

                        -- Convertir a kilos
                        factura_detalle.cantidad := factura_detalle.cantidad::double precision * densidadProd;

                    ELSE

                        EXECUTE 'select ''' || factura_detalle.nombre_unidad || ''' ~* ''LITRO*'';' INTO match_cadena;

                        IF match_cadena = true THEN
                            -- Convertir a Litros
                            factura_detalle.cantidad := factura_detalle.cantidad::double precision / densidadProd;
                        END IF;

                    END IF;
                END IF;

            END IF;

            -- Si el tipo de producto es diferente de 4, hay que devolver existencias y generar Movimientos
            -- tipo = 4 " Servicios: para el tipo servicios debe generar movimientos ni devolver existencias "
            IF factura_detalle.tipo_producto <> 4 THEN

                -- Indica que por lo menos un producto es diferente de tipo 4, por lo tanto deberan generarse movimientos
                conjunto_servicios = FALSE;

                IF  factura_detalle.tipo_producto = 1 OR    -- Normal o Terminado
                    factura_detalle.tipo_producto = 2 OR    -- Subensable o Formulacion o Intermedio
                    factura_detalle.tipo_producto = 5 OR    -- Refacciones
                    factura_detalle.tipo_producto = 6 OR    -- Accesorios
                    factura_detalle.tipo_producto = 7 OR    -- Materia Prima
                    factura_detalle.tipo_producto = 8 THEN  -- Prod. en Desarrollo

                    --Redondear la cantidad
                    factura_detalle.cantidad := round( factura_detalle.cantidad::numeric,factura_detalle.no_dec )::double precision;

                    -- Genera registro en detalles del movimiento
                    INSERT INTO inv_mov_detalle(
                        producto_id,
                        alm_origen_id,
                        alm_destino_id,
                        cantidad,
                        inv_mov_id,
                        inv_prod_presentacion_id
                    )
                    VALUES(
                        factura_detalle.inv_prod_id,
                        0,
                        almacen_id,
                        factura_detalle.cantidad,
                        identificador_nuevo_movimiento,
                        factura_detalle.presentacion_id
                    );

                    -- Consulta para verificar existencia del producto en almacen (sobre el año en curso)
                    q_pivot := ' SELECT count(id) FROM inv_exi
                        WHERE inv_prod_id = ' || factura_detalle.inv_prod_id ||
                        ' AND inv_alm_id = ' || almacen_id ||
                        ' AND ano = ' || ano_actual || ';' ;
                    EXECUTE q_pivot INTO exis;

                    IF exis > 0 THEN
                        q_pivot := 'UPDATE inv_exi SET entradas_'||mes_actual||'=(entradas_'||mes_actual||' + '||factura_detalle.cantidad||'::double precision),momento_entrada_'||mes_actual||'='''||espacio_tiempo_ejecucion||'''
                            WHERE inv_alm_id='|| almacen_id ||' AND inv_prod_id='||factura_detalle.inv_prod_id||' AND ano='||ano_actual||';';
                        EXECUTE q_pivot;
                    ELSE
                        q_pivot := 'INSERT INTO inv_exi (inv_prod_id,inv_alm_id, ano, entradas_'||mes_actual||',momento_entrada_'||mes_actual||',exi_inicial) '||
                            'VALUES('||factura_detalle.inv_prod_id||','|| almacen_id ||','||ano_actual||','||factura_detalle.cantidad||','''|| espacio_tiempo_ejecucion ||''',0)';
                        EXECUTE q_pivot;
                    END IF;

                    -- Verificar si se está llevando el control de existencias por Presentaciones
                    IF controlExisPres = TRUE THEN

                        -- Convertir la cantidad de la partida a su equivalente a presentaciones
                        cantPresAsignado := factura_detalle.cantidad::double precision / factura_detalle.cant_equiv::double precision;

                        -- Redondear la cantidad de Presentaciones asignado en la partida
                        cantPresAsignado := round( cantPresAsignado::numeric,factura_detalle.no_dec )::double precision;

                        -- Consulta para verificar existencia del producto en el almacen y en el año actual
                        q_pivot := 'SELECT count(id) FROM inv_exi_pres WHERE inv_prod_id='||factura_detalle.inv_prod_id||' AND inv_alm_id='|| almacen_id ||' AND inv_prod_presentacion_id = '||factura_detalle.presentacion_id||';';
                        EXECUTE q_pivot INTO exis;

                        -- Sumar entradas de inv_exi_pres
                        IF exis > 0 THEN
                            UPDATE inv_exi_pres SET entradas=(entradas::double precision + cantPresAsignado::double precision),
                            momento_actualizacion=espacio_tiempo_ejecucion, gral_usr_id_actualizacion = _usr_id
                            WHERE inv_alm_id = almacen_id
                            AND inv_prod_id = factura_detalle.inv_prod_id
                            AND inv_prod_presentacion_id = factura_detalle.presentacion_id;
                        ELSE
                            INSERT INTO inv_exi_pres(
                                inv_alm_id,
                                inv_prod_id,
                                inv_prod_presentacion_id,
                                inicial,
                                momento_creacion,
                                gral_usr_id_creacion,
                                entradas
                            )
                            VALUES(
                                almacen_id,
                                factura_detalle.inv_prod_id,
                                factura_detalle.presentacion_id,
                                0,
                                espacio_tiempo_ejecucion,
                                _usr_id,
                                cantPresAsignado::double precision
                            );
                        END IF;

                    END IF;

                END IF;

            END IF;

        END LOOP;

        IF conjunto_servicios = TRUE THEN
            --la factura es de un producto tipo 4, por lo tanto se elimina el movimiento generado anteriormente
            DELETE FROM inv_mov WHERE id = identificador_nuevo_movimiento;
        END IF;

        -- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
        -- TERMINA DEVOLUCIONES A EL INVENTARIO
        -- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


        -- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
        -- INICIA CANCELACION DE ORDEN DE SALIDA
        -- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

        -- Obtener datos de la orden de salida que genero esta factura
        SELECT * FROM inv_osal
        WHERE inv_osal.folio_documento = factura_fila.serie_folio
        AND inv_osal.cxc_clie_id = factura_fila.cxc_clie_id
        AND inv_osal.tipo_documento = 1
        INTO osal_fila;

        UPDATE inv_osal SET cancelacion = true,
        momento_cancelacion = espacio_tiempo_ejecucion,
        motivo_cancelacion = _reason,
        gral_usr_id_actualizacion = _usr_id
        WHERE id = osal_fila.id;

        -- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
        -- TERMINA CANCELACION DE ORDEN DE SALIDA
        -- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

        -- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
        -- INICIA GENERACION DE ORDEN DE DEVOLUCION
        -- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

        -- Estatus 0 = No se ha tocado por el personal de Almacen,
        -- Estatus 1 = Ya se ha ingresado cantidades, lotes, pedimentos y fechas de caducidad pero aun no se ha descontado del lote
        -- Estatus 2 = Confirmado( ya se le dio salida )

        -- Solo se puede generar orden de devolucion cuando el estatus es mayor a Uno
        IF osal_fila.estatus::integer >= 1 THEN

            -- Aqui entra para tomar el consecutivo del folio  la sucursal actual
            UPDATE gral_cons SET consecutivo=( SELECT sbt.consecutivo + 1  FROM gral_cons AS sbt WHERE sbt.id=gral_cons.id )
            WHERE gral_emp_id = emp_id
            AND gral_suc_id = suc_id
            AND gral_cons_tipo_id = 26  -- Folio Orden de Devolucion
            RETURNING prefijo, consecutivo INTO prefijo_consecutivo, nuevo_consecutivo;

            -- Concatenamos el prefijo y el nuevo consecutivo para obtener el nuevo folio
            nuevo_folio := prefijo_consecutivo || nuevo_consecutivo::character varying;

            INSERT INTO inv_odev(
                folio,
                inv_mov_tipo_id,
                tipo_documento,
                folio_documento,
                folio_ncto,
                fecha_exp,
                cxc_clie_id,
                inv_alm_id,
                moneda_id,
                erp_proceso_id,
                momento_creacion,
                gral_usr_id_creacion,
                gral_emp_id,
                gral_suc_id,
                cancelacion
            ) VALUES (
                nuevo_folio,
                tipo_movimiento_id,
                osal_fila.tipo_documento,
                osal_fila.folio_documento,
                '',                        -- Este dato se va vacio porque es cancelacion de factura, esto no genera nota de credito.
                osal_fila.fecha_exp,
                factura_fila.cxc_clie_id,
                osal_fila.inv_alm_id,
                factura_fila.moneda_id,
                factura_fila.proceso_id,
                espacio_tiempo_ejecucion,
                _usr_id,
                emp_id,
                suc_id,
                false
            ) RETURNING id INTO identificador_nueva_odev;


            -- Obtiene los productos de la Orden de Salida
            q_pivot := 'SELECT inv_osal_detalle.id,
                inv_osal_detalle.inv_prod_id,
                inv_osal_detalle.inv_prod_presentacion_id,
                (inv_osal_detalle.cantidad::double precision - cant_dev::double precision) AS cantidad_devolucion
                FROM inv_osal_detalle WHERE inv_osal_detalle.inv_osal_id = ' || osal_fila.id || ';' ;


            FOR factura_detalle IN EXECUTE( q_pivot ) LOOP

                -- Registrar cantidades que se devolvieron a inv_osal_detalle
                UPDATE inv_osal_detalle SET cant_dev=( cant_dev + factura_detalle.cantidad_devolucion::double precision )
                WHERE id = factura_detalle.id;

                -- Obtiene lista de lotes de la Salida
                q_pivot := 'SELECT inv_lote_detalle.inv_lote_id AS id_lote,
                    inv_lote_detalle.inv_osal_detalle_id,
                    inv_lote_detalle.cantidad_sal AS cant_fac,
                    (inv_lote_detalle.cantidad_sal::double precision - cantidad_dev::double precision) AS devolucion,
                    inv_osal_detalle.inv_prod_unidad_id AS id_uni_prod_venta
                    FROM inv_osal_detalle
                    JOIN inv_lote_detalle ON inv_lote_detalle.inv_osal_detalle_id=inv_osal_detalle.id
                    JOIN inv_lote ON inv_lote.id=inv_lote_detalle.inv_lote_id
                    WHERE inv_osal_detalle.id = ' || factura_detalle.id || ' AND inv_lote.inv_prod_id = ' || factura_detalle.inv_prod_id || ';';

                FOR lote_detalle IN EXECUTE( q_pivot ) LOOP

                    lote_detalle.devolucion := factura_detalle.cantidad_devolucion::double precision;

                    -- Crear registro en inv_odev_detalle
                    INSERT INTO inv_odev_detalle(
                        inv_odev_id,
                        inv_osal_detalle_id,
                        inv_lote_id,
                        cant_fac_lote,
                        cant_dev_lote,
                        inv_prod_unidad_id
                    ) VALUES(
                        identificador_nueva_odev,
                        lote_detalle.inv_osal_detalle_id,
                        lote_detalle.id_lote,
                        lote_detalle.cant_fac,
                        lote_detalle.devolucion,
                        lote_detalle.id_uni_prod_venta
                    );

                END LOOP;

            END LOOP;

        END IF;

        -- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
        -- TERMINA GENERACION DE ORDEN DE DEVOLUCION
        -- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

    ELSIF _mode = 2 THEN

        --Aqui entra cuando se refactura
        --actualiza campo refacturacion y regresa el id del proceso 
        UPDATE erp_prefacturas SET refacturar = TRUE
        WHERE proceso_id = factura_fila.proceso_id
        RETURNING id INTO last_prefact_id;

        --obtiene lista de productos de la factura
        q_pivot := 'SELECT  fac_docs_detalles.inv_prod_id,
            fac_docs_detalles.inv_prod_presentacion_id AS presentacion_id,
            fac_docs_detalles.cantidad,
            0::double precision AS nueva_cant_fac,
            inv_prod.tipo_de_producto_id AS tipo_producto,
            (CASE WHEN inv_prod_presentaciones.id IS NULL THEN 0 ELSE inv_prod_presentaciones.cantidad END) AS cant_equiv,
            (CASE WHEN inv_prod_unidades.id IS NULL THEN 0 ELSE inv_prod_unidades.decimales END) AS no_dec 
            FROM fac_docs_detalles
            JOIN inv_prod ON inv_prod.id=fac_docs_detalles.inv_prod_id
            LEFT JOIN inv_prod_unidades ON inv_prod_unidades.id=inv_prod.unidad_id
            LEFT JOIN inv_prod_presentaciones ON inv_prod_presentaciones.id=fac_docs_detalles.inv_prod_presentacion_id 
            WHERE fac_docs_detalles.fac_doc_id=' || _fact_id;

        FOR factura_detalle IN EXECUTE(q_pivot) LOOP

            -- Si el tipo de producto es diferente de 4, hay que devolver la cantidad a la prefactura
            -- tipo = 4 " Servicios
            IF factura_detalle.tipo_producto <> 4 THEN
                IF  factura_detalle.tipo_producto = 1 OR    -- Normal o Terminado
                    factura_detalle.tipo_producto = 2 OR    -- Subensable o Formulacion o Intermedio
                    factura_detalle.tipo_producto = 5 OR    -- Refacciones
                    factura_detalle.tipo_producto = 6 OR    -- Accesorios
                    factura_detalle.tipo_producto = 7 OR    -- Materia Prima
                    factura_detalle.tipo_producto = 8 THEN  -- Prod. en Desarrollo

                    --Actualizar partida de Prefacturas detalles
                    UPDATE erp_prefacturas_detalles
                    SET cant_facturado = factura_detalle.nueva_cant_fac, facturado = FALSE
                    WHERE prefacturas_id = last_prefact_id
                    AND producto_id = factura_detalle.inv_prod_id
                    AND presentacion_id = factura_detalle.presentacion_id;

                END IF;
            END IF;

        END LOOP;

        UPDATE erp_proceso SET proceso_flujo_id = 2 WHERE id=factura_fila.proceso_id;

    ELSE
        RAISE EXCEPTION '%', 'Tipo de cancelacion no soportada';
    END IF;

    IF rmsg != '' THEN
        rv := ( -1::integer, rmsg::text );
    ELSE
        rv := ( 0::integer, ''::text );
    END IF;

    RETURN rv;

END;
$$;



--
-- Name: ncr_exec_cancel(integer, integer, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ncr_exec_cancel(_usr_id integer, _ncr_id integer, _reason text, _mode integer) RETURNS record
    LANGUAGE plpgsql
    AS $$

DECLARE

    rv record;

    -- dump of errors
    rmsg character varying;

    ncr_row record;

    total_factura double precision;
    suma_pagos double precision;
    suma_notas_credito double precision;
    id_moneda_factura integer;

    emp_id integer;
    suc_id integer;
    nuevacantidad_monto_pago double precision := 0;
    nuevo_saldo_factura double precision := 0;
    espacio_tiempo_ejecucion timestamp with time zone = now();

BEGIN

    -- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    -- >> Nota credito Cancel Execution  >>
    -- >> Version: CDGB                  >>
    -- >> Date: 21/Dic/2018              >>
    -- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    -- obtener id de empresa, sucursal
    SELECT gral_suc.empresa_id, gral_usr_suc.gral_suc_id
    FROM gral_usr_suc 
    JOIN gral_suc ON gral_suc.id = gral_usr_suc.gral_suc_id
    WHERE gral_usr_suc.gral_usr_id = _usr_id
    INTO emp_id, suc_id;

    UPDATE fac_nota_credito
    SET cancelado = true,
        motivo_cancelacion = _reason,
        ctb_tmov_id_cancelacion = 0, -- Always Zero hardcode (It was just a poor try for a contable approach)
        momento_cancelacion = espacio_tiempo_ejecucion,
        gral_usr_id_cancelacion = _usr_id 
    WHERE id = _ncr_id;

    SELECT * FROM fac_nota_credito
    WHERE id = _ncr_id
    INTO ncr_row;
    
    UPDATE fac_cfdis
    SET cancelado = TRUE,
        fecha_cancela = espacio_tiempo_ejecucion,
        gral_usr_id_cancela = _usr_id 
    WHERE ref_id = ncr_row.ref_id
    AND gral_emp_id = emp_id;

    -- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    -- INICIA ACTUALIZACION erp_h_facturas
    -- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

    SELECT monto_total, moneda_id
    FROM erp_h_facturas
    WHERE serie_folio = ncr_row.serie_folio_factura
    INTO total_factura, id_moneda_factura;

    -- sacar suma total de pagos para esta factura
    SELECT CASE WHEN sum IS NULL THEN 0 ELSE sum END
    FROM ( SELECT sum(cantidad)
           FROM erp_pagos_detalles
           WHERE serie_folio = ncr_row.serie_folio_factura
           AND cancelacion = FALSE ) AS sbt
    INTO suma_pagos;
			
    -- sacar suma total de notas de credito para esta factura
    -- cuando la moneda de la factura es USD hay que convertir todas las Notas de Credito a Dolar
    IF id_moneda_factura = 2 THEN

        SELECT CASE WHEN sum IS NULL THEN 0 ELSE sum END
        FROM (
            SELECT sum(total_nota) FROM (
                SELECT round(( (CASE WHEN moneda_id=1 THEN total/tipo_cambio ELSE total END))::numeric,2)::double precision AS total_nota
                FROM fac_nota_credito
                WHERE serie_folio != ''
                AND serie_folio_factura = ncr_row.serie_folio_factura
                AND cancelado = FALSE
            ) AS sbt 
        ) AS subtabla
        INTO suma_notas_credito;

    ELSE

        -- cuando la Factura es en pesos NO HAY necesidad de convertir,
        -- porque a las facturas en USD no se le aplica notas de credito
        -- de Otra MONEDA, solo pesos
        SELECT CASE WHEN sum IS NULL THEN 0 ELSE sum END
        FROM (
            SELECT sum(total)
            FROM fac_nota_credito
            WHERE serie_folio_factura = ncr_row.serie_folio_factura
            AND cancelado = FALSE ) AS subtabla
        INTO suma_notas_credito;

    END IF;
			
    nuevacantidad_monto_pago := round((suma_pagos)::numeric,4)::double precision;

    nuevo_saldo_factura := round((total_factura - suma_pagos - suma_notas_credito)::numeric,2)::double precision;
			
    -- actualiza cantidades cada vez que se realice un pago
    UPDATE erp_h_facturas
    SET total_pagos = nuevacantidad_monto_pago,
        total_notas_creditos = suma_notas_credito,
        saldo_factura = nuevo_saldo_factura,
        pagado = false,
        momento_actualizacion = espacio_tiempo_ejecucion 
    WHERE serie_folio = ncr_row.serie_folio_factura;

    -- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    -- TERMINA ACTUALIZACION erp_h_facturas
    -- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

    IF rmsg != '' THEN
        rv := ( -1::integer, rmsg::text );
    ELSE
        rv := ( 0::integer, ''::text );
    END IF;

    RETURN rv;


END;
$$;

