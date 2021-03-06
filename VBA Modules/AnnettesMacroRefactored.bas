Attribute VB_Name = "AnnettesMacroRefactored"
Option Explicit

Dim Difference As Long
Dim PT As Worksheet
Dim bAnswer As Integer
Dim CountMissed As Integer
Dim newsheets As Integer
Dim AdHocTemplateStr As String

Sub main()

Application.EnableEvents = False
Application.ScreenUpdating = False
run:
'declare variables
Set PT = Application.ActiveSheet
Dim ws As Worksheet
Dim looptimes As Integer
Dim cell As Range
Dim stdName As String, unhyphName As String, squishName As String
Dim c As Integer

' initialize value to zero (This loop runs about 15 times)
For Each ws In Application.ActiveWorkbook.Worksheets
    If ws.name = "Summary" Or ws.name = PT.name Or ws.Visible = False Then GoTo next1
    Call ZeroOut(ws)
    c = 0

    For Each cell In PT.UsedRange
    
        'check if a real name but not their totals (c. 50 instances)
        If InStr(cell.Value, ",") <> 0 And cell.Offset(0, 1).Value <> "" Then
            
            '' capture the different name possibilities
            Call GetNames(cell, stdName, unhyphName, squishName)
            
            ' should call once for each WS to populate, 15-20 times per real names in pivot table (c.50)
            If stdName = ws.name Or unhyphName = ws.name Or squishName = ws.name Then
                c = c + 1
                Call TransferData(ws, cell)
                    If c = 2 Then GoTo next1: '' no need to keep searching worksheet if both instances of doctors (old and new) found
            End If
        End If
    Next


next1:
Next
    

Call DataValidator(PT)


If Difference = 0 Then
    MsgBox ("Done. Numbers balance out. Have a nice day")
Else
    'warn user
    If CountMissed > 0 Then
        bAnswer = MsgBox("Done. Numbers don't tie out, off by " & Difference & " hours. It looks like not all new doctors were added. Would you like to auto create new worksheets for missing providers?", vbYesNo)
        'ask if should add doctors
        If bAnswer = 6 Then
            Call DoctorAdder
            MsgBox (newsheets & " new sheets added from template and data updated. Note, summary tab not appended with new doctors")
            GoTo run:
        End If
    End If
MsgBox ("Done. Numbers still don't tie out, off by " & Difference & " hours. Most of this data should be good. Data usually transfers perfectly by doctor or not at all, so review all worksheets with zero values for failed transfer. Chcek for name peculiarities and discrepencies between pivot table and worksheet name. Check for spaces or hyphens. I can make this more dynamic in the future if given added criteria (error formatting types)")

End If

    Application.ScreenUpdating = True
    Application.EnableEvents = True
End Sub


Sub TransferData(ws As Worksheet, cell As Range)
Dim looptimes As Integer
Dim datatotransfer As Long
Dim i As Integer
Dim indexnumber As Long
Dim CellToPasteTo As Range

    looptimes = looptimesf(ws, cell)
  
    ' Transfer data looptimes times
    For i = 0 To looptimes - 1
        indexnumber = cell.Offset(i, 1).FormulaR1C1
        datatotransfer = cell.Offset(i, 2).FormulaR1C1
        Set CellToPasteTo = ws.UsedRange.Find(indexnumber).Offset(0, 1)
        CellToPasteTo.FormulaR1C1 = datatotransfer
    Next
End Sub

Function looptimesf(ws As Worksheet, cell As Range)
    Dim endrow As Integer
    Dim startrow As Integer

    If cell.Offset(1, 0).FormulaR1C1 <> "" Then
        looptimesf = 1
    Else
    'need to debut where the xldown and up don't work, where two doctors with one line are squashed
        startrow = cell.row
        endrow = cell.End(xlDown).row
        looptimesf = endrow - startrow
    End If

End Function


Sub ZeroOut(ws As Worksheet)

Dim cell As Range
Dim LastRow As Long
Dim rng As Range
LastRow = ws.UsedRange.rows.count
Set rng = ws.Range("B1:B" & LastRow)

If ws.name = "Summary" Or ws.Visible = False Then
    GoTo endd
End If

For Each cell In rng

    
    'If IsNumeric(cell.value) And cell.value <> "" And InStr(cell.FormulaR1C1, "=") = 0 Then
    If IsNumeric(cell.Value) And cell.Value <> "" And cell.Offset(0, 1).FormulaR1C1 <> "" And cell.Offset(0, -1).FormulaR1C1 <> "" Then '' changed the if to account for any hard coded = in the cells e.g. =4+5. Has happened, resulting in error at least in data validation
        cell.FormulaR1C1 = 0
    End If
Next

endd:
End Sub

Sub DataValidator(PT As Worksheet)
Dim RunningTotalHrs As Long
Dim ws As Worksheet
RunningTotalHrs = 0
Dim PTTotal As Long

PTTotal = PT.UsedRange.Find("Grand Total").Offset(0, 2).Value
PTTotal = PTTotal + PT.UsedRange.FindNext(PT.UsedRange.Find("Grand Total")).Offset(0, 2).Value


For Each ws In Application.ActiveWorkbook.Worksheets
    If ws.name = "Summary" Or ws.name = PT.name Or ws.Visible = False Then GoTo next1

    '' access colum b for getting values
        'set used range of column b as range
        Dim cell As Range
        Dim LastRow As Integer
        Dim rng As Range
        LastRow = ws.UsedRange.rows.count
        Set rng = ws.Range("B1:B" & LastRow)
        
        
        For Each cell In rng
            If InStr(cell.FormulaR1C1, "=") <> 0 Then
            RunningTotalHrs = RunningTotalHrs + cell.Value
            End If
        Next
next1:
Next

Difference = PTTotal - RunningTotalHrs

If Difference > 1 Then
    Call doctorchecker
End If

End Sub

Sub doctorchecker()
Dim cell As Range
CountMissed = 0
Dim stdName As String, unhyphName As String, squishName As String
Dim PT As Worksheet
Set PT = Application.ActiveSheet

    For Each cell In PT.UsedRange
        If InStr(cell.Value, ",") <> 0 And cell.Offset(0, 1).Value <> "" Then ' if it looks to be a bona fide nombre ==>
            Call GetNames(cell, stdName, unhyphName, squishName) ' Get various name forms
            If Not WorksheetExists(stdName) And Not WorksheetExists(unhyphName) And Not WorksheetExists(squishName) Then
                CountMissed = CountMissed + 1  ' might be doubled up due to double names on pivot, but shouldn't matter for our _
                purposes here. We only need it to be > 0 to run switch
            Else '' find which worksheet exists and make that the ad hoc template to copy new worksheets from (prevents errors from choosing a faulty non doctor worksheet as template by accident
                If AdHocTemplateStr = "" Then
                    If WorksheetExists(stdName) Then
                        AdHocTemplateStr = stdName
                    ElseIf WorksheetExists(squishName) Then
                        AdHocTemplateStr = squishName
                    Else: WorksheetExists (unhyphName)
                        AdHocTemplateStr = unhyphName
                    End If
                End If
            End If
        End If
    Next
End Sub

Sub DoctorAdder()
Dim cell As Range
Dim stdName As String, unhyphName As String, squishName As String ''have to check for all name varations to not duplicate ws
newsheets = 0
Dim bUseTemplate As Boolean
If WorksheetExists("Template") Then
    Application.Worksheets("Template").Visible = True
    bUseTemplate = True
Else
    bUseTemplate = False
End If

Set PT = Application.ActiveSheet  ' Pivot has to be active sheet to run this code apparantly. Could make more dynamic
For Each cell In PT.UsedRange

    'check if a real name but not their totals (c. 50 instances)
    If InStr(cell.Value, ",") <> 0 And cell.Offset(0, 1).Value <> "" Then ''bona fide names. TODO promote to funct (below)
        
        'stdName = Mid(cell.Value, InStr(cell.Value, ",") + 2, 1) & ". " & Left(cell.Value, InStr(cell.Value, ",") - 1)
        Call GetNames(cell, stdName, unhyphName, squishName)
    
        ' should call once for each WS to populate, 15-20 times per real names in pivot table (c.50)
        If Not WorksheetExists(stdName) And Not WorksheetExists(unhyphName) And Not WorksheetExists(squishName) Then
            ' copy template ws and rename to
            'Call CreateSheet(DoctorName) ''functiont that doesn't exist or hasn't been tested yet
            If bUseTemplate = True Then
                Application.Worksheets("Template").Copy after:=Sheets(Sheets.count)
                Application.ActiveSheet.name = stdName
                Range("a2").Formula = stdName
                newsheets = newsheets + 1
            Else
                Application.Worksheets(AdHocTemplateStr).Copy after:=Sheets(Sheets.count) '' random worksheet chosen, must guess right or error
                '' TODO come up with protection in case no named template and wrong guess. Capture one is worksheet and save that
                Application.ActiveSheet.name = stdName
                Range("a2").Formula = stdName
                newsheets = newsheets + 1
            End If
        End If
    End If
Next
    If bUseTemplate = True Then '' cover our tracks
    Application.Worksheets("Template").Visible = False
    End If
PT.Activate
End Sub

Function WorksheetExists(sName As String) As Boolean
On Error Resume Next ''shouldn't need but just in case
    WorksheetExists = Evaluate("ISREF('" & sName & "'!A1)")
End Function

''not used yet. Maybe for future refactoring
Private Sub CreateSheet(wsname As String)
    Dim ws As Worksheet
    
    Set ws = ThisWorkbook.Sheets.add(after:= _
             ThisWorkbook.Sheets(ThisWorkbook.Sheets.count))
    ws.name = wsname
End Sub


Sub GetNames(ByVal cell As Range, ByRef stdName As String, Optional ByRef unhyphName As String, Optional ByRef squishName As String)

stdName = Mid(cell.Value, InStr(cell.Value, ",") + 2, 1) & ". " & Left(cell.Value, InStr(cell.Value, ",") - 1)

If InStr(cell.Value, "-") Then
    unhyphName = Mid(cell.Value, InStr(cell.Value, ",") + 2, 1) & ". " & Left(cell.Value, InStr(cell.Value, "-") - 1)
    Else
    unhyphName = "."
End If

squishName = Mid(cell.Value, InStr(cell.Value, ",") + 2, 1) & "." & Left(cell.Value, InStr(cell.Value, ",") - 1)

End Sub

''function not currently being used but could replace messier code upstairs.

Function bIsNameCell(ByVal cell As Range)
If InStr(cell.Value, ",") <> 0 And cell.Offset(0, 1).Value <> "" Then ' if it looks to be a bona fide nombre ==>
    bIsNameCell = True
Else
    bIsNameCell = False
End Function

