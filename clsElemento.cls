VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsElemento"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit

'Implements IGnComp

Private mGnComp As GNComprobante
Private mcol As New Collection
'Private mSpTxt As SiiPrint.PrintTxt
Private WithEvents mSpTxt As SiiPrint.PrintTxt
Attribute mSpTxt.VB_VarHelpID = -1

Dim rd As RolDetalle, Ele As Elementos
Dim RDaux  As RolDetalle

Private Type T_PROPS
    Texto As String
    Linea As Integer 'Numero  maximo de lineas
    CambioPag  As Boolean    'True = Cambio de pagina  cuando llega  al numero maximo
    objMain As PrintTrans
    ImpValNota As Boolean    'jeaa 02/09/04 True = Imprime datos del item nota
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
    'Dim tCant As Currency, tPrecio As Currency, tPrecioSinIVA As Currency, tIVA As Currency
    Dim nombreItem As String, suma As Currency, TotLineas As Long
    Dim cmd As String
    Dim codBodega As String
    Dim CountNumBodega As Integer
    Dim mBodega As Variant
    Dim OtraBodega As Boolean, k As Long
    Dim RESP As Integer, bandYaImprimio As Boolean
    Dim v As Variant
    On Error GoTo ErrTrap
    With mSpTxt
        s = mprops.Texto  'carga el texto
        numLinea = 0
        TotLineas = 0
        mNoEsItemNota = True
        CountNumBodega = 0
         'For i = 1 To mGnComp.CountRolDetalle
          '      Set RD = mGnComp.RolDetalle(i)
                        For j = 1 To Len(s)
                            'Si es un comando
                            If Mid$(s, j, 2) = "%(" Then
                                cmd = Mid$(s, j + 2, InStr(j + 2, s, ")") - (j + 2))
                                ProcesaComando cmd, mSpTxt
            
                                j = j + Len(cmd) + 2
                            'Si es una variable
                            ElseIf Mid$(s, j, 2) = "$(" Then
                                cmd = Mid$(s, j + 2, InStr(j + 2, s, ")") - (j + 2))
                                ProcesaVariable cmd, i, nombreItem
                                j = j + Len(cmd) + 2
                            'si es otra linea
                            ElseIf Asc(Mid$(s, j, 1)) = vbKeyReturn Then
                                .PrintLine "", 1
                                numLinea = numLinea + 1 '832095 f bravo
                                TotLineas = TotLineas + 1
                            'Si no es un comando ni variable
                            Else
                                .PrintLine Mid$(s, j, 1)          'Manda un carácter a la impresora
                            End If
                        Next j
            
                        If numLinea >= Me.Linea And Me.CambioPag = True Then
                            If TotLineas < mGnComp.CountIVKardex Then   'Solamente si no ha impreso la totalidad de ítems
                                .ImpSaltoPagina         'genera un  salto de pagina
                                numLinea = 0
                            End If
                        ElseIf numLinea >= Me.Linea And Me.CambioPag = False And Me.Linea > 0 Then
                            'Solamente deja de imprimir items
                            'Exit For
                        End If
        'Next i
        If numLinea < Me.Linea And Me.Linea > 0 Then
            .PrintLine "", Me.Linea - numLinea
        End If
    End With
    Exit Sub
    
ErrTrap:
    Err.Raise ERR_NOIMPRIME, App.EXEName, "Seccion Rol " & Err.Description
End Sub
Private Sub ProcesaVariable(cad As String, i As Long, nombreItem As String)
    Dim lon As Integer, v As Variant
    Dim deci  As Integer, fmt As String
    Dim rd As RolDetalle
    
    With mSpTxt
        v = Split(cad, ";")
        If IsEmpty(v) Then Exit Sub
        
        fmt = gfmt
        If UBound(v, 1) >= 1 Then lon = v(1)
        If UBound(v, 1) >= 2 Then fmt = generafmt(CStr(v(2)), CStr(v(0)))      'Subrutinapublica
        Select Case v(0)
            Case "NUMLIN":  .PrintLine .Rellenar(i, lon, False)
            Case "INGRESOS":
                For i = 1 To mGnComp.CountRolDetalle
                 Set rd = mGnComp.RolDetalle(i)
                    If (mGnComp.RolDetalle(i).tipo = 0 Or mGnComp.RolDetalle(i).tipo = 1 Or mGnComp.RolDetalle(i).tipo = 2) And mGnComp.RolDetalle(i).Imprimir Then
                    .PrintLine .Rellenar(rd.Codelemento, lon, True)
                    End If
                Next
            'Case "CODELEEGR": .PrintLine .Rellenar(rd.Codelemento, lon, True)
            'Case "DESCELEING": .PrintLine .Rellenar(RD.Descripcion, lon, True)
            'Case "DESCELEEGR": .PrintLine .Rellenar(Ele.Descripcion, lon, True)
            'Case "VALORING":
            '            .PrintLine .Rellenar(Format(Abs(rd.valor), fmt), lon, False)
            'Case "VALOREGR":
            '            .PrintLine .Rellenar(Format(Abs(rd.valor), fmt), lon, False)
        End Select
    End With
End Sub

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
    'jeaa 02/09/04 para que si no existe el parametro imprima normalmente
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


