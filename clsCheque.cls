VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsCheque"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'Para imprimir cheques      Alex --> 16/02/2002
Private mGnComp As GNComprobante
Private WithEvents mSpTxt As SiiPrint.PrintTxt
Attribute mSpTxt.VB_VarHelpID = -1
Dim tsk As TSKardex
'Dim banco As TSBanco
'Dim tipodoc As TSTipoDocBanco

Private Type T_PROPS
    Texto As String
    Linea As Integer 'Número  máximo de lineas
    CambioPag  As Boolean    'True = Cambio de pagina  cuando llega  al numero maximo
    Parametros  As String
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


Public Property Let Parametros(value As String)
    mprops.Parametros = value
End Property

Public Property Get Parametros() As String
  Parametros = mprops.Parametros
End Property

Public Sub PrintSection()
    Dim i As Long, j As Long
    Dim s As String, cmd As String
    On Error GoTo ErrTrap
    s = Me.Texto
    For i = 1 To mGnComp.CountTSKardex
        Set tsk = mGnComp.TSKardex(i)
        'hay que comparar el tipo de documento mediante el cód de dcto. para verificar si en efecto es un cheque
        'para ello se tratará de utilizar la variable parámetro.

'        Set banco = mGnComp.Empresa.RecuperaTSBanco(tsk.CodBanco)
'        Set tipodoc = mGnComp.Empresa.RecuperaTSTipoDocBanco(tsk.CodTipoDoc)
'        mGnComp.ListaTSKardex
            
            If tsk.CodTipoDoc <> Me.Parametros Then GoTo CONTINUA 'Para revisar el siguiente documento
'            MsgBox "Imprimir Cheque # " & i
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
                'jeaa 19-05-2004 para controlar que salte la hoja segun configuración
                'problema de impresion de vario cheques sueltos
                If mprops.CambioPag Then
                    mSpTxt.ImpSaltoPagina         'genera un  salto de pagina
                End If
            End With
CONTINUA:   'Pasa a revisar el siguiente documento
    Next i
    Exit Sub
ErrTrap:
    Err.Raise ERR_NOIMPRIME, App.EXEName, "Seccion Cheque  " & Err.Description
End Sub


Private Sub ProcesaVariable(ByVal cad As String, numlin As Long)
    Dim lon As Integer, v As Variant
    Dim fmt As String, cadena As String, pos As Long
    'variables disponibles para  la seccion de Recargo
    With mSpTxt
        v = Split(cad, ";")
        If IsEmpty(v) Then Exit Sub
        
        fmt = gfmt
        If UBound(v, 1) >= 1 Then lon = v(1)
        If UBound(v, 1) >= 2 Then fmt = generafmt(CStr(v(2)), CStr(v(0)))
        Select Case v(0)
'        Case "MSGESPERA": MsgBox v(1)
        Case "NUMLIN": .PrintLine .Rellenar(numlin, lon, True)
        'aqui mandar a imprimir nombre benef., valor cheque, valor en letras, fecha, ciudad, etc.
        Case "NOMBRE": .PrintLine .Rellenar(tsk.Nombre, lon, True)
        Case "VALOR": .PrintLine .Rellenar(Format(tsk.haber, fmt), lon, True)
        Case "VALORL":
            'cadena = ConvertLetrasTexto(tsk.haber, fmt)
            cadena = ConvertLetrasTextoSinCon(tsk.haber, fmt)
            
            If Len(cadena) > lon Then
                pos = InStrRev(cadena, " ", lon, 1)
                If pos < (Len(cadena) - lon) Then
                    .PrintLine .Rellenar(Mid$(cadena, 1, lon), lon, True), 1
                    .PrintLine .Rellenar(Mid$(cadena, lon + 1), lon, True)
                Else
                    .PrintLine .Rellenar(Mid$(cadena, 1, pos), lon, True), 1
                    .PrintLine .Rellenar(Mid$(cadena, pos + 1), lon, True)
                End If
            Else
                .PrintLine .Rellenar(cadena, lon, True), 1
            End If
        Case "FECHA": .PrintLine .Rellenar(Format(tsk.FechaVenci, "dd \de mmmm \de yyyy"), lon, True)
        Case "FECHACHEQUE": .PrintLine .Rellenar(Format(tsk.FechaVenci, fmt), lon, True)
        Case "LF":  .PrintLine ""
'        Case "FECHA": .PrintLine .Rellenar(Format(tsk.FechaVenci, "dd \de mmmm \de yyyy"))
        End Select
    End With
End Sub

Private Sub Class_Terminate()
    Set tsk = Nothing
'    Set banco = Nothing
'    Set tipodoc = Nothing
End Sub

