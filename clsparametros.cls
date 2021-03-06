VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsParametros"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Type T_PROPS
    NomVar As String
End Type
Dim mprops As T_PROPS
Dim mcolParam As New Collection

Public Property Let NomVar(ByVal value As String)
    mprops.NomVar = value
End Property

Public Property Get NomVar() As String
    NomVar = mprops.NomVar
End Property

Public Property Let Parametros(ByVal value As String)
    mcolParam.Add value   'Ejm: "1,x,5", osea conjuntos de par�metros horizontales
End Property

Public Function RecuperaParametro(ByVal i As Long) As String
    'Debe recuperar de acuerdo al nombre de la variable?  --> no
    'o m�s bien esta ser� hija de una colecci�n -> si: se acceder� hasta aqu� conociendo exactamente cu�l es la variable en cuesti�n
    RecuperaParametro = mcolParam.Item(i)
End Function

Public Property Get CountParametros() As Long
    CountParametros = mcolParam.Count
End Property
'Alex Jun/2002
Public Sub ActualizaParametros(ByVal s As String)
    Dim cad As String
    'carga los par�metros de la variable "X" contenida en esta instancia
    If InStr(1, s, "(") > 0 Then        'Antes de ello, estar�a el nombre de la variable, y despu�s el primer grupo de par�metros
        'Recuerda: esta clase ser� parte de una colecci�n controlada desde PrintTrans
'        mprops.NomVar = Trim$(Left(s, Len(s) - InStr(1, s, "(")))
        cad = Trim$(Right(s, Len(s) - InStr(1, s, "(")))
        If Mid(cad, Len(cad), 1) = ")" Then cad = Mid(cad, 1, Len(cad) - 1)
        Me.Parametros = cad
    ElseIf InStr(1, s, ")") > 0 Then    'Antes del cierre estar�a el �ltimo grupo de par�metros
        cad = Trim$(Left(s, Len(s) - InStr(1, s, "(")))
        If Mid(cad, Len(cad), 1) = ")" Then cad = Mid(cad, 1, Len(cad) - 1)
        Me.Parametros = cad
    Else
        'En este rango se encontrar�an el grupo de par�metros escritos en "soledad" (segundo,tercer grupo)
        mcolParam.Add Trim$(s)
    End If
End Sub
