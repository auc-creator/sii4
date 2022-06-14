VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsBanco"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private mGnComp As GNComprobante
Private mSpTxt As SiiPrint.PrintTxt
Dim tsk As TSKardex
Dim Banco As TSBanco
Dim tipodoc As TSTipoDocBanco

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
    Dim s As String, cmd As String
    On Error GoTo ErrTrap
    s = Me.Texto
    For i = 1 To mGnComp.CountTSKardex
        Set tsk = mGnComp.TSKardex(i)
        If Not mGnComp.Empresa.VerificaSiEfectivo(tsk.CodTipoDoc) Then ': Exit Sub 'Control para lira
            Set Banco = mGnComp.Empresa.RecuperaTSBanco(tsk.CodBanco)
            Set tipodoc = mGnComp.Empresa.RecuperaTSTipoDocBanco(tsk.CodTipoDoc)
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
                        'Si no es un comando ni variable
                        Else
                            .PrintLine Mid$(s, j, 1)          'Manda un carácter a la impresora
                        End If
                    Next j
                End With
            End If
    Next i
    Exit Sub
ErrTrap:
    Err.Raise ERR_NOIMPRIME, App.EXEName, "Seccion Banco " & Err.Description
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
        Case "CODBANCO":  .PrintLine .Rellenar(tsk.CodBanco, lon, True)
        Case "NOMBANCO": .PrintLine .Rellenar(Banco.Descripcion, lon, True)      '*************
        Case "CODTIPODOC": .PrintLine .Rellenar(tsk.CodTipoDoc, lon, True)
        Case "NOMTIPODOC": .PrintLine .Rellenar(tipodoc.Descripcion, lon, True)  '*********
        Case "NUMDOC": .PrintLine .Rellenar(tsk.NumDoc, lon, True)
        Case "DEBE": .PrintLine .Rellenar(Format(tsk.debe, fmt), lon, False)
        Case "HABER": .PrintLine .Rellenar(Format(tsk.haber, fmt), lon, False)
        Case "VALOR": .PrintLine .Rellenar(Format(Abs(tsk.debe - tsk.haber), fmt), lon, False)
        Case "FEMI": .PrintLine .Rellenar(Format(tsk.FechaEmision, fmt), lon, True)
        Case "PLAZO": .PrintLine .Rellenar(Format(DateDiff("d", tsk.FechaVenci, tsk.FechaEmision), fmt), lon, True)      '*******
        Case "FVENCI": .PrintLine .Rellenar(Format(tsk.FechaVenci, fmt), lon, True)
        Case "NOMBRE": .PrintLine .Rellenar(tsk.Nombre, lon, True)
        Case "OBSERVA": .PrintLine .Rellenar(tsk.Observacion, lon, True)
        Case "BANCOCH": .PrintLine .Rellenar(tsk.CodBancoRef, lon, True)
        Case "CORTARJETA": .PrintLine .Rellenar(tsk.CodTarjeta, lon, True)
        Case "NUMCUENTA": .PrintLine .Rellenar(tsk.NumCuenta, lon, True)
        Case "NUMCHEQUE": .PrintLine .Rellenar(tsk.numCheque, lon, True)
        Case "TITULARCTA": .PrintLine .Rellenar(tsk.TitularCta, lon, True)
        End Select
    End With
End Sub

Private Sub Class_Terminate()
    Set tsk = Nothing
    Set Banco = Nothing
    Set tipodoc = Nothing
End Sub
