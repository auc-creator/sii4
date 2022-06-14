VERSION 5.00
Object = "{86CF1D34-0C5F-11D2-A9FC-0000F8754DA1}#2.0#0"; "MSCOMCT2.OCX"
Object = "{C4EBE568-AA77-11D3-8306-000021C5085D}#5.3#0"; "FlexCombo.ocx"
Object = "{BDC217C8-ED16-11CD-956C-0000C04E4C0A}#1.1#0"; "TABCTL32.OCX"
Begin VB.Form frmGuia 
   Appearance      =   0  'Flat
   BorderStyle     =   3  'Fixed Dialog
   Caption         =   "Guia de Remisión"
   ClientHeight    =   5370
   ClientLeft      =   30
   ClientTop       =   330
   ClientWidth     =   7875
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   5370
   ScaleWidth      =   7875
   ShowInTaskbar   =   0   'False
   StartUpPosition =   1  'CenterOwner
   Begin VB.TextBox txtNumFacturaSRI 
      Height          =   300
      Left            =   2280
      TabIndex        =   29
      Top             =   840
      Width           =   2655
   End
   Begin VB.TextBox txtNumDocImp 
      Height          =   300
      Left            =   6420
      TabIndex        =   6
      Top             =   480
      Width           =   1332
   End
   Begin VB.ComboBox cboMotivo 
      Height          =   315
      ItemData        =   "frmguia.frx":0000
      Left            =   2280
      List            =   "frmguia.frx":0016
      Style           =   2  'Dropdown List
      TabIndex        =   10
      Top             =   1140
      Width           =   2652
   End
   Begin TabDlg.SSTab SSTab1 
      Height          =   2775
      Left            =   60
      TabIndex        =   13
      Top             =   1860
      Width           =   7755
      _ExtentX        =   13679
      _ExtentY        =   4895
      _Version        =   393216
      Tabs            =   2
      Tab             =   1
      TabsPerRow      =   2
      TabHeight       =   420
      TabCaption(0)   =   "Destinatario"
      TabPicture(0)   =   "frmguia.frx":0073
      Tab(0).ControlEnabled=   0   'False
      Tab(0).Control(0)=   "txtLlegada"
      Tab(0).Control(1)=   "txtRucDest"
      Tab(0).Control(2)=   "txtNombreDest"
      Tab(0).Control(3)=   "Label1(9)"
      Tab(0).Control(4)=   "Label3"
      Tab(0).Control(5)=   "Label2"
      Tab(0).ControlCount=   6
      TabCaption(1)   =   "Transporte"
      TabPicture(1)   =   "frmguia.frx":008F
      Tab(1).ControlEnabled=   -1  'True
      Tab(1).Control(0)=   "Label1(7)"
      Tab(1).Control(0).Enabled=   0   'False
      Tab(1).Control(1)=   "Label1(6)"
      Tab(1).Control(1).Enabled=   0   'False
      Tab(1).Control(2)=   "Label1(8)"
      Tab(1).Control(2).Enabled=   0   'False
      Tab(1).Control(3)=   "fcbProv"
      Tab(1).Control(3).Enabled=   0   'False
      Tab(1).Control(4)=   "txtNombreTrans"
      Tab(1).Control(4).Enabled=   0   'False
      Tab(1).Control(5)=   "txtRucTrans"
      Tab(1).Control(5).Enabled=   0   'False
      Tab(1).Control(6)=   "chkTransporte"
      Tab(1).Control(6).Enabled=   0   'False
      Tab(1).Control(7)=   "fraTransportista"
      Tab(1).Control(7).Enabled=   0   'False
      Tab(1).ControlCount=   8
      Begin VB.Frame fraTransportista 
         Height          =   1155
         Left            =   60
         TabIndex        =   32
         Top             =   1500
         Width           =   7455
         Begin VB.CheckBox chkChofer 
            Caption         =   "Transportista Propio de la Empresa"
            Height          =   195
            Left            =   60
            TabIndex        =   39
            Top             =   780
            Width           =   2835
         End
         Begin VB.TextBox txtNombreChofer 
            Height          =   300
            Left            =   60
            TabIndex        =   36
            Top             =   360
            Width           =   4335
         End
         Begin VB.TextBox txtPlaca 
            Height          =   300
            Left            =   4440
            TabIndex        =   35
            Top             =   360
            Width           =   2892
         End
         Begin FlexComboProy.FlexCombo fcbTransp 
            Height          =   300
            Left            =   4440
            TabIndex        =   33
            Top             =   720
            Width           =   2895
            _ExtentX        =   5106
            _ExtentY        =   529
            Enabled         =   0   'False
            ColWidth1       =   2400
            BeginProperty Font {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
               Name            =   "MS Sans Serif"
               Size            =   8.25
               Charset         =   0
               Weight          =   400
               Underline       =   0   'False
               Italic          =   0   'False
               Strikethrough   =   0   'False
            EndProperty
         End
         Begin VB.Label Label1 
            AutoSize        =   -1  'True
            Caption         =   "PLACA"
            Height          =   195
            Index           =   14
            Left            =   4560
            TabIndex        =   38
            Top             =   120
            Width           =   510
         End
         Begin VB.Label Label1 
            AutoSize        =   -1  'True
            Caption         =   "Nombre Transportista"
            Height          =   195
            Index           =   13
            Left            =   60
            TabIndex        =   37
            Top             =   120
            Width           =   1515
         End
         Begin VB.Label Label1 
            AutoSize        =   -1  'True
            Caption         =   "Transportista "
            Height          =   195
            Index           =   12
            Left            =   3360
            TabIndex        =   34
            Top             =   780
            Width           =   960
         End
      End
      Begin VB.CheckBox chkTransporte 
         Caption         =   "Transporte Propio de la Empresa"
         Height          =   195
         Left            =   120
         TabIndex        =   31
         Top             =   960
         Width           =   3435
      End
      Begin VB.TextBox txtLlegada 
         Height          =   300
         Left            =   -74760
         TabIndex        =   19
         Top             =   1320
         Width           =   7395
      End
      Begin VB.TextBox txtRucDest 
         Height          =   300
         Left            =   -70260
         TabIndex        =   17
         Top             =   600
         Width           =   2892
      End
      Begin VB.TextBox txtNombreDest 
         Height          =   300
         Left            =   -74760
         TabIndex        =   15
         Top             =   600
         Width           =   4455
      End
      Begin VB.TextBox txtRucTrans 
         Height          =   300
         Left            =   4560
         TabIndex        =   23
         Top             =   600
         Width           =   2892
      End
      Begin VB.TextBox txtNombreTrans 
         Height          =   300
         Left            =   120
         TabIndex        =   21
         Top             =   600
         Width           =   4335
      End
      Begin FlexComboProy.FlexCombo fcbProv 
         Height          =   300
         Left            =   4560
         TabIndex        =   25
         Top             =   1140
         Width           =   2895
         _ExtentX        =   5106
         _ExtentY        =   529
         ColWidth1       =   2400
         BeginProperty Font {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
            Name            =   "MS Sans Serif"
            Size            =   8.25
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
      End
      Begin VB.Label Label1 
         AutoSize        =   -1  'True
         Caption         =   "Punto de Llegada  (Dirección del cliente)"
         Height          =   195
         Index           =   9
         Left            =   -74880
         TabIndex        =   18
         Top             =   1080
         Width           =   2880
      End
      Begin VB.Label Label3 
         AutoSize        =   -1  'True
         Caption         =   "RUC"
         Height          =   195
         Left            =   -70260
         TabIndex        =   16
         Top             =   360
         Width           =   345
      End
      Begin VB.Label Label2 
         AutoSize        =   -1  'True
         Caption         =   "Nombre  "
         Height          =   192
         Left            =   -74880
         TabIndex        =   14
         Top             =   360
         Width           =   660
      End
      Begin VB.Label Label1 
         AutoSize        =   -1  'True
         Caption         =   "Seleccionar Proveedor"
         Height          =   195
         Index           =   8
         Left            =   4560
         TabIndex        =   24
         Top             =   900
         Width           =   1620
      End
      Begin VB.Label Label1 
         AutoSize        =   -1  'True
         Caption         =   "Nombre  "
         Height          =   192
         Index           =   6
         Left            =   120
         TabIndex        =   20
         Top             =   360
         Width           =   660
      End
      Begin VB.Label Label1 
         AutoSize        =   -1  'True
         Caption         =   "RUC "
         Height          =   195
         Index           =   7
         Left            =   4620
         TabIndex        =   22
         Top             =   360
         Width           =   510
      End
   End
   Begin VB.CommandButton cmdCancelar 
      Cancel          =   -1  'True
      Caption         =   "&Cancelar"
      Height          =   372
      Left            =   3960
      TabIndex        =   27
      Top             =   4740
      Width           =   1212
   End
   Begin VB.CommandButton cmdAceptar 
      Caption         =   "&Aceptar"
      Height          =   372
      Left            =   2640
      TabIndex        =   26
      Top             =   4740
      Width           =   1212
   End
   Begin VB.TextBox txtPartida 
      Height          =   300
      Left            =   2280
      TabIndex        =   12
      Top             =   1500
      Width           =   5475
   End
   Begin VB.TextBox txtNumDocRef 
      Height          =   300
      Left            =   6420
      TabIndex        =   5
      Top             =   120
      Width           =   1332
   End
   Begin MSComCtl2.DTPicker dtpFechaTrans 
      Height          =   300
      Left            =   2280
      TabIndex        =   1
      Top             =   120
      Width           =   1332
      _ExtentX        =   2355
      _ExtentY        =   529
      _Version        =   393216
      Format          =   51773441
      CurrentDate     =   36938
   End
   Begin MSComCtl2.DTPicker dtpFechaEmi 
      Height          =   300
      Left            =   6420
      TabIndex        =   8
      Top             =   840
      Width           =   1335
      _ExtentX        =   2355
      _ExtentY        =   529
      _Version        =   393216
      Format          =   51773441
      CurrentDate     =   36938
   End
   Begin MSComCtl2.DTPicker dtpFechaTermi 
      Height          =   300
      Left            =   2280
      TabIndex        =   3
      Top             =   480
      Width           =   1335
      _ExtentX        =   2355
      _ExtentY        =   529
      _Version        =   393216
      Format          =   51773441
      CurrentDate     =   36938
   End
   Begin VB.Label Label1 
      AutoSize        =   -1  'True
      Caption         =   "Numero Factura"
      Height          =   195
      Index           =   11
      Left            =   120
      TabIndex        =   30
      Top             =   900
      Width           =   1320
   End
   Begin VB.Label Label1 
      AutoSize        =   -1  'True
      Caption         =   "Comprobante Importado  "
      Height          =   195
      Index           =   10
      Left            =   4560
      TabIndex        =   28
      Top             =   540
      Width           =   1785
   End
   Begin VB.Label Label1 
      AutoSize        =   -1  'True
      Caption         =   "Punto de Partida  "
      Height          =   195
      Index           =   5
      Left            =   120
      TabIndex        =   11
      Top             =   1560
      Width           =   1260
   End
   Begin VB.Label Label1 
      AutoSize        =   -1  'True
      Caption         =   "Motivo del Traslado  "
      Height          =   195
      Index           =   4
      Left            =   120
      TabIndex        =   9
      Top             =   1200
      Width           =   1455
   End
   Begin VB.Label Label1 
      AutoSize        =   -1  'True
      Caption         =   "Fecha de Emisión  "
      Height          =   195
      Index           =   3
      Left            =   4980
      TabIndex        =   7
      Top             =   900
      Width           =   1365
   End
   Begin VB.Label Label1 
      AutoSize        =   -1  'True
      Caption         =   "F. Terminación de Traslado  "
      Height          =   195
      Index           =   2
      Left            =   120
      TabIndex        =   2
      Top             =   540
      Width           =   2070
   End
   Begin VB.Label Label1 
      AutoSize        =   -1  'True
      Caption         =   "Comprobante de Venta  "
      Height          =   195
      Index           =   1
      Left            =   4620
      TabIndex        =   4
      Top             =   180
      Width           =   1740
   End
   Begin VB.Label Label1 
      AutoSize        =   -1  'True
      Caption         =   "F. Iniciación de Traslado  "
      Height          =   195
      Index           =   0
      Left            =   120
      TabIndex        =   0
      Top             =   180
      Width           =   1830
   End
End
Attribute VB_Name = "frmGuia"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private mAceptado As Boolean
Private objGNComp As GNComprobante
Private objGNCompref As GNComprobante
Dim emp As String  'formato de  Guia  de remision


Public Sub Inicio(ByVal gc As GNComprobante)
    Set objGNComp = gc
    Visualizar
    Me.Show vbModal
   
    If mAceptado Then
        GuardarCondicion
        GUIAREMISION = 1
        'salir para impresión
    End If
    Unload Me
End Sub

Public Function CargarCboMotivo(ByRef cad As String)
    Dim i As Long, v As Variant
    v = Split(cad, ",")
    cboMotivo.Clear
    For i = 0 To UBound(v, 1)
        cboMotivo.AddItem v(i)
    Next i
    cboMotivo.ListIndex = 0
End Function

Private Sub Visualizar()
    Dim gc As GNComprobante
        Dim cli As pcProvCli
        Set cli = objGNComp.Empresa.RecuperaPCProvCli(objGNComp.CodClienteRef)
        If Not (cli Is Nothing) Then
            txtNombreDest.Text = cli.Nombre
            txtRucDest.Text = cli.RUC
            txtLlegada.Text = cli.Direccion1 & " - " & cli.Ciudad
        End If
        Set cli = Nothing
        txtNumDocRef.Text = objGNComp.CodTrans & " " & objGNComp.NumTrans
        Set gc = objGNComp.Empresa.RecuperaGNComprobante(objGNComp.IdTransFuente)
        If Not gc Is Nothing Then
            txtNumDocImp.Text = gc.CodTrans & " " & gc.NumTrans
            txtNumFacturaSRI.Text = gc.NumSerieEstaSRI & "-" & gc.NumSeriePuntoSRI & "-" & Right$("000000000" & gc.NumTrans, 9)
        End If
        Set gc = Nothing
End Sub


Private Sub GuardarCondicion()
    FECINITRASL = IIf(Not (IsNull(dtpFechaTrans.value)), dtpFechaTrans.value, Date)
    FECFINTRASL = IIf(Not (IsNull(dtpFechaTermi.value)), dtpFechaTermi.value, Date)
    FECEMISION = IIf(Not (IsNull(dtpFechaEmi.value)), dtpFechaEmi.value, Date)
    COMPVTA = txtNumDocRef.Text
    MOTIVTRASLSELEC = cboMotivo.Text
    INDMOTIV = cboMotivo.ListIndex
    PTOPART = txtPartida.Text
    PTOLLEG = txtLlegada.Text
    NOMDEST = txtNombreDest.Text
    RUCDEST = txtRucDest.Text
    NOMTRANSP = txtNombreTrans.Text
    RUCTRANSP = txtRucTrans.Text
    COMPIMP = txtNumDocImp.Text
    NUMFACTSRI = txtNumFacturaSRI.Text
    'NOMCHOFER = txtNombreTrans.Text
    NOMCHOFER = txtNombreChofer.Text
    PLACA = txtPlaca.Text
End Sub

Private Sub chkChofer_Click()
    If chkChofer.value = vbChecked Then
        fcbTransp.Enabled = True
    Else
        fcbTransp.Enabled = False
    End If
End Sub

Private Sub chkTransporte_Click()
    If chkTransporte.value = vbChecked Then
        txtNombreTrans.Text = objGNComp.Empresa.GNOpcion.RazonSocial
        txtRucTrans.Text = objGNComp.Empresa.GNOpcion.RUC
        fcbProv.Enabled = False
        txtNombreTrans.Enabled = False
        txtRucTrans.Enabled = False
    Else
        txtNombreTrans.Text = ""
        txtRucTrans.Text = ""
        fcbProv.Enabled = True
        txtNombreTrans.Enabled = True
        txtRucTrans.Enabled = True
    End If

End Sub

Private Sub cmdAceptar_Click()
    If cboMotivo.ListIndex < 0 Then
        MsgBox "Seleccione el Motivo de Traslado.", vbExclamation
        cboMotivo.SetFocus
        Exit Sub
    End If

    mAceptado = True
    Me.Hide
End Sub

Private Sub cmdCancelar_Click()
    mAceptado = False
    GUIAREMISION = 2
    Me.Hide
End Sub

Private Sub fcbProv_Selected(ByVal Text As String, ByVal KeyText As String)
    Dim pc As pcProvCli
    On Error GoTo ErrTrap
    
    Set pc = objGNComp.Empresa.RecuperaPCProvCli(KeyText)
    If Not (pc Is Nothing) Then
        txtNombreTrans.Text = pc.Nombre
        txtRucTrans.Text = pc.RUC
    End If
    Set pc = Nothing
    Exit Sub
ErrTrap:
    Set pc = Nothing
    MsgBox Err.Description
    Exit Sub
End Sub

Private Sub fcbTransp_Selected(ByVal Text As String, ByVal KeyText As String)
    Dim gntrp As GNTransporte
    On Error GoTo ErrTrap
    
    Set gntrp = objGNComp.Empresa.RecuperaGNTransporte(KeyText)
    If Not (gntrp Is Nothing) Then
        txtNombreChofer.Text = gntrp.Descripcion
    End If
    Set gntrp = Nothing
    Exit Sub
ErrTrap:
    Set gntrp = Nothing
    MsgBox Err.Description
    Exit Sub

End Sub

Private Sub Form_Activate()
    Screen.MousePointer = vbNormal
End Sub

Private Sub Form_Load()
    Dim NumTrans As String, gnt As GNTrans, gnsuc As GNSucursal
    CargarCboMotivo (MOTIVTRASL)
    dtpFechaTrans.value = Date
    dtpFechaTermi.value = Date
    dtpFechaEmi.value = Date
    fcbProv.SetData objGNComp.Empresa.ListaPCProvCli(True, False, False)
    fcbTransp.SetData objGNComp.Empresa.ListaGNTransporte(True, False)
    Set gnt = objGNComp.Empresa.RecuperaGNTrans(objGNComp.CodTrans)
    Set gnsuc = objGNComp.Empresa.RecuperaGNSucursal(gnt.CodSucursal)
    If Not gnsuc Is Nothing Then
        txtPartida.Text = gnsuc.Direccion
    Else
        txtPartida.Text = objGNComp.Empresa.GNOpcion.Direccion1
    End If
    
'            If Len(objGNComp.Empresa.GNOpcion.ObtenerValor("ImportaDatosFactura")) > 0 Then
'                If objGNComp.Empresa.GNOpcion.ObtenerValor("ImportaDatosFactura") > 0 Then
'                    txtNumFacturaSRI.Text = objGNComp.NumSerieEstaSRI & "-" & objGNComp.NumSeriePuntoSRI & "-" & Right$("000000000" & Int(objGNComp.NumDocRef), 9)
'                Else
'                     txtNumFacturaSRI.Text = objGNComp.NumSerieEstaSRI & "-" & objGNComp.NumSeriePuntoSRI & "-" & Right$("000000000" & Int(objGNComp.NumTrans), 9)
'                 End If
'            Else
'                txtNumFacturaSRI.Text = objGNComp.NumSerieEstaSRI & "-" & objGNComp.NumSeriePuntoSRI & "-" & Right$("000000000" & Int(objGNComp.NumTrans), 9)
'            End If
'
'    txtNumFacturaSRI.Text = objGNComp.NumSerieEstaSRI & "-" & objGNComp.NumSeriePuntoSRI & "-" & Right$("000000000" & Int(objGNComp.NumDocRef), 9)
End Sub

Private Sub Form_Terminate()
    If GUIAREMISION = 2 Then GUIAREMISION = 0
End Sub

Private Sub Form_Unload(Cancel As Integer)
    Set objGNComp = Nothing
End Sub

