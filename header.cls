VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsHeader"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'Implements IGnComp
Private mGnComp As GNComprobante
Private mSpTxt As SiiPrint.PrintTxt


Private Type T_PROPS
    'Todo As Boolean   'True= Habilita cabecera en todas las paginas
    Texto As String
End Type
Dim mprops As T_PROPS

'Public Property Let Todo(ByVal value As Boolean)
'    mprops.Todo = value
'End Property
'
'Public Property Get Todo() As Boolean
'    Todo = mprops.Todo
'End Property

Public Property Let Texto(ByVal value As String)
    mprops.Texto = value
End Property

Public Property Get Texto() As String
    Texto = mprops.Texto
End Property

Public Property Set GNC(ByVal gc As GNComprobante)
    Set mGnComp = gc
End Property

Public Property Set Sptxt(ByVal Sptxt As SiiPrint.PrintTxt)
    Set mSpTxt = Sptxt
End Property


Public Sub PrintSection()
    Dim s As String, i As Long
    Dim cmd As String
    On Error GoTo ErrTrap
    'Set mobjGNOp = mGnComp.Empresa.GNOpcion
    'Datos de cliente (Codigo, Nombre, RUC, Direc,Tel)
    
    'Set cli = mGnComp.Empresa.RecuperaPCProvCli(mGnComp.CodClienteRef)
    s = mprops.Texto
    With mSpTxt
        For i = 1 To Len(s)
            'Si es un comando
            If Mid$(s, i, 2) = "%(" Then
                cmd = Mid$(s, i + 2, InStr(i + 2, s, ")") - (i + 2))
                ProcesaComando cmd, mSpTxt
                i = i + Len(cmd) + 2
            'Si es una variable
            ElseIf Mid$(s, i, 2) = "$(" Then
                cmd = Mid$(s, i + 2, InStr(i + 2, s, ")") - (i + 2))
                gnProcesaVariable cmd, mGnComp, mSpTxt
                i = i + Len(cmd) + 2
            'si es otra linea
            ElseIf Asc(Mid$(s, i, 1)) = vbKeyReturn Then
                .PrintLine "", 1
            'Si no es un comando ni variable
            Else
                .PrintLine Mid$(s, i, 1)          'Manda un carácter a la impresora
                'Debug.Print Mid$(s, i, 1)
            End If
        Next i
    End With
    Exit Sub
ErrTrap:
    Err.Raise ERR_NOIMPRIME, App.EXEName, "Seccion Header: " & Err.Description

End Sub


Private Sub Class_Terminate()
    'Set mobjGNOp = Nothing
End Sub
