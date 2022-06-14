VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsDocCobroCHP"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit
Private mGnComp As GNComprobante
Private mSpTxt As SiiPrint.PrintTxt
Dim Pck  As PCKardexCHP
Dim PCKaux  As PCKardexCHP
Dim doc As PCDocAsignado
Dim docT As PCDocAsignado
Dim CodProvCli As String

Private Type T_PROPS
    Texto As String
    Linea As Integer 'Numero  maximo de lineas
    CambioPag  As Boolean    'True = Cambio de pagina  cuando llega  al numero maximo
    ImpxProvCli As Boolean    'jeaa 25/07/2007 True = Imprime datos x proveedor Cliente
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

Public Property Get ImpxProvCli() As Boolean
    ImpxProvCli = mprops.ImpxProvCli
End Property

Public Property Let ImpxProvCli(value As Boolean)
    mprops.ImpxProvCli = value
End Property

Public Property Set GNC(ByVal gc As Sii4A32.GNComprobante)
    Set mGnComp = gc
End Property

Public Property Set Sptxt(ByVal Sptxt As SiiPrint.PrintTxt)
    Set mSpTxt = Sptxt
End Property


Public Sub PrintSection()
    Dim i As Long, j As Long, s As String, cmd As String
    Dim cancela As Double, numLinea As Long, TotLineas As Long
    Dim codcli As String
    On Error GoTo ErrTrap
    CodProvCli = ""
    s = Me.Texto
    For i = 1 To mGnComp.CountPCKardexCHP
        Set Pck = mGnComp.PCKardexCHP(i)
        If i < mGnComp.CountPCKardexCHP - 1 Then
            Set PCKaux = mGnComp.PCKardexCHP(i + 1)
        Else
            Set PCKaux = mGnComp.PCKardexCHP(mGnComp.CountPCKardexCHP)
        End If
        codcli = Pck.CodProvCli
        
        
        'Solo imprimimos si el documento está asignado a un doc. origen
        'recibimos dinero del  cliente por tanto   va  al  haber
        If Pck.IdAsignado <> 0 And Pck.haber <> 0 Then     'Cobros, IT
            cancela = (Pck.debe + Pck.haber)
            Set doc = Pck.RecuperaPCDocAsignado
            'Set docT = PCK.RecuperaPCDocAsignadot
            If Not (doc Is Nothing) Then
                If mGnComp.CodMoneda <> doc.CodMoneda Then
                    'Convierte en la moneda original el valor que cancela
                    cancela = cancela * mGnComp.Cotizacion("") _
                                / mGnComp.Cotizacion(doc.CodMoneda)
                End If
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
                            ProcesaVariable cmd, i, cancela
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
                        If Not Me.ImpxProvCli Then
                            If TotLineas < mGnComp.CountPCKardexCHP Then   'Solamente si no ha impreso la totalidad de ítems
                                .ImpSaltoPagina         'genera un  salto de pagina
                                numLinea = 0
                            End If
                        Else
                            If codcli <> PCKaux.CodProvCli Then   'Solamente si no ha impreso la totalidad de ítems
                                If TotLineas < mGnComp.CountPCKardexCHP And codcli <> PCKaux.CodProvCli Then   'Solamente si no ha impreso la totalidad de ítems
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
            End If
        End If
    Next i
    If numLinea < Me.Linea And Me.Linea > 0 Then
        mSpTxt.PrintLine "", Me.Linea - numLinea
    End If
    Exit Sub
ErrTrap:
    Err.Raise ERR_NOIMPRIME, App.EXEName, "Seccion DocCobro " & Err.Description

End Sub


Private Sub ProcesaVariable(ByVal cad As String, numlin As Long, cancela As Double)
    Dim lon As Integer, v As Variant
    Dim fmt As String
    'variables disponibles para  la seccion de Recargo
    With mSpTxt
        v = Split(cad, ";")
        If IsEmpty(v) Then Exit Sub
        
        fmt = gfmt
        If UBound(v, 1) >= 1 Then lon = v(1)
        If UBound(v, 1) >= 2 Then fmt = generafmt(CStr(v(2)), CStr(v(0)))
        
        Select Case v(0)
            Case "NUMLIN": .PrintLine .Rellenar(numlin, lon, True)
            Case "CODPC":  .PrintLine .Rellenar(doc.CodProvCli, lon, True)
            Case "CODPC1":
                If CodProvCli <> doc.CodProvCli Then
                    .PrintLine .Rellenar(doc.CodProvCli, lon, True)
                Else
                    .PrintLine .Rellenar(Space(lon), lon, True)
                End If
            Case "NOMPC": .PrintLine .Rellenar(doc.NombreProvCli, lon, True)
            Case "NOMPC1":
                If CodProvCli <> doc.CodProvCli Then
                    .PrintLine .Rellenar(doc.NombreProvCli, lon, True)
                Else
                    .PrintLine .Rellenar(Space(lon), lon, True)
                End If
            Case "TRANS":  .PrintLine .Rellenar(doc.trans, lon, True)
            Case "NUMDOC": .PrintLine .Rellenar(doc.doc, lon, False)
            Case "VALORDOC": .PrintLine .Rellenar(Format(doc.valor, fmt), lon, False) ' jeaa 19-08-03  valor del documento no del debe
            Case "VALORCAN": .PrintLine .Rellenar(Format(cancela, fmt), lon, False)
            Case "SALDO": .PrintLine .Rellenar(Format(doc.saldo, fmt), lon, False)
            Case "FVENCI": .PrintLine .Rellenar(Format(doc.FechaVenci, fmt), lon, True)
            Case "SALDOANT":  .PrintLine .Rellenar(Format(doc.saldo + Pck.haber, fmt), lon, False)
            Case "SALDOTOTALTRANS":  .PrintLine .Rellenar(Format(CalculaSaldtoTrans(doc.CodProvCli, doc.TransId), fmt), lon, False)
            Case "SALDOTOTALANTTRANS":  .PrintLine .Rellenar(Format((CalculaSaldtoTrans(doc.CodProvCli, doc.TransId) + cancela), fmt), lon, False)
            '**********  COBRO TOTAL X CLIENTE
            Case "PCCOBROTOTAL":
                If CodProvCli <> doc.CodProvCli Then
                    .PrintLine .Rellenar(Format(TotalCobradoxPCProvCli(doc.CodProvCli, Pck.GNComprobante.TransId), fmt), lon, False)
                    CodProvCli = doc.CodProvCli
                Else
                    .PrintLine .Rellenar(Space(lon), lon, True)
                End If
        End Select
    End With
End Sub

Private Sub Class_Initialize()
    Me.ImpxProvCli = False
End Sub


Private Function CalculaSaldtoTrans(ByVal codcli As String, TransId As Long) As Currency
    Dim sql As String, rsDebe As Recordset, rsHaber As Recordset
    Dim debe As Currency, haber As Currency, saldo As Currency

    sql = " select  isnull(sum(Debe),0) as TDebe"
    sql = sql & " from gncomprobante g"
    sql = sql & " inner join PCKardexCHP p"
    sql = sql & " inner join pcprovcli pc"
    sql = sql & " on p.idprovcli=pc.idprovcli"
    sql = sql & " on g.transid=p.transid"
    sql = sql & " where g.transid=" & TransId
    sql = sql & " and codprovcli='" & codcli & "'"
    sql = sql & " and g.estado <> 3"
    sql = sql & " group by  codprovcli"
    
    Set rsDebe = mGnComp.Empresa.OpenRecordset(sql)
    
    sql = " select  isnull(sum(haber),0) as Thaber"
    sql = sql & " from gncomprobante g"
    sql = sql & " inner join PCKardexCHP p"
    sql = sql & " inner join pcprovcli pc"
    sql = sql & " on p.idprovcli=pc.idprovcli"
    sql = sql & " on g.transid=p.transid"
    sql = sql & " where idasignado in"
    sql = sql & " (select id from gncomprobante g"
    sql = sql & " inner join PCKardexCHP p"
    sql = sql & " inner join pcprovcli pc"
    sql = sql & " on p.idprovcli=pc.idprovcli"
    sql = sql & " on g.transid=p.transid"
    sql = sql & " where g.transid=" & TransId
    sql = sql & " and codprovcli='" & codcli & "'"
    sql = sql & " and g.estado <> 3 )"
    sql = sql & " and g.estado <> 3"
    sql = sql & " group by  codprovcli"
    
    Set rsHaber = mGnComp.Empresa.OpenRecordset(sql)
    If rsDebe.RecordCount > 0 Then
        debe = rsDebe.Fields("TDebe")
    End If
    If rsHaber.RecordCount > 0 Then
        haber = rsHaber.Fields("THaber")
    End If
    CalculaSaldtoTrans = debe - haber
    Set rsHaber = Nothing
    Set rsDebe = Nothing
End Function

Private Function TotalCobradoxPCProvCli(ByVal codcli As String, TransId As Long) As Currency
    Dim sql As String, rs As Recordset
    Set rs = New Recordset
    sql = " SELECT"
    sql = sql & " SUM(haber) As TotalHaber"
    sql = sql & " FROM GNCOMPROBANTE G INNER JOIN PCKardexCHP P"
    sql = sql & " INNER JOIN PCPROVCLI PC ON P.IDPROVCLI=PC.IDPROVCLI"
    sql = sql & " ON P.TRANSID=G.TRANSID"
    sql = sql & " Where g.transid = " & TransId
    sql = sql & " and CODPROVCLI='" & codcli & "'"
    Set rs = mGnComp.Empresa.OpenRecordset(sql)
    If Not rs.EOF Then
        TotalCobradoxPCProvCli = rs.Fields("TotalHaber")
    Else
        TotalCobradoxPCProvCli = 0
    End If
    rs.Close
    Set rs = Nothing
End Function


