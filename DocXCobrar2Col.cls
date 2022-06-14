VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsDocXCobrar2Col"
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
Dim Tarjeta  As IVTarjeta
Dim Banco As IVBanco

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
    'borramos todo pckardex
    For i = mGnComp.CountPCKardex To 1 Step -1
        mGnComp.RemovePCKardex2Col (i)
    Next
    For i = 1 To mGnComp.CountPCKardex2col
        Set Pck = mGnComp.PCKardex(i)
      '  If Pck.IdAsignado = 0 And Pck.DebeImPar <> 0 Then       'Documentos por cobrar
'            Set tsFCP = mGnComp.Empresa.RecuperaTSFormaCobroPago(Pck.codForma)
'            Set pcProvCli = mGnComp.Empresa.RecuperaPCProvCli(Pck.CodProvCli)
'            If Len(Pck.CodTarjeta) > 0 Then
'                Set Tarjeta = mGnComp.Empresa.RecuperaIVTarjeta(Pck.CodTarjeta)
'            End If
'            If Len(Pck.CodBanco) > 0 Then
'                Set Banco = mGnComp.Empresa.RecuperaIVBanco(Pck.CodBanco)
'            End If
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
        'End If
    Next i
    If numLinea < Me.Linea And Me.Linea > 0 Then
        mSpTxt.PrintLine "", Me.Linea - numLinea
    End If
    Exit Sub
ErrTrap:
    Err.Raise ERR_NOIMPRIME, App.EXEName, "Seccion DocxCobrar " & Err.Description

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
            Case "VALORPAR":
                If Pck.debepar <> 0 Then
                    .PrintLine .Rellenar(Format(Pck.debepar, fmt), lon, False)
                End If
                
            Case "VALORIMPAR":
                If Pck.DebeImPar <> 0 Then
                    .PrintLine .Rellenar(Format(Pck.DebeImPar, fmt), lon, False)
                End If
            Case "CODPAR":
                .PrintLine .Rellenar(Pck.CodFormaPar, lon, True)
            Case "CODIMPAR":
                .PrintLine .Rellenar(Pck.CodFormaImPar, lon, True)
            Case "FVENCIPAR":
                If Pck.FechaVenciPar <> "00:00:00" Then
                    .PrintLine .Rellenar(Format(Pck.FechaVenciPar, fmt), lon, True)
                End If
            Case "FVENCIIMPAR":
                If Pck.FechaVenciImPar <> "00:00:00" Then
                    .PrintLine .Rellenar(Format(Pck.FechaVenciImPar, fmt), lon, True)
                End If
            Case "ORDENPAR": .PrintLine .Rellenar(Pck.OrdenPar, lon, True)
            Case "ORDENIMPAR": .PrintLine .Rellenar(Pck.OrdenImPar, lon, True)
            Case "CUOTA": .PrintLine .Rellenar(Pck.CUOTA, lon, True)
        End Select
    End With
End Sub

