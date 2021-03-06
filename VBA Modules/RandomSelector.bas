Attribute VB_Name = "RandomSelector"
Option Explicit
Sub RandomSample()
Application.ScreenUpdating = False
Application.EnableEvents = False
MakeArray
Application.ScreenUpdating = True
Application.EnableEvents = True
End Sub

Sub MakeArray()
Application.EnableEvents = False
    Dim MyArray As Variant
    Dim i As Integer
    Dim TryRand As Integer
    Dim RowCount As Integer
    Dim rngCurrentRegion As Range
    Dim NewWs As Worksheet
    Dim CurrentWSName As String
    Dim PasteCell As String
    PasteCell = "b3"
    CurrentWSName = Application.ActiveSheet.name
    Dim DeleteExtraneous As Integer
    Dim TopRightCell As Range
    Dim BottomRightCell As Range
    Dim InitLastCol As Range
    Dim form As New SelectionParams
    Dim rng As Range
    Dim ChosenRegion As Range
    Dim chosenregiontxt As String
    Dim Quantity As Integer
    Dim bHeader As Boolean
    
    ' get user input
RequestInput:
    form.Show vbModal
    If form.Range.text <> "" Then
        Set rng = Range(form.Range.text)
        RowCount = rng.rows.count
        Set rngCurrentRegion = Intersect(rng.CurrentRegion, rng.EntireRow)
    ElseIf form.CurrentRegionGetter.text <> "" Then
        Set rngCurrentRegion = Range(form.CurrentRegionGetter.text).CurrentRegion
        RowCount = rngCurrentRegion.rows.count
    Else
        MsgBox ("Select either custom range or cell in table")
        GoTo RequestInput
    End If
    Quantity = form.SampleSize
    bHeader = form.bHeader
    
    If bHeader = True Then
        RowCount = RowCount - 1
    End If
    
    If Quantity >= RowCount Then
        MsgBox ("Choose selection size that's smaller than row count")
        GoTo RequestInput
    End If

    ReDim MyArray(Quantity - 1)
    
    For i = 0 To Quantity - 1
retry:
        ' get random int values loaded into array
        TryRand = RndBetween(1, RowCount)
        If IsInArray(TryRand, MyArray) Then GoTo retry
        MyArray(i) = TryRand
    Next
    
    
    
    '' TMP Debug XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    MsgBox ("the row count is " & RowCount & " and the sample size is " & Quantity)
    '' TMP Debug XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    
    
    
    '' Paste current region of range to new worksheet
    Set NewWs = Application.ActiveWorkbook.Worksheets.add(after:=Application.ActiveWorkbook.ActiveSheet)
    If Not WorksheetExists("sample") Then
        NewWs.name = "Sample"
    End If
    
    rngCurrentRegion.Copy NewWs.Range(PasteCell)

    
    Set TopRightCell = Range(PasteCell).CurrentRegion.Cells(1, rngCurrentRegion.Columns.count)
    Set BottomRightCell = Range(PasteCell).CurrentRegion.Cells(rngCurrentRegion.rows.count, rngCurrentRegion.Columns.count)

    If bHeader = True Then
        With TopRightCell.Offset(0, 1) 'need to determine proper top row or could cause error
            .Value = "Selection"
            .Font.Bold = True
        End With
    Else
        With TopRightCell.Offset(-1, 1) 'need to determine proper top row or could cause error
            .Value = "Selection"
            .Font.Bold = True
        End With
    End If
    
    Dim instance As Variant
    If bHeader = True Then
        For Each instance In MyArray
            With TopRightCell.Offset(instance, 1)
                .Value = "x"
                .Interior.ColorIndex = 35
            End With
        Next
    Else
        For Each instance In MyArray
            With TopRightCell.Offset(instance - 1, 1)
                .Value = "x"
                .Interior.ColorIndex = 35
            End With
        Next
    End If
    
    ' 6 = yes, 7 = no
    DeleteExtraneous = MsgBox("Sample table created succesfully. Delete all extraneous rows?", vbYesNo)
    If DeleteExtraneous = 6 Then
        'get used column to iterate through
        Dim cell As Range
        
        '' this assumes there'll be something in the last column whihc may not be true. find way _
        to get lower left corner instead
        If bHeader = True Then
            Set InitLastCol = Range(TopRightCell.Offset(1, 0).Address & ":" & BottomRightCell.Address)
        Else
            Set InitLastCol = Range(TopRightCell.Address & ":" & BottomRightCell.Address)
        End If
            
restart:
        'InitLastCol = range(TopRightCell.Address & ":" & TopRightCell.End(xlDown).Address)
        For Each cell In InitLastCol
            If cell.Offset(0, 1).Value <> "x" Then
                cell.EntireRow.Delete
                GoTo restart
            End If
        Next
    End If
    
    Range(TopRightCell.Address).Offset(1, 3).Value = "Random Numbers Generated"
For i = 0 To Quantity - 1
    Range(TopRightCell.Address).Offset(2 + i, 3).Value = MyArray(i)
Next

MsgBox ("             Tada")
End Sub
' Gets random integer between low and high values
Function RndBetween(Low, High) As Integer
   Randomize
   RndBetween = Int((High - Low + 1) * Rnd + Low)
End Function

Private Function IsInArray(valToBeFound As Variant, arr As Variant) As Boolean
'DEVELOPER: Ryan Wells (wellsr.com)
'DESCRIPTION: Function to check if a value is in an array of values
'INPUT: Pass the function a value to search for and an array of values of any data type.
'OUTPUT: True if is in array, false otherwise
Dim element As Variant
On Error GoTo IsInArrayError: 'array is empty
    For Each element In arr
        If element = valToBeFound Then
            IsInArray = True
            Exit Function
        End If
    Next element
Exit Function
IsInArrayError:
On Error GoTo 0
IsInArray = False
End Function

Function WorksheetExists(sName As String) As Boolean
On Error Resume Next ''shouldn't need but just in case
    WorksheetExists = Evaluate("ISREF('" & sName & "'!A1)")
End Function
