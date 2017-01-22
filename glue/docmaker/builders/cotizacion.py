from reportlab.platypus import BaseDocTemplate, PageTemplate, Frame, Table, TableStyle, Paragraph, Spacer, Image
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.units import cm 
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.pdfgen import canvas
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT, TA_JUSTIFY

import psycopg2
import psycopg2.extras
from docmaker.error import DocBuilderStepError
import re
import os

__captions = {
    'SPA': {
        'TL_DOC_LANG': 'ESPAÑOL',
        'TL_DOC_NAME': 'COTIZACIÓN',
        'TL_DOC_DATE': 'FECHA EXPEDICION',
        'TL_CUST_NAME': 'CLIENTE',
        'TL_CUST_ADDR': 'DIRECCIÓN',
        'TL_CUST_PHONE': 'TEL',
        'TL_CONTACT': 'CONTACTO',
        'TL_CONTACT_EMAIL': 'EMAIL',
        'TL_ART_NAME': 'DESCRIPCIÓN',
        'TL_ART_CONTAINER': 'PRESENTACIÓN',
        'TL_ART_AMNT': 'PRECIO',
        'TL_BILL_CURR': 'MONEDA',
        'TL_PAY_POLICY': 'POLITICAS DE PAGO'
    },
    'ENG': {
        'TL_DOC_LANG': None,
        'TL_DOC_NAME': None,
        'TL_DOC_DATE': None,
        'TL_CUST_NAME': None,
        'TL_CUST_ADDR': None,
        'TL_CUST_PHONE': None,
        'TL_CONTACT': None,
        'TL_CONTACT_EMAIL': None,
        'TL_ART_NAME': None,
        'TL_ART_CONTAINER': None,
        'TL_ART_AMNT': None,
        'TL_BILL_CURR': None,
        'TL_PAY_POLICY': None
    }
}


class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        canvas.Canvas.__init__(self, *args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        """add page info to each page (page x of y)"""
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_number(num_pages)
            canvas.Canvas.showPage(self)
        canvas.Canvas.save(self)

    def draw_page_number(self, page_count):
        width, height = letter
        self.setFont("Helvetica", 7)
        self.drawCentredString(width / 2.0, 0.65*cm,
            "Pagina %d de %d" % (self._pageNumber, page_count))


def __load_cot_items(conn, cot_id):

    __ITEMS_SQL = """SELECT
        inv_prod.sku as codigo,
        inv_prod.descripcion as producto,
        (CASE WHEN inv_prod.descripcion_larga IS NULL THEN '' ELSE inv_prod.descripcion_larga END) AS descripcion_larga,
        inv_prod_unidades.titulo as unidad,
        inv_prod_presentaciones.titulo as presentacion,
        poc_cot_detalle.cantidad,
        poc_cot_detalle.precio_unitario,
        gral_mon.descripcion_abr AS moneda,
        (poc_cot_detalle.cantidad * poc_cot_detalle.precio_unitario) AS importe
    FROM poc_cot_detalle
    LEFT JOIN inv_prod on inv_prod.id = poc_cot_detalle.inv_prod_id
    LEFT JOIN inv_prod_unidades on inv_prod_unidades.id = poc_cot_detalle.inv_prod_unidad_id
    LEFT JOIN inv_prod_presentaciones on inv_prod_presentaciones.id = poc_cot_detalle.inv_presentacion_id
    LEFT JOIN gral_mon on gral_mon.id = poc_cot_detalle.gral_mon_id
    WHERE poc_cot_detalle.poc_cot_id="""

    cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    try:
        q = "{0}{1} ORDER BY poc_cot_detalle.id".format(__ITEMS_SQL, cot_id)
        cur.execute(q)
        rows = cur.fetchall()
        if len(rows) > 0:
            return rows
        else:
            raise DocBuilderStepError('There is not items data')
    except psycopg2.Error as e:
        raise DocBuilderStepError("an error happen when loading items data")

def __load_cot_data(conn, cot_id, cust=True):

    __NON_CUST_SQL="""SELECT
        poc_cot.dias_vigencia,
        poc_cot.tc_usd,
        poc_cot.subtotal,
        poc_cot.impuesto,
        poc_cot.total,
        (CASE
            WHEN poc_cot.fecha IS NULL THEN to_char(poc_cot.momento_creacion,'yyyy-mm-dd')
            ELSE to_char(poc_cot.fecha::timestamp with time zone,'yyyy-mm-dd') END
        ) as fecha,
        (SELECT
            ARRAY(
                SELECT descripcion FROM poc_cot_politicas_pago
                WHERE gral_emp_id = crm_prospectos.gral_emp_id AND borrado_logico=false ORDER BY id
            ) as politicas
        ),
        (SELECT
            ARRAY(
                SELECT
                (CASE WHEN poc_cot_incoterms.nombre IS NULL THEN '' ELSE poc_cot_incoterms.nombre END)
                ||' - '||
                (CASE WHEN poc_cot_incoterms.descripcion_esp IS NULL THEN '' ELSE poc_cot_incoterms.descripcion_esp END) AS titulo
                FROM poc_cot_incoterms
                LEFT JOIN poc_cot_incoterm_x_cot AS incotermxcot ON (incotermxcot.poc_cot_incoterms_id=poc_cot_incoterms.id AND incotermxcot.poc_cot_id=poc_cot_prospecto.poc_cot_id) 
                WHERE poc_cot_incoterms.borrado_logico=FALSE AND poc_cot_incoterms.gral_emp_id=crm_prospectos.gral_emp_id
            ) as incoterms
        ),
        (SELECT
            ARRAY(
                SELECT descripcion
                FROM poc_cot_condiciones_com
                WHERE gral_emp_id=crm_prospectos.gral_emp_id AND borrado_logico=false ORDER BY id
            ) as condiciones
        ),
        (SELECT descripcion_abr
             FROM gral_mon WHERE gral_mon.id = poc_cot.gral_mon_id limit 1
        ) as moneda,
        crm_prospectos.rfc, 
        crm_prospectos.razon_social, 
        crm_prospectos.contacto, 
        crm_prospectos.calle,
        crm_prospectos.numero,
        crm_prospectos.colonia,
        gral_mun.titulo AS municipio,
        gral_edo.titulo AS estado,
        gral_pais.titulo AS pais,
        crm_prospectos.cp
        FROM poc_cot_prospecto
        JOIN poc_cot ON poc_cot.id = poc_cot_prospecto.poc_cot_id
        JOIN crm_prospectos ON crm_prospectos.id=poc_cot_prospecto.crm_prospecto_id
        JOIN gral_pais ON gral_pais.id = crm_prospectos.pais_id
        JOIN gral_edo ON gral_edo.id = crm_prospectos.estado_id
        JOIN gral_mun ON gral_mun.id = crm_prospectos.municipio_id
        WHERE poc_cot_prospecto.poc_cot_id="""


    __CUST_SQL = """SELECT
        poc_cot.dias_vigencia,
        poc_cot.tc_usd,
        poc_cot.subtotal,
        poc_cot.impuesto,
        poc_cot.total,
        (CASE
            WHEN poc_cot.fecha IS NULL THEN to_char(poc_cot.momento_creacion,'yyyy-mm-dd')
            ELSE to_char(poc_cot.fecha::timestamp with time zone,'yyyy-mm-dd') END
        ) as fecha,
        (SELECT
            ARRAY(
                SELECT descripcion FROM poc_cot_politicas_pago
                WHERE gral_emp_id = cxc_clie.empresa_id AND borrado_logico=false ORDER BY id
            ) as politicas
        ),
        (SELECT
            ARRAY(
                SELECT
                (CASE WHEN poc_cot_incoterms.nombre IS NULL THEN '' ELSE poc_cot_incoterms.nombre END)
                ||' - '||
                (CASE WHEN poc_cot_incoterms.descripcion_esp IS NULL THEN '' ELSE poc_cot_incoterms.descripcion_esp END) AS titulo
                FROM poc_cot_incoterms
                LEFT JOIN poc_cot_incoterm_x_cot AS incotermxcot ON (incotermxcot.poc_cot_incoterms_id=poc_cot_incoterms.id AND incotermxcot.poc_cot_id=poc_cot_clie.poc_cot_id) 
                WHERE poc_cot_incoterms.borrado_logico=FALSE AND poc_cot_incoterms.gral_emp_id=cxc_clie.empresa_id
            ) as incoterms
        ),
        (SELECT
            ARRAY(
                SELECT descripcion
                FROM poc_cot_condiciones_com
                WHERE gral_emp_id=cxc_clie.empresa_id AND borrado_logico=false ORDER BY id
            ) as condiciones
        ),
        (SELECT descripcion_abr
             FROM gral_mon WHERE gral_mon.id = poc_cot.gral_mon_id limit 1
        ) as moneda,
        cxc_clie.rfc,
        cxc_clie.razon_social,
        cxc_clie.contacto,
        cxc_clie.calle,
        cxc_clie.numero,
        cxc_clie.colonia,
        gral_mun.titulo AS municipio,
        gral_edo.titulo AS estado,
        gral_pais.titulo AS pais,
        cxc_clie.cp
    FROM poc_cot_clie
    JOIN cxc_clie ON cxc_clie.id=poc_cot_clie.cxc_clie_id
    JOIN poc_cot ON poc_cot.id = poc_cot_clie.poc_cot_id
    JOIN gral_pais ON gral_pais.id = cxc_clie.pais_id
    JOIN gral_edo ON gral_edo.id = cxc_clie.estado_id
    JOIN gral_mun ON gral_mun.id = cxc_clie.municipio_id
    WHERE poc_cot_clie.poc_cot_id="""

    cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    try:
        q = "{0}{1}".format(
            __CUST_SQL if cust else __NON_CUST_SQL,
            cot_id
        )
        cur.execute(q)
        rows = cur.fetchall()
        if len(rows) > 0:
            return rows
        else:
            raise DocBuilderStepError('There is not document data')
    except psycopg2.Error as e:
        raise DocBuilderStepError("an error happen when loading document data")


def __format_cot_data(rows, cap):

    rd = {}
    for i in rows:
        rd["DAYS"] = i['dias_vigencia']
        rd["TC_USD"] = i['tc_usd']
        rd["SUBTOTAL"]= i['subtotal']
        rd["TAX"]= i['impuesto']
        rd["TOTAL"]= i['total']
        rd["DATE"] = i['fecha']
        rd["POLICIES"] = i['politicas']
        rd["INCOTERMS"] = i['incoterms']
        rd["STATEMENTS"] = i['condiciones']
        rd["CURRENCY"] = i['moneda']
        rd["RFC"] = i['rfc']
        rd["RS"] = i['razon_social']
        rd["CONTACT"] = i['contacto']
        rd["STREET"] = i['calle']
        rd["NUMBER"] = i['numero']
        rd["COLONIA"] = i['colonia']
        rd["TOWN"] = i['municipio']
        rd["STATE"] = i['estado']
        rd["COUNTRY"] = i['pais']
        rd["ZIPC"] = i['cp']
    return rd

def __format_cot_items(rows, cap):

    rd = {}
    for i in rows:
        rd["SKU"] = i['codigo']
        rd["NAME"] = i['producto']
        rd["DESC"] = i['descripcion_larga']
        rd["UNIT"] = i['unidad']
        rd["CONTAINER"] = i['presentacion']
        rd["QUANTITY"] =  i['cantidad']
        rd["UNIT_PRICE"] = i['precio_unitario']
        rd["CURRENCY"] = i['moneda']
        rd["AMOUNT"] = i['importe']
    return rd


def __h_acquisition(logger, conn, res_dirs, **kwargs):
    """
    """
    dat = {
        'CAP_LOADED': None,
        'FOOTER_ABOUT': 'xxx'
    }

    cap = kwargs.get('cap', 'SPA')
    if not cap in __captions:
        raise DocBuilderStepError("caption {0} not found".format(cap))
    dat['CAP_LOADED'] = __captions[cap]

    logo_filename = "{0}/{1}_logo.png".format(
        res_dirs['images'],
        kwargs['rfc']
    )
    if not os.path.isfile(logo_filename):
        raise DocBuilderStepError("logo image {0} not found".format(logo_filename))

    dat['LOGO'] = logo_filename

    try:
        dat['DOC_ITEMS'] = __format_cot_items(
            __load_cot_items(conn, kwargs['folio']), cap
        )
        dat['DOC_DATA'] = __format_cot_data(
            __load_cot_data(conn, kwargs['folio']), cap
        )

    except Exception as e:
        logger.error(e)
        raise DocBuilderStepError("loading document elements fails")

    return dat


def __h_write_format(output_file, logger, dat):
    """
    """

    doc = BaseDocTemplate(
         output_file, pagesize=letter,
         rightMargin=30,leftMargin=30, topMargin=30,bottomMargin=18,
    )

    story = []

    logo = Image(dat['LOGO'])
    logo.drawHeight = 3.8*cm
    logo.drawWidth = 5.2*cm

    story.append(
        __top_table(
            logo,
            __create_emisor_table(dat),
            __create_cotizacion_table(dat)
        )
    )
    story.append(Spacer(1, 0.4 * cm))

    def fp_foot(c, d):
        c.saveState()
        width, height = letter
        c.setFont('Helvetica',7)
        c.drawCentredString(width / 2.0, (1.00*cm), dat['FOOTER_ABOUT'])
        c.restoreState()

    cot_frame = Frame(
        doc.leftMargin, doc.bottomMargin, doc.width, doc.height,
        id='cot_frame'
    )

    doc.addPageTemplates(
        [
            PageTemplate(id='cot_page',frames=[cot_frame],onPage=fp_foot),
        ]
    )
    doc.build(story, canvasmaker=NumberedCanvas)

    return

def __top_table(t0, t1, t3):

    cont = [[t0, t1, t3]]

    table = Table(cont,
        [
            5.5 * cm,
            9.4 * cm,
            5.5 * cm
        ]
    )

    table.setStyle( TableStyle([
        ('ALIGN', (0, 0),(0, 0), 'LEFT'),
        ('ALIGN', (1, 0),(1, 0), 'CENTRE'),
        ('ALIGN', (-1, 0),(-1, 0), 'RIGHT'),
    ]))

    return table

def __create_emisor_table(dat):
    st = ParagraphStyle(
        name='info',
        fontName='Helvetica',
        fontSize=7,
        leading = 9.7
    )

    context = {
        'inceptor': 'KATHION CHEMIE DE MEXICO S. DE R.L.', #hardcode
        'rfc': 'KCM081010I58',  #hardcode
        'phone': '(1081)13340206', #hardcode
        'www': 'www.kathionchemie.com.mx', #hardcode
        'street': 'AV. IGNACIO SEPULVEDA', #hardcode
        'number': '109', #hardcode
        'settlement': 'LA ENCARNACION', #hardcode
        'state': 'NUEVO LEÓN, MEXICO', #hardcode
        'town': 'APODACA', #hardcode
        'cp': '66633', #hardcode
        'fontSize': '7', #hardcode
        'fontName':'Helvetica' #hardcode
    }

    text = Paragraph(
        '''
        <para align=center spaceb=3>
            <font name=%(fontName)s size=10 >
                <b>%(inceptor)s</b>
            </font>
            <br/>
            <font name=%(fontName)s size=%(fontSize)s >
                <b>RFC: %(rfc)s</b>
            </font>
            <br/>
            <font name=%(fontName)s size=%(fontSize)s >
                <b>DOMICILIO FISCAL</b>
            </font>
            <br/>
            %(street)s %(number)s %(settlement)s
            <br/>
            %(town)s, %(state)s C.P. %(cp)s
            <br/>
            TEL./FAX. %(phone)s
            <br/>
            %(www)s
        </para>
        ''' % context, st)

    cont = [[text]]

    table = Table(cont,
        colWidths = [ 9.0 *cm]
    )

    table.setStyle(TableStyle(
        [('VALIGN',(-1,-1),(-1,-1),'TOP')]
    ))

    return table


def __create_cotizacion_table(dat):

    st = ParagraphStyle(
        name='info',
        fontName='Helvetica',
        fontSize=7,
        leading = 8
    )

    cont = []

    cont.append([ dat['CAP_LOADED']['TL_DOC_NAME'] ])
    cont.append(['FOLIO.' ])
    cont.append([ '7' ]) # hardcode

    cont.append([ dat['CAP_LOADED']['TL_DOC_DATE'] ])
    cont.append([ dat['DOC_DATA']['DATE'] ])

    cont.append(['TIPO DE CAMBIO'])
    cont.append([ Paragraph( '19.5965', st ) ])

    cont.append(['NO. CERTIFICADO'])
    cont.append(['nothing'])


    table = Table(cont,
        [
           5  * cm,
        ],
        [
            0.40 * cm,
            0.37* cm,
            0.37 * cm,
            0.38 * cm,
            0.38 * cm,
            0.38 * cm,
            0.70 * cm,
            0.38 * cm,
            0.38 * cm,
        ] # rowHeights
    )

    table.setStyle( TableStyle([

        #Body and header look and feel (common)
        ('BOX', (0, 1), (-1, -1), 0.25, colors.black),
        ('FONT', (0, 0), (0, 0), 'Helvetica-Bold', 10),

        ('TEXTCOLOR', (0, 1),(-1, 1), colors.white),
        ('FONT', (0, 1), (-1, 2), 'Helvetica-Bold', 7),

        ('TEXTCOLOR', (0, 3),(-1, 3), colors.white),
        ('FONT', (0, 3), (-1, 3), 'Helvetica-Bold', 7),
        ('FONT', (0, 4), (-1, 4), 'Helvetica', 7),

        ('TEXTCOLOR', (0, 5),(-1, 5), colors.white),
        ('FONT', (0, 5), (-1, 5), 'Helvetica-Bold', 7),

        ('FONT', (0, 7), (-1, 7), 'Helvetica-Bold', 7),
        ('TEXTCOLOR', (0, 7),(-1, 7), colors.white),
        ('FONT', (0, 8), (-1, 8), 'Helvetica', 7),

        ('ROWBACKGROUNDS', (0, 1),(-1, -1), [colors.black, colors.white]),
        ('ALIGN', (0, 0),(-1, -1), 'CENTER'),
        ('VALIGN', (0, 1),(-1, -1), 'MIDDLE'),
    ]))

    return table



def __h_data_release(logger, dat):
    """
    """
    pass


doc_builder_impt = {
    'DATA_ACQUISITION': __h_acquisition,
    'WRITE_FORMAT': __h_write_format,
    'DATA_RELEASE': __h_data_release
}
