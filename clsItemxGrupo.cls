VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsItemxGrupo"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit

'Implements IGnComp

Private mGnComp As GNComprobante
Private mcol As New Collection
'Private mSpTxt As SiiPrint.PrintTxt
Private WithEvents mSpTxt As SiiPrint.PrintTxt
Attribute mSpTxt.VB_VarHelpID = -1


Dim ivk As IVKardex, iv As IVInventario
Dim IvKaux  As IVKardex
Dim IVKOrdenBodega  As IVKardex

Private Type T_PROPS
    Texto As String
    Linea As Integer 'Numero  maximo de lineas
    CambioPag  As Boolean    'True = Cambio de pagina  cuando llega  al numero maximo
    objMain As PrintTrans
    ImpValNota As Boolean    'jeaa 02/09/04 True = Imprime datos del item nota
    Parametros  As String
    Grupo As String 'AUC Agregado cofradia 27/02/2020
End Type

Dim numLinea
Dim mprops As T_PROPS
Dim mNoEsItemNota As Boolean


Public Property Let Texto(value As String)
    mprops.Texto = value
End Property

Public Property Get Texto() As String
    Texto = mprops.Texto
End Property
Public Property Let CambioPag(value As Boolean)
    mprops.CambioPag = value
End Property

Public Property Get CambioPag() As Boolean
    CambioPag = mprops.CambioPag
End Property

Public Property Let Linea(ByVal value As Integer)
    mprops.Linea = value
End Property

Public Property Get Linea() As Integer
    Linea = mprops.Linea
End Property

Public Property Get LineaActual() As Integer
     LineaActual = numLinea
End Property

Public Property Get ImpValNota() As Boolean
    ImpValNota = mprops.ImpValNota
End Property

Public Property Let ImpValNota(value As Boolean)
    mprops.ImpValNota = value
End Property

Public Sub PrintSection()
    Dim i As Long, j As Long, s As String
    'Dim tCant As Currency, tPrecio As Currency, tPrecioSinIVA As Currency, tIVA As Currency
    Dim nombreItem As String, suma As Currency, TotLineas As Long
    Dim cmd As String
    Dim codBodega As String
    Dim CountNumBodega As Integer
    Dim mBodega As Variant
    Dim OtraBodega As Boolean, k As Long
    Dim RESP As Integer, bandYaImprimio As Boolean
    Dim v As Variant, rsItemNoCont As Recordset, sql As String
    On Error GoTo ErrTrap
    With mSpTxt
        s = mprops.Texto  'carga el texto
        numLinea = 0
        TotLineas = 0
        mNoEsItemNota = True
        CountNumBodega = 0
''''        If Not Me.ImpxBod Then
        If Len(Me.Parametros) = 0 And Len(Me.Grupo) = 0 Then
            For i = 1 To mGnComp.CountIVKardex
                Set ivk = mGnComp.IVKardex(i)
                nombreItem = "(Item no encontrado)"
                Set iv = mGnComp.Empresa.RecuperaIVInventario(ivk.CodInventario)
                If Not (iv Is Nothing) Then
                   If iv.CodInventario <> "-" And iv.CodInventario <> "+" And Not iv.BandCambiaDescr Then
                        nombreItem = iv.Descripcion
                        mNoEsItemNota = True
                    Else
                        nombreItem = ivk.Nota
                        If mprops.ImpValNota Then
                            mNoEsItemNota = True
                        Else
                            mNoEsItemNota = False
                        End If
                    End If
                End If
                'Impresion
              If Not ivk.bandImprimir Then   'AUC agregado 08/06/06 para que no imprima las recetas en caso del retro
                        For j = 1 To Len(s)
                            'Si es un comando
                            If Mid$(s, j, 2) = "%(" Then
                                cmd = Mid$(s, j + 2, InStr(j + 2, s, ")") - (j + 2))
                                ProcesaComando cmd, mSpTxt
                                j = j + Len(cmd) + 2
                            'Si es una variable
                            ElseIf Mid$(s, j, 2) = "$(" Then
                                cmd = Mid$(s, j + 2, InStr(j + 2, s, ")") - (j + 2))
                                ProcesaVariable cmd, i, nombreItem
                                 j = j + Len(cmd) + 2
                            'si es otra linea
                            ElseIf Asc(Mid$(s, j, 1)) = vbKeyReturn Then
                                .PrintLine "", 1
                                numLinea = numLinea + 1
                                TotLineas = TotLineas + 1
                            'Si no es un comando ni variable
                            Else
                                .PrintLine Mid$(s, j, 1)          'Manda un carácter a la impresora
                            End If
                        Next j
            
                        If numLinea >= Me.Linea And Me.CambioPag = True Then
                            If TotLineas < mGnComp.CountIVKardex Then   'Solamente si no ha impreso la totalidad de ítems
                                .ImpSaltoPagina         'genera un  salto de pagina
                                numLinea = 0
                            End If
                        ElseIf numLinea >= Me.Linea And Me.CambioPag = False And Me.Linea > 0 Then
                            'Solamente deja de imprimir items
                            Exit For
                        End If
                    End If
            Next i
        ElseIf Len(Me.Parametros) = 0 And Len(Me.Grupo) > 0 Then
            For i = 1 To mGnComp.CountIVKardex
                Set ivk = mGnComp.IVKardex(i)
                nombreItem = "(Item no encontrado)"
                If ivk.codGrupo(6) = Me.Grupo Then
                    Set iv = mGnComp.Empresa.RecuperaIVInventario(ivk.CodInventario)
                    If Not (iv Is Nothing) Then
                       If iv.CodInventario <> "-" And iv.CodInventario <> "+" And Not iv.BandCambiaDescr Then
                            nombreItem = iv.Descripcion
                            mNoEsItemNota = True
                        Else
                            nombreItem = ivk.Nota
                            If mprops.ImpValNota Then
                                mNoEsItemNota = True
                            Else
                                mNoEsItemNota = False
                            End If
                        End If
                    End If
                    'Impresion
                  If Not ivk.bandImprimir Then   'AUC agregado 08/06/06 para que no imprima las recetas en caso del retro
                            For j = 1 To Len(s)
                                'Si es un comando
                                If Mid$(s, j, 2) = "%(" Then
                                    cmd = Mid$(s, j + 2, InStr(j + 2, s, ")") - (j + 2))
                                    ProcesaComando cmd, mSpTxt
                                    j = j + Len(cmd) + 2
                                'Si es una variable
                                ElseIf Mid$(s, j, 2) = "$(" Then
                                    cmd = Mid$(s, j + 2, InStr(j + 2, s, ")") - (j + 2))
                                    ProcesaVariable cmd, i, nombreItem
                                     j = j + Len(cmd) + 2
                                'si es otra linea
                                ElseIf Asc(Mid$(s, j, 1)) = vbKeyReturn Then
                                    .PrintLine "", 1
                                    numLinea = numLinea + 1
                                    TotLineas = TotLineas + 1
                                'Si no es un comando ni variable
                                Else
                                    .PrintLine Mid$(s, j, 1)          'Manda un carácter a la impresora
                                End If
                            Next j
                
                            If numLinea >= Me.Linea And Me.CambioPag = True Then
                                If TotLineas < mGnComp.CountIVKardex Then   'Solamente si no ha impreso la totalidad de ítems
                                    .ImpSaltoPagina         'genera un  salto de pagina
                                    numLinea = 0
                                End If
                            ElseIf numLinea >= Me.Linea And Me.CambioPag = False And Me.Linea > 0 Then
                                'Solamente deja de imprimir items
                                Exit For
                            End If
                        End If
                    End If
                Next i
        Else
            For i = 1 To mGnComp.CountIVKardex
                If i = 1 Then
                    ReDim mBodega(1) As Variant
                    mBodega(CountNumBodega) = mGnComp.IVKardex(i).codBodega
                    CountNumBodega = CountNumBodega + 1
                Else
                    For j = 0 To UBound(mBodega) - 1
                        If mBodega(j) <> mGnComp.IVKardex(i).codBodega Then
                            OtraBodega = True
                        Else
                            OtraBodega = False
                            Exit For
                        End If
                    Next j
                    If OtraBodega Then
                        ReDim Preserve mBodega(UBound(mBodega) + 1)
                        mBodega(CountNumBodega) = mGnComp.IVKardex(i).codBodega
                        CountNumBodega = CountNumBodega + 1
                    End If
                End If
            Next i
            Select Case UCase(Me.Parametros)
                Case "TODO_ORDEN_BODEGA"
                    For k = 0 To UBound(mBodega) - 1
                            For i = 1 To mGnComp.CountIVKardex
                                Set ivk = mGnComp.IVKardex(i)
        
                                If ivk.codBodega = mBodega(k) Then
        
                                If i < mGnComp.CountIVKardex - 1 Then
                                    Set IvKaux = mGnComp.IVKardex(i + 1)
                                Else
                                    Set IvKaux = mGnComp.IVKardex(mGnComp.CountIVKardex)
                                End If
                                'Recupera el item correspondiente
                                codBodega = ivk.codBodega
                                nombreItem = "(Item no encontrado)"
                                Set iv = mGnComp.Empresa.RecuperaIVInventario(ivk.CodInventario)
                                If Not (iv Is Nothing) Then
                                   If iv.CodInventario <> "-" And iv.CodInventario <> "+" And Not iv.BandCambiaDescr Then
                                        nombreItem = iv.Descripcion
                                        mNoEsItemNota = True
                                    Else
                                        nombreItem = ivk.Nota
                                        If mprops.ImpValNota Then
                                            mNoEsItemNota = True
                                        Else
                                            mNoEsItemNota = False
                                        End If
                                    End If
                                End If
                                'Impresion
                              If Not ivk.bandImprimir Then  'AUC agregado 08/06/06 para que no imprima las recetas en caso del retro
                                        For j = 1 To Len(s)
                                            'Si es un comando
                                            If Mid$(s, j, 2) = "%(" Then
                                                cmd = Mid$(s, j + 2, InStr(j + 2, s, ")") - (j + 2))
                                                ProcesaComando cmd, mSpTxt
                                                j = j + Len(cmd) + 2
                                            'Si es una variable
                                            ElseIf Mid$(s, j, 2) = "$(" Then
                                                cmd = Mid$(s, j + 2, InStr(j + 2, s, ")") - (j + 2))
                                                ProcesaVariable cmd, i, nombreItem
                                                j = j + Len(cmd) + 2
                                            'si es otra linea
                                            ElseIf Asc(Mid$(s, j, 1)) = vbKeyReturn Then
                                                .PrintLine "", 1
                                                numLinea = numLinea + 1
                                                TotLineas = TotLineas + 1
                                            'Si no es un comando ni variable
                                            Else
                                                .PrintLine Mid$(s, j, 1)          'Manda un carácter a la impresora
                                            End If
                                        Next j
                                        If numLinea >= Me.Linea And Me.CambioPag = True Then
                                            If TotLineas < mGnComp.CountIVKardex Then   'Solamente si no ha impreso la totalidad de ítems
                                                .ImpSaltoPagina         'genera un  salto de pagina
                                                numLinea = 0
                                            End If
                                        ElseIf numLinea >= Me.Linea And Me.CambioPag = False And Me.Linea > 0 Then
                                            'Solamente deja de imprimir items
                                            Exit For
                                        End If
                                    End If
                                End If
                            Next i
                    Next k
                Case "XBODEGA"
                    RESP = MsgBox("Desea Imprimir Items de la Bodega: " & mBodega(0), vbYesNoCancel)
                    bandYaImprimio = False
                    For k = 0 To UBound(mBodega) - 1
                        If RESP = vbYes Then
                            bandYaImprimio = True
                            For i = 1 To mGnComp.CountIVKardex
                                Set ivk = mGnComp.IVKardex(i)
                                If ivk.codBodega = mBodega(k) Then
                                If i < mGnComp.CountIVKardex - 1 Then
                                    Set IvKaux = mGnComp.IVKardex(i + 1)
                                Else
                                    Set IvKaux = mGnComp.IVKardex(mGnComp.CountIVKardex)
                                End If
                                'Recupera el item correspondiente
                                codBodega = ivk.codBodega
                                nombreItem = "(Item no encontrado)"
                                Set iv = mGnComp.Empresa.RecuperaIVInventario(ivk.CodInventario)
                                If Not (iv Is Nothing) Then
                                   If iv.CodInventario <> "-" And iv.CodInventario <> "+" And Not iv.BandCambiaDescr Then
                                        nombreItem = iv.Descripcion
                                        mNoEsItemNota = True
                                    Else
                                        nombreItem = ivk.Nota
                                        If mprops.ImpValNota Then
                                            mNoEsItemNota = True
                                        Else
                                            mNoEsItemNota = False
                                        End If
                                    End If
                                End If
                                'Impresion
                              If Not ivk.bandImprimir Then  'AUC agregado 08/06/06 para que no imprima las recetas en caso del retro
                                        For j = 1 To Len(s)
                                            'Si es un comando
                                            If Mid$(s, j, 2) = "%(" Then
                                                cmd = Mid$(s, j + 2, InStr(j + 2, s, ")") - (j + 2))
                                                ProcesaComando cmd, mSpTxt
        
                                                j = j + Len(cmd) + 2
                                            'Si es una variable
                                            ElseIf Mid$(s, j, 2) = "$(" Then
                                                cmd = Mid$(s, j + 2, InStr(j + 2, s, ")") - (j + 2))
                                                ProcesaVariable cmd, i, nombreItem
                                                j = j + Len(cmd) + 2
                                            'si es otra linea
                                            ElseIf Asc(Mid$(s, j, 1)) = vbKeyReturn Then
                                                .PrintLine "", 1
                                                numLinea = numLinea + 1
                                                TotLineas = TotLineas + 1
                                            'Si no es un comando ni variable
                                            Else
                                                .PrintLine Mid$(s, j, 1)          'Manda un carácter a la impresora
                                            End If
                                        Next j
        
                                        If numLinea >= Me.Linea And Me.CambioPag = True Then
                                        ElseIf numLinea >= Me.Linea And Me.CambioPag = False And Me.Linea > 0 Then
                                            'Solamente deja de imprimir items
                                            Exit For
                                        End If
                                    End If
                                End If
                            Next i
                        End If
                            If k = UBound(mBodega) - 1 Then
                                numLinea = 0
                            Else
                                If TotLineas < mGnComp.CountIVKardex Then   'Solamente si no ha impreso la totalidad de ítems
                                    RESP = MsgBox("Desea Imprimir Items de la Bodega: " & mBodega(k + 1), vbYesNoCancel)
                                    If RESP = vbYes Then
                                        If bandYaImprimio Then
                                            .ImpSaltoPagina         'genera un  salto de pagina
                                            numLinea = 0
                                        End If
                                    End If
                                End If
                            End If
                        'End If
                        
                    Next k
                Case "ITEM_NO_CONTADO"
                    Set iv = mGnComp.Empresa.RecuperaIVInventario(mGnComp.IVKardex(1).CodInventario)
                    sql = " select codinventario from ivinventario"
                    sql = sql & " Where idgrupo1 = " & iv.IdGrupo(1)
                    sql = sql & " and idinventario not in("
                    sql = sql & " select idinventario from gncomprobante g inner join ivkardex i on g.transid=i.transid"
                    sql = sql & " where g.transid = " & mGnComp.TransId & ")"
                    
                    Set rsItemNoCont = mGnComp.Empresa.OpenRecordset(sql)
                    Set iv = Nothing
                
                    For k = 0 To rsItemNoCont.RecordCount - 1
                                Set ivk = mGnComp.IVKardex(1)
        
                                'Recupera el item correspondiente
                                codBodega = ivk.codBodega
        
                                nombreItem = "(Item no encontrado)"
                                Set iv = mGnComp.Empresa.RecuperaIVInventario(rsItemNoCont.Fields(0))
                                If Not (iv Is Nothing) Then
                                    If iv.CodInventario <> "-" And iv.CodInventario <> "+" And Not iv.BandCambiaDescr Then
                                        nombreItem = iv.Descripcion
                                        mNoEsItemNota = True
                                    Else
                                        nombreItem = ivk.Nota
                                        If mprops.ImpValNota Then
                                            mNoEsItemNota = True
                                        Else
                                            mNoEsItemNota = False
                                        End If
                                    End If
                                End If
                                'Impresion
                              If Not ivk.bandImprimir Then  'AUC agregado 08/06/06 para que no imprima las recetas en caso del retro
                                    For j = 1 To Len(s)
                                        'Si es un comando
                                        If Mid$(s, j, 2) = "%(" Then
                                            cmd = Mid$(s, j + 2, InStr(j + 2, s, ")") - (j + 2))
                                            ProcesaComando cmd, mSpTxt
                                            j = j + Len(cmd) + 2
                                        'Si es una variable
                                        ElseIf Mid$(s, j, 2) = "$(" Then
                                            cmd = Mid$(s, j + 2, InStr(j + 2, s, ")") - (j + 2))
                                            ProcesaVariableNoContado cmd, k + 1, iv, codBodega
                                            j = j + Len(cmd) + 2
                                        'si es otra linea
                                        ElseIf Asc(Mid$(s, j, 1)) = vbKeyReturn Then
                                            .PrintLine "", 1
                                            numLinea = numLinea + 1
                                            TotLineas = TotLineas + 1
                                        'Si no es un comando ni variable
                                        Else
                                            .PrintLine Mid$(s, j, 1)          'Manda un carácter a la impresora
                                        End If
                                    Next j
                                    If numLinea >= Me.Linea And Me.CambioPag = True Then
                                        If TotLineas < mGnComp.CountIVKardex Then   'Solamente si no ha impreso la totalidad de ítems
                                            .ImpSaltoPagina         'genera un  salto de pagina
                                            numLinea = 0
                                        End If
                                    ElseIf numLinea >= Me.Linea And Me.CambioPag = False And Me.Linea > 0 Then
                                        'Solamente deja de imprimir items
                                        Exit For
                                    End If
                                    End If
                            rsItemNoCont.MoveNext
                    Next k
                Case Else
                    v = Split(Me.Parametros, "=")
                    If v(0) = "SOLO_BODEGA" Then
                            k = 0
'                        For k = 0 To UBound(mBodega) - 1
                                For i = 1 To mGnComp.CountIVKardex
                                    Set ivk = mGnComp.IVKardex(i)
            
                                    If ivk.codBodega = v(1) Then
            
                                        If i < mGnComp.CountIVKardex - 1 Then
                                            Set IvKaux = mGnComp.IVKardex(i + 1)
                                        Else
                                            Set IvKaux = mGnComp.IVKardex(mGnComp.CountIVKardex)
                                        End If
                                        'Recupera el item correspondiente
                                        codBodega = ivk.codBodega
                                        nombreItem = "(Item no encontrado)"
                                        Set iv = mGnComp.Empresa.RecuperaIVInventario(ivk.CodInventario)
                                        If Not (iv Is Nothing) Then
                                           If iv.CodInventario <> "-" And iv.CodInventario <> "+" And Not iv.BandCambiaDescr Then
                                                nombreItem = iv.Descripcion
                                                mNoEsItemNota = True
                                            Else
                                                nombreItem = ivk.Nota
                                                If mprops.ImpValNota Then
                                                    mNoEsItemNota = True
                                                Else
                                                    mNoEsItemNota = False
                                                End If
                                            End If
                                        End If
                                    'Impresion
                                      If Not ivk.bandImprimir Then  'AUC agregado 08/06/06 para que no imprima las recetas en caso del retro
                                            For j = 1 To Len(s)
                                                'Si es un comando
                                                If Mid$(s, j, 2) = "%(" Then
                                                    cmd = Mid$(s, j + 2, InStr(j + 2, s, ")") - (j + 2))
                                                    ProcesaComando cmd, mSpTxt
                                                    j = j + Len(cmd) + 2
                                                'Si es una variable
                                                ElseIf Mid$(s, j, 2) = "$(" Then
                                                    cmd = Mid$(s, j + 2, InStr(j + 2, s, ")") - (j + 2))
                                                    ProcesaVariable cmd, i, nombreItem
                                                    j = j + Len(cmd) + 2
                                                'si es otra linea
                                                ElseIf Asc(Mid$(s, j, 1)) = vbKeyReturn Then
                                                    .PrintLine "", 1
                                                    numLinea = numLinea + 1
                                                    TotLineas = TotLineas + 1
                                                'Si no es un comando ni variable
                                                Else
                                                    .PrintLine Mid$(s, j, 1)          'Manda un carácter a la impresora
                                                End If
                                            Next j
                                            If numLinea >= Me.Linea And Me.CambioPag = True Then
                                                If TotLineas < mGnComp.CountIVKardex Then   'Solamente si no ha impreso la totalidad de ítems
                                                    .ImpSaltoPagina         'genera un  salto de pagina
                                                    numLinea = 0
                                                End If
                                            ElseIf numLinea >= Me.Linea And Me.CambioPag = False And Me.Linea > 0 Then
                                                'Solamente deja de imprimir items
                                                Exit For
                                            End If
                                        End If
                                    End If
                                Next i
'                        Next k
                End If
            End Select
        End If
        If numLinea < Me.Linea And Me.Linea > 0 Then
            .PrintLine "", Me.Linea - numLinea
        End If
    End With
    Exit Sub
ErrTrap:
    Err.Raise ERR_NOIMPRIME, App.EXEName, "Seccion Items " & Err.Description
End Sub

Private Sub ProcesaVariable(cad As String, i As Long, nombreItem As String)
    Dim lon As Integer, v As Variant, Texto As String
    Dim deci  As Integer, fmt As String, ivg As IvGrupo, pc As pcProvCli
    Dim uni As IVUnidad
    Dim IVISO As IVInventario
    Dim ivs As IVNumSerie
    Dim sql As String, rsiso  As Recordset, cu As Currency
    Dim iniCad As Integer, j As Long
    Dim strCad As String
    Dim numFil As Currency
    Dim contFil As Integer
    Dim lim As Currency
    'variables disponibles para  la seccion de Items
    With mSpTxt
        v = Split(cad, ";")
        If IsEmpty(v) Then Exit Sub
        fmt = gfmt
        If UBound(v, 1) >= 1 Then lon = v(1)
        If UBound(v, 1) >= 2 Then fmt = generafmt(CStr(v(2)), CStr(v(0)))      'Subrutinapublica
        Select Case v(0)
            Case "NUMLIN":  .PrintLine .Rellenar(i, lon, False)
            Case "CODITEM": .PrintLine .Rellenar(ivk.CodInventario, lon, True)
            Case "CODALTITEM": .PrintLine .Rellenar(iv.CodAlterno1, lon, True)
            Case "CODALT2ITEM": .PrintLine .Rellenar(iv.CodAlterno2, lon, True)
            Case "DESCITEM": .PrintLine .Rellenar(nombreItem, lon, True)
            Case "DESCITEMVL":
                numFil = Len(nombreItem) / lon
                numFil = Ceiling(numFil)
                contFil = 1
                    For j = 1 To numFil
                        strCad = strCad & Mid(nombreItem, contFil, lon) & vbCrLf & "  "
                        contFil = contFil + lon
                    Next
                    strCad = Left(strCad, Len(strCad) - 3)
                    .PrintLine .Rellenar(strCad, Len(strCad), True)
                    strCad = ""
            Case "DESCITEMIVA":
                If ivk.IVA = 0 Then
                    .PrintLine .Rellenar(nombreItem, lon, True)
                Else
                    .PrintLine .Rellenar("*" & nombreItem, lon, True)
                End If
            Case "DESCITEMNOIVA":
                If ivk.IVA = 0 Then
                    .PrintLine .Rellenar("*" & nombreItem, lon, True)
                Else
                    .PrintLine .Rellenar(nombreItem, lon, True)
                End If
            Case "DESCITEMIVAPR":
                If ivk.IVA = 0 Then
                    If ivk.idpadre = 0 Then
                        .PrintLine .Rellenar(nombreItem, lon, True)
                    Else
                        .PrintLine .Rellenar("++ " & nombreItem, lon, True)
                    End If
                Else
                    If ivk.idpadre = 0 Then
                        .PrintLine .Rellenar("*" & nombreItem, lon, True)
                    Else
                        .PrintLine .Rellenar("* ++ " & nombreItem, lon, True)
                    End If
                End If
                
            '.PrintLine .Rellenar(IIf(ivk.IVA = 0, nombreItem, "*" & nombreItem), lon, True)
            Case "DESCITEMPROMO": .PrintLine .Rellenar(IIf(ivk.idpadre = 0, nombreItem, "++ " & nombreItem), lon, True)
            Case "DESCITEMIVAALIN": .PrintLine .Rellenar(IIf(ivk.IVA = 0, "  " & nombreItem, "* " & nombreItem), lon, True)
            Case "CODBOD": .PrintLine .Rellenar(ivk.codBodega, lon, True)
            Case "CANT":
                If mNoEsItemNota Then
                    If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                        If mGnComp.GNTrans.IVTipoTrans = "E" Then
                            If ivk.CantidaddOU < 0 Then
                                .PrintLine .Rellenar(Format(Abs(ivk.CantidaddOU), fmt), lon, False)
                            Else
                                'cuando existedevolucion en el mismo item
                                .PrintLine .Rellenar(Format((ivk.CantidaddOU) * -1, fmt), lon, False)
                            End If
                        Else
                            .PrintLine .Rellenar(Format(Abs(ivk.CantidaddOU), fmt), lon, False)
                        End If
                    Else
                        If mGnComp.GNTrans.IVTipoTrans = "E" Then
                            If ivk.Cantidad < 0 Then
                                .PrintLine .Rellenar(Format(Abs(ivk.Cantidad), fmt), lon, False)
                            Else
                                'cuando existedevolucion en el mismo item
                                .PrintLine .Rellenar(Format((ivk.Cantidad) * -1, fmt), lon, False)
                            End If
                        Else
                            .PrintLine .Rellenar(Format(Abs(ivk.Cantidad), fmt), lon, False)
                        End If
                    End If
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            
            Case "CANTSGN":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(ivk.Cantidad, fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "UNIDAD":
                .PrintLine .Rellenar(iv.Unidad, lon, True)
            Case "CU":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(ivk.Costo, fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "CT":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(Abs(ivk.CostoTotal), fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "CTSGN":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(ivk.CostoTotal, fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "CUR":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(ivk.CostoReal, fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "CTR":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(Abs(ivk.CostoRealTotal), fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "CTRSGN":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(Abs(ivk.CostoRealTotal), fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PU":
                If mNoEsItemNota Then
                    If mGnComp.GNTrans.IVTipoTrans = "E" Then
                        If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                            If ivk.CantidaddOU < 0 Then
                                    .PrintLine .Rellenar(Format(Abs(ivk.PrecioDou), fmt), lon, False)
                            Else
                                    .PrintLine .Rellenar(Format(ivk.PrecioDou, fmt), lon, False)
                            End If
                        Else
                            If ivk.Cantidad < 0 Then
                                    .PrintLine .Rellenar(Format(Abs(ivk.Precio), fmt), lon, False)
                            Else
                                    .PrintLine .Rellenar(Format(ivk.Precio, fmt), lon, False)
                            End If
                        End If
                    Else
                        If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                            .PrintLine .Rellenar(Format(Abs(ivk.PrecioDou), fmt), lon, False)
                        Else
                            .PrintLine .Rellenar(Format(Abs(ivk.Precio), fmt), lon, False)
                        End If
                    End If
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
                Case "PUND":
                If mNoEsItemNota Then
                    If mGnComp.GNTrans.IVTipoTrans = "E" Then
                        If ivk.Cantidad < 0 Then
                            .PrintLine .Rellenar(Format(Abs(ivk.PrecioND), fmt), lon, False)
                        Else
                            .PrintLine .Rellenar(Format(ivk.PrecioND, fmt), lon, False)
                        End If
                    Else
                        .PrintLine .Rellenar(Format(Abs(ivk.PrecioND), fmt), lon, False)
                    End If
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If

            Case "PT":
                If mNoEsItemNota Then
                    If mGnComp.GNTrans.IVTipoTrans = "E" Then
                        If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                            If ivk.CantidaddOU < 0 Then
                                .PrintLine .Rellenar(Format(Abs(ivk.PrecioTotalDou), fmt), lon, False)
                            Else
                                .PrintLine .Rellenar(Format((ivk.PrecioTotalDou) * -1, fmt), lon, False)
                            End If
                        Else
                            If ivk.Cantidad < 0 Then
                                .PrintLine .Rellenar(Format(Abs(ivk.PrecioTotal), fmt), lon, False)
                            Else
                                .PrintLine .Rellenar(Format((ivk.PrecioTotal) * -1, fmt), lon, False)
                            End If
                        End If
                    Else
                        If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                            .PrintLine .Rellenar(Format(Abs(ivk.PrecioTotalDou), fmt), lon, False)
                        Else
                            .PrintLine .Rellenar(Format(Abs(ivk.PrecioTotal), fmt), lon, False)
                        End If
                    End If
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PUNIT+IVA":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format((Abs(CDbl(ivk.Precio)) + (Abs(ivk.IVA) * Abs(CDbl(ivk.Precio)))), fmt), lon, False) '  jeaa 17/09/03 precio total unitario + IVA
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PU+IVA":
                If mNoEsItemNota Then
                    If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                        .PrintLine .Rellenar(Format((CDbl(ivk.PrecioRealDou) + (ivk.IVA * Abs(CDbl(ivk.PrecioRealDou)))), fmt), lon, False)
                    Else
                        .PrintLine .Rellenar(Format((CDbl(ivk.PrecioReal) + (ivk.IVA * Abs(CDbl(ivk.PrecioReal)))), fmt), lon, False)
                    End If
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PTOTAL+IVA":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(((Abs(CDbl(ivk.Precio)) + Abs(ivk.IVA) * Abs(CDbl(ivk.Precio)))) * Abs(ivk.Cantidad), fmt), lon, False) '  jeaa 17/09/03 precio total  + IVA
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PT+IVA":
                If mNoEsItemNota Then
                    If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                        .PrintLine .Rellenar(Format((CDbl(ivk.PrecioRealDou) + (ivk.IVA * Abs(CDbl(ivk.PrecioRealDou)))) * Abs(ivk.CantidaddOU), fmt), lon, False)
                    Else
                        .PrintLine .Rellenar(Format((CDbl(ivk.PrecioReal) + (ivk.IVA * Abs(CDbl(ivk.PrecioReal)))) * Abs(ivk.Cantidad), fmt), lon, False)
                    End If
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PTSGN":
                If mNoEsItemNota Then
                    If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                        .PrintLine .Rellenar(Format(ivk.PrecioTotalDou, fmt), lon, False)
                    Else
                        .PrintLine .Rellenar(Format(ivk.PrecioTotal, fmt), lon, False)
                    End If
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PUR":
                If mNoEsItemNota Then
                    If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                        .PrintLine .Rellenar(Format(ivk.PrecioRealDou, fmt), lon, False)
                    Else
                        .PrintLine .Rellenar(Format(ivk.PrecioReal, fmt), lon, False)
                    End If
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PTR":
                If mNoEsItemNota Then
                    If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                        .PrintLine .Rellenar(Format(Abs(ivk.PrecioRealTotalDou), fmt), lon, False)
                    Else
                        .PrintLine .Rellenar(Format(Abs(ivk.PrecioRealTotal), fmt), lon, False)
                    End If
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PTRSGN":
                If mNoEsItemNota Then
                    If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                        .PrintLine .Rellenar(Format(Abs(ivk.PrecioRealTotalDou), fmt), lon, False)
                    Else
                        .PrintLine .Rellenar(Format(Abs(ivk.PrecioRealTotal), fmt), lon, False)
                    End If
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PORDESC": .PrintLine .Rellenar(Format(ivk.Descuento * 100, fmt), lon, False)
            Case "PORIVA": .PrintLine .Rellenar(Format(ivk.IVA * 100, fmt), lon, False)
            Case "PORDESP": .PrintLine .Rellenar(Format(iv.PorDesperdicio * 100, fmt), lon, False)
            Case "VALIVA":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(ivk.IVA * Abs(ivk.PrecioRealTotal), fmt), lon, False)    'revisar
                                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "BANDIVA":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(IIf(iv.BandIva, "S", "N"), fmt), lon, False)  'revisar
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            
            Case "PU2":
                If mNoEsItemNota Then
                    If iv.Precio(2) <> 0 Then
                        .PrintLine .Rellenar(Format(iv.Precio(2), fmt), lon, True)   'Modificado 19/10/2001 Diego
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "DESCDETITEM":  .PrintLine .Rellenar(iv.DescripcionDetalle, lon, True)   '**** jeaa 01-12-2003
            Case "EXISTACTUAL": .PrintLine .Rellenar(Format(Abs(iv.Existencia(ivk.codBodega)), fmt), lon, False) '**** jeaa 18-03-2004
            Case "EXISTANTES": .PrintLine .Rellenar(Format(Abs(iv.Existencia(ivk.codBodega) - Abs(ivk.Cantidad)), fmt), lon, False) '**** jeaa 18-03-2004
            
            '------------------------------------------------------------------------
            '**** Agregado. 18/Ago/2004. Angel. Para sacar informaciòn de los grupos
            Case "CODGRUPO1": .PrintLine .Rellenar(iv.codGrupo(1), lon, True)
            Case "DESCGRUPO1":
                If Len(iv.codGrupo(1)) > 0 Then
                    Set ivg = mGnComp.Empresa.RecuperaIVGrupo(1, iv.codGrupo(1))
                    If Not (ivg Is Nothing) Then
                        .PrintLine .Rellenar(ivg.Descripcion, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                Else
                    .PrintLine .Rellenar("", lon, True)
                End If
            Case "CODGRUPO2": .PrintLine .Rellenar(iv.codGrupo(2), lon, True)
            Case "DESCGRUPO2":
                If Len(iv.codGrupo(2)) > 0 Then
                    Set ivg = mGnComp.Empresa.RecuperaIVGrupo(2, iv.codGrupo(2))
                    If Not (ivg Is Nothing) Then
                        .PrintLine .Rellenar(ivg.Descripcion, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                Else
                    .PrintLine .Rellenar("", lon, True)
                End If
            Case "CODGRUPO3": .PrintLine .Rellenar(iv.codGrupo(3), lon, True)
            Case "DESCGRUPO3":
                If Len(iv.codGrupo(3)) > 0 Then
                    Set ivg = mGnComp.Empresa.RecuperaIVGrupo(3, iv.codGrupo(3))
                    If Not (ivg Is Nothing) Then
                        .PrintLine .Rellenar(ivg.Descripcion, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                Else
                    .PrintLine .Rellenar("", lon, True)
                End If
            Case "CODGRUPO4": .PrintLine .Rellenar(iv.codGrupo(4), lon, True)
            Case "DESCGRUPO4":
                If Len(iv.codGrupo(4)) > 0 Then
                    Set ivg = mGnComp.Empresa.RecuperaIVGrupo(4, iv.codGrupo(4))
                    If Not (ivg Is Nothing) Then
                        .PrintLine .Rellenar(ivg.Descripcion, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                Else
                    .PrintLine .Rellenar("", lon, True)
                End If
            Case "CODGRUPO5": .PrintLine .Rellenar(iv.codGrupo(5), lon, True)
            Case "DESCGRUPO5":
                If Len(iv.codGrupo(5)) > 0 Then
                    Set ivg = mGnComp.Empresa.RecuperaIVGrupo(5, iv.codGrupo(5))
                    If Not (ivg Is Nothing) Then
                        .PrintLine .Rellenar(ivg.Descripcion, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                Else
                    .PrintLine .Rellenar("", lon, True)
                End If
            'JEAA 31/03/2005
            Case "PU+IVA+REC":
                If mNoEsItemNota Then
                    If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                        .PrintLine .Rellenar(Format((CDbl(ivk.PrecioRealDou) + (ivk.IVA * Abs(CDbl(ivk.PrecioRealDou))) + (ivk.ValorRecargoItem)), fmt), lon, False)
                    Else
                        .PrintLine .Rellenar(Format((CDbl(ivk.PrecioReal) + (ivk.IVA * Abs(CDbl(ivk.PrecioReal))) + (ivk.ValorRecargoItem)), fmt), lon, False)
                    End If
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PT+IVA+REC":
                If mNoEsItemNota Then
                    If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                        .PrintLine .Rellenar(Format((CDbl(ivk.PrecioRealDou) + (ivk.IVA * Abs(CDbl(ivk.PrecioRealDou))) + (ivk.ValorRecargoItem)) * Abs(ivk.CantidaddOU), fmt), lon, False)
                    Else
                        .PrintLine .Rellenar(Format((CDbl(ivk.PrecioReal) + (ivk.IVA * Abs(CDbl(ivk.PrecioReal))) + (ivk.ValorRecargoItem)) * Abs(ivk.Cantidad), fmt), lon, False)
                    End If
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PU+REC":
                If mNoEsItemNota Then
                    If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                         .PrintLine .Rellenar(Format((CDbl(ivk.PrecioRealDou) + (ivk.ValorRecargoItem)), fmt), lon, False)
                    Else
                        .PrintLine .Rellenar(Format((CDbl(ivk.PrecioReal) + (ivk.ValorRecargoItem)), fmt), lon, False)
                    End If
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            
            Case "PT+REC":
                If mNoEsItemNota Then
                    If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                        .PrintLine .Rellenar(Format((CDbl(ivk.PrecioRealDou) + (ivk.ValorRecargoItem)) * Abs(ivk.CantidaddOU), fmt), lon, False)
                    Else
                        .PrintLine .Rellenar(Format((CDbl(ivk.PrecioReal) + (ivk.ValorRecargoItem)) * Abs(ivk.Cantidad), fmt), lon, False)
                    End If
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "OBSERVA":
                If iv.CodInventario <> "-" And iv.CodInventario <> "+" And Not iv.BandCambiaDescr Then
                    If mNoEsItemNota Then
                            'si existe nota imprime lo que esta alli
                            If Len(ivk.Nota) > 0 Then
                                    .PrintLine .Rellenar(ivk.Nota, lon, True)
                            Else
                                    .PrintLine .Rellenar(iv.Observacion, lon, True)
                            End If
                    Else
                        .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                    End If
                End If
            'JEAA 23/09/2005
            Case "TENTREGA":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(ivk.TiempoEntrega, lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            'JEAA 02/01/06
            Case "CODUNIDAD"
                    .PrintLine .Rellenar(iv.CodUnidad, lon, True)
            Case "DESCUNIDAD":
                    Set uni = mGnComp.Empresa.RecuperaUnidad(iv.IdUnidad)
                    If Not (uni Is Nothing) Then
                        .PrintLine .Rellenar(uni.Descripcion, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                    Set uni = Nothing
            Case "CODUCONTEO"
                    .PrintLine .Rellenar(iv.CodUnidadConteo, lon, True)
            Case "DESCUCONTEO":
                    Set uni = mGnComp.Empresa.RecuperaUnidad(iv.IdUnidadConteo)
                    If Not (uni Is Nothing) Then
                        .PrintLine .Rellenar(uni.Descripcion, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                    Set uni = Nothing
            Case "DESCITEMIVAPREP":
                If iv.Tipo = Preparacion Then
                    .PrintLine .Rellenar(IIf(ivk.IVA = 0, nombreItem, "*" & nombreItem), lon, True)
                ElseIf iv.Tipo = Normal Then
                    .PrintLine .Rellenar(IIf(ivk.IVA = 0, nombreItem, "    *" & nombreItem), lon, True)
                End If
            Case "DESCITEMPREP":
                If iv.Tipo = Preparacion Then
                    .PrintLine .Rellenar(nombreItem, lon, True)
                ElseIf iv.Tipo = Normal Then
                    .PrintLine .Rellenar("    " & nombreItem, lon, True)
                End If
            Case "PORICE": .PrintLine .Rellenar(Format(iv.PorcentajeICE * 100, fmt), lon, False)
            Case "PORDESP": .PrintLine .Rellenar(Format(iv.PorDesperdicio * 100, fmt), lon, False)
                    'AUC 16/07/07 agregado valor de descuento
            Case "NUMPIEZAS": 'AUC agregado Numpiezas 15/09/06 para la casa del disfraz
                    If iv.Tipo = Preparacion And Len(ivk.Nota) = 0 Then
                        .PrintLine .Rellenar(Format(Abs(iv.RecuperaNumPiezas(iv.CodInventario, mGnComp.CodTrans, mGnComp.NumTrans)), fmt), lon, False)
                    ElseIf iv.Tipo = Preparacion And Len(ivk.Nota) > 0 Then
                        .PrintLine .Rellenar(ivk.Nota, lon, True)
                    End If
            'AUC 16/07/07 agregado valor de descuento
            Case "VALDESC": .PrintLine .Rellenar(Format(Abs(ivk.ValorDescuento), fmt), lon, False)
                    
            'Case "VALDESC":  .PrintLine .Rellenar(Format(Abs(ivk.ValorDescuento), fmt), lon, False)
            'AUC 17/02/2014 PARA FABRICA BRAVO
            Case "P1ITEM": .PrintLine .Rellenar(Format(Abs(ivk.P1ITEM), fmt), lon, False)
                
            
            Case "PORDESCREFP1": .PrintLine .Rellenar(Format(ivk.DescuentoRefP1 * 100, fmt), lon, False) + "%"
            Case "VALDESCREFP1": .PrintLine .Rellenar(Format(ivk.ValorDescuentoRefP1, fmt), lon, False)
            
                    'AUC 28/09/07 agregado para imprimir la unidad relacion
            Case "CANTUNICONT":
                .PrintLine .Rellenar(Format((Abs(ivk.Cantidad) - Abs(ivk.Cantidad Mod iv.CantReluni)) / iv.CantReluni, fmt), lon, False)
            Case "RESTOUNICONT":
                .PrintLine .Rellenar(Format(Abs(ivk.Cantidad Mod iv.CantReluni), fmt), lon, False)
                    'AUC 16/07/07 agregado valor de descuento
            'Case "VALCDESC":  .PrintLine .Rellenar(Format(Abs(ivk.ValorCDescuento), fmt), lon, False)
             Case "FECHADEV":
                .PrintLine .Rellenar(Format(Abs(ivk.FechaDevol), fmt), lon, False)
            Case "NUMDIAS":
                .PrintLine .Rellenar(Format(Abs(ivk.NumDias), fmt), lon, False)
            Case "PESONETOUNIT":
                .PrintLine .Rellenar(Format(iv.PesoNeto, fmt), lon, False)   'Modificado 19/10/2001 Diego
            Case "PESOBRUTOUNIT":
                .PrintLine .Rellenar(Format(iv.PesoBruto, fmt), lon, False)   'Modificado 19/10/2001 Diego
            Case "PESONETOTOT":
                .PrintLine .Rellenar(Format(iv.PesoNeto * Abs(ivk.Cantidad), fmt), lon, False) 'Modificado 19/10/2001 Diego
            Case "PESOBRUTOTOT":
                .PrintLine .Rellenar(Format(iv.PesoBruto * Abs(ivk.Cantidad), fmt), lon, False) 'Modificado 19/10/2001 Diego
            Case "CODUNIDADPESO":
                    .PrintLine .Rellenar(iv.CodUnidadPeso, lon, True)
        'ISOLLANTA
            Case "CODMARCA":
                    .PrintLine .Rellenar(ivk.CodMarca, lon, True)
            Case "DESCMARCA":
                Set IVISO = mGnComp.Empresa.RecuperaIVInventario(ivk.CodMarca)
                If Not IVISO Is Nothing Then
                    .PrintLine .Rellenar(IVISO.Descripcion, lon, True)
                End If
                Set IVISO = Nothing
            Case "CODTAMANIO":
                    .PrintLine .Rellenar(ivk.CodTamanio, lon, True)
            Case "DESCTAMANIO":
                Set IVISO = mGnComp.Empresa.RecuperaIVInventario(ivk.CodTamanio)
                If Not IVISO Is Nothing Then
                    .PrintLine .Rellenar(IVISO.Descripcion, lon, True)
                End If
                Set IVISO = Nothing
            Case "CODTRABAJO":
                    .PrintLine .Rellenar(ivk.CodTrabajo, lon, True)
            Case "DESCTRABAJO":
                Set IVISO = mGnComp.Empresa.RecuperaIVInventario(ivk.CodTrabajo)
                If Not IVISO Is Nothing Then
                    .PrintLine .Rellenar(IVISO.Descripcion, lon, True)
                End If
                Set IVISO = Nothing
            Case "CODPROCESADO":
                    .PrintLine .Rellenar(ivk.CodProcesado, lon, True)
            Case "DESCPROCESADO":
                Set IVISO = mGnComp.Empresa.RecuperaIVInventario(ivk.CodProcesado)
                If Not IVISO Is Nothing Then
                    .PrintLine .Rellenar(IVISO.Descripcion, lon, True)
                End If
                Set IVISO = Nothing
            
            Case "TIKET":
                    .PrintLine .Rellenar(ivk.TiempoEntrega, lon, False)
            Case "DISENIO":
                    .PrintLine .Rellenar(ivk.DisenioOri, lon, True)
            Case "NUMSERIE":
                    .PrintLine .Rellenar(ivk.NumSerie, lon, True)
            Case "DISENIORECLAMO":
                    .PrintLine .Rellenar(ivk.TiempoEntrega, lon, True)
            Case "RADIAL":
                    .PrintLine .Rellenar(ivk.Radial, lon, True)
            Case "ORIGINAL":
                    .PrintLine .Rellenar(ivk.Original, lon, True)
            Case "ORDEN":
                    If Len(ivk.TiempoEntrega) > 0 Then
                        .PrintLine .Rellenar(mGnComp.Empresa.RecuperaOrdenISO(ivk.TiempoEntrega), lon, True)
                    End If
            Case "NUMINGRESO":
                    .PrintLine .Rellenar(ivk.NumIngreso, lon, True)
            Case "MARCAPRECIOANT":
                If ivk.NumDias = 1 Then
                    .PrintLine .Rellenar("PA", lon, True)
                End If
            Case "NOMCLICAR":
                Set pc = mGnComp.Empresa.RecuperaPCProvCli(ivk.CodCliente)
                If Not pc Is Nothing Then
                    .PrintLine .Rellenar(pc.Nombre, lon, True)
                End If
                Set pc = Nothing
            Case "BANDDESC":
                If ivk.Descuento <> 0 Then
                    If UBound(v) = 2 Then
                        Texto = v(2)
                    Else
                        Texto = "+"
                    End If
                    .PrintLine .Rellenar(Texto, lon, True)
                End If
                'AUC Fabrica Bravo
            Case "DESCITEM+SERIE":
                    If iv.bandSerie Then
                        Set ivs = mGnComp.Empresa.RecuperaIVSerie(Val(ivk.TiempoEntrega))
                        .PrintLine .Rellenar(iv.Descripcion & " " & ivs.Campo1, lon, True)
                    Else
                        .PrintLine .Rellenar(iv.Descripcion, lon, True)
                    End If
                    Set ivs = Nothing
            'AUC reutilizacon campos para lacto
            Case "PH"
                    .PrintLine .Rellenar(Format(Abs(ivk.Arancel), fmt), lon, False)
            Case "GRASA"
                    .PrintLine .Rellenar(Format(Abs(ivk.ICE), fmt), lon, False)
            Case "PROTEINA"
                    .PrintLine .Rellenar(Format(Abs(ivk.FODIN), fmt), lon, False)
            Case "AGUA"
                    .PrintLine .Rellenar(Format(Abs(ivk.Comision), fmt), lon, False)
            Case "QUIO"
                    .PrintLine .Rellenar(ivk.NumDias, lon, False) 'UTILIZAR NUMDIAS
            Case "REDUC"
                    If Len(ivk.TiempoEntrega) > 0 Then
                        .PrintLine .Rellenar(Format(Abs(ivk.TiempoEntrega), fmt), lon, False)
                    Else
                        .PrintLine .Rellenar(Format(0, fmt), lon, False)
                    End If
            Case "MERMA"
                    .PrintLine .Rellenar(Format(Abs(ivk.DescuentoOriginal * 100), fmt), lon, False)
            Case "VALMERMA"
                    .PrintLine .Rellenar(Format(Abs(ivk.Cantidad * ivk.DescuentoOriginal), fmt), lon, False)
            Case "CTM"
                    .PrintLine .Rellenar(Format(Abs(ivk.Cantidad - (ivk.Cantidad * ivk.DescuentoOriginal)), fmt), lon, False)
            Case "CANTMERMA"
                    .PrintLine .Rellenar(Format(Abs(ivk.Cantidad * (mGnComp.Merma / 100)), fmt), lon, False)
           Case "CANTOTALMERMA"
                    .PrintLine .Rellenar(Format(Abs(ivk.Cantidad - (ivk.Cantidad * (mGnComp.Merma / 100))), fmt), lon, False)
            Case "CANTCONTEO":
                If mNoEsItemNota Then
                    If mGnComp.GNTrans.IVTipoTrans = "E" Then
                        If ivk.Cantidad < 0 Then
                            Set IVISO = mGnComp.Empresa.RecuperaIVInventario(ivk.CodInventario)
                            .PrintLine .Rellenar(Format(Abs(ivk.Cantidad * IVISO.CantReluni), fmt), lon, False)
                        Else
                            'cuando existedevolucion en el mismo item
                            .PrintLine .Rellenar(Format((ivk.Cantidad) * -1, fmt), lon, False)
                        End If
                    Else
                        .PrintLine .Rellenar(Format(Abs(ivk.Cantidad), fmt), lon, False)
                    End If
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "CANTCONTEOUNIDAD":
                If mNoEsItemNota Then
                    If mGnComp.GNTrans.IVTipoTrans = "E" Then
                        If ivk.Cantidad < 0 Then
                            Set IVISO = mGnComp.Empresa.RecuperaIVInventario(ivk.CodInventario)
                            .PrintLine .Rellenar(Format(Abs(ivk.Cantidad * IVISO.CantReluniCont), fmt), lon, False)
                        Else
                            'cuando existedevolucion en el mismo item
                            .PrintLine .Rellenar(Format((ivk.Cantidad) * -1, fmt), lon, False)
                        End If
                    Else
                        .PrintLine .Rellenar(Format(Abs(ivk.Cantidad), fmt), lon, False)
                    End If
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "DATOSTECNICOS" 'DATOS TECNICOS
                .PrintLine .Rellenar(iv.DescripcionDetalle, lon, True)
            Case "IVSCAMPO1":
                    If iv.bandSerie Then
                        'Set ivs = mGnComp.Empresa.RecuperaIVSerie(Val(ivk.TiempoEntrega))
                        Set ivs = mGnComp.Empresa.RecuperaIVSxidIvKardex(ivk.Id)
                        .PrintLine .Rellenar(ivs.Campo1, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                    Set ivs = Nothing
            Case "IVSCAMPO2":
                    If iv.bandSerie Then
                        'Set ivs = mGnComp.Empresa.RecuperaIVSerie(Val(ivk.TiempoEntrega))
                        Set ivs = mGnComp.Empresa.RecuperaIVSxidIvKardex(ivk.Id)
                        .PrintLine .Rellenar(ivs.campo2, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                    Set ivs = Nothing
            Case "IVSCAMPO3":
                    If iv.bandSerie Then
                        'Set ivs = mGnComp.Empresa.RecuperaIVSerie(Val(ivk.TiempoEntrega))
                        Set ivs = mGnComp.Empresa.RecuperaIVSxidIvKardex(ivk.Id)
                        .PrintLine .Rellenar(ivs.Campo3, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                    Set ivs = Nothing
            Case "IVSCAMPO4":
                    If iv.bandSerie Then
                        'Set ivs = mGnComp.Empresa.RecuperaIVSerie(Val(ivk.TiempoEntrega))
                        Set ivs = mGnComp.Empresa.RecuperaIVSxidIvKardex(ivk.Id)
                        .PrintLine .Rellenar(ivs.Campo4, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                    Set ivs = Nothing
            Case "IVSCAMPO5":
                    If iv.bandSerie Then
                        'Set ivs = mGnComp.Empresa.RecuperaIVSerie(Val(ivk.TiempoEntrega))
                        Set ivs = mGnComp.Empresa.RecuperaIVSxidIvKardex(ivk.Id)
                        .PrintLine .Rellenar(ivs.Campo5, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                    Set ivs = Nothing
            Case "IVSFECHACRE":
                    If iv.bandSerie Then
                        'Set ivs = mGnComp.Empresa.RecuperaIVSerie(Val(ivk.TiempoEntrega))
                        Set ivs = mGnComp.Empresa.RecuperaIVSxidIvKardex(ivk.Id)
                        .PrintLine .Rellenar(ivs.FechaCreacion, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                    Set ivs = Nothing
            Case "CANTCONV": 'Cantidad conversion
                    If mGnComp.GNTrans.IVTipoTrans = "E" Then
                        If ivk.CantidadConv < 0 Then
                            .PrintLine .Rellenar(Format(Abs(ivk.CantidadConv), fmt), lon, False)
                        Else
                            'cuando existedevolucion en el mismo item
                            .PrintLine .Rellenar(Format((ivk.CantidadConv) * -1, fmt), lon, False)
                        End If
                    Else
                        .PrintLine .Rellenar(Format(Abs(ivk.CantidadConv), fmt), lon, False)
                    End If
            Case "UCONV": 'Cantidad conversion
                    .PrintLine .Rellenar(ivk.UnidadConv, lon, True)
                    
            Case "CUULTIMACP"
                            sql = "select top 1 isnull(costorealtotal/cantidad,0) as cu"
                            sql = sql & " from gncomprobante g inner join ivkardex i"
                            sql = sql & " inner join IVInventario ivi on i.IdInventario = ivi.idinventario on g.transid=i.transid"
                            sql = sql & " Where Estado <> 3"
                            sql = sql & " and codinventario='" & ivk.CodInventario & "'"
                            sql = sql & " and codtrans in ('cp')"
                            sql = sql & " and g.transid <> " & mGnComp.TransId
                            sql = sql & " order by fechatrans desc, orden desc"
                           Set rsiso = mGnComp.Empresa.OpenRecordset(sql)
                            If Not rsiso.EOF Then
                                .PrintLine .Rellenar(Format(Abs(rsiso.Fields("cu")), fmt), lon, False)
                            Else
                                .PrintLine .Rellenar(Format(0, fmt), lon, False)
                            End If
                            rsiso.Close
                            Set rsiso = Nothing
                Case "FULTIMACP"
                            sql = "select top 1 Fechatrans "
                            sql = sql & " from gncomprobante g inner join ivkardex i"
                            sql = sql & " inner join IVInventario ivi on i.IdInventario = ivi.idinventario on g.transid=i.transid"
                            sql = sql & " Where Estado <> 3"
                            sql = sql & " and codinventario='" & ivk.CodInventario & "'"
                            sql = sql & " and codtrans in ('cp')"
                            sql = sql & " and g.transid <> " & mGnComp.TransId
                            sql = sql & " order by fechatrans desc, orden desc"
                           Set rsiso = mGnComp.Empresa.OpenRecordset(sql)
                            If Not rsiso.EOF Then
                                .PrintLine .Rellenar(Format(Abs(rsiso.Fields("Fechatrans")), fmt), lon, False)
                            Else
                                .PrintLine .Rellenar("ITEM NUEVO", lon, True)
                            End If
                            rsiso.Close
                            Set rsiso = Nothing
                Case "PORULTIMCP"
            
                            sql = "select top 1 costorealtotal/cantidad as cu"
                            sql = sql & " from gncomprobante g inner join ivkardex i"
                            sql = sql & " inner join IVInventario ivi on i.IdInventario = ivi.idinventario on g.transid=i.transid"
                            sql = sql & " Where Estado <> 3"
                            sql = sql & " and codinventario='" & ivk.CodInventario & "'"
                            sql = sql & " and codtrans in ('cp')"
                            sql = sql & " and g.transid <> " & mGnComp.TransId
                            sql = sql & " order by fechatrans desc, orden desc"
                            Set rsiso = mGnComp.Empresa.OpenRecordset(sql)
                            cu = 0
                            If Not rsiso.EOF Then
                                cu = rsiso.Fields("cu")
                            End If
                            If cu <> 0 Then
                                .PrintLine .Rellenar(Format((((ivk.Costo / Abs(rsiso!cu)) - 1) * 100), fmt), lon, False)
                            Else
                                .PrintLine .Rellenar(Format(0, fmt), lon, False)
                            End If
                Case "UTILVTAP1"
                        Set IVISO = mGnComp.Empresa.RecuperaIVInventarioQuick(ivk.CodInventario)
                        .PrintLine .Rellenar(Format((1 - (ivk.CostoReal / IVISO.Precio(1))) * 100, fmt), lon, False)
                        Set IVISO = Nothing
        End Select
        If Not (ivg Is Nothing) Then Set ivg = Nothing '***Agregado. 18/ago/2004. Angel
    End With
End Sub

Public Property Set GNC(ByVal gc As Sii4A32.GNComprobante)
    Set mGnComp = gc
End Property
Public Property Set Sptxt(ByVal Sptxt As SiiPrint.PrintTxt)
    Set mSpTxt = Sptxt
End Property


Friend Property Set PrintTransMain(ByVal newObj As PrintTrans)
    Set mprops.objMain = newObj
End Property

Public Property Get PrintTransMain() As PrintTrans
    Set PrintTransMain = mprops.objMain
End Property

Private Sub Class_Initialize()
    numLinea = 0
    'jeaa 02/09/04 para que si no existe el parametro imprima normalmente
    ImpValNota = True
   Me.CambioPag = False
End Sub

Private Sub mSpTxt_NuevaPagina()
    'PrintTransMain.NuevaPagina
    'PrintTransMain.NuevaPagina
End Sub

Public Sub PrintSection_ItemLInea(ByVal numfila As Integer, ByVal CODITEM As String)
    Dim i As Long, j As Long, s As String
    'Dim tCant As Currency, tPrecio As Currency, tPrecioSinIVA As Currency, tIVA As Currency
    Dim nombreItem As String, suma As Currency, TotLineas As Long
    Dim cmd As String
    On Error GoTo ErrTrap
    With mSpTxt
        s = mprops.Texto  'carga el texto
        numLinea = 0
        TotLineas = 0
        mNoEsItemNota = True
        For i = numfila To numfila
            Set ivk = mGnComp.IVKardex(i)
            'Recupera el item correspondiente
            nombreItem = "(Item no encontrado)"
            Set iv = mGnComp.Empresa.RecuperaIVInventario(CODITEM)
            If Not (iv Is Nothing) Then
               If iv.CodInventario <> "-" And iv.CodInventario <> "+" And Not iv.BandCambiaDescr Then
                    nombreItem = iv.Descripcion
                    mNoEsItemNota = True
                Else
                    nombreItem = ivk.Nota
                    If mprops.ImpValNota Then
                        mNoEsItemNota = True
                    Else
                        mNoEsItemNota = False
                    End If
                End If
            End If
            'Impresion
            For j = 1 To Len(s)
                'Si es un comando
                If Mid$(s, j, 2) = "%(" Then
                    cmd = Mid$(s, j + 2, InStr(j + 2, s, ")") - (j + 2))
                    ProcesaComando cmd, mSpTxt
                    j = j + Len(cmd) + 2
                'Si es una variable
                ElseIf Mid$(s, j, 2) = "$(" Then
                    cmd = Mid$(s, j + 2, InStr(j + 2, s, ")") - (j + 2))
                    ProcesaComando "CD1", mSpTxt
                    ProcesaVariable cmd, i, nombreItem
                    ProcesaComando "CD0", mSpTxt
                    j = j + Len(cmd) + 2
                'si es otra linea
                ElseIf Asc(Mid$(s, j, 1)) = vbKeyReturn Then
                    .PrintLine "", 1
                    numLinea = numLinea + 1
                    TotLineas = TotLineas + 1
                'Si no es un comando ni variable
                Else
                    .PrintLine Mid$(s, j, 1)          'Manda un carácter a la impresora
                End If
            Next j
        Next i
        If numLinea < Me.Linea And Me.Linea > 0 Then
            .PrintLine "", 1 - numLinea  'Me.Linea - numLinea
        End If
    End With
    Exit Sub
ErrTrap:
    Err.Raise ERR_NOIMPRIME, App.EXEName, "Seccion Items " & Err.Description
End Sub

Public Property Let Parametros(value As String)
    mprops.Parametros = value
End Property

Public Property Get Parametros() As String
  Parametros = mprops.Parametros
End Property

Public Property Let Grupo(value As String)
    mprops.Grupo = value
End Property

Public Property Get Grupo() As String
  Grupo = mprops.Grupo
End Property

Private Sub ProcesaVariableNoContado(cad As String, i As Long, ITEM As IVInventario, codBodega As String)
    Dim lon As Integer, v As Variant, Texto As String
    Dim deci  As Integer, fmt As String
    Dim uni As IVUnidad
    Dim IVISO As IVInventario
    Dim ivs As IVNumSerie
    'variables disponibles para  la seccion de Items
    With mSpTxt
        v = Split(cad, ";")
        If IsEmpty(v) Then Exit Sub
        fmt = gfmt
        If UBound(v, 1) >= 1 Then lon = v(1)
        If UBound(v, 1) >= 2 Then fmt = generafmt(CStr(v(2)), CStr(v(0)))      'Subrutinapublica
        Select Case v(0)
            Case "NUMLIN":  .PrintLine .Rellenar(i, lon, False)
            Case "CODITEM": .PrintLine .Rellenar(iv.CodInventario, lon, True)
            Case "CODALTITEM": .PrintLine .Rellenar(iv.CodAlterno1, lon, True)
            Case "CODALT2ITEM": .PrintLine .Rellenar(iv.CodAlterno2, lon, True)
            Case "DESCITEM": .PrintLine .Rellenar(iv.Descripcion, lon, True)
            Case "DESCITEMIVA":
                If ivk.IVA = 0 Then
                    .PrintLine .Rellenar(iv.Descripcion, lon, True)
                Else
                    .PrintLine .Rellenar("*" & iv.Descripcion, lon, True)
                End If
            Case "DESCITEMNOIVA":
                If ivk.IVA = 0 Then
                    .PrintLine .Rellenar("*" & iv.Descripcion, lon, True)
                Else
                    .PrintLine .Rellenar(iv.Descripcion, lon, True)
                End If
            Case "DESCITEMIVAPR":
                If ivk.IVA = 0 Then
                    If ivk.idpadre = 0 Then
                        .PrintLine .Rellenar(iv.Descripcion, lon, True)
                    Else
                        .PrintLine .Rellenar("++ " & iv.Descripcion, lon, True)
                    End If
                Else
                    If ivk.idpadre = 0 Then
                        .PrintLine .Rellenar("*" & iv.Descripcion, lon, True)
                    Else
                        .PrintLine .Rellenar("* ++ " & iv.Descripcion, lon, True)
                    End If
               
                End If
            Case "CODBOD": .PrintLine .Rellenar(codBodega, lon, True)
            Case "CANT": .PrintLine .Rellenar(Format("0", fmt), lon, False)
            Case "UNIDAD":
                .PrintLine .Rellenar(iv.Unidad, lon, True)
        End Select
    End With
End Sub

Private Function Ceiling(ByVal X As Double) As Long
   Ceiling = -Int(X * (-1))
End Function

