Attribute VB_Name = "ModRol"
Option Explicit
Type LineasRol
    Ingreso As String
    ValorIngreso As Double
    Egreso As String
    ValorEgreso As Double
    ObservacionIng As String '  AUC 02/10/07
    ObservacionEgr As String '  AUC 02/10/07
End Type
Type DATOS_AGRUPA
    NumColumna As Integer
    valor As Variant
End Type
'AUC
Private DetalleRol() As LineasRol
Const MARGENSUP = 0          'Margen superior para la primera hoja

Dim Ind As Integer        'Valor del indice de la matriz
Private ComparaAgrupacion() As DATOS_AGRUPA
'AUC 11/05/07
Private rsRegistro As New Recordset
Private mEmpleado As String
Private mFechaIngreso As Date
Private mFechaSalida As Date
Private mprov As Currency
Private multsueldo As Currency
Private mIngresos As Currency
Private mEgresos As Currency
Private contCampo As Integer
Private Margen As Integer
Const MaxCamposH = 23


Public Sub ImpEncabezadoRol(ByVal gc As GNCOMPROBANTE, ByVal pt As PrintTxt, ByVal Titulo As String)
    With pt
        .ImpCondensado 0
        .ImpEnfatizado 0
        .ImpExpandido 0
        .ImpSubrayado 0
        .IndentLeft = 0
        'Recupera los datos de la empresa de acuerdo al nombre de la base que va a ser el código
        'hasta segunda orden
        'Datos de la empresa
'        .ImpInicializa
        .ImpExpandido 1
        .PrintLine "", MARGENSUP
        
        .PrintLine gc.Empresa.GNOpcion.NombreEmpresa, 1
        .ImpExpandido 0
        .ImpEnfatizado 1
        .PrintLine "Direccion: " & .Rellenar(gc.Empresa.GNOpcion.Direccion1, 25, True) & " "
        .PrintLine "Telefono: " & .Rellenar(gc.Empresa.GNOpcion.Telefono1, 15, True), 2
        'Título del reporte
        .PrintLine Space$(6)
        .ImpSubrayado 1
        .PrintLine Titulo
        .PrintLine Space$(2)
        .PrintLine Space$(2), 2
        .ImpSubrayado 0
        .ImpEnfatizado 0
    End With
End Sub


Private Sub ListaDepColTitulo(ByVal pt As PrintTxt)
    With pt
        .ImpCondensado 1
        .PrintLine "", 1
        .PrintLine pt.Rellenar("#", 5, False) & "   "
        .PrintLine pt.Rellenar("Código", 15, True)
        .PrintLine pt.Rellenar("Nombre del Departamento", 50, True), 1
        .PrintLine String$(134, "="), 1 'Cambio de Línea
        .ImpCondensado 0
    End With
End Sub


Private Sub ListaProvColTitulo(ByVal pt As PrintTxt)
    With pt
        .ImpCondensado 1
        .PrintLine "", 1
        .PrintLine pt.Rellenar("#", 4, False) & "   "
        .PrintLine pt.Rellenar("Dias Labor.", 10, True) & " "
        .PrintLine pt.Rellenar("Nomina", 40, True) & " "
        .PrintLine pt.Rellenar("Num_Cedula", 13, True) & " "
        .PrintLine pt.Rellenar("Valor", 18, False) & " "
        .PrintLine pt.Rellenar("Recibi Conforme", 30, True), 1
        .PrintLine String$(134, "="), 1 'Cambio de Línea
        .ImpCondensado 0
    End With
End Sub

Private Sub ListaBancosColTitulo(ByVal pt As PrintTxt)
    With pt
        .ImpCondensado 1
        .PrintLine "", 1
        .PrintLine pt.Rellenar("#", 4, False) & "   "
        .PrintLine pt.Rellenar("Nomina", 40, True) & " "
        .PrintLine pt.Rellenar("Num_Cedula", 13, True) & " "
        .PrintLine pt.Rellenar("Num_Cuenta", 15, True) & " "
        .PrintLine pt.Rellenar("Valor", 18, False), 1
        .PrintLine String$(134, "="), 1 'Cambio de Línea
        .ImpCondensado 0
    End With
End Sub

Private Sub ListaPerColTitulo(ByVal pt As PrintTxt)
    With pt
        .ImpCondensado 1
        .PrintLine "", 1
        .PrintLine pt.Rellenar("#", 5, False) & " "
        .PrintLine pt.Rellenar("Código", 10, True) & " "
        .PrintLine pt.Rellenar("Nombre", 30, True) & " "
        .PrintLine pt.Rellenar("Num_Cedula", 13, True) & " "
        .PrintLine pt.Rellenar("Direccion", 28, True) & " "
        .PrintLine pt.Rellenar("Telefono", 18, True) & " "
        .PrintLine pt.Rellenar("Cargo", 24, True), 1
        .PrintLine String$(134, "="), 1 'Cambio de Línea
        .ImpCondensado 0
    End With
End Sub





Private Sub ImprimeSubtotal(ByVal pt As PrintTxt, ByRef bandFirstTotal As Boolean, _
                            total As Currency, AnchoDescripcion As Long, AnchoValor As Long, Formato As String)
    Dim j As Integer
    With pt
        If bandFirstTotal Then
            bandFirstTotal = False
        Else
            .PrintLine pt.Rellenar(" ", AnchoDescripcion + 3, False)
            .ImpSubrayado 1
            .PrintLine pt.Rellenar(" ", AnchoValor, False), 1
            .ImpSubrayado 0
            .PrintLine pt.Rellenar(" SUBTOTAL", AnchoDescripcion + 3, True) & _
                       pt.Rellenar(Format(total, Formato), AnchoValor, False), 1
        End If
    End With
End Sub

Private Sub SubLinea(ByVal pt As PrintTxt, s As String)
    With pt
        .ImpEnfatizado 1
'        .PrintLine "", 1                   ' desperdicio de papel
        .PrintLine s, 1
        .ImpEnfatizado 0
    End With
End Sub

Public Sub ImprimeDetalleGeneralxLote(ByVal gc As GNCOMPROBANTE, ByVal emp As String, ByVal pt As PrintTxt, NumLineas As Long, _
                              ByVal grdIngresos As Variant, grdEgresos As Variant)
    Dim i As Integer, cont1 As Integer, cont2 As Integer, dif As Integer
    Dim ele As Elementos
    pt.ImpCondensado 1
    'Redimensiona el vector dinámico de acuerdo al número de elementos que se necesita
    For i = 0 To NumLineas
        ReDim DetalleRol(i)
    Next i
    'Pasa valores de las grillas (Ingresos y Egresos) hacia el vector
    cont1 = 0
    
    
        
        For i = 0 To UBound(grdIngresos, 1) '.Rows - 1
            Set ele = gc.Empresa.RecuperarElemento(grdIngresos(i, 1))
            If grdIngresos(i, 0) = emp And grdIngresos(i, 8) = -1 Then
                DetalleRol(cont1).Ingreso = grdIngresos(i, 2)
                DetalleRol(cont1).ValorIngreso = Format(grdIngresos(i, 5), gc.Empresa.GNOpcion.FormatoCantidad)
                cont1 = cont1 + 1
            End If
            Set ele = Nothing
        Next i
        
    cont2 = 0
    
        For i = 0 To UBound(grdEgresos, 1)
        Set ele = gc.Empresa.RecuperarElemento(grdEgresos(i, 1))
            If grdEgresos(i, 0) = emp And grdEgresos(i, 8) = -1 Then
                DetalleRol(cont2).Egreso = grdEgresos(i, 2)
                DetalleRol(cont2).ValorEgreso = Format(grdEgresos(i, 5), gc.Empresa.GNOpcion.FormatoCantidad)
                cont2 = cont2 + 1
            End If
        Next i
    
    dif = IIf(cont1 > cont2, NumLineas - (cont1 - 1), NumLineas - (cont2 - 1)) 'Para omitir lineas en blanco
    NumLineas = NumLineas - dif
    'Imprime por Lineas el Rol es decir un elemento de ingreso y otro de egreso
    For i = 0 To NumLineas
        With pt
            .PrintLine .Rellenar(DetalleRol(i).Ingreso, 15, True) & " " 'Nombre del ingreso
            If DetalleRol(i).Ingreso <> "" Then                         'Si hay nombre del elemento imprime el valor del mismo
                .PrintLine .Rellenar(Format(DetalleRol(i).ValorIngreso, gc.Empresa.GNOpcion.FormatoCantidad), 15, False)
            Else
                .PrintLine Space$(15)
            End If
            .PrintLine Space$(20)
            .PrintLine .Rellenar(DetalleRol(i).Egreso, 15, True) & " "  'Nombre del egreso
            If DetalleRol(i).Egreso <> "" Then
                .PrintLine .Rellenar(Format(DetalleRol(i).ValorEgreso, gc.Empresa.GNOpcion.FormatoCantidad), 15, False)
            Else
                .PrintLine Space$(15)
            End If
            .PrintLine "", 1
        End With
    Next i
    pt.ImpCondensado 0
End Sub

Public Sub ImprimeDetalleGeneral(ByVal gc As GNCOMPROBANTE, ByVal emp As String, ByVal pt As PrintTxt, NumLineas As Long, _
                              ByVal grdIngresos As Variant, grdEgresos As Variant)
    Dim i As Integer, cont1 As Integer, cont2 As Integer, dif As Integer
    Dim ele As Elementos
    pt.ImpCondensado 1
    'Redimensiona el vector dinámico de acuerdo al número de elementos que se necesita
    For i = 0 To NumLineas
        ReDim DetalleRol(i)
    Next i
    'Pasa valores de las grillas (Ingresos y Egresos) hacia el vector
    cont1 = 0
    
        For i = 0 To UBound(grdIngresos, 1)  '.Rows - 1
            Set ele = gc.Empresa.RecuperarElemento(grdIngresos(i, 0))
            If CBool(grdIngresos(i, 7)) Then
                DetalleRol(cont1).Ingreso = grdIngresos(i, 1)
                DetalleRol(cont1).ValorIngreso = Format(grdIngresos(i, 4), gc.Empresa.GNOpcion.FormatoCantidad)
                cont1 = cont1 + 1
            End If
        Next i
    
    cont2 = 0
    
        For i = 0 To UBound(grdEgresos, 1)
            If CBool(grdEgresos(i, 7)) Then
                DetalleRol(cont2).Egreso = grdEgresos(i, 1)
                DetalleRol(cont2).ValorEgreso = Format(grdEgresos(i, 4), gc.Empresa.GNOpcion.FormatoCantidad)
                cont2 = cont2 + 1
            End If
        Next i
    
    dif = IIf(cont1 > cont2, NumLineas - (cont1 - 1), NumLineas - (cont2 - 1)) 'Para omitir lineas en blanco
    NumLineas = NumLineas - dif
    'Imprime por Lineas el Rol es decir un elemento de ingreso y otro de egreso
    For i = 0 To NumLineas
        With pt
            .PrintLine .Rellenar(DetalleRol(i).Ingreso, 15, True) & " " 'Nombre del ingreso
            If DetalleRol(i).Ingreso <> "" Then                         'Si hay nombre del elemento imprime el valor del mismo
                .PrintLine .Rellenar(Format(DetalleRol(i).ValorIngreso, gc.Empresa.GNOpcion.FormatoCantidad), 15, False)
            Else
                .PrintLine Space$(15)
            End If
            .PrintLine Space$(20)
            .PrintLine .Rellenar(DetalleRol(i).Egreso, 15, True) & " "  'Nombre del egreso
            If DetalleRol(i).Egreso <> "" Then
                .PrintLine .Rellenar(Format(DetalleRol(i).ValorEgreso, gc.Empresa.GNOpcion.FormatoCantidad), 15, False)
            Else
                .PrintLine Space$(15)
            End If
            .PrintLine "", 1
        End With
    Next i
    pt.ImpCondensado 0
End Sub

