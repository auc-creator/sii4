VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsRetencion"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'Implements IGnComp

Private mGnComp As GNComprobante
Private WithEvents mSpTxt As SiiPrint.PrintTxt
Attribute mSpTxt.VB_VarHelpID = -1

Dim ivk As IVKardex, iv As IVInventario

Private Type T_PROPS
    Texto As String
    Linea As Integer 'Numero  maximo de lineas
    CambioPag  As Boolean    'True = Cambio de pagina  cuando llega  al numero maximo
    Parametros  As String
    objMain As PrintTrans
End Type

Dim numLinea
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

Public Property Get LineaActual() As Integer
     LineaActual = numLinea
End Property

Public Property Let Parametros(value As String)
    mprops.Parametros = value
End Property

Public Property Get Parametros() As String
  Parametros = mprops.Parametros
End Property

Public Sub PrintSection()
    Dim i As Long, j As Long, s As String
    'Dim tCant As Currency, tPrecio As Currency, tPrecioSinIVA As Currency, tIVA As Currency
    Dim nombreItem As String, suma As Currency, TotLineas As Long
    Dim cmd As String, rs As Recordset, mcolRet As New Collection, v As Variant
    Dim v1(7, 6) As Variant, NumRet As Long
    'JEAA 14/10/2005
    If UCase(Me.Parametros) <> "TODOSASOCIA" Then
        Set rs = mGnComp.ListaTSKardexRet
    Else
        Set rs = mGnComp.ListaTSKardexRetAsociada
    End If
    
    
    Set rs = mGnComp.ListaTSKardexRet
'    v = rs.GetRows(rs.RecordCount)
'    Set rs = Nothing
    If Not rs.EOF Then
        rs.MoveLast
        rs.MoveFirst
    End If
    If UCase(Me.Parametros) <> "TODOS" And UCase(Me.Parametros) <> "TODOSASOCIA" Then
        Do Until rs.EOF
            If InStr(rs!CodRetencion, Me.Parametros) <> 0 Then NumRet = NumRet + 1
            rs.MoveNext
        Loop
        rs.MoveLast
        rs.MoveFirst
    End If
'    If UCase(Me.Parametros) <> "TODOS" Then     'Filtrar que calcule de un determinado tipo de retención o bien de todos
'        '        'prueba con rs --> no funciona, porque solamente lee un registro y no los dos que son
'        '        For i = 1 To rs.RecordCount
'        '                If InStr(rs!CodRetencion, Me.Parametros) <> 0 Then
'        '                        v = rs.GetRows(1)
'        '                        mcolRet.Add v
'        '                        rs.MoveNext
'        '                End If
'        '        Next i
'        '  prueba con variants
'        'v = rs.GetRows(rs.RecordCount)
'        For i = 0 To UBound(v, 2)
'            If InStr(v(0, i), Me.Parametros) <> 0 Then
'                NumRet = NumRet + 1
'                'aqui podría controlar el número de registros que se están asignando
'                For j = 0 To UBound(v)
'                    v1(j, i) = v(j, i)
'                Next j
'            End If
'        Next i
'        End If
    
    On Error GoTo ErrTrap
    With mSpTxt
        s = mprops.Texto  'carga el texto
        numLinea = 0
        TotLineas = 0
        Do Until rs.EOF
'        For i = 0 To NumRet
            'Verificar si el registro corresponde a lo que debe imprimir
            If UCase(Me.Parametros) <> "TODOS" And UCase(Me.Parametros) <> "TODOSASOCIA" Then     'Filtrar que calcule de un determinado tipo de retención o bien de todos
                'si no es el código solicitado, avance con el siguiente registro
                If InStr(rs!CodRetencion, Me.Parametros) = 0 Then
                    GoTo CONTINUA
'                Else
'                    v = rs.GetRows(1)
'                    mcolRet.Add v
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
                    'ProcesaVariable cmd, i, rs
                    ProcesaVariable cmd, i, rs
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
CONTINUA:
            If numLinea >= Me.Linea And Me.CambioPag = True Then
                If TotLineas < NumRet Then
                    'genera un  salto de pagina
                    .ImpSaltoPagina
                    numLinea = 0
                End If
            ElseIf numLinea >= Me.Linea And Me.CambioPag = False And Me.Linea > 0 Then
                'Solamente deja de imprimir items
                Exit Do
            End If
            rs.MoveNext
        Loop
        Set rs = Nothing
        If numLinea < Me.Linea And Me.Linea > 0 Then
            .PrintLine "", Me.Linea - numLinea
        End If
        
    End With
    Exit Sub
    
ErrTrap:
    Err.Raise ERR_NOIMPRIME, App.EXEName, "Seccion Items " & Err.Description
End Sub

Private Sub ProcesaVariable(cad As String, i As Long, ByVal rs As Recordset)

    Dim lon As Integer, v As Variant, ts As TSRetencion
    Dim deci  As Integer, fmt As String, Pck As PCKardex
    Dim gc As GNComprobante, total As Currency, cadena As String, j As Long
    Dim TipoCompSRI As Anexos
    
    'variables disponibles para  la seccion de Items
    With mSpTxt
        If rs Is Nothing Then Exit Sub
        If UCase(Me.Parametros) <> "TODOS" And UCase(Me.Parametros) <> "TODOSASOCIA" Then     'Filtrar que calcule de un determinado tipo de retención
            If InStr(rs!CodRetencion, Me.Parametros) = 0 Then Exit Sub    'o bien de todos
        End If
       
        Set ts = mGnComp.Empresa.RecuperaTSRetencion(rs!CodRetencion)
        
        If ts Is Nothing Then Exit Sub
        'If ts.Porcentaje = 0 Then Exit Sub
        
            v = Split(cad, ";")
            If IsEmpty(v) Then Exit Sub
            fmt = gfmt
            If UBound(v, 1) >= 1 Then lon = v(1)
            If UBound(v, 1) >= 2 Then fmt = generafmt(CStr(v(2)), CStr(v(0)))      'Subrutina publica
            Select Case v(0)
                Case "CODRET": .PrintLine .Rellenar(rs!CodRetencion, lon, False)
                Case "CODSRI":
                    .PrintLine .Rellenar(rs!CodSRI, lon, False) 'AGREGADO AUC 20/09/2005
                Case "NUMDOC": .PrintLine .Rellenar(rs!NumDoc, lon, False)
                Case "DEBE": .PrintLine .Rellenar(Format(Abs(rs!debe), fmt), lon, False)
                Case "HABER": .PrintLine .Rellenar(Format(Abs(rs!haber), fmt), lon, False)
                Case "OBSERVA": .PrintLine .Rellenar(rs!Observacion, lon, False)
                Case "BASE": .PrintLine .Rellenar(Format(Abs(rs!base), fmt), lon, False)
                Case "PORCENT":
                    If Not ts.BandDividendo Then
                        For i = 1 To ts.CountTSRetencionDet
                            If mGnComp.FechaTrans >= ts.TSRetencionDet(i).FechaInicio And mGnComp.FechaTrans <= ts.TSRetencionDet(i).FechaFin Then
                            '.PrintLine .Rellenar(ts.Porcentaje * 100, lon, False)
                                .PrintLine .Rellenar(ts.TSRetencionDet(i).Porcentaje * 100, lon, False)
                            End If
                        Next
                    Else
                        .PrintLine .Rellenar(rs!haber * 100 / rs!base, lon, False)
                    End If
                Case "DESC": .PrintLine .Rellenar(ts.Descripcion, lon, True)
                Case "TIPORET":
                    If ts.BandIva Then
                        .PrintLine .Rellenar("IVA", lon, True)
                    Else
                        .PrintLine .Rellenar("RENTA", lon, True)
                    End If
                Case "FECDOCREF":
                    If mGnComp.CountPCKardex > 0 Then
                        For j = 1 To mGnComp.CountPCKardex
                            cadena = cadena & Format(mGnComp.PCKardex(j).RecuperaPCDocAsignado.FechaEmision, "dd/mm/yy") & ","
                        Next j
                    End If
                    If cadena = "" Then
                        Do
                        cadena = InputBox("Por favor ingrese Fecha del documento " & vbCrLf & "que origina la retención")
                        Loop Until (IsDate(cadena))
                    Else
                        cadena = Mid(cadena, 1, Len(cadena) - 1)    'borra la última coma
                    End If
                    .PrintLine .Rellenar(cadena, lon, True)
                Case "NUMDOCREF":
                    If mGnComp.CountPCKardex > 0 Then
                        For j = 1 To mGnComp.CountPCKardex
                            cadena = cadena & mGnComp.PCKardex(1).RecuperaPCDocAsignado.CodTrans & mGnComp.PCKardex(1).RecuperaPCDocAsignado.NumTrans & ","
                        Next j
                    End If
                    If cadena = "" Then
                        cadena = InputBox("Por favor ingrese Número del documento " & vbCrLf & "que origina la retención")
                    Else
                        cadena = Mid(cadena, 1, Len(cadena) - 1)    'borra la última coma
                    End If
                    .PrintLine .Rellenar(cadena, lon, True)
                Case "EJEFISCAL":   ' JEAA 11-12-03 AÑO FISCAL
                        .PrintLine .Rellenar(Format(mGnComp.FechaTrans, fmt), lon, True)
                Case "TIPODOCSRI": 'jeaa 07/01/2008
                        cadena = ""
                        Set gc = mGnComp.Empresa.RecuperaGNComprobante(mGnComp.IdTransFuente)
                        If Not (gc Is Nothing) Then
                            Set TipoCompSRI = mGnComp.Empresa.RecuperaAnexos(gc.CodTipoComp)
                            If Not (TipoCompSRI Is Nothing) Then
                                cadena = UCase(TipoCompSRI.Descripcion)
                            End If
                        End If
                        .PrintLine .Rellenar(cadena, lon, True)
                        Set gc = Nothing
                        Set TipoCompSRI = Nothing
                Case "NUMDOCREFSRI":
                    cadena = ""
                    If mGnComp.CountPCKardex > 0 Then
                        For j = 1 To mGnComp.CountPCKardex
                            j = mGnComp.PCKardex(1).RecuperaPCDocAsignado.TransId
                            If j <> 0 Then
                                Set gc = mGnComp.Empresa.RecuperaGNComprobante(j)
                                If Not gc Is Nothing Then
                                    If Len(gc.NumDocRef) = 7 Then
                                        cadena = gc.NumSerieEstablecimiento & gc.NumSeriePunto & gc.NumDocRef
                                    Else
                                        cadena = gc.NumDocRef
                                    End If
                                    
                                End If
                            End If
                            
                            
                        Next j
                    End If
                    If cadena = "" Then
                        cadena = InputBox("Por favor ingrese Número del documento " & vbCrLf & "que origina la retención")
                    Else
                        cadena = cadena
                    End If
                    If Len(cadena) = 13 Then
                        cadena = Mid$(cadena, 1, 3) & "-" & Mid$(cadena, 4, 3) & "-" & Mid$(cadena, 7, 7)
                    End If
                    .PrintLine .Rellenar(cadena, lon, True)
                
                End Select
        
        Set ts = Nothing
        Set rs = Nothing
    End With
End Sub

Public Property Set GNC(ByVal gc As Sii4A32.GNComprobante)
    Set mGnComp = gc
End Property

Public Property Set Sptxt(ByVal Sptxt As SiiPrint.PrintTxt)
    Set mSpTxt = Sptxt
End Property

Private Sub Class_Initialize()
    numLinea = 0
    Me.CambioPag = False
End Sub

Private Sub mSpTxt_NuevaPagina()

'    Me.PrintTransMain.NuevaPagina
    'PrintTransMain.NuevaPagina
End Sub


