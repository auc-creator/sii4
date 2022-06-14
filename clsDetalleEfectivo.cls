VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsDetalleEfectivo"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit

Private mGnComp As GNComprobante
Private mSpTxt As SiiPrint.PrintTxt
Dim pcProvCli  As pcProvCli
Dim tsde As TSDetalleEfectivo

Private Type T_PROPS
    Texto As String
    Linea As Integer 'Numero  maximo de lineas
    CambioPag  As Boolean    'True = Cambio de pagina  cuando llega  al numero maximo
    objMain As PrintTrans
End Type

Dim mprops As T_PROPS

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
Public Property Set GNC(ByVal gc As Sii4A32.GNComprobante)
    Set mGnComp = gc
End Property

Public Property Set Sptxt(ByVal Sptxt As SiiPrint.PrintTxt)
    Set mSpTxt = Sptxt
End Property

Public Sub PrintSection()
    Dim i As Long, j As Long
    Dim s As String, cmd As String, numLinea As Long, TotLineas As Long
    On Error GoTo ErrTrap
    s = Me.Texto
    For i = 1 To mGnComp.CountTSDetalleEfectivo
        Set tsde = mGnComp.TSDetalleEfectivo(i)
'        If Pck.IdAsignado = 0 And Pck.debe <> 0 Then     'Documentos por cobrar
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
                        ProcesaVariable cmd, i
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
                If TotLineas < mGnComp.CountTSDetalleEfectivo Then    'Solamente si no ha impreso la totalidad de ítems
                    .ImpSaltoPagina         'genera un  salto de pagina
                    numLinea = 0
                End If
                ElseIf numLinea >= Me.Linea And Me.CambioPag = False And Me.Linea > 0 Then
                    'Solamente deja de imprimir items
                    Exit For
                End If
            End With
 '       End If
    Next i
    If numLinea < Me.Linea And Me.Linea > 0 Then
        mSpTxt.PrintLine "", Me.Linea - numLinea
    End If
    Exit Sub
ErrTrap:
    Err.Raise ERR_NOIMPRIME, App.EXEName, "Seccion DocxCobrar " & Err.Description

End Sub


Private Sub ProcesaVariable(ByVal cad As String, numlin As Long)
    Dim lon As Integer, v As Variant
    Dim fmt As String, cadena As String
    'variables disponibles para  la seccion de Recargo
    With mSpTxt
        v = Split(cad, ";")
        If IsEmpty(v) Then Exit Sub
        
        fmt = gfmt
        If UBound(v, 1) >= 1 Then lon = v(1)
        If UBound(v, 1) >= 2 Then fmt = generafmt(CStr(v(2)), CStr(v(0)))
        Select Case v(0)
            Case "NUMLIN": .PrintLine .Rellenar(numlin, lon, True)
            Case "DENO": .PrintLine .Rellenar(tsde.Orden, lon, True)
            Case "DESC":
            Select Case tsde.Orden
                Case 1: cadena = "Billetes 100 dolares"
                Case 2: cadena = "Billetes  50 dolares"
                Case 3: cadena = "Billetes  20 dolares"
                Case 4: cadena = "Billetes  10 dolares"
                Case 5: cadena = "Billetes   5 dolares"
                Case 6: cadena = "Billetes   1 dolar"
                Case 7: cadena = "Monedas 1 dolar"
                Case 8: cadena = "Monedas 0.50 ctvs"
                Case 9: cadena = "Monedas 0.25 ctvs"
                Case 10: cadena = "Monedas 0.10 ctvs"
                Case 11: cadena = "Monedas 0.05 ctvs"
                Case 12: cadena = "Monedas 0.01 ctv"
            End Select
            .PrintLine .Rellenar(cadena, lon, True)
            Case "CANT":
                .PrintLine .Rellenar(Format(tsde.Cantidad, fmt), lon, False)
            Case "VALOR": .PrintLine .Rellenar(Format(tsde.Cantidad * tsde.valor, fmt), lon, False)
        End Select
    End With
End Sub







