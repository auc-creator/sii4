VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsCredito"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'Para documentos creditos AUC 04/10/07
Private mGnComp As GNComprobante
Private WithEvents mSpTxt As SiiPrint.PrintTxt
Attribute mSpTxt.VB_VarHelpID = -1
Dim Pck As PCKardex

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
    Dim bandImprimio As Boolean
    On Error GoTo ErrTrap
    s = Me.Texto
    For i = 1 To mGnComp.CountPCKardex
        Set Pck = mGnComp.PCKardex(i)
                    
            If Pck.codForma <> Me.Parametros Then GoTo CONTINUA    'Para revisar el siguiente documento
            'Impresion
            If Not bandImprimio Then
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
                        ProcesaVariable cmd, i ' AUC HABILITADO PROCEDIMIENTO PARA IMPRIMIR LETRAS DE CAMBIO LIRA
                        j = j + Len(cmd) + 2
                    'si es otra linea
                        ElseIf Asc(Mid$(s, j, 1)) = vbKeyReturn Then
                            .PrintLine "", 1
                    'Si no es un comando ni variable
                        Else
                            .PrintLine Mid$(s, j, 1)          'Manda un carácter a la impresora
                            bandImprimio = True
                        End If
                    Next j
                
                'problema de impresion de vario cheques sueltos
                    If mprops.CambioPag Then
                        mSpTxt.ImpSaltoPagina         'genera un  salto de pagina
                    End If
                End With
            End If
CONTINUA:   'Pasa a revisar el siguiente documento
    Next i
    Exit Sub
ErrTrap:
    Err.Raise ERR_NOIMPRIME, App.EXEName, "Seccion Credito  " & Err.Description
End Sub


Private Sub Class_Terminate()
    Set Pck = Nothing
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
          '  Case "NUMLIN": .PrintLine .Rellenar(numlin, lon, True)
           ' Case "COD":  .PrintLine .Rellenar(Pck.codForma, lon, True)
           ' Case "DESC": .PrintLine .Rellenar(tsFCP.NombreForma, lon, True)
           ' Case "NUMDOC": .PrintLine .Rellenar(Pck.NumLetra, lon, False)
           ' Case "OBSERVA": .PrintLine .Rellenar(Pck.Observacion, lon, True)
           ' Case "FEMISION": .PrintLine .Rellenar(Format(Pck.FechaEmision, fmt), lon, True)
            Case "FVENCI": .PrintLine .Rellenar(Format(Pck.FechaVenci, fmt), lon, True)
           ' Case "VALOR": .PrintLine .Rellenar(Format(Pck.debe, fmt), lon, False) ''JEAA para que sealinea a la derecha 06/12/04
            'Case "CODCLI": .PrintLine .Rellenar(pcProvCli.CodProvCli, lon, True)
            'Case "NOMCLI": .PrintLine .Rellenar(pcProvCli.nombre, lon, True)
            
            'Case "CODBANCO":
            '        .PrintLine .Rellenar(Pck.CodBanco, lon, True)
            'Case "DESCBANCO":
            '        .PrintLine .Rellenar(Banco.Descripcion, lon, True)
            'Case "CODTARJETA":
            '        .PrintLine .Rellenar(Pck.CodTarjeta, lon, True)
            'Case "DESCTARJETA":
            '        .PrintLine .Rellenar(Tarjeta.Descripcion, lon, True)
            'Case "NUMCHEQUE": .PrintLine .Rellenar(Pck.numCheque, lon, True)
            'Case "NUMCUENTA": .PrintLine .Rellenar(Pck.NumCuenta, lon, True)
            'Case "TITULAR": .PrintLine .Rellenar(Pck.TitularCta, lon, True)
            'Case "PLAZO":      .PrintLine .Rellenar(DateDiff("d", Pck.FechaEmision, Pck.FechaVenci), lon, True)
        End Select
    End With
End Sub

