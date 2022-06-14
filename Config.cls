VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsConfig"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'22 Junio 2001 DIEGO M
'Diseño de nueva version
'Modificar  para que  soporte multiples  formatos

Private Type T_PROPS
    Modo As String  'T=Texto  G=Grafico
    numLinea As Integer
    IgnorarControl As Boolean 'False = No  ignora codigos  de control de impresora
    Texto As String
    HeaderTodo As Boolean

    '***Agregado ANGEL 12/Mayo/2003
    NombreImpresora As String
    LongitudCorte As Double
    '**** Ageregado jeaa 29/09/04
    MargenIzq As Integer 'para modificar nropiedad IndentLeft de SiiPrint
End Type
Dim mprops As T_PROPS

Public Property Let Texto(ByVal value As String)
    mprops.Texto = value
End Property

Public Property Get HeaderTodo() As Boolean
    HeaderTodo = mprops.HeaderTodo
End Property

Public Property Get Texto() As String
    Texto = mprops.Texto
End Property


Public Property Let Modo(ByVal value As String)
  If Len(value) > 1 Then
        Err.Raise ERR_INVALIDO, "Elementos.Modo", MSGERR_INVALIDO
    End If
    mprops.Modo = value
End Property

Public Property Get Modo() As String
    Modo = mprops.Modo
End Property

Public Property Let numLinea(ByVal value As Integer)
    mprops.numLinea = value
End Property

Public Property Get numLinea() As Integer
    numLinea = mprops.numLinea
End Property

Public Property Let IgnorarControl(ByVal value As Boolean)
    mprops.IgnorarControl = value
End Property

Public Property Get IgnorarControl() As Boolean
    IgnorarControl = mprops.IgnorarControl
End Property

Public Property Let NombreImpresora(ByVal value As String)
    mprops.NombreImpresora = value
End Property

Public Property Get NombreImpresora() As String
    NombreImpresora = mprops.NombreImpresora
End Property

Public Property Let LongitudCorte(ByVal value As Double)
    mprops.LongitudCorte = value
End Property

Public Property Get LongitudCorte() As Double
    LongitudCorte = mprops.LongitudCorte
End Property
'**** Ageregado jeaa 29/09/04
Public Property Let MargenIzq(ByVal value As Integer)
    mprops.MargenIzq = value
End Property

Public Property Get MargenIzq() As Integer
    MargenIzq = mprops.MargenIzq
End Property

Public Sub ActualizaValor(ByVal s As String)
    'Borra espacios en blanco y tabuladores
    's = BorraEspacios(s)
    'Carga las propiedades del objeto
    If InStr(1, s, "MODO") > 0 Then
        mprops.Modo = Trim$(Right(s, Len(s) - InStr(1, s, "=")))
    ElseIf InStr(1, s, "NUMLINEA") > 0 Then
        mprops.numLinea = CInt(Right(s, Len(s) - InStr(1, s, "=")))
    ElseIf InStr(1, s, "IGNORACONTROL") > 0 Then
        mprops.IgnorarControl = IIf(Right(s, Len(s) - InStr(1, s, "=")) = "T", True, False)
    ElseIf InStr(1, s, "HEADERTODO") > 0 Then
        mprops.HeaderTodo = IIf(InStr(Right(s, Len(s) - InStr(1, s, "=")), "T"), True, False)
    ElseIf InStr(1, s, "NOMBREIMPRESORA") > 0 Then
        mprops.NombreImpresora = Trim$(Right(s, Len(s) - InStr(1, s, "=")))
    ElseIf InStr(1, s, "LONGITUDCORTE") > 0 Then
        mprops.LongitudCorte = CDbl(Right(s, Len(s) - InStr(1, s, "=")))
    ElseIf InStr(1, s, "MARGENIZQ") > 0 Then
        '**** Ageregado jeaa 29/09/04
        mprops.MargenIzq = CInt(Right(s, Len(s) - InStr(1, s, "=")))
    End If
End Sub


Private Sub Class_Initialize()
    '**** Ageregado jeaa 29/09/04
    MargenIzq = 5 ' INICIALIZA CON ESTE VALOR PARA COMPATIBILIDAD DE  LIBRERIAS EXISTENTES
                              'PUEDE CAMBIASE PROPIEDAD DEL MARGEN IZQUIERDO
End Sub
    
