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
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'Implements IGnComp

Private mGnComp As GNComprobante
'Private mSpTxt As SiiPrint.PrintTxt
Private WithEvents mSpTxt As SiiPrint.PrintTxt
Attribute mSpTxt.VB_VarHelpID = -1


Dim afk As AFKardex, iv As AFInventario

Private Type T_PROPS
    Texto As String
    Linea As Integer 'Numero  maximo de lineas
    CambioPag  As Boolean    'True = Cambio de pagina  cuando llega  al numero maximo
    objMain As PrintTrans
    ImpValNota As Boolean    'jeaa 02/09/04 True = Imprime datos del item nota
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
    On Error GoTo ErrTrap
    With mSpTxt
        s = mprops.Texto  'carga el texto
        numLinea = 0
        TotLineas = 0
        mNoEsItemNota = True
        For i = 1 To mGnComp.CountAFKardex
            Set afk = mGnComp.AFKardex(i)
            'Recupera el item correspondiente
            nombreItem = "(Item no encontrado)"
            Set iv = mGnComp.Empresa.RecuperaIVInventario(afk.CodInventario)
            If Not (iv Is Nothing) Then
               If iv.CodInventario <> "-" And iv.CodInventario <> "+" Then
                    nombreItem = iv.Descripcion
                    mNoEsItemNota = True
                Else
                    nombreItem = afk.Nota
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
    
    'variables disponibles para  la seccion de Items
    With mSpTxt
        v = Split(cad, ";")
        If IsEmpty(v) Then Exit Sub
                
        fmt = gfmt
        If UBound(v, 1) >= 1 Then lon = v(1)
        If UBound(v, 1) >= 2 Then fmt = generafmt(CStr(v(2)), CStr(v(0)))      'Subrutinapublica
        Select Case v(0)
            Case "NUMLIN":  .PrintLine .Rellenar(i, lon, False)
            Case "CODITEM": .PrintLine .Rellenar(afk.CodInventario, lon, True)
            Case "CODALTITEM": .PrintLine .Rellenar(iv.CodAlterno1, lon, True)
            Case "CODALT2ITEM": .PrintLine .Rellenar(iv.CodAlterno2, lon, True)
            Case "DESCITEM": .PrintLine .Rellenar(nombreItem, lon, True)
            Case "DESCITEMIVA":
                If afk.IVA = 0 Then
                    .PrintLine .Rellenar(nombreItem, lon, True)
                Else
                    .PrintLine .Rellenar("*" & nombreItem, lon, True)
                End If
                
                
            Case "DESCITEMIVAALIN": .PrintLine .Rellenar(IIf(afk.IVA = 0, "  " & nombreItem, "* " & nombreItem), lon, True)
            Case "CODBOD": .PrintLine .Rellenar(afk.codBodega, lon, True)
            Case "CANT":
                If mNoEsItemNota Then
                    If mGnComp.GNTrans.IVTipoTrans = "E" Then
                        If afk.Cantidad < 0 Then
                            .PrintLine .Rellenar(Format(Abs(afk.Cantidad), fmt), lon, False)
                        Else
                            'cuando existedevolucion en el mismo item
                            .PrintLine .Rellenar(Format((afk.Cantidad) * -1, fmt), lon, False)
                        End If
                    Else
                        .PrintLine .Rellenar(Format(Abs(afk.Cantidad), fmt), lon, False)
                    End If
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "CANTSGN":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(afk.Cantidad, fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "CU":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(afk.Costo, fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "CT":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(Abs(afk.CostoTotal), fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "CTSGN":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(afk.CostoTotal, fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "CUR":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(afk.CostoReal, fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "CTR":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(Abs(afk.CostoRealTotal), fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "CTRSGN":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(Abs(afk.CostoRealTotal), fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PU":
                If mNoEsItemNota Then
                    If mGnComp.GNTrans.IVTipoTrans = "E" Then
                        If afk.Cantidad < 0 Then
                            .PrintLine .Rellenar(Format(Abs(afk.Precio), fmt), lon, False)
                        Else
                            .PrintLine .Rellenar(Format(afk.Precio, fmt), lon, False)
                        End If
                    Else
                        .PrintLine .Rellenar(Format(Abs(afk.Precio), fmt), lon, False)
                    End If
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PT":
                If mNoEsItemNota Then
                    If mGnComp.GNTrans.IVTipoTrans = "E" Then
                        If afk.Cantidad < 0 Then
                            .PrintLine .Rellenar(Format(Abs(afk.PrecioTotal), fmt), lon, False)
                        Else
                            .PrintLine .Rellenar(Format((afk.PrecioTotal) * -1, fmt), lon, False)
                        End If
                    Else
                        .PrintLine .Rellenar(Format(Abs(afk.PrecioTotal), fmt), lon, False)
                    End If
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PUNIT+IVA":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format((Abs(CDbl(afk.Precio)) + (Abs(afk.IVA) * Abs(CDbl(afk.Precio)))), fmt), lon, False) '  jeaa 17/09/03 precio total unitario + IVA
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PU+IVA":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format((CDbl(afk.PrecioReal) + (afk.IVA * Abs(CDbl(afk.PrecioReal)))), fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PTOTAL+IVA":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(((Abs(CDbl(afk.Precio)) + Abs(afk.IVA) * Abs(CDbl(afk.Precio)))) * Abs(afk.Cantidad), fmt), lon, False) '  jeaa 17/09/03 precio total  + IVA
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PT+IVA":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format((CDbl(afk.PrecioReal) + (afk.IVA * Abs(CDbl(afk.PrecioReal)))) * Abs(afk.Cantidad), fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PTSGN":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(afk.PrecioTotal, fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PUR":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(afk.PrecioReal, fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PTR":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(Abs(afk.PrecioRealTotal), fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PTRSGN":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(Abs(afk.PrecioRealTotal), fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "PORDESC": .PrintLine .Rellenar(Format(afk.Descuento * 100, fmt), lon, False)
            Case "PORIVA": .PrintLine .Rellenar(Format(afk.IVA * 100, fmt), lon, False)
            Case "VALIVA":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(afk.IVA * Abs(afk.PrecioRealTotal), fmt), lon, False)    'revisar
                                Else
                    .PrintLine .Rellenar(Format(" ", fmt), lon, False)
                End If
            Case "BANDIVA":
                If mNoEsItemNota Then
                    .PrintLine .Rellenar(Format(IIf(iv.BandIVA, "S", "N"), fmt), lon, False)  'revisar
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
            Case "EXISTACTUAL": .PrintLine .Rellenar(Format(Abs(iv.Existencia(afk.codBodega)), fmt), lon, False) '**** jeaa 18-03-2004
            Case "EXISTANTES": .PrintLine .Rellenar(Format(Abs(iv.Existencia(afk.codBodega) - Abs(afk.Cantidad)), fmt), lon, False) '**** jeaa 18-03-2004
            
            '------------------------------------------------------------------------
            '**** Agregado. 18/Ago/2004. Angel. Para sacar informaciòn de los grupos
            Case "CODGRUPO1": .PrintLine .Rellenar(iv.CodGrupo(1), lon, True)
            Case "DESCGRUPO1":
                If Len(iv.CodGrupo(1)) > 0 Then
                    Set ivg = mGnComp.Empresa.RecuperaAFGrupo(1, iv.CodGrupo(1))
                    If Not (ivg Is Nothing) Then
                        .PrintLine .Rellenar(ivg.Descripcion, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                Else
                    .PrintLine .Rellenar("", lon, True)
                End If
            Case "CODGRUPO2": .PrintLine .Rellenar(iv.CodGrupo(2), lon, True)
            Case "DESCGRUPO2":
                If Len(iv.CodGrupo(2)) > 0 Then
                    Set ivg = mGnComp.Empresa.RecuperaAFGrupo(2, iv.CodGrupo(2))
                    If Not (ivg Is Nothing) Then
                        .PrintLine .Rellenar(ivg.Descripcion, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                Else
                    .PrintLine .Rellenar("", lon, True)
                End If
            Case "CODGRUPO3": .PrintLine .Rellenar(iv.CodGrupo(3), lon, True)
            Case "DESCGRUPO3":
                If Len(iv.CodGrupo(3)) > 0 Then
                    Set ivg = mGnComp.Empresa.RecuperaAFGrupo(3, iv.CodGrupo(3))
                    If Not (ivg Is Nothing) Then
                        .PrintLine .Rellenar(ivg.Descripcion, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                Else
                    .PrintLine .Rellenar("", lon, True)
                End If
            Case "CODGRUPO4": .PrintLine .Rellenar(iv.CodGrupo(4), lon, True)
            Case "DESCGRUPO4":
                If Len(iv.CodGrupo(4)) > 0 Then
                    Set ivg = mGnComp.Empresa.RecuperaAFGrupo(4, iv.CodGrupo(4))
                    If Not (ivg Is Nothing) Then
                        .PrintLine .Rellenar(ivg.Descripcion, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                Else
                    .PrintLine .Rellenar("", lon, True)
                End If
            Case "CODGRUPO5": .PrintLine .Rellenar(iv.CodGrupo(5), lon, True)
            Case "DESCGRUPO5":
                If Len(iv.CodGrupo(5)) > 0 Then
                    Set ivg = mGnComp.Empresa.RecuperaAFGrupo(5, iv.CodGrupo(5))
                    If Not (ivg Is Nothing) Then
                        .PrintLine .Rellenar(ivg.Descripcion, lon, True)
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
                            If Len(afk.Nota) > 0 Then
                                    .PrintLine .Rellenar(afk.Nota, lon, True)
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
                    .PrintLine .Rellenar(afk.TiempoEntrega, lon, False)
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
        Case "VALDESC":  .PrintLine .Rellenar(Format(Abs(afk.ValorDescuento), fmt), lon, False)
                'AUC 28/09/07 agregado para imprimir la unidad relacion
        Case "CANTUNICONT":
            .PrintLine .Rellenar(Format((Abs(afk.Cantidad) - Abs(afk.Cantidad Mod iv.CantRelUnidad)) / iv.CantRelUnidad, fmt), lon, False)
        Case "RESTOUNICONT":
            .PrintLine .Rellenar(Format(Abs(afk.Cantidad Mod iv.CantRelUnidad), fmt), lon, False)
                'AUC 16/07/07 agregado valor de descuento
        'Case "VALCDESC":  .PrintLine .Rellenar(Format(Abs(afk.ValorCDescuento), fmt), lon, False)
        
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
            Set afk = mGnComp.AFKardex(i)
            'Recupera el item correspondiente
            nombreItem = "(Item no encontrado)"
            Set iv = mGnComp.Empresa.RecuperaIVInventario(CODITEM)
            If Not (iv Is Nothing) Then
               If iv.CodInventario <> "-" And iv.CodInventario <> "+" Then
                    nombreItem = iv.Descripcion
                    mNoEsItemNota = True
                Else
                    nombreItem = afk.Nota
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

