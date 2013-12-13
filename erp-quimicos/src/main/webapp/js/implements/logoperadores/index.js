$(function() {
	String.prototype.toCharCode = function(){
	    var str = this.split(''), len = str.length, work = new Array(len);
	    for (var i = 0; i < len; ++i){
			work[i] = this.charCodeAt(i);
	    }
	    return work.join(',');
	};
	
	$('#header').find('#header1').find('span.emp').text($('#lienzo_recalculable').find('input[name=emp]').val());
	$('#header').find('#header1').find('span.suc').text($('#lienzo_recalculable').find('input[name=suc]').val());
    var $username = $('#header').find('#header1').find('span.username');
	$username.text($('#lienzo_recalculable').find('input[name=user]').val());
	
	var $contextpath = $('#lienzo_recalculable').find('input[name=contextpath]');
	var controller = $contextpath.val()+"/controllers/logoperadores";
    
    //Barra para las acciones
    $('#barra_acciones').append($('#lienzo_recalculable').find('.table_acciones'));
    $('#barra_acciones').find('.table_acciones').css({'display':'block'});
	var $new_logoperadores = $('#barra_acciones').find('.table_acciones').find('a[href*=new_item]');
	var $visualiza_buscador = $('#barra_acciones').find('.table_acciones').find('a[href*=visualiza_buscador]');
	
	$('#barra_acciones').find('.table_acciones').find('#nItem').mouseover(function(){
		$(this).removeClass("onmouseOutNewItem").addClass("onmouseOverNewItem");
	});
	$('#barra_acciones').find('.table_acciones').find('#nItem').mouseout(function(){
		$(this).removeClass("onmouseOverNewItem").addClass("onmouseOutNewItem");
	});
	
	$('#barra_acciones').find('.table_acciones').find('#vbuscador').mouseover(function(){
		$(this).removeClass("onmouseOutVisualizaBuscador").addClass("onmouseOverVisualizaBuscador");
	});
	$('#barra_acciones').find('.table_acciones').find('#vbuscador').mouseout(function(){
		$(this).removeClass("onmouseOverVisualizaBuscador").addClass("onmouseOutVisualizaBuscador");
	});
	
	
	//aqui va el titulo del catalogo
	$('#barra_titulo').find('#td_titulo').append('Cat&aacute;logo de Operadores');
	
	//barra para el buscador 
	$('#barra_buscador').append($('#lienzo_recalculable').find('.tabla_buscador'));
	$('#barra_buscador').find('.tabla_buscador').css({'display':'block'});
    
    
	
	var $cadena_busqueda = "";
	var $busqueda_cve_operador = $('#barra_buscador').find('.tabla_buscador').find('input[name=busqueda_cve_operador]');
	var $busqueda_nombre = $('#barra_buscador').find('.tabla_buscador').find('input[name=busqueda_nombre]');
        
	//var $busca_numeconomico =$('#barra_buscador').find('.tabla_buscador').find('input[name=busqueda_numeconomico]');
	var $buscar = $('#barra_buscador').find('.tabla_buscador').find('input[value$=Buscar]');
	var $limbuscarpiar = $('#barra_buscador').find('.tabla_buscador').find('input[value$=Limpiar]');
	
	
	
	var to_make_one_search_string = function(){
		var valor_retorno = "";
		var signo_separador = "=";
		valor_retorno += "clave_operador" + signo_separador + $busqueda_cve_operador.val() + "|";
		valor_retorno += "nombre" + signo_separador + $busqueda_nombre.val() + "|";
		valor_retorno += "iu" + signo_separador + $('#lienzo_recalculable').find('input[name=iu]').val() + "|";
		return valor_retorno;
	};
	
	cadena = to_make_one_search_string();
	$cadena_busqueda = cadena.toCharCode();
	//$cadena_busqueda = cadena;
	
	$buscar.click(function(event){
		event.preventDefault();
		cadena = to_make_one_search_string();
		$cadena_busqueda = cadena.toCharCode();
		$get_datos_grid();
	});
	
	
	
	$limbuscarpiar.click(function(event){
		event.preventDefault();
                $busqueda_cve_operador.val(' ');
                $busqueda_nombre.val(' ');
	});
	
	
	
	TriggerClickVisializaBuscador = 0;
	//visualizar  la barra del buscador
	$visualiza_buscador.click(function(event){
		event.preventDefault();
		
		var alto=0;
		if(TriggerClickVisializaBuscador==0){
			 TriggerClickVisializaBuscador=1;
			 var height2 = $('#cuerpo').css('height');
			 //alert('height2: '+height2);
			 
			 alto = parseInt(height2)-220;
			 var pix_alto=alto+'px';
			 //alert('pix_alto: '+pix_alto);
			 
			 $('#barra_buscador').find('.tabla_buscador').css({'display':'block'});
			 $('#barra_buscador').animate({height: '60px'}, 500);
			 $('#cuerpo').css({'height': pix_alto});
			 
			 //alert($('#cuerpo').css('height'));
		}else{
			 TriggerClickVisializaBuscador=0;
			 var height2 = $('#cuerpo').css('height');
			 alto = parseInt(height2)+220;
			 var pix_alto=alto+'px';
			 
			 $('#barra_buscador').animate({height:'0px'}, 500);
			 $('#cuerpo').css({'height': pix_alto});
		};
		$busqueda_cve_operador.focus();
	});
	
	//aplicar evento Keypress para que al pulsar enter ejecute la busqueda
	$(this).aplicarEventoKeypressEjecutaTrigger($busqueda_cve_operador, $buscar);
	$(this).aplicarEventoKeypressEjecutaTrigger($busqueda_nombre, $buscar);

	
	
	
	
	
	
	
	
	
	$tabs_li_funxionalidad = function(){
		
		$('#forma-logoperadores-window').find('#submit').mouseover(function(){
			$('#forma-logoperadores-window').find('#submit').removeAttr("src").attr("src","../../img/modalbox/bt1.png");
		});
		$('#forma-logoperadores-window').find('#submit').mouseout(function(){
			$('#forma-logoperadores-window').find('#submit').removeAttr("src").attr("src","../../img/modalbox/btn1.png");
		});
		$('#forma-logoperadores-window').find('#boton_cancelar').mouseover(function(){
			$('#forma-logoperadores-window').find('#boton_cancelar').css({backgroundImage:"url(../../img/modalbox/bt2.png)"});
		})
		$('#forma-logoperadores-window').find('#boton_cancelar').mouseout(function(){
			$('#forma-logoperadores-window').find('#boton_cancelar').css({backgroundImage:"url(../../img/modalbox/btn2.png)"});
		});
		
		$('#forma-logoperadores-window').find('#close').mouseover(function(){
			$('#forma-logoperadores-window').find('#close').css({backgroundImage:"url(../../img/modalbox/close_over.png)"});
		});
		$('#forma-logoperadores-window').find('#close').mouseout(function(){
			$('#forma-logoperadores-window').find('#close').css({backgroundImage:"url(../../img/modalbox/close.png)"});
		});
		
		
		$('#forma-logoperadores-window').find(".contenidoPes").hide(); //Hide all content
		$('#forma-logoperadores-window').find("ul.pestanas li:first").addClass("active").show(); //Activate first tab
		$('#forma-logoperadores-window').find(".contenidoPes:first").show(); //Show first tab content
		
		//On Click Event
		$('#forma-logoperadores-window').find("ul.pestanas li").click(function() {
			$('#forma-logoperadores-window').find(".contenidoPes").hide();
			$('#forma-logoperadores-window').find("ul.pestanas li").removeClass("active");
			var activeTab = $(this).find("a").attr("href");
			$('#forma-logoperadores-window').find( activeTab , "ul.pestanas li" ).fadeIn().show();
			$(this).addClass("active");
			return false;
		});

	}
	
	
	
	
	
	//nuevas operadores
	$new_logoperadores.click(function(event){
		event.preventDefault();
		var id_to_show = 0;
		$(this).modalPanel_logoperadores();   //llamada al plug in 
		
		var form_to_show = 'formaLogoperadores';
		$('#' + form_to_show).each (function(){this.reset();});
		var $forma_selected = $('#' + form_to_show).clone();
		$forma_selected.attr({id : form_to_show + id_to_show});
		
		$('#forma-logoperadores-window').css({"margin-left": -300, 	"margin-top": -200});
		$forma_selected.prependTo('#forma-logoperadores-window');
		$forma_selected.find('.panelcito_modal').attr({id : 'panelcito_modal' + id_to_show , style:'display:table'});
		$tabs_li_funxionalidad();
                
		//campos de la vista
		var $campo_id = $('#forma-logoperadores-window').find('input[name=identificador]'); 
                //alert($campo_id);
		//var $marca = $('#forma-logoperadores-window').find('input[name=clave_operador]');
		var $nombre = $('#forma-logoperadores-window').find('input[name=nombre]');
		var $apellido_paterno = $('#forma-logoperadores-window').find('input[name=apellido_paterno]');
		var $apellido_materno = $('#forma-logoperadores-window').find('input[name=apellido_materno]');

		//botones		
		var $cerrar_plugin = $('#forma-logoperadores-window').find('#close');
		var $cancelar_plugin = $('#forma-logoperadores-window').find('#boton_cancelar');
		var $submit_actualizar = $('#forma-logoperadores-window').find('#submit');
		
		$campo_id.attr({'value' : 0});
       
		var respuestaProcesada = function(data){
			if ( data['success'] == "true" ){
				jAlert("El Operador fue dado de alta con exito", 'Atencion!');
				var remove = function() {$(this).remove();};
				$('#forma-logoperadores-overlay').fadeOut(remove);
				//refresh_table();
				$get_datos_grid();
			}else{
				// Desaparece todas las interrogaciones si es que existen
				$('#forma-logoperadores-window').find('div.interrogacion').css({'display':'none'});
				
				var valor = data['success'].split('___');
				//muestra las interrogaciones
				for (var element in valor){
					tmp = data['success'].split('___')[element];
					longitud = tmp.split(':');
					if( longitud.length > 1 ){
                                            $('#forma-logoperadores-window').find('img[rel=warning_' + tmp.split(':')[0] + ']')
                                            .parent()
                                            .css({'display':'block'})
                                            .easyTooltip({tooltipId: "easyTooltip2",content: tmp.split(':')[1]});
					}
				}
			}
		}
		var options = {dataType :  'json', success : respuestaProcesada};
		$forma_selected.ajaxForm(options);
                
                var input_json = document.location.protocol + '//' + document.location.host + '/'+controller+'/getOperador.json';
		var parametros={
                    id:0,
                    iu: $('#lienzo_recalculable').find('input[name=iu]').val()
                }
                //alert($('#lienzo_recalculable').find('input[name=iu]').val())
                $.post(input_json,parametros,function(entry){
                        
                });//termina llamada json
		
                
		$cerrar_plugin.bind('click',function(){
			var remove = function() {$(this).remove();};
			$('#forma-logoperadores-overlay').fadeOut(remove);
		});
		
		$cancelar_plugin.click(function(event){
			var remove = function() {$(this).remove();};
			$('#forma-logoperadores-overlay').fadeOut(remove);
			$buscar.trigger('click');
		});
	});
        
        //Eventos del grid edicion,borrar!
	var carga_formaCC00_for_datagrid00 = function(id_to_show, accion_mode){
		//aqui entra para eliminar una entrada
		if(accion_mode == 'cancel'){
                     
			var input_json = document.location.protocol + '//' + document.location.host + '/' + controller + '/' + 'logicDelete.json';
			$arreglo = {'id':id_to_show,
						'iu': $('#lienzo_recalculable').find('input[name=iu]').val()
						};
			jConfirm('Realmente desea eliminar el Operador seleccionado', 'Dialogo de confirmacion', function(r) {
                            if (r){
                                $.post(input_json,$arreglo,function(entry){
                                        if ( entry['success'] == '1' ){
                                                jAlert("El Operador fue eliminado exitosamente", 'Atencion!');
                                                $get_datos_grid();
                                        }
                                        else{
                                                jAlert("El Operador no pudo ser eliminado", 'Atencion!');
                                        }
                                },"json");
                            }
			});
                    
		}else{
			//aqui  entra para editar un registro
			var form_to_show = 'formaLogoperadores';
			
			$('#' + form_to_show).each (function(){this.reset();});
			var $forma_selected = $('#' + form_to_show).clone();
			$forma_selected.attr({id : form_to_show + id_to_show});
			
			$(this).modalPanel_logoperadores();
						
			$('#forma-logoperadores-window').css({"margin-left": -300, 	"margin-top": -200});
                        $forma_selected.prependTo('#forma-logoperadores-window');
                        $forma_selected.find('.panelcito_modal').attr({id : 'panelcito_modal' + id_to_show , style:'display:table'});
                        $tabs_li_funxionalidad();

                        //campos de la vista
                        var $campo_id = $('#forma-logoperadores-window').find('input[name=identificador]'); 
                        //alert($campo_id);
                        var $clave_operador = $('#forma-logoperadores-window').find('input[name=clave_operador]');
                        var $nombre = $('#forma-logoperadores-window').find('input[name=nombre]');
                        var $apellido_paterno = $('#forma-logoperadores-window').find('input[name=apellido_paterno]');
                        var $apellido_materno = $('#forma-logoperadores-window').find('input[name=apellido_materno]');
                       $clave_operador.attr("readonly",true);

                        //botones                        
                        var $cerrar_plugin = $('#forma-logoperadores-window').find('#close');
                        var $cancelar_plugin = $('#forma-logoperadores-window').find('#boton_cancelar');
                        var $submit_actualizar = $('#forma-logoperadores-window').find('#submit');
			
			if(accion_mode == 'edit'){
                            
                            //aqui es el post que envia los datos a getOperador.json
				var input_json = document.location.protocol + '//' + document.location.host + '/'+controller+'/getOperador.json';
				$arreglo = {'id':id_to_show,
							'iu': $('#lienzo_recalculable').find('input[name=iu]').val()
				};
				
				var respuestaProcesada = function(data){
					if ( data['success'] == 'true' ){
						var remove = function() {$(this).remove();};
						$('#forma-logoperadores-overlay').fadeOut(remove);
						jAlert("Los datos se han actualizado.", 'Atencion!');
                                                $get_datos_grid();
						
					}
					else{
						// Desaparece todas las interrogaciones si es que existen
						$('#forma-logoperadores-window').find('div.interrogacion').css({'display':'none'});
						
						var valor = data['success'].split('___');
						//muestra las interrogaciones
						for (var element in valor){
							tmp = data['success'].split('___')[element];
							longitud = tmp.split(':');
							if( longitud.length > 1 ){
								$('#forma-logoperadores-window').find('img[rel=warning_' + tmp.split(':')[0] + ']')
								.parent()
								.css({'display':'block'})
								.easyTooltip({tooltipId: "easyTooltip2",content: tmp.split(':')[1]});
							}
						}
					}
				}
				
				var options = {dataType :  'json', success : respuestaProcesada};
				$forma_selected.ajaxForm(options);
				
				//aqui se cargan los campos al editar
				$.post(input_json,$arreglo,function(entry){
				// aqui van los campos de editar
                                $campo_id.attr({'value' : entry['Operador']['0']['id']});
                                $clave_operador.attr({'value' : entry['Operador']['0']['clave']});
                                $nombre.attr({'value' : entry['Operador']['0']['nombre']});      
				$apellido_paterno.attr({'value' : entry['Operador']['0']['apellido_paterno']});
				$apellido_materno.attr({'value' : entry['Operador']['0']['apellido_materno']});   
				 },"json");//termina llamada json
				
				
				
				//Ligamos el boton cancelar al evento click para eliminar la forma
				$cancelar_plugin.bind('click',function(){
					var remove = function() {$(this).remove();};
					$('#forma-logoperadores-overlay').fadeOut(remove);
				});
				
				$cerrar_plugin.bind('click',function(){
					var remove = function() {$(this).remove();};
					$('#forma-logoperadores-overlay').fadeOut(remove);
					$buscar.trigger('click');
				});
                                
				
			}
		}
	}
    
    $get_datos_grid = function(){
        var input_json = document.location.protocol + '//' + document.location.host + '/'+controller+'/getAllOperadores.json';
        
        var iu = $('#lienzo_recalculable').find('input[name=iu]').val();
        
        $arreglo = {
            'orderby':'id',
            'desc':'DESC',
            'items_por_pag':10,
            'pag_start':1,
            'display_pag':10,
            'input_json':'/'+controller+'/getAllOperadores.json',
            'cadena_busqueda':$cadena_busqueda,
            'iu':iu}
        
        $.post(input_json,$arreglo,function(data){
            
            //pinta_grid
            $.fn.tablaOrdenable(data,$('#lienzo_recalculable').find('.tablesorter'),carga_formaCC00_for_datagrid00);

            //resetea elastic, despues de pintar el grid y el slider
            Elastic.reset(document.getElementById('lienzo_recalculable'));
        },"json");
    }

    $get_datos_grid();
    
    
    
});
