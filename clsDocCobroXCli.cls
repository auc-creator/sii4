VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsDocCobroXCli"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit
Private mGnComp As GNComprobante
Private mSpTxt As SiiPrint.PrintTxt
Dim PCK  As PCKardex
Dim PCKaux  As PCKardex
Dim doc As PCDocAsignado


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
    Dim i As Long, j As Long, s As String, cmd As String
    Dim cancela As Double, numLinea As Long, TotLineas As Long
    Dim CODCLI As String
    On Error GoTo ErrTrap
    s = Me.Texto
    For i = 1 To mGnComp.CountPCKardex
        Set PCK = mGnComp.PCKardex(i)
        If i < mGnComp.CountPCKardex - 1 Then
            Set PCKaux = mGnComp.PCKardex(i + 1)
        End If
        CODCLI = PCK.CodProvCli
        'Solo imprimimos si el documento está asignado a un doc. origen
        'recibimos dinero del  cliente por tanto   va  al  haber
        If PCK.IdAsignado <> 0 And PCK.Haber <> 0 Then     'Cobros, IT
            cancela = (PCK.Debe + PCK.Haber)
            Set doc = PCK.RecuperaPCDocAsignado
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
                        If CODCLI <> PCKaux.CodProvCli Then   'Solamente si no ha impreso la totalidad de ítems
                            If TotLineas < mGnComp.CountPCKardex And CODCLI <> PCKaux.CodProvCli Then   'Solamente si no ha impreso la totalidad de ítems
                            .ImpSaltoPagina         'genera un  salto de pagina
                            numLinea = 0
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
        Case "NOMPC": .PrintLine .Rellenar(doc.NombreProvCli, lon, True)
        Case "TRANS":  .PrintLine .Rellenar(doc.trans, lon, True)
        Case "NUMDOC": .PrintLine .Rellenar(doc.doc, lon, False)
        'Case "VALORDOC": .PrintLine .Rellenar(Format(pck.Haber, fmt), lon, False)
        Case "VALORDOC": .PrintLine .Rellenar(Format(doc.valor, fmt), lon, False) ' jeaa 19-08-03  valor del documento no del debe
        Case "VALORCAN": .PrintLine .Rellenar(Format(cancela, fmt), lon, False)
        Case "SALDO": .PrintLine .Rellenar(Format(doc.saldo, fmt), lon, False)
        Case "FVENCI": .PrintLine .Rellenar(Format(doc.FechaVenci, fmt), lon, True)
        Case "SALDOANT":  .PrintLine .Rellenar(Format(doc.saldo + PCK.Haber, fmt), lon, False)
        End Select
    End With
End Sub






