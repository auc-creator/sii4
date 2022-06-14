VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsRecargo"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private mGnComp As GNComprobante
Private WithEvents mSpTxt As SiiPrint.PrintTxt
Attribute mSpTxt.VB_VarHelpID = -1
Dim ivkr As IVKardexRecargo, ivr As IVRecargo

Private Type T_PROPS
    Texto As String
    Linea As Integer 'Numero  maximo de lineas
    CambioPag  As Boolean    'True = Cambio de pagina  cuando llega  al numero maximo
    ValorAcum As String  'PTOTAL ; CTOTAL    ->  no se usa
    objMain As PrintTrans
End Type

Dim mprops As T_PROPS
Dim numLinea As Long

Friend Property Set PrintTransMain(ByVal newObj As PrintTrans)
    Set mprops.objMain = newObj
End Property

Public Property Get PrintTransMain() As PrintTrans
    Set PrintTransMain = mprops.objMain
End Property

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

Public Property Let ValorAcum(ByVal value As String)
  If Len(value) > 6 Then
        Err.Raise ERR_INVALIDO, "Elementos.Modo", MSGERR_INVALIDO
    End If
    mprops.ValorAcum = value
End Property

Public Property Get ValorAcum() As String
    ValorAcum = mprops.ValorAcum
End Property

Public Property Set GNC(ByVal gc As Sii4A32.GNComprobante)
    Set mGnComp = gc
End Property

Public Property Set Sptxt(ByVal Sptxt As SiiPrint.PrintTxt)
    Set mSpTxt = Sptxt
End Property

Public Sub PrintSection()

    Dim suma As Currency, nombreRec As String
    'Dim sumarecargo As Currency
    Dim i As Long, j As Long, s As String, cmd As String, TotLineas As Long
    On Error GoTo ErrTrap
    s = Me.Texto
    numLinea = 0
    suma = Abs(mGnComp.IVKardexTotal(False))   'Suma = Total de items
    'Imprime recargos
    For i = 1 To mGnComp.CountIVKardexRecargo
        Set ivkr = mGnComp.IVKardexRecargo(i)
        Set ivr = mGnComp.Empresa.RecuperaIVRecargo(ivkr.CodRecargo)
        'Suma totales
        suma = suma + ivkr.valor
        'Impresion
        With mSpTxt
            For j = 1 To Len(s)
                'Si es un comando
                If Mid$(s, j, 2) = "%(" Then
                    cmd = Mid$(s, j + 2, InStr(j + 2, s, ")") - (j + 2))
                    ProcesaComando cmd, mSpTxt
                    j = j + Len(cmd) + 2
                'Si es una variable
                ElseIf Mid$(s, j, 2) = "$(" Then
                    cmd = Mid$(s, j + 2, InStr(j + 2, s, ")") - (j + 2))
                    ProcesaVariable cmd, suma
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
                If TotLineas < mGnComp.CountIVKardexRecargo Then
                    'genera un  salto de pagina
                    .ImpSaltoPagina     'Genera automáticamente impresión cabecera si se ha especificado así en Config
                    numLinea = 0
                End If
            ElseIf numLinea >= Me.Linea And Me.CambioPag = False And Me.Linea > 0 Then
                'Solamente deja de imprimir items
                Exit For
            End If
        End With
    Next i
    If numLinea < Me.Linea And Me.Linea > 0 Then
            mSpTxt.PrintLine "", Me.Linea - numLinea
    End If
    Exit Sub
ErrTrap:
    Err.Raise ERR_NOIMPRIME, App.EXEName, "Seccion Recargo " & Err.Description

End Sub


Private Sub ProcesaVariable(ByVal cad As String, ByVal suma As Currency)
    Dim lon As Integer, v As Variant
    Dim fmt As String
    Dim cod As String
    'variables disponibles para  la seccion de Recargo
    With mSpTxt
        v = Split(cad, ";")
        If IsEmpty(v) Then Exit Sub
        
        fmt = gfmt
        If UBound(v, 1) >= 1 Then lon = v(1)
        If UBound(v, 1) >= 2 Then fmt = generafmt(CStr(v(2)), CStr(v(0)))
        If UBound(v, 1) >= 3 Then cod = v(3)
        Select Case v(0)
        Case "COD":  .PrintLine .Rellenar(ivr.CodRecargo, lon, True)
        Case "DESC": .PrintLine .Rellenar(ivr.Descripcion, lon, True)
        Case "PORCENT": .PrintLine .Rellenar(Format(ivkr.Porcentaje, fmt), lon, False)
        Case "SIGNO":   .PrintLine .Rellenar(IIf(ivr.Signo = 1, "+", "-"), lon, True)
        Case "VALOR": .PrintLine .Rellenar(Format(Abs(ivkr.valor), fmt), lon, False)
        Case "VALORACUM": .PrintLine .Rellenar(Format(Abs(suma), fmt), lon, False)
        Case "VALOR+IVA": .PrintLine .Rellenar(Format(Abs(ivkr.valor) + Abs(ivkr.valor * (CDbl(cod) / 100)), fmt), lon, False)
        End Select
    End With
End Sub



'Private Sub ImprimeRecargos()
'    Dim ivkr As IVKardexRecargo, ivr As IVRecargo, i As Long, s As String
'    Dim suma As Currency, nombreRec As String
'    Dim sumarecargo As Currency
'    With mSpTxt
'        suma = Abs(mGNComp.IVKardexTotal(False))    'Suma = Total de items sin recargo
'
'        'Imprime recargos
'        For i = 1 To mGNComp.CountIVKardexRecargo
'            Set ivkr = mGNComp.IVKardexRecargo(i)
'            'Suma totales
'            suma = suma + ivkr.Valor
'
'            '*** MAKOTO 06/sep/00 siempre con 2 decimales
'            s = Space$(78) & _
'                .Rellenar(ivkr.CodRecargo, 5, False) & _
'                .Rellenar(Format(ivkr.Porcentaje * 100, "#,0.00"), 12, False) & _
'                .Rellenar(Format(ivkr.Valor, "#,0.00"), 28, False)
'            .PrintLine s, 1
'        Next i
'
'
'        'Total de Factura
'        s = Space$(105) & .Rellenar(Format(suma, "#,0.00"), 18, False)
'        .PrintLine s, 1
'    End With
'    Set ivkr = Nothing
'    Set ivr = Nothing
'End Sub







