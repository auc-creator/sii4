VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsivgrupo"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private mGnComp As GNComprobante
Private mcol As New Collection
Private WithEvents mSpTxt As SiiPrint.PrintTxt
Attribute mSpTxt.VB_VarHelpID = -1

Dim ivk As IVKardex, iv As IVInventario
Dim IvKaux  As IVKardex
Dim IVKOrdenBodega  As IVKardex

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
    Dim rsIvg As Recordset
    Dim rsdet As Recordset
    Dim rsRec As Recordset
    On Error GoTo ErrTrap
    With mSpTxt
        s = mprops.Texto  'carga el texto
        numLinea = 0
        TotLineas = 0
        mNoEsItemNota = True
                'carga items con iva
                
                'Impresion
                    Set rsdet = mGnComp.Empresa.RecuperaDetalleIvGrupo(mGnComp.FechaTrans, mGnComp.codUsuario, Parametros, True)
                     
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
                                ProcesaVariable cmd, i, nombreItem, rsdet, rsRec
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
    Set rsRec = Nothing
    Exit Sub
    
ErrTrap:
    Err.Raise ERR_NOIMPRIME, App.EXEName, "Seccion Items " & Err.Description
End Sub

Private Sub ProcesaVariable(cad As String, i As Long, codGrupo As String, rs As Recordset, rsRec As Recordset)
    Dim lon As Integer, v As Variant
    Dim deci  As Integer, fmt As String, ivg As IvGrupo
    Dim uni As IVUnidad
    Dim IVISO As IVInventario
    Dim rsdet As Recordset
    Dim rs1 As Recordset
    Dim rs2 As Recordset
    Dim TotIva As Currency
    Dim totSinIva As Currency
    Dim valorRec As Currency, valorIVA As Currency
    Dim rec As Currency

    'variables disponibles para  la seccion de Items
    With mSpTxt
        v = Split(cad, ";")
        If IsEmpty(v) Then Exit Sub
        fmt = gfmt
        If UBound(v, 1) >= 1 Then lon = v(1)
        If UBound(v, 1) >= 2 Then fmt = generafmt(CStr(v(2)), CStr(v(0)))      'Subrutinapublica
        Select Case v(0)
            Case "CODGRUPO"
                If rs.RecordCount <> 0 Then .PrintLine .Rellenar(rs!codGrupo, lon, True)
            Case "DESCGRUPO"
                If rs.RecordCount <> 0 Then .PrintLine .Rellenar(rs!Descripcion, lon, True)
            Case "PTCONIVA"
                 Set rsdet = mGnComp.Empresa.RecuperaDetalleIvGrupoPTIva(mGnComp.FechaTrans, mGnComp.codUsuario, Parametros, rs!codGrupo, True)
                    If rsdet.RecordCount <> 0 Then
                        .PrintLine .Rellenar(Abs(rsdet!ptiva), lon, False)
                    Else
                        .PrintLine .Rellenar(Format(0, fmt), lon, False)
                    End If
                 Set rsdet = Nothing
            Case "PTSINIVA"
                    Set rsdet = mGnComp.Empresa.RecuperaDetalleIvGrupoPTIva(mGnComp.FechaTrans, mGnComp.codUsuario, Parametros, rs!codGrupo, False)
                    If rsdet.RecordCount <> 0 Then
                        .PrintLine .Rellenar(Format(Abs(rsdet!ptiva), fmt), lon, False)
                    Else
                        .PrintLine .Rellenar(Format(0, fmt), lon, False)
                    End If
                 Set rsdet = Nothing
            Case "SUBT"
                    Set rs1 = mGnComp.Empresa.RecuperaDetalleIvGrupoPTIva(mGnComp.FechaTrans, mGnComp.codUsuario, Parametros, rs!codGrupo, True)
                    If rs1.RecordCount > 0 Then
                        TotIva = Abs(rs1!ptiva)
                    Else
                        TotIva = 0
                    End If
                    Set rs2 = mGnComp.Empresa.RecuperaDetalleIvGrupoPTIva(mGnComp.FechaTrans, mGnComp.codUsuario, Parametros, rs!codGrupo, False)
                    If rs2.RecordCount > 0 Then
                        totSinIva = Abs(rs2!ptiva)
                    Else
                        totSinIva = 0
                    End If
                    'aqui saca descuento
                    Set rsRec = mGnComp.Empresa.RecuperaDetalleIvRecarDesc(mGnComp.FechaTrans, mGnComp.codUsuario, Parametros, rs!codGrupo)
                    If rsRec.RecordCount > 0 Then
                        valorRec = Abs(rsRec!descu)
                    Else
                        valorRec = 0
                    End If
                    
                    .PrintLine .Rellenar(Format(Round(TotIva, 2) + Round(totSinIva, 2) - Round(valorRec, 2), fmt), lon, False)
                    Set rs1 = Nothing
                    Set rs2 = Nothing
            Case "TOT"
                    Set rs1 = mGnComp.Empresa.RecuperaDetalleIvGrupoPTIva(mGnComp.FechaTrans, mGnComp.codUsuario, Parametros, rs!codGrupo, True)
                    If rs1.RecordCount > 0 Then
                        TotIva = Abs(rs1!ptiva)
                    Else
                        TotIva = 0
                    End If
                    Set rs2 = mGnComp.Empresa.RecuperaDetalleIvGrupoPTIva(mGnComp.FechaTrans, mGnComp.codUsuario, Parametros, rs!codGrupo, False)
                    If rs2.RecordCount > 0 Then
                        totSinIva = Abs(rs2!ptiva)
                    Else
                        totSinIva = 0
                    End If
                    'desc
                    Set rsRec = mGnComp.Empresa.RecuperaDetalleIvRecarDesc(mGnComp.FechaTrans, mGnComp.codUsuario, Parametros, rs!codGrupo)
                    If rsRec.RecordCount > 0 Then
                        valorRec = Abs(rsRec!descu)
                        valorIVA = Abs(rsRec!valIva)
                    Else
                        valorRec = 0
                        valorIVA = 0
                    End If
                        .PrintLine .Rellenar(Format(Round(TotIva, 2) + Round(totSinIva, 2) - Round(valorRec, 2) + Round(valorIVA, 2), fmt), lon, False)
                    Set rs1 = Nothing
                    Set rs2 = Nothing
                    Set rsRec = Nothing
            Case "DESC"
                Set rsRec = mGnComp.Empresa.RecuperaDetalleIvRecarDesc(mGnComp.FechaTrans, mGnComp.codUsuario, Parametros, rs!codGrupo)
                If rsRec.RecordCount > 0 Then
                    .PrintLine .Rellenar(Format(Abs(rsRec!descu), fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(0, fmt), lon, True)
                End If
                Set rsRec = Nothing
            Case "IVA"
                Set rsRec = mGnComp.Empresa.RecuperaDetalleIvRecarDesc(mGnComp.FechaTrans, mGnComp.codUsuario, Parametros, rs!codGrupo)
                If rsRec.RecordCount > 0 Then
                    .PrintLine .Rellenar(Format(Abs(rsRec!valIva), fmt), lon, False)
                Else
                    .PrintLine .Rellenar(Format(0, fmt), lon, False)
                End If
                Set rsRec = Nothing
        End Select
        
        If Not (ivg Is Nothing) Then Set ivg = Nothing
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

