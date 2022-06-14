VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsDetalleTarjetas"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit

Private mGnComp As GNCOMPROBANTE
Private mSpTxt As SiiPrint.PrintTxt
Dim pcProvCli  As pcProvCli
Dim tsdt As TSDetalleTarjeta
Dim tsdtAUX  As TSDetalleTarjeta
Dim CodTarjeta As String

Private Type T_PROPS
    Texto As String
    Linea As Integer 'Numero  maximo de lineas
    CambioPag  As Boolean    'True = Cambio de pagina  cuando llega  al numero maximo
    ImpxTarjeta As Boolean    'jeaa 25/07/2007 True = Imprime datos x proveedor Cliente
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

Public Property Get ImpxTarjeta() As Boolean
    ImpxTarjeta = mprops.ImpxTarjeta
End Property

Public Property Let ImpxTarjeta(value As Boolean)
    mprops.ImpxTarjeta = value
End Property


Public Property Set GNC(ByVal gc As Sii4A32.GNCOMPROBANTE)
    Set mGnComp = gc
End Property

Public Property Set Sptxt(ByVal Sptxt As SiiPrint.PrintTxt)
    Set mSpTxt = Sptxt
End Property

Public Sub PrintSection()
    Dim i As Long, j As Long
    Dim s As String, cmd As String, numLinea As Long, TotLineas As Long
    Dim CodTar As String
    On Error GoTo ErrTrap
    CodTarjeta = ""
    s = Me.Texto
        
    For i = 1 To mGnComp.CountTSDetalleTarjeta
        Set tsdt = mGnComp.TSDetalleTarjeta(i)
        If i < mGnComp.CountTSDetalleTarjeta - 1 Then
            Set tsdtAUX = mGnComp.TSDetalleTarjeta(i + 1)
        Else
            Set tsdtAUX = mGnComp.TSDetalleTarjeta(mGnComp.CountTSDetalleTarjeta)
        End If
        CodTar = tsdt.CodTarjeta
        'If CodTar <> tsdt.CodTarjeta Then
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
                    If Not Me.ImpxTarjeta Then
                        If TotLineas < mGnComp.CountTSDetalleTarjeta Then    'Solamente si no ha impreso la totalidad de ítems
                            .ImpSaltoPagina         'genera un  salto de pagina
                            numLinea = 0
                        End If
                    Else
                        If CodTar <> tsdtAUX.CodTarjeta Then   'Solamente si no ha impreso la totalidad de ítems
                            If TotLineas < mGnComp.CountTSDetalleTarjeta And CodTar <> tsdtAUX.CodTarjeta Then   'Solamente si no ha impreso la totalidad de ítems
                            .ImpSaltoPagina         'genera un  salto de pagina
                            numLinea = 0
                            End If
                        End If
                    
                    End If
                ElseIf numLinea >= Me.Linea And Me.CambioPag = False And Me.Linea > 0 Then
                    'Solamente deja de imprimir items
                    Exit For
                End If
            End With
'        End If
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
    Dim ivb As IVBanco, ivt As ivtaRJETA
    Dim gc As GNCOMPROBANTE
    Set gc = mGnComp.Empresa.RecuperaGNComprobante(tsdt.IdTransRef)

    'variables disponibles para  la seccion de Recargo
    With mSpTxt
        v = Split(cad, ";")
        If IsEmpty(v) Then Exit Sub
        
        fmt = gfmt
        If UBound(v, 1) >= 1 Then lon = v(1)
        If UBound(v, 1) >= 2 Then fmt = generafmt(CStr(v(2)), CStr(v(0)))
        Select Case v(0)
            Case "NUMLIN": .PrintLine .Rellenar(numlin, lon, True)
            Case "CODTARJETA":
                If Not Me.ImpxTarjeta Then
                    .PrintLine .Rellenar(tsdt.CodTarjeta, lon, True)
                Else
                    If CodTarjeta <> tsdt.CodTarjeta Then
                        .PrintLine .Rellenar(tsdt.CodTarjeta, lon, True)
                    End If
                End If
            Case "DESCTARJETA":
                Set ivt = mGnComp.Empresa.RecuperaIVTarjeta(tsdt.CodTarjeta)
                .PrintLine .Rellenar(ivt.Descripcion, lon, True)
                Set ivt = Nothing
            Case "TITULAR":
                .PrintLine .Rellenar(tsdt.Nombre, lon, True)
            Case "AUTORIZA":
                .PrintLine .Rellenar(tsdt.NumDoc, lon, True)
            Case "VALOR": .PrintLine .Rellenar(Format(tsdt.valor, fmt), lon, False)
            Case "TRANS":
                cadena = gc.CodTrans & " " & gc.NumTrans
                .PrintLine .Rellenar(cadena, lon, True)
            '**********  VALOR TOTAL X TARJETA
            Case "TOTALTARJETA":
                If CodTarjeta <> tsdt.CodTarjeta Then
                    .PrintLine .Rellenar(Format(TotalxTarjeta(tsdt.CodTarjeta, mGnComp.TransId), fmt), lon, False)
                    CodTarjeta = tsdt.CodTarjeta
                Else
                    .PrintLine .Rellenar(Space(lon), lon, True)
                End If
        End Select
            
        
    End With
End Sub

Private Function TotalxTarjeta(ByVal CodTar As String, TransId As Long) As Currency
    Dim sql As String, rs As Recordset
    Set rs = New Recordset
    sql = " SELECT"
    
    sql = sql & " SUM(valor) As valor"
    sql = sql & " FROM GNCOMPROBANTE G"
    sql = sql & " INNER JOIN TSDetalleTarjeta T"
    sql = sql & " INNER JOIN ivtaRJETA ta"
    sql = sql & " ON T.IDTARJETA=ta.IDtARJETA"
    sql = sql & " ON t.TRANSID=G.TRANSID"
    sql = sql & " Where g.transid = " & TransId
    sql = sql & " and CODTarjeta='" & CodTar & "'"
    
    Set rs = mGnComp.Empresa.OpenRecordset(sql)
    If Not rs.EOF Then
        TotalxTarjeta = rs.Fields("Valor")
    Else
        TotalxTarjeta = 0
    End If
    rs.Close
    Set rs = Nothing

End Function

Private Sub Class_Initialize()
    Me.ImpxTarjeta = False
End Sub
