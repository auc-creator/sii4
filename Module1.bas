Attribute VB_Name = "Module1"
Option Explicit
'---------- Comandos de Impresion------------------------------
'ModoExpandido              %(EX0), %(EX1)
'ModoCondensadoOn           %(CD1)
'ModoCondensadoOff          %(CD0)
'ModoEnfatizadoOn           %(EF1)
'ModoEnfatizadoOff          %(EF0)
'ModoSubrayado              %(SB0), %(SB1)
'SaltoPagina                %(SPG)

Public gfmt As String, gfmtCant As String  'formato de moneda y cantidad
'Public gobjGNOp As GNOpcion
'Public gcli As pcProvCli


'variables globales para uso de Guía de remisión

Public FECINITRASL As Date      'fecha inicio traslado
Public FECFINTRASL As Date      'fecha fin traslado
Public FECEMISION As Date       'fecha emisión
Public COMPVTA As String            'comprovante de  venta
Public MOTIVTRASL As String     'motivo del traslado--> valor inicial: lista de motivos
Public MOTIVTRASLSELEC As String     'texto del motivo seleccionado
Public PTOPART As String            'punto de partida
Public PTOLLEG As String              'punto de llegada
Public NOMDEST As String            'nombre destinatario
Public RUCDEST As String                'ruc destinatario
Public NOMTRANSP As String      'nombre transportista
Public RUCTRANSP As String          'ruc transportista
Public GUIAREMISION As String * 1 '0: no ingresó, 1:aceptado; 2:cancelado
Public INDMOTIV As Long
Public COMPIMP As String            'comprovante IMportado
Public NUMFACTSRI As String            'comprovante IMportado

Public NOMCHOFER As String
Public PLACA As String



Public Parametros() As Variant
Public mColP As New Collection


Public Function PreparaCad(ByVal cad As String) As String
    Dim ubica As Integer
    'Elimina los  comentarios y los espacios  en  blanco
    ubica = InStr(1, cad, "'")
    If ubica > 1 Then
        cad = Left$(cad, ubica - 1)
        'cad = Trim$(cad)   no debe eliminar  ¿en que caso?
    ElseIf ubica = 1 Then
        'cad = ""
    End If
 
    PreparaCad = cad
    
End Function

'***Agregado. 19/Mayo/2002. Angel
Private Function ComandoImpresora(ByVal cmd As String) As String
    Dim v As Variant, cadena As String, i As Integer
    
    v = Split(cmd, "-")
    For i = 0 To UBound(v, 1)
        cadena = cadena & Chr$(v(i))
    Next i
    ComandoImpresora = cadena
End Function

Public Sub ProcesaComando(ByVal cmd As String, Sptxt As SiiPrint.PrintTxt, Optional ByRef bandSalto As Boolean)
    Dim valor As Single
      With Sptxt
        Select Case Left(cmd, 3)
        Case "EX0":     .ImpExpandido (0)
        Case "EX1":     .ImpExpandido (1)
        Case "CD0":     .ImpCondensado (0)
        Case "CD1":     .ImpCondensado (1)
        Case "EF0":     .ImpEnfatizado (0)
        Case "EF1":     .ImpEnfatizado (1)
        Case "SB0":     .ImpSubrayado (0)
        Case "SB1":     .ImpSubrayado (1)
        Case "SPG":
            .ImpSaltoPagina
            bandSalto = True
        Case "LIN":
            valor = CSng("0" & Right(cmd, Len(cmd) - InStr(1, cmd, ";")))
            'INTL valor  en milimetros
            'Convierte  de milimetros a pulgadas
            If valor > 0 Then
                valor = valor / 25.4
                .EspacioVertical 3, valor * 216            'INTERLINEADO
                'n= 0:1/6(NORMAL) (36/216=0.166666 pulgada, 4.3mm)
                '   1:1/8         (27/216=0.125    pulgada, 3.175mm)
                '   2:7/72        (21/216=0.097222 pulgada, 2.46mm)
                '   3:x/216
                'x: Solo para cuando n=3
            End If
        Case "LCA": '***Agregado ANGEL 12/Mayo/2003. Longitud de Corte Automático
            .ImpLongitudCorte
        Case "CMD":
            .ImpComando ComandoImpresora(Mid$(cmd, 5, Len(cmd) - 4))
        End Select
     End With
End Sub
 
Public Sub gnProcesaVariable(cad As String, objGNComp As GNComprobante, Sptxt As SiiPrint.PrintTxt)
    Dim mobjGNOp As GNOpcion
    Dim cli As pcProvCli, centro As GNCentroCosto, centroHijo As GNCentroCostoHijo
    Dim GnComp As GNComprobante     'para colocar info. de cliente consumidor final
    Dim prov As pcProvCli, pctranspor As pcProvCli
    Dim vende  As FCVendedor
    Dim Grupo As PCGrupo
    Dim lon As Integer, v As Variant, v1 As Variant
    Dim fmt As String
    Dim CF As Boolean   'variable para consumidor  final SIIFactura
    Dim cod As String, s As String
    Dim VerificaProv As Boolean, i As Integer
    Dim trans As GNTrans
    Dim Pck As PCKardex
    Dim codi As String
    Dim posini As Integer, posfin As Integer, w As Variant
    Dim Porcentaje As Currency, Venta As Currency, Costo As Currency, k As Long
    Dim ITEM As IVInventario, vGrupo As GNVGrupo, gnv As GnVehiculo, idvehi  As Long
    Dim Gar As pcProvCli
    Dim SUC As GNSucursal
    Dim CANTON As PCCanton, pcPROV As PCProvincia, PARRO As PCParroquia
    Dim pcParr As PCParroquia
    Dim rsdet As Recordset, Texto As String, gc  As GNComprobante
    Dim rs As Recordset
    Dim X As Integer, sql As String, saldo As Long, codigo As String
    Dim pca As PCAGencia
    Dim e As pcProvCli, cadL As String
    Dim pcAct As PCActConyuge
    Dim GarAct As PCActConyuge
    Dim GARCANTON As PCCanton
    Dim GARPROV As PCProvincia
    Dim GARParr As PCParroquia
    Dim cadena As String
    Dim PCCalleP As PCCalle
    Dim PCCalleS As PCCalle
    Dim calleP As String, calleS As String
    Dim Forma As TSFormaCobroPago
    Dim rsMesa As Recordset 'hasta tener una clase
    
    Set mobjGNOp = objGNComp.Empresa.GNOpcion
    Set cli = objGNComp.Empresa.RecuperaPCProvCli(objGNComp.CodClienteRef)
    Set prov = objGNComp.Empresa.RecuperaPCProvCli(ObtenerCodPC(objGNComp, VerificaProv))
    Set Gar = objGNComp.Empresa.RecuperaPCProvCli(objGNComp.CodGaranteRef)
    Set centro = objGNComp.Empresa.RecuperaGNCentroCosto(objGNComp.CodCentro)
    Set vende = objGNComp.Empresa.RecuperaFCVendedor(objGNComp.CodVendedor)
    Set pca = objGNComp.Empresa.RecuperaPCAgencia(objGNComp.IdAgencia)
    Dim maxDscto As Currency, suma As Currency, vcancelaTrans  As Currency
    If Not cli Is Nothing Then
        Set pcAct = objGNComp.Empresa.RecuperarPCActConyuge(cli.IdProvcli)
    End If
    If Not Gar Is Nothing Then
        Set GarAct = objGNComp.Empresa.RecuperarPCActConyuge(Gar.IdProvcli)
    End If
    
     
    'variables disponibles para  todas las secciones
    
    With Sptxt
        
        v = Split(cad, ";")
        If IsEmpty(v) Then Exit Sub
        
        fmt = gfmt
        'Corregir Error
        If UBound(v, 1) >= 1 Then lon = IIf(Not (IsNumeric(v(1))), 0, v(1))
        If UBound(v, 1) >= 2 Then fmt = generafmt(CStr(v(2)), CStr(v(0)))
        If UBound(v, 1) >= 3 Then cod = v(3)
        If Not cli Is Nothing Then
            'If cli.CodProvCli = "C0001" Then
            If cli.codtipoDocumento = "F" Then
                CF = True
                s = objGNComp.Descripcion
                If Len(s) > 0 Then
                    '***Angel. 17/oct/2003
                    posini = InStr(1, s, "[")
                    If posini > 0 Then posfin = InStr(posini, s, "]")
                    If (posini <> 0) And (posfin <> 0) Then
                        s = Mid$(s, posini + 1, (posfin - posini) - 1)
                    Else
                        s = Mid(s, 1, IIf((InStr(1, s, "- Efectivo (") - 1) > 0, InStr(1, s, "- Efectivo (") - 1, Len(s)))
                    End If
                    v1 = Split(s, ";")
                End If
            Else
            End If
        End If
        Select Case v(0)
        Case "NUMPAG":  .PrintLine Sptxt.Pagina
        'Campos de Informacion de la empresa
        Case "NOMEMP": .PrintLine .Rellenar(mobjGNOp.NombreEmpresa, lon, True)
        Case "TL1EMP":  .PrintLine .Rellenar(mobjGNOp.Telefono1, lon, True)
        Case "TL2EMP":  .PrintLine .Rellenar(mobjGNOp.Telefono2, lon, True)
        Case "TL3EMP":  .PrintLine .Rellenar(mobjGNOp.Telefono3, lon, True)
        'Case "FX1EMP":  .PrintLine .Rellenar(mobjGNOp.Fax1, lon, True)
        Case "DR1EMP":  .PrintLine .Rellenar(mobjGNOp.Direccion1, lon, True)
        Case "DR2EMP":  .PrintLine .Rellenar(mobjGNOp.Direccion2, lon, True)
        Case "RUCEMP":  .PrintLine .Rellenar(mobjGNOp.RUC, lon, True)
        Case "EMAIL": .PrintLine .Rellenar(mobjGNOp.EMail, lon, True)
        Case "RESOLUCION": .PrintLine .Rellenar(mobjGNOp.Resolucion, lon, True)
        Case "TIPOEMPRESA"
            Select Case mobjGNOp.TipoEmpresaSRI
                Case "CE"
                    Texto = "Contibuyente Especial Resolucion " & mobjGNOp.Resolucion
                Case "SC"
                    Texto = "Obligada a llevar Contabilidad "
            End Select
        .PrintLine .Rellenar(Texto, lon, True)
        'Campos de encabezado comunes entre todas las transacciones
        Case "CODTRANS":    .PrintLine .Rellenar(objGNComp.CodTrans, lon, True)
        Case "NOMGNTRANS":
                        Set trans = objGNComp.Empresa.RecuperaGNTrans(objGNComp.CodTrans)   ' ************** JEAA 20-8-03
                            .PrintLine .Rellenar(trans.NombreTrans, lon, True)   '*************** JEAA 20-8-03  Nombre de la transaccion en el catalogo
        Case "NOMTRANS":
                            .PrintLine .Rellenar(objGNComp.Nombre, lon, True)   '************** JEAA 16-02-04  Valor DEL CAMPO NOMBRE EN LA CABECERA
        Case "NUMTRANS":    .PrintLine .Rellenar(objGNComp.NumTrans, lon, True)
        Case "NUMTRANSSIG":    .PrintLine .Rellenar(objGNComp.GNTrans.NumTransSiguiente, lon, True)  'JEAA 06/02/2007
        Case "NUMTRANSERIE":
                Dim num As String
                    num = objGNComp.NumTrans
                    For i = 1 To lon - 1
                        If Len(num) < lon Then
                                num = "0" & num
                        End If
                    Next i
                    .PrintLine .Rellenar(num, lon, True)
        Case "NUMTRANSERIESIG":
                    num = objGNComp.GNTrans.NumTransSiguiente
                    For i = 1 To lon - 1
                        If Len(num) < lon Then
                                num = "0" & num
                        End If
                    Next i
                    .PrintLine .Rellenar(num, lon, True)
        Case "FECHATRANS":
            .PrintLine .Rellenar(Format(objGNComp.FechaTrans, fmt), lon, True)
        Case "HORATRANS":    .PrintLine .Rellenar(Format(objGNComp.HoraTrans, fmt), lon, True)
        Case "DESCTRANS":
                If UBound(v, 1) > 1 Then 'AUC MODIFICADO PARA AGREGAR PARAMETROS DE LONGITUD DE CADENA AL IMPRIMIR
                    .PrintLine .Rellenar(Mid$(objGNComp.Descripcion, v(2), v(1)), lon, True)
                Else
                    .PrintLine .Rellenar(objGNComp.Descripcion, lon, True)
                End If
        Case "ESTADOTRANS":   .PrintLine .Rellenar(objGNComp.Estado, lon, True)
        Case "CODASIENTO":   .PrintLine .Rellenar(objGNComp.CodAsiento, lon, True)
        Case "CODPRASIENTO":   .PrintLine .Rellenar(objGNComp.CodPRAsiento, lon, True)
        Case "NUMDOCREF":  .PrintLine .Rellenar(objGNComp.NumDocRef, lon, True)
        
        Case "CODCENTRO":   .PrintLine .Rellenar(objGNComp.CodCentro, lon, True)
        Case "CODMESA":
            Set rsMesa = objGNComp.Empresa.Empresa2.ListaMesaPorCC(True, centro.idMesa)
            If Not rsMesa Is Nothing Then
                .PrintLine .Rellenar(rsMesa!codigo, lon, True)
            End If
            Set rsMesa = Nothing
        Case "DESCCENTRO":   .PrintLine .Rellenar(centro.Descripcion, lon, True)
        Case "NOMCENTRO":    .PrintLine .Rellenar(centro.Nombre, lon, True)
        Case "FINICENTRO":  .PrintLine .Rellenar(Format(centro.FechaInicio), lon, True)
        Case "FENTCENTRO":  .PrintLine .Rellenar(Format(centro.FechaEntrega), lon, True)
        Case "DIRCENTRO"
            If Not (centro Is Nothing) Then
                If Len(centro.CodCallePri) > 0 Then
                    Set PCCalleP = objGNComp.Empresa.RecuperaPCCalle(centro.CodCallePri)
                    If Not (PCCalleP Is Nothing) Then
                        calleP = PCCalleP.Descripcion
                    End If
                End If
    
                If Len(centro.CodCalleSec) > 0 Then
                    Set PCCalleS = objGNComp.Empresa.RecuperaPCCalle(centro.CodCalleSec)
                    If Not (PCCalleS Is Nothing) Then
                        calleS = PCCalleS.Descripcion
                    End If
                End If
                .PrintLine .Rellenar(UCase(calleP) & " y " & UCase(calleS) & " No.: " & centro.NumCasa, lon, True)
            End If
    Case "DESCPROVCENTRO"
        If Not (centro Is Nothing) Then
            Set pcPROV = objGNComp.Empresa.RecuperaPCProvincia(centro.IdProvincia)   ' ************** JEAA 17-09-2003
            If Not pcPROV Is Nothing Then
               .PrintLine .Rellenar(pcPROV.Descripcion, lon, True)
            End If
            Set pcPROV = Nothing
        End If
    Case "DESCCANTONCENTRO"
        If Not (centro Is Nothing) Then
            Set CANTON = objGNComp.Empresa.RecuperaPCCanton(centro.IdCanton)   ' ************** JEAA 17-09-2003
            If Not CANTON Is Nothing Then
                .PrintLine .Rellenar(CANTON.Descripcion, lon, True)
            End If
            Set CANTON = Nothing
        End If
    
    Case "DESCPARROQUIACENTRO"
        If Not (centro Is Nothing) Then
            Set PARRO = objGNComp.Empresa.RecuperaPCCanton(centro.IDParroquia)   ' ************** JEAA 17-09-2003
            If Not PARRO Is Nothing Then
                .PrintLine .Rellenar(PARRO.Descripcion, lon, True)
            End If
            Set PARRO = Nothing
        End If
    
    Case "DIRDETALLADACENTRO"
        If Not (centro Is Nothing) Then
            .PrintLine .Rellenar(centro.Observacion, lon, True)
        End If
    
    Case "ZONACENTRO"
        If Not (centro Is Nothing) Then
            .PrintLine .Rellenar(centro.CodZona, lon, True)
        End If
    
    Case "SUBZONACENTRO"
        If Not (centro Is Nothing) Then
            .PrintLine .Rellenar(centro.CodSubZona, lon, True)
        End If
        Case "CODVENDE":  .PrintLine .Rellenar(objGNComp.CodVendedor, lon, True)
        Case "NOMVENDE":
            If Not (vende Is Nothing) Then
                .PrintLine .Rellenar(vende.Nombre, lon, True)
            End If
        Case "EMAILVENDE":
            If Not (vende Is Nothing) Then
                .PrintLine .Rellenar(vende.EMail, lon, True)
            End If
        Case "TELFVENDE":
            If Not (vende Is Nothing) Then
                .PrintLine .Rellenar(vende.telefono, lon, True)
            End If
        Case "FGRABADO":    .PrintLine .Rellenar(Format(objGNComp.fechagrabado, fmt), lon, True)
        Case "CODUSUARIO": .PrintLine .Rellenar(objGNComp.CodUsuario, lon, True)  ' Modificado Oli /19/07/2001
        Case "CODUSUARIOMOD": .PrintLine .Rellenar(objGNComp.CodUsuarioModifica, lon, True)  ' agregado 27/10/04 esteban
        Case "CODRESP": .PrintLine .Rellenar(objGNComp.CodResponsable, lon, True) ' Agregado oliver /19/07/2001
        
        'Case "NUMAUTSRIA": .PrintLine .Rellenar(objGNComp.NumAutSRI, lon, True) '*********JEAA 12/08/03
        Case "NUMAUTSRIA": .PrintLine .Rellenar(objGNComp.AutorizacionSRI, lon, True) '*********JEAA 12/08/03
        Case "CODCREDITOTRIB": .PrintLine .Rellenar(objGNComp.CodCredTrib, lon, True)
        Case "CREDITOTRIB":
                s = DESCCreditoTributario(objGNComp.CodCredTrib)
                .PrintLine .Rellenar(s, lon, True)
        Case "CODTIPOCOMPROBANTE": .PrintLine .Rellenar(objGNComp.CodTipoComp, lon, True)
        Case "TIPOCOMPROBANTE":
                s = DescComprobante(objGNComp.CodTipoComp)
                .PrintLine .Rellenar(s, lon, True)
        Case "FECHAANEXOS": .PrintLine .Rellenar(objGNComp.FechaAnexos, lon, True)
        Case "NUMSERIE":      .PrintLine .Rellenar(objGNComp.NumSerie, lon, True)
        Case "DERDEVOLUCION":
            If objGNComp.BandDevolucion = True Then
                 .PrintLine .Rellenar("SI", lon, True)
            Else
                .PrintLine .Rellenar("NO", lon, True)
            End If
        Case "NUMSERIEESTA":      .PrintLine .Rellenar(objGNComp.NumSerieEstablecimiento, lon, True)
        Case "NUMSERIEPUNTO":      .PrintLine .Rellenar(objGNComp.NumSeriePunto, lon, True)
        'Case "FECHACADU": .PrintLine .Rellenar(objGNComp.FechaCaducidad, lon, True)
        Case "FECHACADUA":        .PrintLine .Rellenar(Format(objGNComp.FechaCaducidad, fmt), lon, True)
        'Case "NOMUSUARIO": .PrintLine .Rellenar(mGNComp.Empresa.UserName, lon, True)
        
        Case "SPACE":  .PrintLine Space(lon)
        Case "CODMONEDA": .PrintLine .Rellenar(objGNComp.CodMoneda, lon, True)
        Case "NOMMONEDA": .PrintLine .Rellenar(mobjGNOp.NombreMoneda(objGNComp.CodMoneda), lon, True)
        Case "COTIZACION": .PrintLine .Rellenar(objGNComp.Cotizacion(objGNComp.CodMoneda), lon, True)
        'Agregado Alex 18/Jun/2002  --> aún por revisar factibilidad
Case "CODCLI", "NOMCLI", "TELCLI", "RUCCLI", "DIRCLI", "CIUCLI", _
               "PCCODGRUPO1", "PCDESGRUPO1", "PCCODGRUPO2", "PCDESGRUPO2", _
                "PCCODGRUPO3", "PCDESGRUPO3", "PCCODGRUPO4", "PCDESGRUPO4", _
                "TELCLI2", "TELCLI3", "FAXCLI", "DIRCLI2", "CODPOSTALCLI", "CIUCLI", _
                "PROVINCLI", "PAISCLI", "AUTSRICLI", "BANCOCLI", "NUMCUECLI", "NOMALTCLI", "LIMITECREDITO", _
                "PCSALDOTOTAL", "NOMALTCLI", "PCCODGRUPO4", "PCDESGRUPO4", _
                 "PCCANTON", "PCPROVINCIA", "EMAILCLI", "SWIT", "DIRBANCO", "TELBANCO", "PCPARROQUIA", "CLIINGRESOS", _
                "CLIACTIVIDAD", "CLINOMTRAB", "CLIDIRTRAB", "CLIDIRTRAB", "CLITELTRAB", "CLIANTTRAB"

            If Not (cli Is Nothing) Then
                Select Case v(0)
                  'Modificado Alex/22/11/01 ==> para colocar datos de cliente consumidor final
                Case "CODCLI":   .PrintLine .Rellenar(cli.CodProvCli, lon, True)
                Case "NOMCLI": .PrintLine .Rellenar(IIf(CF, objGNComp.Nombre, cli.Nombre), lon, True)
                'AUC 18/05/07 desde aqui
                Case "NOMALTCLI":
                    If Len(Trim$(cli.NombreAlterno)) > 0 Then
                        .PrintLine .Rellenar(cli.NombreAlterno, lon, True)
                    Else
                        .PrintLine .Rellenar(Space(lon), lon, True)
                    End If
                Case "SWIT": .PrintLine .Rellenar(cli.Swit, lon, True) 'auc 13/10/2014 ta mal el campo estaba telefono2
                Case "TELCLI3": .PrintLine .Rellenar(cli.Telefono3, lon, True)
                Case "FAXCLI": .PrintLine .Rellenar(cli.Fax, lon, True)
                Case "DIRCLI2": .PrintLine .Rellenar(cli.Direccion2, lon, True)
                Case "CODPOSTALCLI": .PrintLine .Rellenar(cli.CodPostal, lon, True)
                Case "CIUCLI": .PrintLine .Rellenar(cli.ciudad, lon, True)
                Case "PROVINCLI": .PrintLine .Rellenar(cli.Provincia, lon, True)
                Case "PAISCLI": .PrintLine .Rellenar(cli.Pais, lon, True)
                Case "AUTSRICLI": .PrintLine .Rellenar(cli.NumAutSRI, lon, True)
                Case "BANCOCLI": .PrintLine .Rellenar(cli.Banco, lon, True)
                Case "NUMCUECLI": .PrintLine .Rellenar(cli.NumCuenta, lon, True)
                Case "EMAILCLI": .PrintLine .Rellenar(cli.EMail, lon, True)
                Case "DIRBANCO": .PrintLine .Rellenar(cli.DirecBanco, lon, True)
                Case "TELBANCO": .PrintLine .Rellenar(cli.TelBanco, lon, True)
                Case "CLIINGRESOS"
                    If Not pcAct Is Nothing Then .PrintLine .Rellenar(pcAct.IngresosSoli, lon, True)
                Case "CLIACTIVIDAD":
                    If Not pcAct Is Nothing Then .PrintLine .Rellenar(pcAct.ActividadSoli, lon, True)
                Case "CLINOMTRAB":
                    If Not pcAct Is Nothing Then .PrintLine .Rellenar(pcAct.NombreTrabajoSoli, lon, True)
                Case "CLIDIRTRAB":
                    If Not pcAct Is Nothing Then .PrintLine .Rellenar(pcAct.DirTrabajoSoli, lon, True)
                Case "CLITELTRAB":
                    If Not pcAct Is Nothing Then .PrintLine .Rellenar(pcAct.TelfActividadSol, lon, True)
                Case "CLIANTTRAB":
                    If Not pcAct Is Nothing Then .PrintLine .Rellenar(pcAct.AntiguedadSoli, lon, True)
                    
                
               Case "TELCLI":
                  If CF Then
                    .PrintLine .Rellenar(objGNComp.telefono, lon, True)
                  Else
                    .PrintLine .Rellenar(cli.Telefono1, lon, True)
                  End If
                Case "RUCCLI":
                    If CF Then
                        .PrintLine .Rellenar(objGNComp.RUC, lon, True)
                    Else
                        .PrintLine .Rellenar(cli.RUC, lon, True)
                    End If
                Case "DIRCLI":
                  If CF Then
                        .PrintLine .Rellenar(objGNComp.direccion, lon, True)
                  Else
                    .PrintLine .Rellenar(cli.Direccion1, lon, True)
                  End If
                Case "CIUCLI":
                  If CF Then
                    If Not IsEmpty(v1) Then
                        If UBound(v1, 1) > 2 Then .PrintLine .Rellenar(v1(3), lon, True)
                    End If
                  Else
                    .PrintLine .Rellenar(cli.ciudad, lon, True)
                  End If
                Case "FAXCLI":
                  If CF Then
                    If Not IsEmpty(v1) Then
                        If UBound(v1, 1) > 2 Then .PrintLine .Rellenar(v1(3), lon, True)
                    End If
                  Else
                    .PrintLine .Rellenar(cli.Fax, lon, True)
                  End If
                
                Case "PCCODGRUPO1":    ' JEAA 17/09/2003 codigo gupo de PCGRUPO1
                  If Not CF Then
                        Set Grupo = objGNComp.Empresa.RecuperaPCGrupo(1, cli.IdGrupo1)  ' ************** JEAA 17-09-2003
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.codGrupo, lon, True)
                        End If
                  End If
                  
            Case "PCCODGRUPO2":    ' JEAA 17/09/2003 codigo gupo de PCGRUPO2
                  If Not CF Then
                        Set Grupo = objGNComp.Empresa.RecuperaPCGrupo(2, cli.IdGrupo2)  ' ************** JEAA 17-09-2003
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.codGrupo, lon, True)
                        End If
                  End If
                  
            Case "PCCODGRUPO3":    ' JEAA 17/09/2003 codigo gupo de PCGRUPO3
                  If Not CF Then
                        Set Grupo = objGNComp.Empresa.RecuperaPCGrupo(3, cli.IdGrupo3)  ' ************** JEAA 17-09-2003
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.codGrupo, lon, True)
                        End If
                  End If
            Case "PCCODGRUPO4":    ' JEAA 17/09/2003 codigo gupo de PCGRUPO3
                  If Not CF Then
                        Set Grupo = objGNComp.Empresa.RecuperaPCGrupo(4, cli.IdGrupo4)  ' ************** JEAA 17-09-2003
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.codGrupo, lon, True)
                        End If
                  End If
                Case "PCDESGRUPO1":    ' JEAA 17/09/2003 descripcion gupo de PCGRUPO1
                  If Not CF Then
                        Set Grupo = objGNComp.Empresa.RecuperaPCGrupo(1, cli.IdGrupo1)  ' ************** JEAA 17-09-2003
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.Descripcion, lon, True)
                        End If
                  End If
                Case "PCDESGRUPO2":    ' JEAA 17/09/2003 descripcion gupo de PCGRUPO2
                  If Not CF Then
                        Set Grupo = objGNComp.Empresa.RecuperaPCGrupo(2, cli.IdGrupo2)  ' ************** JEAA 17-09-2003
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.Descripcion, lon, True)
                        End If
                  End If
                Case "PCDESGRUPO3":    ' JEAA 17/09/2003 descripcion gupo de PCGRUPO3
                  If Not CF Then
                        Set Grupo = objGNComp.Empresa.RecuperaPCGrupo(3, cli.IdGrupo3)  ' ************** JEAA 17-09-2003
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.Descripcion, lon, True)
                        End If
                  End If
            Case "PCDESGRUPO4":    ' JEAA 18/05/2006 descripcion gupo de PCGRUPO3
                  If Not CF Then
                        Set Grupo = objGNComp.Empresa.RecuperaPCGrupo(4, cli.IdGrupo4)  ' ************** JEAA 17-09-2003
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.Descripcion, lon, True)
                        End If
                  End If
                'AUC 18/05/07 desde aqui
                Case "NOMALTCLI": .PrintLine .Rellenar(cli.NombreAlterno, lon, True)
                Case "TELCLI2": .PrintLine .Rellenar(cli.Telefono2, lon, True)
                Case "TELCLI3": .PrintLine .Rellenar(cli.Telefono3, lon, True)
                Case "FAXCLI": .PrintLine .Rellenar(cli.Fax, lon, True)
                Case "DIRCLI2": .PrintLine .Rellenar(cli.Direccion2, lon, True)
                Case "CODPOSTALCLI": .PrintLine .Rellenar(cli.CodPostal, lon, True)
                Case "CIUCLI": .PrintLine .Rellenar(cli.ciudad, lon, True)
                Case "PROVINCLI": .PrintLine .Rellenar(cli.Provincia, lon, True)
                Case "PAISCLI": .PrintLine .Rellenar(cli.Pais, lon, True)
                Case "AUTSRICLI": .PrintLine .Rellenar(cli.NumAutSRI, lon, True)
                Case "BANCOCLI": .PrintLine .Rellenar(cli.Banco, lon, True)
                Case "NUMCUECLI": .PrintLine .Rellenar(cli.NumCuenta, lon, True)
                Case "LIMITECREDITO": .PrintLine .Rellenar(cli.LimiteCredito, lon, True)
                Case "PCCANTON":    ' JEAA 18/05/2006 descripcion gupo de PCGRUPO3
                        Set CANTON = objGNComp.Empresa.RecuperaPCCanton(cli.IdCanton)   ' ************** JEAA 17-09-2003
                        If Not CANTON Is Nothing Then
                            .PrintLine .Rellenar(CANTON.Descripcion, lon, True)
                        Else
                            .PrintLine .Rellenar("                                                ", lon, True)
                        End If
                Case "PCPROVINCIA":    ' JEAA 18/05/2006 descripcion gupo de PCGRUPO3
                        Set pcPROV = objGNComp.Empresa.RecuperaPCProvincia(cli.IdProvincia)   ' ************** JEAA 17-09-2003
                        If Not pcPROV Is Nothing Then
                            .PrintLine .Rellenar(pcPROV.Descripcion, lon, True)
                        Else
                            .PrintLine .Rellenar("                                                ", lon, True)
                        End If
                Case "PCPARROQUIA":
                        Set pcParr = objGNComp.Empresa.RecuperaPCParroquia(cli.IDParroquia)
                        If Not pcParr Is Nothing Then
                            .PrintLine .Rellenar(pcParr.Descripcion, lon, True)
                        Else
                            .PrintLine .Rellenar("                                                ", lon, True)
                        End If
                'hasta aqui
                Case "PCSALDOTOTAL":        '**********  SALDO TOTAL
                    Set rs = New Recordset
                    If Not (cli Is Nothing) Then
                        codigo = cli.CodProvCli
                    Else
                If Not (prov Is Nothing) Then
                            codigo = prov.CodProvCli
                        End If
                     End If
                    X = mobjGNOp.IndiceMoneda(objGNComp.CodMoneda)
                    sql = "SELECT  " & _
                    "   CodProvCli, " & _
                    "   sum(" & _
                    " Valor" & X & " - VCancelado" & X & _
                     "   ) AS Saldo" & _
                    "   FROM vwConsPCPorCobrarPagar " & _
                    "   WHERE  (CodProvCli ='" & codigo & "') AND " & _
                    "   (PorCobrar = 1)  AND " & _
                    "   (ConsiderarComoEfectivo = 0) "
                    If UBound(v) = 3 Then
                        sql = sql & " and codforma='" & v(3) & "'"
                    End If
                    sql = sql & " group BY CodProvCli"
                    Set rs = objGNComp.Empresa.OpenRecordset(sql)
                    If Not rs.EOF Then
                        .PrintLine .Rellenar(Format(rs.Fields("saldo"), fmt), lon, False) ' 19-09-03 SALDO TOTAL X PAGAR DEL CLEIENTE
                    Else
                        .PrintLine .Rellenar(Format(0, fmt), lon, False)   ' 19-09-03 SALDO TOTAL X PAGAR DEL CLEIENTE
                    End If
                    rs.Close
                    Set rs = Nothing
        Case "PCSALDOTOTALVENCIDO":        '**********  SALDO TOTAL VENCIDO
                    Set rs = New Recordset
                    If Not (cli Is Nothing) Then
                        codigo = cli.CodProvCli
                    Else
                        If Not (prov Is Nothing) Then
                            codigo = prov.CodProvCli
                        End If
                     End If
                    X = mobjGNOp.IndiceMoneda(objGNComp.CodMoneda)
                    sql = "SELECT  " & _
                    "   CodProvCli, " & _
                    "   sum(" & _
                    " Valor" & X & " - VCancelado" & X & _
                     "   ) AS Saldo" & _
                    "   FROM vwConsPCPorCobrarPagar " & _
                    "   WHERE  (FechaVenci <= '" & objGNComp.FechaTrans & "') AND " & _
                    "       (CodProvCli ='" & codigo & "') AND " & _
                    "   (PorCobrar = 1)  AND " & _
                    "   (ConsiderarComoEfectivo = 0) "
                    If UBound(v) = 3 Then
                        sql = sql & " and codforma='" & v(3) & "'"
                    End If
                    sql = sql & "   group BY CodProvCli"
                    Set rs = objGNComp.Empresa.OpenRecordset(sql)
                    If Not rs.EOF Then
                        .PrintLine .Rellenar(Format(rs.Fields("saldo"), fmt), lon, False) ' 05-08-04 SALDO TOTAL X PAGAR DEL CLEIENTE
                    Else
                        .PrintLine .Rellenar(Format(0, fmt), lon, False)   ' 05-08-04 SALDO TOTAL VENCIDO X PAGAR DEL CLEIENTE
                    End If
                    rs.Close
                    Set rs = Nothing
            End Select
            End If
        Case "CODPROV", "NOMPROV", "TELPROV", "RUCPROV", "DIRPROV", "CIUPROV", "NOMALTPROV", _
             "TELCLI2", "TELCLI3", "FAXPROV", "DIRPROV2", "CODPOSTALPROV", "CIUPROV", _
             "PROVINPROV", "PAISPROV", "AUTSRIPROV", "BANCOPROV", "NUMCUEPROV"
            cod = v(0)
            If Not (prov Is Nothing) Then
                Select Case cod
                    Case "CODPROV": .PrintLine .Rellenar(prov.CodProvCli, lon, True)
                    Case "NOMPROV": .PrintLine .Rellenar(prov.Nombre, lon, True)
                    Case "TELPROV": .PrintLine .Rellenar(prov.Telefono1, lon, True)
                    Case "RUCPROV":
                        If VerificaProv And prov.RUC = "" Then
                            .PrintLine .Rellenar(InputBox("No existe RUC de Proveedor " & vbCrLf & "Por favor ingréselo"), lon, True)
                        Else
                            .PrintLine .Rellenar(prov.RUC, lon, True)
                        End If
                    Case "DIRPROV": .PrintLine .Rellenar(prov.Direccion1, lon, True)
                    Case "CIUPROV": .PrintLine .Rellenar(prov.ciudad, lon, True)
                    Case "FAXPROV": .PrintLine .Rellenar(prov.Fax, lon, True)
                    Case "NOMALTPROV": .PrintLine .Rellenar(prov.NombreAlterno, lon, True)  'AUC agregado 18/05/07
                    Case "TELPROV": .PrintLine .Rellenar(prov.Telefono1, lon, True)
                    'AUC 18/05/07 desde aqui
                    
                    Case "TELPROV2": .PrintLine .Rellenar(prov.Telefono2, lon, True)
                    Case "TELPROV3": .PrintLine .Rellenar(prov.Telefono3, lon, True)
                    Case "FAXPROV": .PrintLine .Rellenar(prov.Fax, lon, True)
                    Case "DIRPROV2": .PrintLine .Rellenar(prov.Direccion2, lon, True)
                    Case "CODPOSTALPROV": .PrintLine .Rellenar(prov.CodPostal, lon, True)
                    Case "CIUPROV": .PrintLine .Rellenar(prov.ciudad, lon, True)
                    Case "PROVINPROV": .PrintLine .Rellenar(prov.Provincia, lon, True)
                    Case "PAISPROV": .PrintLine .Rellenar(prov.Pais, lon, True)
                    Case "AUTSRIPROV": .PrintLine .Rellenar(prov.NumAutSRI, lon, True)
                    Case "BANCOPROV": .PrintLine .Rellenar(prov.Banco, lon, True)
                    Case "NUMCUEPROV": .PrintLine .Rellenar(prov.NumCuenta, lon, True)
                    'hasta aqui
                
                End Select
            ElseIf VerificaProv Then
                Select Case cod
                    Case "NOMPROV":
                        If objGNComp.Nombre = "" Then
                                .PrintLine .Rellenar(InputBox("No existe Nombre de Proveedor " & vbCrLf & "Por favor ingréselo"), lon, True)
                        Else
                            .PrintLine .Rellenar(objGNComp.Nombre, lon, True)
                        End If   'controlar cuando da escape en el ruc--> debe digitar un número de ruc
                    Case "RUCPROV": .PrintLine .Rellenar(InputBox("No existe RUC de Proveedor " & vbCrLf & "Por favor ingréselo"), lon, True)
                End Select
            End If
        Case "CODBODORI": .PrintLine .Rellenar(CodBodegaOri(objGNComp), lon, True)
        Case "DESCBODORI": .PrintLine .Rellenar(DescBodega(objGNComp, CodBodegaOri(objGNComp)), lon, True)
        Case "CODBODDEST": .PrintLine .Rellenar(CodBodegaDest(objGNComp), lon, True)
        Case "DESCBODDEST": .PrintLine .Rellenar(DescBodega(objGNComp, CodBodegaDest(objGNComp)), lon, True)
        Case "CANTTTL":  .PrintLine .Rellenar(Format(CantTotal(objGNComp), fmt), lon, False)
        Case "CODBCOPRI": .PrintLine .Rellenar(CodBcoPri(objGNComp), lon, True)
        Case "NOMBBCOPRI": .PrintLine .Rellenar(NomBcoPri(objGNComp, CodBcoPri(objGNComp)), lon, True)
        Case "BENBCOPRI": .PrintLine .Rellenar(CodBcoPri(objGNComp, True), lon, True)
        Case "FVENCIPRI":
        If objGNComp.CountPCKardex > 0 Then
        .PrintLine .Rellenar(Format(FVenci(objGNComp), fmt), lon, True)  'fecha  vencimiento
        Else
            .PrintLine .Rellenar(Format(Date, fmt), lon, True)  'fecha  vencimiento
        End If
        Case "CODDOCXCOBPRI": .PrintLine .Rellenar(Format(CodDocxCobPri(objGNComp), fmt), lon, True)
        Case "NOMDOCXCOBPRI": .PrintLine .Rellenar(Format(NomDocxCobPri(objGNComp, CodDocxCobPri(objGNComp)), fmt), lon, True)
        'enviar a imprimir nombre, dir, tel, ruc de proveedor cuando se hacen ET y estos datos no existen directamente en header
         Case "NOMPROVXPAG": .PrintLine .Rellenar(NomProvxPag(objGNComp), lon, True)
        Case "NUMTRANSFUENTE": .PrintLine .Rellenar(TransFuente(objGNComp, "NUMTRANS"), lon, True) '14/05/2001  Angel P.
        Case "RECAR":        'recargo  especificado con  codigo
                .PrintLine .Rellenar(Format(Abs(Recargo(objGNComp, cod)), fmt), lon, False)
        Case "AFRECAR":        'recargo  especificado con  codigo
                .PrintLine .Rellenar(Format(Abs(AFRecargo(objGNComp, cod)), fmt), lon, False)
        Case "CARGARMOTIVTRASL", "CARGARMOTIVO_TRASL": MOTIVTRASL = v(1)
        Case "FECINITRASL", "FECFINTRASL", "FECEMISION", "COMPVTA", "PTOPART", "PTOLLEG", _
            "NOMDEST", "RUCDEST", "NOMTRANSP", "RUCTRANSP", "COMPIMP", "NUMFACTSRI", "NOMCHOFER", "PLACA-CHOFER" 'Alex 03/01/2002 control para guías de remisión
            If Val(GUIAREMISION) = 0 Then
                frmGuia.Inicio objGNComp
            End If
            Select Case v(0)
                Case "FECINITRASL": .PrintLine .Rellenar(Format(FECINITRASL, fmt), lon, True)
                Case "FECFINTRASL": .PrintLine .Rellenar(Format(FECFINTRASL, fmt), lon, True)
                Case "FECEMISION": .PrintLine .Rellenar(Format(FECEMISION, fmt), lon, True)
                Case "COMPVTA": .PrintLine .Rellenar(COMPVTA, lon, True)
                Case "PTOPART": .PrintLine .Rellenar(PTOPART, lon, True)
                Case "PTOLLEG": .PrintLine .Rellenar(PTOLLEG, lon, True)
                Case "NOMDEST": .PrintLine .Rellenar(NOMDEST, lon, True)
                Case "RUCDEST": .PrintLine .Rellenar(RUCDEST, lon, True)
                Case "NOMTRANSP": .PrintLine .Rellenar(NOMTRANSP, lon, True)
                Case "RUCTRANSP": .PrintLine .Rellenar(RUCTRANSP, lon, True)
                Case "COMPIMP": .PrintLine .Rellenar(COMPIMP, lon, True)
                Case "NUMFACTSRI": .PrintLine .Rellenar(NUMFACTSRI, lon, True)
                Case "NOMCHOFER":
                    .PrintLine .Rellenar(NOMCHOFER, lon, True)
                Case "PLACA-CHOFER": .PrintLine .Rellenar(PLACA, lon, True)
                
            End Select
        Case "MOTIVTRASL"
                'comparar qué valor va a imprimir de acuerdo a los parámetros enviados.
                s = ImpParam("MOTIVTRASL", Val(v(2)))
                .PrintLine .Rellenar(s, lon, True)
        Case "MOTIVO_TRASL"
                s = ImpresionP("MOTIVTRASL", Val(v(2)))
                  .PrintLine .Rellenar(s, lon, True)
'        Case "PCSALDOTOTAL":        '**********  SALDO TOTAL
'                   Dim rs As Recordset
'                    Dim X As Integer, sql As String, saldo As Long, codigo As String
'                    Set rs = New Recordset
'                    If Not (cli Is Nothing) Then
'                        codigo = cli.CodProvCli
'                    Else
'                If Not (prov Is Nothing) Then
'                            codigo = prov.CodProvCli
'                        End If
'                     End If
'                    X = mobjGNOp.IndiceMoneda(objGNComp.CodMoneda)
'                    sql = "SELECT  " & _
'                    "   CodProvCli, " & _
'                    "   sum(" & _
'                    " Valor" & X & " - VCancelado" & X & _
'                     "   ) AS Saldo" & _
'                    "   FROM vwConsPCPorCobrarPagar " & _
'                    "   WHERE  (CodProvCli ='" & codigo & "') AND " & _
'                    "   (PorCobrar = 1)  AND " & _
'                    "   (ConsiderarComoEfectivo = 0) "
'                    If UBound(v) = 3 Then
'                        sql = sql & " and codforma='" & v(3) & "'"
'                    End If
'                    sql = sql & " group BY CodProvCli"
'                    Set rs = objGNComp.Empresa.OpenRecordset(sql)
'                    If Not rs.EOF Then
'                        .PrintLine .Rellenar(Format(rs.Fields("saldo"), fmt), lon, False) ' 19-09-03 SALDO TOTAL X PAGAR DEL CLEIENTE
'                    Else
'                        .PrintLine .Rellenar(Format(0, fmt), lon, False)   ' 19-09-03 SALDO TOTAL X PAGAR DEL CLEIENTE
'                    End If
'                    rs.Close
'                    Set rs = Nothing
'        Case "PCSALDOTOTALVENCIDO":        '**********  SALDO TOTAL VENCIDO
'                    Set rs = New Recordset
'                    If Not (cli Is Nothing) Then
'                        codigo = cli.CodProvCli
'                    Else
'                        If Not (prov Is Nothing) Then
'                            codigo = prov.CodProvCli
'                        End If
'                     End If
'                    X = mobjGNOp.IndiceMoneda(objGNComp.CodMoneda)
'                    sql = "SELECT  " & _
'                    "   CodProvCli, " & _
'                    "   sum(" & _
'                    " Valor" & X & " - VCancelado" & X & _
'                     "   ) AS Saldo" & _
'                    "   FROM vwConsPCPorCobrarPagar " & _
'                    "   WHERE  (FechaVenci <= '" & objGNComp.FechaTrans & "') AND " & _
'                    "       (CodProvCli ='" & codigo & "') AND " & _
'                    "   (PorCobrar = 1)  AND " & _
'                    "   (ConsiderarComoEfectivo = 0) "
'                    If UBound(v) = 3 Then
'                        sql = sql & " and codforma='" & v(3) & "'"
'                    End If
'                    sql = sql & "   group BY CodProvCli"
'                    Set rs = objGNComp.Empresa.OpenRecordset(sql)
'                    If Not rs.EOF Then
'                        .PrintLine .Rellenar(Format(rs.Fields("saldo"), fmt), lon, False) ' 05-08-04 SALDO TOTAL X PAGAR DEL CLEIENTE
'                    Else
'                        .PrintLine .Rellenar(Format(0, fmt), lon, False)   ' 05-08-04 SALDO TOTAL VENCIDO X PAGAR DEL CLEIENTE
'                    End If
'                    rs.Close
'                    Set rs = Nothing
        Case "ESCOPIA"  'jeaa 30-09-04
                    If objGNComp.Impresion = 1 Then
                        If Not cli Is Nothing Then
                            If cli.codtipoDocumento <> "F" Then
                                If UBound(v) = 3 Then Texto = v(3)
                            Else
                                Texto = "****  REIMPRESION **** "
                            End If
                        Else
                            If UBound(v) = 3 Then Texto = v(3)
                        End If
                    Else
                            If UBound(v) > 1 Then
                                    Texto = v(2)
                            End If
                    End If
                    .PrintLine .Rellenar(Texto, lon, True)

                        
                'solo para fACTURAS CON fINANCIAMIENTO
                '        Case "CAPITALFINANCIADO":
                '                w = Split(objGNComp.DatosFinaciamiento, ";")
                '                If UBound(w) > -1 Then .PrintLine .Rellenar(Format(Abs(w(0)), fmt), lon, False)
                '        Case "NUMEPER"
                '                w = Split(objGNComp.DatosFinaciamiento, ";")
                '                If UBound(w) > 0 Then .PrintLine .Rellenar(Format(Abs(w(1)), fmt), lon, False)
                '        Case "TASA"
                '                w = Split(objGNComp.DatosFinaciamiento, ";")
                '                If UBound(w) > 1 Then .PrintLine .Rellenar(Format(Abs(w(2)), fmt), lon, False)
                '        Case "PERIODOS"
                '                w = Split(objGNComp.DatosFinaciamiento, ";")
                '                If UBound(w) > 2 Then .PrintLine .Rellenar(SeleccionaPeriodo(w(3)), lon, True)
                '        Case "PAGOMENSUAL"
                '                w = Split(objGNComp.DatosFinaciamiento, ";")
                '                If UBound(w) > 3 Then .PrintLine .Rellenar(Format(Abs(w(4)), fmt), lon, False)
        Case "NUMDOCREFRET":
                Set rs = New Recordset
                Set rs = objGNComp.ListaTSKardexRetAsociada
                If Not rs.EOF Then
                    rs.MoveLast
                    rs.MoveFirst
                End If
                        .PrintLine .Rellenar(rs.Fields(2), lon, True)
        Case "FECHADEVOLUCION":
                .PrintLine .Rellenar(Format(objGNComp.FechaDevol, fmt), lon, True)
        Case "FECHADEV": 'AUC imprime fecha devolucion casa del disfraz 25/01/07
               .PrintLine .Rellenar(Format(objGNComp.FechaDevol, fmt), lon, True)
        Case "NUMSERIEEST":    .PrintLine .Rellenar(objGNComp.GNTrans.NumSerieEstablecimiento, lon, True)
        Case "NUMSERIEPUN":    .PrintLine .Rellenar(objGNComp.GNTrans.NumSeriePunto, lon, True)
        Case "NUMAUTOSRI":    .PrintLine .Rellenar(objGNComp.AutorizacionSRI, lon, True)
        Case "FECHACADU":        .PrintLine .Rellenar(Format(objGNComp.FechaCaducidadSRI, fmt), lon, True)
        Case "FECHAAUTO":
            .PrintLine .Rellenar(Format(objGNComp.FechaAutorizacionSRI, fmt), lon, True)
        Case "RECAR+IVA":        'recargo  especificado con  codigo mas iva jeaa 21/06/2005
                Dim ValRec As Currency
                ValRec = objGNComp.Empresa.GNOpcion.PorcentajeIVA
                cod = v(3)
                .PrintLine .Rellenar(Format(Abs(RecargoMasIva(objGNComp, cod, ValRec)), fmt), lon, False)
        '09/11/05 AUC imprime fechadealquiler
        Case "FECHAALQ":
                sql = "select fechaAlquilar from ivreservacion where transid = " & objGNComp.TransId & " group by fechaAlquilar "
                Set rs = objGNComp.Empresa.OpenRecordset(sql)
                .PrintLine .Rellenar(Format(rs!fechaAlquilar, fmt), lon, True)
                Set rs = Nothing
        Case "RAZONSOCIAL":
            .PrintLine .Rellenar(objGNComp.Empresa.GNOpcion.RazonSocial, lon, True) 'JEAA 11/06/2007
        Case "SALDOCREDITO":        '**********  SALDO CREDITO
                   
                    'Dim x As Integer, sql As String, saldo As Long, codigo As String
                    Set rs = New Recordset
                    If Not (cli Is Nothing) Then
                        codigo = cli.CodProvCli
                    Else
                        If Not (prov Is Nothing) Then
                            codigo = prov.CodProvCli
                        End If
                     End If
                    X = mobjGNOp.IndiceMoneda(objGNComp.CodMoneda)
                    sql = "SELECT  " & _
                    "   CodProvCli, " & _
                    "   sum(" & _
                    " Valor" & X & " - VCancelado" & X & _
                     "   ) AS Saldo"
                     
                     
                    sql = sql & "   FROM vwConsPCPorCobrarPagar " & _
                    "   WHERE  (CodProvCli ='" & codigo & "') AND " & _
                    "   (PorCobrar = 1)  AND " & _
                    "   (ConsiderarComoEfectivo = 0) "
                    If UBound(v) = 3 Then
                        sql = sql & " and codforma='" & v(3) & "'"
                    End If
                    sql = sql & " group BY CodProvCli"
                    Set rs = objGNComp.Empresa.OpenRecordset(sql)
                    If Not rs.EOF Then
                        .PrintLine .Rellenar(Format(cli.LimiteCredito - rs.Fields("saldo"), fmt), lon, False) ' 19-09-03 SALDO TOTAL X PAGAR DEL CLEIENTE
                    Else
                        .PrintLine .Rellenar(Format(cli.LimiteCredito - 0, fmt), lon, False) ' 19-09-03 SALDO TOTAL X PAGAR DEL CLEIENTE
                    End If
                    rs.Close
                    Set rs = Nothing
        Case "NUMPAGOS":        '**********  NUMERO DE PAGOS
                    Set rs = New Recordset
                    X = mobjGNOp.IndiceMoneda(objGNComp.CodMoneda)
                    sql = "SELECT  P.TRANSID,COUNT(P.TRANSID) AS NUMPAGOS"
                    sql = sql & " FROM GNCOMPROBANTE G INNER JOIN PCKARDEX P ON G.TRANSID=P.TRANSID "
                    sql = sql & " WHERE G.TRANSID= " & objGNComp.TransId
                    sql = sql & " GROUP BY P.TRANSID "
                    Set rs = objGNComp.Empresa.OpenRecordset(sql)
                    If Not rs.EOF Then
                        .PrintLine .Rellenar(rs.Fields("NUMPAGOS"), lon, False) '
                    Else
                        .PrintLine .Rellenar(0, lon, False) '
                    End If
                    rs.Close
                    Set rs = Nothing
        Case "UTILPOR" 'AUC 17/12/07 Imprime porcentaje de utilidad por transaccion
                    Venta = 0
                    Costo = 0
                     For k = 1 To objGNComp.CountIVKardex
                        If Len(objGNComp.IVKardex(k).CodInventario) > 0 Then
                            sql = "SELECT  costoultimoingreso from ivinventario where codinventario = '" & objGNComp.IVKardex(k).CodInventario & "'"
                            Set rs = objGNComp.Empresa.OpenRecordset(sql)
                            If objGNComp.GNTrans.IVCostoCalculaUtil = 0 Then
                                If Not IsNull(rs!CostoUltimoIngreso) Then
                                    Costo = Costo + Abs(rs!CostoUltimoIngreso) * Abs(objGNComp.IVKardex(k).Cantidad)
                                End If
                            ElseIf objGNComp.GNTrans.IVCostoCalculaUtil = 1 Then
                                    Costo = Costo + Abs(objGNComp.IVKardex(k).CostoRealTotal)
                            End If
                            Venta = Venta + Abs(objGNComp.IVKardex(k).PrecioRealTotal)
                            rs.Close
                            Set rs = Nothing
                        End If
                    Next
                    If Costo <> 0 Then
                        Porcentaje = (Abs(Venta) - Abs(Costo)) / Abs(Costo) * 100
                    Else
                        Porcentaje = Abs(Venta)
                    End If

                        .PrintLine .Rellenar(Format(Porcentaje, fmt), lon, False)
        Case "UTILVAL" 'AUC 17/12/07 Imprime valor de utilidad por transaccion
                     For k = 1 To objGNComp.CountIVKardex
                        If Len(objGNComp.IVKardex(k).CodInventario) > 0 Then
                            sql = "SELECT  costoultimoingreso from ivinventario where codinventario = '" & objGNComp.IVKardex(k).CodInventario & "'"
                            Set rs = objGNComp.Empresa.OpenRecordset(sql)
                                If objGNComp.GNTrans.IVCostoCalculaUtil = 0 Then
                                    If Not IsNull(rs!CostoUltimoIngreso) Then
                                        Costo = Costo + Abs(rs!CostoUltimoIngreso) * Abs(objGNComp.IVKardex(k).Cantidad)
                                    End If
                                ElseIf objGNComp.GNTrans.IVCostoCalculaUtil = 1 Then
                                        Costo = Costo + Abs(objGNComp.IVKardex(k).CostoRealTotal)
                            End If
                            Venta = Venta + Abs(objGNComp.IVKardex(k).PrecioRealTotal)
                            rs.Close
                            Set rs = Nothing
                        End If
                    Next
                        .PrintLine .Rellenar(Format(Venta - Costo, fmt), lon, False)
        Case "NUMTRANSDER":
            .PrintLine .Rellenar(Right(objGNComp.NumTrans, lon), lon, True) 'AUC 30/01/08 Imprime los dos ultimos caracteres del numtrans desde la derecha
        Case "OBSPROVCLI":
            If UBound(v, 1) > 1 Then
                Select Case v(2)
                Case 1
                        If Len(objGNComp.ObservacionImpExp) > (v(1) * v(2)) Then
                            .PrintLine .Rellenar(Mid$(objGNComp.ObservacionImpExp, 1, v(1)), lon, True)
                        Else
                            .PrintLine .Rellenar(objGNComp.ObservacionImpExp, lon, True)
                        End If
                Case Else
                        If Len(objGNComp.ObservacionImpExp) > (v(1) * v(2)) Then
                            .PrintLine .Rellenar(Mid$(objGNComp.ObservacionImpExp, v(1) + 1, v(1) * v(2)), lon, True)
                        Else
                            .PrintLine .Rellenar(Mid$(objGNComp.ObservacionImpExp, v(1) * (v(2) - 1) + 1, Len(objGNComp.ObservacionImpExp) - v(1)), lon, True)
                        End If
                End Select
            Else
                .PrintLine .Rellenar(objGNComp.ObservacionImpExp, lon, True)
            End If
        Case "FORMAENVIO": .PrintLine .Rellenar(objGNComp.FormaEnvio, lon, True)
        Case "CONSIGNATARIO":
            If UBound(v, 1) > 1 Then
                Select Case v(2)
                Case 1
                        If Len(objGNComp.ObservacionImpExp) > (v(1) * v(2)) Then
                            .PrintLine .Rellenar(Mid$(objGNComp.Consignatario, 1, v(1)), lon, True)
                        Else
                            .PrintLine .Rellenar(objGNComp.Consignatario, lon, True)
                        End If
                Case Else
                        If Len(objGNComp.ObservacionImpExp) > (v(1) * v(2)) Then
                            .PrintLine .Rellenar(Mid$(objGNComp.Consignatario, v(1) + 1, v(1) * v(2)), lon, True)
                        Else
                            .PrintLine .Rellenar(Mid$(objGNComp.Consignatario, v(1) * (v(2) - 1) + 1, Len(objGNComp.Consignatario) - v(1)), lon, True)
                        End If
                End Select
            Else
                .PrintLine .Rellenar(objGNComp.Consignatario, lon, True)
            End If
            
        Case "PESOBRUTO": .PrintLine .Rellenar(objGNComp.PesoBruto, lon, True)
        Case "PESONETO": .PrintLine .Rellenar(objGNComp.PesoNeto, lon, True)
        Case "REFERENCIA": .PrintLine .Rellenar(objGNComp.Referencia, lon, True)
            If UBound(v, 1) > 1 Then
                Select Case v(2)
                Case 1
                        If Len(objGNComp.Referencia) > (v(1) * v(2)) Then
                            .PrintLine .Rellenar(Mid$(objGNComp.Referencia, 1, v(1)), lon, True)
                        Else
                            .PrintLine .Rellenar(objGNComp.Referencia, lon, True)
                        End If
                Case Else
                        If Len(objGNComp.Referencia) > (v(1) * v(2)) Then
                            .PrintLine .Rellenar(Mid$(objGNComp.Referencia, v(1) + 1, v(1) * v(2)), lon, True)
                        Else
                        
                            .PrintLine .Rellenar(Mid$(objGNComp.Referencia, v(1) * (v(2) - 1) + 1, Len(objGNComp.Referencia) - v(1)), lon, True)
                        End If
                End Select
            Else
                .PrintLine .Rellenar(objGNComp.Referencia, lon, True)
            End If
        
        Case "SUBTOTALIVGRUPO"  'jeaa 01-08-2008
            Venta = 0
             For k = 1 To objGNComp.CountIVKardex
                Set ITEM = objGNComp.Empresa.RecuperaIVInventario(objGNComp.IVKardex(k).CodInventario)
                If v(4) = ITEM.codGrupo(CDbl(v(3))) Then
                 Venta = Venta + (objGNComp.IVKardex(k).PrecioRealTotal * -1)
                End If
            Next
            .PrintLine .Rellenar(Format(Venta, fmt), lon, False)
        Case "PC_TOTALANTICIPOS":        '**********  TOTAL ANTICIPOS
                    Set rs = New Recordset
                    If Not (cli Is Nothing) Then
                        codigo = cli.CodProvCli
                        Set rs = objGNComp.Empresa.ConsPCSaldoconF_CortexProvcli(cli.BandProveedor, cli.BandCliente, cli.CodProvCli, 1, objGNComp.FechaTrans)
                    Else
                        If Not (prov Is Nothing) Then
                            codigo = prov.CodProvCli
                            Set rs = objGNComp.Empresa.ConsPCSaldoconF_CortexProvcli(prov.BandProveedor, prov.BandCliente, prov.CodProvCli, 1, objGNComp.FechaTrans)
                        End If
                     End If
                    If Not rs.EOF Then
                        .PrintLine .Rellenar(Format(rs.Fields("saldo"), fmt), lon, False) ' 05-08-04 SALDO TOTAL X PAGAR DEL CLEIENTE
                    Else
                        .PrintLine .Rellenar(Format(0, fmt), lon, False)   ' 05-08-04 SALDO TOTAL VENCIDO X PAGAR DEL CLEIENTE
                    End If
                    rs.Close
                    Set rs = Nothing
        Case "PORCENTAJEIVA":
            If objGNComp.PorcentIVA = 0 Then
                .PrintLine .Rellenar(objGNComp.Empresa.GNOpcion.PorcentajeIVA * 100, lon, True) 'JEAA 11/06/2007
            Else
                .PrintLine .Rellenar(objGNComp.PorcentIVA * 100, lon, True) 'JEAA 11/06/2007
            End If
        Case "NUMTRANSAFECTASRI"
            Set GnComp = objGNComp.Empresa.RecuperaGNComprobante(objGNComp.IdTransFuente)
            If Not GnComp Is Nothing Then
                num = CStr(GnComp.NumTrans)
                While Len(num) < 9
                    num = "0" & num
                Wend
                
                num = GnComp.NumSerieEstaSRI & GnComp.GNTrans.NumSeriePunto & num
                .PrintLine .Rellenar(num, lon, True)
            End If
            Set GnComp = Nothing
        Case "CODTIPOTRANSAFECTASRI"
            'Dim num As String
            Set GnComp = objGNComp.Empresa.RecuperaGNComprobante(objGNComp.IdTransFuente)
            If Not GnComp Is Nothing Then
                num = GnComp.GNTrans.TipoTrans
                If Len(num) = 1 Then num = "0" & num
                .PrintLine .Rellenar(num, lon, True)
            End If
            Set GnComp = Nothing
        Case "DESCTIPOTRANSAFECTASRI"
            Dim TipoComp As Anexos
            Set GnComp = objGNComp.Empresa.RecuperaGNComprobante(objGNComp.IdTransFuente)
            If Not GnComp Is Nothing Then
                Set TipoComp = objGNComp.Empresa.RecuperaAnexos(GnComp.GNTrans.TipoTrans)
                If Not TipoComp Is Nothing Then
                    .PrintLine .Rellenar(TipoComp.Descripcion, lon, True)
                End If
            End If
            Set GnComp = Nothing
        Case "AUTORIZATRANSAFECTASRI"
            Set GnComp = objGNComp.Empresa.RecuperaGNComprobante(objGNComp.IdTransFuente)
            If Not GnComp Is Nothing Then
                If GnComp.GNTrans.IVComprobanteElectronico Then
                    .PrintLine .Rellenar(GnComp.NumeroAutorizacion, lon, True)
                Else
                    .PrintLine .Rellenar(GnComp.NumAutSRI, lon, True)
                End If
            End If
            Set GnComp = Nothing
        
        Case "FECHACADTRANSAFECTASRI"
            Set GnComp = objGNComp.Empresa.RecuperaGNComprobante(objGNComp.IdTransFuente)
            If Not GnComp Is Nothing Then
                    .PrintLine .Rellenar(Format(GnComp.FechaCaducidadSRI, fmt), lon, True)
            End If
            Set GnComp = Nothing
        
        Case "FECHATRANSAFECTASRI"
            Set GnComp = objGNComp.Empresa.RecuperaGNComprobante(objGNComp.IdTransFuente)
            If Not GnComp Is Nothing Then
                    .PrintLine .Rellenar(Format(GnComp.FechaTrans, fmt), lon, True)
            End If
            Set GnComp = Nothing
        
        
        Case "CODGAR", "NOMGAR", "TELGAR", "RUCGAR", "DIRGAR", "CIUGAR", _
               "PCGCODGRUPO1", "PCGDESGRUPO1", "PCGCODGRUPO2", "PCGDESGRUPO2", _
                "PCGCODGRUPO3", "PCGDESGRUPO3", "PCGCODGRUPO4", "PCGDESGRUPO4", _
                "TELGAR2", "TELGAR3", "FAXGAR", "DIRGAR2", "CODPOSTALGAR", "CIUGAR", _
                "PROVINGAR", "PAISGAR", "AUTSRIGAR", "BANCOGAR", "NUMCUEGAR", "NOMALTGAR", _
                "PCSALDOTOTAL", "NOMALTGAR", "PCCODGRUPO4", "PCDESGRUPO4", "CANTONGAR", "PARRGAR", "GARACTIVIDAD", _
                "GARNOMTRAB", "GARDIRTRAB", "GARTELTRAB", "GARANTTRAB", "GARINGRESOS"

            If Not (Gar Is Nothing) Then
                Select Case v(0)
                  'Modificado Alex/22/11/01 ==> para colocar datos de GARente consumidor final
                Case "CODGAR":   .PrintLine .Rellenar(Gar.CodProvCli, lon, True)
                Case "NOMGAR": .PrintLine .Rellenar(IIf(CF, objGNComp.Nombre, Gar.Nombre), lon, True)
                'AUC 18/05/07 desde aqui
                Case "NOMALTGAR": .PrintLine .Rellenar(Gar.NombreAlterno, lon, True)
                Case "TELGAR2": .PrintLine .Rellenar(Gar.Telefono2, lon, True)
                Case "TELGAR3": .PrintLine .Rellenar(Gar.Telefono3, lon, True)
                Case "FAXGAR": .PrintLine .Rellenar(Gar.Fax, lon, True)
                Case "DIRGAR2": .PrintLine .Rellenar(Gar.Direccion2, lon, True)
                Case "CODPOSTALGAR": .PrintLine .Rellenar(Gar.CodPostal, lon, True)
                Case "CIUGAR": .PrintLine .Rellenar(Gar.ciudad, lon, True)
                Case "PROVINGAR": .PrintLine .Rellenar(Gar.Provincia, lon, True)
                Case "PAISGAR": .PrintLine .Rellenar(Gar.Pais, lon, True)
                Case "AUTSRIGAR": .PrintLine .Rellenar(Gar.NumAutSRI, lon, True)
                Case "BANCOGAR": .PrintLine .Rellenar(Gar.Banco, lon, True)
                Case "NUMCUEGAR": .PrintLine .Rellenar(Gar.NumCuenta, lon, True)
               Case "TELGAR":
                  If CF Then
                    .PrintLine .Rellenar(objGNComp.telefono, lon, True)
                  Else
                    .PrintLine .Rellenar(Gar.Telefono1, lon, True)
                  End If
                Case "RUCGAR":
                    If CF Then
                        .PrintLine .Rellenar(objGNComp.RUC, lon, True)
                    Else
                        .PrintLine .Rellenar(Gar.RUC, lon, True)
                    End If
                Case "DIRGAR":
                  If CF Then
                        .PrintLine .Rellenar(objGNComp.direccion, lon, True)
                  Else
                    .PrintLine .Rellenar(Gar.Direccion1, lon, True)
                  End If
                Case "CIUGAR":
                  If CF Then
                    If Not IsEmpty(v1) Then
                        If UBound(v1, 1) > 2 Then .PrintLine .Rellenar(v1(3), lon, True)
                    End If
                  Else
                    .PrintLine .Rellenar(Gar.ciudad, lon, True)
                  End If
                Case "FAXGAR":
                  If CF Then
                    If Not IsEmpty(v1) Then
                        If UBound(v1, 1) > 2 Then .PrintLine .Rellenar(v1(3), lon, True)
                    End If
                  Else
                    .PrintLine .Rellenar(Gar.Fax, lon, True)
                  End If
                
                Case "PCGCODGRUPO1":    ' JEAA 17/09/2003 codigo gupo de PCGRUPO1
                  If Not CF Then
                        Set Grupo = objGNComp.Empresa.RecuperaPCGrupo(1, Gar.IdGrupo1)  ' ************** JEAA 17-09-2003
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.codGrupo, lon, True)
                        End If
                  End If
                  
            Case "PCGCODGRUPO2":    ' JEAA 17/09/2003 codigo gupo de PCGRUPO2
                  If Not CF Then
                        Set Grupo = objGNComp.Empresa.RecuperaPCGrupo(2, Gar.IdGrupo2)  ' ************** JEAA 17-09-2003
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.codGrupo, lon, True)
                        End If
                  End If
                  
            Case "PCGCODGRUPO3":    ' JEAA 17/09/2003 codigo gupo de PCGRUPO3
                  If Not CF Then
                        Set Grupo = objGNComp.Empresa.RecuperaPCGrupo(3, Gar.IdGrupo3)  ' ************** JEAA 17-09-2003
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.codGrupo, lon, True)
                        End If
                  End If
            Case "PCGCODGRUPO4":    ' JEAA 17/09/2003 codigo gupo de PCGRUPO3
                  If Not CF Then
                        Set Grupo = objGNComp.Empresa.RecuperaPCGrupo(4, Gar.IdGrupo4)  ' ************** JEAA 17-09-2003
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.codGrupo, lon, True)
                        End If
                  End If
                Case "PCGDESGRUPO1":    ' JEAA 17/09/2003 descripcion gupo de PCGRUPO1
                  If Not CF Then
                        Set Grupo = objGNComp.Empresa.RecuperaPCGrupo(1, Gar.IdGrupo1)  ' ************** JEAA 17-09-2003
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.Descripcion, lon, True)
                        End If
                  End If
                Case "PCGDESGRUPO2":    ' JEAA 17/09/2003 descripcion gupo de PCGRUPO2
                  If Not CF Then
                        Set Grupo = objGNComp.Empresa.RecuperaPCGrupo(2, Gar.IdGrupo2)  ' ************** JEAA 17-09-2003
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.Descripcion, lon, True)
                        End If
                  End If
                Case "PCGDESGRUPO3":    ' JEAA 17/09/2003 descripcion gupo de PCGRUPO3
                  If Not CF Then
                        Set Grupo = objGNComp.Empresa.RecuperaPCGrupo(3, Gar.IdGrupo3)  ' ************** JEAA 17-09-2003
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.Descripcion, lon, True)
                        End If
                  End If
            Case "PCGDESGRUPO4":    ' JEAA 18/05/2006 descripcion gupo de PCGRUPO3
                  If Not CF Then
                        Set Grupo = objGNComp.Empresa.RecuperaPCGrupo(4, Gar.IdGrupo4)  ' ************** JEAA 17-09-2003
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.Descripcion, lon, True)
                        End If
                  End If
                'AUC 18/05/07 desde aqui
                Case "NOMALTGAR": .PrintLine .Rellenar(Gar.NombreAlterno, lon, True)
                Case "TELGAR2": .PrintLine .Rellenar(Gar.Telefono2, lon, True)
                Case "TELGAR3": .PrintLine .Rellenar(Gar.Telefono3, lon, True)
                Case "FAXGAR": .PrintLine .Rellenar(Gar.Fax, lon, True)
                Case "DIRGAR2": .PrintLine .Rellenar(Gar.Direccion2, lon, True)
                Case "CODPOSTALGAR": .PrintLine .Rellenar(Gar.CodPostal, lon, True)
                Case "CIUGAR": .PrintLine .Rellenar(Gar.ciudad, lon, True)
                'Case "PROVINGAR": .PrintLine .Rellenar(Gar.Provincia, lon, True)
                Case "PAISGAR": .PrintLine .Rellenar(Gar.Pais, lon, True)
                Case "AUTSRIGAR": .PrintLine .Rellenar(Gar.NumAutSRI, lon, True)
                Case "BANCOGAR": .PrintLine .Rellenar(Gar.Banco, lon, True)
                Case "NUMCUEGAR": .PrintLine .Rellenar(Gar.NumCuenta, lon, True)
                Case "CANTONGAR":
                        Set GARCANTON = objGNComp.Empresa.RecuperaPCCanton(Gar.IdCanton)    ' ************** JEAA 17-09-2003
                        If Not GARCANTON Is Nothing Then
                            .PrintLine .Rellenar(GARCANTON.Descripcion, lon, True)
                        End If
                        Set GARCANTON = Nothing
                Case "PROVINGAR":
                        Set GARPROV = objGNComp.Empresa.RecuperaPCProvincia(Gar.IdProvincia)  ' ************** JEAA 17-09-2003
                        If Not GARPROV Is Nothing Then
                            .PrintLine .Rellenar(GARPROV.Descripcion, lon, True)
                        End If
                        Set GARPROV = Nothing
                Case "PARRGAR":
                        Set GARParr = objGNComp.Empresa.RecuperaPCParroquia(Gar.IdProvincia)
                        If Not GARParr Is Nothing Then
                            .PrintLine .Rellenar(GARParr.Descripcion, lon, True)
                        End If
                        Set GARParr = Nothing
                Case "GARACTIVIDAD":
                        If Not GarAct Is Nothing Then .PrintLine .Rellenar(GarAct.ActividadSoli, lon, True)
                Case "GARNOMTRAB":
                    If Not GarAct Is Nothing Then .PrintLine .Rellenar(GarAct.NombreTrabajoSoli, lon, True)
                Case "GARDIRTRAB":
                    If Not GarAct Is Nothing Then .PrintLine .Rellenar(GarAct.DirTrabajoSoli, lon, True)
                Case "GARTELTRAB":
                    If Not GarAct Is Nothing Then .PrintLine .Rellenar(GarAct.TelfActividadSol, lon, True)
                Case "GARANTTRAB":
                    If Not GarAct Is Nothing Then .PrintLine .Rellenar(GarAct.AntiguedadSoli, lon, True)           '----
                Case "GARINGRESOS": If Not GarAct Is Nothing Then .PrintLine .Rellenar(GarAct.IngresosSoli, lon, True)
                
                
                'hasta aqui
            End Select
        End If
        Case "NOMSUC":
            Set trans = objGNComp.Empresa.RecuperaGNTrans(objGNComp.CodTrans)   ' ************** JEAA 20-8-03
            Set SUC = objGNComp.Empresa.RecuperaGNSucursal(trans.CodSucursal)   ' ************** JEAA 20-8-03
            If Not SUC Is Nothing Then
                .PrintLine .Rellenar(SUC.Nombre, lon, True)
            Else
                .PrintLine .Rellenar("", lon, True)
            End If
            Set trans = Nothing
            Set SUC = Nothing
        Case "CODSUC":
            Set trans = objGNComp.Empresa.RecuperaGNTrans(objGNComp.CodTrans)   ' ************** JEAA 20-8-03
            Set SUC = objGNComp.Empresa.RecuperaGNSucursal(trans.CodSucursal)   ' ************** JEAA 20-8-03
            If Not SUC Is Nothing Then
                .PrintLine .Rellenar(SUC.CodSucursal, lon, True)
            Else
                .PrintLine .Rellenar("", lon, True)
            End If
            Set trans = Nothing
            Set SUC = Nothing
        
        Case "DIRSUC":
            Set trans = objGNComp.Empresa.RecuperaGNTrans(objGNComp.CodTrans)   ' ************** JEAA 20-8-03
            Set SUC = objGNComp.Empresa.RecuperaGNSucursal(trans.CodSucursal)   ' ************** JEAA 20-8-03
            If Not SUC Is Nothing Then
                .PrintLine .Rellenar(SUC.direccion, lon, True)
            Else
                .PrintLine .Rellenar("", lon, True)
            End If
            Set trans = Nothing
            Set SUC = Nothing
        Case "TELFSUC":
            Set trans = objGNComp.Empresa.RecuperaGNTrans(objGNComp.CodTrans)   ' ************** JEAA 20-8-03
            Set SUC = objGNComp.Empresa.RecuperaGNSucursal(trans.CodSucursal)   ' ************** JEAA 20-8-03
            If Not SUC Is Nothing Then
                .PrintLine .Rellenar(SUC.telefono, lon, True)
            Else
                .PrintLine .Rellenar("", lon, True)
            End If
            Set trans = Nothing
            Set SUC = Nothing
        Case "DETALLETRANSIV":
            Set rsdet = objGNComp.Empresa.RecuperaDetalleTransIV(objGNComp.FechaTrans, objGNComp.CodUsuario)
            If rsdet.RecordCount > 0 Then
                For i = 1 To rsdet.RecordCount
                    cad = rsdet.Fields("codtrans")
                    cad = cad & Space(10 - Len(rsdet.Fields("codtrans"))) & rsdet.Fields("cantidad")
                    cad = cad & Space(10 - Len(rsdet.Fields("cantidad"))) & rsdet.Fields("inicio")
                    cad = cad & Space(10 - Len(rsdet.Fields("inicio"))) & rsdet.Fields("fin")
                    .PrintLine .Rellenar(cad, lon, True)
                    rsdet.MoveNext
                Next i
            End If
        Case "DETALLES":
            If UBound(v, 1) > 1 Then
                Select Case v(2)
                Case 1
                        If Len(objGNComp.Detalles) > (v(1) * v(2)) Then
                            .PrintLine .Rellenar(Mid$(objGNComp.Detalles, 1, v(1)), lon, True)
                        Else
                            .PrintLine .Rellenar(objGNComp.Detalles, lon, True)
                        End If
                Case Else
                        If Len(objGNComp.ObservacionImpExp) > (v(1) * v(2)) Then
                            .PrintLine .Rellenar(Mid$(objGNComp.Detalles, v(1) + 1, v(1) * v(2)), lon, True)
                        Else
                            .PrintLine .Rellenar(Mid$(objGNComp.Detalles, v(1) * (v(2) - 1) + 1, Len(objGNComp.Detalles) - v(1)), lon, True)
                        End If
                End Select
            Else
                .PrintLine .Rellenar(objGNComp.Detalles, lon, True)
            End If
        Case "FECHAVALIDEZ":        .PrintLine .Rellenar(Format(objGNComp.FechaValidez, fmt), lon, True)
        Case "ATENCION":    .PrintLine .Rellenar(objGNComp.Atencion, lon, True)
        Case "TRANSFUENTE"
            Set gc = objGNComp.Empresa.RecuperaGNComprobante(objGNComp.IdTransFuente)
            If Not gc Is Nothing Then
                    .PrintLine .Rellenar(gc.CodTrans & "-" & gc.NumTrans, lon, True)
            End If
            Set gc = Nothing
        Case "PCCANTON":    ' JEAA 17/09/2003 descripcion gupo de PCGRUPO4
            Set CANTON = objGNComp.Empresa.RecuperaPCCanton(cli.IdCanton)   ' ************** JEAA 17-09-2003
            If Not CANTON Is Nothing Then
                .PrintLine .Rellenar(CANTON.Descripcion, lon, True)
            End If
            Set CANTON = Nothing
        Case "PCPROVINCIA":    ' JEAA 17/09/2003 descripcion gupo de PCGRUPO4
            Set pcPROV = objGNComp.Empresa.RecuperaPCProvincia(cli.IdProvincia)   ' ************** JEAA 17-09-2003
            If Not pcPROV Is Nothing Then
                .PrintLine .Rellenar(pcPROV.Descripcion, lon, True)
            End If
        Set pcPROV = Nothing
        'AUC imprime todo por cobrar en una linea
        Case "CTSXCOBRAR"
            '.PrintLine .Rellenar(objGNComp.PCkarderDebeTotalLin(cod), lon, True)
             .PrintLine .Rellenar(objGNComp.PCkarderDebeTotalLin(""), lon, True)
        Case "CODSUCFUENTE":
            If objGNComp.IdTransFuente <> 0 Then
                .PrintLine .Rellenar(TransFuente(objGNComp, "CODSUCURSAL"), lon, True) '14/05/2001  Angel P.
            Else
                .PrintLine .Rellenar(objGNComp.GNTrans.CodSucursal, lon, True) '14/05/2001  Angel P.
            End If
        Case "NOMSUCFUENTE":
            If objGNComp.IdTransFuente <> 0 Then
                .PrintLine .Rellenar(TransFuente(objGNComp, "NOMSUCURSAL"), lon, True) '14/05/2001  Angel P.
            Else
                Set SUC = objGNComp.Empresa.RecuperaGNSucursal(objGNComp.GNTrans.CodSucursal)
                If Not SUC Is Nothing Then
                    .PrintLine .Rellenar(SUC.Nombre, lon, True) '14/05/2001  Angel P.
                End If
                Set SUC = Nothing
            End If
        Case "PORRECAR":        'recargo  especificado con  codigo
                .PrintLine .Rellenar(Format(Abs(PorcentajeRecargo(objGNComp, cod)), fmt), lon, False)
        Case "PLACA", "DESCVEHICULO", "VCODGRUPO1", "VCODGRUPO2", "VCODGRUPO3", "VCODGRUPO4", "VDESCGRUPO1", "VDESCGRUPO2", "VDESCGRUPO3", "VDESCGRUPO4"
            If Len(objGNComp.idCentros) = 0 Then
                Set centro = objGNComp.Empresa.RecuperaGNCentroCosto(objGNComp.CodCentro)
                If Not centro Is Nothing Then
                    Set gnv = objGNComp.Empresa.RecuperaGNVehiculo(centro.CodVehiculo)
                End If
            Else
                idvehi = objGNComp.Empresa.ObtieneVehiculodeunMismoCC(objGNComp.idCentros)
                Set gnv = objGNComp.Empresa.RecuperaGNVehiculo(idvehi)
            End If
            If Not gnv Is Nothing Then
                Select Case v(0)
                    Case "PLACA":  .PrintLine .Rellenar(gnv.CodVehiculo, lon, True)
                    Case "DESCVEHICULO": .PrintLine .Rellenar(gnv.Descripcion, lon, True)
                    Case "VCODGRUPO1"
                        Set vGrupo = objGNComp.Empresa.RecuperaGNVGrupo(1, gnv.IdGrupo(1))
                        If Not vGrupo Is Nothing Then
                            .PrintLine .Rellenar(vGrupo.codGrupo, lon, True)
                        End If
                        Set vGrupo = Nothing
                    Case "VCODGRUPO2"
                        Set vGrupo = objGNComp.Empresa.RecuperaGNVGrupo(2, gnv.IdGrupo(2))
                        If Not vGrupo Is Nothing Then
                            .PrintLine .Rellenar(vGrupo.codGrupo, lon, True)
                        End If
                        Set vGrupo = Nothing
                    Case "VCODGRUPO3"
                        Set vGrupo = objGNComp.Empresa.RecuperaGNVGrupo(3, gnv.IdGrupo(3))
                        If Not vGrupo Is Nothing Then
                            .PrintLine .Rellenar(vGrupo.codGrupo, lon, True)
                        End If
                        Set vGrupo = Nothing
                    Case "VCODGRUPO4"
                        Set vGrupo = objGNComp.Empresa.RecuperaGNVGrupo(4, gnv.IdGrupo(4))
                        If Not vGrupo Is Nothing Then
                            .PrintLine .Rellenar(vGrupo.codGrupo, lon, True)
                        End If
                        Set vGrupo = Nothing
                    Case "VDESCGRUPO1"
                        Set vGrupo = objGNComp.Empresa.RecuperaGNVGrupo(1, gnv.IdGrupo(1))
                        If Not vGrupo Is Nothing Then
                            .PrintLine .Rellenar(vGrupo.Descripcion, lon, True)
                        End If
                        Set vGrupo = Nothing
                    Case "VDESCGRUPO2"
                        Set vGrupo = objGNComp.Empresa.RecuperaGNVGrupo(2, gnv.IdGrupo(2))
                        If Not vGrupo Is Nothing Then
                            .PrintLine .Rellenar(vGrupo.Descripcion, lon, True)
                        End If
                        Set vGrupo = Nothing
                    Case "VDESCGRUPO3"
                        Set vGrupo = objGNComp.Empresa.RecuperaGNVGrupo(3, gnv.IdGrupo(3))
                        If Not vGrupo Is Nothing Then
                            .PrintLine .Rellenar(vGrupo.Descripcion, lon, True)
                        End If
                        Set vGrupo = Nothing
                    Case "VDESCGRUPO4"
                        Set vGrupo = objGNComp.Empresa.RecuperaGNVGrupo(4, gnv.IdGrupo(4))
                        If Not vGrupo Is Nothing Then
                            .PrintLine .Rellenar(vGrupo.Descripcion, lon, True)
                        End If
                        Set vGrupo = Nothing
                   
                End Select
            End If
            Set gnv = Nothing
            'End If
            Set centro = Nothing
        Case "CODZONA"
            .PrintLine .Rellenar(objGNComp.CodZona, lon, True)
        Case "TSVALORSIS" 'AUC total de los valores del tsresumen
                .PrintLine .Rellenar(objGNComp.TSResumenTotal(True), lon, True)
        Case "TSVALORDOC"
            .PrintLine .Rellenar(objGNComp.TSResumenTotal(False), lon, True)
        Case "DESCCENTROHIJO"
            Set centroHijo = objGNComp.Empresa.RecuperaGNCentroCostoHijo(objGNComp.CodCentroHijo)
            If Not centroHijo Is Nothing Then
                .PrintLine .Rellenar(centroHijo.Descripcion, lon, True)
            End If
            Set centroHijo = Nothing
        Case "NECESITATRANSPORTE":
            If objGNComp.Estado1 = "11" Then
                Texto = "SI"
            Else
                Texto = "NO"
            End If
                .PrintLine .Rellenar(Texto, lon, True)
        Case "DIRTRANSPORTE":
                    If objGNComp.Estado1 = "11" Then
                        If UBound(v) = 3 Then
                            Texto = v(3)
                        Else
                            Texto = objGNComp.DirTransporte
                        End If
                    Else
                        If UBound(v) > 1 Then Texto = v(2)
                    End If
                    .PrintLine .Rellenar(Texto, lon, True)
        Case "CODAGE"
            If Not pca Is Nothing Then
                .PrintLine .Rellenar(pca.CodAgencia, lon, True)
            Else
                .PrintLine .Rellenar("", lon, True)
            End If
        Case "DESCAGE"
            If Not pca Is Nothing Then
                .PrintLine .Rellenar(pca.Descripcion, lon, True)
            Else
                .PrintLine .Rellenar("", lon, True)
            End If
        Case "DIRAGE"
            If Not pca Is Nothing Then
                .PrintLine .Rellenar(pca.direccion, lon, True)
            Else
                .PrintLine .Rellenar("", lon, True)
            End If
        Case "TELAGE"
            If Not pca Is Nothing Then
                .PrintLine .Rellenar(pca.telefono, lon, True)
            Else
                .PrintLine .Rellenar("", lon, True)
            End If
        Case "CIUDADAGE"
            If Not pca Is Nothing Then
                Set CANTON = objGNComp.Empresa.RecuperaPCCanton(pca.ciudad)
                    If Not CANTON Is Nothing Then
                        .PrintLine .Rellenar(CANTON.Descripcion, lon, True)
                    End If
            Else
                       .PrintLine .Rellenar("", lon, True)
            End If
                
        Case "CONTACTOAGE"
            If Not pca Is Nothing Then
                .PrintLine .Rellenar(pca.contacto, lon, True)
            Else
                .PrintLine .Rellenar("", lon, True)
            End If
        Case "NOMEMPLEADO"
                Set e = objGNComp.Empresa.RecuperaEmpleado(objGNComp.CodEmpleadoRef)
                If Not e Is Nothing Then
                    .PrintLine .Rellenar(e.Nombre, lon, True)
                Else
                    .PrintLine .Rellenar("", lon, True)
                End If
                Set e = Nothing
        Case "CODFORMA"
            .PrintLine .Rellenar(objGNComp.codForma, lon, True)
        Case "DESCFORMA"
            Set Forma = objGNComp.Empresa.RecuperaTSFormaCobroPago(objGNComp.codForma)
            If Not Forma Is Nothing Then
                .PrintLine .Rellenar(Forma.NombreForma, lon, True)
            Else
                .PrintLine .Rellenar("", lon, True)
            End If
            Set Forma = Nothing
         Case "TASAMENSUAL"
            .PrintLine .Rellenar(objGNComp.TasaMensual, lon, True)
        Case "TASAANUAL"
            .PrintLine .Rellenar(objGNComp.TasaAnual, lon, True)
        Case "NUMPAGOS"
            .PrintLine .Rellenar(objGNComp.NumeroPagos, lon, True)
        Case "NUMCUOTASAMORT"
            .PrintLine .Rellenar(objGNComp.NumCoutasAmort, lon, True)
            
        Case "FECHAPRICUOTA" 'fecha primera cuota
            .PrintLine .Rellenar(Format(objGNComp.PCkarderFechaPriUltCuota(True, v(3)), fmt), lon, True)
        Case "FECHAULTCUOTA" ' fecha ultima cuota
            .PrintLine .Rellenar(Format(IIf(objGNComp.PCkarderFechaPriUltCuota(False, v(3)) = "00:00:00", objGNComp.FechaTrans, objGNComp.PCkarderFechaPriUltCuota(False, v(3))), fmt), lon, True)
      Case "CTSXCOBRARLETRAS" 'capital interes
            s = objGNComp.PCkarderDebePorLineas(v(2), v(1))
            For X = 1 To Len(s)
                If i = lon Then
                    If X - 1 > i Then
                        .PrintLine Space(v(3))
                        .PrintLine .Rellenar(cadL, lon, True)
                    Else
                        .PrintLine .Rellenar(cadL, lon, True)
                        X = X - 1
                    End If
                    cadL = ""
                    .PrintLine "", 1    'cambio de linea
                    i = 0
                Else
                    cadL = cadL & Mid$(s, X, 1)
                End If
                i = i + 1
            Next
            If Len(cadL) > 0 Then
               .PrintLine Space(v(3))
               .PrintLine .Rellenar(cadL, lon, True)
            End If
        Case "CLAVEACCESO"
            .PrintLine .Rellenar(objGNComp.ClaveAcceso, lon, True)
        Case "NUMEROAUTORIZACION"
            .PrintLine .Rellenar(objGNComp.NumeroAutorizacion, lon, True)
        Case "FECHAAUTORIZACION"
            .PrintLine .Rellenar(objGNComp.FechaAutorizacion, lon, True)
        Case "TIPOEMISION"
            If objGNComp.TipoEmision = "1" Then
                cadena = "NORMAL"
            ElseIf objGNComp.TipoEmision = "2" Then
                cadena = "CONTINGENCIA"
            End If
            .PrintLine .Rellenar(cadena, lon, True)
        Case "TIPOAMBIENTE":
            If objGNComp.TipoAmbiente = "1" Then
                cadena = "PRUEBA"
            ElseIf objGNComp.TipoAmbiente = "2" Then
                cadena = "PRODUCCION"
            End If
            .PrintLine .Rellenar(cadena, lon, True)
        Case "CODIGOCOMPROBANTE"
            Set trans = objGNComp.Empresa.RecuperaGNTrans(objGNComp.CodTrans)   ' ************** JEAA 20-8-03
            If trans.TipoTrans = "1" Then
                cadena = "FACTURA No."
            ElseIf trans.TipoTrans = "4" Then
                cadena = "NOTA DE CREDITO No."
            ElseIf trans.TipoTrans = "5" Then
                cadena = "NOTA DE DEBITO No."
            Else
                cadena = "RETENCION No."
            End If
            .PrintLine .Rellenar(cadena, lon, True)
            Set trans = Nothing
        Case "TIPOEMPRESA"
            Select Case objGNComp.Empresa.GNOpcion.TipoEmpresaSRI
                Case "CE"
                    cadena = "CONTRIBUYENTE ESPECIAL"
                Case "SC"
                    cadena = "OBLIGADA A LLEVAR CONTABILIDAD"
            End Select
            .PrintLine .Rellenar(cadena, lon, True)
        Case "RESOLUCION"
            cadena = objGNComp.Empresa.GNOpcion.Resolucion
            .PrintLine .Rellenar(cadena, lon, True)
        Case "ARANCELPESO":    .PrintLine .Rellenar(objGNComp.Atencion, lon, True)
        Case "ARANCELNUMPAQ":    .PrintLine .Rellenar(objGNComp.FormaPago, lon, True)
        Case "ARANCELPARTIDA":    .PrintLine .Rellenar(objGNComp.TiempoEntrega, lon, True)
        Case "SOLIDOS"
                .PrintLine .Rellenar(Format(Abs(objGNComp.Solidos), fmt), lon, False)
        Case "LACTASA"
                .PrintLine .Rellenar(Format(Abs(objGNComp.Lactasa), fmt), lon, False)
        Case "ACIDEZ"
                .PrintLine .Rellenar(Format(Abs(objGNComp.Acidez), fmt), lon, False)
        Case "ALCOHOL"
                .PrintLine .Rellenar(Format(Abs(objGNComp.Alcohol), fmt), lon, False)
        Case "FILTRADO"
                .PrintLine .Rellenar(Format(Abs(objGNComp.Filtrado), fmt), lon, False)
        Case "TEMPERATURA"
                .PrintLine .Rellenar(Format(Abs(objGNComp.Temperatura), fmt), lon, False)
                
        Case "PH"
                .PrintLine .Rellenar(Format(Abs(objGNComp.PH), fmt), lon, False)
        Case "GRASA"
                .PrintLine .Rellenar(Format(Abs(objGNComp.Grasa), fmt), lon, False)
        Case "PROTEINA"
                .PrintLine .Rellenar(Format(Abs(objGNComp.Proteina), fmt), lon, False)
        Case "AGUA"
                .PrintLine .Rellenar(Format(Abs(objGNComp.Agua), fmt), lon, False)
        Case "QUIO"
                .PrintLine .Rellenar(Format(Abs(objGNComp.QUIO), fmt), lon, False)
        Case "REDUC"
                .PrintLine .Rellenar(Format(Abs(objGNComp.Reduccion), fmt), lon, False)
        Case "MERMA"
                .PrintLine .Rellenar(Format(Abs(objGNComp.Merma), fmt), lon, False)
        Case "HORALLEGADA"
                '.PrintLine .Rellenar(Format(objGNComp.HoraLlegada, fmt), lon, False)
                .PrintLine .Rellenar(Format(objGNComp.HoraMarcada, fmt), lon, False) 'AUC Cambiado para que imp el detalle de la hora maracada
        Case "TRANSPORTISTA"
                .PrintLine .Rellenar(objGNComp.CodTransportista, lon, True)
        Case "NOMBRETRANSPORTISTA"
                Set pctranspor = objGNComp.Empresa.RecuperaPCProvCli(objGNComp.CodTransportista)
                .PrintLine .Rellenar(pctranspor.Nombre, lon, True)
                Set pctranspor = Nothing
    'DATOS GUIA
    Case "FECHAINICIOGUIA", "FECHAINITRANSP"
                .PrintLine .Rellenar(objGNComp.FechaInicio, lon, True)
    Case "FECHAFINGUIA", "FECHAFINTRANSP"
                .PrintLine .Rellenar(objGNComp.FechaFin, lon, True)
    Case "CODMOTIVOGUIA"
                .PrintLine .Rellenar(objGNComp.CodMotivoGuia, lon, True)
    Case "DESCMOTIVOGUIA", "MOTIVOTRASLADO"
        Dim Motivo As IvMotivo
            If Len(objGNComp.CodMotivoGuia) > 0 Then
                Set Motivo = objGNComp.Empresa.RecuperaIvMotivo(objGNComp.CodMotivoGuia)
                .PrintLine .Rellenar(Motivo.Descripcion, lon, True)
                Set Motivo = Nothing
            End If
        Case "PUNTOPARTIDAGUIA", "PUNTOPARTIDA"
                    .PrintLine .Rellenar(objGNComp.PuntoPartida, lon, True)
        Case "NOMBREDESTINOGUIA", "NOMBREDESTINO"
                    .PrintLine .Rellenar(objGNComp.NombreDestino, lon, True)
        Case "RUCDESTINOGUIA", "RUCDESTINO"
                    .PrintLine .Rellenar(objGNComp.RucDestino, lon, True)
        Case "DIRECCIONDESTINOGUIA", "PUNTODESTINO"
                    .PrintLine .Rellenar(objGNComp.DireccionDestino, lon, True)
        Case "NOMBRETRANSPORTEGUIA"
                    .PrintLine .Rellenar(objGNComp.NombreTransporte, lon, True)
        Case "RUCTRANSPORTEGUIA", "RUCTRANSPORTISTA"
                    .PrintLine .Rellenar(objGNComp.RUCTransporte, lon, True)
        Case "NOMBRECHOFERGUIA"
                    .PrintLine .Rellenar(objGNComp.NombreChofer, lon, True)
        Case "RUCCHOFERGUIA"
                    .PrintLine .Rellenar(objGNComp.RUCChofer, lon, True)
        Case "PLACAGUIA"
                    .PrintLine .Rellenar(objGNComp.PLACA, lon, True)
        Case "PESOCARGAGUIA"
                    .PrintLine .Rellenar(objGNComp.PesoCarga, lon, True)
        Case "BULTOSCARGAGUIA"
                    .PrintLine .Rellenar(objGNComp.BultosCarga, lon, True)
        Case "VALORFLETEGUIA"
                    .PrintLine .Rellenar(objGNComp.ValorFlete, lon, True)
        Case "GUIACARGAGUIA"
                    .PrintLine .Rellenar(objGNComp.GuiaCarga, lon, True)
        
        Case "MAXDESCTOXITEM"
            maxDscto = 0
            For k = 1 To objGNComp.CountIVKardex
                If objGNComp.IVKardex(k).Descuento > maxDscto Then
                    maxDscto = objGNComp.IVKardex(k).Descuento
                End If
            Next k
            maxDscto = maxDscto * 100
            If maxDscto > 0 Then
                .PrintLine .Rellenar(Format(Abs(maxDscto), fmt), lon, False)
            End If
            
        Case "NUMDOCVENTA":
                Set gc = objGNComp.Empresa.RecuperaGNComprobante(objGNComp.IdTransFuente)
                If Not gc Is Nothing Then
                    num = gc.NumSerieEstaSRI & "-" & gc.NumSeriePuntoSRI & "-" & Right("000000000" & gc.NumTrans, 9)
                    .PrintLine .Rellenar(num, lon, True)
                    Set gc = Nothing
                End If

        Case "NUMAUTORIZANUMDOCVENTA":
                Set gc = objGNComp.Empresa.RecuperaGNComprobante(objGNComp.IdTransFuente)
                If Not gc Is Nothing Then
                    num = gc.NumeroAutorizacion
                    .PrintLine .Rellenar(num, lon, True)
                    Set gc = Nothing
                End If

        Case "FECHANUMDOCVENTA":
                Set gc = objGNComp.Empresa.RecuperaGNComprobante(objGNComp.IdTransFuente)
                If Not gc Is Nothing Then
                    num = gc.FechaTrans
                    .PrintLine .Rellenar(num, lon, True)
                    Set gc = Nothing
                End If
        Case "TOTALFORMASRI"
                If UBound(v, 1) > 0 Then 'AUC MODIFICADO PARA AGREGAR PARAMETROS DE LONGITUD DE CADENA AL IMPRIMIR
                    vcancelaTrans = 0
                    sql = " select  "
                    sql = sql & " isnull(SUM(DEBE),0) as Total"
                    sql = sql & " from gncomprobante g"
                    sql = sql & " inner join pckardex p"
                    sql = sql & " INNER JOIN tsformacobropago ts"
                    sql = sql & " inner join Anexo_FormaPago a on ts.idformaSRI=a.id"
                    sql = sql & " on p.idforma=ts.IdForma"
                    sql = sql & " on g.transid=p.transid"
                    sql = sql & " where estado <> 3 "
                    sql = sql & " and g.transid = " & objGNComp.TransId
                    sql = sql & " and CodFormaPago in (" & PreparaCadena(v(3)) & ")"
'                                        sql = sql & " GROUP BY codtrans"
                    Set rs = objGNComp.Empresa.OpenRecordset(sql)
                    If rs.RecordCount > 0 Then
                        vcancelaTrans = rs.Fields("Total")
                    End If
                    .PrintLine .Rellenar(vcancelaTrans, lon, True)
                End If
        Case Else:
                gnProcesaVariable2 cad, objGNComp, Sptxt
        End Select
    End With
    Set cli = Nothing
    Set centro = Nothing
    Set prov = Nothing
    Set vende = Nothing
    Set pcAct = Nothing
    Set GarAct = Nothing
    Set pca = Nothing
End Sub

Public Sub gnProcesaVariable2(cad As String, objGNComp As GNComprobante, Sptxt As SiiPrint.PrintTxt)
    Dim mobjGNOp As GNOpcion
    Dim lon As Integer, v As Variant
    Dim fmt As String
    Dim suma  As Currency
    Dim bandLetra As Boolean, Texto As String
    Set mobjGNOp = objGNComp.Empresa.GNOpcion

    'Set cli = objGnComp.Empresa.RecuperaPCProvCli(objGnComp.CodClienteRef)
    'variables disponibles para  todas las secciones
    
    With Sptxt
        v = Split(cad, ";")
        If IsEmpty(v) Then Exit Sub
        fmt = gfmt
        If UBound(v, 1) >= 1 Then lon = v(1)
        If UBound(v, 1) >= 2 Then fmt = generafmt(CStr(v(2)), CStr(v(0)))
        If UBound(v, 1) >= 3 Then
            If v(3) = "L" Or v(3) = "LM" Then      'Escribir en letras        'LM: Escribir en letras más nombre moneda
                bandLetra = True
            End If
        End If
        If UBound(v, 1) >= 4 Then
            If v(4) = "L" Then
                bandLetra = True
            End If
        End If
        Select Case v(0)
        Case "PTOTAL1": 'Valor  total de PT de Items
            If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                suma = Abs(objGNComp.IVKardexPTotalDou(False))   ' sin recargos
            Else
                suma = Abs(objGNComp.IVKardexPTotal(False))  ' sin recargos
            End If
        Case "PTOTAL2": 'Valor  total de PT + Recargos/descuentos
            If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                suma = Abs(objGNComp.IVKardexPTotalDou(True)) + objGNComp.IVRecargoTotal(True, False)
            Else
                suma = Abs(objGNComp.IVKardexPTotal(True)) + objGNComp.IVRecargoTotal(True, False)
            End If
        Case "PRTOTAL":  'Valor total de Precio real de Items
            If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                suma = Abs(objGNComp.IVKardexPTotalDou(True))
            Else
                suma = Abs(objGNComp.IVKardexPTotal(True))
            End If
        Case "TOTALSINIVA":
            If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                suma = TotalCSIvaDou(objGNComp, 0)
            Else
                suma = TotalCSIva(objGNComp, 0) '11/05/2001  Angel P.
            End If
        Case "TOTALCONIVA":
            If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                suma = TotalCSIvaDou(objGNComp, 1) '11/05/2001  Angel P.
            Else
                suma = TotalCSIva(objGNComp, 1) '11/05/2001  Angel P.
            End If
        Case "TOTALSINIVAR":
            If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                suma = TotalCSIvaRealDou(objGNComp, 0) '19-12-03 JEAA
            Else
                suma = TotalCSIvaReal(objGNComp, 0) '19-12-03 JEAA
            End If
        Case "TOTALCONIVAR":
            If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                suma = TotalCSIvaRealDou(objGNComp, 1) '19-12-03
            Else
                suma = TotalCSIvaReal(objGNComp, 1) '19-12-03
            End If
        Case "VNETO":
            If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                suma = Abs(ValorNetoDou(objGNComp, cad))
            Else
                suma = Abs(ValorNeto(objGNComp, cad))
            End If
        Case "VNETOSINIVA":
            If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                suma = Abs(ValorNetoIVADou(objGNComp, cad, False))
            Else
                suma = Abs(ValorNetoIVA(objGNComp, cad, False))
            End If
        Case "VNETOCONIVA":
            If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                suma = Abs(ValorNetoIVADou(objGNComp, cad, True))
            Else
                suma = Abs(ValorNetoIVA(objGNComp, cad, True))
            End If
        Case "CNETO": 'Sin recargos
            If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                suma = Abs(CostoNetoNewDou(objGNComp, cad, True))
            Else
                suma = Abs(CostoNetoNew(objGNComp, cad, True))
            End If
        Case "CNETOR": 'con recargos
            If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                suma = Abs(CostoNetoNewDou(objGNComp, cad, False))
            Else
                suma = Abs(CostoNetoNew(objGNComp, cad, False))
            End If
        Case "EFECTIVO":
             If objGNComp.GNTrans.IVMostrarVuelto Then      ' jeaa-05-12-03 pregunta si muestra pantalla de vuelto
                If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                    suma = Abs(CalculaEfectivoDou(objGNComp, False))
                Else
                    suma = Abs(CalculaEfectivo(objGNComp, False))
                End If
            End If
        Case "VUELTO"
             If objGNComp.GNTrans.IVMostrarVuelto Then      ' jeaa-05-12-03 pregunta si muestra pantalla de vuelto
                If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                    suma = CalculaEfectivoDou(objGNComp, True)
                    suma = IIf(suma < 0, 0, suma)
                Else
                    suma = CalculaEfectivo(objGNComp, True)
                    suma = IIf(suma < 0, 0, suma)
                End If
            End If
        Case "CTOTAL1":
            If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                suma = Abs(objGNComp.IVKardexCTotalDou(False))   ' sin recargos
            Else
                suma = Abs(objGNComp.IVKardexCTotal(False))  ' sin recargos
            End If
        Case "AFCTOTAL1":
            suma = Abs(objGNComp.AFKardexCTotal(False))  ' sin recargos
            
        Case "CTOTAL2": 'Valor  total de CT + Recargos/descuentos
            If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                suma = Abs(objGNComp.IVKardexCTotalDou(True)) + objGNComp.IVRecargoTotal(True, False)   ' sin recargos
            Else
                suma = Abs(objGNComp.IVKardexCTotal(True)) + objGNComp.IVRecargoTotal(True, False)  ' sin recargos
            End If
        Case "AFCTOTAL2": 'Valor  total de CT + Recargos/descuentos
            suma = Abs(objGNComp.AFKardexCTotal(True)) + objGNComp.AFRecargoTotal(True, False)  ' sin recargos
        Case "RECARTTL":   'Recargo total
            suma = objGNComp.IVRecargoTotal(True, True)
        Case "ASIDTTL":
            suma = objGNComp.DebeTotal
        Case "ASIHTTL":
            suma = objGNComp.HaberTotal
        Case "DOCXCOBTTL":
            suma = objGNComp.PCKardexDebeTotal
        Case "DOCXPAGTTL":
            suma = objGNComp.PCKardexHaberTotal
        Case "DOCCOBROTTL":  'Idasignado <> 0
            suma = objGNComp.TSKardexDebeTotal
        Case "DOCCOBROTTLR"
            suma = TotalDocCobrados(objGNComp)
        Case "DOCPAGOTTL":
            suma = objGNComp.TSKardexHaberTotal
        Case "BCODTTL":  'Valor total debe documentos bancarios
            suma = objGNComp.TSKardexDebeTotal
        Case "BCOHTTL":
            suma = objGNComp.TSKardexHaberTotal
        Case "BCOTTL":
            suma = TotalBanco(objGNComp)
        Case "TOTRET":      'Valor total de Retenciones     Agregado Alex Feb/2002
            suma = TotalRetencion(objGNComp)
        Case "TOTRETP"
            suma = CCur(ImpresionP("TOTRETP", , objGNComp))
        Case "TOTALANTICIPOS"
            suma = TotalAnticipos(objGNComp)
        Case "CTOTAL1TR":
            If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                suma = Abs(objGNComp.IVKardexCTotalDou(False) / 2)  ' sin recargos PARA TRANSFERENCIA DE BODEGAS
            Else
                suma = Abs(objGNComp.IVKardexCTotal(False) / 2) ' sin recargos PARA TRANSFERENCIA DE BODEGAS
            End If
        Case "CTOTAL2TR": 'Valor  total de CT + Recargos/descuentos PARA TRANSFERENCIA DE BODEGAS
            If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                suma = (Abs(objGNComp.IVKardexCTotalDou(False)) + objGNComp.IVRecargoTotal(True, True)) / 2 ' sin recargos
            Else
                suma = (Abs(objGNComp.IVKardexCTotal(False)) + objGNComp.IVRecargoTotal(True, True)) / 2 ' sin recargos
            End If
        Case "PTOTAL1TR": 'Valor  total de PT de Items PARA TRANSFERENCIA DE BODEGAS
            If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                'suma = Abs(objGNComp.IVKardexPTotalDou(False) / 2) ' sin recargos
                suma = Abs(objGNComp.IVKardexPTotal1Dou(False))
            Else
                'suma = Abs(objGNComp.IVKardexPTotal(False) / 2) ' sin recargos
                suma = Abs(objGNComp.IVKardexPTotal1(False))  ' sin recargos
            End If
        Case "PTOTAL2TR": 'Valor  total de PT + Recargos/descuentos PARA TRANSFERENCIA DE BODEGAS
            If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                'suma = (Abs(objGNComp.IVKardexPTotalDou(True)) + objGNComp.IVRecargoTotal(True, False)) / 2
                suma = Abs(objGNComp.IVKardexPTotal1Dou(True)) + objGNComp.IVRecargoTotal(True, False)
            Else
                'suma = (Abs(objGNComp.IVKardexPTotal(True)) + objGNComp.IVRecargoTotal(True, False)) / 2
                suma = Abs(objGNComp.IVKardexPTotal1(True)) + objGNComp.IVRecargoTotal(True, False)
            End If
        Case "VNETO+IVA":
            If objGNComp.Empresa.GNOpcion.IVKTipoDatoDouble Then
                suma = Abs(ValorNetoMasIVADou(objGNComp, cad))
            Else
                suma = Abs(ValorNetoMasIVA(objGNComp, cad))
            End If
        Case "TOTBASE":      'Valor total de Base Imponible
            suma = (TotalBaseImponible(objGNComp))
        Case "TOTBASE-RET":      'Valor total de Base Imponible menos Retenciones
            Dim basetrans As Currency, retiva As Currency, retir As Currency
            Dim TotIva As Currency, vv As Currency
            basetrans = 0
            TotIva = CalculoTotalIVA(objGNComp)
            If objGNComp.CountTSKardexRet > 1 Then
                basetrans = TotalBaseImponible(objGNComp) - TotIva
            Else
                basetrans = TotalBaseImponible(objGNComp)
            End If
            retiva = TotIva - TotalRetIVA(objGNComp)
            retir = TotalRetIR(objGNComp)
            TotIva = CalculoTotalIVA(objGNComp)
            suma = TotalBaseImponible(objGNComp) - TotalRetIVA(objGNComp) - TotalRetIR(objGNComp)
            If objGNComp.CountTSKardexRet > 1 Then
                suma = basetrans - retiva - retir + TotIva
'                suma = retiva + retir + TotIva
            Else
                If retiva = 0 Then
                    suma = basetrans - retiva - retir + TotIva
                    'suma = retir
                Else
                    suma = retir + TotIva - retiva
                End If
            End If
        Case "ABONO":
                suma = Abs(objGNComp.AbonoRes - TotalAnticipos(objGNComp))
        Case "SALDO":
                suma = Abs(objGNComp.saldo(True))
        Case "SALDOANT":
                suma = Abs(objGNComp.saldo(False))
        Case "ABONORES": 'abono en reservacion 23/02/07
                suma = Abs(objGNComp.AbonoRes)
        Case "SALDORES":
                    suma = (Abs(objGNComp.IVKardexPTotal(True)) + objGNComp.IVRecargoTotal(True, False)) - Abs(objGNComp.saldo(False))
        Case "SUBTOTALSINIVA":
            suma = SubTotalCSIva(objGNComp, 0) '11/05/2001  Angel P.
        Case "SUBTOTALCONIVA":
            suma = SubTotalCSIva(objGNComp, 1) '11/05/2001  Angel P.
        Case "PESOTOTALNETO":
            suma = Abs(objGNComp.IVKardexPesoTotalNeto)  ' sin recargos
        Case "PESOTOTALBRUTO":
            suma = Abs(objGNComp.IVKardexPesoTotalBruto)  ' sin recargos
        Case "PESOTOTALNETOTRANSF":
            suma = Abs(objGNComp.IVKardexPesoTotalNetoTransf)  ' sin recargos
        Case "PESOTOTALBRUTOTRANSF":
            suma = Abs(objGNComp.IVKardexPesoTotalBrutoTransf)  ' sin recargos
        Case "CANTTRANSF":
            suma = Abs(CantTotalTransferencia(objGNComp))
        Case "TOTALDETEFECTIVO":
            suma = Abs(TotalDetEfectivo(objGNComp))
        Case "TOTALDETTARJETA":
            suma = Abs(TotalDetTarjeta(objGNComp))
        Case "TOTALDETCHEQUE":
            suma = Abs(TotalDetCheque(objGNComp))
        Case "TOTALDETCHEQUEPOSF":
            suma = Abs(TotalDetChequePosf(objGNComp))
        Case "TOTALDETVMANUAL":
            suma = Abs(TotalDetVmanual(objGNComp))
        Case "TOTALDETCOBROS":
            suma = Abs(TotalDetCobros(objGNComp))
        Case "TOTALDETCOBROSRT":
            suma = Abs(TotalDetCobrosRT(objGNComp))
        Case "TOTALCIERREEFECT"
             suma = objGNComp.PCKardexHaberTotal + Abs(TotalDetCobros(objGNComp))
        Case "TOTALDETINGRESOS":
            suma = Abs(TotalIngresosCierre(objGNComp))
        Case "TOTALDETEGRESOS":
            suma = Abs(TotalEgresosCierre(objGNComp))
        Case "TOTALDETVCREDITO":
            suma = Abs(TotalDetVcredito(objGNComp))
        Case "TOTALCIERRECAJA":
            suma = Abs(TotalDetEfectivo(objGNComp)) + Abs(TotalDetTarjeta(objGNComp)) + Abs(TotalDetCheque(objGNComp)) + Abs(TotalDetVmanual(objGNComp)) + Abs(TotalDetVcredito(objGNComp)) + Abs(TotalEgresosCierre(objGNComp)) + Abs(TotalDetCobros(objGNComp))
        Case "TOTALDEPOSITOCIERRECAJA":
            suma = Abs(TotalDetEfectivo(objGNComp)) + Abs(TotalDetCheque(objGNComp)) + Abs(TotalDetCobros(objGNComp))
        Case "TOTALDETINGRESOS":
            suma = Abs(TotalDetEfectivo(objGNComp))
        Case "TOTALDEPOSITOCIERRE": 'PARA YOLITA
            suma = objGNComp.PCKardexHaberTotal + Abs(TotalDetCobros(objGNComp)) - Abs(TotalEgresosCierre(objGNComp))
        Case "DIFERENCIACIERRECAJA":
              '  suma = Abs(TotalDetEfectivo(objGNComp) - (Abs(TotalEgresosCierre(objGNComp)) + Abs(TotalDetCobros(objGNComp)) + Abs(objGNComp.PCKardexHaberTotal)))
              'AUC cambiando 25/07/2018 pq da error en el horno creo q deberia ser asi
                If objGNComp.GNTrans.TSunirCobrosFacturas Then
                    suma = (Abs(objGNComp.PCKardexHaberTotal) + Abs(TotalDetCobros(objGNComp))) - (Abs(TotalDetEfectivo(objGNComp)) + Abs(TotalEgresosCierre(objGNComp)))
                Else 'aqui no le tomo en cuenta los cobros pq no pongo en ningun lado
                    'suma = Abs(objGNComp.PCKardexHaberTotal) - (Abs(TotalDetEfectivo(objGNComp)) + Abs(TotalEgresosCierre(objGNComp)))
                    'AUC 03/12/2018 cambiado el orden para q muestre el sigo (- o + ) para saber si faltante o sobrante
                    ' (-) faltante
                    ' (+) sobrante
                    suma = Abs(TotalDetEfectivo(objGNComp)) + Abs(TotalEgresosCierre(objGNComp)) - Abs(objGNComp.PCKardexHaberTotal)
                End If
            
            'AUC 11/10/2010
        Case "DETCONIVA" 'TOTAL DETALLE CON IVA
            suma = objGNComp.Empresa.RecuperaDetalleSinConIva(objGNComp.FechaTrans, objGNComp.CodUsuario, True)
        Case "DETSINIVA" 'TOTAL DETALLE SIN IVA 'el mismo pero con la bandera false
            suma = objGNComp.Empresa.RecuperaDetalleSinConIva(objGNComp.FechaTrans, objGNComp.CodUsuario, False)
        Case "DETDESC" 'TOTAL DETALLE DESCUENTO
            suma = objGNComp.Empresa.RecuperaDetalleTotalDesc(objGNComp.FechaTrans, objGNComp.CodUsuario)
        Case "DETSUBTOTAL" 'SUBTOTAL DETALLE 'este subtotal es menos los descuentos
            suma = objGNComp.Empresa.RecuperaDetalleSinConIva(objGNComp.FechaTrans, objGNComp.CodUsuario, True) + objGNComp.Empresa.RecuperaDetalleSinConIva(objGNComp.FechaTrans, objGNComp.CodUsuario, False)
        Case "DETIVA" 'TOTAL IVA DETALLE
            suma = objGNComp.Empresa.RecuperaDetalleTotalIVA(objGNComp.FechaTrans, objGNComp.CodUsuario)
        Case "DETTOTAL" 'TOTAL TOTAL DEL DETALLE
            suma = objGNComp.Empresa.RecuperaDetalleSinConIva(objGNComp.FechaTrans, objGNComp.CodUsuario, True) + objGNComp.Empresa.RecuperaDetalleSinConIva(objGNComp.FechaTrans, objGNComp.CodUsuario, False) + objGNComp.Empresa.RecuperaDetalleTotalIVA(objGNComp.FechaTrans, objGNComp.CodUsuario)
        Case "ASIPRDTTL":
            suma = objGNComp.PRDebeTotal
        Case "ASIPRHTTL":
            suma = objGNComp.PRHaberTotal
         Case "TSEFECTIVO":
             suma = objGNComp.CalculaTSEfectivo
         Case "CTSXCOBRARF" 'imprime credito por cobrar filtrado por codigo
            suma = objGNComp.PCkarderDebeTotalFormaCobro(v(4))
        Case "CUOTA" ' VALOR CUOTA CAP+INTERES
            '.PrintLine .Rellenar(Format(objGNComp.PCkarderCuota(False, v(3)), fmt), lon, False)
            suma = objGNComp.PCkarderCuota(False, v(3))
            
        Case Else
            'gnProcesaComRet cad, objGNComp, Sptxt
            Err.Raise ERR_NOIMPRIME, App.EXEName, "Comando " & v(0) & " no encontrado"
            Exit Sub
        End Select
        If bandLetra Then
            Texto = ConvertLetrasTexto(suma, fmt)
            If v(3) = "LM" Then Texto = Texto & " " & mobjGNOp.NombreMoneda(objGNComp.CodMoneda)
            .PrintLine .Rellenar(Texto, lon, True)
        Else
        If UBound(v, 1) >= 3 Then
                If v(3) = "KGQQ" Then
                    .PrintLine .Rellenar(Format(Round(Abs(suma) / 45.36, 2), fmt), lon, False)
                ElseIf v(3) = "LBQQ" Then
                    .PrintLine .Rellenar(Format(Round(Abs(suma) / 100, 2), fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(Abs(suma), fmt), lon, False)
                End If
            Else
                If v(0) = "DIFERENCIACIERRECAJA" Then 'AUC agregado 03/12/2018 para el horno para diferenciar entre
                    .PrintLine .Rellenar(Format(suma, fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(Abs(suma), fmt), lon, False)
                End If
            End If
        End If
    End With
    
End Sub

Private Function ObtenerCodPC(ByRef GnComp As GNComprobante, Optional ByRef VerifProv As Boolean) As String
    Dim i As Long, codPC As String
    With GnComp
        If Len(.CodProveedorRef) > 0 And Len(.CodClienteRef) = 0 Then
            codPC = .CodProveedorRef
        ElseIf Len(.CodProveedorRef) = 0 And Len(.CodClienteRef) > 0 Then
            codPC = .CodClienteRef
            'AUC 14/11/2007 Cuando se imprima el cliente y el proveedor en un misma transaccion
        ElseIf Len(.CodProveedorRef) > 0 And Len(.CodClienteRef) > 0 Then
            codPC = .CodProveedorRef
       ElseIf .CountPCKardex > 0 Then
            codPC = .PCKardex(1).CodProvCli
            VerifProv = True
        ElseIf .CountTSKardexRet > 0 Then
            VerifProv = True
        End If
    End With
    ObtenerCodPC = codPC
End Function



Public Function generafmt(ByRef fmt As String, ByRef campo As String) As String
    Dim i As Integer
    Dim deci As Integer '= numero de decimales
    'If Left(campo, 1) = "F" Then   'Cuando es formato de fecha
    If Not IsNumeric(fmt) Then
        generafmt = fmt
    ElseIf Left(campo, 4) = "CANT" And Len(fmt) = 0 Then      'Formato de cantidad
        generafmt = gfmtCant
    Else
        deci = CInt(fmt)
        If deci = 0 Then  'sin decimales
            generafmt = "#,0"
        Else
            generafmt = "#,0."
            For i = 1 To deci
                generafmt = generafmt & "0"
            Next i
        End If
    End If
End Function

Private Function CantTotal(ByRef GnComp As GNComprobante) As Double
    'devuelve la cantidad  total de la transaccion
    Dim ivk As IVKardex
    Dim i As Long
     For i = 1 To GnComp.CountIVKardex
        Set ivk = GnComp.IVKardex(i)
        'jeaa 06/01/05 para que no se sumen los items de servicio
        If GnComp.IVKardex(i).CodInventario <> "-" And GnComp.IVKardex(i).CodInventario <> "+" And GnComp.IVKardex(i).auxBandCambiaDescr = False Then
            CantTotal = CantTotal + ivk.Cantidad
        End If
    Next i
    CantTotal = Abs(CantTotal)    'valor   absoluto
End Function

Private Function CodBodegaOri(ByRef GnComp As GNComprobante) As String
    'devuelve la cantidad  total de la transaccion
    Dim ivk As IVKardex
    Dim i As Long
     For i = 1 To GnComp.CountIVKardex
        Set ivk = GnComp.IVKardex(i)
        If ivk.Cantidad < 0 Then Exit For
    Next i
    CodBodegaOri = ivk.codBodega
    
End Function

Private Function CodBodegaDest(ByRef GnComp As GNComprobante) As String
    'devuelve la cantidad  total de la transaccion
    Dim ivk As IVKardex
    Dim i As Long
     For i = 1 To GnComp.CountIVKardex
        Set ivk = GnComp.IVKardex(i)
        If ivk.Cantidad >= 0 Then Exit For
    Next i
    CodBodegaDest = ivk.codBodega
End Function

Private Function DescBodega(ByRef GnComp As GNComprobante, ByRef codBodega As String) As String
    'devuelve la cantidad  total de la transaccion
    Dim bod As IVBodega
    Set bod = GnComp.Empresa.RecuperaIVBodega(codBodega)
    DescBodega = bod.Descripcion
End Function

Private Function CodBcoPri(ByRef GnComp As GNComprobante, Optional beneficiario As Boolean = False) As String
    Dim tsk As TSKardex
    Set tsk = GnComp.TSKardex(1)
    CodBcoPri = IIf(beneficiario, tsk.Nombre, tsk.CodBanco)
End Function

Private Function CodDocxCobPri(ByRef GnComp As GNComprobante) As String
    'El primet documento  grabado en el cargex de banco
    Dim Pck As PCKardex
    Set Pck = GnComp.PCKardex(1)
    CodDocxCobPri = Pck.codForma
End Function

Private Function FVenci(ByRef GnComp As GNComprobante) As Date
    'El primet documento  grabado en el cargex de banco
    Dim Pck As PCKardex
    Set Pck = GnComp.PCKardex(1)
    FVenci = Pck.FechaVenci
End Function

Private Function NomDocxCobPri(ByRef GnComp As GNComprobante, ByRef codForma) As String
    Dim Forma As TSFormaCobroPago
    Set Forma = GnComp.Empresa.RecuperaTSFormaCobroPago(codForma)
    If Forma Is Nothing Then
        Err.Raise ERR_NOIMPRIME, App.EXEName, "No existe codigo forma de  cobro: " & codForma
    Else
        NomDocxCobPri = Forma.NombreForma
    End If
End Function

'Modificado Alex 25/02/2002
Private Function NomProvxPag(ByRef GnComp As GNComprobante) As String
    Dim prov  As pcProvCli

    Set prov = GnComp.Empresa.RecuperaPCProvCli(GnComp.TransId)
    If prov Is Nothing Then
        Err.Raise ERR_NOIMPRIME, App.EXEName, "Datos de Proveedor: No se ha realizado ninguna retención"
    Else
        NomProvxPag = prov.Nombre
    End If
    Set prov = Nothing
End Function

Private Function NomBcoPri(ByRef GnComp As GNComprobante, ByRef CodBanco As String) As String
    Dim bco As TSBanco
    Set bco = GnComp.Empresa.RecuperaTSBanco(CodBanco)
    If bco Is Nothing Then
        Err.Raise ERR_NOIMPRIME, App.EXEName, "No existe CodBanco: " & CodBanco
    Else
        NomBcoPri = bco.Descripcion
    End If
End Function

Private Function TotalBanco(ByRef GnComp As GNComprobante) As Currency
    Dim tsk As TSKardex, i As Long
    Dim total As Currency
    For i = 1 To GnComp.CountTSKardex
        Set tsk = GnComp.TSKardex(i) ' **************12-01-04 jeaa modificado 1 por variable i
        total = total + tsk.debe + tsk.haber  'Preguntar
    Next i
    TotalBanco = total
End Function

'Agregado Alex  25/02/2005
Private Function TotalRetencion(ByRef GnComp As GNComprobante) As Currency
    Dim tsk As TSKardexRet, i As Long
    Dim total As Currency, v As Variant
     v = SeparaParamVar("TOTRET")
    For i = 1 To GnComp.CountTSKardexRet
        Set tsk = GnComp.TSKardexRet(i)
        If UCase(v(1)) <> "TODOS" Or v(1) = "" Then            'Resolver el caso en el que no pusieron ningún parámetro para imprimir TOTRET
            If InStr(tsk.CodRetencion, v(1)) Then total = total + Abs(tsk.debe - tsk.haber)   'Preguntar
        Else
            total = total + Abs(tsk.debe - tsk.haber)   'Preguntar
        End If
    Next i
    TotalRetencion = total
End Function

Private Function Recargo(ByRef GnComp As GNComprobante, ByRef cod As String) As Currency
    'Busca  el codigo  en  IVKardexRecargo
    'si existe en la transaccion  devuelve  el valor
    Dim ivr As IVRecargo, ivkr As IVKardexRecargo, ivk As IVKardex
    Dim i As Long
    If UCase(cod) = "DESCXITEM" Then
        Recargo = 0
        For i = 1 To GnComp.CountIVKardex
            Set ivk = GnComp.IVKardex(i)
            Recargo = Recargo + (ivk.Descuento * ivk.PrecioTotal)
        Next i
    ElseIf UCase(cod) = "DESCXTODO" Then
        Recargo = 0
        For i = 1 To GnComp.CountIVKardex
            Set ivk = GnComp.IVKardex(i)
            Recargo = Recargo + (ivk.Descuento * ivk.PrecioTotal)
        Next i
        Set ivr = GnComp.Empresa.RecuperaIVRecargo("DESC")
        If ivr Is Nothing Then
            Err.Raise ERR_NOIMPRIME, App.EXEName, "No existe recargo: " & "DESC"
        Else
            For i = 1 To GnComp.CountIVKardexRecargo
                Set ivkr = GnComp.IVKardexRecargo(i)
                If ivr.CodRecargo = ivkr.CodRecargo Then
                    Recargo = Recargo + ivkr.valor
                    Exit Function
                End If
            Next i
        End If
    ElseIf UCase(cod) = "DESCCXITEM" Then
        Recargo = 0
        For i = 1 To GnComp.CountIVKardex
            Set ivk = GnComp.IVKardex(i)
            Recargo = Recargo + (ivk.Descuento * ivk.CostoTotal)
        Next i
        'MsgBox Recargo
    ElseIf UCase(cod) = "DESCCXTODO" Then
        Recargo = 0
        For i = 1 To GnComp.CountIVKardex
            Set ivk = GnComp.IVKardex(i)
            Recargo = Recargo + (ivk.Descuento * ivk.CostoTotal)
        Next i
        Set ivr = GnComp.Empresa.RecuperaIVRecargo("DESC")
        If ivr Is Nothing Then
            Err.Raise ERR_NOIMPRIME, App.EXEName, "No existe recargo: " & "DESC"
        Else
            For i = 1 To GnComp.CountIVKardexRecargo
                Set ivkr = GnComp.IVKardexRecargo(i)
                If ivr.CodRecargo = ivkr.CodRecargo Then
                    Recargo = Recargo + ivkr.valor
                    Exit Function
                End If
            Next i
        End If
    ElseIf UCase(cod) = "DESCXTODOIVA" Then
        Recargo = 0
        For i = 1 To GnComp.CountIVKardex
            Set ivk = GnComp.IVKardex(i)
            Recargo = Recargo + (ivk.Descuento * ivk.PrecioTotal)
        Next i
        Set ivr = GnComp.Empresa.RecuperaIVRecargo("DESC")
        If ivr Is Nothing Then
            Err.Raise ERR_NOIMPRIME, App.EXEName, "No existe recargo: " & "DESC"
        Else
            For i = 1 To GnComp.CountIVKardexRecargo
                Set ivkr = GnComp.IVKardexRecargo(i)
                If ivr.CodRecargo = ivkr.CodRecargo Then
                    Recargo = Recargo + ivkr.valor
                    Exit Function
                End If
            Next i
        End If
        Set ivr = GnComp.Empresa.RecuperaIVRecargo("IVA")
        If ivr Is Nothing Then
            Err.Raise ERR_NOIMPRIME, App.EXEName, "No existe recargo: " & "IVA"
        Else
            For i = 1 To GnComp.CountIVKardexRecargo
                Set ivkr = GnComp.IVKardexRecargo(i)
                If ivr.CodRecargo = ivkr.CodRecargo Then
                    Recargo = Recargo + ivkr.valor
                    Exit Function
                End If
            Next i
        End If
    
    Else
        Set ivr = GnComp.Empresa.RecuperaIVRecargo(cod)
        If ivr Is Nothing Then
            Err.Raise ERR_NOIMPRIME, App.EXEName, "No existe recargo: " & cod
        Else
            For i = 1 To GnComp.CountIVKardexRecargo
                Set ivkr = GnComp.IVKardexRecargo(i)
                If ivr.CodRecargo = ivkr.CodRecargo Then
                    Recargo = ivkr.valor
                    Exit Function
                End If
            Next i
            Recargo = 0
        End If
    End If
End Function

Private Function ValorNeto(ByRef GnComp As GNComprobante, ByRef cad As String) As Currency
    'saca  el valor  neto  de la factura
    'suma  Pt + Recargos(especificados)
    Dim v As Variant, numRec As Integer
    Dim i As Integer
    v = Split(cad, ";")
    If IsEmpty(v) Then Exit Function
    numRec = UBound(v, 1)
    ValorNeto = Abs(GnComp.IVKardexPTotal(True))    ' sin recargos
    For i = 3 To numRec
        ValorNeto = ValorNeto + Recargo(GnComp, CStr(v(i)))
    Next i
End Function


Private Function CalculaEfectivo(ByVal GnComp As GNComprobante, ByVal bandVuelto As Boolean) As Currency
    'Campos  especiales  para SiiFactura
    'GnComp.Desccripcion = 'XXXXXXXXXXXX - Efectivo(5.12)'
    Dim s As String, posini As Integer, posfin As Integer
    Dim Efectivo As String, efec As Currency
    Dim PTotal As Currency, Pck As PCKardex
    
    PTotal = Abs(GnComp.IVKardexPTotal(True)) + GnComp.IVRecargoTotal(True, False)      '- gnComp.IVKardexDescItemTotal
    'antes GnComp.efectivo
    s = GnComp.Efectivo
    posini = InStr(1, s, "Efectivo (") + 10
    posfin = InStr(posini, s, ")")
    If posfin <> 0 Then     '***Diego 21/12/2003  Control  cuando  no  graba vuelto
        Efectivo = Mid$(s, posini, posfin - posini)
    End If
    If IsNumeric(Efectivo) Then
        efec = CCur(Efectivo)
    End If
    If bandVuelto Then
        Dim CContado As Currency
        CContado = GnComp.CalculaCobroContado(GnComp.GNTrans.IVCobroContado)  ' esteba 20/10/2003 para cuando existen anticipados  valor anterior       Set pck = GnComp.PCKardex(1)        'asumiendo que el valor pagado de contado siempre se guarda en el primer registro de la tabla
        CalculaEfectivo = efec - CContado        ' anteriorpck.Debe
        Set Pck = Nothing
    Else
        CalculaEfectivo = efec
    End If
End Function

Private Function TotalCSIva(ByRef GnComp As GNComprobante, ByVal CSIva As Byte) As Double
'11/05/2001  Angel P. para calcular el total de productos con Iva y sin Iva
'CSIva=0  ---> Sin Iva     CSIva=1 ---> Con Iva
    Dim ivk As IVKardex
    Dim i As Long
    For i = 1 To GnComp.CountIVKardex
        If CSIva = 0 Then
            Set ivk = GnComp.IVKardex(i)
            If ivk.IVA = 0 Then TotalCSIva = TotalCSIva + Abs(ivk.PrecioRealTotal)
        Else
            Set ivk = GnComp.IVKardex(i)
            If ivk.IVA <> 0 Then TotalCSIva = TotalCSIva + Abs(ivk.PrecioRealTotal)
        End If
    Next i
End Function

Private Function TransFuente(ByVal GnComp As GNComprobante, ByVal campo As String) As Variant
'14/05/2001  Angel P. para extraer datos de la transacción de origen
    Dim gc As GNComprobante
    Dim gs As GNSucursal
    Set gc = GnComp.Empresa.RecuperaGNComprobante(GnComp.IdTransFuente)
    Set gs = GnComp.Empresa.RecuperaGNSucursal(GnComp.CodTrans)
    
    If Not (gc Is Nothing) Then
        Select Case campo
        Case "NUMTRANS"
            TransFuente = gc.NumTrans
        Case "NUMDOCREF"
            TransFuente = gc.NumDocRef
        Case "CODSUCURSAL"
            TransFuente = gc.GNTrans.CodSucursal
        Case "NOMSUCURSAL"
            TransFuente = gs.Nombre
        
        End Select
    Else
        TransFuente = ""
    End If
    Set gc = Nothing
    Set gs = Nothing
    
End Function
'Agregado  Alex 07/02/2002
Private Function ImpParam(ByVal NomVar As String, ByVal Ind As Integer) As String
    Dim v As Variant, i As Integer
    Dim ParamVar As Variant, numparam As Integer
    
    ReDim ParamVar(60)
    numparam = 0
    
    ParamVar = SeparaParamVar(NomVar, numparam)
    Select Case NomVar
        Case "MOTIVTRASL"   'verifica si el parámetro corresponde a la variable a analizar
        For i = 1 To numparam       'analizando de línea en línea
            v = Split(ParamVar(i), ",")     'separa todos los parámetros    'Comparar siempre solo por indice
            If Ind = Val(v(0)) Then     'encuentra los parámetros que corresponden al índice requerido por el usuario
                If Val(v(0)) = INDMOTIV + 1 Then    'compara si lo requerido por el usuario es igual a lo antes seleccionado
                    ImpParam = IIf(v(1) = "Texto", MOTIVTRASLSELEC, v(1))
                End If
                Exit Function
            End If
        Next i
        End Select
    ImpParam = ""
End Function

'Agregado  Alex 07/02/2002
Private Function SeparaParamVar(ByRef NomVar As String, Optional ByRef numparam As Integer) As Variant
    Dim v As Variant, i As Integer
    ReDim v(60)
    For i = 1 To Parametros(3, 1)           'Se trasladan los valores correspondientes a una sola variable (NomVar)
        If Parametros(0, i) = NomVar Then
            v(i) = Parametros(1, i)
            numparam = numparam + 1
        End If
    Next i
    SeparaParamVar = v
End Function

'Agregado Alex 24/Jun/2002
Private Function ImpresionP(Optional ByVal NomVar As String, Optional ByVal Ind As Integer, _
                                            Optional ByRef GnComp As GNComprobante) As String
    Dim i As Long, obj As clsParametros, X As Long, cad As String
    Dim ParamVar As Variant, v As Variant, tsk As TSKardexRet, total As Currency
    
    If NomVar = "MOTIVTRASL" Then cad = NomVar & ",MOTIVO_TRASL"
    
     For i = 1 To mColP.Count                    'Localiza la variable a imprimir
        If InStr(cad, mColP(i).NomVar) > 0 Then
            Set obj = mColP(i)
            X = i
            Exit For
        End If
    Next i
    Set obj = mColP(X)
    Select Case NomVar
        Case "MOTIVTRASL"
            For i = 1 To obj.CountParametros
            If Ind = INDMOTIV + 1 Then
                v = Split(obj.RecuperaParametro(i), ",")
'                 If i = Ind Then 'encuentra los parámetros que corresponden al índice requerido por el usuario
                    ImpresionP = IIf(InStr(v(INDMOTIV), "Texto") > 0, MOTIVTRASLSELEC, v(INDMOTIV))
'                If Val(v(0)) = Ind Then 'encuentra los parámetros que corresponden al índice requerido por el usuario
'                    If Val(v(0)) = INDMOTIV + 1 Then    'compara si lo requerido por el usuario es igual a lo antes seleccionado
'                        ImpresionP = IIf(InStr(v(1), "Texto") > 0, MOTIVTRASLSELEC, v(1))
'                    End If
'                    Exit Function
'                End If
                    Exit Function
            End If
'                End If
            Next i
        Case "TOTRETP"
            v = Split(obj.RecuperaParametro(1), ",")
            For i = 1 To GnComp.CountTSKardexRet
                Set tsk = GnComp.TSKardexRet(i)
                If UCase(v(0)) <> "TODOS" Or v(0) = "" Then
                    If InStr(tsk.CodRetencion, v(1)) Then total = total + Abs(tsk.debe - tsk.haber)
                Else
                    total = total + Abs(tsk.debe - tsk.haber)
                End If
            Next i
            ImpresionP = total
            Exit Function
    
    End Select
    
     ImpresionP = ""
End Function

'Agregado Alex Septiembre/2002
Public Function BorraEspacios(ByVal cad As String) As String
     'elimina caracter tabulado por nada
    cad = Replace(cad, vbTab, "")
    
     'elimina caracter espacio por nada
    cad = Replace(cad, " ", "")
    BorraEspacios = cad
End Function

'Agregado Alex Enero 31/2003
Public Function TotalDocCobrados(ByVal mobjGnComp As GNComprobante) As Double
    Dim i As Long, Pck As PCKardex, cancela As Double
    For i = 1 To mobjGnComp.CountPCKardex
        Set Pck = mobjGnComp.PCKardex(i)
        'Solo imprimimos si el documento está asignado a un doc. origen
        'recibimos dinero del  cliente por tanto   va  al  haber
        If Pck.IdAsignado <> 0 And Pck.haber <> 0 Then     'Cobros, IT
            cancela = cancela + (Pck.debe + Pck.haber)
        End If
    Next i
    Set mobjGnComp = Nothing
    Set Pck = Nothing
    TotalDocCobrados = cancela
End Function
Private Function TotalCSIvaReal(ByRef GnComp As GNComprobante, ByVal CSIva As Byte) As Double
'11/05/2001  Angel P. para calcular el total de productos con Iva y sin Iva
'CSIva=0  ---> Sin Iva     CSIva=1 ---> Con Iva
    Dim ivk As IVKardex
    Dim i As Long
    For i = 1 To GnComp.CountIVKardex
        If CSIva = 0 Then
            Set ivk = GnComp.IVKardex(i)
            If ivk.IVA = 0 Then TotalCSIvaReal = TotalCSIvaReal + Abs(ivk.PrecioRealTotal)
        Else
            Set ivk = GnComp.IVKardex(i)
            If ivk.IVA <> 0 Then TotalCSIvaReal = TotalCSIvaReal + Abs(ivk.PrecioRealTotal)
        End If
    Next i
End Function


'******************* JEAA 12/08/2003
Public Function DescComprobante(ByVal num As String) As String
    Select Case num
    Case "01"
    DescComprobante = "Factura "
    Case "02"
    DescComprobante = "Nota o boleta de venta"
    Case "03"
    DescComprobante = "Liquidación de Compra de bienes o Prestación de servicios"
    Case "04"
    DescComprobante = "Nota de crédito"
    Case "05"
    DescComprobante = "Nota de débito"
    Case "09"
    DescComprobante = "Tiquetes o vales emitidos pór máquinas registradoras"
    Case "10"
    DescComprobante = "Comprobante de Venta autorizados en el Art. 10"
    Case "11"
    DescComprobante = "Pasajes expedidos por empresas de aviación"
    Case "12"
    DescComprobante = "Documentos emitidos por instituciones financieras"
    Case "13"
    DescComprobante = "Documentos emitidos por compañías de seguros"
    Case "14"
    DescComprobante = "Comprobantes emitidos por empresas de telecomunicaciones"
    Case "15"
    DescComprobante = "Comprobante de Venta emitido en el exterior"
    Case "16"
    DescComprobante = "Formulario Único de Exportación FUE"
    Case "17"
    DescComprobante = "Documento Único de importación o Declaración Aduanera Simplificada"
    Case "18"
    DescComprobante = "Dctos. Autorizados utilizados en ventas excepto N/C N/D"
    End Select
End Function

Public Function DESCCreditoTributario(ByVal num As String) As Variant
    Select Case num
    Case "00"
        DESCCreditoTributario = "No aplica"
    Case "01"
        DESCCreditoTributario = "Crédito Tributario para declaración de IVA"
    Case "02"
        DESCCreditoTributario = "Costo o Gasto para declaración de IR"
    Case "03"
        DESCCreditoTributario = "Activo Fijo - Crédito Tributario para declaración de IVA"
    Case "04"
        DESCCreditoTributario = "Activo Fijo - Costo o Gasto par declaración de IR"
    Case "05"
        DESCCreditoTributario = "Liquidación Gastos de Viaje, hospedaje y alimentación Gastos IR"
    Case "06"
        DESCCreditoTributario = "Inventario - Crédito Tributario para declaración de IVA"
    Case "07"
        DESCCreditoTributario = "Inventario - Costo o Gasto para declaración de IR"
    End Select
End Function

Private Function SeleccionaPeriodo(ByVal num As Integer) As String
Select Case num
    Case 0
            SeleccionaPeriodo = "Diarios"
    Case 1
            SeleccionaPeriodo = "Semanal"
    Case 2
            SeleccionaPeriodo = "Quincenal"
    Case 3
            SeleccionaPeriodo = "Mensual"
    Case 4
            SeleccionaPeriodo = "Bbimensual"
    Case 5
            SeleccionaPeriodo = "Trimestral"
    Case 6
            SeleccionaPeriodo = "Cuatrimestre"
    Case 7
            SeleccionaPeriodo = "Semestral"
    Case 8
            SeleccionaPeriodo = "Anual"
    End Select
End Function

'Agregado JEAA Enero 13/2005
Public Function TotalAnticipos(ByVal mobjGnComp As GNComprobante) As Double
    Dim i As Long, Pck As PCKardex, cancela As Double
    For i = 1 To mobjGnComp.CountPCKardex
        Set Pck = mobjGnComp.PCKardex(i)
        'Solo imprimimos si el documento está asignado a un doc. origen
        'y si es anticipo
        If Pck.IdAsignado <> 0 And Pck.haber = 0 Then     'Anticipos
            cancela = cancela + (Pck.debe + Pck.haber)
        End If
    Next i
    Set mobjGnComp = Nothing
    Set Pck = Nothing
    TotalAnticipos = cancela
End Function

Private Function TotalBaseImponible(ByRef GnComp As GNComprobante) As Currency
    Dim tsk As TSKardexRet, i As Long
    Dim total As Currency, v As Variant
     v = SeparaParamVar("TODOS")
    For i = 1 To GnComp.CountTSKardexRet
        Set tsk = GnComp.TSKardexRet(i)
        If UCase(v(1)) <> "TODOS" Or v(1) = "" Then            'Resolver el caso en el que no pusieron ningún parámetro para imprimir TOTRET
            If InStr(tsk.CodRetencion, v(1)) Then total = total + Abs(tsk.base)   'Preguntar
        Else
            total = total + Abs(tsk.base)   'Preguntar
        End If
    Next i
    TotalBaseImponible = total
End Function

Private Function TotalRetIVA(ByRef mGnComp As GNComprobante) As Currency
    Dim t As Currency, valorIR As Currency, valorIVA As Currency, P As Currency
    Dim GNC As GNComprobante, sql As String, TransId As Long, RsAux As Recordset
    Dim GNC1 As GNComprobante
    Dim tsAUX As TSRetencion, SUBTOT As Currency
    Set RsAux = mGnComp.ListaTSKardexRet
        Dim RSAUX1 As Recordset
        sql = "select pck.TransID as transid from pckardex pck"
        sql = sql & " inner join gncomprobante gnc"
        sql = sql & " on pck.transid=gnc.transid"
        sql = sql & " where id=" & mGnComp.PCKardex(1).IdAsignado
        Set RSAUX1 = mGnComp.Empresa.OpenRecordset(sql)
        If Not RSAUX1.EOF Then
            Set GNC = mGnComp.Empresa.RecuperaGNComprobante(RSAUX1.Fields("transid"))
            If Not GNC Is Nothing Then
                Set GNC1 = mGnComp.Empresa.RecuperaGNComprobante(GNC.TransId)
                If Not GNC1 Is Nothing Then
                        P = GNC1.IVRecargoIVA(True, False)
                        valorIVA = MiCCur(Format$(P, GNC1.FormatoMoneda))  'Redondea al formato de moneda
                        SUBTOT = SUBTOT + valorIVA
                End If
            End If
        End If
        
        Set RsAux = mGnComp.ListaTSKardexRet
         If Not RsAux.EOF Then
                RsAux.MoveLast
                RsAux.MoveFirst
        End If
        Do Until RsAux.EOF
            If InStr(RsAux!CodRetencion, "IV") Then
                Set tsAUX = mGnComp.Empresa.RecuperaTSRetencion(RsAux!CodRetencion)
                If tsAUX Is Nothing Then
                    TotalRetIVA = 0
                    Exit Function
                Else
                    SUBTOT = SUBTOT - (valorIVA - (Abs(RsAux!base) + Abs(RsAux!debe) - Abs(RsAux!haber)))
                End If
            End If
            RsAux.MoveNext
        Loop
        TotalRetIVA = SUBTOT
        Set RsAux = Nothing
        Set tsAUX = Nothing
        Set GNC = Nothing
        Set GNC1 = Nothing
        Set RSAUX1 = Nothing
End Function

'*** MAKOTO 29/ene/01 Agregado
'Para convertir de otro tipo a Currency sin que se de error de conversión
Public Function MiCCur(ByVal v As Variant) As Currency
    If IsNumeric(v) Then MiCCur = CCur(v)
End Function

Private Function TotalRetIR(ByRef mGnComp As GNComprobante) As Currency
    Dim t As Currency, valorIR As Currency, valorIVA As Currency, P As Currency
    Dim GNC As GNComprobante, sql As String, TransId As Long, RsAux As Recordset
    Dim GNC1 As GNComprobante
    Dim tsAUX As TSRetencion, SUBTOT As Currency
    Set RsAux = mGnComp.ListaTSKardexRet
        Dim RSAUX1 As Recordset
        sql = "select pck.TransID as transid from pckardex pck"
        sql = sql & " inner join gncomprobante gnc"
        sql = sql & " on pck.transid=gnc.transid"
        sql = sql & " where id=" & mGnComp.PCKardex(1).IdAsignado
        Set RSAUX1 = mGnComp.Empresa.OpenRecordset(sql)
        If Not RSAUX1.EOF Then
            Set GNC = mGnComp.Empresa.RecuperaGNComprobante(RSAUX1.Fields("transid"))
            If Not GNC Is Nothing Then
                Set GNC1 = mGnComp.Empresa.RecuperaGNComprobante(GNC.TransId)
                If Not GNC1 Is Nothing Then
                                t = GNC1.IVKardexTotal(True) + GNC1.IVRecargoAntesIVA(True, False)
                                valorIR = MiCCur(Format$(t, GNC1.FormatoMoneda))  'Redondea al formato de moneda                    tot
                                SUBTOT = SUBTOT + valorIR
                End If
            End If
        End If
        
        Set RsAux = mGnComp.ListaTSKardexRet
         If Not RsAux.EOF Then
                RsAux.MoveLast
                RsAux.MoveFirst
        End If
        Do Until RsAux.EOF
            If InStr(RsAux!CodRetencion, "IR") Then
                Set tsAUX = mGnComp.Empresa.RecuperaTSRetencion(RsAux!CodRetencion)
                If tsAUX Is Nothing Then
                    TotalRetIR = 0
                    Exit Function
                Else
                    SUBTOT = SUBTOT + (valorIVA - (Abs(RsAux!base) + Abs(RsAux!debe) - Abs(RsAux!haber)))
                End If
            End If
            RsAux.MoveNext
        Loop
        TotalRetIR = SUBTOT
        Set RsAux = Nothing
        Set tsAUX = Nothing
        Set GNC = Nothing
        Set GNC1 = Nothing
        Set RSAUX1 = Nothing
End Function

Private Function CalculoTotalIVA(ByRef mGnComp As GNComprobante) As Currency
    Dim t As Currency, valorIR As Currency, valorIVA As Currency, P As Currency
    Dim GNC As GNComprobante, sql As String, TransId As Long, RsAux As Recordset
    Dim GNC1 As GNComprobante
    Dim tsAUX As TSRetencion, SUBTOT As Currency
    Set RsAux = mGnComp.ListaTSKardexRet
        Dim RSAUX1 As Recordset
        sql = "select pck.TransID as transid from pckardex pck"
        sql = sql & " inner join gncomprobante gnc"
        sql = sql & " on pck.transid=gnc.transid"
        sql = sql & " where id=" & mGnComp.PCKardex(1).IdAsignado
        Set RSAUX1 = mGnComp.Empresa.OpenRecordset(sql)
        If Not RSAUX1.EOF Then
            Set GNC = mGnComp.Empresa.RecuperaGNComprobante(RSAUX1.Fields("transid"))
            If Not GNC Is Nothing Then
                Set GNC1 = mGnComp.Empresa.RecuperaGNComprobante(GNC.TransId)
                If Not GNC1 Is Nothing Then
                        P = GNC1.IVRecargoIVA(True, False)
                        valorIVA = MiCCur(Format$(P, GNC1.FormatoMoneda))  'Redondea al formato de moneda
                        SUBTOT = SUBTOT + valorIVA
                End If
            End If
        End If
        
        CalculoTotalIVA = SUBTOT
        Set RsAux = Nothing
        Set tsAUX = Nothing
        Set GNC = Nothing
        Set GNC1 = Nothing
        Set RSAUX1 = Nothing
End Function


'SUBTOTAL +IVA
Private Function ValorNetoMasIVA(ByRef GnComp As GNComprobante, ByRef cad As String) As Currency
    'saca  el valor  neto  de la factura
    'suma  Pt + Recargos(especificados)
    Dim v As Variant, numRec As Integer
    Dim i As Integer, valIva As Currency, PorcentajeRecargo As Currency, j As Long
    Dim ivr As IVRecargo, ivkr As IVKardexRecargo, ivkrd As IVRecargoDetalle
    Dim xi As Long
    v = Split(cad, ";")
    If IsEmpty(v) Then Exit Function
    numRec = UBound(v, 1)
    ValorNetoMasIVA = Abs(GnComp.IVKardexPTotal(True))    ' sin recargos
    valIva = Recargo(GnComp, IIf(Len(GnComp.Empresa.GNOpcion.ObtenerValor("RecDescParaIVA")) > 0, GnComp.Empresa.GNOpcion.ObtenerValor("RecDescParaIVA"), "IVA"))
'    If v(3) = 0 Then
'        PorcentajeRecargo = 1
'    Else
        PorcentajeRecargo = GnComp.Empresa.GNOpcion.PorcentajeIVA ' v(3)
'    End If
    'For i = 1 To numRec
        If v(3) <> IIf(Len(GnComp.Empresa.GNOpcion.ObtenerValor("RecDescParaIVA")) > 0, GnComp.Empresa.GNOpcion.ObtenerValor("RecDescParaIVA"), "IVA") Then
            ValorNetoMasIVA = ValorNetoMasIVA + Abs(RecargoMasIva(GnComp, CStr(v(3)), PorcentajeRecargo))
        End If
'    Next i
    ValorNetoMasIVA = ValorNetoMasIVA + valIva
End Function


Private Function RecargoMasIva(ByRef GnComp As GNComprobante, ByRef cod As String, ByRef valor As Currency) As Currency
    'Busca  el codigo  en  IVKardexRecargo
    'si existe en la transaccion  devuelve  el valor
    Dim ivr As IVRecargo, ivkr As IVKardexRecargo, ivk As IVKardex
    Dim i As Long
        Set ivr = GnComp.Empresa.RecuperaIVRecargo(cod)
        If ivr Is Nothing Then
            Err.Raise ERR_NOIMPRIME, App.EXEName, "No existe recargo: " & cod
        Else
            For i = 1 To GnComp.CountIVKardexRecargo
                Set ivkr = GnComp.IVKardexRecargo(i)
                If ivr.CodRecargo = ivkr.CodRecargo Then
                    RecargoMasIva = (ivkr.valor * (1 + (valor)))  ' para que el valor sea inverso
                    Exit Function
                End If
            Next i
            RecargoMasIva = 0
        End If
End Function


Private Function CostoNeto(ByRef GnComp As GNComprobante, ByRef cad As String) As Currency
    'saca  el valor  neto  de la factura
    'suma  Ct + Recargos(especificados)
    Dim v As Variant, numRec As Integer
    Dim i As Integer
    v = Split(cad, ";")
    If IsEmpty(v) Then Exit Function
    numRec = UBound(v, 1)
    CostoNeto = Abs(GnComp.IVKardexCTotal(True))     ' sin recargos
    For i = 3 To numRec
        CostoNeto = CostoNeto + Recargo(GnComp, CStr(v(i)))
    Next i
End Function

Private Function SubTotalCSIva(ByRef GnComp As GNComprobante, ByVal CSIva As Byte) As Currency
'Agregado Oliver
'CSIva=0  ---> Sin Iva     CSIva=1 ---> Con Iva
'Reutilizado de Angel

    Dim ivk As IVKardex
    Dim i As Long
    For i = 1 To GnComp.CountIVKardex
        If CSIva = 0 Then
            Set ivk = GnComp.IVKardex(i)
            If ivk.IVA = 0 Then SubTotalCSIva = SubTotalCSIva + Abs(ivk.PrecioTotal)
        Else
            Set ivk = GnComp.IVKardex(i)
            If ivk.IVA <> 0 Then SubTotalCSIva = SubTotalCSIva + Abs(ivk.PrecioTotal)
        End If
    Next i
End Function


Private Function CantTotalTransferencia(ByRef GnComp As GNComprobante) As Double
    'devuelve la cantidad  total de la transaccion
    Dim ivk As IVKardex
    Dim i As Long
    CantTotalTransferencia = 0
     For i = 1 To GnComp.CountIVKardex
        Set ivk = GnComp.IVKardex(i)
        'jeaa 06/01/05 para que no se sumen los items de servicio
        Debug.Print GnComp.IVKardex(i).CodInventario
        If GnComp.IVKardex(i).CodInventario <> "-" And GnComp.IVKardex(i).CodInventario <> "+" And ivk.Cantidad > 0 Then
            CantTotalTransferencia = CantTotalTransferencia + ivk.Cantidad
        End If
    Next i
    CantTotalTransferencia = Abs(CantTotalTransferencia)    'valor   absoluto
End Function

Private Function TotalDetEfectivo(ByRef GnComp As GNComprobante) As Currency
    Dim tsde As TSDetalleEfectivo
    Dim i As Long
    TotalDetEfectivo = 0
     For i = 1 To GnComp.CountTSDetalleEfectivo
        Set tsde = GnComp.TSDetalleEfectivo(i)
        TotalDetEfectivo = TotalDetEfectivo + (tsde.valor * tsde.Cantidad)
    Next i
    Set tsde = Nothing
End Function

Private Function TotalDetTarjeta(ByRef GnComp As GNComprobante) As Currency
    Dim tsdt As TSDetalleTarjeta
    Dim i As Long
    TotalDetTarjeta = 0
     For i = 1 To GnComp.CountTSDetalleTarjeta
        Set tsdt = GnComp.TSDetalleTarjeta(i)
        TotalDetTarjeta = TotalDetTarjeta + (tsdt.valor)
    Next i
    Set tsdt = Nothing
End Function


Private Function TotalDetCheque(ByRef GnComp As GNComprobante) As Currency
    Dim TsdCh As TSDetalleCheque
    Dim i As Long
    TotalDetCheque = 0
     For i = 1 To GnComp.CountTSDetalleCheque
        Set TsdCh = GnComp.TSDetalleCheque(i)
        TotalDetCheque = TotalDetCheque + (TsdCh.valor)
    Next i
    Set TsdCh = Nothing
End Function


Private Function TotalDetVmanual(ByRef GnComp As GNComprobante) As Currency
    Dim TsdVM As TSDetalleVManuales
    Dim i As Long
    TotalDetVmanual = 0
     For i = 1 To GnComp.CountTSDetalleVManuales
        Set TsdVM = GnComp.TSDetalleVManuales(i)
        TotalDetVmanual = TotalDetVmanual + (TsdVM.valor)
    Next i
    Set TsdVM = Nothing
End Function


Private Function TotalIngresosCierre(ByRef GnComp As GNComprobante) As Currency
    Dim tsde As TSDetalleEfectivo
    Dim i As Long, TotalDetEfectivo As Currency, TotalDetTarjeta  As Currency
    Dim TotalDetCheque  As Currency, TotalDetVmanual  As Currency, TotalDetVcredito As Currency
    Dim Totalingreso As Currency
    Dim tsdt As TSDetalleTarjeta
    Dim TsdCh As TSDetalleCheque
    Dim TsdVM As TSDetalleVManuales
    Dim TsdVC As TSDetalleVCredito
    Dim TsdIn As TSDetalleIngreso
    
    TotalDetEfectivo = 0
     For i = 1 To GnComp.CountTSDetalleEfectivo
        Set tsde = GnComp.TSDetalleEfectivo(i)
        TotalDetEfectivo = TotalDetEfectivo + (tsde.valor * tsde.Cantidad)
    Next i

    
    TotalDetTarjeta = 0
     For i = 1 To GnComp.CountTSDetalleTarjeta
        Set tsdt = GnComp.TSDetalleTarjeta(i)
        TotalDetTarjeta = TotalDetTarjeta + (tsdt.valor)
    Next i
    
    
    TotalDetCheque = 0
     For i = 1 To GnComp.CountTSDetalleCheque
        Set TsdCh = GnComp.TSDetalleCheque(i)
        TotalDetCheque = TotalDetCheque + (TsdCh.valor)
    Next i
    
    
    
    TotalDetVmanual = 0
     For i = 1 To GnComp.CountTSDetalleVManuales
        Set TsdVM = GnComp.TSDetalleVManuales(i)
        TotalDetVmanual = TotalDetVmanual + (TsdVM.valor)
    Next i
    
    TotalDetVcredito = 0
     For i = 1 To GnComp.CountTSDetalleVCredito
        Set TsdVC = GnComp.TSDetalleVCredito(i)
        TotalDetVcredito = TotalDetVcredito + (TsdVC.valor)
    Next i
    
    Totalingreso = 0
     For i = 1 To GnComp.CountTSDetalleIngreso
        Set TsdIn = GnComp.TSDetalleIngreso(i)
        Totalingreso = Totalingreso + (TsdIn.valor)
    Next i
    
    
    Set tsde = Nothing
    Set tsdt = Nothing
    Set TsdVM = Nothing
    Set TsdCh = Nothing
    Set TsdVC = Nothing
    Set TsdIn = Nothing
    
    TotalIngresosCierre = TotalDetEfectivo + TotalDetTarjeta + TotalDetCheque + TotalDetVmanual + TotalDetVcredito + Totalingreso
End Function


Private Function TotalEgresosCierre(ByRef GnComp As GNComprobante) As Currency
    Dim tsde As TSDetalleEgreso
    Dim i As Long, TotalEgreso As Currency
    TotalEgreso = 0
     For i = 1 To GnComp.CountTSDetalleEgreso
        Set tsde = GnComp.TSDetalleEgreso(i)
        TotalEgreso = TotalEgreso + (tsde.valor)
    Next i
    Set tsde = Nothing
    TotalEgresosCierre = TotalEgreso
End Function


Private Function TotalDetVcredito(ByRef GnComp As GNComprobante) As Currency
    Dim TsdVC As TSDetalleVCredito
    Dim i As Long, TotalVCredito As Currency
    
    TotalVCredito = 0
     For i = 1 To GnComp.CountTSDetalleVCredito
        Set TsdVC = GnComp.TSDetalleVCredito(i)
        TotalVCredito = TotalVCredito + (TsdVC.valor)
    Next i

    
    Set TsdVC = Nothing
    
    TotalDetVcredito = TotalVCredito
End Function


Private Function TotalDetIngresos(ByRef GnComp As GNComprobante) As Currency
    Dim TsdIn As TSDetalleIngreso
    Dim i As Long, Totalingreso As Currency
    
    Totalingreso = 0
     For i = 1 To GnComp.CountTSDetalleIngreso
        Set TsdIn = GnComp.TSDetalleIngreso(i)
        Totalingreso = Totalingreso + (TsdIn.valor)
    Next i

    
    Set TsdIn = Nothing
    
    TotalDetIngresos = Totalingreso
End Function

Private Function ValorNetoIVA(ByRef GnComp As GNComprobante, ByRef cad As String, BandIva As Boolean) As Currency
    'saca  el valor  neto  de la factura
    'suma  Pt + Recargos(especificados)
    Dim v As Variant, numRec As Integer
    Dim i As Integer
    v = Split(cad, ";")
    If IsEmpty(v) Then Exit Function
    numRec = UBound(v, 1)
    ValorNetoIVA = Abs(GnComp.IVKardexPTotalIVA(True, BandIva))   ' sin recargos
    For i = 3 To numRec
        ValorNetoIVA = ValorNetoIVA + Recargo(GnComp, CStr(v(i)))
    Next i
End Function

Private Function TotalDetCobros(ByRef GnComp As GNComprobante) As Currency
    Dim TsdI As TSDetalleIngreso
    Dim i As Long
    TotalDetCobros = 0
     For i = 1 To GnComp.CountTSDetalleIngreso
        Set TsdI = GnComp.TSDetalleIngreso(i)
        TotalDetCobros = TotalDetCobros + (TsdI.valor)
    Next i
    Set TsdI = Nothing
End Function

Private Function TotalDetCobrosRT(ByRef GnComp As GNComprobante) As Currency
    Dim TsdI As TSDetalleIngresoRT
    Dim i As Long
    TotalDetCobrosRT = 0
     For i = 1 To GnComp.CountTSDetalleIngresoRT
        Set TsdI = GnComp.TSDetalleIngresoRT(i)
        TotalDetCobrosRT = TotalDetCobrosRT + (TsdI.valor)
    Next i
    Set TsdI = Nothing
End Function

Private Function AFRecargo(ByRef GnComp As GNComprobante, ByRef cod As String) As Currency
    'Busca  el codigo  en  IVKardexRecargo
    'si existe en la transaccion  devuelve  el valor
    Dim ivr As IVRecargo, ivkr As AFKardexRecargo, ivk As AFKardex
    Dim i As Long
    If UCase(cod) = "DESCXITEM" Then
        AFRecargo = 0
        For i = 1 To GnComp.CountAFKardex
            Set ivk = GnComp.AFKardex(i)
            AFRecargo = AFRecargo + (ivk.Descuento * ivk.PrecioTotal)
        Next i
        'MsgBox AfRecargo
    ElseIf UCase(cod) = "DESCXTODO" Then
        AFRecargo = 0
        For i = 1 To GnComp.CountAFKardex
            Set ivk = GnComp.AFKardex(i)
            AFRecargo = AFRecargo + (ivk.Descuento * ivk.PrecioTotal)
        Next i
        Set ivr = GnComp.Empresa.RecuperaIVRecargo("DESC")
        If ivr Is Nothing Then
            Err.Raise ERR_NOIMPRIME, App.EXEName, "No existe AfRecargo: " & "DESC"
        Else
            For i = 1 To GnComp.CountAFKardexRecargo
                Set ivkr = GnComp.AFKardexRecargo(i)
                If ivr.CodRecargo = ivkr.CodRecargo Then
                    AFRecargo = AFRecargo + ivkr.valor
                    Exit Function
                End If
            Next i
        End If
    ElseIf UCase(cod) = "DESCCXITEM" Then
        AFRecargo = 0
        For i = 1 To GnComp.CountAFKardex
            Set ivk = GnComp.AFKardex(i)
            AFRecargo = AFRecargo + (ivk.Descuento * ivk.CostoTotal)
        Next i
        'MsgBox AfRecargo
    ElseIf UCase(cod) = "DESCCXTODO" Then
        AFRecargo = 0
        For i = 1 To GnComp.CountAFKardex
            Set ivk = GnComp.AFKardex(i)
            AFRecargo = AFRecargo + (ivk.Descuento * ivk.CostoTotal)
        Next i
        Set ivr = GnComp.Empresa.RecuperaIVRecargo("DESC")
        If ivr Is Nothing Then
            Err.Raise ERR_NOIMPRIME, App.EXEName, "No existe AfRecargo: " & "DESC"
        Else
            For i = 1 To GnComp.CountAFKardexRecargo
                Set ivkr = GnComp.AFKardexRecargo(i)
                If ivr.CodRecargo = ivkr.CodRecargo Then
                    AFRecargo = AFRecargo + ivkr.valor
                    Exit Function
                End If
            Next i
        End If
    ElseIf UCase(cod) = "DESCXTODOIVA" Then
        AFRecargo = 0
        For i = 1 To GnComp.CountAFKardex
            Set ivk = GnComp.AFKardex(i)
            AFRecargo = AFRecargo + (ivk.Descuento * ivk.PrecioTotal)
        Next i
        Set ivr = GnComp.Empresa.RecuperaIVRecargo("DESC")
        If ivr Is Nothing Then
            Err.Raise ERR_NOIMPRIME, App.EXEName, "No existe AfRecargo: " & "DESC"
        Else
            For i = 1 To GnComp.CountAFKardexRecargo
                Set ivkr = GnComp.AFKardexRecargo(i)
                If ivr.CodRecargo = ivkr.CodRecargo Then
                    AFRecargo = AFRecargo + ivkr.valor
                    Exit Function
                End If
            Next i
        End If
        Set ivr = GnComp.Empresa.RecuperaIVRecargo("IVA")
        If ivr Is Nothing Then
            Err.Raise ERR_NOIMPRIME, App.EXEName, "No existe AfRecargo: " & "IVA"
        Else
            For i = 1 To GnComp.CountAFKardexRecargo
                Set ivkr = GnComp.AFKardexRecargo(i)
                If ivr.CodRecargo = ivkr.CodRecargo Then
                    AFRecargo = AFRecargo + ivkr.valor
                    Exit Function
                End If
            Next i
        End If
    
    Else
        Set ivr = GnComp.Empresa.RecuperaIVRecargo(cod)
        If ivr Is Nothing Then
            Err.Raise ERR_NOIMPRIME, App.EXEName, "No existe AfRecargo: " & cod
        Else
            For i = 1 To GnComp.CountAFKardexRecargo
                Set ivkr = GnComp.AFKardexRecargo(i)
                If ivr.CodRecargo = ivkr.CodRecargo Then
                    AFRecargo = ivkr.valor
                    Exit Function
                End If
            Next i
            AFRecargo = 0
        End If
    End If
End Function
Public Sub gnProcesaComRet(cad As String, Sptxt As SiiPrint.PrintTxt, gc As GNComprobante, codEmpleado As String)

    Dim lon As Integer, v As Variant, v1 As Variant
    Dim fmt As String
    Dim cod As String, s As String
    Dim posini As Integer, posfin As Integer, w As Variant
    Dim RucConta As String
    
    Dim pc As pcProvCli
    Set pc = gc.Empresa.RecuperaPCProvCli(codEmpleado)

    With Sptxt
    
        v = Split(cad, ";")
        If IsEmpty(v) Then Exit Sub
        
        fmt = gfmt
        'Corregir Error
        If UBound(v, 1) >= 1 Then lon = IIf(Not (IsNumeric(v(1))), 0, v(1))
        If UBound(v, 1) >= 2 Then fmt = generafmt(CStr(v(2)), CStr(v(0)))
        If UBound(v, 1) >= 3 Then cod = v(3)
       
        
     '   MsgBox v(0)
        Select Case v(0)
     
        Case "NUMPAG":  .PrintLine Sptxt.Pagina
        'Campos de Informacion de la empresa
        
        Case "EJEFISCAL": .PrintLine .Rellenar(Format$(gc.FechaDevol, "yyyy"), lon, True)
        Case "AÑO": .PrintLine .Rellenar(Format$(gc.FechaTrans, "yyyy"), lon, True)
        Case "MES": .PrintLine .Rellenar(Format$(gc.FechaTrans, "mm"), lon, True)
        Case "DIA": .PrintLine .Rellenar(Format$(gc.FechaTrans, "dd"), lon, True)
        
        Case "NOMEMP107": .PrintLine .Rellenar(gc.Empresa.GNOpcion.NombreEmpresa, lon, True)
        Case "RUCEMP107": .PrintLine .Rellenar(gc.Empresa.GNOpcion.RUC, lon, True)
        Case "RUCCONTA107":
            RucConta = gc.Empresa.GNOpcion.ObtenerValor("RUCContdor")
            .PrintLine .Rellenar(RucConta, lon, True)
                
        Case "CEDEMPL": If Not pc Is Nothing Then .PrintLine .Rellenar(pc.RUC, lon, True)
        Case "NOMEMPL": If Not pc Is Nothing Then .PrintLine .Rellenar(pc.Nombre, lon, True)
        Case "INGLIQ":  .PrintLine .Rellenar(Format(gc.ImpRelDep("Ingresos", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "APOIESS": .PrintLine .Rellenar(Format(gc.ImpRelDep("AportePersonal", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "BASEIMP": .PrintLine .Rellenar(Format(gc.ImpRelDep("BaseImponible", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "VALORRETENIDO": .PrintLine .Rellenar(Format(gc.ImpRelDep("ValorRetenido", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "REMUNERACION": .PrintLine .Rellenar(Format(gc.ImpRelDep("OtraRemuneracion", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "XIII": .PrintLine .Rellenar(Format(gc.ImpRelDep("XIII", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy"))), lon, False)
        Case "XIV": .PrintLine .Rellenar(Format(gc.ImpRelDep("XIV", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "FR":  .PrintLine .Rellenar(Format(gc.ImpRelDep("FR", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "UTILIDAD":  .PrintLine .Rellenar(Format(gc.ImpRelDep("Utilidad", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "DESHAUCIO":  .PrintLine .Rellenar(Format(gc.ImpRelDep("Deshaucio", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "GPVIVIENDA":  .PrintLine .Rellenar(Format(gc.ImpRelDep("GPVivienda", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "GPSALUD":  .PrintLine .Rellenar(Format(gc.ImpRelDep("GPSalud", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "GPEDUCACION":  .PrintLine .Rellenar(Format(gc.ImpRelDep("GPEducacion", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "GPALIMENTACION":   .PrintLine .Rellenar(Format(gc.ImpRelDep("GPAlimentacion", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "GPVESTIMENTA":  .PrintLine .Rellenar(Format(gc.ImpRelDep("GPVestimenta", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "REBAJAESPECIAL":  .PrintLine .Rellenar(Format(gc.ImpRelDep("RebajaEspecial", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "REBAJAESPECIAL3E":  .PrintLine .Rellenar(Format(gc.ImpRelDep("RebajaEspecial3E", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "IR":            .PrintLine .Rellenar(Format(gc.ImpRelDep("ImpRentEmpl", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "SUBTOTAL": .PrintLine .Rellenar(Format(gc.SubTotal107(pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "NUMRET":             .PrintLine .Rellenar(Format(gc.ImpRelDep("NumRet", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "NUMMESES":                .PrintLine .Rellenar(Format(gc.ImpRelDep("NumMeses", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "INGGRAVOTROSEMP":  .PrintLine .Rellenar(Format(gc.ImpRelDep("IngGravOtrosEmp", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "GPOTROSEMP":  .PrintLine .Rellenar(Format(gc.ImpRelDep("GPOtrosEmp", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "OTRASREB": .PrintLine .Rellenar(Format(gc.ImpRelDep("OtrasReb", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        
        Case "IMPCAU": .PrintLine .Rellenar(Format(gc.ImpRelDep("IRCausado", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "VALORIR":  .PrintLine .Rellenar(Format(gc.ImpRelDep("ValorIR", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        Case "VALORIRANT":  .PrintLine .Rellenar(Format(gc.ImpRelDep("ValorIRAnt", pc.CodProvCli, Format$(gc.FechaDevol, "yyyy")), fmt), lon, False)
        
        
        Case "SPACE":  .PrintLine Space(lon)
        
        
                  
        End Select
    End With

End Sub

Private Function PorcentajeRecargo(ByRef GnComp As GNComprobante, ByRef cod As String) As Currency
    'Busca  el codigo  en  IVKardexRecargo
    'si existe en la transaccion  devuelve  el valor
    Dim ivr As IVRecargo, ivkr As IVKardexRecargo, ivk As IVKardex
    Dim i As Long
        Set ivr = GnComp.Empresa.RecuperaIVRecargo(cod)
        If ivr Is Nothing Then
            Err.Raise ERR_NOIMPRIME, App.EXEName, "No existe recargo: " & cod
        Else
            For i = 1 To GnComp.CountIVKardexRecargo
                Set ivkr = GnComp.IVKardexRecargo(i)
                If ivr.CodRecargo = ivkr.CodRecargo Then
                    PorcentajeRecargo = Round((ivkr.Porcentaje * 100), 2)
                    Exit Function
                End If
            Next i
            PorcentajeRecargo = 0
        End If

End Function

Public Sub gnProcesaSolCredito(cad As String, Sptxt As SiiPrint.PrintTxt, objpcs As PCSOLCREProvCli)
    Dim lon As Integer, v As Variant
    Dim fmt As String
    Dim cli As pcProvCli
    Dim Grupo As PCGrupo
    Dim cod As String, s As String
    Dim posini As Integer, posfin As Integer
    Dim pcsC As PCSOLCREProvCli
    Dim pcsG As PCSOLCREProvCli
    Dim Gar As pcProvCli
    Dim CANTON As PCCanton
    Dim pcPROV As PCProvincia
    Dim pcParr As PCParroquia
    Dim GARCANTON As PCCanton
    Dim GARPROV As PCProvincia
    Dim GARParr As PCParroquia
    Dim pcAct As PCActConyuge
    Dim GarAct As PCActConyuge
    
    Dim gn As GNComprobante
    Set gn = objpcs.Empresa.RecuperaGNComprobante(objpcs.IdTransFuente)
   ' If objpcs.TipoSolicitud = 0 Then 'recupera datos segun cliente
        Set cli = objpcs.Empresa.RecuperaPCProvCli(objpcs.CodProvCli)
        Set Gar = objpcs.Empresa.RecuperaPCProvCli(objpcs.CodGar)
        Set pcAct = objpcs.Empresa.RecuperarPCActConyuge(cli.IdProvcli)
        If Not Gar Is Nothing Then
            Set GarAct = objpcs.Empresa.RecuperarPCActConyuge(Gar.IdProvcli)
        End If
        
       'Set Gar = objpcs.Empresa.RecuperaPCProvClixSolCred("1", objpcs.IdTransFuente)
         'Set pcsC = objpcs.Empresa.RecuperaPCSolCreProvCli(objpcs.Id)
        'If Not Gar Is Nothing Then
        '    Set pcsG = objpcs.Empresa.RecuperaPCSolCreProvCli(Gar.idSolCredito)
        'End If
    'Else 'recupera datos segun garante
        'Set Gar = objpcs.Empresa.RecuperaPCProvCliQuick(objpcs.CodProvCli)
        'Set cli = objpcs.Empresa.RecuperaPCProvClixSolCred("0", objpcs.IdTransFuente)
        'Set pcsG = objpcs.Empresa.RecuperaPCSolCreProvCli(objpcs.Id)
        'Set pcsC = objpcs.Empresa.RecuperaPCSolCreProvCli(cli.idSolCredito)
   ' End If
   With Sptxt
        
        v = Split(cad, ";")
        If IsEmpty(v) Then Exit Sub
        fmt = gfmt
        'Corregir Error
        If UBound(v, 1) >= 1 Then lon = IIf(Not (IsNumeric(v(1))), 0, v(1))
        If UBound(v, 1) >= 2 Then fmt = generafmt(CStr(v(2)), CStr(v(0)))
        If UBound(v, 1) >= 3 Then cod = v(3)
'        If v(0) = "GARACTIVIDAD" Then
'            MsgBox "PARAR"
'        End If
        Select Case v(0)
            Case "SPACE":  .PrintLine Space(lon)
            Case "FECHA": .PrintLine .Rellenar(objpcs.FechaSolicitud, lon, True)
            Case "CLIINGRESOS":
                If Not pcAct Is Nothing Then .PrintLine .Rellenar(pcAct.IngresosSoli, lon, True)
'            Case "CLITIPOVIVENDA":
'                 Select Case pcAct.TipoVivienda
'                    Case 0: .PrintLine .Rellenar("PROPIA", lon, True)
'                    Case 1: .PrintLine .Rellenar("ARRENDADA", lon, True)
'                    Case 2: .PrintLine .Rellenar("AMBULATORIA", lon, True)
'                    Case 3: .PrintLine .Rellenar("VIVE CON FAMILAR", lon, True)
'                 End Select QUITADO NO HAY EN EL CAT
'            Case "CLIANIORESIDENCIA":
'                .PrintLine .Rellenar(pcAct.AnioResidencia, lon, True)
            Case "CLIACTIVIDAD":
                If Not pcAct Is Nothing Then .PrintLine .Rellenar(pcAct.ActividadSoli, lon, True)
            Case "CLINOMTRAB":
                If Not pcAct Is Nothing Then .PrintLine .Rellenar(pcAct.NombreTrabajoSoli, lon, True)
            Case "CLIDIRTRAB":
                If Not pcAct Is Nothing Then .PrintLine .Rellenar(pcAct.DirTrabajoSoli, lon, True)
            Case "CLITELTRAB":
                If Not pcAct Is Nothing Then .PrintLine .Rellenar(pcAct.TelfActividadSol, lon, True)
            Case "CLIANTTRAB":
                If Not pcAct Is Nothing Then .PrintLine .Rellenar(pcAct.AntiguedadSoli, lon, True)
            Case "CLIREFDOMICILIO":
                .PrintLine .Rellenar(cli.DescripcionDetalle, lon, True)
'            Case "NOMFAMILIAR1": .PrintLine .Rellenar(pcsC.NombreFami, lon, True)
'            Case "RELFAMILIAR1": .PrintLine .Rellenar(pcsC.RelacionFami, lon, True)
'            Case "TELFAMILIAR1": .PrintLine .Rellenar(pcsC.TelfFami, lon, True)
'            Case "NOMFAMILIAR2": .PrintLine .Rellenar(pcsC.NombreFami2, lon, True)
'            Case "RELFAMILIAR2": .PrintLine .Rellenar(pcsC.RelacionFami2, lon, True)
'            Case "TELFAMILIAR2": .PrintLine .Rellenar(pcsC.TelfFami2, lon, True)
'            Case "NOMCOMERCIAL1": .PrintLine .Rellenar(pcsC.NombreComer1, lon, True)
'            Case "DIRCOMERCIAL1": .PrintLine .Rellenar(pcsC.DirComer1, lon, True)
'            Case "TELCOMERCIAL1": .PrintLine .Rellenar(pcsC.TelfComer1, lon, True)
'            Case "NOMCOMERCIAL2": .PrintLine .Rellenar(pcsC.NombreComer2, lon, True)
'            Case "DIRCOMERCIAL2": .PrintLine .Rellenar(pcsC.DirComer2, lon, True)
'            Case "TELCOMERCIAL2": .PrintLine .Rellenar(pcsC.TelfComer2, lon, True)
            Case "MONTO": .PrintLine .Rellenar(objpcs.MontoCredito, lon, True)
            'Case "RUCGAR": .PrintLine .Rellenar(pcsC.NombreComer2, lon, True)
           Case "CODCLI", "NOMCLI", "TELCLI", "RUCCLI", "DIRCLI", "CIUCLI", _
               "PCCODGRUPO1", "PCDESGRUPO1", "PCCODGRUPO2", "PCDESGRUPO2", _
                "PCCODGRUPO3", "PCDESGRUPO3", "PCCODGRUPO4", "PCDESGRUPO4", _
                "TELCLI2", "TELCLI3", "FAXCLI", "DIRCLI2", "CODPOSTALCLI", "CIUCLI", _
                "PROVINCLI", "PAISCLI", "AUTSRICLI", "BANCOCLI", "NUMCUECLI", "NOMALTCLI", "LIMITECREDITO", _
                "NOMALTCLI", "PCCODGRUPO4", "PCDESGRUPO4", _
                "PCCANTON", "PCPROVINCIA", "PCPARROQUIA", "EMAILCLI", "SWIT", "DIRBANCO", "TELBANCO"
            If Not (cli Is Nothing) Then
                Select Case v(0)
                Case "CODCLI":   .PrintLine .Rellenar(cli.CodProvCli, lon, True)
                Case "NOMCLI": .PrintLine .Rellenar(cli.Nombre, lon, True)
                Case "NOMALTCLI":
                    If Len(Trim$(cli.NombreAlterno)) > 0 Then
                        .PrintLine .Rellenar(cli.NombreAlterno, lon, True)
                    Else
                        .PrintLine .Rellenar(Space(lon), lon, True)
                    End If
                Case "TELCLI2": .PrintLine .Rellenar(cli.Telefono2, lon, True)
                Case "TELCLI3": .PrintLine .Rellenar(cli.Telefono3, lon, True)
                Case "FAXCLI": .PrintLine .Rellenar(cli.Fax, lon, True)
                Case "DIRCLI2": .PrintLine .Rellenar(cli.Direccion2, lon, True)
                Case "CODPOSTALCLI": .PrintLine .Rellenar(cli.CodPostal, lon, True)
                Case "CIUCLI": .PrintLine .Rellenar(cli.ciudad, lon, True)
                Case "PROVINCLI": .PrintLine .Rellenar(cli.Provincia, lon, True)
                Case "PAISCLI": .PrintLine .Rellenar(cli.Pais, lon, True)
                Case "AUTSRICLI": .PrintLine .Rellenar(cli.NumAutSRI, lon, True)
                Case "BANCOCLI": .PrintLine .Rellenar(cli.Banco, lon, True)
                Case "NUMCUECLI": .PrintLine .Rellenar(cli.NumCuenta, lon, True)
                Case "TELCLI": .PrintLine .Rellenar(cli.Telefono1, lon, True)
                Case "RUCCLI": .PrintLine .Rellenar(cli.RUC, lon, True)
                Case "DIRCLI": .PrintLine .Rellenar(cli.Direccion1, lon, True)
                Case "CIUCLI": .PrintLine .Rellenar(cli.ciudad, lon, True)
                Case "FAXCLI": .PrintLine .Rellenar(cli.Fax, lon, True)
                Case "EMAILCLI": .PrintLine .Rellenar(cli.EMail, lon, True)
                Case "DIRBANCO":
                    .PrintLine .Rellenar(cli.DirecBanco, lon, True)
                Case "TELBANCO":
                        .PrintLine .Rellenar(cli.TelBanco, lon, True)
                Case "PCCODGRUPO1":
                        Set Grupo = objpcs.Empresa.RecuperaPCGrupo(1, cli.IdGrupo1)
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.codGrupo, lon, True)
                        End If
            Case "PCCODGRUPO2":
                        Set Grupo = objpcs.Empresa.RecuperaPCGrupo(2, cli.IdGrupo2)
                       If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.codGrupo, lon, True)
                        End If
            Case "PCCODGRUPO3":
                        Set Grupo = objpcs.Empresa.RecuperaPCGrupo(3, cli.IdGrupo3)
                       If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.codGrupo, lon, True)
                        End If
            Case "PCCODGRUPO4":
                        Set Grupo = objpcs.Empresa.RecuperaPCGrupo(4, cli.IdGrupo4)
                       If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.codGrupo, lon, True)
                        End If
                Case "PCDESGRUPO1":
                        Set Grupo = objpcs.Empresa.RecuperaPCGrupo(1, cli.IdGrupo1)
                       If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.Descripcion, lon, True)
                        End If
                Case "PCDESGRUPO2":
                        Set Grupo = objpcs.Empresa.RecuperaPCGrupo(2, cli.IdGrupo2)
                       If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.Descripcion, lon, True)
                        End If
                Case "PCDESGRUPO3":
                        Set Grupo = objpcs.Empresa.RecuperaPCGrupo(3, cli.IdGrupo3)
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.Descripcion, lon, True)
                        End If
                Case "PCDESGRUPO4":
                        Set Grupo = objpcs.Empresa.RecuperaPCGrupo(4, cli.IdGrupo4)
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.Descripcion, lon, True)
                        End If
                Case "TELCLI2": .PrintLine .Rellenar(cli.Telefono2, lon, True)
                Case "TELCLI3": .PrintLine .Rellenar(cli.Telefono3, lon, True)
                Case "LIMITECREDITO": .PrintLine .Rellenar(cli.LimiteCredito, lon, True)
                Case "PCCANTON":
                        Set CANTON = objpcs.Empresa.RecuperaPCCanton(cli.CodCanton)
                        If Not CANTON Is Nothing Then
                            .PrintLine .Rellenar(CANTON.Descripcion, lon, True)
                        End If
                Case "PCPROVINCIA":
                        Set pcPROV = objpcs.Empresa.RecuperaPCProvincia(cli.CodProvincia)
                        If Not pcPROV Is Nothing Then
                            .PrintLine .Rellenar(pcPROV.Descripcion, lon, True)
                        End If
                Case "PCPARROQUIA":
                        Set pcParr = objpcs.Empresa.RecuperaPCParroquia(cli.CodParroquia)
                        If Not pcParr Is Nothing Then
                            .PrintLine .Rellenar(pcParr.Descripcion, lon, True)
                        End If
            End Select
          End If
          '''''''AUC DESDE AQUI INFORMACION DEL GARANTE EN SOLICITUD DE CREDITO
'            Case "NOMGFAMILIAR1": If Not Gar Is Nothing Then .PrintLine .Rellenar(pcsG.NombreFami, lon, True)
'            Case "RELGFAMILIAR1": If Not Gar Is Nothing Then .PrintLine .Rellenar(pcsG.RelacionFami, lon, True)
'            Case "TELGFAMILIAR1": If Not Gar Is Nothing Then .PrintLine .Rellenar(pcsG.TelfFami, lon, True)
'            Case "NOMGFAMILIAR2": If Not Gar Is Nothing Then .PrintLine .Rellenar(pcsG.NombreFami2, lon, True)
'            Case "RELGFAMILIAR2": If Not Gar Is Nothing Then .PrintLine .Rellenar(pcsG.RelacionFami2, lon, True)
'            Case "TELGFAMILIAR2": If Not Gar Is Nothing Then .PrintLine .Rellenar(pcsG.TelfFami2, lon, True)
'            Case "NOMGCOMERCIAL1": If Not Gar Is Nothing Then .PrintLine .Rellenar(pcsG.NombreComer1, lon, True)
'            Case "DIRGCOMERCIAL1": If Not Gar Is Nothing Then .PrintLine .Rellenar(pcsG.DirComer1, lon, True)
'            Case "TELGCOMERCIAL1": If Not Gar Is Nothing Then .PrintLine .Rellenar(pcsG.TelfComer1, lon, True)
'            Case "NOMGCOMERCIAL2": If Not Gar Is Nothing Then .PrintLine .Rellenar(pcsG.NombreComer2, lon, True)
'            Case "DIRGCOMERCIAL2": If Not Gar Is Nothing Then .PrintLine .Rellenar(pcsG.DirComer2, lon, True)
'            Case "TELGCOMERCIAL2": If Not Gar Is Nothing Then .PrintLine .Rellenar(pcsG.TelfComer2, lon, True)
            '----
            Case "GARACTIVIDAD":
                If Not GarAct Is Nothing Then .PrintLine .Rellenar(GarAct.ActividadSoli, lon, True)
           Case "GARNOMTRAB":
                If Not GarAct Is Nothing Then .PrintLine .Rellenar(GarAct.NombreTrabajoSoli, lon, True)
           Case "GARDIRTRAB":
                If Not GarAct Is Nothing Then .PrintLine .Rellenar(GarAct.DirTrabajoSoli, lon, True)
           Case "GARTELTRAB":
                If Not GarAct Is Nothing Then .PrintLine .Rellenar(GarAct.TelfActividadSol, lon, True)
           Case "GARANTTRAB":
                If Not GarAct Is Nothing Then .PrintLine .Rellenar(GarAct.AntiguedadSoli, lon, True)
           '----
            Case "GARINGRESOS": If Not GarAct Is Nothing Then .PrintLine .Rellenar(GarAct.IngresosSoli, lon, True)
'            Case "GARTIPOVIVENDA":
'                If Not Gar Is Nothing Then
'                    Select Case pcsG.TipoVivienda
'                        Case 0: .PrintLine .Rellenar("PROPIA", lon, True)
'                        Case 1: .PrintLine .Rellenar("ARRENDADA", lon, True)
'                        Case 2: .PrintLine .Rellenar("AMBULATORIA", lon, True)
'                        Case 3: .PrintLine .Rellenar("VIVE CON FAMILAR", lon, True)
'                     End Select
'                End If
                        '.PrintLine .Rellenar(objpcs.TipoVivienda, lon, True)
'            Case "GARANIORESIDENCIA": If Not Gar Is Nothing Then .PrintLine .Rellenar(pcsG.AnioResidencia, lon, True)
            Case "GARREFDOMICILIO": If Not Gar Is Nothing Then .PrintLine .Rellenar(Gar.DescripcionDetalle, lon, True)
         Case "CODGAR", "NOMGAR", "TELGAR", "RUCGAR", "DIRGAR", "CIUGAR", _
               "PCGCODGRUPO1", "PCGDESGRUPO1", "PCGCODGRUPO2", "PCGDESGRUPO2", _
                "PCGCODGRUPO3", "PCGDESGRUPO3", "PCGCODGRUPO4", "PCGDESGRUPO4", _
                "TELGAR2", "TELGAR3", "FAXGAR", "DIRGAR2", "CODPOSTALGAR", "CIUGAR", _
                "PROVINGAR", "PAISGAR", "AUTSRIGAR", "BANCOGAR", "NUMCUEGAR", "NOMALTGAR", _
                 "NOMALTGAR", "GARCANTON", "GARPARROQUIA", "GARPROVINCIA", "VENDESOLCRED", "DESCTRANSSOLCRED", "CODFORMASOLCRED", "SWITGAR", "DIRBANCOGAR", "TELBANCOGAR"
            If Not (Gar Is Nothing) Then
                Select Case v(0)
                Case "CODGAR":   .PrintLine .Rellenar(Gar.CodProvCli, lon, True)
                Case "NOMGAR": .PrintLine .Rellenar(Gar.Nombre, lon, True)
                Case "NOMALTGAR": .PrintLine .Rellenar(Gar.NombreAlterno, lon, True)
                Case "TELGAR2": .PrintLine .Rellenar(Gar.Telefono2, lon, True)
                Case "TELGAR3": .PrintLine .Rellenar(Gar.Telefono3, lon, True)
                Case "FAXGAR": .PrintLine .Rellenar(Gar.Fax, lon, True)
                Case "DIRGAR2": .PrintLine .Rellenar(Gar.Direccion2, lon, True)
                Case "CODPOSTALGAR": .PrintLine .Rellenar(Gar.CodPostal, lon, True)
                'Case "PARROQGAR": .PrintLine .Rellenar(Gar.PARR, lon, True) 'agregar parroquia
                'Case "CIUGAR": .PrintLine .Rellenar(Gar.Ciudad, lon, True)
                'Case "PROVINGAR": .PrintLine .Rellenar(Gar.Provincia, lon, True)
                Case "PAISGAR": .PrintLine .Rellenar(Gar.Pais, lon, True)
                Case "AUTSRIGAR": .PrintLine .Rellenar(Gar.NumAutSRI, lon, True)
                Case "BANCOGAR": .PrintLine .Rellenar(Gar.Banco, lon, True)
                Case "NUMCUEGAR": .PrintLine .Rellenar(Gar.NumCuenta, lon, True)
                Case "TELGAR": .PrintLine .Rellenar(Gar.Telefono1, lon, True)
                Case "RUCGAR": .PrintLine .Rellenar(Gar.RUC, lon, True)
                Case "DIRGAR": .PrintLine .Rellenar(Gar.Direccion1, lon, True)
                Case "CIUGAR": .PrintLine .Rellenar(Gar.ciudad, lon, True)
                Case "FAXGAR": .PrintLine .Rellenar(Gar.Fax, lon, True)
                Case "BANCOGAR": .PrintLine .Rellenar(Gar.Banco, lon, True)
                Case "NUMCUEGAR": .PrintLine .Rellenar(Gar.NumCuenta, lon, True)
                Case "EMAILGAR": .PrintLine .Rellenar(Gar.EMail, lon, True)
                Case "DIRBANCOGAR": .PrintLine .Rellenar(Gar.DirecBanco, lon, True)
                Case "TELBANCOGAR": .PrintLine .Rellenar(Gar.TelBanco, lon, True)
                Case "PCGCODGRUPO1":
                        Set Grupo = Gar.Empresa.RecuperaPCGrupo(1, Gar.IdGrupo1)
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.codGrupo, lon, True)
                        End If
            Case "PCGCODGRUPO2":
                        Set Grupo = Gar.Empresa.RecuperaPCGrupo(2, Gar.IdGrupo2)
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.codGrupo, lon, True)
                        End If
            Case "PCGCODGRUPO3":
                        Set Grupo = Gar.Empresa.RecuperaPCGrupo(3, Gar.IdGrupo3)
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.codGrupo, lon, True)
                        End If
            Case "PCGCODGRUPO4":
                        Set Grupo = Gar.Empresa.RecuperaPCGrupo(4, Gar.IdGrupo4)
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.codGrupo, lon, True)
                        End If
                Case "PCGDESGRUPO1":
                        Set Grupo = Gar.Empresa.RecuperaPCGrupo(1, Gar.IdGrupo1)
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.Descripcion, lon, True)
                        End If
                Case "PCGDESGRUPO2":
                        Set Grupo = Gar.Empresa.RecuperaPCGrupo(2, Gar.IdGrupo2)
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.Descripcion, lon, True)
                        End If
                Case "PCGDESGRUPO3":
                        Set Grupo = Gar.Empresa.RecuperaPCGrupo(3, Gar.IdGrupo3)
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.Descripcion, lon, True)
                        End If
            Case "PCGDESGRUPO4":
                        Set Grupo = Gar.Empresa.RecuperaPCGrupo(4, Gar.IdGrupo4)
                        If Not Grupo Is Nothing Then
                            .PrintLine .Rellenar(Grupo.Descripcion, lon, True)
                        End If
            Case "GARPARROQUIA":
                        Set GARParr = Gar.Empresa.RecuperaPCParroquia(Gar.IDParroquia)
                        If Not GARParr Is Nothing Then
                            .PrintLine .Rellenar(GARParr.Descripcion, lon, True)
                        End If
                        Set GARParr = Nothing
                Case "GARCANTON":
                        Set GARCANTON = Gar.Empresa.RecuperaPCCanton(Gar.IdCanton)
                        If Not GARCANTON Is Nothing Then
                            .PrintLine .Rellenar(GARCANTON.Descripcion, lon, True)
                        End If
                        Set GARCANTON = Nothing
                Case "GARPROVINCIA":
                        Set GARPROV = Gar.Empresa.RecuperaPCProvincia(Gar.IdProvincia)
                        If Not GARPROV Is Nothing Then
                            .PrintLine .Rellenar(GARPROV.Descripcion, lon, True)
                        End If
                        Set GARPROV = Nothing
                Case "DESCTRANSSOLCRED":
                        If Not gn Is Nothing Then
                            .PrintLine .Rellenar(gn.Descripcion, lon, True)
                        Else
                            .PrintLine .Rellenar("", lon, True)
                        End If
                Case "CODFORMASOLCRED":
                        If Not gn Is Nothing Then
                            .PrintLine .Rellenar(gn.codForma, lon, True)
                        Else
                            .PrintLine .Rellenar("", lon, True)
                        End If
                Case "VENDESOLCRED":
                        If Not gn Is Nothing Then
                            .PrintLine .Rellenar(gn.CodVendedor, lon, True)
                        Else
                            .PrintLine .Rellenar("", lon, True)
                        End If
            End Select
        End If
        End Select
    End With
        Set cli = Nothing
        Set Gar = Nothing
        Set pcsG = Nothing
        Set pcsC = Nothing
        Set gn = Nothing
        Set GarAct = Nothing
        Set pcAct = Nothing
End Sub
Private Function TotalDetChequePosf(ByRef GnComp As GNComprobante) As Currency
    Dim TsdCh As TSDetalleChequePosf
    Dim i As Long
    TotalDetChequePosf = 0
     For i = 1 To GnComp.CountTSDetalleChequePosf
        Set TsdCh = GnComp.TSDetalleChequePosf(i)
        TotalDetChequePosf = TotalDetChequePosf + (TsdCh.valor)
    Next i
    Set TsdCh = Nothing
End Function

Private Function CostoNetoNew(ByRef GnComp As GNComprobante, ByRef cad As String, ByVal bandRec As Boolean) As Currency
    'saca  el valor  neto  de la factura
    'suma  Ct + Recargos(especificados)
    Dim v As Variant, numRec As Integer
    Dim i As Integer
    v = Split(cad, ";")
    If IsEmpty(v) Then Exit Function
    numRec = UBound(v, 1)
    If bandRec Then
        CostoNetoNew = Abs(GnComp.IVKardexCTotal(True))     ' con recargos
    Else
        CostoNetoNew = Abs(GnComp.IVKardexCTotal(False))     ' sin recargos
    End If
    For i = 3 To numRec
        CostoNetoNew = CostoNetoNew + Recargo(GnComp, CStr(v(i)))
    Next i
End Function


Public Function PreparaCadena(ByVal cadena As String) As String
'Funcion que concatena apostrofes en una cadena separada por comas
Dim v As Variant, max As Integer, i As Integer
Dim Respuesta As String
    If cadena = "" Then
        PreparaCadena = "''"
        Exit Function
    End If
    v = Split(cadena, ",")
    max = UBound(v, 1)
    For i = 0 To max
        Respuesta = Respuesta & "'" & v(i) & "'" & ","
    Next i
    Respuesta = Left(Respuesta, Len(Respuesta) - 1) 'Quita la útima coma
    PreparaCadena = Respuesta
End Function

Private Function TotalCSIvaDou(ByRef GnComp As GNComprobante, ByVal CSIva As Byte) As Double
'CSIva=0  ---> Sin Iva     CSIva=1 ---> Con Iva
    Dim ivk As IVKardex
    Dim i As Long
    For i = 1 To GnComp.CountIVKardex
        If CSIva = 0 Then
            Set ivk = GnComp.IVKardex(i)
            If ivk.IVA = 0 Then TotalCSIvaDou = TotalCSIvaDou + Abs(ivk.PrecioRealTotalDou)
        Else
            Set ivk = GnComp.IVKardex(i)
            If ivk.IVA <> 0 Then TotalCSIvaDou = TotalCSIvaDou + Abs(ivk.PrecioRealTotalDou)
        End If
    Next i
End Function

Private Function TotalCSIvaRealDou(ByRef GnComp As GNComprobante, ByVal CSIva As Byte) As Double
'CSIva=0  ---> Sin Iva     CSIva=1 ---> Con Iva
    Dim ivk As IVKardex
    Dim i As Long
    For i = 1 To GnComp.CountIVKardex
        If CSIva = 0 Then
            Set ivk = GnComp.IVKardex(i)
            If ivk.IVA = 0 Then TotalCSIvaRealDou = TotalCSIvaRealDou + Abs(ivk.PrecioRealTotalDou)
        Else
            Set ivk = GnComp.IVKardex(i)
            If ivk.IVA <> 0 Then TotalCSIvaRealDou = TotalCSIvaRealDou + Abs(ivk.PrecioRealTotalDou)
        End If
    Next i
End Function

Private Function ValorNetoDou(ByRef GnComp As GNComprobante, ByRef cad As String) As Double
    'saca  el valor  neto  de la factura
    'suma  Pt + Recargos(especificados)
    Dim v As Variant, numRec As Integer
    Dim i As Integer
    v = Split(cad, ";")
    If IsEmpty(v) Then Exit Function
    numRec = UBound(v, 1)
    ValorNetoDou = Abs(GnComp.IVKardexPTotalDou(True))   ' sin recargos
    For i = 3 To numRec
        ValorNetoDou = ValorNetoDou + Recargo(GnComp, CStr(v(i)))
    Next i
End Function

Private Function ValorNetoIVADou(ByRef GnComp As GNComprobante, ByRef cad As String, BandIva As Boolean) As Double
    'saca  el valor  neto  de la factura
    'suma  Pt + Recargos(especificados)
    Dim v As Variant, numRec As Integer
    Dim i As Integer
    v = Split(cad, ";")
    If IsEmpty(v) Then Exit Function
    numRec = UBound(v, 1)
    ValorNetoIVADou = Abs(GnComp.IVKardexPTotalIVADou(True, BandIva))   ' sin recargos
    For i = 3 To numRec
        ValorNetoIVADou = ValorNetoIVADou + Recargo(GnComp, CStr(v(i)))
    Next i
End Function

Private Function CostoNetoNewDou(ByRef GnComp As GNComprobante, ByRef cad As String, ByVal bandRec As Boolean) As Double
    'saca  el valor  neto  de la factura
    'suma  Ct + Recargos(especificados)
    Dim v As Variant, numRec As Integer
    Dim i As Integer
    v = Split(cad, ";")
    If IsEmpty(v) Then Exit Function
    numRec = UBound(v, 1)
    If bandRec Then
        CostoNetoNewDou = Abs(GnComp.IVKardexCTotalDou(True))      ' con recargos
    Else
        CostoNetoNewDou = Abs(GnComp.IVKardexCTotalDou(False))      ' sin recargos
    End If
    For i = 3 To numRec
        CostoNetoNewDou = CostoNetoNewDou + Recargo(GnComp, CStr(v(i)))
    Next i
End Function

Private Function CalculaEfectivoDou(ByVal GnComp As GNComprobante, ByVal bandVuelto As Boolean) As Double
    
    Dim s As String, posini As Integer, posfin As Integer
    Dim Efectivo As String, efec As Double
    Dim PTotal As Double, Pck As PCKardex
    
    PTotal = Abs(GnComp.IVKardexPTotalDou(True)) + GnComp.IVRecargoTotal(True, False)
    'antes GnComp.efectivo
    s = GnComp.Efectivo
    posini = InStr(1, s, "Efectivo (") + 10
    posfin = InStr(posini, s, ")")
    If posfin <> 0 Then     '***Diego 21/12/2003  Control  cuando  no  graba vuelto
        Efectivo = Mid$(s, posini, posfin - posini)
    End If
    If IsNumeric(Efectivo) Then
        efec = CCur(Efectivo)
    End If
    If bandVuelto Then
        Dim CContado As Currency
        CContado = GnComp.CalculaCobroContado(GnComp.GNTrans.IVCobroContado)  ' esteba 20/10/2003 para cuando existen anticipados  valor anterior       Set pck = GnComp.PCKardex(1)        'asumiendo que el valor pagado de contado siempre se guarda en el primer registro de la tabla
        CalculaEfectivoDou = efec - CContado        ' anteriorpck.Debe
        Set Pck = Nothing
    Else
        CalculaEfectivoDou = efec
    End If
End Function

Private Function ValorNetoMasIVADou(ByRef GnComp As GNComprobante, ByRef cad As String) As Double
    'saca  el valor  neto  de la factura
    'suma  Pt + Recargos(especificados)
    Dim v As Variant, numRec As Integer
    Dim i As Integer, valIva As Double, PorcentajeRecargo As Double, j As Long
    Dim ivr As IVRecargo, ivkr As IVKardexRecargo, ivkrd As IVRecargoDetalle
    Dim xi As Long
    v = Split(cad, ";")
    If IsEmpty(v) Then Exit Function
    numRec = UBound(v, 1)
    ValorNetoMasIVADou = Abs(GnComp.IVKardexPTotalDou(True))    ' sin recargos
    valIva = Recargo(GnComp, IIf(Len(GnComp.Empresa.GNOpcion.ObtenerValor("RecDescParaIVA")) > 0, GnComp.Empresa.GNOpcion.ObtenerValor("RecDescParaIVA"), "IVA"))
    PorcentajeRecargo = GnComp.Empresa.GNOpcion.PorcentajeIVA ' v(3)
    If v(3) <> IIf(Len(GnComp.Empresa.GNOpcion.ObtenerValor("RecDescParaIVA")) > 0, GnComp.Empresa.GNOpcion.ObtenerValor("RecDescParaIVA"), "IVA") Then
        ValorNetoMasIVADou = ValorNetoMasIVADou + Abs(RecargoMasIvaDouble(GnComp, CStr(v(3)), PorcentajeRecargo))
    End If
    ValorNetoMasIVADou = ValorNetoMasIVADou + valIva
End Function

Private Function RecargoMasIvaDouble(ByRef GnComp As GNComprobante, ByRef cod As String, ByRef valor As Double) As Currency
    'Busca  el codigo  en  IVKardexRecargo
    'si existe en la transaccion  devuelve  el valor
    Dim ivr As IVRecargo, ivkr As IVKardexRecargo, ivk As IVKardex
    Dim i As Long
        Set ivr = GnComp.Empresa.RecuperaIVRecargo(cod)
        If ivr Is Nothing Then
            Err.Raise ERR_NOIMPRIME, App.EXEName, "No existe recargo: " & cod
        Else
            For i = 1 To GnComp.CountIVKardexRecargo
                Set ivkr = GnComp.IVKardexRecargo(i)
                If ivr.CodRecargo = ivkr.CodRecargo Then
                    RecargoMasIvaDouble = (ivkr.valor * (1 + (valor)))  ' para que el valor sea inverso
                    Exit Function
                End If
            Next i
            RecargoMasIvaDouble = 0
        End If
End Function

Public Function CogeSoloNombre(Desc As String) As String
    Dim s As String, i As Long, f As Long
    i = InStrRev(Desc, "_")
    f = InStrRev(Desc, ".")
    If i > 0 Then s = Mid$(Desc, i + 1, f - i)
    If Len(s) > 0 Then s = Left$(s, Len(s) - 1)
    CogeSoloNombre = s
End Function
Public Function verificaExisteItemsPorGrupo(ByVal gc As GNComprobante, ByVal codGrupo As String) As Boolean
Dim i As Long
For i = 1 To gc.CountIVKardex
    If gc.IVKardex(i).codGrupos(6) = codGrupo And gc.IVKardex(i).bandImprimir = 0 Then
        verificaExisteItemsPorGrupo = True
        Exit Function
    End If
Next
End Function
