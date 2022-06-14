VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "PrintTrans"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit
'Private mSpTxt As SiiPrint.PrintTxt   'impresion  en modo texto
Private WithEvents mSpTxt As SiiPrint.PrintTxt
Attribute mSpTxt.VB_VarHelpID = -1
Dim mobjGnComp As GNComprobante
Dim ActiveSection As String
Dim mcol As New Collection
Dim mcolAux As New Collection
Dim nomarchi As String
Dim ArchivoPadre As String
Dim ArchivoBoleto As String
Dim Config As clsConfig   'Clase   para guardar  la  configuraciones  generales
'Dim pcs As PCSOLCREProvCli
Dim pc As pcProvCli

'Public Property Get ActiveSection() As String
'    ActiveSection
'End Property

Public Property Get NombreDLL() As String
    NombreDLL = App.EXEName
End Property

Public Sub PrintTrans(ByVal objEmpresa As Empresa, _
                       Directo As Boolean, _
                       Copias As Integer, _
                       TransId As Long, _
                       Optional CodTrans As String, _
                       Optional NumTrans As Long, _
                       Optional ByVal objGNComp As GNComprobante)
    
'Se puede llamar de 3 formas, por ejemplo:
'1. objEmp, False, 1, TransId                  (Especifica por TransID)
'2. objEmp, False, 1, 0, CodTrans, NumTrans    (Especifica por CodTrans y NumTrans)
'3. objEmp, False, 1, 0, "", 0, objGNComp      (Envia el objeto GNComprobante)
'
'Directo = True: Imprime directamente a por la impresora.
'        = False:Abre la pantalla de vista previa.
'Copias : Número de copias
'
    

    'Si no ha enviado el objeto mismo
    If objGNComp Is Nothing Then
        'Recupera de la base
        Set objGNComp = objEmpresa.RecuperaGNComprobante(TransId, CodTrans, NumTrans)
        If objGNComp Is Nothing Then
            Err.Raise ERR_NOHAYCODIGO, App.EXEName, _
                "No se puede recuperar la transacción. " & vbCr & _
                "(tid=" & TransId & ", CodTrans='" & CodTrans & "', NumTrans=" & NumTrans & ")"
        End If
    End If

    'Si está anulado nunca puede imprimir
    If objGNComp.Estado = ESTADO_ANULADO Then
        Err.Raise ERR_NOIMPRIME3, App.EXEName, MSGERR_NOIMPRIME3
    End If

    'Si la transacción requiere que esté aprobada
    If objGNComp.GNTrans.ImprimeSoloAprobado Then
        'Si no está aprobada o despachada, no puede imprimir
        If Not (objGNComp.Estado = ESTADO_APROBADO Or _
                objGNComp.Estado = ESTADO_DESPACHADO Or _
                objGNComp.Estado = ESTADO_SEMDESPACHADO) Then
            Err.Raise ERR_NOIMPRIME, App.EXEName, MSGERR_NOIMPRIME
        End If
    End If

    Set mobjGnComp = objGNComp
'    Set ip.GNComprobante = objGNComp

    'Para imprimir varios documentos, se empezará por recuperar el archivo principal, en el que debe
    'constar los nombres de todos los documentos a imprimir, los cuales serán asignados a un vector
    'para su posterior impresión
    
    AbreArchivoPadre
    If mobjGnComp.EsNuevo Then
        ImprimirDocumento (objGNComp.GNTrans.ImprimeComprobante = "P")
    Else
        If Not objGNComp.GNTrans.IVAutoImpresor Then
            If objGNComp.GNTrans.ImprimeComprobante = "S" Then
                ImprimirDocumento (False)
            Else
                ImprimirDocumento (True)
            End If
        Else
            ImprimirDocumento (False)
        End If
    End If
End Sub

Private Sub AbreArchivoPadre()
    On Error GoTo ErrTrap
    If Not mobjGnComp.GNTrans.BandImpGlobal Then
        ArchivoPadre = App.Path
        If Right$(App.Path, 1) <> "\" Then ArchivoPadre = ArchivoPadre & "\"
    Else
        ArchivoPadre = mobjGnComp.GNTrans.RutaLibImp
        If Right$(mobjGnComp.GNTrans.RutaLibImp, 1) <> "\" Then ArchivoPadre = ArchivoPadre & "\"
    End If
    ArchivoPadre = ArchivoPadre & mobjGnComp.CodTrans & ".txt"
    Exit Sub
ErrTrap:
        Err.Raise ERR_NOIMPRIME, App.EXEName, Err.Description
End Sub

Private Sub ImprimirDocumento(Pregunta As Boolean)
    Dim rt As Integer, v() As Variant
    Dim i As Long, NumDctos As Long
    Dim nom As String
    v = AsignaArchivoHijo(NumDctos)
    For i = 1 To NumDctos
        rt = vbYes
        If Pregunta Then 'AUC agregado esto para cofradia para q respete conf dela trans
            If Pregunta Or NumDctos > 1 Or mobjGnComp.Impresion = 1 Then
                If i <> 1 Or Pregunta Or mobjGnComp.Impresion = 1 Then
                    rt = MsgBox("El sistema se dispone a imprimir documento: " & v(0, i) & vbCrLf & _
                              "Confirma Impresión?", vbYesNo)
                Else
                    rt = vbYes
                End If
            End If
        End If
        nomarchi = v(1, i)
        'AUC agregado validacion para ver si imprime o no la transaccion para cofradia
        nom = CogeSoloNombre(nomarchi)
        'verifico si existen items con este parametro ivgrupo  e imprimo
        If Len(nom) > 0 Then
            If verificaExisteItemsPorGrupo(mobjGnComp, nom) Then
                If rt = vbYes Then
                    RecuperaArchivo
                    GeneraDoc
                End If
            End If
        Else
            If rt = vbYes Then
                RecuperaArchivo
                GeneraDoc
            End If
        End If
    Next i
End Sub

'carga en un vector todos los documentos    Modificado: Alex 22/02/2002
Private Function AsignaArchivoHijo(ByRef NumArch As Long) As Variant
    Dim i As Long, nTxt As Integer
    Dim v As Variant, s As String
    On Error GoTo ErrTrap
    ReDim v(2, 10) 'v(0,0) -> nombre del documento; v(1,0) -> nombre del archivo de texto que contiene el documento
    nTxt = FreeFile
    Open ArchivoPadre For Input As nTxt
    NumArch = 0
    Do Until EOF(nTxt)
        Line Input #nTxt, s
        If Mid$(s, 1, 10) = "[DOCUMENTO" Then
            NumArch = NumArch + 1
            v(0, NumArch) = Mid$(s, 11, InStr(s, ";") - 11) 'nombre del documento convertido en nombre de archivo
            If InStr(s, "/]") <= 0 Then Err.Raise ERR_NOIMPRIME, App.EXEName, "Error de sintaxis"
            
            If Not mobjGnComp.GNTrans.BandImpGlobal Then
                v(1, NumArch) = App.Path
                If Right$(App.Path, 1) <> "\" Then v(1, NumArch) = v(1, NumArch) & "\"
            Else
                v(1, NumArch) = mobjGnComp.GNTrans.RutaLibImp
                If Right$(mobjGnComp.GNTrans.RutaLibImp, 1) <> "\" Then v(1, NumArch) = v(1, NumArch) & "\"
            End If
'            End If
            
''            v(1, NumArch) = App.Path
'            If Right$(App.Path, 1) <> "\" Then v(1, NumArch) = v(1, NumArch) & "\"
            Dim FCOBRO As String
            FCOBRO = Mid$(s, InStr(s, ":") + 1, InStr(s, "/]") - InStr(s, ":") - 1)
            If Left(FCOBRO, 1) <> "[" Then
                If mobjGnComp.VerificaFormaCobro(FCOBRO) Then
                    v(1, NumArch) = v(1, NumArch) & Mid$(s, InStr(s, ";") + 1, InStr(s, "/]") - InStr(s, ";") - 2 - Len(FCOBRO)) & ".txt"
                Else
                    NumArch = NumArch - 1
                End If
            Else
                v(1, NumArch) = v(1, NumArch) & Mid$(s, InStr(s, ";") + 1, InStr(s, "/]") - InStr(s, ";") - 1) & ".txt"
            End If
            
'           v(1, NumArch) = Mid$(s, InStr(s, ";") + 1, InStr(s, "/]") - InStr(s, ";") - 1) & ".txt"  'nombre del archivo
        End If
    Loop
    Close nTxt
    If NumArch = 0 Then
        v(0, 1) = Mid(ArchivoPadre, InStrRev(ArchivoPadre, "\") + 1, InStr(ArchivoPadre, ".txt") - InStrRev(ArchivoPadre, "\") - 1)
        v(1, 1) = ArchivoPadre
        NumArch = 1
    End If
    AsignaArchivoHijo = v
    Exit Function
ErrTrap:
        Err.Raise ERR_NOIMPRIME, App.EXEName, "Impresión de Documentos: " & Err.Description & vbCrLf & s
End Function

Private Sub RecuperaArchivo()
    'Abre el archivo de texto que contiene el formato de reporte
    'Set objImp = CreateObject(gc.GNTrans.ArchivoReporte & ".PrintTrans")
    Dim nTxt As Integer
    Dim s As String, numLinea As Long, obj As Object
    On Error GoTo ErrTrap
'    nomarchi = App.Path
'    If Right$(App.Path, 1) <> "\" Then nomarchi = nomarchi & "\"
'    nomarchi = nomarchi & mobjGnComp.CodTrans & ".txt"
    nTxt = FreeFile
    Open nomarchi For Input As nTxt
    'Escaneado de archivo  para   guardar Elementos
    'Lee las lineas de archivo de definicion
    numLinea = 0
    ActiveSection = ""
    Do Until EOF(nTxt)
        Line Input #nTxt, s
        If Len(s) Then
            If Len(ActiveSection) > 0 Then
                CargaTexto s
            Else
                 CargaSecciones s
            End If

        End If
        numLinea = numLinea + 1
    Loop
    'Cierra el archivo de texto
    Close nTxt
    Exit Sub

ErrTrap:
    If Err.Number = 53 Then
        Err.Raise ERR_NOIMPRIME, App.EXEName, Err.Description
    Else
        Err.Raise ERR_NOIMPRIME, App.EXEName, "Error en archivo: " & _
                    nomarchi & vbKeyReturn & " linea: " & numLinea
    End If
End Sub

Private Sub CargaTexto(s As String)
    Dim i As Integer, obj As Object
    
    s = PreparaCad(s)
    For i = 1 To Len(s)
        'Si es Seccion
        If Mid$(s, i, 10) = "[/SECTION]" Then
           ActiveSection = ""
           Exit Sub
        End If
    Next i
    Select Case ActiveSection
    Case "CONFIG"
        Config.ActualizaValor s
    Case "PARAMETROS"
        'Aquí, asignar la colección de objeto clsParametos para cada variable, o enviar a aumentar parámetros de ella
        Set obj = New clsParametros
        If InStr(1, s, "(") > 0 Then
            mColP.Add obj, "LISTAPARAMETROS" & mColP.Count
            mColP.ITEM("LISTAPARAMETROS" & mColP.Count - 1).NomVar = Mid(s, 1, InStr(1, s, "(") - 1)
        End If
        mColP.ITEM("LISTAPARAMETROS" & mColP.Count - 1).ActualizaParametros s
    Case Else  'Carga texto
        mcol.ITEM(ActiveSection).Texto = mcol.ITEM(ActiveSection).Texto & s & Chr(vbKeyReturn)
    End Select
End Sub

Private Sub CargaSecciones(ByRef s As String)
    Dim i As Integer, cad As String
    Dim v As Variant, numpmt As Integer   'numparametros
    Dim obj As Object, j As Integer, numparam As Integer, NomVar As String
    Dim Header As clsHeader, ITEM As clsItem, TransfItem As clsTransfItem
    Dim Recargo As clsRecargo, DocxCobrar As clsDocXCobrar, DocxPagar As clsDocXPagar, Docxcobrar2col As clsDocXCobrar2Col
    Dim DocCobro As clsDocCobro, DocPago As clsDocPago, Banco As clsBanco, Retencion As clsRetencion, DocxCobrarSRI As clsDocXCobrarSRI
    Dim DocCobroT As clsDocCobroTotal
    Dim Cheque As clsCheque, Asiento As clsAsiento
    Dim CambioPresItem As clsCambioPresItem
    Dim RetencionAuto As clsRetencionAuto
    Dim DetEfectivo As clsDetalleEfectivo
    Dim DetTarjeta As clsDetalleTarjetas
    Dim DetCheque As clsDetalleCheque
    Dim DetVManual As clsDetalleVManuales
    Dim DetEgreso As clsDetalleEgresos
    Dim DetVCredito As clsDetallevCredito
    Dim IvGrupo As clsIVGrupo
    Dim DetIngreso As clsDetalleIngresos
    Dim DetIngresoRT As clsDetalleIngresosRT
    Dim DetTarjetaT As clsTotalTarjetas
    Dim TSResumen As clsTSResumen
    Dim PCAGencia As clsPCAgencia
    Dim key As String
    Dim Credito As clsCredito
    Dim Presupuesto As clsPresupuesto
    Dim AFitem As clsAFItem
    Dim ResvCredito As clsResumenvcredito
    Dim DetChequePosf As clsDetalleChequePosf
    Dim DocxCobrarEmp As clsDocXCobrarEmp
    'Dim ele As clsElemento
    'Crea  el  objeto  y carga las  configuraciones inicales
    s = PreparaCad(s)
    For i = 1 To Len(s)
        'Si es Seccion
        If Mid$(s, i, 8) = "[SECTION" Then
            cad = Mid$(s, i + 8, InStr(i + 8, s, "]") - (i + 8))
            'Carga  en  un vector las  configuraciones
            v = Split(cad, ";")
            If IsEmpty(v) Then Exit For
            numpmt = UBound(v, 1)
            'ALEX JULIO/2002
            ' Si ya existe section, crear una nueva instancia de acuerdo a requerimientos de usuario
            ActiveSection = AsignaSeccion(Trim$(v(0)))
            'ActiveSection = Trim$(v(0))
            
            Select Case Trim$(v(0))
            Case "CONFIG"
                'Set obj = New clsConfig
                'mcol.Add obj, "CONFIG"
                Set Config = New clsConfig
            Case "HEADER"
                Set obj = New clsHeader
                mcol.Add obj, ActiveSection
                'If numpmt >= 1 Then mcol.Item("HEADER").Todo = IIf(Right(Trim$(v(1)), 1) = "T", True, False)
            Case "ITEM"
                Set ITEM = New clsItem
                Set ITEM.PrintTransMain = Me
                mcol.Add ITEM, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
                'jeaa 02/09/04 parametro para imprimir datos del item "-"
                If numpmt >= 3 Then mcol.ITEM(ActiveSection).ImpValNota = IIf(Right(Trim$(v(3)), 1) = "T", True, False)
                If numpmt >= 4 Then mcol.ITEM(ActiveSection).Parametros = Mid(v(4), InStr(1, v(4), "=") + 1, Len(v(4)))
                 If numpmt >= 5 Then mcol.ITEM(ActiveSection).Grupo = Mid(v(5), InStr(1, v(5), "=") + 1, Len(v(5)))
                 If numpmt >= 6 Then mcol.ITEM(ActiveSection).Rest = IIf(Right(Trim$(v(6)), 1) = "T", True, False)
                Set ITEM = Nothing
            Case "RECARGO"
                Set Recargo = New clsRecargo
                Set Recargo.PrintTransMain = Me
                mcol.Add Recargo, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
                If numpmt >= 3 Then mcol.ITEM(ActiveSection).ValorAcum = Trim$(v(3))  'PTOTAL / CTOTAL
                Set Recargo = Nothing
            Case "DOCXCOBRAR"
                Set DocxCobrar = New clsDocXCobrar
                Set DocxCobrar.PrintTransMain = Me
                mcol.Add DocxCobrar, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
            Case "DOCXPAGAR"
                Set DocxPagar = New clsDocXPagar
                Set DocxPagar.PrintTransMain = Me
                mcol.Add DocxPagar, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
            Case "DOCPAGO"
                Set DocPago = New clsDocPago
                Set DocPago.PrintTransMain = Me
                mcol.Add DocPago, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
            Case "DOCCOBRO"
                Set DocCobro = New clsDocCobro
                Set DocCobro.PrintTransMain = Me
                mcol.Add DocCobro, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
                If numpmt >= 3 Then mcol.ITEM(ActiveSection).ImpxProvCli = IIf(Right(Trim$(v(3)), 1) = "T", True, False)
            Case "BANCO"
                Set Banco = New clsBanco
                Set Banco.PrintTransMain = Me
                mcol.Add Banco, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
            Case "ASIENTO"
                Set Asiento = New clsAsiento
                Set Asiento.PrintTransMain = Me
                mcol.Add Asiento, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
            Case "RETENCION"
                Set Retencion = New clsRetencion
                Set Retencion.PrintTransMain = Me
                mcol.Add Retencion, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
                If numpmt >= 3 Then mcol.ITEM(ActiveSection).Parametros = Mid(v(3), InStr(1, v(3), "=") + 1, Len(v(3)))
                Set Retencion = Nothing
         Case "CHEQUE"
                Set Cheque = New clsCheque
                mcol.Add Cheque, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
                If numpmt >= 3 Then mcol.ITEM(ActiveSection).Parametros = Mid(v(3), InStr(1, v(3), "=") + 1, Len(v(3)))
'        Case "CARGARMOTIVTRASL"
'            MOTIVTRASL = v(1)
        Case "PARAMETROS"
            ReDim Parametros(3, 60) 'repetir análisis, porque no está claro cómo va a funcionar para más de una variable
            For j = 1 To numpmt     'no olvidar guardar el valor numpmt: número total de parámetros
                'nomvar = Mid(v(j), 1, InStr(v(j), ":") - 1)
                Parametros(0, j) = Mid(v(j), 1, InStr(v(j), ":") - 1)   'nombre de la variable
                Parametros(1, j) = Mid(v(j), InStr(v(j), ":") + 1, Len(v(j)))   'Valores de los parámetros de la variable
            Next j
            Parametros(3, 1) = numpmt
         Case "TRANSFITEM"
                Set TransfItem = New clsTransfItem
                Set TransfItem.PrintTransMain = Me     'apunta  al padre
                mcol.Add TransfItem, ActiveSection
'                mcol.item(ActiveSection).PrintTrans = Me
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
         Case "CAMBIOPRESITEM"
                Set CambioPresItem = New clsCambioPresItem
                Set CambioPresItem.PrintTransMain = Me     'apunta  al padre
                mcol.Add CambioPresItem, ActiveSection
'                mcol.item(ActiveSection).PrintTrans = Me
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
            ' para camari
            Case "RETENCIONAUTO"
                Set RetencionAuto = New clsRetencionAuto
                Set RetencionAuto.PrintTransMain = Me
                mcol.Add RetencionAuto, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
                If numpmt >= 3 Then mcol.ITEM(ActiveSection).Parametros = Mid(v(3), InStr(1, v(3), "=") + 1, Len(v(3)))
                Set RetencionAuto = Nothing
            Case "DOCCOBROTOTAL"
                Set DocCobroT = New clsDocCobroTotal
                Set DocCobroT.PrintTransMain = Me
                mcol.Add DocCobroT, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
                If numpmt >= 3 Then mcol.ITEM(ActiveSection).ImpxProvCli = IIf(Right(Trim$(v(3)), 1) = "T", True, False)
            Case "CREDITO"
                Set Credito = New clsCredito
                Set Credito.PrintTransMain = Me
                mcol.Add Credito, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Parametros = Mid(v(1), InStr(1, v(1), "=") + 1, Len(v(1)))
                Set Credito = Nothing
            Case "DETEFECTIVO"
                Set DetEfectivo = New clsDetalleEfectivo
                Set DetEfectivo.PrintTransMain = Me
                mcol.Add DetEfectivo, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
            Case "DETTARJETA"
                Set DetTarjeta = New clsDetalleTarjetas
                Set DetTarjeta.PrintTransMain = Me
                mcol.Add DetTarjeta, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
                If numpmt >= 3 Then mcol.ITEM(ActiveSection).ImpxTarjeta = IIf(Right(Trim$(v(3)), 1) = "T", True, False)
            Case "TOTTARJETA"
                Set DetTarjetaT = New clsTotalTarjetas
                Set DetTarjetaT.PrintTransMain = Me
                mcol.Add DetTarjetaT, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
                If numpmt >= 3 Then mcol.ITEM(ActiveSection).ImpxTarjeta = IIf(Right(Trim$(v(3)), 1) = "T", True, False)
                
            Case "DETCHEQUE"
                Set DetCheque = New clsDetalleCheque
                Set DetCheque.PrintTransMain = Me
                mcol.Add DetCheque, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
            Case "DETCHEQUEPOSF"
                Set DetChequePosf = New clsDetalleChequePosf
                Set DetChequePosf.PrintTransMain = Me
                mcol.Add DetChequePosf, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
            Case "DETVMANUAL"
                Set DetVManual = New clsDetalleVManuales
                Set DetVManual.PrintTransMain = Me
                mcol.Add DetVManual, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
            Case "DETEGRESO"
                Set DetEgreso = New clsDetalleEgresos
                Set DetEgreso.PrintTransMain = Me
                mcol.Add DetEgreso, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
            Case "DETVCREDITO"
                Set DetVCredito = New clsDetallevCredito
                Set DetVCredito.PrintTransMain = Me
                mcol.Add DetVCredito, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
        Case "IVGRUPO"
                Set IvGrupo = New clsIVGrupo
                Set IvGrupo.PrintTransMain = Me
                mcol.Add IvGrupo, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
                If numpmt >= 3 Then mcol.ITEM(ActiveSection).Parametros = Mid(v(3), InStr(1, v(3), "=") + 1, Len(v(3)))
                Set IvGrupo = Nothing
            Case "DETINGRESO"
                Set DetIngreso = New clsDetalleIngresos
                Set DetIngreso.PrintTransMain = Me
                mcol.Add DetIngreso, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
            Case "DETINGRESORT"
                Set DetIngresoRT = New clsDetalleIngresosRT
                Set DetIngresoRT.PrintTransMain = Me
                mcol.Add DetIngresoRT, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
            Case "PRESUPUESTO"
                Set Presupuesto = New clsPresupuesto
                Set Presupuesto.PrintTransMain = Me
                mcol.Add Presupuesto, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
            Case "AFITEM"
                Set AFitem = New clsAFItem
                Set AFitem.PrintTransMain = Me
                mcol.Add AFitem, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
                'jeaa 02/09/04 parametro para imprimir datos del item "-"
                If numpmt >= 3 Then mcol.ITEM(ActiveSection).ImpValNota = IIf(Right(Trim$(v(3)), 1) = "T", True, False)
                If numpmt >= 4 Then mcol.ITEM(ActiveSection).Parametros = Mid(v(4), InStr(1, v(4), "=") + 1, Len(v(4)))
                Set ITEM = Nothing
           Case "TSRESUMEN"
                Set TSResumen = New clsTSResumen
                Set TSResumen.PrintTransMain = Me
                mcol.Add TSResumen, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
            Case "PCAGENCIA"
                Set PCAGencia = New clsPCAgencia
                Set PCAGencia.PrintTransMain = Me
                mcol.Add PCAGencia, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
          Case "DOCXCOBRAR2COL"
                Set Docxcobrar2col = New clsDocXCobrar2Col
                Set Docxcobrar2col.PrintTransMain = Me
                mcol.Add Docxcobrar2col, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
        Case "RESVCREDITO" 'resumen ventas credito creado para yolita
                Set ResvCredito = New clsResumenvcredito
                Set ResvCredito.PrintTransMain = Me
                mcol.Add ResvCredito, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
            Case "DOCXCOBRARSRI"
                Set DocxCobrarSRI = New clsDocXCobrarSRI
                Set DocxCobrarSRI.PrintTransMain = Me
                mcol.Add DocxCobrarSRI, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)
             Case "DOCXCOBRAREMP" 'AUC agregado para imprimir anticipos de empleados
                Set DocxCobrarEmp = New clsDocXCobrarEmp
                Set DocxCobrarEmp.PrintTransMain = Me
                mcol.Add DocxCobrarEmp, ActiveSection
                If numpmt >= 1 Then mcol.ITEM(ActiveSection).Linea = CInt(Right(v(1), Len(v(1)) - InStr(1, v(1), "=")))
                If numpmt >= 2 Then mcol.ITEM(ActiveSection).CambioPag = IIf(Right(Trim$(v(2)), 1) = "T", True, False)

       End Select
'            If ActiveSection = "PCAGENCIA" Then
'                Set mcol.item(ActiveSection).objCli = PC
'            Else
                If ActiveSection <> "CONFIG" And ActiveSection <> "PARAMETROS" Then   'ActiveSection <> "CARGARMOTIVTRASL" And
                    If mcol.ITEM(ActiveSection) Is Nothing Then
                        Err.Raise ERR_NOIMPRIME, App.EXEName, "Error en archivo: " & nomarchi & _
                               "No existe Seccion: " & ActiveSection
                    ElseIf ActiveSection <> "PARAMETROS" Then    'ActiveSection <> "CARGARMOTIVTRASL" And
                        Set mcol.ITEM(ActiveSection).GNC = mobjGnComp
                    End If
                End If
'            End If
            i = i + Len(cad) + 8
        End If
    Next i
End Sub

Private Sub GeneraDoc()
    Dim i  As Integer, s As String
    Dim nTxt As Integer, numLinea As Integer
    Dim bandfirst As Boolean
    Dim bandImpItem As Boolean
    bandImpItem = True
    If Config.Modo = "T" Then  'Modo texto
        Set mSpTxt = New SiiPrint.PrintTxt
    Else
    End If
    gfmt = mobjGnComp.FormatoMoneda
    gfmtCant = mobjGnComp.Empresa.GNOpcion.FormatoCantidad
    '***Agregado ANGEL 12/Mayo/2003
    mSpTxt.NombreImpresora = Config.NombreImpresora
    mSpTxt.LongitudCorte = Config.LongitudCorte
    '**** Ageregado jeaa 29/09/04
    mSpTxt.IndentLeft = Config.MargenIzq
    
    mSpTxt.ImpInicializa
    mSpTxt.StartDoc mobjGnComp.CodTrans & " " & mobjGnComp.NumTrans
    mSpTxt.NumLineaPagina = Config.numLinea
    nTxt = FreeFile
    Open nomarchi For Input As nTxt
    'Escaneado de archivo  para   guardar Elementos
    'Lee las lineas de archivo de definicion
    numLinea = 0
    ActiveSection = ""
    bandfirst = True
    Do Until EOF(nTxt)
        Line Input #nTxt, s
        s = PreparaCad(s)  ' elimina los comentarios
        verificaSeccion s, bandfirst
        If Len(ActiveSection) > 0 And bandfirst = True Then
             If ActiveSection <> "CONFIG" And ActiveSection <> "PARAMETROS" Then   '(ActiveSection <> "CARGARMOTIVTRASL" And
                'Objeto de impresion Apunta a la clase
'                If ActiveSection <> "ITEM" Then
                    Set mcol.ITEM(ActiveSection).Sptxt = mSpTxt
                    mcol.ITEM(ActiveSection).PrintSection
                    bandfirst = False
'                End If
             End If
        ElseIf Len(ActiveSection) = 0 Then
             ProcesaLinea s
        End If
        numLinea = numLinea + 1
    Loop
    'Cierra el archivo de texto
    Close nTxt
    'mSpTxt.ImpSaltoPagina
    mSpTxt.EndDoc
    Set mcol = Nothing
    Set mcolAux = Nothing
End Sub

Public Sub ProcesaLinea(s As String)
    Dim i As Long, v As Variant, cad As String
    Dim cmd As String, bandSalto As Boolean
    'Set mobjGNOp = mGNComp.Empresa.GNOpcion
    'Datos de cliente (Codigo, Nombre, RUC, Direc,Tel)
    'Set cli = mGNComp.Empresa.RecuperaPCProvCli(mGNComp.CodClienteRef)
    's = mprops.Texto
    On Error GoTo ErrTrap
    bandSalto = False
    With mSpTxt
        For i = 1 To Len(s)
            'Si es un comando
            If Mid$(s, i, 2) = "%(" Then
                cmd = Mid$(s, i + 2, InStr(i + 2, s, ")") - (i + 2))
                ProcesaComando cmd, mSpTxt, bandSalto
                i = i + Len(cmd) + 2
            'Si es una variable
            ElseIf Mid$(s, i, 2) = "$(" Then
                cmd = Mid$(s, i + 2, InStr(i + 2, s, ")") - (i + 2))
                gnProcesaVariable cmd, mobjGnComp, mSpTxt
                i = i + Len(cmd) + 2
            ElseIf Mid$(s, i, 8) = "[SECTION" Then
                cad = Mid$(s, i + 8, InStr(i + 8, s, "]") - (i + 8))
                'Carga  en  un vector las  configuraciones
                v = Split(cad, ";")
                If Not IsEmpty(v) Then
                    ActiveSection = Trim$(v(0))
                End If
                'i = i + Len(cad) + 8
                Exit Sub
            ElseIf Mid$(s, i, 10) = "[/SECTION]" Then
               ActiveSection = ""
               'i = i + 10
               Exit Sub
            Else
                .PrintLine Mid$(s, i, 1)          'Manda un carácter a la impresora
            End If
        Next i
        If bandSalto = False Then .PrintLine "", 1    'cambio de linea
    End With
    Exit Sub
ErrTrap:
    Set mcol = Nothing
    Set mcolAux = Nothing
    Err.Raise ERR_NOIMPRIME, App.EXEName, "Error en archivo " & _
                nomarchi & vbKeyReturn & " linea: " & s
End Sub

Private Sub Class_Initialize()
    GUIAREMISION = 0
End Sub

Private Sub Class_Terminate()
    Set mSpTxt = Nothing
    Set mcol = Nothing
    Set Config = Nothing
    Set mColP = Nothing
    Set mcolAux = Nothing
End Sub

Private Sub verificaSeccion(ByVal s As String, ByRef bandfirst As Boolean)
    Dim i As Long, cad As String, v As Variant
    For i = 1 To Len(s)
        If Mid$(s, i, 8) = "[SECTION" Then
            cad = Mid$(s, i + 8, InStr(i + 8, s, "]") - (i + 8))
            'Carga  en  un vector las  configuraciones
            v = Split(cad, ";")
            If Not IsEmpty(v) Then
                'Aquí también debe existir un control que permita ir recorriendo todas las n instancias de la sección repetida
                'ActiveSection = Trim$(v(0))
                ActiveSection = RecuperaSeccionAsignada(Trim$(v(0)))
                bandfirst = True
            End If
            'i = i + Len(cad) + 8
            Exit Sub
        ElseIf Mid$(s, i, 10) = "[/SECTION]" Then
           ActiveSection = ""
           bandfirst = False
           'i = i + 10
           Exit Sub
        End If
      Next i
End Sub

Private Sub mSpTxt_NuevaPagina()
    Me.NuevaPagina
End Sub

Public Sub NuevaPagina()
    If Config.HeaderTodo = True Then
        mcol.ITEM("HEADER").PrintSection
    End If
End Sub

'Agregado Alex Julio/2002, para permitir que se llame más de una vez una sección en el mismo dcto.

Private Function AsignaSeccion(ByVal key As String) As String
    Dim i As Long, cont As Long, KeyAux As String
    On Error GoTo ErrTrap
    cont = 0
    KeyAux = key
    For i = 1 To mcol.Count
        If Not (mcol.ITEM(key) Is Nothing) Then
            KeyAux = key & cont
            cont = cont + 1
        End If
    Next i
    AsignaSeccion = KeyAux
    Exit Function
ErrTrap:
    If Err.Number = 5 Then AsignaSeccion = IIf(cont > 0, key & cont, key)
End Function

Private Function RecuperaSeccionAsignada(ByVal key As String) As String
    Dim i As Long, KeyAux As String
    Dim cont As Long        '-->debe llevarse un contador por nombre de sección, o hacer recursivo hasta que no exista
    On Error GoTo ErrTrap
    cont = 0
    If Len(mcolAux.ITEM(key)) > 0 Then
        cont = 1
        For i = 1 To mcolAux.Count
            KeyAux = key & cont
            If Len(mcolAux.ITEM(KeyAux)) > 0 Then cont = cont + 1
        Next i
    End If
    RecuperaSeccionAsignada = KeyAux
    Exit Function
ErrTrap:
    If Err.Number = 5 Then
        RecuperaSeccionAsignada = IIf(cont > 0, key & cont, key)
        mcolAux.Add key, RecuperaSeccionAsignada
    End If
End Function


'Esta función debe adicionarse/adecuarse para impresión de Asiento utilizando <CTRL>+A.
        'ejemplo tomado de librería HormiprintA
Public Sub PrintAsiento(ByVal objEmpresa As Empresa, _
                       Directo As Boolean, _
                       Copias As Integer, _
                       TransId As Long, _
                       Optional CodTrans As String, _
                       Optional NumTrans As Long, _
                       Optional ByVal objGNComp As GNComprobante)

'Se puede llamar de 3 formas, por ejemplo:
'1. objEmp, False, 1, TransId                  (Especifica por TransID)
'2. objEmp, False, 1, 0, CodTrans, NumTrans    (Especifica por CodTrans y NumTrans)
'3. objEmp, False, 1, 0, "", 0, objGNComp      (Envia el objeto GNComprobante)
'
'Directo = True: Imprime directamente a por la impresora.
'        = False:Abre la pantalla de vista previa.
'Copias : Número de copias
'


    'Si no ha enviado el objeto mismo
   If objGNComp Is Nothing Then
        'Recupera de la base
        Set objGNComp = objEmpresa.RecuperaGNComprobante(TransId, CodTrans, NumTrans)
        If objGNComp Is Nothing Then
            Err.Raise ERR_NOHAYCODIGO, App.EXEName, _
                "No se puede recuperar la transacción. " & vbCr & _
                "(tid=" & TransId & ", CodTrans='" & CodTrans & "', NumTrans=" & NumTrans & ")"
        End If
    End If

    'Si está anulado nunca puede imprimir
    If objGNComp.Estado = ESTADO_ANULADO Then
        Err.Raise ERR_NOIMPRIME3, App.EXEName, MSGERR_NOIMPRIME3
    End If

    'Si la transacción requiere que esté aprobada
    If objGNComp.GNTrans.ImprimeSoloAprobado Then
        'Si no está aprobada o despachada, no puede imprimir
        If Not (objGNComp.Estado = ESTADO_APROBADO Or _
                objGNComp.Estado = ESTADO_DESPACHADO) Then
            Err.Raise ERR_NOIMPRIME, App.EXEName, MSGERR_NOIMPRIME
        End If
    End If

    Set mobjGnComp = objGNComp
    
    'Se asignaría un apertura directa del archivo de asiento, que naturalmente siempre
    'tendría el mismo nombre : CTD
    If Not mobjGnComp.GNTrans.BandImpGlobal Then
        ArchivoPadre = App.Path
        If Right$(App.Path, 1) <> "\" Then ArchivoPadre = ArchivoPadre & "\"
    Else
        ArchivoPadre = mobjGnComp.GNTrans.RutaLibImp
        If Right$(mobjGnComp.GNTrans.RutaLibImp, 1) <> "\" Then ArchivoPadre = ArchivoPadre & "\"
    End If
    ArchivoPadre = ArchivoPadre & "CTD.txt"              'mobjGnComp.CodTrans & ".txt"
    
    'ImprimirDocumento objGNComp.GNTrans.ImprimeComprobante = "P"
    ImprimirDocumento True
    
'    'Prepara el objeto de impresión para cada transacción
'    Set mIp = Nothing       'Limpia lo anterior
'    Set mIp = New clsCTD
'    Set mIp.GNComprobante = objGNComp
'
'    'Crea una instancia de PreviewVSPrint de SiiPrint.Dll
'    Set mSp = New SiiPrint.PreviewVSPrint
'    mSp.Caption = objGNComp.CodTrans & " " & objGNComp.NumTrans
'    mSp.Copias = Copias
'    mSp.CargaFormatos mIp.EnumFormato
'    mSp.EnabledExport = spefHTML + spefPDF
'
'    'Abre el formulario si no es directo a la impresora
'    If Not Directo Then mSp.Show
'
'    'Genera el documento
'    mSp_Regenerar
'
'    'Envia a la impresora si es directo
'    If Directo Then mSp.Imprimir
End Sub

Public Sub PrintItem(ByVal objEmpresa As Empresa, _
                       Directo As Boolean, _
                       Copias As Integer, _
                       TransId As Long, _
                       Optional CodTrans As String, _
                       Optional NumTrans As Long, _
                       Optional ByVal objGNComp As GNComprobante, _
                       Optional fila As Integer, _
                       Optional CODITEM As String)
    
'Se puede llamar de 3 formas, por ejemplo:
'1. objEmp, False, 1, TransId                  (Especifica por TransID)
'2. objEmp, False, 1, 0, CodTrans, NumTrans    (Especifica por CodTrans y NumTrans)
'3. objEmp, False, 1, 0, "", 0, objGNComp      (Envia el objeto GNComprobante)
'
'Directo = True: Imprime directamente a por la impresora.
'        = False:Abre la pantalla de vista previa.
'Copias : Número de copias
'
    

    'Si no ha enviado el objeto mismo
    If objGNComp Is Nothing Then
        'Recupera de la base
        Set objGNComp = objEmpresa.RecuperaGNComprobante(TransId, CodTrans, NumTrans)
        If objGNComp Is Nothing Then
            Err.Raise ERR_NOHAYCODIGO, App.EXEName, _
                "No se puede recuperar la transacción. " & vbCr & _
                "(tid=" & TransId & ", CodTrans='" & CodTrans & "', NumTrans=" & NumTrans & ")"
        End If
    End If

    'Si está anulado nunca puede imprimir
'    If objGNComp.Estado = ESTADO_ANULADO Then
'        Err.Raise ERR_NOIMPRIME3, App.EXEName, MSGERR_NOIMPRIME3
'    End If

    'Si la transacción requiere que esté aprobada
'    If objGNComp.GNTrans.ImprimeSoloAprobado Then
'        'Si no está aprobada o despachada, no puede imprimir
'        If Not (objGNComp.Estado = ESTADO_APROBADO Or _
'                objGNComp.Estado = ESTADO_DESPACHADO) Then
'            Err.Raise ERR_NOIMPRIME, App.EXEName, MSGERR_NOIMPRIME
'        End If
'    End If

    Set mobjGnComp = objGNComp
'    Set ip.GNComprobante = objGNComp

    'Para imprimir varios documentos, se empezará por recuperar el archivo principal, en el que debe
    'constar los nombres de todos los documentos a imprimir, los cuales serán asignados a un vector
    'para su posterior impresión
    
    AbreArchivoPadreDetalle
    ImprimirItem False, fila, CODITEM
End Sub


Private Sub ImprimirItem(Pregunta As Boolean, ByVal numlin As Integer, ByVal CODITEM As String)
    Dim rt As Integer, v() As Variant
    Dim i As Long, NumDctos As Long

    v = AsignaArchivoHijo(NumDctos)
'    For i = 1 To NumDctos
'        rt = vbYes
'        If NumDctos > 0 Then
'        rt = MsgBox("El sistema se dispone a imprimir documento: " & v(0, i) & vbCrLf & _
'                              "Confirma Impresión?", vbYesNo)
'        End If
        nomarchi = v(1, 1)
'        If rt = vbYes Then
            RecuperaArchivo
            GeneraLinea numlin, CODITEM
'        End If
'    Next i
End Sub


Private Sub GeneraLinea(ByVal fila As Integer, ByVal CODITEM As String)
    Dim i  As Integer, s As String
    Dim nTxt As Integer, numLinea As Integer
    Dim bandfirst As Boolean
    If Config.Modo = "T" Then  'Modo texto
        Set mSpTxt = New SiiPrint.PrintTxt
    Else
    End If
    gfmt = mobjGnComp.FormatoMoneda
    gfmtCant = mobjGnComp.Empresa.GNOpcion.FormatoCantidad
    
    '***Agregado ANGEL 12/Mayo/2003
    mSpTxt.NombreImpresora = Config.NombreImpresora
    mSpTxt.LongitudCorte = Config.LongitudCorte
    '**** Ageregado jeaa 29/09/04
    mSpTxt.IndentLeft = Config.MargenIzq
    mSpTxt.ImpInicializa
    
    mSpTxt.StartDoc mobjGnComp.CodTrans & " " & mobjGnComp.NumTrans
    mSpTxt.NumLineaPagina = Config.numLinea
    nTxt = FreeFile
    Open nomarchi For Input As nTxt
    'Escaneado de archivo  para   guardar Elementos
    'Lee las lineas de archivo de definicion
    numLinea = 0
    ActiveSection = ""
    bandfirst = True
    Do Until EOF(nTxt)
        Line Input #nTxt, s
        s = PreparaCad(s)  ' elimina los comentarios
        verificaSeccion s, bandfirst
        If Len(ActiveSection) > 0 And bandfirst = True Then
             'If ActiveSection <> "CONFIG" And ActiveSection <> "PARAMETROS" Then   '(ActiveSection <> "CARGARMOTIVTRASL" And
             If ActiveSection = "ITEM" Then 'And ActiveSection <> "PARAMETROS" Then   '(ActiveSection <> "CARGARMOTIVTRASL" And
                'Objeto de impresion Apunta a la clase
                Set mcol.ITEM(ActiveSection).Sptxt = mSpTxt
                'mcol.Item(ActiveSection).PrintSection
                mcol.ITEM(ActiveSection).PrintSection_ItemLInea fila, CODITEM
                ProcesaLinea_ImpLinea s, fila, CODITEM
                Exit Do
                bandfirst = False
             End If
        ElseIf Len(ActiveSection) = 0 Then
'             ProcesaLinea_ImpLinea s, Fila, CODITEM
        End If
        numLinea = numLinea + 1
    Loop
    'Cierra el archivo de texto
    Close nTxt
    'mSpTxt.ImpSaltoPagina
    mSpTxt.EndDoc
    Set mcol = Nothing
    Set mcolAux = Nothing
End Sub

Public Sub ProcesaLinea_ImpLinea(s As String, numlin As Integer, CODITEM As String)
    Dim i As Long, v As Variant, cad As String
    Dim cmd As String, bandSalto As Boolean
    'Set mobjGNOp = mGNComp.Empresa.GNOpcion
    'Datos de cliente (Codigo, Nombre, RUC, Direc,Tel)
    'Set cli = mGNComp.Empresa.RecuperaPCProvCli(mGNComp.CodClienteRef)
    's = mprops.Texto
    On Error GoTo ErrTrap
    bandSalto = False
    With mSpTxt
        For i = 1 To Len(s)
            'Si es un comando
            If Mid$(s, i, 13) = "[SECTION ITEM" Then
                cad = Mid$(s, i + 13, InStr(i + 13, s, "]") - (i + 13))
                'Carga  en  un vector las  configuraciones
                v = Split(cad, ";")
                If Not IsEmpty(v) Then
                    ActiveSection = Trim$(v(0))
                End If
                'i = i + Len(cad) + 8
                Exit Sub
            ElseIf Mid$(s, i, 10) = "[/SECTION]" Then
               ActiveSection = ""
               'i = i + 10
               Exit Sub
            Else
                .PrintLine Mid$(s, i, 1)          'Manda un carácter a la impresora
            End If
        Next i
        If bandSalto = False Then .PrintLine "", 1    'cambio de linea
    End With
    Exit Sub
ErrTrap:
    Set mcol = Nothing
    Set mcolAux = Nothing
    Err.Raise ERR_NOIMPRIME, App.EXEName, "Error en archivo " & _
                nomarchi & vbKeyReturn & " linea: " & s
End Sub


Private Sub ImprimirCabecera(Pregunta As Boolean)
    Dim rt As Integer, v() As Variant
    Dim i As Long, NumDctos As Long

    v = AsignaArchivoHijo(NumDctos)
        nomarchi = v(1, 1)
            RecuperaArchivo
            GeneraDoc
End Sub



Public Sub PrintCabecera(ByVal objEmpresa As Empresa, _
                       Directo As Boolean, _
                       Copias As Integer, _
                       TransId As Long, _
                       Optional CodTrans As String, _
                       Optional NumTrans As Long, _
                       Optional ByVal objGNComp As GNComprobante)
    
        'Se puede llamar de 3 formas, por ejemplo:
        '1. objEmp, False, 1, TransId                  (Especifica por TransID)
        '2. objEmp, False, 1, 0, CodTrans, NumTrans    (Especifica por CodTrans y NumTrans)
        '3. objEmp, False, 1, 0, "", 0, objGNComp      (Envia el objeto GNComprobante)
        '
        'Directo = True: Imprime directamente a por la impresora.
        '        = False:Abre la pantalla de vista previa.
        'Copias : Número de copias
        '
    'Si no ha enviado el objeto mismo
    If objGNComp Is Nothing Then
        'Recupera de la base
        Set objGNComp = objEmpresa.RecuperaGNComprobante(TransId, CodTrans, NumTrans)
        If objGNComp Is Nothing Then
            Err.Raise ERR_NOHAYCODIGO, App.EXEName, _
                "No se puede recuperar la transacción. " & vbCr & _
                "(tid=" & TransId & ", CodTrans='" & CodTrans & "', NumTrans=" & NumTrans & ")"
        End If
    End If

    'Si está anulado nunca puede imprimir
    'Si la transacción requiere que esté aprobada
    Set mobjGnComp = objGNComp

    'Para imprimir varios documentos, se empezará por recuperar el archivo principal, en el que debe
    'constar los nombres de todos los documentos a imprimir, los cuales serán asignados a un vector
    'para su posterior impresión
    
    AbreArchivoPadreCabecera
    ImprimirCabecera False
End Sub


Private Sub AbreArchivoPadreCabecera()
    On Error GoTo ErrTrap
    If Not mobjGnComp.GNTrans.BandImpGlobal Then
        ArchivoPadre = App.Path
        If Right$(App.Path, 1) <> "\" Then ArchivoPadre = ArchivoPadre & "\"
    Else
        ArchivoPadre = mobjGnComp.GNTrans.RutaLibImp
        If Right$(mobjGnComp.GNTrans.RutaLibImp, 1) <> "\" Then ArchivoPadre = ArchivoPadre & "\"
    End If
    ArchivoPadre = ArchivoPadre & mobjGnComp.CodTrans & "_cabecera" & ".txt"
    Exit Sub
ErrTrap:
        Err.Raise ERR_NOIMPRIME, App.EXEName, Err.Description
End Sub

Private Sub AbreArchivoPadreDetalle()
    On Error GoTo ErrTrap
    If Not mobjGnComp.GNTrans.BandImpGlobal Then
        ArchivoPadre = App.Path
        If Right$(App.Path, 1) <> "\" Then ArchivoPadre = ArchivoPadre & "\"
    Else
        ArchivoPadre = mobjGnComp.GNTrans.RutaLibImp
        If Right$(mobjGnComp.GNTrans.RutaLibImp, 1) <> "\" Then ArchivoPadre = ArchivoPadre & "\"
    End If
    ArchivoPadre = ArchivoPadre & mobjGnComp.CodTrans & "_detalle" & ".txt"
    Exit Sub
ErrTrap:
        Err.Raise ERR_NOIMPRIME, App.EXEName, Err.Description
End Sub

Private Sub AbreArchivoPadreTotales()
    On Error GoTo ErrTrap
    If Not mobjGnComp.GNTrans.BandImpGlobal Then
        ArchivoPadre = App.Path
        If Right$(App.Path, 1) <> "\" Then ArchivoPadre = ArchivoPadre & "\"
    Else
        ArchivoPadre = mobjGnComp.GNTrans.RutaLibImp
        If Right$(mobjGnComp.GNTrans.RutaLibImp, 1) <> "\" Then ArchivoPadre = ArchivoPadre & "\"
    End If
    ArchivoPadre = ArchivoPadre & mobjGnComp.CodTrans & "_totales" & ".txt"
    Exit Sub
ErrTrap:
        Err.Raise ERR_NOIMPRIME, App.EXEName, Err.Description
End Sub

Private Sub ImprimirTotales(Pregunta As Boolean)
    Dim rt As Integer, v() As Variant
    Dim i As Long, NumDctos As Long

    v = AsignaArchivoHijo(NumDctos)
        nomarchi = v(1, 1)
            RecuperaArchivo
            GeneraDoc
End Sub

Public Sub PrintTotales(ByVal objEmpresa As Empresa, _
                       Directo As Boolean, _
                       Copias As Integer, _
                       TransId As Long, _
                       Optional CodTrans As String, _
                       Optional NumTrans As Long, _
                       Optional ByVal objGNComp As GNComprobante)
    
        'Se puede llamar de 3 formas, por ejemplo:
        '1. objEmp, False, 1, TransId                  (Especifica por TransID)
        '2. objEmp, False, 1, 0, CodTrans, NumTrans    (Especifica por CodTrans y NumTrans)
        '3. objEmp, False, 1, 0, "", 0, objGNComp      (Envia el objeto GNComprobante)
        '
        'Directo = True: Imprime directamente a por la impresora.
        '        = False:Abre la pantalla de vista previa.
        'Copias : Número de copias
        '
    'Si no ha enviado el objeto mismo
    If objGNComp Is Nothing Then
        'Recupera de la base
        Set objGNComp = objEmpresa.RecuperaGNComprobante(TransId, CodTrans, NumTrans)
        If objGNComp Is Nothing Then
            Err.Raise ERR_NOHAYCODIGO, App.EXEName, _
                "No se puede recuperar la transacción. " & vbCr & _
                "(tid=" & TransId & ", CodTrans='" & CodTrans & "', NumTrans=" & NumTrans & ")"
        End If
    End If

    'Si está anulado nunca puede imprimir
    'Si la transacción requiere que esté aprobada
    Set mobjGnComp = objGNComp

    'Para imprimir varios documentos, se empezará por recuperar el archivo principal, en el que debe
    'constar los nombres de todos los documentos a imprimir, los cuales serán asignados a un vector
    'para su posterior impresión
    
    AbreArchivoPadreTotales
    ImprimirTotales False
End Sub


Public Sub PrintTransLoteRuta(ByVal objEmpresa As Empresa, _
                       Directo As Boolean, _
                       Copias As Integer, _
                       TransId As Long, _
                       archivo As String, _
                       Optional CodTrans As String, _
                       Optional NumTrans As Long, _
                       Optional ByVal objGNComp As GNComprobante)
    
'Se puede llamar de 3 formas, por ejemplo:
'1. objEmp, False, 1, TransId                  (Especifica por TransID)
'2. objEmp, False, 1, 0, CodTrans, NumTrans    (Especifica por CodTrans y NumTrans)
'3. objEmp, False, 1, 0, "", 0, objGNComp      (Envia el objeto GNComprobante)
'
'Directo = True: Imprime directamente a por la impresora.
'        = False:Abre la pantalla de vista previa.
'Copias : Número de copias
'
    

    'Si no ha enviado el objeto mismo
    If objGNComp Is Nothing Then
        'Recupera de la base
        Set objGNComp = objEmpresa.RecuperaGNComprobante(TransId, CodTrans, NumTrans)
        If objGNComp Is Nothing Then
            Err.Raise ERR_NOHAYCODIGO, App.EXEName, _
                "No se puede recuperar la transacción. " & vbCr & _
                "(tid=" & TransId & ", CodTrans='" & CodTrans & "', NumTrans=" & NumTrans & ")"
        End If
    End If

    'Si está anulado nunca puede imprimir
    If objGNComp.Estado = ESTADO_ANULADO Then
        Err.Raise ERR_NOIMPRIME3, App.EXEName, MSGERR_NOIMPRIME3
    End If

    'Si la transacción requiere que esté aprobada
    If objGNComp.GNTrans.ImprimeSoloAprobado Then
        'Si no está aprobada o despachada, no puede imprimir
        If Not (objGNComp.Estado = ESTADO_APROBADO Or _
                objGNComp.Estado = ESTADO_DESPACHADO Or _
                objGNComp.Estado = ESTADO_SEMDESPACHADO) Then
            Err.Raise ERR_NOIMPRIME, App.EXEName, MSGERR_NOIMPRIME
        End If
    End If

    Set mobjGnComp = objGNComp
'    Set ip.GNComprobante = objGNComp

    'Para imprimir varios documentos, se empezará por recuperar el archivo principal, en el que debe
    'constar los nombres de todos los documentos a imprimir, los cuales serán asignados a un vector
    'para su posterior impresión
    
    ArchivoPadre = archivo
    ImprimirDocumento (False)
End Sub

Public Sub PrintAsientoPresup(ByVal objEmpresa As Empresa, _
                       Directo As Boolean, _
                       Copias As Integer, _
                       TransId As Long, _
                       Optional CodTrans As String, _
                       Optional NumTrans As Long, _
                       Optional ByVal objGNComp As GNComprobante)

'Se puede llamar de 3 formas, por ejemplo:
'1. objEmp, False, 1, TransId                  (Especifica por TransID)
'2. objEmp, False, 1, 0, CodTrans, NumTrans    (Especifica por CodTrans y NumTrans)
'3. objEmp, False, 1, 0, "", 0, objGNComp      (Envia el objeto GNComprobante)
'
'Directo = True: Imprime directamente a por la impresora.
'        = False:Abre la pantalla de vista previa.
'Copias : Número de copias
'


    'Si no ha enviado el objeto mismo
   If objGNComp Is Nothing Then
        'Recupera de la base
        Set objGNComp = objEmpresa.RecuperaGNComprobante(TransId, CodTrans, NumTrans)
        If objGNComp Is Nothing Then
            Err.Raise ERR_NOHAYCODIGO, App.EXEName, _
                "No se puede recuperar la transacción. " & vbCr & _
                "(tid=" & TransId & ", CodTrans='" & CodTrans & "', NumTrans=" & NumTrans & ")"
        End If
    End If

    'Si está anulado nunca puede imprimir
    If objGNComp.Estado = ESTADO_ANULADO Then
        Err.Raise ERR_NOIMPRIME3, App.EXEName, MSGERR_NOIMPRIME3
    End If

    'Si la transacción requiere que esté aprobada
    If objGNComp.GNTrans.ImprimeSoloAprobado Then
        'Si no está aprobada o despachada, no puede imprimir
        If Not (objGNComp.Estado = ESTADO_APROBADO Or _
                objGNComp.Estado = ESTADO_DESPACHADO) Then
            Err.Raise ERR_NOIMPRIME, App.EXEName, MSGERR_NOIMPRIME
        End If
    End If

    Set mobjGnComp = objGNComp
    
    'Se asignaría un apertura directa del archivo de asiento, que naturalmente siempre
    'tendría el mismo nombre : CTD
    If Not mobjGnComp.GNTrans.BandImpGlobal Then
        ArchivoPadre = App.Path
        If Right$(App.Path, 1) <> "\" Then ArchivoPadre = ArchivoPadre & "\"
    Else
        ArchivoPadre = mobjGnComp.GNTrans.RutaLibImp
        If Right$(mobjGnComp.GNTrans.RutaLibImp, 1) <> "\" Then ArchivoPadre = ArchivoPadre & "\"
    End If
    ArchivoPadre = ArchivoPadre & "PRED.txt"              'mobjGnComp.CodTrans & ".txt"
    
    'ImprimirDocumento objGNComp.GNTrans.ImprimeComprobante = "P"
    ImprimirDocumento True
    
'    'Prepara el objeto de impresión para cada transacción
'    Set mIp = Nothing       'Limpia lo anterior
'    Set mIp = New clsCTD
'    Set mIp.GNComprobante = objGNComp
'
'    'Crea una instancia de PreviewVSPrint de SiiPrint.Dll
'    Set mSp = New SiiPrint.PreviewVSPrint
'    mSp.Caption = objGNComp.CodTrans & " " & objGNComp.NumTrans
'    mSp.Copias = Copias
'    mSp.CargaFormatos mIp.EnumFormato
'    mSp.EnabledExport = spefHTML + spefPDF
'
'    'Abre el formulario si no es directo a la impresora
'    If Not Directo Then mSp.Show
'
'    'Genera el documento
'    mSp_Regenerar
'
'    'Envia a la impresora si es directo
'    If Directo Then mSp.Imprimir
End Sub

Public Sub ImprimeRolGeneralxLote(ByVal gc As GNComprobante, ByVal grdIngresos As Variant, ByVal grdEgresos As Variant, _
                                ByVal codEmpleado As String, ByVal nomcargo As String, ByVal MfechaIng As Date, ByVal Nombre As String, ByVal Apagar As Currency, _
                                ByVal dpto As String, ByVal cedula As String, ByVal bandInd As Boolean)

    Dim pt As SiiPrint.PrintTxt, Titulo As String, NumLineas As Long, esp As Long
    Dim LineasRol() As String
    Dim i As Integer, elem As Elementos, codelem As String
    
    Titulo = gc.Descripcion '& ": " & Format(gc.FechaDevol, "MMMM-YYYY")
    'titulo = "ROL DE PAGOS - CORRESPONDIENTE A: "
    Set pt = New SiiPrint.PrintTxt
    With pt
        .StartDoc Titulo
        .ImpInicializa

        'Imprime el encabezado del rol individual
        ImpEncabezadoRol gc, pt, Titulo
        .ImpCondensado 1

        'Datos del Empleado
        .IndentLeft = 10
        
            .ImpCondensado 1
            .PrintLine .Rellenar("Departamento: ", 20, True)
            .PrintLine .Rellenar(dpto, 40, True), 1 'departamento
        
        .PrintLine .Rellenar("CodEmpleado: ", 20, True)
        .PrintLine .Rellenar(codEmpleado, 30, True) & "   "   'Código del Empleado
        .PrintLine .Rellenar("Nombre: ", 20, True)
        .PrintLine .Rellenar(Nombre, 40, True), 1            'Nombre del Empleado
        'JEAA 02/03/05
        .PrintLine .Rellenar("Cargo: ", 20, True)
        .PrintLine .Rellenar(nomcargo, 30, True) & "   "            'cargo del empleado
        .PrintLine .Rellenar("FechaIngreso: ", 20, True)
        .PrintLine .Rellenar(MfechaIng, 30, True), 1          'Fecha ingreso
        .PrintLine .Rellenar("I N G R E S O S", 35, True) & Space$(31)
        .PrintLine .Rellenar("E G R E S O S", 35, True), 1
        .ImpCondensado 0
        'Define el número de líneas que se van a imprimir
        NumLineas = IIf(UBound(grdIngresos, 1) > UBound(grdEgresos, 1), UBound(grdIngresos, 1), UBound(grdEgresos, 1)) - 1
        If NumLineas <= 0 Then
            MsgBox "No existe datos para imprimir el rol"
            Exit Sub
        End If

        'Imprime los elementos del rol con sus valores correspondientes
        If bandInd Then
            ImprimeDetalleGeneral gc, codEmpleado, pt, NumLineas, grdIngresos, grdEgresos
        Else
            ImprimeDetalleGeneralxLote gc, codEmpleado, pt, NumLineas, grdIngresos, grdEgresos
        End If
        .ImpCondensado 0

        'Imprime el Total a Pagar
        .ImpEnfatizado 1
        .PrintLine "TOTAL A PAGAR: (USD)  " & pt.Rellenar(Format(Apagar, gc.FormatoMoneda), 20, False), 1
        .ImpEnfatizado 0
'        If gobjRol.EmpresaActual.Opcion.ObtenerValor("DatosBanco") Then
'            .PrintLine "Cheque #: " & .Rellenar(numcheque, 20, True) & Space$(5) & _
'                       "Banco: " & .Rellenar(Banco, 20, True), 2
'        Else
        Dim Salto As Integer
        
        NumLineas = gc.Empresa.GNOpcion.ObtenerValor("LineasPorPagina")
        Salto = gc.Empresa.GNOpcion.ObtenerValor("SaltoLinea")
            .PrintLine "", Salto
'        End If
        .PrintLine Space$(5) & "____________________               ____________________", 1
        .PrintLine Space$(5) & .Rellenar(gc.Empresa.GNOpcion.NombreEmpresa, 25, True) & _
                   Space$(12) & "Recibi Conforme"
        .PrintLine Space$(65) & "C.I. " & .Rellenar(cedula, 12, True)
        

        '*** Angel en vez de enviar salto de página, saltamos lineas
        '*** Hasta igualar al número de líneas por página
        'If gobjRol.EmpresaActual.Opcion.ObtenerValor("SaltoDePagina") Then
         '   .ImpSaltoPagina
        'Else
            If (.PosY Mod NumLineas) <> 0 Then
                .PrintLine "", (NumLineas - .PosY)
            End If
                .PrintLine "", 1
        'End If
        .EndDoc
    End With
    Set pt = Nothing
End Sub

Public Sub PrintComprobanteRet(ByRef gc As GNComprobante, ByRef codEmpleado As String)
    Set mobjGnComp = gc
    'AbreArchivoPadreComRet
    AbreArchivoPadre
    ImprimirComprobanteRet gc, codEmpleado
End Sub

Private Sub ImprimirComprobanteRet(ByVal gc As GNComprobante, ByVal codEmpleado As String)
    Dim rt As Integer, v() As Variant
    Dim i As Long, NumDctos As Long

    v = AsignaArchivoHijo(NumDctos)
    For i = 1 To NumDctos
        rt = vbYes
        If NumDctos > 1 Then
        rt = MsgBox("El sistema se dispone a imprimir documento Rel. Dep.: " & v(0, i) & vbCrLf & _
                              "Confirma Impresión?", vbYesNo)
        End If
        nomarchi = v(1, i)
        If rt = vbYes Then
            RecuperaArchivo
            GeneraDocComRet gc, codEmpleado
        End If
    Next i
End Sub


Private Sub GeneraDocComRet(ByVal gc As GNComprobante, ByVal codEmpleado As String)
    Dim i  As Integer, s As String
    Dim nTxt As Integer, numLinea As Integer
    Dim gOpcion As GNOpcion
    Dim bandfirst As Boolean
    If Config.Modo = "T" Then  'Modo texto
        Set mSpTxt = New SiiPrint.PrintTxt
    Else
    End If
    'gfmt = gOpcion.FormatoMoneda(
    'gfmtCant = mobjGnComp.Empresa.GNOpcion.FormatoCantidad
    
    '***Agregado ANGEL 12/Mayo/2003
    mSpTxt.NombreImpresora = Config.NombreImpresora
    mSpTxt.LongitudCorte = Config.LongitudCorte
    '**** Ageregado jeaa 29/09/04
    mSpTxt.IndentLeft = Config.MargenIzq
    mSpTxt.ImpInicializa
    
   mSpTxt.StartDoc mobjGnComp.CodTrans & " " & mobjGnComp.NumTrans
    mSpTxt.NumLineaPagina = Config.numLinea
    nTxt = FreeFile
    Open nomarchi For Input As nTxt
    'Escaneado de archivo  para   guardar Elementos
    'Lee las lineas de archivo de definicion
    numLinea = 0
    ActiveSection = ""
    bandfirst = True
    Do Until EOF(nTxt)
        Line Input #nTxt, s
        s = PreparaCad(s)  ' elimina los comentarios
        verificaSeccion s, bandfirst
        If Len(ActiveSection) > 0 And bandfirst = True Then
             If ActiveSection <> "CONFIG" And ActiveSection <> "PARAMETROS" Then   '(ActiveSection <> "CARGARMOTIVTRASL" And
                'Objeto de impresion Apunta a la clase
                Set mcol.ITEM(ActiveSection).Sptxt = mSpTxt
                
                mcol.ITEM(ActiveSection).PrintSectionGenCom gc, codEmpleado
                bandfirst = False
             End If
        ElseIf Len(ActiveSection) = 0 Then
             ProcesaLineaComRet s, gc, codEmpleado
        End If
        numLinea = numLinea + 1
    Loop
    'Cierra el archivo de texto
    Close nTxt
    'mSpTxt.ImpSaltoPagina
    mSpTxt.EndDoc
    Set mcol = Nothing
    Set mcolAux = Nothing
End Sub
Public Sub ProcesaLineaComRet(s As String, gc As GNComprobante, codEmpleado As String)
    Dim i As Long, v As Variant, cad As String
    Dim cmd As String, bandSalto As Boolean
    'Set mobjGNOp = mGNComp.Empresa.GNOpcion
    'Datos de cliente (Codigo, Nombre, RUC, Direc,Tel)
    'Set cli = mGNComp.Empresa.RecuperaPCProvCli(mGNComp.CodClienteRef)
    's = mprops.Texto
    On Error GoTo ErrTrap
    bandSalto = False
    With mSpTxt
        For i = 1 To Len(s)
            'Si es un comando
            If Mid$(s, i, 2) = "%(" Then
                cmd = Mid$(s, i + 2, InStr(i + 2, s, ")") - (i + 2))
                ProcesaComando cmd, mSpTxt, bandSalto
                i = i + Len(cmd) + 2
            'Si es una variable
            ElseIf Mid$(s, i, 2) = "$(" Then
                cmd = Mid$(s, i + 2, InStr(i + 2, s, ")") - (i + 2))
                gnProcesaComRet cmd, mSpTxt, gc, codEmpleado
                i = i + Len(cmd) + 2
            ElseIf Mid$(s, i, 8) = "[SECTION" Then
                cad = Mid$(s, i + 8, InStr(i + 8, s, "]") - (i + 8))
                'Carga  en  un vector las  configuraciones
                v = Split(cad, ";")
                If Not IsEmpty(v) Then
                    ActiveSection = Trim$(v(0))
                End If
                'i = i + Len(cad) + 8
                Exit Sub
            ElseIf Mid$(s, i, 10) = "[/SECTION]" Then
               ActiveSection = ""
               'i = i + 10
               Exit Sub
            Else
                .PrintLine Mid$(s, i, 1)          'Manda un carácter a la impresora
            End If
        Next i
        If bandSalto = False Then .PrintLine "", 1    'cambio de linea
    End With
    Exit Sub
ErrTrap:
    Set mcol = Nothing
    Set mcolAux = Nothing
    Err.Raise ERR_NOIMPRIME, App.EXEName, "Error en archivo " & _
                nomarchi & vbKeyReturn & " linea: " & s
End Sub

Public Sub ImprimeQuincenaRol(ByVal gc As GNComprobante, ByVal grd As Variant)
    Dim pt As SiiPrint.PrintTxt, Titulo As String, NumLineas As Long, esp As Long
    Dim i As Integer, dpto As String, cod_emp As String, Nombre As String, s_total As String, cedula As String
    Dim pc As pcProvCli
       
  

    For i = 1 To UBound(grd, 1)
            Titulo = "PAGO DE QUINCENA."
            Set pt = New SiiPrint.PrintTxt
            With pt
                .StartDoc Titulo & Trim$(Str$(i))
                .ImpInicializa
                .PrintLine "", 3
                ImpEncabezadoRol gc, pt, Titulo
                .IndentLeft = 20
                .ImpCondensado 1
                .PrintLine .Rellenar("FECHA_IMPRES:", 14, True)
                .PrintLine .Rellenar(Date, 20, True), 1
                .PrintLine .Rellenar("MES:", 14, True)
                .PrintLine .Rellenar(UCase$(Format(gc.FechaDevol, "MMMM")), 20, True), 1
                .PrintLine .Rellenar("AÑO:", 14, True)
                .PrintLine .Rellenar(Format(gc.FechaDevol, "YYYY"), 4, True), 1
                
                'Datos del Empleado
               ' dpto = grd(i, COL_DPT)
                cod_emp = grd(i, 2)
                Nombre = grd(i, 3)
                s_total = grd(i, 4)
                Set pc = gc.Empresa.RecuperaPCProvCli(grd(i, 2))
               ' cedula = grd(i, COL_CED)
                
                If gc.Empresa.GNOpcion.ObtenerValor("Departamento") Then
                    .PrintLine .Rellenar("DEPARTAMENTO:", 14, True)
                    .PrintLine .Rellenar(UCase$(pc.CodGrupo1), 30, True), 1
                End If
                
                .PrintLine .Rellenar("COD_EMPLEADO:", 14, True)
                .PrintLine .Rellenar(UCase$(cod_emp), 15, True), 1         'Código del Empleado
                .PrintLine .Rellenar("NOMBRE:", 14, True)
                .PrintLine .Rellenar(UCase$(Nombre), 40, True), 3          'Nombre del Empleado
                
                .IndentLeft = 9
                .ImpEnfatizado 1
                .PrintLine "TOTAL A PAGAR: (USD)  " & pt.Rellenar(Format(s_total, gc.Empresa.GNOpcion.FormatoMoneda("USD")), 20, False), 6
                .IndentLeft = 1
                .PrintLine Space$(8) & "_________________________          _________________________", 1
                 esp = Int(23 - Len(gc.Empresa.GNOpcion.NombreEmpresa) / 2)
                 
                .PrintLine Space$(8) & .Rellenar(Space$(esp) & gc.Empresa.GNOpcion.NombreEmpresa, 25, True) & _
                           Space$(15) & "Recibi Conforme", 1
                 .PrintLine Space$(47) & "C.I." & .Rellenar(Space$(1) & cedula, 15, True)
                .ImpEnfatizado 0
                        
               
                    'If (.PosY Mod gc.Empresa.GNOpcion.ObtenerValor("LineasPorPagina")) <> 0 Then .PrintLine "", (gc.Empresa.GNOpcion.ObtenerValor("LineasPorPagina") - .PosY)
                    '.PrintLine "", gc.Empresa.GNOpcion.ObtenerValor("SaltoLinea") + 1
                    
                    .PrintLine "", gc.Empresa.GNOpcion.ObtenerValor("SaltoLineaQuin")
               
                .EndDoc
            End With
            Set pt = Nothing
            Set pc = Nothing
        'End If
    Next i
End Sub
'AUC ya no necesito este proceso porque se cambio ahora es por transaccion 11/11/2014
Public Sub PrintSolCredito(ByVal objEmpresa As Empresa, ByVal objpcs As PCSOLCREProvCli, _
                       ByVal objGNComp As GNComprobante, _
                       ByVal Ruta As String)
    
'Se puede llamar de 3 formas, por ejemplo:
'1. objEmp, False, 1, TransId                  (Especifica por TransID)
'2. objEmp, False, 1, 0, CodTrans, NumTrans    (Especifica por CodTrans y NumTrans)
'3. objEmp, False, 1, 0, "", 0, objGNComp      (Envia el objeto GNComprobante)
'
'Directo = True: Imprime directamente a por la impresora.
'        = False:Abre la pantalla de vista previa.
'Copias : Número de copias
'
    

    'Si no ha enviado el objeto mismo
'    If objGNComp Is Nothing Then
'        'Recupera de la base
'        Set objGNComp = objEmpresa.RecuperaGNComprobante(TransId, CodTrans, NumTrans)
'        If objGNComp Is Nothing Then
'            Err.Raise ERR_NOHAYCODIGO, App.EXEName, _
'                "No se puede recuperar la transacción. " & vbCr & _
'                "(tid=" & TransId & ", CodTrans='" & CodTrans & "', NumTrans=" & NumTrans & ")"
'        End If
'    End If

    'Si está anulado nunca puede imprimir
'    If objGNComp.Estado = ESTADO_ANULADO Then
'        Err.Raise ERR_NOIMPRIME3, App.EXEName, MSGERR_NOIMPRIME3
'    End If

'    'Si la transacción requiere que esté aprobada
'    If objGNComp.GNTrans.ImprimeSoloAprobado Then
'        'Si no está aprobada o despachada, no puede imprimir
'        If Not (objGNComp.Estado = ESTADO_APROBADO Or _
'                objGNComp.Estado = ESTADO_DESPACHADO Or _
'                objGNComp.Estado = ESTADO_SEMDESPACHADO) Then
'            Err.Raise ERR_NOIMPRIME, App.EXEName, MSGERR_NOIMPRIME
'        End If
'    End If

    Set mobjGnComp = objGNComp
'    Set pcs = objpcs
'    Set ip.GNComprobante = objGNComp

    'Para imprimir varios documentos, se empezará por recuperar el archivo principal, en el que debe
    'constar los nombres de todos los documentos a imprimir, los cuales serán asignados a un vector
    'para su posterior impresión
    
    AbreArchivoPadreSolCre Ruta
    ImprimirSolCredito
End Sub


Private Sub AbreArchivoPadreSolCre(ByVal Ruta As String)
    On Error GoTo ErrTrap
    ArchivoPadre = Ruta & "\SolCredito.txt"
    Exit Sub
ErrTrap:
        Err.Raise ERR_NOIMPRIME, App.EXEName, Err.Description
End Sub

Public Sub ProcesaLineaSolCredito(s As String)
'    Dim i As Long, v As Variant, cad As String
'    Dim cmd As String, bandSalto As Boolean
'    'Set mobjGNOp = mGNComp.Empresa.GNOpcion
'    'Datos de cliente (Codigo, Nombre, RUC, Direc,Tel)
'    'Set cli = mGNComp.Empresa.RecuperaPCProvCli(mGNComp.CodClienteRef)
'    's = mprops.Texto
'    On Error GoTo ErrTrap
'    bandSalto = False
'    With mSpTxt
'        For i = 1 To Len(s)
'            'Si es un comando
'            If Mid$(s, i, 2) = "%(" Then
'                cmd = Mid$(s, i + 2, InStr(i + 2, s, ")") - (i + 2))
'                ProcesaComando cmd, mSpTxt, bandSalto
'                i = i + Len(cmd) + 2
'            'Si es una variable
'            ElseIf Mid$(s, i, 2) = "$(" Then
'                cmd = Mid$(s, i + 2, InStr(i + 2, s, ")") - (i + 2))
'                gnProcesaSolCredito cmd, mSpTxt, pcs
'                i = i + Len(cmd) + 2
'            ElseIf Mid$(s, i, 8) = "[SECTION" Then
'                cad = Mid$(s, i + 8, InStr(i + 8, s, "]") - (i + 8))
'                'Carga  en  un vector las  configuraciones
'                v = Split(cad, ";")
'                If Not IsEmpty(v) Then
'                    ActiveSection = Trim$(v(0))
'                End If
'                'i = i + Len(cad) + 8
'                Exit Sub
'            ElseIf Mid$(s, i, 10) = "[/SECTION]" Then
'               ActiveSection = ""
'               'i = i + 10
'               Exit Sub
'            Else
'                .PrintLine Mid$(s, i, 1)          'Manda un carácter a la impresora
'            End If
'        Next i
'        If bandSalto = False Then .PrintLine "", 1    'cambio de linea
'    End With
'    Exit Sub
'ErrTrap:
'    Set mcol = Nothing
'    Set mcolAux = Nothing
'    Err.Raise ERR_NOIMPRIME, App.EXEName, "Error en archivo " & _
'                nomarchi & vbKeyReturn & " linea: " & s
End Sub


Private Sub GeneraDocSolCre()
    Dim i  As Integer, s As String
    Dim nTxt As Integer, numLinea As Integer
    Dim gOpcion As GNOpcion
    Dim bandfirst As Boolean
    If Config.Modo = "T" Then  'Modo texto
        Set mSpTxt = New SiiPrint.PrintTxt
    Else
    End If
    'gfmt = gOpcion.FormatoMoneda(
    'gfmtCant = mobjGnComp.Empresa.GNOpcion.FormatoCantidad
    
    '***Agregado ANGEL 12/Mayo/2003
    mSpTxt.NombreImpresora = Config.NombreImpresora
    mSpTxt.LongitudCorte = Config.LongitudCorte
    '**** Ageregado jeaa 29/09/04
    mSpTxt.IndentLeft = Config.MargenIzq
    mSpTxt.ImpInicializa
    
   mSpTxt.StartDoc mobjGnComp.CodTrans & " " & mobjGnComp.NumTrans
    mSpTxt.NumLineaPagina = Config.numLinea
    nTxt = FreeFile
    Open nomarchi For Input As nTxt
    'Escaneado de archivo  para   guardar Elementos
    'Lee las lineas de archivo de definicion
    numLinea = 0
    ActiveSection = ""
    bandfirst = True
    Do Until EOF(nTxt)
        Line Input #nTxt, s
        s = PreparaCad(s)  ' elimina los comentarios
        verificaSeccion s, bandfirst
        If Len(ActiveSection) > 0 And bandfirst = True Then
             If ActiveSection <> "CONFIG" And ActiveSection <> "PARAMETROS" Then   '(ActiveSection <> "CARGARMOTIVTRASL" And
                'Objeto de impresion Apunta a la clase
                Set mcol.ITEM(ActiveSection).Sptxt = mSpTxt

                mcol.ITEM(ActiveSection).PrintSection
                bandfirst = False
             End If
        ElseIf Len(ActiveSection) = 0 Then
             ProcesaLineaSolCredito s
        End If
        numLinea = numLinea + 1
    Loop
    'Cierra el archivo de texto
    Close nTxt
    'mSpTxt.ImpSaltoPagina
    mSpTxt.EndDoc
    Set mcol = Nothing
    Set mcolAux = Nothing
End Sub

Private Sub ImprimirSolCredito()
    Dim rt As Integer, v() As Variant
    Dim i As Long, NumDctos As Long

    v = AsignaArchivoHijo(NumDctos)
    For i = 1 To NumDctos
        rt = vbYes
        If NumDctos > 1 Then
        rt = MsgBox("El sistema se dispone a imprimir Sol. Crédito: " & v(0, i) & vbCrLf & _
                              "Confirma Impresión?", vbYesNo)
        End If
        nomarchi = v(1, i)
        If rt = vbYes Then
            RecuperaArchivo
            GeneraDocSolCre
        End If
    Next i
End Sub

Public Sub PrintBoleto(ByVal objEmpresa As Empresa, _
                       Directo As Boolean, _
                       Copias As Integer, _
                       TransId As Long, _
                       Optional CodTrans As String, _
                       Optional NumTrans As Long, _
                       Optional ByVal objGNComp As GNComprobante)
    
'Se puede llamar de 3 formas, por ejemplo:
'1. objEmp, False, 1, TransId                  (Especifica por TransID)
'2. objEmp, False, 1, 0, CodTrans, NumTrans    (Especifica por CodTrans y NumTrans)
'3. objEmp, False, 1, 0, "", 0, objGNComp      (Envia el objeto GNComprobante)
'
'Directo = True: Imprime directamente a por la impresora.
'        = False:Abre la pantalla de vista previa.
'Copias : Número de copias
'
    Dim i As Integer, NUMBOLETO As Integer, ivb As IVBanco, ITEM As IVInventario, IX As Long

    'Si no ha enviado el objeto mismo
    If objGNComp Is Nothing Then
        'Recupera de la base
        Set objGNComp = objEmpresa.RecuperaGNComprobante(TransId, CodTrans, NumTrans)
        If objGNComp Is Nothing Then
            Err.Raise ERR_NOHAYCODIGO, App.EXEName, _
                "No se puede recuperar la transacción. " & vbCr & _
                "(tid=" & TransId & ", CodTrans='" & CodTrans & "', NumTrans=" & NumTrans & ")"
        End If
    End If

    'Si está anulado nunca puede imprimir
    If objGNComp.Estado = ESTADO_ANULADO Then
        Err.Raise ERR_NOIMPRIME3, App.EXEName, MSGERR_NOIMPRIME3
    End If

    'Si la transacción requiere que esté aprobada
    If objGNComp.GNTrans.ImprimeSoloAprobado Then
        'Si no está aprobada o despachada, no puede imprimir
        If Not (objGNComp.Estado = ESTADO_APROBADO Or _
                objGNComp.Estado = ESTADO_DESPACHADO Or _
                objGNComp.Estado = ESTADO_SEMDESPACHADO) Then
            Err.Raise ERR_NOIMPRIME, App.EXEName, MSGERR_NOIMPRIME
        End If
    End If

    Set mobjGnComp = objGNComp
'    Set ip.GNComprobante = objGNComp

    'Para imprimir varios documentos, se empezará por recuperar el archivo principal, en el que debe
    'constar los nombres de todos los documentos a imprimir, los cuales serán asignados a un vector
    'para su posterior impresión
    NUMBOLETO = 0
    For IX = 1 To mobjGnComp.CountIVKardex
        Set ITEM = mobjGnComp.Empresa.RecuperaIVInventarioQuick(mobjGnComp.IVKardex(IX).CodInventario)
        If ITEM.BandRepGastos Then
            NUMBOLETO = mobjGnComp.IVKardex(IX).Cantidad * -1
        End If
    Next IX
    Set ITEM = Nothing
    
    For IX = 1 To mobjGnComp.CountPCKardex
        If Len(mobjGnComp.PCKardex(IX).CodBanco) > 0 Then
            Set ivb = mobjGnComp.Empresa.RecuperaIVBanco(mobjGnComp.PCKardex(IX).CodBanco)
            NUMBOLETO = NUMBOLETO * ivb.Factor
        End If
    Next IX
'    NUMBOLETO
    AbreArchivoBoleto
    If Not mobjGnComp.SoloVer Then
        ImprimirBoleto (NUMBOLETO)
    End If
End Sub

Private Sub AbreArchivoBoleto()
    On Error GoTo ErrTrap
    If Not mobjGnComp.GNTrans.BandImpGlobal Then
        ArchivoPadre = App.Path
        If Right$(App.Path, 1) <> "\" Then ArchivoPadre = ArchivoPadre & "\"
    Else
        ArchivoPadre = mobjGnComp.GNTrans.RutaLibImp
        If Right$(mobjGnComp.GNTrans.RutaLibImp, 1) <> "\" Then ArchivoPadre = ArchivoPadre & "\"
    End If
    ArchivoPadre = ArchivoPadre & "BOLETO.txt"
    Exit Sub
ErrTrap:
        Err.Raise ERR_NOIMPRIME, App.EXEName, Err.Description
End Sub

Private Sub ImprimirBoleto(Numcopia As Integer)
    Dim rt As Integer, v() As Variant
    Dim i As Long, NumDctos As Long, j As Integer
    
    v = AsignaArchivoHijo(NumDctos)
                For j = 1 To Numcopia
    For i = 1 To NumDctos
'        rt = vbYes
'        If Pregunta Or NumDctos > 1 Or mobjGnComp.Impresion = 1 Then
'            If I <> 1 Or Pregunta Or mobjGnComp.Impresion = 1 Then
'                rt = MsgBox("El sistema se dispone a imprimir documento: " & v(0, I) & vbCrLf & _
'                              "Confirma Impresión?", vbYesNo)
'            Else
'                rt = vbYes
'            End If
'        End If
        nomarchi = v(1, i)
'        If rt = vbYes Then
            RecuperaArchivo

                GeneraDoc

'        End If
    Next i
                Next j
End Sub


