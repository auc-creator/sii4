VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsDocXPagar"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private mGnComp As GNComprobante
Private mSpTxt As SiiPrint.PrintTxt
Dim Pck As PCKardex
Dim tsFCP As TSFormaCobroPago
Dim pcProvCli  As pcProvCli



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
    Dim s As String, cmd As String, numLinea As Long, TotLineas As Long
    On Error GoTo ErrTrap
    s = Me.Texto
    For i = 1 To mGnComp.CountPCKardex
        Set Pck = mGnComp.PCKardex(i)
        If Pck.IdAsignado = 0 And Pck.haber <> 0 Then     'Documentos por cobrar
            Set tsFCP = mGnComp.Empresa.RecuperaTSFormaCobroPago(Pck.codForma)
            Set pcProvCli = mGnComp.Empresa.RecuperaPCProvCli(Pck.CodProvCli)
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
                        TotLineas = TotLineas + 1
                    'Si no es un comando ni variable
                    Else
                        .PrintLine Mid$(s, j, 1)          'Manda un carácter a la impresora
                    End If
                Next j
                If numLinea >= Me.Linea And Me.CambioPag = True Then
                If TotLineas < mGnComp.CountPCKardex Then    'Solamente si no ha impreso la totalidad de ítems
                    .ImpSaltoPagina         'genera un  salto de pagina
                    numLinea = 0
                End If
                ElseIf numLinea >= Me.Linea And Me.CambioPag = False And Me.Linea > 0 Then
                    'Solamente deja de imprimir items
                    Exit For
                End If
            End With
        End If
    Next i
    If numLinea < Me.Linea And Me.Linea > 0 Then
        mSpTxt.PrintLine "", Me.Linea - numLinea
    End If
    Exit Sub
ErrTrap:
    Err.Raise ERR_NOIMPRIME, App.EXEName, "Seccion DocXPagar " & Err.Description
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
        Case "COD":  .PrintLine .Rellenar(Pck.codForma, lon, True)
        Case "DESC": .PrintLine .Rellenar(tsFCP.NombreForma, lon, True)
        Case "NUMDOC": .PrintLine .Rellenar(Pck.NumLetra, lon, False)
        Case "OBSERVA": .PrintLine .Rellenar(Pck.Observacion, lon, True)
        Case "FVENCI": .PrintLine .Rellenar(Format(Pck.FechaVenci, fmt), lon, True)
        Case "VALOR": .PrintLine .Rellenar(Format(Pck.haber, fmt), lon, False) 'JEAA para que sealinea a la derecha 06/12/04
        Case "CODPROV": .PrintLine .Rellenar(pcProvCli.CodProvCli, lon, True)
        Case "NOMPROV": .PrintLine .Rellenar(pcProvCli.Nombre, lon, True)
        End Select
    End With
End Sub


