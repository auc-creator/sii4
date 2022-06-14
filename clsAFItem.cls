VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsAFItem"
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


Dim ivk As AFKardex, iv As AFInventario
Dim IvKaux  As AFKardex
Dim IVKOrdenBodega  As AFKardex

Private Type T_PROPS
    Texto As String
    Linea As Integer 'Numero  maximo de lineas
    CambioPag  As Boolean    'True = Cambio de pagina  cuando llega  al numero maximo
    objMain As PrintTrans
    ImpValNota As Boolean    'jeaa 02/09/04 True = Imprime datos del item nota
    Parametros  As String
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
    Dim v As Variant
    On Error GoTo ErrTrap
    With mSpTxt
        s = mprops.Texto  'carga el texto
        numLinea = 0
        TotLineas = 0
        mNoEsItemNota = True
        CountNumBodega = 0
''''        If Not Me.ImpxBod Then
        If Len(Me.Parametros) = 0 Then
            For i = 1 To mGnComp.CountAFKardex
                Set ivk = mGnComp.AFKardex(i)
                
                
                nombreItem = "(Item no encontrado)"
                Set iv = mGnComp.Empresa.RecuperaAFInventario(ivk.CodInventario)
                If Not (iv Is Nothing) Then
                   If iv.CodInventario <> "-" And iv.CodInventario <> "+" Then
                        nombreItem = iv.DESCRIPCION
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
                            If TotLineas < mGnComp.CountAFKardex Then   'Solamente si no ha impreso la totalidad de ítems
                                .ImpSaltoPagina         'genera un  salto de pagina
                                numLinea = 0
                            End If
                        ElseIf numLinea >= Me.Linea And Me.CambioPag = False And Me.Linea > 0 Then
                            'Solamente deja de imprimir items
                            Exit For
                        End If
                    
            Next i
        Else
            
            For i = 1 To mGnComp.CountAFKardex
                If i = 1 Then
                    ReDim mBodega(1) As Variant
                    mBodega(CountNumBodega) = mGnComp.AFKardex(i).codBodega
                    CountNumBodega = CountNumBodega + 1
                Else
                    For j = 0 To UBound(mBodega) - 1
                        If mBodega(j) <> mGnComp.AFKardex(i).codBodega Then
                            OtraBodega = True
                        Else
                            OtraBodega = False
                            Exit For
                        End If
                    Next j
                    If OtraBodega Then
                        ReDim Preserve mBodega(UBound(mBodega) + 1)
                        mBodega(CountNumBodega) = mGnComp.AFKardex(i).codBodega
                        CountNumBodega = CountNumBodega + 1
                    End If
                End If
            Next i
        
        
            Select Case UCase(Me.Parametros)
                Case "TODO_ORDEN_BODEGA"
                    For k = 0 To UBound(mBodega) - 1
                            For i = 1 To mGnComp.CountAFKardex
                                Set ivk = mGnComp.AFKardex(i)
        
                                If ivk.codBodega = mBodega(k) Then
        
                                If i < mGnComp.CountAFKardex - 1 Then
                                    Set IvKaux = mGnComp.AFKardex(i + 1)
                                Else
                                    Set IvKaux = mGnComp.AFKardex(mGnComp.CountAFKardex)
                                End If
        
                                'Recupera el item correspondiente
                                codBodega = ivk.codBodega
        
                                nombreItem = "(Item no encontrado)"
                                Set iv = mGnComp.Empresa.RecuperaAFInventario(ivk.CodInventario)
                                If Not (iv Is Nothing) Then
                                   If iv.CodInventario <> "-" And iv.CodInventario <> "+" Then
                                        nombreItem = iv.DESCRIPCION
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
                                            If TotLineas < mGnComp.CountAFKardex Then   'Solamente si no ha impreso la totalidad de ítems
                                                .ImpSaltoPagina         'genera un  salto de pagina
                                                numLinea = 0
                                            End If
                                        ElseIf numLinea >= Me.Linea And Me.CambioPag = False And Me.Linea > 0 Then
                                            'Solamente deja de imprimir items
                                            Exit For
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
                            For i = 1 To mGnComp.CountAFKardex
                                Set ivk = mGnComp.AFKardex(i)
        
                                If ivk.codBodega = mBodega(k) Then
        
                                If i < mGnComp.CountAFKardex - 1 Then
                                    Set IvKaux = mGnComp.AFKardex(i + 1)
                                Else
                                    Set IvKaux = mGnComp.AFKardex(mGnComp.CountAFKardex)
                                End If
        
                                'Recupera el item correspondiente
                                codBodega = ivk.codBodega
        
                                nombreItem = "(Item no encontrado)"
                                Set iv = mGnComp.Empresa.RecuperaAFInventario(ivk.CodInventario)
                                If Not (iv Is Nothing) Then
                                   If iv.CodInventario <> "-" And iv.CodInventario <> "+" Then
                                        nombreItem = iv.DESCRIPCION
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

                            Next i
                        End If
                            If k = UBound(mBodega) - 1 Then
                                numLinea = 0
                            Else
                                If TotLineas < mGnComp.CountAFKardex Then   'Solamente si no ha impreso la totalidad de ítems
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
                Case Else
                    v = Split(Me.Parametros, "=")
                    If v(0) = "SOLO_BODEGA" Then
                            k = 0
'                        For k = 0 To UBound(mBodega) - 1
                                For i = 1 To mGnComp.CountAFKardex
                                    Set ivk = mGnComp.AFKardex(i)
            
                                    If ivk.codBodega = v(1) Then
            
                                        If i < mGnComp.CountAFKardex - 1 Then
                                            Set IvKaux = mGnComp.AFKardex(i + 1)
                                        Else
                                            Set IvKaux = mGnComp.AFKardex(mGnComp.CountAFKardex)
                                        End If
                
                                        'Recupera el item correspondiente
                                        codBodega = ivk.codBodega
                
                                        nombreItem = "(Item no encontrado)"
                                        Set iv = mGnComp.Empresa.RecuperaAFInventario(ivk.CodInventario)
                                        If Not (iv Is Nothing) Then
                                           If iv.CodInventario <> "-" And iv.CodInventario <> "+" Then
                                                nombreItem = iv.DESCRIPCION
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
                                                If TotLineas < mGnComp.CountAFKardex Then   'Solamente si no ha impreso la totalidad de ítems
                                                    .ImpSaltoPagina         'genera un  salto de pagina
                                                    numLinea = 0
                                                End If
                                            ElseIf numLinea >= Me.Linea And Me.CambioPag = False And Me.Linea > 0 Then
                                                'Solamente deja de imprimir items
                                                Exit For
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
    Dim lon As Integer, v As Variant
    Dim deci  As Integer, fmt As String, ivg As AFGrupo
    Dim uni As IVUnidad
    Dim IVISO As AFInventario
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
            Case "DESCITEMIVA":
                If ivk.IVA = 0 Then
                    .PrintLine .Rellenar(nombreItem, lon, True)
                Else
                    .PrintLine .Rellenar("*" & nombreItem, lon, True)
                End If
                
                
            '.PrintLine .Rellenar(IIf(ivk.IVA = 0, nombreItem, "*" & nombreItem), lon, True)
            Case "CODBOD": .PrintLine .Rellenar(ivk.codBodega, lon, True)
            Case "CODCUSTODIO": .PrintLine .Rellenar(ivk.codBodega, lon, True)
            Case "CANT":
                If mNoEsItemNota Then
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
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "CANTSGN":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(ivk.Cantidad, fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
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
                        If ivk.Cantidad < 0 Then
                            .PrintLine .Rellenar(Format(Abs(ivk.Precio), fmt), lon, False)
                        Else
                            .PrintLine .Rellenar(Format(ivk.Precio, fmt), lon, False)
                        End If
                    Else
                        .PrintLine .Rellenar(Format(Abs(ivk.Precio), fmt), lon, False)
                    End If
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If

            Case "PT":
                If mNoEsItemNota Then
                    If mGnComp.GNTrans.IVTipoTrans = "E" Then
                        If ivk.Cantidad < 0 Then
                            .PrintLine .Rellenar(Format(Abs(ivk.PrecioTotal), fmt), lon, False)
                        Else
                            .PrintLine .Rellenar(Format((ivk.PrecioTotal) * -1, fmt), lon, False)
                        End If
                    Else
                        .PrintLine .Rellenar(Format(Abs(ivk.PrecioTotal), fmt), lon, False)
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
                    .PrintLine .Rellenar(Format((CDbl(ivk.PrecioReal) + (ivk.IVA * Abs(CDbl(ivk.PrecioReal)))), fmt), lon, False)
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
                    .PrintLine .Rellenar(Format((CDbl(ivk.PrecioReal) + (ivk.IVA * Abs(CDbl(ivk.PrecioReal)))) * Abs(ivk.Cantidad), fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PTSGN":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(ivk.PrecioTotal, fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PUR":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(ivk.PrecioReal, fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PTR":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(Abs(ivk.PrecioRealTotal), fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PTRSGN":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(Abs(ivk.PrecioRealTotal), fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PORDESC": .PrintLine .Rellenar(Format(ivk.Descuento * 100, fmt), lon, False)
            Case "PORIVA": .PrintLine .Rellenar(Format(ivk.IVA * 100, fmt), lon, False)

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
                    Set ivg = mGnComp.Empresa.RecuperaAFGrupo(1, iv.codGrupo(1))
                    If Not (ivg Is Nothing) Then
                        .PrintLine .Rellenar(ivg.DESCRIPCION, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                Else
                    .PrintLine .Rellenar("", lon, True)
                End If
            Case "CODGRUPO2": .PrintLine .Rellenar(iv.codGrupo(2), lon, True)
            Case "DESCGRUPO2":
                If Len(iv.codGrupo(2)) > 0 Then
                    Set ivg = mGnComp.Empresa.RecuperaAFGrupo(2, iv.codGrupo(2))
                    If Not (ivg Is Nothing) Then
                        .PrintLine .Rellenar(ivg.DESCRIPCION, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                Else
                    .PrintLine .Rellenar("", lon, True)
                End If
            Case "CODGRUPO3": .PrintLine .Rellenar(iv.codGrupo(3), lon, True)
            Case "DESCGRUPO3":
                If Len(iv.codGrupo(3)) > 0 Then
                    Set ivg = mGnComp.Empresa.RecuperaAFGrupo(3, iv.codGrupo(3))
                    If Not (ivg Is Nothing) Then
                        .PrintLine .Rellenar(ivg.DESCRIPCION, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                Else
                    .PrintLine .Rellenar("", lon, True)
                End If
            Case "CODGRUPO4": .PrintLine .Rellenar(iv.codGrupo(4), lon, True)
            Case "DESCGRUPO4":
                If Len(iv.codGrupo(4)) > 0 Then
                    Set ivg = mGnComp.Empresa.RecuperaAFGrupo(4, iv.codGrupo(4))
                    If Not (ivg Is Nothing) Then
                        .PrintLine .Rellenar(ivg.DESCRIPCION, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                Else
                    .PrintLine .Rellenar("", lon, True)
                End If
            Case "CODGRUPO5": .PrintLine .Rellenar(iv.codGrupo(5), lon, True)
            Case "DESCGRUPO5":
                If Len(iv.codGrupo(5)) > 0 Then
                    Set ivg = mGnComp.Empresa.RecuperaAFGrupo(5, iv.codGrupo(5))
                    If Not (ivg Is Nothing) Then
                        .PrintLine .Rellenar(ivg.DESCRIPCION, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                Else
                    .PrintLine .Rellenar("", lon, True)
                End If
            'JEAA 31/03/2005
            Case "OBSERVA":
                If iv.CodInventario <> "-" And iv.CodInventario <> "+" Then
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
                        .PrintLine .Rellenar(uni.DESCRIPCION, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                    Set uni = Nothing
            Case "CODUCONTEO"
                    .PrintLine .Rellenar(iv.CodUnidadConteo, lon, True)
            Case "DESCUCONTEO":
                    Set uni = mGnComp.Empresa.RecuperaUnidad(iv.IdUnidadConteo)
                    If Not (uni Is Nothing) Then
                        .PrintLine .Rellenar(uni.DESCRIPCION, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                    Set uni = Nothing

                    'AUC 16/07/07 agregado valor de descuento
            'AUC 16/07/07 agregado valor de descuento
            Case "VALDESC": .PrintLine .Rellenar(Format(Abs(ivk.ValorDescuento), fmt), lon, False)
                    
            Case "VALDESC":  .PrintLine .Rellenar(Format(Abs(ivk.ValorDescuento), fmt), lon, False)
                    'AUC 28/09/07 agregado para imprimir la unidad relacion
            Case "CANTUNICONT":
                .PrintLine .Rellenar(Format((Abs(ivk.Cantidad) - Abs(ivk.Cantidad Mod iv.CantRelUnidad)) / iv.CantRelUnidad, fmt), lon, False)
            Case "RESTOUNICONT":
                .PrintLine .Rellenar(Format(Abs(ivk.Cantidad Mod iv.CantRelUnidad), fmt), lon, False)
                    'AUC 16/07/07 agregado valor de descuento
            'Case "VALCDESC":  .PrintLine .Rellenar(Format(Abs(ivk.ValorCDescuento), fmt), lon, False)
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
            Set ivk = mGnComp.AFKardex(i)
            'Recupera el item correspondiente
            nombreItem = "(Item no encontrado)"
            Set iv = mGnComp.Empresa.RecuperaAFInventario(CODITEM)
            If Not (iv Is Nothing) Then
               If iv.CodInventario <> "-" And iv.CodInventario <> "+" Then
                    nombreItem = iv.DESCRIPCION
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


