VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsPresupuesto"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit


Private Type T_PROPS
    Texto As String
    Linea As Integer 'Numero  maximo de lineas
    CambioPag  As Boolean    'True = Cambio de pagina  cuando llega  al numero maximo
    objMain As PrintTrans
End Type

Private mGnComp As GNComprobante
Private WithEvents mSpTxt As SiiPrint.PrintTxt
Attribute mSpTxt.VB_VarHelpID = -1
Dim ctk As PRLibroDetalle
Dim rs_ctk As Recordset
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

Public Property Set GNC(ByVal gc As Sii4A32.GNComprobante)
    Set mGnComp = gc
End Property

Public Property Set Sptxt(ByVal Sptxt As SiiPrint.PrintTxt)
    Set mSpTxt = Sptxt
End Property

Public Sub PrintSection()
    Dim i As Long, j As Long
    Dim s As String, cmd As String
    Dim sql As String
    On Error GoTo ErrTrap
    s = Me.Texto
    numLinea = 0
    If mGnComp.Empresa.GNOpcion.ObtenerValor("OrdenarAsientoPorDebe") = "0" Then
            sql = "spConsPRDiarioDetalle"      'Por Orden en la que ingresó
    Else
            sql = "spConsPRDiarioDetalle2"      'Debe primero y luego Haber
    End If
    sql = sql & " " & mGnComp.CodPRAsiento & "," & mGnComp.Cotizacion("")
    Set rs_ctk = mGnComp.Empresa.OpenRecordset(sql)
      
    If rs_ctk.RecordCount > 0 Then
        For i = 1 To rs_ctk.RecordCount
            mGnComp.ListaTSKardex
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
                    'Si no es un comando ni variable
                    Else
                        .PrintLine Mid$(s, j, 1)          'Manda un carácter a la impresora
                    End If
                Next j
                If numLinea - 1 >= Me.Linea And Me.CambioPag = True Then
                'genera un  salto de pagina
                    .ImpSaltoPagina
                    numLinea = 0
                ElseIf numLinea - 1 >= Me.Linea And Me.CambioPag = False And Me.Linea > 0 Then
                    'Solamente deja de imprimir items
                    Exit For
                End If
            End With
            rs_ctk.MoveNext
        Next i
    End If
        If numLinea < Me.Linea And Me.Linea > 0 Then
            mSpTxt.PrintLine "", Me.Linea - numLinea
        End If
        
    Exit Sub
ErrTrap:
    Err.Raise ERR_NOIMPRIME, App.EXEName, "Seccion Presupuesto " & Err.Description
End Sub


Private Sub ProcesaVariable(ByVal cad As String, numlin As Long)
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
        Case "CODCTA":  .PrintLine .Rellenar(rs_ctk.Fields("CodCuenta"), lon, True)
        Case "NOMCTA": .PrintLine .Rellenar(rs_ctk.Fields("NombreCuenta"), lon, True)
        Case "DESC": .PrintLine .Rellenar(rs_ctk.Fields("Descripcion"), lon, True)
        Case "DEBE": .PrintLine .Rellenar(IIf(rs_ctk.Fields("ValorDebe") = 0, "", Format(rs_ctk.Fields("ValorDebe"), fmt)), lon, False)
        Case "HABER": .PrintLine .Rellenar(IIf(rs_ctk.Fields("ValorHaber") = 0, "", Format(rs_ctk.Fields("ValorHaber"), fmt)), lon, False)
        'jeaa 08/01/2008
        Case "CODSUCURSAL": .PrintLine .Rellenar(IIf(IsNull(rs_ctk.Fields("Cod")), "", rs_ctk.Fields("Cod")), lon, True)
        Case "SUCURSAL": .PrintLine .Rellenar(IIf(IsNull(rs_ctk.Fields("Nom")), "", rs_ctk.Fields("Nom")), lon, True)
        End Select
    End With
End Sub

Private Sub Class_Initialize()
    numLinea = 0
    Me.CambioPag = False
End Sub

