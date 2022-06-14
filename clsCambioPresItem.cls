VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsCambioPresItem"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'Agregado Esteban 16/09/2005  --> nueva sección para implementar impresión de Productos Con Cambio de Presentacion
                                            ' y mantener similitud de uso con GnPrintG

'Implements IGnComp

Private mGnComp As GNComprobante
'Private mSpTxt As SiiPrint.PrintTxt
Private WithEvents mSpTxt As SiiPrint.PrintTxt
Attribute mSpTxt.VB_VarHelpID = -1
Dim ivk As IVKardex, iv As IVInventario
Private Type T_PROPS
    Texto As String
    Linea As Integer 'Numero  maximo de lineas
    CambioPag  As Boolean    'True = Cambio de pagina  cuando llega  al numero maximo
    objMain As PrintTrans
End Type
Dim numLinea
Dim mprops As T_PROPS

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
        For i = 1 To mGnComp.CountIVKardex
            Set ivk = mGnComp.IVKardex(i)
            'If ivk.Cantidad <= 0 Then GoTo CONTINUA
            'Recupera el item correspondiente
            nombreItem = "(Item no encontrado)"
            Set iv = mGnComp.Empresa.RecuperaIVInventario(ivk.CodInventario)
            If Not (iv Is Nothing) Then
               If iv.CodInventario <> "-" And iv.CodInventario <> "+" Then
                    nombreItem = iv.Descripcion
                Else
                    nombreItem = ivk.Nota
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
                If TotLineas < mGnComp.CountIVKardex Then   'Solamente si no ha impreso la totalidad de ítems
                    .ImpSaltoPagina         'genera un  salto de pagina
                    numLinea = 0
                End If
            ElseIf numLinea >= Me.Linea And Me.CambioPag = False And Me.Linea > 0 Then
                'Solamente deja de imprimir items
                Exit For
            End If
CONTINUA:
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
    Dim deci  As Integer, fmt As String
    
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
        Case "DESCITEM": .PrintLine .Rellenar(nombreItem, lon, True)
        Case "DESCITEMIVA": .PrintLine .Rellenar(IIf(ivk.IVA = 0, nombreItem, "*" & nombreItem), lon, True)
        Case "DESCITEMIVAALIN": .PrintLine .Rellenar(IIf(ivk.IVA = 0, "  " & nombreItem, "* " & nombreItem), lon, True)
        Case "CODBOD": .PrintLine .Rellenar(ivk.codBodega, lon, True)
        Case "CANT"
            If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                .PrintLine .Rellenar(Format(ivk.CantidaddOU, fmt), lon, False)
            Else
                .PrintLine .Rellenar(Format(ivk.Cantidad, fmt), lon, False)
            End If
        Case "UNIDAD":
            'Set iv = mGnComp.Empresa.RecuperaIVInventario(ivk.CodInventario)
            .PrintLine .Rellenar(iv.Unidad, lon, True)
        Case "CU"
            If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                .PrintLine .Rellenar(Format(ivk.CostoDou, fmt), lon, False)
            Else
                .PrintLine .Rellenar(Format(ivk.Costo, fmt), lon, False)
            End If
        Case "CT":
            If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                .PrintLine .Rellenar(Format(Abs(ivk.CostoTotalDou), fmt), lon, False)
            Else
                .PrintLine .Rellenar(Format(Abs(ivk.CostoTotal), fmt), lon, False)
            End If
        Case "CTSGN"
            If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                .PrintLine .Rellenar(Format(ivk.CostoTotalDou, fmt), lon, False)
            Else
                .PrintLine .Rellenar(Format(ivk.CostoTotal, fmt), lon, False)
            End If
        Case "CUR"
            If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                .PrintLine .Rellenar(Format(ivk.CostoRealDou, fmt), lon, False)
            Else
                .PrintLine .Rellenar(Format(ivk.CostoReal, fmt), lon, False)
            End If
        Case "CTR"
            If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                .PrintLine .Rellenar(Format(Abs(ivk.CostoRealTotalDou), fmt), lon, False)
            Else
                .PrintLine .Rellenar(Format(Abs(ivk.CostoRealTotal), fmt), lon, False)
            End If
        Case "CTRSGN"
            If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                .PrintLine .Rellenar(Format(Abs(ivk.CostoRealTotalDou), fmt), lon, False)
            Else
                .PrintLine .Rellenar(Format(Abs(ivk.CostoRealTotal), fmt), lon, False)
            End If
        Case "PU"
            If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                .PrintLine .Rellenar(Format(ivk.PrecioDou, fmt), lon, False)
            Else
                .PrintLine .Rellenar(Format(ivk.Precio, fmt), lon, False)
            End If
        Case "PT"
            If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                .PrintLine .Rellenar(Format(Abs(ivk.PrecioTotalDou), fmt), lon, False)
            Else
                .PrintLine .Rellenar(Format(Abs(ivk.PrecioTotal), fmt), lon, False)
            End If
        Case "PU+IVA"
            If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                .PrintLine .Rellenar(Format(ivk.PrecioRealDou + ivk.IVA * Abs(ivk.PrecioRealDou), fmt), lon, False)
            Else
                .PrintLine .Rellenar(Format(ivk.PrecioReal + ivk.IVA * Abs(ivk.PrecioReal), fmt), lon, False)
            End If
        Case "PT+IVA"
            If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                .PrintLine .Rellenar(Format((ivk.PrecioRealDou + ivk.IVA * Abs(ivk.PrecioRealDou)) * Abs(ivk.CantidaddOU), fmt), lon, False)
            Else
                .PrintLine .Rellenar(Format((ivk.PrecioReal + ivk.IVA * Abs(ivk.PrecioReal)) * Abs(ivk.Cantidad), fmt), lon, False)
            End If
        Case "PTSGN"
            If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                .PrintLine .Rellenar(Format(ivk.PrecioTotalDou, fmt), lon, False)
            Else
                .PrintLine .Rellenar(Format(ivk.PrecioTotal, fmt), lon, False)
            End If
        Case "PUR"
            If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                .PrintLine .Rellenar(Format(ivk.PrecioRealDou, fmt), lon, False)
            Else
                .PrintLine .Rellenar(Format(ivk.PrecioReal, fmt), lon, False)
            End If
        Case "PTR"
            If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                .PrintLine .Rellenar(Format(Abs(ivk.PrecioRealTotalDou), fmt), lon, False)
            Else
                .PrintLine .Rellenar(Format(Abs(ivk.PrecioRealTotal), fmt), lon, False)
            End If
        Case "PTRSGN"
            If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                .PrintLine .Rellenar(Format(Abs(ivk.PrecioRealTotalDou), fmt), lon, False)
            Else
                .PrintLine .Rellenar(Format(Abs(ivk.PrecioRealTotal), fmt), lon, False)
            End If
        Case "PORDESC": .PrintLine .Rellenar(Format(ivk.Descuento * 100, fmt), lon, False)
        Case "PORIVA": .PrintLine .Rellenar(Format(ivk.IVA * 100, fmt), lon, False)
        
        Case "VALIVA"
            If ivk.GNComprobante.Empresa.GNOpcion.IVKTipoDatoDouble Then
                .PrintLine .Rellenar(Format(ivk.IVA * Abs(ivk.PrecioRealTotalDou), fmt), lon, False)     'revisar
            Else
                .PrintLine .Rellenar(Format(ivk.IVA * Abs(ivk.PrecioRealTotal), fmt), lon, False)    'revisar
            End If
        Case "PU2":
          If iv.Precio(2) <> 0 Then
            .PrintLine .Rellenar(Format(iv.Precio(2), fmt), lon, True)   'Modificado 19/10/2001 Diego
          Else
            .PrintLine .Rellenar("", lon, True)
          End If
        Case "MOVIMIENTO"
            If ivk.Cantidad > 0 Then
                .PrintLine .Rellenar("INGRESO", lon, True)
            Else
                .PrintLine .Rellenar("EGRESO", lon, True)
            End If
        End Select
    End With
End Sub

Public Property Set GNC(ByVal gc As Sii4A32.GNComprobante)
    Set mGnComp = gc
End Property
Public Property Set Sptxt(ByVal Sptxt As SiiPrint.PrintTxt)
    Set mSpTxt = Sptxt
End Property


Friend Property Set PrintTransMain(ByVal objMain As PrintTrans)
    Set mprops.objMain = objMain
End Property

Public Property Get PrintTransMain() As PrintTrans
    Set PrintTransMain = mprops.objMain
End Property


Private Sub Class_Initialize()
    numLinea = 0
    Me.CambioPag = False
End Sub

Private Sub mSpTxt_NuevaPagina()

    'PrintTransMain.NuevaPagina
    'PrintTransMain.NuevaPagina
End Sub

