VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Elementos"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit


Private Type T_PROPS
    Modo As String  'T=Texto  G=Grafico
    NumLinea As Integer
    IgnorarControl As Boolean 'False = No  ignora codigos  de control de impresora
    Header_Todo As Boolean   'True= Habilita cabecera en todas las paginas
    Item_Linea As Integer 'Numero  maximo de lineas
    Item_CambioPag  As Boolean    'True = Cambio de pagina  cuando llega  al numero maximo
    Recargo_Linea As Integer
    Recargo_ValorAcum As String  'PTOTAL ; CTOTAL
    Recargo_CambioPag As Boolean
    DocXCobrar_Linea As Integer
    DocXCobrar_CambioPag As Boolean
    DocXPagar_Linea As Integer
    DocXPagar_CambioPag As Boolean
    DocCobro_Linea As Integer
    DocCobro_CambioPag As Boolean
    DocPago_Linea As Integer
    DocPago_CambioPag As Boolean
    DocBanco_Linea As Integer
    DocBanco_CambioPag As Boolean
    Asiento_Linea As Integer
    Asiento_CambioPag As Boolean
End Type
Dim mprops As T_PROPS



Public Property Let DocBanco_CambioPag(value As Boolean)
    mprops.DocBanco_CambioPag = value
End Property

Public Property Get DocBanco_CambioPag() As Boolean
    DocBanco_CambioPag = mprops.DocPago_CambioPag
End Property

Public Property Let DocBanco_Linea(ByVal value As Integer)
    mprops.DocBanco_Linea = value
End Property

Public Property Get DocBanco_Linea() As Integer
    DocBanco_Linea = mprops.DocBanco_Linea
End Property

Public Property Let DocPago_CambioPag(value As Boolean)
    mprops.DocPago_CambioPag = value
End Property

Public Property Get DocPago_CambioPag() As Boolean
    DocPago_CambioPag = mprops.DocPago_CambioPag
End Property

Public Property Let DocPago_Linea(ByVal value As Integer)
    mprops.DocPago_Linea = value
End Property

Public Property Get DocPago_Linea() As Integer
    DocPago_Linea = mprops.DocPago_Linea
End Property



Public Property Let DocCobro_CambioPag(value As Boolean)
    mprops.DocCobro_CambioPag = value
End Property

Public Property Get DocCobro_CambioPag() As Boolean
    DocCobro_CambioPag = mprops.DocCobro_CambioPag
End Property

Public Property Let DocCobro_Linea(ByVal value As Integer)
    mprops.DocCobro_Linea = value
End Property

Public Property Get DocCobro_Linea() As Integer
    DocCobro_Linea = mprops.DocCobro_Linea
End Property



Public Property Let DocXPagar_CambioPag(value As Boolean)
    mprops.DocXPagar_CambioPag = value
End Property

Public Property Get DocXPagar_CambioPag() As Boolean
    DocXPagar_CambioPag = mprops.DocXPagar_CambioPag
End Property

Public Property Let DocXPagar_Linea(ByVal value As Integer)
    mprops.DocXPagar_Linea = value
End Property

Public Property Get DocXPagar_Linea() As Integer
    DocXPagar_Linea = mprops.DocXPagar_Linea
End Property


Public Property Let DocXCobrar_CambioPag(value As Boolean)
    mprops.DocXCobrar_CambioPag = value
End Property

Public Property Get DocXCobrar_CambioPag() As Boolean
    DocXCobrar_CambioPag = mprops.DocXCobrar_CambioPag
End Property

Public Property Let DocXCobrar_Linea(ByVal value As Integer)
    mprops.DocXCobrar_Linea = value
End Property

Public Property Get DocXCobrar_Linea() As Integer
    DocXCobrar_Linea = mprops.DocXCobrar_Linea
End Property

Public Property Let Recargo_CambioPag(value As Boolean)
    mprops.Recargo_CambioPag = value
End Property

Public Property Get Recargo_CambioPag() As Boolean
    Recargo_CambioPag = mprops.Recargo_CambioPag
End Property

Public Property Let Recargo_ValorAcum(ByVal value As String)
  If Len(value) > 6 Then
        Err.Raise ERR_INVALIDO, "Elementos.Modo", MSGERR_INVALIDO
    End If
    mprops.Recargo_ValorAcum = value
End Property

Public Property Get Recargo_ValorAcum() As String
    Recargo_ValorAcum = mprops.Recargo_ValorAcum
End Property

Public Property Let Recargo_Linea(ByVal value As Integer)
    mprops.Recargo_Linea = value
End Property

Public Property Get Recargo_Linea() As Integer
    Recargo_Linea = mprops.Recargo_Linea
End Property


