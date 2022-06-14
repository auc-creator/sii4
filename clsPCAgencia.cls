VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsPCAgencia"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit

'Private pcSol As PCSOLCREProvCli
'Private objPC As pcProvCli
Private mGnComp As GNComprobante
Private mcol As New Collection
Private WithEvents mSpTxt As SiiPrint.PrintTxt
Attribute mSpTxt.VB_VarHelpID = -1

Dim pca As PCAGencia


Private Type T_PROPS
    Texto As String
    Linea As Integer
    CambioPag  As Boolean
    objMain As PrintTrans
    ImpValNota As Boolean
    Parametros  As String
End Type

Dim numLinea
Dim mprops As T_PROPS
Dim mNoEsItemNota As Boolean


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

Public Property Get ImpValNota() As Boolean
    ImpValNota = mprops.ImpValNota
End Property

Public Property Let ImpValNota(value As Boolean)
    mprops.ImpValNota = value
End Property

Public Sub PrintSection()
    Dim i As Long, j As Long, s As String
    Dim nombreItem As String, suma As Currency, TotLineas As Long
    Dim cmd As String
    Dim BandIva As Boolean
    
    Dim v As Variant
    Dim rsdet As Recordset
    On Error GoTo ErrTrap
    With mSpTxt
        s = mprops.Texto  'carga el texto
        numLinea = 0
        TotLineas = 0
        mNoEsItemNota = True
                'carga items con iva
                
                'Impresion
                    'Set rsdet = pcSol.Empresa.RSPCAgenciaxPC(pcSol.IdProvCli)
                    Set rsdet = mGnComp.Empresa.RSPCAgenciaxPC(mGnComp.IdClienteRef)
                     
                    Do While Not rsdet.EOF
                        For j = 1 To Len(s)
                            'Si es un comando
                            If Mid$(s, j, 2) = "%(" Then
                                cmd = Mid$(s, j + 2, InStr(j + 2, s, ")") - (j + 2))
                                ProcesaComando cmd, mSpTxt
                                j = j + Len(cmd) + 2
                            'Si es una variable
                            ElseIf Mid$(s, j, 2) = "$(" Then
                                cmd = Mid$(s, j + 2, InStr(j + 2, s, ")") - (j + 2))
                                ProcesaVariable cmd, i, nombreItem, rsdet
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
                    rsdet.MoveNext
                    Loop
                      
        If numLinea < Me.Linea And Me.Linea > 0 Then
            .PrintLine "", Me.Linea - numLinea
        End If
        
    End With
    Set rsdet = Nothing
    Exit Sub
ErrTrap:
    Err.Raise ERR_NOIMPRIME, App.EXEName, "Seccion Items " & Err.Description
End Sub

Private Sub ProcesaVariable(cad As String, i As Long, codGrupo As String, rs As Recordset)
    Dim lon As Integer, v As Variant
    Dim fmt As String
    'variables disponibles para  la seccion de Items
    With mSpTxt
        v = Split(cad, ";")
        If IsEmpty(v) Then Exit Sub
        fmt = gfmt
        If UBound(v, 1) >= 1 Then lon = v(1)
        If UBound(v, 1) >= 2 Then fmt = generafmt(CStr(v(2)), CStr(v(0)))      'Subrutinapublica
        Select Case v(0)
            Case "AGECOD"
                    If rs.RecordCount <> 0 Then
                        .PrintLine .Rellenar(rs!CodAgencia, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                 
            Case "AGEDESC"
                If rs.RecordCount <> 0 Then
                        .PrintLine .Rellenar(rs!Descripcion, lon, True)
                    Else
                        .PrintLine .Rellenar("", lon, True)
                    End If
                    
            Case "AGECIU"
                If rs.RecordCount <> 0 Then .PrintLine .Rellenar(rs!ciudad, lon, True)
                
            Case "AGEDIR"
                If rs.RecordCount <> 0 Then .PrintLine .Rellenar(rs!direccion, lon, True)
            Case "AGETEL"
                 If rs.RecordCount <> 0 Then .PrintLine .Rellenar(rs!telefono, lon, True)
            
            Case "AGECONTAC"
                    If rs.RecordCount <> 0 Then .PrintLine .Rellenar(rs!contacto, lon, True)
        End Select
    End With
End Sub

Public Property Set SolPC(ByVal Sol As Sii4A32.PCSOLCREProvCli)
    'Set pcSol = Sol 'AUC Anulado ya no necesito para sol. credito
End Property
Public Property Set GNC(ByVal gc As Sii4A32.GNComprobante)
    Set mGnComp = gc
End Property

Public Property Set Sptxt(ByVal Sptxt As SiiPrint.PrintTxt)
    Set mSpTxt = Sptxt
End Property


Friend Property Set PrintTransMain(ByVal newObj As PrintTrans)
    Set mprops.objMain = newObj
End Property

Public Property Get PrintTransMain() As PrintTrans
    Set PrintTransMain = mprops.objMain
End Property


Private Sub Class_Initialize()
    numLinea = 0
    ImpValNota = True
   Me.CambioPag = False
End Sub

Private Sub mSpTxt_NuevaPagina()
    'PrintTransMain.NuevaPagina
    'PrintTransMain.NuevaPagina
End Sub

Public Property Let Parametros(value As String)
    mprops.Parametros = value
End Property

Public Property Get Parametros() As String
  Parametros = mprops.Parametros
End Property




